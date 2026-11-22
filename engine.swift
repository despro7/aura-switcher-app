import Cocoa
import Carbon
import ServiceManagement
import ApplicationServices
import os

// MARK: - Layouts

let kMagic: Int64 = 0x4B535754 // marks our own synthetic events
/// why a word was left alone — no typed text, only the reason (`log show --predicate 'subsystem == "com.chernov.aura"'`)
let auraLog = Logger(subsystem: "com.chernov.aura", category: "auto")
func langName(_ code: String) -> String { Locale(identifier: uiCode()).localizedString(forLanguageCode: code)?.capitalized ?? code }

/// A key press. `ch` is the character it actually produced (from the event), which tells which layout
/// was really active — more reliable than asking the system from a background app. `caps` (Caps Lock)
/// uppercases letters only, not digits or symbols. Neither is part of equality.
struct Key: Hashable {
    let code: UInt16; let shift: Bool; var caps = false; var ch: Character? = nil
    static func == (a: Key, b: Key) -> Bool { a.code == b.code && a.shift == b.shift }
    func hash(into h: inout Hasher) { h.combine(code); h.combine(shift) }
}

final class Layout {
    let lang: String
    let source: TISInputSource
    var toChar: [Key: Character] = [:]
    var toKey: [Character: Key] = [:]
    var dead: [Key: String] = [:]   // dead key (accent typed before the letter) → its combining marks

    init?(lang: String, source: TISInputSource) {
        self.lang = lang
        self.source = source
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
        data.withUnsafeBytes { raw in
            guard let layout = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return }
            for code in UInt16(0)...50 where ![36, 48, 49].contains(code) {
                for shift in [false, true] {
                    var dead: UInt32 = 0, len = 0
                    var chars = [UniChar](repeating: 0, count: 4)
                    let mod: UInt32 = shift ? UInt32((shiftKey >> 8) & 0xFF) : 0
                    UCKeyTranslate(layout, code, UInt16(kUCKeyActionDown), mod, UInt32(LMGetKbdType()),
                                   OptionBits(1 << kUCKeyTranslateNoDeadKeysBit), &dead, 4, &len, &chars)
                    guard len == 1, chars[0] >= 0x20, let s = Unicode.Scalar(chars[0]) else { continue }
                    let c = Character(s)
                    let k = Key(code: code, shift: shift)
                    toChar[k] = c
                    if toKey[c] == nil { toKey[c] = k }
                    var state: UInt32 = 0
                    UCKeyTranslate(layout, code, UInt16(kUCKeyActionDown), mod, UInt32(LMGetKbdType()), 0, &state, 4, &len, &chars)
                    if len == 0, state != 0 {  // the spacing accent (´ ΄ ¨) decomposes to space + combining marks
                        let marks = String(String(c).decomposedStringWithCompatibilityMapping.unicodeScalars
                            .filter { $0.properties.generalCategory == .nonspacingMark }.map(Character.init))
                        if !marks.isEmpty { self.dead[k] = marks }
                    }
                }
            }
        }
    }

    /// What the keys type in this layout; a dead key and the letter after it make one accented letter (´ e → é).
    func text(_ keys: [Key]) -> String {
        var s = "", i = 0
        while i < keys.count {
            let k = keys[i]; i += 1
            guard var c = toChar[k].map(String.init) else { continue }
            if let n = keys[i...].first, let l = toChar[n], l.isLetter {
                if let m = dead[k] { c = (String(l) + m).precomposedStringWithCanonicalMapping; i += 1; if n.caps { c = c.uppercased() } }
            }
            if k.caps, c.count == 1, c.first!.isLetter { c = c.uppercased() }
            s += c
        }
        return s
    }

    func maps(_ keys: [Key]) -> Bool { keys.allSatisfy { toChar[$0] != nil } }

    /// Keys that type a character here: one key, or a dead key + letter for an accented one.
    func keys(for c: Character) -> [Key]? {
        if let k = toKey[c] { return [k] }
        let sc = String(c).decomposedStringWithCanonicalMapping.unicodeScalars
        guard let base = sc.first, let bk = toKey[Character(base)] else { return nil }
        let marks = String(sc.dropFirst().map(Character.init))
        guard !marks.isEmpty, let dk = dead.first(where: { $0.value == marks })?.key else { return nil }
        return [dk, bk]
    }
}

func loadLayouts() -> [Layout] {
    let filter = [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource!,
                  kTISPropertyInputSourceIsSelectCapable: true] as CFDictionary
    guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else { return [] }
    // every enabled keyboard layout, one per language, in system order (IMEs without key data are skipped)
    var result: [Layout] = []
    for src in list {
        guard let l = sourceLang(src), !result.contains(where: { $0.lang == l }),
              let layout = Layout(lang: l, source: src) else { continue }
        result.append(layout)
    }
    return result
}

func sourceLang(_ src: TISInputSource) -> String? {
    guard let p = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages) else { return nil }
    let langs = Unmanaged<CFArray>.fromOpaque(p).takeUnretainedValue() as? [String]
    return langs?.first.map { String($0.prefix(2)) }
}

/// Language code written in the language's own script: en → EN, uk → УК, ru → РУ, el → ΕΛ
let nativeCodes = ["uk": "УК", "ru": "РУ", "be": "БЕ", "bg": "БГ", "sr": "СР", "mk": "МК", "kk": "ҚЗ", "ky": "КЫ",
                   "tg": "ТҶ", "mn": "МН", "el": "ΕΛ", "ka": "ქა", "hy": "ՀՅ", "he": "עב", "ar": "عر", "fa": "فا"]
func displayCode(_ lang: String?) -> String {
    guard let lang else { return "--" }
    return nativeCodes[lang] ?? lang.uppercased()
}

/// tests set the "active" layout here instead of switching the system's
var forcedLang: String? = nil
func currentLang() -> String? { forcedLang ?? sourceLang(TISCopyCurrentKeyboardInputSource().takeRetainedValue()) }

// MARK: - Language models

/// For languages whose spelling dictionary may be missing (lang/<code>.txt, built by tools/langmodel.py):
/// the most frequent words, and letter-trigram costs (−10·ln p) that tell a word of the language
/// typed in the wrong layout from an English typo.
/// tests read the models from the repo's lang/ folder instead of the app bundle
var langDir: URL? = nil

final class LangModel {
    let words: Set<String>, tri: [String: Int], floor: Int
    init?(_ lang: String) {
        guard let url = langDir.map({ $0.appendingPathComponent(lang + ".txt") })
                ?? Bundle.main.url(forResource: lang, withExtension: "txt", subdirectory: "lang"),
              let s = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let lines = s.split(separator: "\n").filter { !$0.hasPrefix("#") }
        guard let first = lines.first else { return nil }
        words = Set(first.split(separator: " ").map(String.init))
        var t: [String: Int] = [:]
        for l in lines.dropFirst() { let p = l.split(separator: "\t"); if p.count == 2, let v = Int(p[1]) { t[String(p[0])] = v } }
        tri = t; floor = (t.values.max() ?? 100) + 10
    }
    func has(_ w: String) -> Bool { words.contains(w.lowercased()) }
    /// average trigram cost: lower = more typical of the language
    func cost(_ w: String) -> Double {
        let c = Array("^" + w.lowercased() + "$")
        guard c.count >= 3 else { return Double(floor) }
        return Double((0..<c.count - 2).reduce(0) { $0 + (tri[String(c[$1..<$1 + 3])] ?? floor) }) / Double(c.count - 2)
    }
}

// MARK: - Settings

final class Settings {
    let d = UserDefaults.standard
    var enabled: Bool { get { d.object(forKey: "enabled") as? Bool ?? true } set { d.set(newValue, forKey: "enabled") } }
    var auto: Bool { get { d.object(forKey: "auto") as? Bool ?? true } set { d.set(newValue, forKey: "auto") } }
    var excluded: [String] { get { d.stringArray(forKey: "excluded") ?? [] } set { d.set(newValue, forKey: "excluded") } }
    var bindings: [String: String] { get { d.dictionary(forKey: "bindings") as? [String: String] ?? [:] } set { d.set(newValue, forKey: "bindings") } }
    var uiLang: String? { get { d.string(forKey: "uiLang") } set { d.set(newValue, forKey: "uiLang") } } // nil = system
    var sound: Bool { get { d.object(forKey: "sound") as? Bool ?? true } set { d.set(newValue, forKey: "sound") } }
    /// user's words that are never auto-corrected (slang like «хз», «ща»), stored lowercased
    var words: [String] { get { d.stringArray(forKey: "words") ?? [] } set { d.set(newValue, forKey: "words") } }
    /// fix letter case on a space: «ПРивіт» → «Привіт», «пРИВІТ» (Caps Lock) → «Привіт», abbreviations in capitals
    var caseFix: Bool { get { d.object(forKey: "caseFix") as? Bool ?? true } set { d.set(newValue, forKey: "caseFix") } }
    /// user's abbreviations that are always written in capitals («ттн» → «ТТН»), stored lowercased
    var abbrevs: [String] { get { d.stringArray(forKey: "abbrevs") ?? [] } set { d.set(newValue, forKey: "abbrevs") } }
    /// when the user last opened the releases page (seconds since 1970), 0 = never
    var updateCheckedAt: Double { get { d.double(forKey: "updateCheckedAt") } set { d.set(newValue, forKey: "updateCheckedAt") } }
}

/// Updates: the app goes online only when the user clicks «Check for updates…» (updater.swift: update.json on
/// klbk.github.io, the download from github.com); nothing typed and no personal data is ever sent. «What's new»
/// opens the site's update page (only the version and menu language are in its address), and some time after
/// this build (or after the last check) the menu and the icon remind that a newer version may be out. The build date is
/// written into Info.plist by build.sh. The site's update page: says whether a newer version is out, what's
/// new and how to update, in the menu language.
func updatePageURL() -> URL {
    let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    return URL(string: "https://klbk.github.io/aura-switcher/update/?v=\(ver)&l=\(uiCode())")!
}
let updateNudgeDays = 30.0
let buildDate = (Bundle.main.object(forInfoDictionaryKey: "AURABuildDate") as? String).flatMap(Double.init) ?? 0
func updateDue() -> Bool {
    let since = max(buildDate, engine.settings.updateCheckedAt)
    return since > 0 && Date().timeIntervalSince1970 - since > updateNudgeDays * 86400
}

/// Games (App Store category "Games" and its subcategories): double ⇧ is often sprint there, and a
/// full-screen game hides the menu bar, so the app can't be excluded by hand — pause AURA automatically.
func isGame(_ app: NSRunningApplication?) -> Bool {
    guard let url = app?.bundleURL, let cat = Bundle(url: url)?.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
    else { return false }
    return cat.hasSuffix("games")
}

/// VS Code, JetBrains IDEs and others copy the whole current line when nothing is selected —
/// a single line ending in a line break is that, not a selection to convert.
func isCopiedLine(_ s: String) -> Bool {
    guard s.last?.isNewline == true else { return false }  // "\r\n" is one Character in Swift
    return !s.dropLast().contains(where: \.isNewline)
}

/// "хз, ща яж" → ["хз", "ща", "яж"]
func parseWords(_ s: String) -> [String] {
    var seen = Set<String>()
    return s.lowercased().components(separatedBy: CharacterSet(charactersIn: ",;\n ").union(.whitespaces))
        .filter { !$0.isEmpty && seen.insert($0).inserted }
}

// MARK: - Sounds (synthesized, identical on Mac and Windows)

enum Sounds {
    /// A short quiet "tick" (fast attack, quick decay) for auto-correction, two rising ticks for double ⇧ —
    /// soft enough to stop noticing after a while.
    static func blip(_ freqs: [Double]) -> Data {
        let rate = 44100, toneLen = rate * 50 / 1000, gap = rate * 30 / 1000
        var pcm: [Int16] = []
        for (i, f) in freqs.enumerated() {
            if i > 0 { pcm += [Int16](repeating: 0, count: gap) }
            for n in 0..<toneLen {
                let t = Double(n) / Double(rate)
                let env = min(1, Double(n) / 40) * exp(-Double(n) / (Double(rate) * 0.012))  // no click, ~12 ms decay
                pcm.append(Int16(sin(2 * .pi * f * t) * env * 0.12 * 32767))
            }
        }
        var d = Data()
        func u32(_ v: Int) { var x = UInt32(v).littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: Int) { var x = UInt16(v).littleEndian; d.append(Data(bytes: &x, count: 2)) }
        d.append("RIFF".data(using: .ascii)!); u32(36 + pcm.count * 2); d.append("WAVEfmt ".data(using: .ascii)!)
        u32(16); u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16)
        d.append("data".data(using: .ascii)!); u32(pcm.count * 2)
        pcm.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
        return d
    }
    static let auto = NSSound(data: blip([1568]))
    static let shift = NSSound(data: blip([1318, 1760]))
    static func play(_ s: NSSound?) {
        guard engine.settings.sound, let s else { return }
        s.stop(); s.play()
    }
}

// MARK: - Localization (35 languages; Russian system → Ukrainian)

// BEGIN menu strings — generated by tools/menu_i18n.py, edit there
let uiLangs = ["en", "uk", "pl", "de", "es", "fr", "it", "pt", "tr", "nl", "cs", "sv", "fi", "ro", "hu", "el", "bg", "he", "ar", "hi", "ko", "be", "kk", "ky", "ka", "hy", "az", "sr", "mk", "sk", "hr", "sl", "lt", "lv", "et", "da", "nb", "is", "sq", "fa", "vi", "tg", "mn", "tt", "uz", "ga", "mt", "cy"]
let uiLangNames = ["English", "Українська", "Polski", "Deutsch", "Español", "Français", "Italiano", "Português", "Türkçe", "Nederlands", "Čeština", "Svenska", "Suomi", "Română", "Magyar", "Ελληνικά", "Български", "עברית", "العربية", "हिन्दी", "한국어", "Беларуская", "Қазақша", "Кыргызча", "ქართული", "Հայերեն", "Azərbaycan", "Српски", "Македонски", "Slovenčina", "Hrvatski", "Slovenščina", "Lietuvių", "Latviešu", "Eesti", "Dansk", "Norsk bokmål", "Íslenska", "Shqip", "فارسی", "Tiếng Việt", "Тоҷикӣ", "Монгол", "Татарча", "Oʻzbek", "Gaeilge", "Malti", "Cymraeg"]
/// Menu-language picker: a few likely languages on top, the rest under "All languages" by region.
/// Regions in menu order (title key → codes); a language not listed here goes to the first region.
let uiRegions: [(String, [String])] = [("regEurope", []), ("regCaucasus", ["kk", "ky", "ka", "hy", "az", "tg", "mn", "uz"]), ("regMiddleEast", ["he", "ar", "fa", "ku"]), ("regAsia", ["hi", "ko", "zh", "ja", "vi"])]
func uiRegionIndex(_ code: String) -> Int { uiRegions.firstIndex { $0.1.contains(code) } ?? 0 }
/// the languages shown on top of the picker: the current one, English, then the languages of the user's keyboard layouts
func uiTopLangs(current: String, layoutLangs: [String]) -> [String] {
    var top: [String] = []
    for c in [current, "en"] + layoutLangs where uiLangs.contains(c) && !top.contains(c) && top.count < 6 { top.append(c) }
    return top
}
let uiStrings: [String: [String]] = [ // key: one string per uiLangs
    "enabled": ["Enabled", "Увімкнено", "Włączone", "Aktiviert", "Activado", "Activé", "Attivo", "Ativado", "Etkin", "Ingeschakeld", "Zapnuto", "Aktiverad", "Käytössä", "Activat", "Bekapcsolva", "Ενεργό", "Включено", "מופעל", "مفعّل", "चालू", "켜기", "Уключана", "Қосулы", "Күйгүзүлгөн", "ჩართულია", "Միացված է", "Aktivdir", "Укључено", "Вклучено", "Zapnuté", "Uključeno", "Vklopljeno", "Įjungta", "Ieslēgts", "Sees", "Aktiveret", "På", "Kveikt", "Aktivizuar", "روشن", "Bật", "Фаъол", "Идэвхтэй", "Кабызылган", "Yoqilgan", "Cumasaithe", "Attivat", "Wedi’i alluogi"],
    "auto": ["Auto-correction", "Автовиправлення", "Autokorekta", "Autokorrektur", "Autocorrección", "Correction automatique", "Correzione automatica", "Correção automática", "Otomatik düzeltme", "Autocorrectie", "Automatické opravy", "Autokorrigering", "Automaattinen korjaus", "Corectare automată", "Automatikus javítás", "Αυτόματη διόρθωση", "Автокорекция", "תיקון אוטומטי", "التصحيح التلقائي", "स्वतः सुधार", "자동 수정", "Аўтавыпраўленне", "Автотүзету", "Авто оңдоо", "ავტოშესწორება", "Ինքնաուղղում", "Avtomatik düzəliş", "Аутокорекција", "Автокорекција", "Automatické opravy", "Automatski ispravak", "Samodejni popravki", "Automatinis taisymas", "Automātiskā labošana", "Automaatne parandus", "Automatisk rettelse", "Autokorrigering", "Sjálfvirk leiðrétting", "Korrigjim automatik", "تصحیح خودکار", "Tự động sửa", "Ислоҳи худкор", "Автомат засвар", "Автоматик төзәтү", "Avtomatik tuzatish", "Ceartú uathoibríoch", "Korrezzjoni awtomatika", "Cywiro awtomatig"],
    "sound": ["Sound", "Звук", "Dźwięk", "Ton", "Sonido", "Son", "Suono", "Som", "Ses", "Geluid", "Zvuk", "Ljud", "Ääni", "Sunet", "Hang", "Ήχος", "Звук", "צליל", "الصوت", "ध्वनि", "소리", "Гук", "Дыбыс", "Үн", "ხმა", "Ձայն", "Səs", "Звук", "Звук", "Zvuk", "Zvuk", "Zvok", "Garsas", "Skaņa", "Heli", "Lyd", "Lyd", "Hljóð", "Zëri", "صدا", "Âm thanh", "Овоз", "Дуу", "Тавыш", "Tovush", "Fuaim", "Ħoss", "Sain"],
    "access": ["⚠︎ Grant access: Accessibility, Input Monitoring", "⚠︎ Надайте доступ: Універсальний доступ, Моніторинг введення", "⚠︎ Nadaj dostęp: Dostępność, Monitorowanie wejścia", "⚠︎ Zugriff erlauben: Bedienungshilfen, Eingabeüberwachung", "⚠︎ Conceder acceso: Accesibilidad, Monitorización de entrada", "⚠︎ Autoriser l'accès : Accessibilité, Surveillance de l’entrée", "⚠︎ Concedi l’accesso: Accessibilità, Monitoraggio input", "⚠︎ Conceder acesso: Acessibilidade, Monitoramento de entrada", "⚠︎ Erişim izni verin: Erişilebilirlik, Girdi İzleme", "⚠︎ Geef toegang: Toegankelijkheid, Invoercontrole (Input Monitoring)", "⚠︎ Udělte přístup: Zpřístupnění, Sledování vstupu", "⚠︎ Ge åtkomst: Hjälpmedel, Indataövervakning (Input Monitoring)", "⚠︎ Anna käyttöoikeus: Käyttöapu, Syötteen valvonta (Input Monitoring)", "⚠︎ Acordați acces: Accesibilitate, Monitorizare intrare (Input Monitoring)", "⚠︎ Hozzáférés megadása: Kisegítő lehetőségek, Bevitelfigyelés (Input Monitoring)", "⚠︎ Δώστε πρόσβαση: Προσβασιμότητα, Παρακολούθηση εισόδου (Input Monitoring)", "⚠︎ Дайте достъп: Достъпност, Input Monitoring", "⚠︎ תנו גישה: נגישות, ניטור קלט (Input Monitoring)", "⚠︎ امنح الوصول: تسهيلات الاستخدام، مراقبة الإدخال (Input Monitoring)", "⚠︎ अनुमति दें: सुलभता, इनपुट मॉनिटरिंग (Input Monitoring)", "⚠︎ 접근 권한 허용: 손쉬운 사용, 입력 모니터링", "⚠︎ Дайце доступ: Спецыяльныя магчымасці, Input Monitoring", "⚠︎ Рұқсат беріңіз: Арнайы мүмкіндіктер, Input Monitoring", "⚠︎ Мүмкүнчүлүк бериңиз: Атайын мүмкүнчүлүктөр, Input Monitoring", "⚠︎ მიეცით წვდომა: მისაწვდომობა, Input Monitoring", "⚠︎ Տվեք թույլտվություն՝ Հասանելիություն, Input Monitoring", "⚠︎ İcazə verin: Əlçatımlılıq, Input Monitoring", "⚠︎ Дозволите приступ: Приступачност, Input Monitoring", "⚠︎ Дозволете пристап: Пристапност, Input Monitoring", "⚠︎ Povoľte prístup: Zjednodušenie ovládania, Monitorovanie vstupu (Input Monitoring)", "⚠︎ Dopustite pristup: Pristupačnost, Praćenje unosa (Input Monitoring)", "⚠︎ Dovolite dostop: Dostopnost, Input Monitoring", "⚠︎ Suteikite prieigą: Pritaikymas neįgaliesiems, Input Monitoring", "⚠︎ Atļaujiet piekļuvi: Pieejamība, Input Monitoring", "⚠︎ Andke juurdepääs: Juurdepääsetavus, Input Monitoring", "⚠︎ Giv adgang: Tilgængelighed, Inputovervågning (Input Monitoring)", "⚠︎ Gi tilgang: Tilgjengelighet, Inndataovervåking (Input Monitoring)", "⚠︎ Veittu aðgang: Algildur aðgangur, Input Monitoring", "⚠︎ Jepni qasje: Përdorimi i lehtë, Input Monitoring", "⚠︎ دسترسی بدهید: دسترسی‌پذیری، Input Monitoring", "⚠︎ Cấp quyền: Trợ năng, Giám sát đầu vào (Input Monitoring)", "⚠︎ Дастрасӣ диҳед: Дастрасии универсалӣ, Input Monitoring", "⚠︎ Хандалт өгнө үү: Хүртээмж, Input Monitoring", "⚠︎ Кереп җитү рөхсәт итегез: Махсус мөмкинлекләр, Input Monitoring", "⚠︎ Ruxsat bering: Maxsus imkoniyatlar, Input Monitoring", "⚠︎ Tabhair rochtain: Inrochtaineacht, Input Monitoring", "⚠︎ Agħti aċċess: Aċċessibbiltà, Input Monitoring", "⚠︎ Rhowch fynediad: Hygyrchedd, Input Monitoring"],
    "app": ["App: ", "Програма: ", "Aplikacja: ", "App: ", "App: ", "App : ", "App: ", "App: ", "Uygulama: ", "App: ", "Aplikace: ", "App: ", "Ohjelma: ", "Aplicație: ", "Alkalmazás: ", "Εφαρμογή: ", "Програма: ", "יישום: ", "التطبيق: ", "ऐप: ", "앱: ", "Праграма: ", "Қолданба: ", "Колдонмо: ", "აპლიკაცია: ", "Հավելված՝ ", "Tətbiq: ", "Апликација: ", "Апликација: ", "Aplikácia: ", "Aplikacija: ", "Aplikacija: ", "Programa: ", "Lietotne: ", "Rakendus: ", "App: ", "App: ", "Forrit: ", "Aplikacioni: ", "برنامه: ", "Ứng dụng: ", "Барнома: ", "Апп: ", "Кушымта: ", "Ilova: ", "Aip: ", "Applikazzjoni: ", "Ap: "],
    "exclude": ["Don't work in this app", "Не працювати в цій програмі", "Nie działaj w tej aplikacji", "In dieser App nicht aktiv", "No funcionar en esta app", "Ne pas fonctionner dans cette app", "Disattiva in questa app", "Não funcionar nesta app", "Bu uygulamada çalışma", "Niet werken in deze app", "Nefungovat v této aplikaci", "Arbeta inte i den här appen", "Älä toimi tässä ohjelmassa", "Nu funcționa în această aplicație", "Ne működjön ebben az alkalmazásban", "Να μη λειτουργεί σε αυτή την εφαρμογή", "Да не работи в тази програма", "לא לפעול ביישום זה", "لا تعمل في هذا التطبيق", "इस ऐप में काम न करें", "이 앱에서 작동 안 함", "Не працаваць у гэтай праграме", "Бұл қолданбада жұмыс істемеу", "Бул колдонмодо иштебөө", "ამ აპლიკაციაში არ იმუშაოს", "Չաշխատել այս հավելվածում", "Bu tətbiqdə işləmə", "Не радити у овој апликацији", "Не работи во оваа апликација", "V tejto aplikácii nepracovať", "Ne radi u ovoj aplikaciji", "V tej aplikaciji ne delajte", "Šioje programoje nedirbti", "Šajā lietotnē nedarboties", "Selles rakenduses mitte töötada", "Deaktiver i denne app", "Ikke aktiv i denne appen", "Ekki virkt í þessu forriti", "Mos vepro në këtë aplikacion", "در این برنامه کار نکن", "Không hoạt động trong ứng dụng này", "Дар ин барнома кор накунед", "Энэ аппад ажиллахгүй", "Бу кушымтада эшләмәскә", "Bu ilovada ishlamasin", "Ná oibrigh san aip seo", "Taħdimx f’din l-applikazzjoni", "Peidio â gweithio yn yr ap hwn"],
    "game": ["Game — AURA paused", "Гра — AURA на паузі", "Gra — AURA wstrzymana", "Spiel — AURA pausiert", "Juego — AURA en pausa", "Jeu — AURA en pause", "Gioco — AURA in pausa", "Jogo — AURA em pausa", "Oyun — AURA duraklatıldı", "Game — AURA gepauzeerd", "Hra — AURA pozastavena", "Spel — AURA pausad", "Peli — AURA tauolla", "Joc — AURA în pauză", "Játék — AURA szüneteltetve", "Παιχνίδι — AURA σε παύση", "Игра — AURA е на пауза", "משחק — AURA מושהית", "لعبة — AURA متوقف مؤقتًا", "गेम — AURA रुका हुआ", "게임 — AURA 일시 중지됨", "Гульня — AURA на паўзе", "Ойын — AURA кідіртілді", "Оюн — AURA тыныгууда", "თამაში — AURA დაპაუზებულია", "Խաղ — AURA-ն դադարի վրա է", "Oyun — AURA fasilədədir", "Игра — AURA паузирана", "Игра — AURA паузирана", "Hra — AURA pozastavená", "Igra — AURA pauzirana", "Igra — AURA zaustavljena", "Žaidimas — AURA pristabdyta", "Spēle — AURA apturēta", "Mäng — AURA peatatud", "Spil — AURA på pause", "Spill — AURA er satt på pause", "Leikur — AURA í bið", "Lojë — AURA në pauzë", "بازی — AURA متوقف است", "Trò chơi — AURA tạm dừng", "Бозӣ — AURA таваққуф шудааст", "Тоглоом — AURA түр зогссон", "Уен — AURA туктатылган", "Oʻyin — AURA pauzada", "Cluiche — AURA ar sos", "Logħba — AURA fil-pawża", "Gêm — AURA wedi’i oedi"],
    "appLang": ["Language for this app", "Мова для цієї програми", "Język dla tej aplikacji", "Sprache für diese App", "Idioma para esta app", "Langue pour cette app", "Lingua per questa app", "Idioma para esta app", "Bu uygulama için dil", "Taal voor deze app", "Jazyk pro tuto aplikaci", "Språk för den här appen", "Kieli tälle ohjelmalle", "Limba pentru această aplicație", "Nyelv ehhez az alkalmazáshoz", "Γλώσσα για αυτή την εφαρμογή", "Език за тази програма", "שפה ליישום זה", "لغة هذا التطبيق", "इस ऐप की भाषा", "이 앱의 언어", "Мова для гэтай праграмы", "Осы қолданбаның тілі", "Бул колдонмонун тили", "ამ აპლიკაციის ენა", "Այս հավելվածի լեզուն", "Bu tətbiq üçün dil", "Језик за ову апликацију", "Јазик за оваа апликација", "Jazyk pre túto aplikáciu", "Jezik za ovu aplikaciju", "Jezik za to aplikacijo", "Kalba šiai programai", "Valoda šai lietotnei", "Selle rakenduse keel", "Sprog for denne app", "Språk for denne appen", "Tungumál fyrir þetta forrit", "Gjuha për këtë aplikacion", "زبان این برنامه", "Ngôn ngữ cho ứng dụng này", "Забон барои ин барнома", "Энэ аппын хэл", "Бу кушымта өчен тел", "Bu ilova uchun til", "Teanga don aip seo", "Lingwa għal din l-applikazzjoni", "Iaith ar gyfer yr ap hwn"],
    "noBinding": ["No binding", "Без прив'язки", "Bez przypisania", "Keine Zuordnung", "Sin asignación", "Aucune association", "Nessuna associazione", "Sem associação", "Atama yok", "Geen koppeling", "Bez přiřazení", "Ingen koppling", "Ei liitosta", "Fără asociere", "Nincs hozzárendelés", "Χωρίς αντιστοίχιση", "Без обвързване", "ללא שיוך", "بدون ربط", "कोई बंधन नहीं", "지정 안 함", "Без прывязкі", "Байланыссыз", "Байланышсыз", "მიბმის გარეშე", "Առանց կապակցման", "Bağlama yoxdur", "Без повезивања", "Без врзување", "Bez priradenia", "Bez povezivanja", "Brez povezave", "Be priskyrimo", "Bez piesaistes", "Seostamata", "Ingen tilknytning", "Ingen kobling", "Engin tenging", "Pa lidhje", "بدون اتصال", "Chưa gán", "Бе пайвастшавӣ", "Холбоогүй", "Бәйләнешсез", "Bogʻlanmagan", "Gan nasc", "L-ebda rabta", "Dim cysylltiad"],
    "exclusions": ["Exclusions", "Винятки", "Wyjątki", "Ausnahmen", "Excepciones", "Exceptions", "Esclusioni", "Exceções", "İstisnalar", "Uitzonderingen", "Výjimky", "Undantag", "Poikkeukset", "Excepții", "Kivételek", "Εξαιρέσεις", "Изключения", "חריגים", "الاستثناءات", "अपवाद", "예외", "Выключэнні", "Ерекшеліктер", "Өзгөчөлүктөр", "გამონაკლისები", "Բացառություններ", "İstisnalar", "Изузеци", "Исклучоци", "Výnimky", "Iznimke", "Izjeme", "Išimtys", "Izņēmumi", "Erandid", "Undtagelser", "Unntak", "Undantekningar", "Përjashtime", "استثناها", "Ngoại lệ", "Истисноҳо", "Үл хамаарах зүйлс", "Аерымлыклар", "Istisnolar", "Eisceachtaí", "Eċċezzjonijiet", "Eithriadau"],
    "recent": ["Don't work in (recent apps)", "Не працювати в (останні програми)", "Nie działaj w (ostatnie aplikacje)", "Nicht aktiv in (letzte Apps)", "No funcionar en (apps recientes)", "Ne pas fonctionner dans (apps récentes)", "Disattiva in (app recenti)", "Não funcionar em (apps recentes)", "Şurada çalışma (son uygulamalar)", "Niet werken in (recente apps)", "Nefungovat v (nedávné aplikace)", "Arbeta inte i (senaste appar)", "Älä toimi ohjelmassa (viimeisimmät)", "Nu funcționa în (aplicații recente)", "Ne működjön itt (legutóbbi alkalmazások)", "Να μη λειτουργεί σε (πρόσφατες εφαρμογές)", "Да не работи в (последни програми)", "לא לפעול ב (יישומים אחרונים)", "لا تعمل في (التطبيقات الأخيرة)", "इनमें काम न करें (हाल के ऐप)", "작동 안 함 (최근 앱)", "Не працаваць у (нядаўнія праграмы)", "Мында жұмыс істемеу (соңғы қолданбалар)", "Төмөндө иштебөө (акыркы колдонмолор)", "არ იმუშაოს (ბოლო აპლიკაციები)", "Չաշխատել (վերջին հավելվածներ)", "Burada işləmə (son tətbiqlər)", "Не радити у (недавне апликације)", "Не работи во (неодамнешни апликации)", "Nepracovať v (nedávne aplikácie)", "Ne radi u (nedavne aplikacije)", "Ne delajte v (nedavne aplikacije)", "Nedirbti (naujausios programos)", "Nedarboties (nesenās lietotnes)", "Mitte töötada (hiljutised rakendused)", "Deaktiver i (seneste apps)", "Ikke aktiv i (nylige apper)", "Ekki virkt í (nýleg forrit)", "Mos vepro në (aplikacionet e fundit)", "در این‌ها کار نکن (برنامه‌های اخیر)", "Không hoạt động trong (ứng dụng gần đây)", "Кор накунед дар (барномаҳои охирин)", "Ажиллахгүй (сүүлийн аппууд)", "Эшләмәскә (соңгы кушымталар)", "Ishlamasin (soʻnggi ilovalar)", "Ná oibrigh i (aipeanna le déanaí)", "Taħdimx fi (applikazzjonijiet reċenti)", "Peidio â gweithio yn (apiau diweddar)"],
    "bindings": ["Language bindings", "Прив'язки мов", "Przypisania języków", "Sprachzuordnungen", "Idiomas asignados", "Langues associées", "Lingue associate", "Idiomas associados", "Dil atamaları", "Taalkoppelingen", "Přiřazení jazyků", "Språkkopplingar", "Kieliliitokset", "Limbi asociate", "Nyelvi hozzárendelések", "Αντιστοιχίσεις γλωσσών", "Обвързани езици", "שיוכי שפה", "ربط اللغات", "भाषा बंधन", "언어 지정", "Прывязкі моў", "Тіл байланыстары", "Тил байланыштары", "ენების მიბმა", "Լեզուների կապակցումներ", "Dil bağlamaları", "Повезивање језика", "Врзувања на јазици", "Priradenia jazykov", "Povezivanja jezika", "Povezave jezikov", "Kalbų priskyrimai", "Valodu piesaistes", "Keeleseosed", "Sprogtilknytninger", "Språkkoblinger", "Tungumálatengingar", "Lidhjet e gjuhëve", "اتصال زبان‌ها", "Gán ngôn ngữ", "Пайвасткунии забонҳо", "Хэлний холболтууд", "Телләр бәйләнеше", "Til bogʻlanishlari", "Naisc teanga", "Rabtiet tal-lingwi", "Cysylltiadau iaith"],
    "empty": ["Empty", "Порожньо", "Pusto", "Leer", "Vacío", "Vide", "Vuoto", "Vazio", "Boş", "Leeg", "Prázdné", "Tomt", "Tyhjä", "Gol", "Üres", "Κενό", "Празно", "ריק", "فارغ", "खाली", "비어 있음", "Пуста", "Бос", "Бош", "ცარიელია", "Դատարկ է", "Boşdur", "Празно", "Празно", "Prázdne", "Prazno", "Prazno", "Tuščia", "Tukšs", "Tühi", "Tom", "Tom", "Tómt", "Bosh", "خالی", "Trống", "Холӣ", "Хоосон", "Буш", "Boʻsh", "Folamh", "Vojt", "Gwag"],
    "login": ["Launch at login", "Запускати під час входу", "Uruchamiaj przy logowaniu", "Bei Anmeldung starten", "Abrir al iniciar sesión", "Ouvrir à la connexion", "Apri al login", "Abrir ao iniciar sessão", "Oturum açılışında başlat", "Starten bij inloggen", "Spouštět po přihlášení", "Starta vid inloggning", "Käynnistä kirjautuessa", "Pornește la autentificare", "Indítás bejelentkezéskor", "Εκκίνηση κατά τη σύνδεση", "Стартиране при вход", "הפעלה בעת התחברות", "التشغيل عند تسجيل الدخول", "लॉगिन पर शुरू करें", "로그인 시 실행", "Запускаць пры ўваходзе", "Кіргенде іске қосу", "Кирүүдө иштетүү", "გაშვება შესვლისას", "Գործարկել մուտքի ժամանակ", "Girişdə başlat", "Покрени при пријави", "Стартувај при најава", "Spúšťať po prihlásení", "Pokreni pri prijavi", "Zaženi ob prijavi", "Paleisti prisijungiant", "Palaist pieteikšanās brīdī", "Käivita sisselogimisel", "Start ved login", "Start ved innlogging", "Ræsa við innskráningu", "Hap në hyrje", "اجرا هنگام ورود", "Chạy khi đăng nhập", "Оғоз ҳангоми воридшавӣ", "Нэвтрэхэд эхлүүлэх", "Керүдә эшләтеп җибәрергә", "Kirishda ishga tushirish", "Seol ag logáil isteach", "Ibda mad-dħul", "Cychwyn wrth fewngofnodi"],
    "words": ["My words…", "Мої слова…", "Moje słowa…", "Meine Wörter…", "Mis palabras…", "Mes mots…", "Le mie parole…", "As minhas palavras…", "Kelimelerim…", "Mijn woorden…", "Moje slova…", "Mina ord…", "Omat sanat…", "Cuvintele mele…", "Saját szavak…", "Οι λέξεις μου…", "Моите думи…", "המילים שלי…", "كلماتي…", "मेरे शब्द…", "내 단어…", "Мае словы…", "Менің сөздерім…", "Менин сөздөрүм…", "ჩემი სიტყვები…", "Իմ բառերը…", "Mənim sözlərim…", "Моје речи…", "Моите зборови…", "Moje slová…", "Moje riječi…", "Moje besede…", "Mano žodžiai…", "Mani vārdi…", "Minu sõnad…", "Mine ord…", "Mine ord…", "Mín orð…", "Fjalët e mia…", "واژه‌های من…", "Từ của tôi…", "Калимаҳои ман…", "Миний үгс…", "Минем сүзләр…", "Mening soʻzlarim…", "Mo chuid focal…", "Kliemi…", "Fy ngeiriau…"],
    "save": ["Save", "Зберегти", "Zapisz", "Sichern", "Guardar", "Enregistrer", "Salva", "Guardar", "Kaydet", "Bewaar", "Uložit", "Spara", "Tallenna", "Salvează", "Mentés", "Αποθήκευση", "Запази", "שמירה", "حفظ", "सहेजें", "저장", "Захаваць", "Сақтау", "Сактоо", "შენახვა", "Պահպանել", "Saxla", "Сачувај", "Зачувај", "Uložiť", "Spremi", "Shrani", "Išsaugoti", "Saglabāt", "Salvesta", "Gem", "Lagre", "Vista", "Ruaj", "ذخیره", "Lưu", "Захира кардан", "Хадгалах", "Саклау", "Saqlash", "Sábháil", "Salva", "Cadw"],
    "cancel": ["Cancel", "Скасувати", "Anuluj", "Abbrechen", "Cancelar", "Annuler", "Annulla", "Cancelar", "İptal", "Annuleer", "Zrušit", "Avbryt", "Kumoa", "Anulează", "Mégse", "Ακύρωση", "Отказ", "ביטול", "إلغاء", "रद्द करें", "취소", "Скасаваць", "Бас тарту", "Жокко чыгаруу", "გაუქმება", "Չեղարկել", "Ləğv et", "Откажи", "Откажи", "Zrušiť", "Odustani", "Prekliči", "Atšaukti", "Atcelt", "Tühista", "Annuller", "Avbryt", "Hætta við", "Anulo", "لغو", "Hủy", "Бекор кардан", "Цуцлах", "Баш тарту", "Bekor qilish", "Cealaigh", "Ikkanċella", "Diddymu"],
    "uiLang": ["Menu language", "Мова меню", "Język menu", "Menüsprache", "Idioma del menú", "Langue du menu", "Lingua del menu", "Idioma do menu", "Menü dili", "Menutaal", "Jazyk nabídky", "Menyspråk", "Valikon kieli", "Limba meniului", "Menü nyelve", "Γλώσσα μενού", "Език на менюто", "שפת התפריט", "لغة القائمة", "मेनू की भाषा", "메뉴 언어", "Мова меню", "Мәзір тілі", "Меню тили", "მენიუს ენა", "Ցանկի լեզուն", "Menyu dili", "Језик менија", "Јазик на менито", "Jazyk ponuky", "Jezik izbornika", "Jezik menija", "Meniu kalba", "Izvēlnes valoda", "Menüü keel", "Menusprog", "Menyspråk", "Tungumál valmyndar", "Gjuha e menysë", "زبان منو", "Ngôn ngữ menu", "Забони меню", "Цэсний хэл", "Меню теле", "Menyu tili", "Teanga an roghchláir", "Lingwa tal-menu", "Iaith y ddewislen"],
    "allLangs": ["All languages", "Усі мови", "Wszystkie języki", "Alle Sprachen", "Todos los idiomas", "Toutes les langues", "Tutte le lingue", "Todos os idiomas", "Tüm diller", "Alle talen", "Všechny jazyky", "Alla språk", "Kaikki kielet", "Toate limbile", "Minden nyelv", "Όλες οι γλώσσες", "Всички езици", "כל השפות", "كل اللغات", "सभी भाषाएँ", "모든 언어", "Усе мовы", "Барлық тілдер", "Бардык тилдер", "ყველა ენა", "Բոլոր լեզուները", "Bütün dillər", "Сви језици", "Сите јазици", "Všetky jazyky", "Svi jezici", "Vsi jeziki", "Visos kalbos", "Visas valodas", "Kõik keeled", "Alle sprog", "Alle språk", "Öll tungumál", "Të gjitha gjuhët", "همه زبان‌ها", "Tất cả ngôn ngữ", "Ҳамаи забонҳо", "Бүх хэл", "Барлык телләр", "Barcha tillar", "Gach teanga", "Il-lingwi kollha", "Pob iaith"],
    "regEurope": ["Europe", "Європа", "Europa", "Europa", "Europa", "Europe", "Europa", "Europa", "Avrupa", "Europa", "Evropa", "Europa", "Eurooppa", "Europa", "Európa", "Ευρώπη", "Европа", "אירופה", "أوروبا", "यूरोप", "유럽", "Еўропа", "Еуропа", "Европа", "ევროპა", "Եվրոպա", "Avropa", "Европа", "Европа", "Európa", "Europa", "Evropa", "Europa", "Eiropa", "Euroopa", "Europa", "Europa", "Evrópa", "Evropa", "اروپا", "Châu Âu", "Аврупо", "Европ", "Европа", "Yevropa", "An Eoraip", "Ewropa", "Ewrop"],
    "regCaucasus": ["Caucasus & Central Asia", "Кавказ і Центральна Азія", "Kaukaz i Azja Środkowa", "Kaukasus und Zentralasien", "Cáucaso y Asia Central", "Caucase et Asie centrale", "Caucaso e Asia centrale", "Cáucaso e Ásia Central", "Kafkasya ve Orta Asya", "Kaukasus en Centraal-Azië", "Kavkaz a Střední Asie", "Kaukasus och Centralasien", "Kaukasia ja Keski-Aasia", "Caucaz și Asia Centrală", "Kaukázus és Közép-Ázsia", "Καύκασος και Κεντρική Ασία", "Кавказ и Централна Азия", "הקווקז ומרכז אסיה", "القوقاز وآسيا الوسطى", "काकेशस और मध्य एशिया", "캅카스·중앙아시아", "Каўказ і Цэнтральная Азія", "Кавказ және Орталық Азия", "Кавказ жана Борбордук Азия", "კავკასია და ცენტრალური აზია", "Կովկաս և Կենտրոնական Ասիա", "Qafqaz və Mərkəzi Asiya", "Кавказ и Централна Азија", "Кавказ и Централна Азија", "Kaukaz a Stredná Ázia", "Kavkaz i Srednja Azija", "Kavkaz in Srednja Azija", "Kaukazas ir Vidurio Azija", "Kaukāzs un Centrālāzija", "Kaukaasia ja Kesk-Aasia", "Kaukasus og Centralasien", "Kaukasus og Sentral-Asia", "Kákasus og Mið-Asía", "Kaukazi dhe Azia Qendrore", "قفقاز و آسیای مرکزی", "Kavkaz và Trung Á", "Қафқоз ва Осиёи Марказӣ", "Кавказ ба Төв Ази", "Кавказ һәм Үзәк Азия", "Kavkaz va Markaziy Osiyo", "An Chugais agus an Áise Láir", "Il-Kawkasu u l-Asja Ċentrali", "Y Cawcasws a Chanolbarth Asia"],
    "regMiddleEast": ["Middle East", "Близький Схід", "Bliski Wschód", "Naher Osten", "Oriente Medio", "Moyen-Orient", "Medio Oriente", "Médio Oriente", "Orta Doğu", "Midden-Oosten", "Blízký východ", "Mellanöstern", "Lähi-itä", "Orientul Mijlociu", "Közel-Kelet", "Μέση Ανατολή", "Близкия изток", "המזרח התיכון", "الشرق الأوسط", "मध्य पूर्व", "중동", "Блізкі Усход", "Таяу Шығыс", "Жакынкы Чыгыш", "ახლო აღმოსავლეთი", "Մերձավոր Արևելք", "Yaxın Şərq", "Блиски исток", "Блиски Исток", "Blízky východ", "Bliski istok", "Bližnji vzhod", "Artimieji Rytai", "Tuvie Austrumi", "Lähis-Ida", "Mellemøsten", "Midtøsten", "Mið-Austurlönd", "Lindja e Mesme", "خاورمیانه", "Trung Đông", "Шарқи Наздик", "Ойрхи Дорнод", "Якын Көнчыгыш", "Yaqin Sharq", "An Mheánoirthear", "Il-Lvant Nofsani", "Y Dwyrain Canol"],
    "regAsia": ["Asia", "Азія", "Azja", "Asien", "Asia", "Asie", "Asia", "Ásia", "Asya", "Azië", "Asie", "Asien", "Aasia", "Asia", "Ázsia", "Ασία", "Азия", "אסיה", "آسيا", "एशिया", "아시아", "Азія", "Азия", "Азия", "აზია", "Ասիա", "Asiya", "Азија", "Азија", "Ázia", "Azija", "Azija", "Azija", "Āzija", "Aasia", "Asien", "Asia", "Asía", "Azia", "آسیا", "Châu Á", "Осиё", "Ази", "Азия", "Osiyo", "An Áise", "L-Asja", "Asia"],
    "system": ["System", "Системна", "Systemowy", "System", "Sistema", "Système", "Sistema", "Sistema", "Sistem", "Systeem", "Systémový", "System", "Järjestelmä", "Sistem", "Rendszer", "Συστήματος", "Системен", "מערכת", "النظام", "सिस्टम", "시스템", "Сістэмная", "Жүйелік", "Системалык", "სისტემური", "Համակարգային", "Sistem", "Системски", "Системски", "Systémový", "Sustavski", "Sistemski", "Sistemos", "Sistēmas", "Süsteemne", "System", "System", "Kerfið", "Sistemi", "سیستم", "Hệ thống", "Система", "Систем", "Система", "Tizim", "Córas", "Sistema", "System"],
    "hint": ["Double ⇧ — convert word/selection", "Подвійний ⇧ — змінити мову слова/виділення", "Podwójny ⇧ — zmień układ słowa/zaznaczenia", "Doppel-⇧ — Wort/Auswahl umwandeln", "Doble ⇧ — convertir palabra/selección", "Double ⇧ — convertir le mot/la sélection", "Doppio ⇧ — converti parola o selezione", "Duplo ⇧ — converter palavra/seleção", "Çift ⇧ — kelimeyi/seçimi dönüştür", "Dubbel ⇧ — woord/selectie omzetten", "Dvojitý ⇧ — převést slovo/výběr", "Dubbel-⇧ — konvertera ord/markering", "Kaksois-⇧ — muunna sana/valinta", "Dublu ⇧ — convertește cuvântul/selecția", "Dupla ⇧ — szó/kijelölés átalakítása", "Διπλό ⇧ — μετατροπή λέξης/επιλογής", "Двоен ⇧ — смяна на езика на дума/селекция", "⇧ כפול — המרת מילה/בחירה", "⇧ مزدوج — تحويل الكلمة/التحديد", "दो बार ⇧ — शब्द/चयन बदलें", "⇧ 두 번 — 단어/선택 영역 변환", "Падвойны ⇧ — змяніць мову слова/вылучэння", "Қос ⇧ — сөзді/таңдалғанды түрлендіру", "Кош ⇧ — сөздү/тандалганды өзгөртүү", "ორმაგი ⇧ — სიტყვის/მონიშნულის გადაყვანა", "Կրկնակի ⇧ — փոխարկել բառը/նշվածը", "Qoşa ⇧ — sözü/seçilmişi çevir", "Двоструки ⇧ — претвори реч/избор", "Двоен ⇧ — претвори збор/избор", "Dvojitý ⇧ — previesť slovo/výber", "Dvostruki ⇧ — pretvori riječ/odabir", "Dvojni ⇧ — pretvori besedo/izbor", "Dvigubas ⇧ — konvertuoti žodį/pažymėtą tekstą", "Dubults ⇧ — pārvērst vārdu/atlasi", "Topelt ⇧ — teisenda sõna/valik", "Dobbelt ⇧ — konvertér ord/markering", "Dobbel ⇧ — konverter ord/markering", "Tvöfalt ⇧ — umbreyta orði/vali", "Dyfishi ⇧ — konverto fjalën/përzgjedhjen", "دوبار ⇧ — تبدیل واژه/انتخاب", "Nhấn đôi ⇧ — chuyển đổi từ/vùng chọn", "Дукарата ⇧ — табдили калима/интихоб", "Давхар ⇧ — үг/сонголтыг хөрвүүлэх", "Икеләтә ⇧ — сүзне/сайланганны әйләндерү", "Ikki marta ⇧ — soʻz/belgilashni aylantirish", "⇧ faoi dhó — tiontaigh focal/roghnúchán", "⇧ doppju — ikkonverti kelma/għażla", "⇧ dwbl — trosi gair/dewisiad"],
    "report": ["Report a problem…", "Повідомити про проблему…", "Zgłoś problem…", "Problem melden…", "Informar de un problema…", "Signaler un problème…", "Segnala un problema…", "Comunicar um problema…", "Sorun bildir…", "Probleem melden…", "Nahlásit problém…", "Rapportera ett problem…", "Ilmoita ongelmasta…", "Raportează o problemă…", "Probléma bejelentése…", "Αναφορά προβλήματος…", "Съобщете за проблем…", "דיווח על בעיה…", "الإبلاغ عن مشكلة…", "समस्या बताएँ…", "문제 신고…", "Паведаміць пра праблему…", "Мәселе туралы хабарлау…", "Көйгөй тууралуу кабарлоо…", "პრობლემის შეტყობინება…", "Հաղորդել խնդրի մասին…", "Problem barədə bildir…", "Пријави проблем…", "Пријави проблем…", "Nahlásiť problém…", "Prijavi problem…", "Prijavi težavo…", "Pranešti apie problemą…", "Ziņot par problēmu…", "Teata probleemist…", "Rapportér et problem…", "Rapporter et problem…", "Tilkynna vandamál…", "Raporto një problem…", "گزارش مشکل…", "Báo cáo sự cố…", "Хабар додан дар бораи мушкилот…", "Асуудлын талаар мэдээлэх…", "Проблема турында хәбәр итү…", "Muammo haqida xabar berish…", "Tuairiscigh fadhb…", "Irrapporta problema…", "Adrodd am broblem…"],
    "reportBody": ["What happened and in which app:", "Що сталося і в якій програмі:", "Co się stało i w jakiej aplikacji:", "Was ist passiert und in welcher App:", "Qué pasó y en qué app:", "Ce qui s'est passé et dans quelle app :", "Cosa è successo e in quale app:", "O que aconteceu e em que app:", "Ne oldu ve hangi uygulamada:", "Wat er gebeurde en in welke app:", "Co se stalo a v jaké aplikaci:", "Vad hände och i vilken app:", "Mitä tapahtui ja missä ohjelmassa:", "Ce s-a întâmplat și în ce aplicație:", "Mi történt és melyik alkalmazásban:", "Τι συνέβη και σε ποια εφαρμογή:", "Какво се случи и в коя програма:", "מה קרה ובאיזה יישום:", "ماذا حدث وفي أي تطبيق:", "क्या हुआ और किस ऐप में:", "무슨 일이 어느 앱에서 있었나요:", "Што здарылася і ў якой праграме:", "Не болды және қай қолданбада:", "Эмне болду жана кайсы колдонмодо:", "რა მოხდა და რომელ აპლიკაციაში:", "Ինչ է պատահել և որ հավելվածում՝", "Nə baş verdi və hansı tətbiqdə:", "Шта се догодило и у којој апликацији:", "Што се случи и во која апликација:", "Čo sa stalo a v ktorej aplikácii:", "Što se dogodilo i u kojoj aplikaciji:", "Kaj se je zgodilo in v kateri aplikaciji:", "Kas nutiko ir kurioje programoje:", "Kas notika un kurā lietotnē:", "Mis juhtus ja millises rakenduses:", "Hvad skete der, og i hvilken app:", "Hva skjedde, og i hvilken app:", "Hvað gerðist og í hvaða forriti:", "Çfarë ndodhi dhe në cilin aplikacion:", "چه اتفاقی افتاد و در کدام برنامه:", "Chuyện gì đã xảy ra và trong ứng dụng nào:", "Чӣ шуд ва дар кадом барнома:", "Юу болсон, ямар аппад:", "Нәрсә булды һәм кайсы кушымтада:", "Nima boʻldi va qaysi ilovada:", "Cad a tharla agus in cén aip:", "X’ġara u f’liema applikazzjoni:", "Beth ddigwyddodd ac ym mha ap:"],
    "update": ["Check for updates…", "Перевірити оновлення…", "Sprawdź aktualizacje…", "Nach Updates suchen…", "Buscar actualizaciones…", "Rechercher des mises à jour…", "Controlla aggiornamenti…", "Procurar atualizações…", "Güncellemeleri denetle…", "Zoek naar updates…", "Zkontrolovat aktualizace…", "Sök efter uppdateringar…", "Tarkista päivitykset…", "Caută actualizări…", "Frissítések keresése…", "Έλεγχος για ενημερώσεις…", "Проверка за актуализации…", "בדיקת עדכונים…", "التحقق من التحديثات…", "अपडेट जाँचें…", "업데이트 확인…", "Праверыць абнаўленні…", "Жаңартуларды тексеру…", "Жаңыртууларды текшерүү…", "განახლებების შემოწმება…", "Ստուգել թարմացումները…", "Yeniləmələri yoxla…", "Провери ажурирања…", "Провери за ажурирања…", "Skontrolovať aktualizácie…", "Provjeri ažuriranja…", "Preverite posodobitve…", "Tikrinti naujinimus…", "Meklēt atjauninājumus…", "Otsi uuendusi…", "Søg efter opdateringer…", "Se etter oppdateringer…", "Athuga með uppfærslur…", "Kontrollo për përditësime…", "بررسی به‌روزرسانی…", "Kiểm tra cập nhật…", "Санҷиши навсозиҳо…", "Шинэчлэлт шалгах…", "Яңартуларны тикшерү…", "Yangilanishlarni tekshirish…", "Seiceáil le haghaidh nuashonruithe…", "Iċċekkja għal aġġornamenti…", "Gwirio am ddiweddariadau…"],
    "updateDue": ["⬆︎ An update may be available — check", "⬆︎ Можливо, вийшло оновлення — перевірити", "⬆︎ Może być dostępna aktualizacja — sprawdź", "⬆︎ Möglicherweise gibt es ein Update — prüfen", "⬆︎ Puede haber una actualización — comprobar", "⬆︎ Une mise à jour est peut-être disponible — vérifier", "⬆︎ Potrebbe essere disponibile un aggiornamento — verifica", "⬆︎ Pode haver uma atualização — verificar", "⬆︎ Güncelleme olabilir — denetle", "⬆︎ Er is misschien een update — controleren", "⬆︎ Možná je k dispozici aktualizace — zkontrolovat", "⬆︎ Det kan finnas en uppdatering — kontrollera", "⬆︎ Päivitys saattaa olla saatavilla — tarkista", "⬆︎ Poate există o actualizare — verifică", "⬆︎ Lehet, hogy van frissítés — ellenőrzés", "⬆︎ Ίσως υπάρχει ενημέρωση — έλεγχος", "⬆︎ Може да има актуализация — проверете", "⬆︎ ייתכן שיש עדכון — בדיקה", "⬆︎ قد يتوفر تحديث — تحقّق", "⬆︎ शायद नया अपडेट आया है — जाँचें", "⬆︎ 업데이트가 있을 수 있습니다 — 확인", "⬆︎ Магчыма, выйшла абнаўленне — праверыць", "⬆︎ Жаңарту шыққан болуы мүмкін — тексеру", "⬆︎ Жаңыртуу чыгып калышы мүмкүн — текшерүү", "⬆︎ შესაძლოა განახლება გამოვიდა — შეამოწმეთ", "⬆︎ Հնարավոր է՝ թարմացում է թողարկվել — ստուգել", "⬆︎ Yeniləmə çıxmış ola bilər — yoxlayın", "⬆︎ Можда је изашло ажурирање — провери", "⬆︎ Можеби има ново ажурирање — провери", "⬆︎ Možno vyšla aktualizácia — skontrolovať", "⬆︎ Možda je izašlo ažuriranje — provjeri", "⬆︎ Morda je izšla posodobitev — preverite", "⬆︎ Galbūt išleistas naujinimas — patikrinkite", "⬆︎ Iespējams, iznācis atjauninājums — pārbaudīt", "⬆︎ Uuendus võib olla saadaval — kontrolli", "⬆︎ Der kan være en opdatering — tjek", "⬆︎ En oppdatering kan være tilgjengelig — sjekk", "⬆︎ Uppfærsla gæti verið tiltæk — athuga", "⬆︎ Mund të ketë një përditësim — kontrollo", "⬆︎ ممکن است به‌روزرسانی موجود باشد — بررسی کنید", "⬆︎ Có thể có bản cập nhật — kiểm tra", "⬆︎ Шояд навсозӣ мавҷуд бошад — санҷед", "⬆︎ Шинэчлэлт байж магадгүй — шалгах", "⬆︎ Яңарту булырга мөмкин — тикшерегез", "⬆︎ Yangilanish boʻlishi mumkin — tekshiring", "⬆︎ B’fhéidir go bhfuil nuashonrú ar fáil — seiceáil", "⬆︎ Jista’ jkun hemm aġġornament — iċċekkja", "⬆︎ Efallai bod diweddariad ar gael — gwiriwch"],
    "donate": ["Support AURA Switcher ☕", "Підтримати AURA Switcher ☕", "Wesprzyj AURA Switcher ☕", "AURA Switcher unterstützen ☕", "Apoyar AURA Switcher ☕", "Soutenir AURA Switcher ☕", "Sostieni AURA Switcher ☕", "Apoiar o AURA Switcher ☕", "AURA Switcher'ı destekle ☕", "Steun AURA Switcher ☕", "Podpořit AURA Switcher ☕", "Stöd AURA Switcher ☕", "Tue AURA Switcheriä ☕", "Susține AURA Switcher ☕", "Az AURA Switcher támogatása ☕", "Υποστηρίξτε το AURA Switcher ☕", "Подкрепете AURA Switcher ☕", "תמכו ב-AURA Switcher ☕", "ادعم AURA Switcher ☕", "AURA Switcher का समर्थन करें ☕", "AURA Switcher 후원하기 ☕", "Падтрымаць AURA Switcher ☕", "AURA Switcher жобасын қолдау ☕", "AURA Switcher долбоорун колдоо ☕", "AURA Switcher-ის მხარდაჭერა ☕", "Աջակցել AURA Switcher-ին ☕", "AURA Switcher-i dəstəkləyin ☕", "Подржи AURA Switcher ☕", "Поддржи го AURA Switcher ☕", "Podporiť AURA Switcher ☕", "Podrži AURA Switcher ☕", "Podpri AURA Switcher ☕", "Paremti AURA Switcher ☕", "Atbalstīt AURA Switcher ☕", "Toeta AURA Switcherit ☕", "Støt AURA Switcher ☕", "Støtt AURA Switcher ☕", "Styðja AURA Switcher ☕", "Mbështet AURA Switcher ☕", "حمایت از AURA Switcher ☕", "Ủng hộ AURA Switcher ☕", "Дастгирии AURA Switcher ☕", "AURA Switcher-ийг дэмжих ☕", "AURA Switcher'ны хупларга ☕", "AURA Switcher’ni qoʻllab-quvvatlash ☕", "Tacaigh le AURA Switcher ☕", "Appoġġa lil AURA Switcher ☕", "Cefnogi AURA Switcher ☕"],
    "quit": ["Quit", "Вихід", "Zakończ", "Beenden", "Salir", "Quitter", "Esci", "Sair", "Çık", "Stop", "Ukončit", "Avsluta", "Lopeta", "Ieșire", "Kilépés", "Έξοδος", "Изход", "יציאה", "إنهاء", "बंद करें", "종료", "Выхад", "Шығу", "Чыгуу", "გასვლა", "Ելք", "Çıxış", "Изађи", "Излези", "Ukončiť", "Izađi", "Končaj", "Išeiti", "Iziet", "Välju", "Afslut", "Avslutt", "Hætta", "Mbyll", "خروج", "Thoát", "Баромадан", "Гарах", "Чыгу", "Chiqish", "Scoir", "Ieqaf", "Gadael"],
    "updNew": ["AURA Switcher {v} is out", "Вийшла AURA Switcher {v}", "Wyszła AURA Switcher {v}", "AURA Switcher {v} ist da", "Ya está aquí AURA Switcher {v}", "AURA Switcher {v} est sortie", "È disponibile AURA Switcher {v}", "Saiu o AURA Switcher {v}", "AURA Switcher {v} çıktı", "AURA Switcher {v} is uit", "Vyšel AURA Switcher {v}", "AURA Switcher {v} är här", "AURA Switcher {v} on julkaistu", "A apărut AURA Switcher {v}", "Megjelent az AURA Switcher {v}", "Κυκλοφόρησε το AURA Switcher {v}", "Излезе AURA Switcher {v}", "יצאה AURA Switcher {v}", "صدر AURA Switcher {v}", "AURA Switcher {v} आ गया है", "AURA Switcher {v} 출시", "Выйшла AURA Switcher {v}", "AURA Switcher {v} шықты", "AURA Switcher {v} чыкты", "გამოვიდა AURA Switcher {v}", "Թողարկվել է AURA Switcher {v}", "AURA Switcher {v} çıxdı", "Изашао је AURA Switcher {v}", "Излезе AURA Switcher {v}", "Vyšiel AURA Switcher {v}", "Izašao je AURA Switcher {v}", "Izšel je AURA Switcher {v}", "Išleistas AURA Switcher {v}", "Iznācis AURA Switcher {v}", "AURA Switcher {v} on väljas", "AURA Switcher {v} er udkommet", "AURA Switcher {v} er ute", "AURA Switcher {v} er komið út", "AURA Switcher {v} doli", "AURA Switcher {v} منتشر شد", "AURA Switcher {v} đã ra mắt", "AURA Switcher {v} баромад", "AURA Switcher {v} гарлаа", "AURA Switcher {v} чыкты", "AURA Switcher {v} chiqdi", "Tá AURA Switcher {v} amuigh", "AURA Switcher {v} ħareġ", "Mae AURA Switcher {v} allan"],
    "updLatest": ["You have the latest version", "У вас остання версія", "Masz najnowszą wersję", "Du hast die neueste Version", "Tienes la última versión", "Vous avez la dernière version", "Hai l’ultima versione", "Tem a versão mais recente", "En son sürümü kullanıyorsunuz", "Je hebt de nieuwste versie", "Máte nejnovější verzi", "Du har den senaste versionen", "Sinulla on uusin versio", "Ai cea mai nouă versiune", "A legújabb verzió van nálad", "Έχετε την τελευταία έκδοση", "Имате най-новата версия", "יש לכם את הגרסה העדכנית", "لديك أحدث إصدار", "आपके पास नवीनतम संस्करण है", "최신 버전을 사용 중입니다", "У вас апошняя версія", "Сізде соңғы нұсқа бар", "Сизде акыркы версия бар", "გაქვთ უახლესი ვერსია", "Դուք ունեք վերջին տարբերակը", "Ən son versiya sizdədir", "Имате најновију верзију", "Ја имате најновата верзија", "Máte najnovšiu verziu", "Imate najnoviju verziju", "Imate najnovejšo različico", "Turite naujausią versiją", "Jums ir jaunākā versija", "Sul on uusim versioon", "Du har den nyeste version", "Du har den nyeste versjonen", "Þú ert með nýjustu útgáfuna", "Keni versionin më të ri", "جدیدترین نسخه را دارید", "Bạn đang dùng phiên bản mới nhất", "Шумо навтарин версияро доред", "Танд хамгийн сүүлийн хувилбар байна", "Сездә иң соңгы версия", "Sizda eng soʻnggi versiya bor", "Tá an leagan is déanaí agat", "Għandek l-aħħar verżjoni", "Mae gennych y fersiwn ddiweddaraf"],
    "updNotes": ["What's new", "Що нового", "Co nowego", "Was ist neu", "Novedades", "Nouveautés", "Novità", "Novidades", "Yenilikler", "Wat is er nieuw", "Co je nového", "Nyheter", "Uutta", "Ce e nou", "Újdonságok", "Τι νέο υπάρχει", "Какво ново", "מה חדש", "ما الجديد", "नया क्या है", "새로운 기능", "Што новага", "Не жаңалық", "Эмне жаңы", "რა არის ახალი", "Ինչ նոր է", "Nə yenidir", "Шта је ново", "Што е ново", "Čo je nové", "Što je novo", "Kaj je novega", "Kas naujo", "Kas jauns", "Mis on uut", "Nyheder", "Nytt", "Hvað er nýtt", "Çfarë ka të re", "چه چیز تازه است", "Có gì mới", "Чӣ нав аст", "Шинэ зүйл", "Нәрсә яңа", "Yangiliklar", "Cad atá nua", "X’hemm ġdid", "Beth sy’n newydd"],
    "updNow": ["Update", "Оновити", "Aktualizuj", "Aktualisieren", "Actualizar", "Mettre à jour", "Aggiorna", "Atualizar", "Güncelle", "Bijwerken", "Aktualizovat", "Uppdatera", "Päivitä", "Actualizează", "Frissítés", "Ενημέρωση", "Обнови", "עדכן", "تحديث", "अपडेट करें", "업데이트", "Абнавіць", "Жаңарту", "Жаңыртуу", "განახლება", "Թարմացնել", "Yenilə", "Ажурирај", "Ажурирај", "Aktualizovať", "Ažuriraj", "Posodobi", "Atnaujinti", "Atjaunināt", "Uuenda", "Opdater", "Oppdater", "Uppfæra", "Përditëso", "به‌روزرسانی", "Cập nhật", "Навсозӣ", "Шинэчлэх", "Яңарту", "Yangilash", "Nuashonraigh", "Aġġorna", "Diweddaru"],
    "updLater": ["Later", "Пізніше", "Później", "Später", "Más tarde", "Plus tard", "Più tardi", "Mais tarde", "Daha sonra", "Later", "Později", "Senare", "Myöhemmin", "Mai târziu", "Később", "Αργότερα", "По-късно", "מאוחר יותר", "لاحقًا", "बाद में", "나중에", "Пазней", "Кейінірек", "Кийинчерээк", "მოგვიანებით", "Հետո", "Sonra", "Касније", "Подоцна", "Neskôr", "Kasnije", "Pozneje", "Vėliau", "Vēlāk", "Hiljem", "Senere", "Senere", "Síðar", "Më vonë", "بعداً", "Để sau", "Баъдтар", "Дараа", "Соңрак", "Keyinroq", "Níos déanaí", "Aktar tard", "Yn nes ymlaen"],
    "updFail": ["Couldn't update automatically. Open the website to download it?", "Не вдалося оновити автоматично. Відкрити сайт, щоб завантажити?", "Nie udało się zaktualizować automatycznie. Otworzyć stronę, aby pobrać?", "Automatisches Update fehlgeschlagen. Website zum Herunterladen öffnen?", "No se pudo actualizar automáticamente. ¿Abrir la web para descargarla?", "Mise à jour automatique impossible. Ouvrir le site pour la télécharger ?", "Impossibile aggiornare automaticamente. Vuoi aprire il sito per scaricare l’aggiornamento?", "Não foi possível atualizar automaticamente. Abrir o site para baixar?", "Otomatik güncellenemedi. İndirmek için web sitesi açılsın mı?", "Automatisch bijwerken is mislukt. De website openen om te downloaden?", "Automatická aktualizace se nezdařila. Otevřít web a stáhnout?", "Kunde inte uppdatera automatiskt. Öppna webbplatsen för att ladda ner?", "Automaattinen päivitys epäonnistui. Avataanko sivusto latausta varten?", "Actualizarea automată a eșuat. Deschizi site-ul pentru descărcare?", "Az automatikus frissítés nem sikerült. Megnyitod a weboldalt a letöltéshez?", "Η αυτόματη ενημέρωση απέτυχε. Άνοιγμα του ιστότοπου για λήψη;", "Автоматичното обновяване не успя. Да се отвори ли сайтът за изтегляне?", "העדכון האוטומטי נכשל. לפתוח את האתר להורדה?", "تعذّر التحديث تلقائيًا. هل تريد فتح الموقع للتنزيل؟", "अपने-आप अपडेट नहीं हो सका। डाउनलोड के लिए वेबसाइट खोलें?", "자동으로 업데이트하지 못했습니다. 다운로드하려면 웹사이트를 열까요?", "Не ўдалося абнавіць аўтаматычна. Адкрыць сайт, каб спампаваць?", "Автоматты түрде жаңарту мүмкін болмады. Жүктеп алу үшін сайтты ашу керек пе?", "Автоматтык түрдө жаңыртуу мүмкүн болгон жок. Жүктөп алуу үчүн сайтты ачайынбы?", "ავტომატურად განახლება ვერ მოხერხდა. გავხსნა საიტი ჩამოსატვირთად?", "Չհաջողվեց թարմացնել ավտոմատ կերպով։ Բացե՞լ կայքը՝ ներբեռնելու համար։", "Avtomatik yeniləmək alınmadı. Yükləmək üçün sayt açılsın?", "Аутоматско ажурирање није успело. Отворити сајт за преузимање?", "Автоматското ажурирање не успеа. Да го отворам сајтот за преземање?", "Automatická aktualizácia sa nepodarila. Otvoriť web na stiahnutie?", "Automatsko ažuriranje nije uspjelo. Otvoriti web-stranicu za preuzimanje?", "Samodejna posodobitev ni uspela. Odprem spletno mesto za prenos?", "Nepavyko atnaujinti automatiškai. Atidaryti svetainę atsisiuntimui?", "Automātiski atjaunināt neizdevās. Atvērt vietni lejupielādei?", "Automaatne uuendamine ebaõnnestus. Avada veebileht allalaadimiseks?", "Kunne ikke opdatere automatisk. Åbn hjemmesiden for at hente den?", "Kunne ikke oppdatere automatisk. Åpne nettstedet for å laste den ned?", "Ekki tókst að uppfæra sjálfkrafa. Opna vefsíðuna til að sækja hana?", "Nuk u përditësua automatikisht. Të hapet faqja e internetit për ta shkarkuar?", "به‌روزرسانی خودکار انجام نشد. وب‌سایت برای دانلود باز شود؟", "Không thể tự động cập nhật. Mở trang web để tải về?", "Навсозии худкор муяссар нашуд. Сайтро барои боргирӣ кушоед?", "Автоматаар шинэчилж чадсангүй. Татаж авахын тулд вэбсайтыг нээх үү?", "Автоматик рәвештә яңартып булмады. Йөкләү өчен сайтны ачарга?", "Avtomatik yangilab boʻlmadi. Yuklab olish uchun saytni ochaymi?", "Níorbh fhéidir nuashonrú go huathoibríoch. An bhfuil fonn ort an suíomh gréasáin a oscailt chun é a íoslódáil?", "Ma setax jiġi aġġornat awtomatikament. Niftaħ is-sit biex tniżżlu?", "Methu diweddaru’n awtomatig. Agor y wefan i’w lawrlwytho?"],
    "firstRun": ["AURA Switcher is running. Its icon is in the notification area; click ^ next to the clock to open the menu", "AURA Switcher працює. Значок — в області сповіщень; натисніть ^ біля годинника, щоб відкрити меню", "AURA Switcher działa. Ikona jest w obszarze powiadomień; kliknij ^ obok zegara, aby otworzyć menu", "AURA Switcher läuft. Das Symbol ist im Infobereich; klicken Sie neben der Uhr auf ^, um das Menü zu öffnen", "AURA Switcher está funcionando. Su icono está en el área de notificaciones; haz clic en ^ junto al reloj para abrir el menú", "AURA Switcher fonctionne. Son icône est dans la zone de notification ; cliquez sur ^ près de l’horloge pour ouvrir le menu", "AURA Switcher è in esecuzione. L’icona è nell’area di notifica; fai clic su ^ accanto all’orologio per aprire il menu", "O AURA Switcher está a funcionar. O ícone está na área de notificação; clique em ^ junto ao relógio para abrir o menu", "AURA Switcher çalışıyor. Simgesi bildirim alanında; menüyü açmak için saatin yanındaki ^ simgesine tıklayın", "AURA Switcher draait. Het pictogram staat in het systeemvak; klik op ^ naast de klok om het menu te openen", "AURA Switcher běží. Ikona je v oznamovací oblasti; menu otevřete kliknutím na ^ vedle hodin", "AURA Switcher körs. Ikonen finns i aviseringsfältet; klicka på ^ bredvid klockan för att öppna menyn", "AURA Switcher on käynnissä. Kuvake on ilmoitusalueella; avaa valikko napsauttamalla kellon vieressä olevaa ^-merkkiä", "AURA Switcher rulează. Pictograma este în zona de notificare; faceți clic pe ^ de lângă ceas pentru a deschide meniul", "Az AURA Switcher fut. Az ikonja az értesítési területen van; a menü megnyitásához kattintson az óra melletti ^ jelre", "Το AURA Switcher εκτελείται. Το εικονίδιο βρίσκεται στην περιοχή ειδοποιήσεων· κάντε κλικ στο ^ δίπλα στο ρολόι για να ανοίξετε το μενού", "AURA Switcher работи. Иконата е в областта за известия; щракнете върху ^ до часовника, за да отворите менюто", "AURA Switcher פועל. הסמל נמצא באזור ההתראות; לחצו על ^ ליד השעון כדי לפתוח את התפריט", "AURA Switcher يعمل. الأيقونة في منطقة الإشعارات؛ انقر على ^ بجانب الساعة لفتح القائمة", "AURA Switcher चल रहा है। इसका आइकन नोटिफ़िकेशन एरिया में है; मेनू खोलने के लिए घड़ी के पास ^ पर क्लिक करें", "AURA Switcher가 실행 중입니다. 아이콘은 알림 영역에 있습니다. 시계 옆의 ^를 눌러 메뉴를 여세요", "AURA Switcher працуе. Значок — у вобласці апавяшчэнняў; націсніце ^ побач з гадзіннікам, каб адкрыць меню", "AURA Switcher жұмыс істеп тұр. Белгішесі хабарландыру аймағында; мәзірді ашу үшін сағаттың жанындағы ^ түймесін басыңыз", "AURA Switcher иштеп жатат. Сөлөкөтү билдирмелер аймагында; менюну ачуу үчүн сааттын жанындагы ^ баскычын басыңыз", "AURA Switcher მუშაობს. ხატულა შეტყობინებების არეშია; მენიუს გასახსნელად დააწკაპუნეთ საათის გვერდით ^-ზე", "AURA Switcher-ը աշխատում է։ Պատկերակը ծանուցումների տարածքում է․ մենյուն բացելու համար սեղմեք ժամացույցի կողքի ^-ը", "AURA Switcher işləyir. Nişan bildiriş sahəsindədir; menyunu açmaq üçün saatın yanındakı ^ işarəsinə klikləyin", "AURA Switcher ради. Икона је у пољу за обавештења; кликните на ^ поред сата да бисте отворили мени", "AURA Switcher работи. Иконата е во областа за известувања; кликнете на ^ покрај часовникот за да го отворите менито", "AURA Switcher beží. Ikona je v oblasti oznámení; ponuku otvoríte kliknutím na ^ vedľa hodín", "AURA Switcher radi. Ikona je u području obavijesti; kliknite ^ pored sata da otvorite izbornik", "AURA Switcher deluje. Ikona je v območju za obvestila; kliknite ^ ob uri, da odprete meni", "AURA Switcher veikia. Piktograma yra pranešimų srityje; spustelėkite ^ šalia laikrodžio, kad atidarytumėte meniu", "AURA Switcher darbojas. Ikona ir paziņojumu apgabalā; noklikšķiniet uz ^ blakus pulkstenim, lai atvērtu izvēlni", "AURA Switcher töötab. Ikoon on teavitusalas; menüü avamiseks klõpsake kella kõrval ^", "AURA Switcher kører. Ikonet er i meddelelsesområdet; klik på ^ ved siden af uret for at åbne menuen", "AURA Switcher kjører. Ikonet er i varslingsfeltet; klikk på ^ ved siden av klokken for å åpne menyen", "AURA Switcher er í gangi. Táknið er á tilkynningasvæðinu; smelltu á ^ við hliðina á klukkunni til að opna valmyndina", "AURA Switcher po funksionon. Ikona është në zonën e njoftimeve; kliko ^ pranë orës për të hapur menynë", "AURA Switcher در حال اجراست. نماد آن در ناحیه اعلان‌هاست؛ برای باز کردن منو روی ^ کنار ساعت کلیک کنید", "AURA Switcher đang chạy. Biểu tượng nằm ở khu vực thông báo; bấm ^ cạnh đồng hồ để mở menu", "AURA Switcher кор карда истодааст. Нишона дар минтақаи огоҳиҳост; барои кушодани меню ^-ро дар назди соат пахш кунед", "AURA Switcher ажиллаж байна. Дүрс тэмдэг мэдэгдлийн хэсэгт байна; цэсийг нээхийн тулд цагийн хажууох ^-г дарна уу", "AURA Switcher эшли. Билгечә белдерүләр өлкәсендә; менюны ачу өчен сәгать янындагы ^ төймәсенә басыгыз", "AURA Switcher ishlayapti. Belgisi bildirishnomalar hududida; menyuni ochish uchun soat yonidagi ^ belgisini bosing", "Tá AURA Switcher ag rith. Tá an deilbhín sa limistéar fógraí; cliceáil ^ cois an chloig chun an roghchlár a oscailt", "AURA Switcher qed jaħdem. L-ikona tinsab fiż-żona tan-notifiki; ikklikkja fuq ^ ħdejn l-arloġġ biex tiftaħ il-menu", "Mae AURA Switcher yn rhedeg. Mae’r eicon yn yr ardal hysbysu; cliciwch ^ wrth ymyl y cloc i agor y ddewislen"],
    "caseFix": ["Fix letter case", "Виправляти регістр", "Popraw wielkość liter", "Groß-/Kleinschreibung korrigieren", "Corregir mayúsculas", "Corriger la casse", "Correggi maiuscole", "Corrigir maiúsculas", "Harf büyüklüğünü düzelt", "Hoofdletters corrigeren", "Opravovat velikost písmen", "Rätta versaler/gemener", "Korjaa kirjainkoko", "Corectează majusculele", "Kis- és nagybetűk javítása", "Διόρθωση πεζών/κεφαλαίων", "Поправяне на главни/малки букви", "תיקון אותיות גדולות/קטנות", "تصحيح حالة الأحرف", "अक्षरों का केस ठीक करें", "대소문자 자동 수정", "Выпраўляць рэгістр", "Әріп регистрін түзету", "Регистрди оңдоо", "რეგისტრის გასწორება", "Ուղղել մեծատառերը", "Hərf registrini düzəlt", "Исправи величину слова", "Поправи големи/мали букви", "Opravovať veľkosť písmen", "Ispravi velika/mala slova", "Popravi velike/male črke", "Taisyti didžiąsias/mažąsias raides", "Labot lielos/mazos burtus", "Paranda suur-/väiketähti", "Ret store/små bogstaver", "Rett store/små bokstaver", "Laga há-/lágstafi", "Korrigjo shkronjat e mëdha/vogla", "اصلاح حروف بزرگ/کوچک", "Sửa chữ hoa/thường", "Ислоҳи ҳарфи калон/хурд", "Том/жижиг үсгийг засах", "Хәреф регистрын төзәтү", "Harf registrini tuzatish", "Ceartaigh cás na litreacha", "Ikkoreġi l-ittri kapitali", "Cywiro priflythrennau"],
    "abbrevs": ["Abbreviations…", "Абревіатури…", "Skróty…", "Abkürzungen…", "Abreviaturas…", "Abréviations…", "Abbreviazioni…", "Abreviaturas…", "Kısaltmalar…", "Afkortingen…", "Zkratky…", "Förkortningar…", "Lyhenteet…", "Abrevieri…", "Rövidítések…", "Συντομογραφίες…", "Съкращения…", "ראשי תיבות…", "الاختصارات…", "संक्षिप्त रूप…", "약어…", "Абрэвіятуры…", "Аббревиатуралар…", "Аббревиатуралар…", "აბრევიატურები…", "Հապավումներ…", "Abreviaturalar…", "Скраћенице…", "Кратенки…", "Skratky…", "Kratice…", "Kratice…", "Santrumpos…", "Saīsinājumi…", "Lühendid…", "Forkortelser…", "Forkortelser…", "Skammstafanir…", "Shkurtesa…", "اختصارات…", "Từ viết tắt…", "Ихтисораҳо…", "Товчлолууд…", "Кыскартмалар…", "Qisqartmalar…", "Giorrúcháin…", "Abbrevjazzjonijiet…", "Byrfoddau…"],
    "caseHint": ["⌥ + double ⇧ — change case", "⌥ + подвійний ⇧ — змінити регістр", "⌥ + podwójny ⇧ — zmień wielkość liter", "⌥ + Doppel-⇧ — Groß-/Kleinschreibung ändern", "⌥ + doble ⇧ — cambiar mayúsculas", "⌥ + double ⇧ — changer la casse", "⌥ + doppio ⇧ — cambia maiuscole", "⌥ + duplo ⇧ — alterar maiúsculas", "⌥ + çift ⇧ — harf büyüklüğünü değiştir", "⌥ + dubbel ⇧ — hoofdletters wijzigen", "⌥ + dvojitý ⇧ — změnit velikost písmen", "⌥ + dubbel-⇧ — ändra versaler/gemener", "⌥ + kaksois-⇧ — vaihda kirjainkoko", "⌥ + dublu ⇧ — schimbă majusculele", "⌥ + dupla ⇧ — kis-/nagybetű váltása", "⌥ + διπλό ⇧ — αλλαγή πεζών/κεφαλαίων", "⌥ + двоен ⇧ — смяна на главни/малки букви", "⌥ + ⇧ כפול — שינוי אותיות גדולות/קטנות", "⌥ + ⇧ مزدوج — تغيير حالة الأحرف", "⌥ + दो बार ⇧ — केस बदलें", "⌥ + ⇧ 두 번 — 대소문자 변경", "⌥ + падвойны ⇧ — змяніць рэгістр", "⌥ + қос ⇧ — регистрді өзгерту", "⌥ + кош ⇧ — регистрди өзгөртүү", "⌥ + ორმაგი ⇧ — რეგისტრის შეცვლა", "⌥ + կրկնակի ⇧ — փոխել տառերի գրանցումը", "⌥ + qoşa ⇧ — registri dəyiş", "⌥ + двоструки ⇧ — промени величину слова", "⌥ + двоен ⇧ — промени големи/мали букви", "⌥ + dvojitý ⇧ — zmeniť veľkosť písmen", "⌥ + dvostruki ⇧ — promijeni velika/mala slova", "⌥ + dvojni ⇧ — spremeni velike/male črke", "⌥ + dvigubas ⇧ — keisti raidžių dydį", "⌥ + dubults ⇧ — mainīt burtu reģistru", "⌥ + topelt ⇧ — muuda tähesuurust", "⌥ + dobbelt ⇧ — skift store/små bogstaver", "⌥ + dobbel ⇧ — bytt store/små bokstaver", "⌥ + tvöfalt ⇧ — breyta há-/lágstöfum", "⌥ + dyfishi ⇧ — ndrysho shkronjat e mëdha/vogla", "⌥ + ⇧ دوبار — تغییر حروف بزرگ/کوچک", "⌥ + nhấn đôi ⇧ — đổi chữ hoa/thường", "⌥ + дукарата ⇧ — иваз кардани ҳарфҳои калон/хурд", "⌥ + давхар ⇧ — том/жижиг үсэг солих", "⌥ + икеләтә ⇧ — регистрны үзгәртү", "⌥ + ikki marta ⇧ — registrni oʻzgartirish", "⌥ + ⇧ faoi dhó — athraigh cás na litreacha", "⌥ + ⇧ doppju — biddel il-kobor tal-ittri", "⌥ + ⇧ dwbl — newid priflythrennau"],
    "settings": ["Settings…", "Налаштування…", "Ustawienia…", "Einstellungen…", "Ajustes…", "Réglages…", "Impostazioni…", "Ajustes…", "Ayarlar…", "Instellingen…", "Nastavení…", "Inställningar…", "Asetukset…", "Setări…", "Beállítások…", "Ρυθμίσεις…", "Настройки…", "הגדרות…", "الإعدادات…", "सेटिंग…", "설정…", "Налады…", "Баптаулар…", "Жөндөөлөр…", "პარამეტრები…", "Կարգավորումներ…", "Parametrlər…", "Подешавања…", "Поставки…", "Nastavenia…", "Postavke…", "Nastavitve…", "Nustatymai…", "Iestatījumi…", "Seaded…", "Indstillinger…", "Innstillinger…", "Stillingar…", "Cilësimet…", "تنظیمات…", "Cài đặt…", "Танзимот…", "Тохиргоо…", "Көйләүләр…", "Sozlamalar…", "Socruithe…", "Issettings…", "Gosodiadau…"],
    "secGeneral": ["General", "Загальні", "Ogólne", "Allgemein", "General", "Général", "Generali", "Geral", "Genel", "Algemeen", "Obecné", "Allmänt", "Yleiset", "General", "Általános", "Γενικά", "Общи", "כללי", "عام", "सामान्य", "일반", "Агульныя", "Жалпы", "Жалпы", "ზოგადი", "Ընդհանուր", "Ümumi", "Опште", "Општо", "Všeobecné", "Općenito", "Splošno", "Bendra", "Vispārīgi", "Üldine", "Generelt", "Generelt", "Almennt", "Të përgjithshme", "عمومی", "Chung", "Умумӣ", "Ерөнхий", "Гомуми", "Umumiy", "Ginearálta", "Ġenerali", "Cyffredinol"],
    "secShortcuts": ["Shortcuts", "Гарячі клавіші", "Skróty klawiszowe", "Tastenkürzel", "Atajos", "Raccourcis", "Scorciatoie", "Atalhos", "Kısayollar", "Sneltoetsen", "Zkratky", "Genvägar", "Pikanäppäimet", "Comenzi rapide", "Billentyűparancsok", "Συντομεύσεις", "Клавишни комбинации", "קיצורי מקשים", "الاختصارات", "शॉर्टकट", "단축키", "Спалучэнні клавіш", "Пернелер тіркесімдері", "Ыкчам баскычтар", "მალსახმობები", "Դյուրանցումներ", "Qısayollar", "Пречице", "Кратенки на тастатура", "Skratky", "Prečaci", "Bližnjice", "Spartieji klavišai", "Īsinājumtaustiņi", "Kiirklahvid", "Genveje", "Snarveier", "Flýtilyklar", "Shkurtoret", "میانبرها", "Phím tắt", "Тугмаҳои тез", "Товчлолууд", "Кыска юллар", "Tezkor tugmalar", "Aicearraí", "Shortcuts", "Llwybrau byr"],
    "secWords": ["Words", "Слова", "Słowa", "Wörter", "Palabras", "Mots", "Parole", "Palavras", "Sözcükler", "Woorden", "Slova", "Ord", "Sanat", "Cuvinte", "Szavak", "Λέξεις", "Думи", "מילים", "الكلمات", "शब्द", "단어", "Словы", "Сөздер", "Сөздөр", "სიტყვები", "Բառեր", "Sözlər", "Речи", "Зборови", "Slová", "Riječi", "Besede", "Žodžiai", "Vārdi", "Sõnad", "Ord", "Ord", "Orð", "Fjalët", "واژه‌ها", "Từ", "Калимаҳо", "Үгс", "Сүзләр", "Soʻzlar", "Focail", "Kliem", "Geiriau"],
    "secApps": ["Apps", "Програми", "Aplikacje", "Apps", "Apps", "Apps", "App", "Apps", "Uygulamalar", "Apps", "Aplikace", "Appar", "Apit", "Aplicații", "Alkalmazások", "Εφαρμογές", "Приложения", "אפליקציות", "التطبيقات", "ऐप्स", "앱", "Праграмы", "Қолданбалар", "Колдонмолор", "აპები", "Հավելվածներ", "Tətbiqlər", "Апликације", "Апликации", "Aplikácie", "Aplikacije", "Aplikacije", "Programos", "Lietotnes", "Rakendused", "Apps", "Apper", "Forrit", "Aplikacionet", "برنامه‌ها", "Ứng dụng", "Барномаҳо", "Апп-ууд", "Кушымталар", "Ilovalar", "Aipeanna", "Applikazzjonijiet", "Apiau"],
    "secAbout": ["About", "Про програму", "O programie", "Info", "Acerca de", "À propos", "Info", "Sobre", "Hakkında", "Over", "O aplikaci", "Om", "Tietoja", "Despre", "Névjegy", "Σχετικά", "Относно", "אודות", "حول", "के बारे में", "정보", "Пра праграму", "Туралы", "Жөнүндө", "შესახებ", "Ծրագրի մասին", "Haqqında", "О програму", "За апликацијата", "O aplikácii", "O aplikaciji", "O programu", "Apie", "Par programmu", "Teave", "Om", "Om", "Um", "Rreth", "درباره", "Giới thiệu", "Дар бораи барнома", "Тухай", "Программа турында", "Dastur haqida", "Faoi", "Dwar", "Ynghylch"],
    "colWord": ["Word", "Слово", "Słowo", "Wort", "Palabra", "Mot", "Parola", "Palavra", "Sözcük", "Woord", "Slovo", "Ord", "Sana", "Cuvânt", "Szó", "Λέξη", "Дума", "מילה", "الكلمة", "शब्द", "단어", "Слова", "Сөз", "Сөз", "სიტყვა", "Բառ", "Söz", "Реч", "Збор", "Slovo", "Riječ", "Beseda", "Žodis", "Vārds", "Sõna", "Ord", "Ord", "Orð", "Fjala", "واژه", "Từ", "Калима", "Үг", "Сүз", "Soʻz", "Focal", "Kelma", "Gair"],
    "colApp": ["App", "Програма", "Aplikacja", "App", "App", "App", "App", "App", "Uygulama", "App", "Aplikace", "App", "Appi", "Aplicație", "Alkalmazás", "Εφαρμογή", "Приложение", "אפליקציה", "التطبيق", "ऐप", "앱", "Праграма", "Қолданба", "Колдонмо", "აპი", "Հավելված", "Tətbiq", "Апликација", "Апликација", "Aplikácia", "Aplikacija", "Aplikacija", "Programa", "Lietotne", "Rakendus", "App", "App", "Forrit", "Aplikacioni", "برنامه", "Ứng dụng", "Барнома", "Апп", "Кушымта", "Ilova", "Aip", "Applikazzjoni", "Ap"],
    "colLang": ["Language", "Мова", "Język", "Sprache", "Idioma", "Langue", "Lingua", "Idioma", "Dil", "Taal", "Jazyk", "Språk", "Kieli", "Limbă", "Nyelv", "Γλώσσα", "Език", "שפה", "اللغة", "भाषा", "언어", "Мова", "Тіл", "Тил", "ენა", "Լեզու", "Dil", "Језик", "Јазик", "Jazyk", "Jezik", "Jezik", "Kalba", "Valoda", "Keel", "Sprog", "Språk", "Tungumál", "Gjuha", "زبان", "Ngôn ngữ", "Забон", "Хэл", "Тел", "Til", "Teanga", "Lingwa", "Iaith"],
    "search": ["Search", "Пошук", "Szukaj", "Suchen", "Buscar", "Rechercher", "Cerca", "Pesquisar", "Ara", "Zoeken", "Hledat", "Sök", "Hae", "Caută", "Keresés", "Αναζήτηση", "Търсене", "חיפוש", "بحث", "खोजें", "검색", "Пошук", "Іздеу", "Издөө", "ძიება", "Որոնել", "Axtar", "Претрага", "Пребарај", "Hľadať", "Traži", "Iskanje", "Ieškoti", "Meklēt", "Otsi", "Søg", "Søk", "Leita", "Kërko", "جستجو", "Tìm kiếm", "Ҷустуҷӯ", "Хайх", "Эзләү", "Qidirish", "Cuardaigh", "Fittex", "Chwilio"],
    "add": ["Add", "Додати", "Dodaj", "Hinzufügen", "Añadir", "Ajouter", "Aggiungi", "Adicionar", "Ekle", "Voeg toe", "Přidat", "Lägg till", "Lisää", "Adaugă", "Hozzáadás", "Προσθήκη", "Добави", "הוספה", "إضافة", "जोड़ें", "추가", "Дадаць", "Қосу", "Кошуу", "დამატება", "Ավելացնել", "Əlavə et", "Додај", "Додај", "Pridať", "Dodaj", "Dodaj", "Pridėti", "Pievienot", "Lisa", "Tilføj", "Legg til", "Bæta við", "Shto", "افزودن", "Thêm", "Илова кардан", "Нэмэх", "Өстәү", "Qoʻshish", "Cuir leis", "Żid", "Ychwanegu"],
    "remove": ["Remove", "Видалити", "Usuń", "Entfernen", "Quitar", "Supprimer", "Rimuovi", "Remover", "Kaldır", "Verwijder", "Odebrat", "Ta bort", "Poista", "Elimină", "Eltávolítás", "Αφαίρεση", "Премахни", "הסרה", "إزالة", "हटाएँ", "제거", "Выдаліць", "Жою", "Өчүрүү", "წაშლა", "Հեռացնել", "Sil", "Уклони", "Отстрани", "Odstrániť", "Ukloni", "Odstrani", "Pašalinti", "Noņemt", "Eemalda", "Fjern", "Fjern", "Fjarlægja", "Hiq", "حذف", "Xóa", "Тоза кардан", "Хасах", "Бетерү", "Olib tashlash", "Bain", "Neħħi", "Dileu"],
    "chooseApp": ["Choose app…", "Обрати програму…", "Wybierz aplikację…", "App auswählen…", "Elegir app…", "Choisir une app…", "Scegli app…", "Escolher app…", "Uygulama seç…", "Kies app…", "Vybrat aplikaci…", "Välj app…", "Valitse appi…", "Alege aplicația…", "Alkalmazás kiválasztása…", "Επιλογή εφαρμογής…", "Избор на приложение…", "בחירת אפליקציה…", "اختيار تطبيق…", "ऐप चुनें…", "앱 선택…", "Выбраць праграму…", "Қолданбаны таңдау…", "Колдонмону тандоо…", "აპის არჩევა…", "Ընտրել հավելված…", "Tətbiq seç…", "Изабери апликацију…", "Избери апликација…", "Vybrať aplikáciu…", "Odaberi aplikaciju…", "Izberi aplikacijo…", "Pasirinkti programą…", "Izvēlēties lietotni…", "Vali rakendus…", "Vælg app…", "Velg app…", "Velja forrit…", "Zgjidh aplikacion…", "انتخاب برنامه…", "Chọn ứng dụng…", "Интихоби барнома…", "Апп сонгох…", "Кушымтаны сайлау…", "Ilovani tanlash…", "Roghnaigh aip…", "Agħżel applikazzjoni…", "Dewis ap…"],
    "recentApps": ["Recent apps", "Останні програми", "Ostatnie aplikacje", "Zuletzt verwendete Apps", "Apps recientes", "Apps récentes", "App recenti", "Apps recentes", "Son uygulamalar", "Recente apps", "Poslední aplikace", "Senaste appar", "Viimeisimmät apit", "Aplicații recente", "Legutóbbi alkalmazások", "Πρόσφατες εφαρμογές", "Скорошни приложения", "אפליקציות אחרונות", "التطبيقات الأخيرة", "हाल के ऐप्स", "최근 앱", "Апошнія праграмы", "Соңғы қолданбалар", "Акыркы колдонмолор", "ბოლო აპები", "Վերջին հավելվածներ", "Son tətbiqlər", "Недавне апликације", "Неодамнешни апликации", "Posledné aplikácie", "Nedavne aplikacije", "Nedavne aplikacije", "Naujausios programos", "Pēdējās lietotnes", "Hiljutised rakendused", "Seneste apps", "Nylige apper", "Nýleg forrit", "Aplikacionet e fundit", "برنامه‌های اخیر", "Ứng dụng gần đây", "Барномаҳои охирин", "Сүүлийн апп-ууд", "Соңгы кушымталар", "Oxirgi ilovalar", "Aipeanna le déanaí", "Applikazzjonijiet reċenti", "Apiau diweddar"],
    "version": ["Version", "Версія", "Wersja", "Version", "Versión", "Version", "Versione", "Versão", "Sürüm", "Versie", "Verze", "Version", "Versio", "Versiune", "Verzió", "Έκδοση", "Версия", "גרסה", "الإصدار", "संस्करण", "버전", "Версія", "Нұсқа", "Версия", "ვერსია", "Տարբերակ", "Versiya", "Верзија", "Верзија", "Verzia", "Verzija", "Različica", "Versija", "Versija", "Versioon", "Version", "Versjon", "Útgáfa", "Versioni", "نسخه", "Phiên bản", "Версия", "Хувилбар", "Версия", "Versiya", "Leagan", "Verżjoni", "Fersiwn"],
    "origRepo": ["Original project on GitHub", "Оригінальний проєкт на GitHub", "Oryginalny projekt na GitHubie", "Originalprojekt auf GitHub", "Proyecto original en GitHub", "Projet original sur GitHub", "Progetto originale su GitHub", "Projeto original no GitHub", "GitHub'daki özgün proje", "Oorspronkelijk project op GitHub", "Původní projekt na GitHubu", "Originalprojektet på GitHub", "Alkuperäinen projekti GitHubissa", "Proiectul original pe GitHub", "Az eredeti projekt a GitHubon", "Αρχικό έργο στο GitHub", "Оригиналният проект в GitHub", "הפרויקט המקורי ב-GitHub", "المشروع الأصلي على GitHub", "GitHub पर मूल प्रोजेक्ट", "GitHub의 원본 프로젝트", "Арыгінальны праект на GitHub", "GitHub-тағы түпнұсқа жоба", "GitHub'дагы түпнуска долбоор", "ორიგინალური პროექტი GitHub-ზე", "Բնօրինակ նախագիծը GitHub-ում", "GitHub-dakı orijinal layihə", "Оригинални пројекат на GitHub-у", "Оригиналниот проект на GitHub", "Pôvodný projekt na GitHube", "Izvorni projekt na GitHubu", "Izvirni projekt na GitHubu", "Originalus projektas „GitHub“", "Oriģinālais projekts GitHub", "Algne projekt GitHubis", "Det oprindelige projekt på GitHub", "Det opprinnelige prosjektet på GitHub", "Upprunalega verkefnið á GitHub", "Projekti origjinal në GitHub", "پروژه اصلی در GitHub", "Dự án gốc trên GitHub", "Лоиҳаи аслӣ дар GitHub", "GitHub дээрх эх төсөл", "GitHub'тагы төп проект", "GitHub’dagi asl loyiha", "An bunthionscadal ar GitHub", "Il-proġett oriġinali fuq GitHub", "Y prosiect gwreiddiol ar GitHub"],
    "shNote": ["These shortcuts can't be changed yet.", "Ці скорочення поки не налаштовуються.", "Tych skrótów nie można jeszcze zmienić.", "Diese Tastenkürzel lassen sich noch nicht ändern.", "Estos atajos aún no se pueden cambiar.", "Ces raccourcis ne sont pas encore modifiables.", "Queste scorciatoie non si possono ancora modificare.", "Estes atalhos ainda não podem ser alterados.", "Bu kısayollar henüz değiştirilemez.", "Deze sneltoetsen kunnen nog niet worden gewijzigd.", "Tyto zkratky zatím nelze změnit.", "De här genvägarna kan inte ändras än.", "Näitä pikanäppäimiä ei voi vielä muuttaa.", "Aceste comenzi rapide nu pot fi încă modificate.", "Ezek a billentyűparancsok még nem módosíthatók.", "Αυτές οι συντομεύσεις δεν αλλάζουν ακόμη.", "Тези комбинации още не могат да се променят.", "עדיין אי אפשר לשנות את הקיצורים האלה.", "لا يمكن تغيير هذه الاختصارات بعد.", "इन शॉर्टकट को अभी बदला नहीं जा सकता।", "이 단축키는 아직 변경할 수 없습니다.", "Гэтыя спалучэнні пакуль нельга змяніць.", "Бұл тіркесімдерді әзірге өзгерту мүмкін емес.", "Бул ыкчам баскычтарды азырынча өзгөртүүгө болбойт.", "ამ მალსახმობების შეცვლა ჯერ შეუძლებელია.", "Այս դյուրանցումները դեռ հնարավոր չէ փոխել։", "Bu qısayolları hələ dəyişmək olmur.", "Ове пречице се још не могу мењати.", "Овие кратенки засега не можат да се менуваат.", "Tieto skratky zatiaľ nemožno zmeniť.", "Ti se prečaci još ne mogu mijenjati.", "Teh bližnjic še ni mogoče spreminjati.", "Šių spartųjų klavišų kol kas negalima keisti.", "Šos īsinājumtaustiņus vēl nevar mainīt.", "Neid kiirklahve ei saa veel muuta.", "Disse genveje kan endnu ikke ændres.", "Disse snarveiene kan ikke endres ennå.", "Ekki er enn hægt að breyta þessum flýtilyklum.", "Këto shkurtore nuk mund të ndryshohen ende.", "این میانبرها هنوز قابل تغییر نیستند.", "Chưa thể thay đổi các phím tắt này.", "Ин тугмаҳои тезро ҳоло иваз кардан мумкин нест.", "Эдгээр товчлолыг одоогоор өөрчлөх боломжгүй.", "Бу кыска юлларны әлегә үзгәртеп булмый.", "Bu tezkor tugmalarni hozircha oʻzgartirib boʻlmaydi.", "Ní féidir na aicearraí seo a athrú go fóill.", "Dawn ix-shortcuts għadhom ma jistgħux jinbidlu.", "Ni ellir newid y llwybrau byr hyn eto."],
    "wordsDesc": ["AURA never changes these words, and fixes them when typed in the wrong layout.", "AURA ніколи не змінює ці слова, а набрані не в тій розкладці — виправляє на них.", "AURA nigdy nie zmienia tych słów, a wpisane w złym układzie poprawia na nie.", "AURA ändert diese Wörter nie und korrigiert im falschen Layout getippte Wörter auf sie.", "AURA nunca cambia estas palabras y corrige a ellas las tecleadas en la distribución equivocada.", "AURA ne modifie jamais ces mots et corrige vers eux ceux tapés dans la mauvaise disposition.", "AURA non modifica mai queste parole e corregge in esse quelle digitate nel layout sbagliato.", "O AURA nunca altera estas palavras e corrige para elas as digitadas no layout errado.", "AURA bu sözcükleri asla değiştirmez; yanlış düzende yazılanları bunlara düzeltir.", "AURA wijzigt deze woorden nooit en corrigeert in de verkeerde indeling getypte woorden ernaar.", "AURA tato slova nikdy nemění a slova napsaná v nesprávném rozložení opraví na ně.", "AURA ändrar aldrig dessa ord och rättar ord skrivna i fel layout till dem.", "AURA ei koskaan muuta näitä sanoja ja korjaa väärällä asettelulla kirjoitetut sanat niiksi.", "AURA nu modifică niciodată aceste cuvinte și corectează în ele cuvintele tastate în aranjamentul greșit.", "Az AURA soha nem módosítja ezeket a szavakat, a rossz kiosztásban gépelteket pedig ezekre javítja.", "Το AURA δεν αλλάζει ποτέ αυτές τις λέξεις και διορθώνει σε αυτές όσες πληκτρολογήθηκαν σε λάθος διάταξη.", "AURA никога не променя тези думи, а написаните в грешна подредба поправя на тях.", "AURA לעולם לא משנה מילים אלה, ומתקנת אליהן מילים שהוקלדו בפריסה הלא נכונה.", "لا يغيّر AURA هذه الكلمات أبدًا، ويصحّح إليها الكلمات المكتوبة بتخطيط خاطئ.", "AURA इन शब्दों को कभी नहीं बदलता, और गलत लेआउट में टाइप किए शब्दों को इनमें सुधारता है।", "AURA는 이 단어들을 절대 바꾸지 않으며, 잘못된 자판 배열로 입력한 단어는 이 단어로 고칩니다.", "AURA ніколі не змяняе гэтыя словы, а набраныя не ў той раскладцы — выпраўляе на іх.", "AURA бұл сөздерді ешқашан өзгертпейді, қате пернетақтада терілгенді осыларға түзетеді.", "AURA бул сөздөрдү эч качан өзгөртпөйт, туура эмес жайгашууда терилгенди ушуларга оңдойт.", "AURA ამ სიტყვებს არასოდეს ცვლის, არასწორ განლაგებაში აკრეფილს კი მათზე ასწორებს.", "AURA-ն երբեք չի փոխում այս բառերը, իսկ սխալ դասավորությամբ տպվածները ուղղում է դրանց։", "AURA bu sözləri heç vaxt dəyişmir, səhv düzümdə yığılanları isə bunlara düzəldir.", "AURA никада не мења ове речи, а откуцане у погрешном распореду исправља на њих.", "AURA никогаш не ги менува овие зборови, а напишаните во погрешен распоред ги поправа на нив.", "AURA tieto slová nikdy nemení a slová napísané v nesprávnom rozložení opraví na ne.", "AURA nikada ne mijenja ove riječi, a utipkane u krivom rasporedu ispravlja u njih.", "AURA teh besed nikoli ne spreminja, natipkane v napačni postavitvi pa popravi vanje.", "AURA niekada nekeičia šių žodžių, o netinkamu išdėstymu surinktus pataiso į juos.", "AURA šos vārdus nekad nemaina, bet nepareizā izkārtojumā ievadītos izlabo uz tiem.", "AURA ei muuda neid sõnu kunagi ja parandab vales paigutuses trükitud sõnad nendeks.", "AURA ændrer aldrig disse ord og retter ord skrevet i forkert layout til dem.", "AURA endrer aldri disse ordene og retter ord skrevet i feil layout til dem.", "AURA breytir þessum orðum aldrei og leiðréttir orð sem slegin eru inn í röngu skipulagi í þau.", "AURA nuk i ndryshon kurrë këto fjalë dhe i korrigjon në to ato që janë shkruar në pamje të gabuar.", "AURA هرگز این واژه‌ها را تغییر نمی‌دهد و واژه‌های تایپ‌شده با چیدمان اشتباه را به آن‌ها اصلاح می‌کند.", "AURA không bao giờ thay đổi các từ này, và sửa sang chúng những từ gõ sai bố cục.", "AURA ин калимаҳоро ҳаргиз иваз намекунад ва калимаҳои дар тарҳбандии нодуруст навишташударо ба онҳо ислоҳ мекунад.", "AURA эдгээр үгийг хэзээ ч өөрчилдөггүй, буруу байрлалд бичсэнийг тэдгээр рүү засна.", "AURA бу сүзләрне беркайчан да үзгәртми, ә ялгыш рәвештә җыелганнарны шуларга төзәтә.", "AURA bu soʻzlarni hech qachon oʻzgartirmaydi, notoʻgʻri joylashuvda terilganlarni esa ularga tuzatadi.", "Ní athraíonn AURA na focail seo choíche, agus ceartaíonn sé chucu iad siúd a clóscríobhadh sa leagan amach mícheart.", "AURA qatt ma tbiddel dan il-kliem, u tirranġa fih dak miktub bit-tqassim żbaljat.", "Nid yw AURA byth yn newid y geiriau hyn, ac mae'n cywiro iddynt y rhai a deipiwyd yn y cynllun anghywir."],
    "abbrevsDesc": ["AURA writes these in capitals (TTN), even when typed in the wrong layout.", "AURA пише їх великими літерами (ТТН), навіть якщо набрано не в тій розкладці.", "AURA zapisuje je wielkimi literami (TTN), także gdy wpisano je w złym układzie.", "AURA schreibt diese in Großbuchstaben (TTN), auch wenn sie im falschen Layout getippt wurden.", "AURA las escribe en mayúsculas (TTN), incluso si se teclearon en la distribución equivocada.", "AURA les écrit en majuscules (TTN), même tapés dans la mauvaise disposition.", "AURA le scrive in maiuscolo (TTN), anche se digitate nel layout sbagliato.", "O AURA escreve-as em maiúsculas (TTN), mesmo digitadas no layout errado.", "AURA bunları büyük harfle yazar (TTN), yanlış düzende yazılsalar bile.", "AURA schrijft deze in hoofdletters (TTN), ook als ze in de verkeerde indeling zijn getypt.", "AURA je píše velkými písmeny (TTN), i když byla napsána v nesprávném rozložení.", "AURA skriver dessa med versaler (TTN), även om de skrivits i fel layout.", "AURA kirjoittaa nämä isoilla kirjaimilla (TTN), vaikka ne olisi kirjoitettu väärällä asettelulla.", "AURA le scrie cu majuscule (TTN), chiar dacă au fost tastate în aranjamentul greșit.", "Az AURA nagybetűvel írja őket (TTN), akkor is, ha rossz kiosztásban gépelték.", "Το AURA τις γράφει με κεφαλαία (TTN), ακόμη και αν πληκτρολογήθηκαν σε λάθος διάταξη.", "AURA ги пише с главни букви (ТТН), дори да са написани в грешна подредба.", "AURA כותבת אותן באותיות גדולות (TTN), גם אם הוקלדו בפריסה הלא נכונה.", "يكتبها AURA بأحرف كبيرة (TTN)، حتى لو كُتبت بتخطيط خاطئ.", "AURA इन्हें बड़े अक्षरों में लिखता है (TTN), भले ही वे गलत लेआउट में टाइप किए गए हों।", "AURA는 이 단어들을 대문자로 씁니다(TTN). 잘못된 자판 배열로 입력해도 마찬가지입니다.", "AURA піша іх вялікімі літарамі (ТТН), нават калі набрана не ў той раскладцы.", "AURA оларды бас әріптермен жазады (ТТН), қате пернетақтада терілсе де.", "AURA аларды баш тамгалар менен жазат (ТТН), туура эмес жайгашууда терилсе да.", "AURA მათ დიდი ასოებით წერს (TTN), თუნდაც არასწორ განლაგებაში იყოს აკრეფილი.", "AURA-ն դրանք գրում է մեծատառերով (TTN), նույնիսկ եթե տպվել են սխալ դասավորությամբ։", "AURA bunları böyük hərflərlə yazır (TTN), səhv düzümdə yığılsa belə.", "AURA их пише великим словима (ТТН), чак и ако су откуцане у погрешном распореду.", "AURA ги пишува со големи букви (ТТН), дури и ако се напишани во погрешен распоред.", "AURA ich píše veľkými písmenami (TTN), aj keď boli napísané v nesprávnom rozložení.", "AURA ih piše velikim slovima (TTN), čak i ako su utipkane u krivom rasporedu.", "AURA jih piše z velikimi črkami (TTN), tudi če so natipkane v napačni postavitvi.", "AURA juos rašo didžiosiomis raidėmis (TTN), net jei jie surinkti netinkamu išdėstymu.", "AURA tos raksta ar lielajiem burtiem (TTN), pat ja tie ievadīti nepareizā izkārtojumā.", "AURA kirjutab need suurtähtedega (TTN), isegi kui need on trükitud vales paigutuses.", "AURA skriver dem med store bogstaver (TTN), selv hvis de er skrevet i det forkerte layout.", "AURA skriver dem med store bokstaver (TTN), selv om de er skrevet i feil layout.", "AURA skrifar þau með hástöfum (TTN), jafnvel þótt þau séu slegin inn í röngu skipulagi.", "AURA i shkruan me shkronja të mëdha (TTN), edhe kur janë shkruar në pamje të gabuar.", "AURA این‌ها را با حروف بزرگ می‌نویسد (TTN)، حتی اگر با چیدمان اشتباه تایپ شده باشند.", "AURA viết hoa chúng (TTN), kể cả khi gõ sai bố cục bàn phím.", "AURA онҳоро бо ҳарфҳои калон менависад (ТТН), ҳатто агар дар тарҳбандии нодуруст навишта шуда бошанд.", "AURA тэдгээрийг том үсгээр бичнэ (ТТН), буруу байрлалд бичсэн ч гэсэн.", "AURA аларны зур хәрефләр белән яза (ТТН), ялгыш рәвештә җыелса да.", "AURA ularni bosh harflar bilan yozadi (TTN), notoʻgʻri joylashuvda terilgan boʻlsa ham.", "Scríobhann AURA iad i mbarrlitreacha (TTN), fiú má clóscríobhadh iad sa leagan amach mícheart.", "AURA tikteb dawn b'ittri kapitali (TTN), anki jekk inkitbu bit-tqassim żbaljat.", "Mae AURA yn eu hysgrifennu mewn priflythrennau (TTN), hyd yn oed os cawsant eu teipio yn y cynllun anghywir."],
    "excludeDesc": ["AURA does nothing in these apps. Full-screen games are paused automatically.", "У цих програмах AURA нічого не робить. Повноекранні ігри ставляться на паузу автоматично.", "W tych aplikacjach AURA nic nie robi. Gry pełnoekranowe są wstrzymywane automatycznie.", "In diesen Apps tut AURA nichts. Vollbildspiele werden automatisch pausiert.", "AURA no hace nada en estas apps. Los juegos a pantalla completa se pausan automáticamente.", "AURA ne fait rien dans ces apps. Les jeux en plein écran sont mis en pause automatiquement.", "In queste app AURA non fa nulla. I giochi a schermo intero vengono messi in pausa automaticamente.", "O AURA não faz nada nestes apps. Jogos em ecrã inteiro são pausados automaticamente.", "AURA bu uygulamalarda hiçbir şey yapmaz. Tam ekran oyunlar otomatik duraklatılır.", "In deze apps doet AURA niets. Volledig-scherm-games worden automatisch gepauzeerd.", "V těchto aplikacích AURA nic nedělá. Celoobrazovkové hry se pozastaví automaticky.", "AURA gör ingenting i dessa appar. Helskärmsspel pausas automatiskt.", "AURA ei tee mitään näissä apeissa. Koko näytön pelit keskeytetään automaattisesti.", "AURA nu face nimic în aceste aplicații. Jocurile pe tot ecranul sunt puse automat în pauză.", "Ezekben az alkalmazásokban az AURA nem csinál semmit. A teljes képernyős játékokat automatikusan szünetelteti.", "Σε αυτές τις εφαρμογές το AURA δεν κάνει τίποτα. Τα παιχνίδια πλήρους οθόνης σταματούν αυτόματα.", "В тези приложения AURA не прави нищо. Игрите на цял екран се паузират автоматично.", "באפליקציות אלה AURA לא עושה דבר. משחקי מסך מלא מושהים אוטומטית.", "لا يفعل AURA شيئًا في هذه التطبيقات. تُوقَف الألعاب بملء الشاشة تلقائيًا.", "इन ऐप्स में AURA कुछ नहीं करता। फ़ुल-स्क्रीन गेम अपने आप रुक जाते हैं।", "이 앱들에서는 AURA가 아무것도 하지 않습니다. 전체 화면 게임은 자동으로 일시 중지됩니다.", "У гэтых праграмах AURA нічога не робіць. Поўнаэкранныя гульні спыняюцца аўтаматычна.", "Бұл қолданбаларда AURA ештеңе істемейді. Толық экранды ойындар автоматты түрде кідіртіледі.", "Бул колдонмолордо AURA эч нерсе кылбайт. Толук экрандуу оюндар автоматтык түрдө тындырылат.", "ამ აპებში AURA არაფერს აკეთებს. სრულეკრანიანი თამაშები ავტომატურად ჩერდება.", "Այս հավելվածներում AURA-ն ոչինչ չի անում։ Լիաէկրան խաղերը ավտոմատ դադարեցվում են։", "Bu tətbiqlərdə AURA heç nə etmir. Tam ekran oyunlar avtomatik dayandırılır.", "У овим апликацијама AURA не ради ништа. Игре преко целог екрана се аутоматски паузирају.", "Во овие апликации AURA не прави ништо. Игрите на цел екран автоматски се паузираат.", "V týchto aplikáciách AURA nič nerobí. Celoobrazovkové hry sa pozastavia automaticky.", "U tim aplikacijama AURA ne radi ništa. Igre preko cijelog zaslona automatski se pauziraju.", "V teh aplikacijah AURA ne naredi ničesar. Igre čez cel zaslon se samodejno začasno ustavijo.", "Šiose programose AURA nieko nedaro. Viso ekrano žaidimai pristabdomi automatiškai.", "Šajās lietotnēs AURA neko nedara. Pilnekrāna spēles tiek automātiski apturētas.", "Nendes rakendustes AURA midagi ei tee. Täisekraanimängud peatatakse automaatselt.", "AURA gør ingenting i disse apps. Fuldskærmsspil sættes automatisk på pause.", "AURA gjør ingenting i disse appene. Fullskjermspill settes automatisk på pause.", "AURA gerir ekkert í þessum forritum. Leikir í öllum skjánum eru settir sjálfkrafa á bið.", "Në këto aplikacione AURA nuk bën asgjë. Lojërat me ekran të plotë ndalen automatikisht.", "در این برنامه‌ها AURA کاری نمی‌کند. بازی‌های تمام‌صفحه به‌طور خودکار متوقف می‌شوند.", "AURA không làm gì trong các ứng dụng này. Trò chơi toàn màn hình tự động tạm dừng.", "Дар ин барномаҳо AURA коре намекунад. Бозиҳои экрани пурра худкор қатъ мешаванд.", "Эдгээр апп-д AURA юу ч хийхгүй. Бүтэн дэлгэцийн тоглоомууд автоматаар түр зогсоно.", "Бу кушымталарда AURA берни эшләми. Тулы экранлы уеннар автоматик туктатыла.", "Bu ilovalarda AURA hech narsa qilmaydi. Toʻliq ekranli oʻyinlar avtomatik toʻxtatiladi.", "Ní dhéanann AURA aon rud sna haipeanna seo. Cuirtear cluichí lánscáileáin ar sos go huathoibríoch.", "F'dawn l-applikazzjonijiet AURA ma tagħmel xejn. Il-logħob bi skrin sħiħ jitwaqqaf awtomatikament.", "Nid yw AURA yn gwneud dim yn yr apiau hyn. Caiff gemau sgrin lawn eu seibio'n awtomatig."],
    "bindDesc": ["When you switch to one of these apps, AURA changes the layout to the chosen language.", "Коли ви перемикаєтесь на одну з цих програм, AURA змінює розкладку на обрану мову.", "Po przełączeniu na jedną z tych aplikacji AURA zmienia układ na wybrany język.", "Wenn Sie zu einer dieser Apps wechseln, stellt AURA das Layout auf die gewählte Sprache um.", "Al cambiar a una de estas apps, AURA cambia la distribución al idioma elegido.", "Quand vous passez à l'une de ces apps, AURA change la disposition pour la langue choisie.", "Quando passi a una di queste app, AURA cambia il layout nella lingua scelta.", "Ao mudar para um destes apps, o AURA muda o layout para o idioma escolhido.", "Bu uygulamalardan birine geçtiğinizde AURA düzeni seçilen dile değiştirir.", "Als je naar een van deze apps overschakelt, wijzigt AURA de indeling naar de gekozen taal.", "Když přepnete na jednu z těchto aplikací, AURA změní rozložení na vybraný jazyk.", "När du byter till någon av dessa appar byter AURA layout till det valda språket.", "Kun vaihdat johonkin näistä apeista, AURA vaihtaa asettelun valittuun kieleen.", "Când treci la una dintre aceste aplicații, AURA schimbă aranjamentul în limba aleasă.", "Ha ezek valamelyikére váltasz, az AURA a kiválasztott nyelvre váltja a kiosztást.", "Όταν μεταβείτε σε μία από αυτές τις εφαρμογές, το AURA αλλάζει τη διάταξη στη γλώσσα που επιλέξατε.", "Когато превключите към някое от тези приложения, AURA сменя подредбата на избрания език.", "כשעוברים לאחת האפליקציות האלה, AURA מחליפה את הפריסה לשפה שנבחרה.", "عند التبديل إلى أحد هذه التطبيقات، يغيّر AURA التخطيط إلى اللغة المختارة.", "जब आप इनमें से किसी ऐप पर जाते हैं, AURA लेआउट को चुनी हुई भाषा में बदल देता है।", "이 앱 중 하나로 전환하면 AURA가 자판 배열을 선택한 언어로 바꿉니다.", "Калі вы пераключаецеся на адну з гэтых праграм, AURA змяняе раскладку на абраную мову.", "Осы қолданбалардың біріне ауысқанда, AURA пернетақта орналасуын таңдалған тілге ауыстырады.", "Бул колдонмолордун бирине которулганыңызда, AURA жайгашууну тандалган тилге өзгөртөт.", "როცა ამ აპებიდან რომელიმეზე გადახვალთ, AURA განლაგებას არჩეულ ენაზე ცვლის.", "Երբ անցնում եք այս հավելվածներից մեկին, AURA-ն դասավորությունը փոխում է ընտրված լեզվի։", "Bu tətbiqlərdən birinə keçdikdə AURA düzümü seçilmiş dilə dəyişir.", "Када пређете на једну од ових апликација, AURA мења распоред на изабрани језик.", "Кога ќе преминете на една од овие апликации, AURA го менува распоредот на избраниот јазик.", "Keď prepnete na jednu z týchto aplikácií, AURA zmení rozloženie na vybraný jazyk.", "Kad prijeđete na jednu od tih aplikacija, AURA mijenja raspored na odabrani jezik.", "Ko preklopite na eno od teh aplikacij, AURA spremeni postavitev na izbrani jezik.", "Perjungus į vieną iš šių programų, AURA pakeičia išdėstymą į pasirinktą kalbą.", "Kad pārslēdzaties uz kādu no šīm lietotnēm, AURA nomaina izkārtojumu uz izvēlēto valodu.", "Kui lülitud ühele neist rakendustest, muudab AURA paigutuse valitud keeleks.", "Når du skifter til en af disse apps, skifter AURA layout til det valgte sprog.", "Når du bytter til en av disse appene, bytter AURA layout til det valgte språket.", "Þegar þú skiptir yfir í eitt þessara forrita breytir AURA skipulaginu í valið tungumál.", "Kur kalon te një nga këto aplikacione, AURA ndryshon pamjen e tastierës në gjuhën e zgjedhur.", "وقتی به یکی از این برنامه‌ها می‌روید، AURA چیدمان را به زبان انتخابی تغییر می‌دهد.", "Khi bạn chuyển sang một trong các ứng dụng này, AURA đổi bố cục sang ngôn ngữ đã chọn.", "Вақте ба яке аз ин барномаҳо мегузаред, AURA тарҳбандиро ба забони интихобшуда иваз мекунад.", "Эдгээр апп-ын аль нэг рүү шилжихэд AURA байрлалыг сонгосон хэл рүү солино.", "Бу кушымталарның берсенә күчкәндә, AURA рәвешне сайланган телгә үзгәртә.", "Shu ilovalardan biriga oʻtganingizda, AURA joylashuvni tanlangan tilga almashtiradi.", "Nuair a athraíonn tú go ceann de na haipeanna seo, athraíonn AURA an leagan amach go dtí an teanga roghnaithe.", "Meta taqleb għal waħda minn dawn l-applikazzjonijiet, AURA tbiddel it-tqassim għal-lingwa magħżula.", "Pan fyddwch yn newid i un o'r apiau hyn, mae AURA yn newid y cynllun i'r iaith a ddewiswyd."],
]
// END menu strings

func uiCode() -> String {
    if let l = engine.settings.uiLang, uiLangs.contains(l) { return l }
    let sys = String(Locale.preferredLanguages.first?.prefix(2) ?? "en")
    return sys == "ru" ? "uk" : uiLangs.contains(sys) ? sys : "en"
}

func L(_ key: String) -> String { uiStrings[key]?[uiLangs.firstIndex(of: uiCode()) ?? 0] ?? key }
/// empty submenu: tell where it gets filled — «Порожньо — ↑ «Не працювати в цій програмі»»
func emptyHint(_ fillKey: String) -> String { "\(L("empty")) — ↑ «\(L(fillKey).trimmingCharacters(in: .whitespaces))»" }

// MARK: - Engine

final class Engine {
    let settings = Settings()
    var layouts: [Layout] = loadLayouts()
    var frontBundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    lazy var frontIsGame = isGame(NSWorkspace.shared.frontmostApplication)
    var recent: [String] = []   // last apps switched to, newest first — to exclude a full-screen game after leaving it
    var tap: CFMachPort?
    let src = CGEventSource(stateID: .privateState)

    var word: [Key] = []        // word being typed
    var lastWord: [Key] = []    // previous word, still convertible
    var trailing = 0            // spaces typed after lastWord
    var before: [Key] = []      // one-letter word right before `word` («z буду»), fixed together with it

    var shiftDownAt: TimeInterval = 0, lastShiftTap: TimeInterval = 0, sawOther = false
    var shiftDownAlt = false, lastTapAlt = false   // ⌥ held with the ⇧ tap: ⌥ + double ⇧ changes the case
    var lastSelOut: String?, lastSelLang = 0

    var allCodes: Set<UInt16> { Set(layouts.flatMap { $0.toChar.keys.map(\.code) }) }
    lazy var codes = allCodes

    var active: Bool { settings.enabled && !frontIsGame && !settings.excluded.contains(frontBundle) }

    func reset() { word = []; lastWord = []; trailing = 0; before = []; lastCycled = []; lastCycledLang = nil; lastCase = nil; handsOff = false }
    /// the user went back into the text (Backspace over a space, arrows) or switched the layout in the middle of a
    /// word: until the next space AURA neither checks nor converts what is typed — it's the user's own word
    var handsOff = false
    /// Backspace/Delete emptied the whole field (Cmd+A, Delete): there is no word to go back into, so the first
    /// word typed now is checked as usual. The field is read a moment later (the app has to handle the key first);
    /// if the app doesn't say (nil) or the user already typed on, handsOff stays.
    var fieldEmpty: () -> Bool? = { Engine.axFieldEmpty() }
    func releaseIfFieldEmpty() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.releaseIfEmptyNow() }
    }
    func releaseIfEmptyNow() {
        if handsOff, word.isEmpty, lastWord.isEmpty, fieldEmpty() == true { handsOff = false }
    }
    static func axFieldEmpty() -> Bool? {
        var f: CFTypeRef?
        guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &f) == .success,
              let f else { return nil }
        let el = f as! AXUIElement
        var sub: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXSubroleAttribute as CFString, &sub)
        if sub as? String == kAXSecureTextFieldSubrole as String { return nil }
        var n: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, kAXNumberOfCharactersAttribute as CFString, &n) == .success,
              let c = n as? Int else { return nil }
        return c == 0
    }
    var wordStartLang: String?  // the layout the current word was started in

    func layout(_ lang: String?) -> Layout? { layouts.first { $0.lang == lang } }
    func index(_ lang: String?) -> Int { layouts.firstIndex { $0.lang == lang } ?? 0 }
    /// the layout AURA selected itself, until the user switches to another one (see handleKey)
    var ownLang: String?
    func select(_ l: Layout) { ownLang = l.lang; TISSelectInputSource(l.source) }

    /// The first spell check in a language loads its dictionary (can take a moment). If that happens
    /// while the user types on, the correction is skipped — so load all dictionaries up front.
    func warmUpDictionaries() { reliable = [:]; for l in layouts { _ = isWord("aura", l.lang) } }

    // MARK: tap

    func start() -> Bool {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue)
        // A listen-only tap: it only watches. An active tap that loses its permission (the user removes AURA from
        // Accessibility while it runs) makes the system hold the keyboard and clicks back for a minute or more;
        // a listen-only one can never hold anything back.
        if !CGPreflightListenEventAccess() {
            if !askedListenAccess { askedListenAccess = true; CGRequestListenEventAccess() }   // the system prompt, once
            return false
        }
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly,
                                eventsOfInterest: mask, callback: { _, type, event, _ in
            engine.handle(type, event)
        }, userInfo: nil)
        guard let tap else { return false }
        let src = CFMachPortCreateRunLoopSource(nil, tap, 0)
        tapSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    /// removes the tap at once (access lost, or about to be re-created); the app then waits for access again
    var onTapLost: (() -> Void)?
    func dropTap() {
        guard let t = tap else { return }
        CGEvent.tapEnable(tap: t, enable: false)
        CFMachPortInvalidate(t)
        if let src = tapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes) }
        tap = nil; tapSource = nil
        reset()
        auraLog.notice("tap removed: no access")
        onTapLost?()
    }
    var tapSource: CFRunLoopSource?
    private var askedListenAccess = false
    func handle(_ type: CGEventType, _ e: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(e)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // the system switched the tap off (access taken away, or a callback was too slow): drop it; the app
            // creates a fresh one a moment later if it still has access
            auraLog.notice("tap disabled by the system (\(type == .tapDisabledByTimeout ? "timeout" : "user input", privacy: .public)): dropped")
            DispatchQueue.main.async { self.dropTap() }
            return pass
        }
        if e.getIntegerValueField(.eventSourceUserData) == kMagic { return pass }
        if !active {
            if type == .keyDown, e.getIntegerValueField(.keyboardEventKeycode) == 49 {
                auraLog.notice("skip: paused (\(self.settings.enabled ? (self.frontIsGame ? "game" : "excluded app") : "turned off", privacy: .public) \(self.frontBundle, privacy: .public))")
            }
            return pass
        }

        switch type {
        case .leftMouseDown, .rightMouseDown:
            reset(); lastShiftTap = 0
        case .flagsChanged:
            handleShift(e)
        case .keyDown:
            sawOther = true; lastShiftTap = 0
            handleKey(e)
        default: break
        }
        return pass
    }

    func handleShift(_ e: CGEvent) {
        let code = e.getIntegerValueField(.keyboardEventKeycode)
        let now = ProcessInfo.processInfo.systemUptime
        guard code == 56 || code == 60 else { lastShiftTap = 0; return }
        if e.flags.contains(.maskShift) {
            if !e.flags.intersection([.maskCommand, .maskControl]).isEmpty { lastShiftTap = 0; return }
            shiftDownAt = now; sawOther = false; shiftDownAlt = e.flags.contains(.maskAlternate)
        } else {
            guard !sawOther, now - shiftDownAt < 0.3 else { lastShiftTap = 0; return }
            if now - lastShiftTap < 0.45, lastTapAlt == shiftDownAlt {
                lastShiftTap = 0
                if shiftDownAlt { DispatchQueue.main.async { self.caseCycle() } }
                else { DispatchQueue.main.async { self.doubleShift() } }
            } else { lastShiftTap = now; lastTapAlt = shiftDownAlt }
        }
    }

    /// never blocks input; heavy work runs after the tap returns
    func handleKey(_ e: CGEvent) {
        let code = UInt16(e.getIntegerValueField(.keyboardEventKeycode))
        let f = e.flags
        if !f.intersection([.maskCommand, .maskControl, .maskAlternate]).isEmpty { reset(); return }
        switch code {
        case 51: // backspace
            // a typo while the word is being typed: AURA keeps watching it. Back over the space into a finished word
            // (or into older text): the word is the user's now — not checked until the next space (double ⇧ still converts it)
            if !word.isEmpty, trailing == 0 { word.removeLast() }
            else { reset(); handsOff = true; releaseIfFieldEmpty() }
        case 49: // space (already delivered to the app)
            if handsOff { reset(); return }  // the end of the user's own word: leave it as it is
            if !word.isEmpty {
                lastWord = word; word = []; trailing = 1
                if settings.auto, settings.bindings[frontBundle] == nil {
                    let keys = lastWord, pre = before, at = ProcessInfo.processInfo.systemUptime
                    DispatchQueue.main.async { self.autoCorrect(keys, before: pre, spaceAt: at) }
                }
            } else if !lastWord.isEmpty { trailing += 1 }
        case 123...126, 115, 116, 117, 119, 121: // arrows, Home, Page Up, Forward Delete, End, Page Down: editing the text
            reset(); handsOff = true
            if code == 117 { releaseIfFieldEmpty() }
        default:
            // the user's own word: not checked, but its keys are kept — double ⇧ is an explicit command and converts it
            if handsOff { if codes.contains(code) { word.append(key(e, code)) } else { reset() }; return }  // Return, Tab…: over
            if codes.contains(code) {
                if word.isEmpty { before = lastWord.count == 1 && trailing == 1 ? lastWord : []; lastCycled = []; lastCycledLang = nil
                                  wordStartLang = ownLang ?? currentLang() }
                if trailing > 0 || !lastWord.isEmpty { lastWord = []; trailing = 0 }
                word.append(key(e, code))
            } else { reset() }
        }
    }

    func key(_ e: CGEvent, _ code: UInt16) -> Key {
        let f = e.flags
        var len = 0
        var buf = [UniChar](repeating: 0, count: 4)
        e.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &len, unicodeString: &buf)
        var ch = len == 1 ? Unicode.Scalar(buf[0]).map(Character.init) : nil
        // after AURA switched the layout itself, key events keep the letters of the old one (macOS doesn't
        // update them), while the app already types in the new one: read the key with the layout we selected.
        // (Asking the system for the current layout instead lags behind the keys when another program switches.)
        if let own = ownLang, let l = layout(own), let c = l.toChar[Key(code: code, shift: f.contains(.maskShift))] {
            let caps = f.contains(.maskAlphaShift) && !f.contains(.maskShift)
            ch = caps ? Character(c.uppercased()) : c
        }
        return Key(code: code, shift: f.contains(.maskShift), caps: f.contains(.maskAlphaShift), ch: ch)
    }

    // one-letter words: a single letter before a fixed word is fixed too («z буду» → «я буду»),
    // unless it is already a word where it was typed (English «a»)
    static let letterWords = ["uk": "авзіїоуйя", "ru": "авжикосуя", "en": "ai"]

    /// «b tot» = «и еще»: «tot» is an English word, so alone it stays; but «b» isn't a word in English and
    /// «и» is in Russian, where «еще» is a real word too — the pair says which language was meant
    func pairFix(_ keys: [Key], before: [Key]) -> Layout? {
        guard before.count == 1, let src = typedLayout(keys) else { return nil }
        let bTyped = src.text(before)
        guard Engine.letterWords[src.lang]?.contains(bTyped.lowercased()) != true else { return nil }
        for l in layouts where l.lang != src.lang && l.maps(keys) && l.maps(before) {
            let b = l.text(before), t = l.text(keys)
            guard Engine.letterWords[l.lang]?.contains(b.lowercased()) == true, !consonantRun(t) else { continue }
            if dictionaryWorks(l.lang) ? isWord(t, l.lang) : model(l.lang)?.has(t) == true { return l }
        }
        return nil
    }

    /// Return right after a word («z elfkbk⏎» in a chat): the word is checked only on a space, so the message went out
    /// unfixed. Return is held, the word fixed (if it needs it), then Return is sent on — a few milliseconds.
    func autoCorrect(_ keys: [Key], before: [Key] = [], spaceAt: Double = 0) {
        let t0 = ProcessInfo.processInfo.systemUptime
        // user kept typing meanwhile — skip
        guard lastWord == keys, word.isEmpty, trailing == 1 else {
            auraLog.notice("skip: kept typing (\(keys.count) letters, waited \(Int((t0 - spaceAt) * 1000)) ms)"); return
        }
        // the word was just switched by double ⇧: the user chose its layout, don't undo it
        // (its keys still carry the letters first typed, so the check would see the old language)
        if keys == lastCycled { return }
        noFix = ""
        // «b yt»: both «и не» (ru) and «не» alone (uk) fit; the pair that makes both words a language wins
        let found = pairFix(keys, before: before) ?? autoFix(keys)
        let ms = Int((ProcessInfo.processInfo.systemUptime - t0) * 1000)
        if ms > 100 { auraLog.notice("slow check: \(ms) ms") }
        if found == nil, noFix.hasPrefix("already a word"), keys.count >= 3, let l = typedLayout(keys), !isLatin(l.text(keys)) {
            recentLang = l.lang; recentAt = ProcessInfo.processInfo.systemUptime
        }
        if let f = found, !isLatin(f.text(keys)) { recentLang = f.lang; recentAt = ProcessInfo.processInfo.systemUptime }
        // diagnostics: the app may show other letters than the keys say (after our own layout switch the key events
        // keep the old layout's letters; Chromium apps may type those). Only a log line, no words in it.
        if found == nil, keys.count >= 3, let l = typedLayout(keys), !isLatin(l.text(keys)) { checkScreen(keys, l) }
        guard let (layout, out) = finalFix(keys, found: found) else {
            if !noFix.isEmpty { auraLog.notice("skip: \(self.noFix, privacy: .public) (\(keys.count) letters)") }
            return
        }
        if lastWord != keys || !word.isEmpty || trailing != 1 {
            auraLog.notice("skip: kept typing during a \(ms) ms check"); return
        }
        applyFix(layout, out, switching: found != nil, keys, before: before, trailing: 1)
    }

    /// What the word becomes: the layout it ends up in and its final text (after the layout fix, then the case fix).
    /// nil = nothing to change. `found` is what the layout check chose (nil = the word stays in its layout).
    func finalFix(_ keys: [Key], found: Layout?) -> (Layout, String)? {
        guard let l = found ?? typedLayout(keys) else { return nil }
        let text = l.text(keys)
        var out = text
        if settings.caseFix, let c = fixCase(text, lang: l.lang, caps: keys.dropFirst().contains { $0.caps }) { out = c }
        return found != nil || out != text ? (l, out) : nil
    }

    /// Letter case of a word: «ПРивіт» → «Привіт», «THe» → «The» (two capitals, only if the capitalized form is a word); «пРИВІТ» → «Привіт» (Caps Lock was on); a user's abbreviation → capitals («ттн» → «ТТН»).
    /// nil = leave as it is. Punctuation around the word stays. `caps` = Caps Lock was on while typing.
    func fixCase(_ word: String, lang: String, caps: Bool = false) -> String? {
        let ch = Array(word)
        guard let a = ch.firstIndex(where: \.isLetter), let b = ch.lastIndex(where: \.isLetter) else { return nil }
        let core = Array(ch[a...b])
        guard core.allSatisfy(\.isLetter) else { return nil }
        let lead = String(ch[..<a]), tail = String(ch[(b + 1)...]), s = String(core), lower = s.lowercased()
        func result(_ c: String) -> String? { c == s ? nil : lead + c + tail }
        if settings.abbrevs.contains(lower) { return result(s.uppercased()) }
        guard core.count >= 3, !settings.words.contains(lower) else { return nil }
        let doubleCapital = core[0].isUppercase && core[1].isUppercase && core.dropFirst(2).allSatisfy(\.isLowercase)
        let inverted = caps && core[0].isLowercase && core.dropFirst().allSatisfy(\.isUppercase)
        guard doubleCapital || inverted else { return nil }
        // «IDs», «PCs», «OKs»: plural of an acronym
        if doubleCapital, core.count == 3, isLatin(s), lower.hasSuffix("s") { return nil }
        // «MBps», «Gbps»: units
        if doubleCapital, isLatin(s), lower.hasSuffix("bps") { return nil }
        let fixed = String(core[0]).uppercased() + String(core.dropFirst()).lowercased()
        // (not asking whether the typed form is a word: spell checkers ignore capitals — «ПРивіт» passes)
        // no working dictionary (macOS sometimes isn't ready at launch and the check switches it off): the frequency list
        guard dictionaryWorks(lang) ? isWord(fixed, lang) : model(lang)?.has(fixed) == true else { return nil }
        return result(fixed)
    }

    /// logs when the text before the caret is not what the keys say (and which layout it does match)
    func checkScreen(_ keys: [Key], _ l: Layout) {
        let expected = l.text(keys).lowercased(), n = expected.utf16.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard self.lastWord == keys, self.word.isEmpty, self.trailing == 1,
                  let seen = self.textBeforeCaret(n + 1 + 8)?.lowercased(), !seen.isEmpty, !seen.contains(expected) else { return }
            let other = self.layouts.first { seen.contains($0.text(keys).lowercased()) }?.lang
            auraLog.notice("screen differs from keys: \(keys.count) letters, keys as \(l.lang, privacy: .public), screen matches \(other ?? "none", privacy: .public), own \(self.ownLang ?? "-", privacy: .public) in \(self.frontBundle, privacy: .public)")
        }
    }

    /// puts the fixed word on screen: `trailing` = spaces typed after it (1 after a space, 0 before Return)
    /// `out` = the final text; `switching` = the layout changes too (otherwise only the letters' case is retyped)
    func applyFix(_ fix: Layout, _ out: String, switching: Bool, _ keys: [Key], before: [Key], trailing: Int) {
        let src = typedLayout(keys), typed = src?.text(keys)
        let b = fix.text(before), bTyped = src?.text(before) ?? ""
        let fixBefore = before.count == 1 && b.count == 1 && b != bTyped
            && Engine.letterWords[fix.lang]?.contains(b.lowercased()) == true
            && Engine.letterWords[src?.lang ?? ""]?.contains(bTyped.lowercased()) != true
        // UK/RU word spelled the same in both layouts: text is already right, only switch the layout
        let shown = typed?.count ?? keys.count  // on screen: accented letters are one character
        let sp = String(repeating: " ", count: trailing)
        // a password prompt doesn't show what is typed (sudo, ssh in Terminal — macOS doesn't hide those keys from us):
        // if the app can say what's before the caret and the word isn't there, leave it alone — the layout too.
        // The app may not have drawn the last keys yet when we ask (Terminal lags a few ms), so the word counts as
        // shown when its start is there; a prompt that doesn't echo shows none of it. In any layout: the letters the
        // key events carry may be another layout's than the app typed (in Terminal 24 of 300 fixes were skipped).
        // Case-insensitive: editors capitalize the first word
        if let seen = textBeforeCaret((typed ?? out).utf16.count + sp.utf16.count + 8)?.lowercased(),
           !layouts.contains(where: { seen.contains(String($0.text(keys).prefix(2)).lowercased()) }) {
            auraLog.notice("skip: not on screen (password?) (\(keys.count) letters)"); return
        }
        // switch first, then retype: switched after the text, the macOS indicator at the caret showed the old layout
        if switching { select(fix) }
        if fixBefore { replace(count: bTyped.count + shown + 1 + trailing, with: b + " " + out + sp) }
        else if out != typed { replace(count: shown + trailing, with: out + sp) }
        if switching {
            auraLog.notice("fixed: \(src?.lang ?? "?", privacy: .public) → \(fix.lang, privacy: .public) (\(keys.count) letters\(trailing == 0 ? ", before Return" : "", privacy: .public))")
        } else { auraLog.notice("case fixed: \(fix.lang, privacy: .public) (\(keys.count) letters)") }
        Sounds.play(Sounds.auto)
    }

    // MARK: auto detection

    // the spell checker takes any two letters for a word (":D" → «ЖВ», "in" → «шт»): only common ones count
    static let twoLetterWords: [String: Set<String>] = [
        "uk": ["як", "що", "не", "та", "до", "на", "за", "по", "ти", "ми", "ви", "їх", "це", "її", "ще", "бо", "чи", "ні",
               "де", "то", "ну", "ой", "аж", "би", "зі", "із", "ця", "ці", "ті", "ок"],
        "ru": ["не", "на", "по", "за", "до", "от", "из", "во", "ко", "то", "же", "бы", "ли", "мы", "вы", "он", "её", "их",
               "да", "но", "ни", "уж", "ой", "ну", "ах", "ох", "со", "об", "ты", "та", "те", "эй", "ок"],
        "en": ["is", "in", "on", "at", "to", "it", "he", "we", "me", "my", "of", "or", "an", "as", "be", "by", "do", "go",
               "if", "no", "so", "up", "us", "am", "hi", "ok", "oh", "ah", "ha", "eh", "yo", "id"]]

    func isWord(_ s: String, _ lang: String) -> Bool {
        var w = s.trimmingCharacters(in: .punctuationCharacters.union(.symbols))
        guard w.count >= 2, w.allSatisfy(\.isLetter) || w.contains("'") || w.contains("-") else { return false }
        if w.count == 2, let set = Engine.twoLetterWords[lang] { return set.contains(w.lowercased()) }
        if w == w.uppercased() { w = w.lowercased() }  // all caps passes any spell check
        guard dictionaryWorks(lang) else { return false }
        if spell(w, lang) { return true }
        // names typed in lower case: «вінницею» is only in the dictionary as «Вінницею». Not for Latin
        // (English names like «Tot» would make gibberish a word) and not for short words
        return w.count >= 5 && !isLatin(w) && w == w.lowercased() && spell(w.prefix(1).uppercased() + w.dropFirst(), lang)
    }

    func spell(_ w: String, _ lang: String) -> Bool {
        let checker = NSSpellChecker.shared
        guard let l = checker.availableLanguages.first(where: { $0.hasPrefix(lang) }) else { return false }
        return checker.checkSpelling(of: w, startingAt: 0, language: l, wrap: false,
                                     inSpellDocumentWithTag: 0, wordCount: nil).location == NSNotFound
    }

    /// A language whose dictionary macOS hasn't downloaded (not a system language) accepts any string:
    /// English typos would turn into gibberish in it. Checked once per language on nonsense typed in its layout.
    var reliable: [String: Bool] = [:]
    func dictionaryWorks(_ lang: String) -> Bool {
        if let r = reliable[lang] { return r }
        // no dictionary at all (Belarusian): not "works" — the language model takes over
        var r = NSSpellChecker.shared.availableLanguages.contains { $0.hasPrefix(lang) }
        if r, let l = layouts.first(where: { $0.lang == lang }) {
            // nonsense from the layout's own letters (keys like Q or Z may type several characters elsewhere)
            // only the layout's own script: macOS «Russian – PC» also types a Latin «Ë», and «ËËËËËËË» passes
            // the Russian spell check (it skips Latin words) — that wrongly switched the Russian dictionary off
            let all = Array(Set(l.toChar.values.filter(\.isLetter))).sorted()
            let own = all.filter { !isLatin(String($0)) }
            let letters = own.count >= 3 ? own : all
            if letters.count >= 3 {
                for w in [String(repeating: letters[0], count: 7), String((0..<7).map { letters[1 + $0 % 2] })] where spell(w, lang) { r = false }
            }
        }
        reliable[lang] = r
        auraLog.notice("dictionary \(lang, privacy: .public): \(r ? "on" : "off", privacy: .public)")
        return r
    }

    /// five Cyrillic consonants in a row: gibberish the spell checker let through ("brachii," → «икфсршшб»)
    func consonantRun(_ s: String) -> Bool {
        var run = 0
        for c in s.lowercased() { run = "бвгґджзйклмнпрстфхцчшщ".contains(c) ? run + 1 : 0; if run >= 5 { return true } }
        return false
    }

    /// Code typed in the wrong layout — «сщтіщдуюдщп(ещефд)ж» is console.log(total); — is one "word" with
    /// dots and brackets: starts with a letter, and every part (split on non-letters and camelCase) is a word.
    func isCode(_ t: String, _ lang: String) -> Bool {
        guard t.first?.isLetter == true else { return false }
        var parts: [String] = [], cur = ""
        for c in t {
            if !c.isLetter { if !cur.isEmpty { parts.append(cur) }; cur = ""; continue }
            if c.isUppercase, let last = cur.last, last.isLowercase { parts.append(cur); cur = "" }
            cur.append(c)
        }
        if !cur.isEmpty { parts.append(cur) }
        let punctuated = t.trimmingCharacters(in: CharacterSet(charactersIn: ";,.)")).contains { !$0.isLetter }
        return (parts.count > 1 || punctuated) && parts.contains { $0.count >= 3 }
            && parts.allSatisfy { $0.count >= 2 && isWord($0.lowercased(), lang) }
    }

    func isCyrillic(_ s: String) -> Bool { s.unicodeScalars.contains { (0x400...0x52F).contains($0.value) } }
    func isLatin(_ s: String) -> Bool { s.unicodeScalars.allSatisfy { $0.value < 0x250 } }

    /// Layout the word was really typed in: the one whose characters match what the key events produced
    /// (prefers the system's current layout when several match, e.g. UK/RU words without і/ы).
    func typedLayout(_ keys: [Key]) -> Layout? {
        let sys = layout(currentLang())
        let actual = String(keys.compactMap(\.ch))
        guard actual.count == keys.count else { return sys }
        let matches = layouts.filter { $0.text(keys) == actual }
        if let sys, matches.contains(where: { $0 === sys }) { return sys }
        return matches.first ?? sys
    }

    var models: [String: LangModel?] = [:]
    func model(_ lang: String) -> LangModel? {
        if let m = models[lang] { return m }
        let m = LangModel(lang); models[lang] = m; return m
    }
    /// how much more typical `t` is of its language than `typed` of its own (trigram costs); nil without both models
    func margin(_ typed: String, _ cur: String, _ t: String, _ lang: String) -> Double? {
        guard let a = model(cur), let b = model(lang) else { return nil }
        // a comma or «?» stuck to the word («шейдерам,») is an unknown trigram on one side only: judge the letters
        let trim = { (w: String) in w.trimmingCharacters(in: CharacterSet(charactersIn: ",.;:!?")) }
        let (x, y) = (trim(typed), trim(t))
        return a.cost(x.count >= 2 ? x : typed) - b.cost(y.count >= 2 ? y : t)
    }
    // tuned on ~2000 words per language (tools/langmodel.py): a word with no dictionary must look clearly
    // more typical than what was typed; a real dictionary word only somewhat more
    static let marginNeeded = 20.0, marginForDictWord = 5.0, marginCyrillic = 11.0  // Belarusian ↔ Russian: «длінный» 13, true «сіла» 4

    var noFix = ""  // why autoFix found nothing (for the log)
    /// language of the last non-Latin word that was fixed or typed right (not set by the tests, which call autoFix alone)
    var recentLang: String? = nil, recentAt = 0.0
    func autoFix(_ keys: [Key]) -> Layout? {
        guard keys.count >= 2, let cur = typedLayout(keys) else { noFix = keys.count >= 2 ? "layout not recognized" : ""; return nil }
        let typed = cur.text(keys)
        let curDict = dictionaryWorks(cur.lang)
        // typed in a language we can't check at all: it may well be right — leave it
        guard curDict || model(cur.lang) != nil else { noFix = "no dictionary for \(cur.lang)"; return nil }
        // an abbreviation typed as it is stays (its letters are made capital by fixCase), it is never layout-switched
        let abbrevs = settings.caseFix ? settings.abbrevs : []
        if abbrevs.contains(typed.lowercased()) { noFix = "abbreviation"; return nil }
        // «THe» is a mistyped «The», not a word of another layout («ЕРу»): the case fix handles it
        if settings.caseFix, fixCase(typed, lang: cur.lang, caps: keys.dropFirst().contains { $0.caps }) != nil { noFix = "case only"; return nil }
        if settings.words.contains(typed.lowercased()) || (curDict ? isWord(typed, cur.lang) : model(cur.lang)!.has(typed)) { noFix = "already a word in \(cur.lang)"; return nil }
        // every other layout is a candidate; take the strongest kind of evidence, not the first layout in the
        // list: with RU, UK, EN in that order «ghbdsn» must become the Ukrainian word «привіт», not the
        // Russian look-alike «привыт» that only passes on letter statistics
        // equal evidence (both are dictionary words: «было» / «біло» from the same keys) — a frequent word of its
        // language wins over a rare one, then the letter statistics decide
        // «ns» is both «ты» (ru) and «ті» (uk): with equal evidence the language of the last non-Latin word wins
        let recent = ProcessInfo.processInfo.systemUptime - recentAt < 600 ? recentLang : nil
        var best: (tier: Int, freq: Int, rec: Int, m: Double, l: Layout)? = nil
        let start = index(cur.lang)
        for i in 1..<max(layouts.count, 1) {
            let l = layouts[(start + i) % layouts.count]
            let t = l.text(keys)
            // same text in two Latin layouts (an English typo that is a Polish word): nothing to fix.
            // Cyrillic UK/RU words spelled the same still switch the layout — that's what users mix up.
            if t == typed, isLatin(t) { continue }
            guard l.maps(keys) else { continue }
            let abbrev = abbrevs.contains(t.lowercased())  // «nny» typed in English = «ттн»: the strongest evidence
            guard abbrev || !consonantRun(t) else { continue }
            let m = margin(typed, cur.lang, t, l.lang) ?? 0
            var tier = 0
            if abbrev { tier = 5 }
            else if settings.words.contains(t.lowercased()) { tier = 4 }  // the user's own word («скілі»)
            else if isLatin(t), !isLatin(typed), isCode(t, l.lang) { tier = 3 }
            else if dictionaryWorks(l.lang) {
                // without the typed language's dictionary, also ask the models which side looks real;
                // close languages in one script (Belarusian ↔ Russian) need the stricter margin
                let need = isCyrillic(typed) && isCyrillic(t) ? Engine.marginCyrillic : Engine.marginForDictWord
                if isWord(t, l.lang), curDict || m >= need { tier = 2 }
                // slang the dictionary doesn't know («гуглити»): long, another script, clearly typical of the language
                else if t.count >= 5, isLatin(typed) != isLatin(t), m >= Engine.marginNeeded { tier = 1 }
            } else if let lm = model(l.lang) {
                // no dictionary there: a frequent word, or clearly more typical than what was typed
                if lm.has(t) { tier = 2 } else if m >= Engine.marginNeeded { tier = 1 }
            }
            let freq = model(l.lang)?.has(t) == true ? 1 : 0
            let rec = l.lang == recent ? 1 : 0
            if tier > 0, best == nil || (tier, freq, rec, m) > (best!.tier, best!.freq, best!.rec, best!.m) { best = (tier, freq, rec, m, l) }
        }
        if best == nil { noFix = "not a word in \(cur.lang), nothing better in other layouts" }
        return best?.l
    }

    // MARK: double shift

    func doubleShift() {
        Sounds.play(Sounds.shift)
        let sel = axSelectedText()
        if let sel, !sel.isEmpty { convertSelection(sel); return }
        // the word being typed, or the previous one right after a single space; after two or more spaces the text
        // stays as it is and double ⇧ only switches the layout
        let keys = !word.isEmpty ? word : trailing == 1 ? lastWord : []
        if !keys.isEmpty { cycleWord(keys, trailing: word.isEmpty ? trailing : 0); return }
        // the app says nothing is selected and can be trusted: switch now, without the ⌘C round trip (up to 0.4 s)
        if sel != nil, !webEngine(frontBundle) { cycleLayout(); return }
        clipboardSelection { sel in
            if let sel, !sel.isEmpty, !isCopiedLine(sel) { self.convertSelection(sel) } else { self.cycleLayout() }
        }
    }

    func next(after lang: String?) -> Layout? {
        layouts.isEmpty ? nil : layouts[(index(lang) + 1) % layouts.count]
    }

    func cycleLayout() { if let n = next(after: currentLang()) { select(n) } }

    /// the word the last double ⇧ converted and where it went: pressing again keeps cycling from there
    /// (right after a switch the system may still report the old layout)
    var lastCycled: [Key] = [], lastCycledLang: String? = nil

    func cycleWord(_ keys: [Key], trailing: Int) {
        // first press: the most likely layout (as auto-correction would pick it), then the next ones in turn
        let again = keys == lastCycled && lastCycledLang != nil
        // (not the layout the word is already in: right after auto-correction that would change nothing)
        let cur = currentLang()
        guard let n = (again ? nil : autoFix(keys).flatMap { $0.lang == cur ? nil : $0 }) ?? next(after: again ? lastCycledLang : cur) else { return }
        lastCycled = keys; lastCycledLang = n.lang
        auraLog.notice("double ⇧: word → \(n.lang, privacy: .public)")
        let shown = typedLayout(keys)?.text(keys).count ?? keys.count
        select(n)  // before the text: see autoCorrect
        replace(count: shown + trailing, with: n.text(keys) + String(repeating: " ", count: trailing))
    }

    func convertSelection(_ text: String) {
        guard !layouts.isEmpty else { return }
        var srcIdx: Int
        if text == lastSelOut, lastSelLang < layouts.count { srcIdx = lastSelLang } else {
            let cur = index(currentLang())
            let scores = layouts.map { l in text.filter { $0.isLetter && l.keys(for: $0) != nil }.count }
            srcIdx = scores.indices.max { a, b in
                scores[a] != scores[b] ? scores[a] < scores[b] : (a != cur && b == cur)
            } ?? cur
        }
        let srcL = layouts[srcIdx], dstIdx = (srcIdx + 1) % layouts.count, dst = layouts[dstIdx]
        // runs of convertible characters go through the keys (so accents compose), the rest stays
        var out = "", run: [Key] = []
        for c in text {
            if let ks = srcL.keys(for: c), ks.allSatisfy({ dst.toChar[$0] != nil }) { run += ks; continue }
            out += dst.text(run) + String(c); run = []
        }
        out += dst.text(run)
        typeText(out)
        for _ in 0..<out.count { postKey(123, flags: .maskShift) } // reselect (⇧← moves by character)
        lastSelOut = out; lastSelLang = dstIdx
        select(dst)
    }

    // MARK: letter case (⌥ + double ⇧)

    /// the word whose case the last ⌥ + double ⇧ changed and what it is now: pressing again keeps cycling
    var lastCase: (keys: [Key], text: String)? = nil

    func caseCycle() {
        Sounds.play(Sounds.shift)
        let sel = axSelectedText()
        if let sel, !sel.isEmpty { caseSelection(sel); return }
        let keys = !word.isEmpty ? word : trailing == 1 ? lastWord : []
        if !keys.isEmpty { caseWord(keys, trailing: word.isEmpty ? trailing : 0); return }
        if sel != nil, !webEngine(frontBundle) { return }
        clipboardSelection { sel in
            if let sel, !sel.isEmpty, !isCopiedLine(sel) { self.caseSelection(sel) }
        }
    }

    func caseSelection(_ text: String) {
        let out = nextCase(text)
        guard out != text else { return }
        auraLog.notice("⌥ double ⇧: selection case (\(text.count) characters)")
        typeText(out)
        for _ in 0..<out.count { postKey(123, flags: .maskShift) }  // reselect, so the next press goes on
    }

    func caseWord(_ keys: [Key], trailing: Int) {
        // the word as it is on screen now (its case may be fixed already): ask the app, else the keys in the current layout
        let l = layout(ownLang ?? currentLang()) ?? typedLayout(keys)
        var text = l?.text(keys) ?? ""
        if let last = lastCase, last.keys == keys { text = last.text }
        else if text.isEmpty { return }
        else if let seen = textBeforeCaret(text.utf16.count + trailing), seen.utf16.count == text.utf16.count + trailing,
                seen.hasSuffix(String(repeating: " ", count: trailing)) {
            let w = String(seen.dropLast(trailing))
            if w.lowercased() == text.lowercased() { text = w }
        }
        let out = nextCase(text)
        guard out != text else { return }
        lastCase = (keys, out)
        auraLog.notice("⌥ double ⇧: word case (\(keys.count) letters)")
        replace(count: text.count + trailing, with: out + String(repeating: " ", count: trailing))
    }

    // MARK: selection

    /// the last `n` characters before the caret in the focused element, if the app tells (nil = it doesn't);
    /// "" for a password field
    func textBeforeCaret(_ n: Int) -> String? {
        var f: CFTypeRef?
        guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &f) == .success,
              let f else { return nil }
        let el = f as! AXUIElement
        var sub: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXSubroleAttribute as CFString, &sub)
        if sub as? String == kAXSecureTextFieldSubrole as String { return "" }
        var r: CFTypeRef?, range = CFRange()
        guard AXUIElementCopyAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, &r) == .success, let r,
              AXValueGetValue(r as! AXValue, .cfRange, &range), range.location > 0 else { return nil }
        var q = CFRange(location: max(0, range.location - n), length: min(n, range.location))
        guard let qv = AXValueCreate(.cfRange, &q) else { return nil }
        var t: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(el, kAXStringForRangeParameterizedAttribute as CFString, qv, &t) == .success
        else { return nil }
        return t as? String
    }

    /// the selection as the focused element reports it: "" = nothing selected, nil = the app doesn't say
    func axSelectedText() -> String? {
        let sys = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let el = focused else { return nil }
        var sel: CFTypeRef?
        AXUIElementCopyAttributeValue(el as! AXUIElement, kAXSelectedTextAttribute as CFString, &sel)
        guard let s = sel as? String else { return nil }
        if s.isEmpty {  // empty text with a non-empty range: the app reports it wrong
            var r: CFTypeRef?, range = CFRange()
            guard AXUIElementCopyAttributeValue(el as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &r) == .success,
                  let r, AXValueGetValue(r as! AXValue, .cfRange, &range), range.length == 0 else { return nil }
        }
        return s
    }

    /// Chrome-based browsers and Electron apps (VS Code, Slack, Discord) report an empty selection while
    /// text is selected when their accessibility is on: there the "" isn't trusted
    var webEngineCache: [String: Bool] = [:]
    func webEngine(_ bundle: String) -> Bool {
        if let r = webEngineCache[bundle] { return r }
        var r = true  // unknown app: the safe way
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) {
            let fw = (try? FileManager.default.contentsOfDirectory(atPath: url.appendingPathComponent("Contents/Frameworks").path)) ?? []
            r = fw.contains { $0.contains("Electron") || $0.contains("Chrom") || $0.hasSuffix(" Framework.framework") }
        }
        webEngineCache[bundle] = r
        return r
    }

    /// Copies the selection with ⌘C and puts the user's clipboard back exactly as it was
    /// (every item and type: images, files, rich text — not only plain text).
    func clipboardSelection(_ done: @escaping (String?) -> Void) {
        let pb = NSPasteboard.general
        let saved: [NSPasteboardItem] = (pb.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for t in item.types { if let d = item.data(forType: t) { copy.setData(d, forType: t) } }
            return copy
        }
        let count = pb.changeCount
        func restore() { pb.clearContents(); if !saved.isEmpty { pb.writeObjects(saved) } }
        postKey(8, flags: .maskCommand) // ⌘C
        // slow apps may copy late: wait up to 0.4 s, and if the copy lands even later, still restore
        func poll(_ left: Int) {
            if pb.changeCount != count {
                let s = pb.string(forType: .string); restore(); done(s); return
            }
            if left > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { poll(left - 1) }; return }
            done(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { if pb.changeCount == count + 1 { restore() } }
        }
        poll(20)
    }

    // MARK: synthetic input

    func postKey(_ code: CGKeyCode, flags: CGEventFlags = []) {
        for down in [true, false] {
            guard let e = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: down) else { continue }
            e.flags = flags
            e.setIntegerValueField(.eventSourceUserData, value: kMagic)
            e.post(tap: .cghidEventTap)
        }
    }

    func typeText(_ s: String) {
        let u = Array(s.utf16)
        for i in stride(from: 0, to: u.count, by: 16) {
            var chunk = Array(u[i..<min(i + 16, u.count)])
            for down in [true, false] {
                guard let e = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: down) else { continue }
                e.flags = []
                e.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
                e.setIntegerValueField(.eventSourceUserData, value: kMagic)
                e.post(tap: .cghidEventTap)
            }
        }
    }

    func replace(count: Int, with s: String) {
        for _ in 0..<count { postKey(51) }
        typeText(s)
    }
}

/// Next letter case of a text: lowercase → Sentence case → UPPERCASE → lowercase; anything mixed → lowercase.
func nextCase(_ s: String) -> String {
    func sentence(_ t: String) -> String {
        var out = "", cap = true, pending = false
        for c in t.lowercased() {
            if c.isLetter { out += cap ? c.uppercased() : String(c); cap = false; pending = false; continue }
            if c.isNewline { cap = true; pending = false }
            else if ".!?…".contains(c) { pending = true }
            else if c.isWhitespace { if pending { cap = true; pending = false } }
            else if c.isNumber { cap = false; pending = false }
            out.append(c)
        }
        return out
    }
    let stages = [{ (t: String) in t.lowercased() }, sentence, { (t: String) in t.uppercased() }]
    let state = s == s.lowercased() ? 0 : s == sentence(s) ? 1 : s == s.uppercased() ? 2 : -1
    if state < 0 { return s.lowercased() }
    for i in 1...3 { let c = stages[(state + i) % 3](s); if c != s { return c } }
    return s
}
