import Cocoa
import Carbon
import ServiceManagement
import ApplicationServices

// single instance: a second copy would double every correction. Two copies started at the same moment
// (login item + manual launch) see each other — the earliest launched (then the lowest pid) stays.
let me = NSRunningApplication.current
func launchedBefore(_ a: NSRunningApplication, _ b: NSRunningApplication) -> Bool {
    let da = a.launchDate ?? .distantFuture, db = b.launchDate ?? .distantFuture
    return da != db ? da < db : a.processIdentifier < b.processIdentifier
}
if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
    .contains(where: { $0 != me && launchedBefore($0, me) }) { exit(0) }

let engine = Engine()

// MARK: - App / menu

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var item: NSStatusItem!
    let menu = NSMenu()
    var s: Settings { engine.settings }

    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        item.menu = menu
        updateTitle()
        installMainMenu()

        if UserDefaults.standard.object(forKey: "loginSet") == nil {
            try? SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: "loginSet")
        }

        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
                                                            object: nil, queue: .main) { _ in
            let now = currentLang()
            if now != engine.ownLang {  // the user switched: key events carry the right letters again
                engine.ownLang = nil
                // …in the middle of a word: they're mixing layouts on purpose («RghРак») — it's their word
                // (macOS sometimes repeats or delays the notice: only a real change from the word's layout counts)
                if !engine.word.isEmpty, now != engine.wordStartLang { engine.reset(); engine.handsOff = true }
            }
            auraLog.notice("layout now: \(now ?? "?", privacy: .public) in \(engine.frontBundle, privacy: .public)")
            self.updateTitle()
        }
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
                                                            object: nil, queue: .main) { _ in engine.layouts = loadLayouts(); engine.codes = engine.allCodes; engine.lastSelOut = nil; engine.warmUpDictionaries() }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil, queue: .main) { note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let id = app.bundleIdentifier, id != Bundle.main.bundleIdentifier else { return }
            engine.frontBundle = id
            engine.frontIsGame = isGame(app)
            engine.recent = Array(([id] + engine.recent.filter { $0 != id }).prefix(6))
            engine.reset()
            if engine.settings.enabled, let lang = engine.settings.bindings[id], let l = engine.layout(lang) { engine.select(l) }
        }

        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        engine.onTapLost = { [weak self] in self?.item.button?.title = "⚠︎"; DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self?.startTap() } }
        startTap()
        // the selection-changed notification is sometimes missed — re-check the indicator twice a second
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            if engine.tap != nil, !AXIsProcessTrusted() { engine.dropTap(); return }
            self.updateTitle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { engine.warmUpDictionaries() }
        if CommandLine.arguments.contains("--settings") { SettingsWindow.shared.show() }
    }

    /// While the Settings window is open the app is a regular one (Dock, ⌘Tab): it needs ⌘, ⌘W ⌘Q
    func installMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        let st = ClosureItem(title: L("settings"), action: { SettingsWindow.shared.show() }, key: ","); appMenu.addItem(st)
        appMenu.addItem(.separator())
        appMenu.addItem(ClosureItem(title: L("quit"), action: { NSApp.terminate(nil) }, key: "q"))
        let winItem = NSMenuItem(); main.addItem(winItem)
        let winMenu = NSMenu(); winItem.submenu = winMenu
        winMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        NSApp.mainMenu = main
    }

    var retrying = false
    func startTap() {
        guard engine.tap == nil else { return }
        NSLog("AURA trusted=\(AXIsProcessTrusted()) listen=\(CGPreflightListenEventAccess()) layouts=\(engine.layouts.map(\.lang)) spell=\(NSSpellChecker.shared.availableLanguages) cur=\(currentLang() ?? "nil")")
        // listen-only taps are created even without access but then receive nothing
        if AXIsProcessTrusted(), engine.start() { retrying = false; NSLog("AURA tap ok"); updateTitle(); return }
        item.button?.title = "⚠︎"
        if retrying { return }
        retrying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.retrying = false; self.startTap() }
    }

    func updateTitle() {
        guard engine.tap != nil else { return }
        let l = displayCode(currentLang())
        let title = (engine.active ? l : l.lowercased()) + (updateDue() ? "•" : "")
        if item.button?.title != title { item.button?.title = title }
    }

    func add(_ m: NSMenu, _ title: String, _ on: Bool? = nil, enabled: Bool = true, icon: String? = nil, key: String = "", _ action: (() -> Void)? = nil) {
        let i = ClosureItem(title: title, action: action, key: key)
        if let icon { i.image = symbol(icon) }
        if let on { i.state = on ? .on : .off }
        i.isEnabled = enabled && action != nil
        m.addItem(i)
    }

    /// Opens an email to the developer with version, macOS and layouts already filled in.
    func reportProblem() {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let body = "\(L("reportBody"))\n\n\n---\nAURA Switcher \(ver) · macOS \(os) · \(engine.layouts.map { displayCode($0.lang) }.joined(separator: ", "))"
        var c = URLComponents(); c.scheme = "mailto"; c.path = "auraswitcher@gmail.com"
        c.queryItems = [URLQueryItem(name: "subject", value: "AURA Switcher \(ver) — macOS"), URLQueryItem(name: "body", value: body)]
        if let url = c.url { NSWorkspace.shared.open(url) }
    }

    /// something changed from the menu: refresh the indicator and the Settings window
    func changed() { updateTitle(); SettingsModel.shared.reload() }

    func menuNeedsUpdate(_ m: NSMenu) {
        m.removeAllItems()
        add(m, L("enabled"), s.enabled, icon: "power") { self.s.enabled.toggle(); self.changed() }
        add(m, L("auto"), s.auto, enabled: s.enabled, icon: "wand.and.stars") { self.s.auto.toggle(); self.changed() }
        if engine.tap == nil { add(m, L("access"), enabled: true, icon: "exclamationmark.triangle") {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!) } }
        m.addItem(.separator())

        let id = engine.frontBundle
        add(m, L("app") + appDisplayName(id), icon: "macwindow")
        if engine.frontIsGame { add(m, L("game"), icon: "gamecontroller") }
        let ex = s.excluded.contains(id)
        add(m, L("exclude"), ex, icon: "nosign") {
            self.s.excluded = ex ? self.s.excluded.filter { $0 != id } : self.s.excluded + [id]
            self.changed()
        }
        let langMenu = NSMenu()
        add(langMenu, L("noBinding"), s.bindings[id] == nil) { self.s.bindings[id] = nil; self.changed() }
        for l in engine.layouts {
            add(langMenu, langName(l.lang), s.bindings[id] == l.lang) { self.s.bindings[id] = l.lang; engine.select(l); self.changed() }
        }
        let li = NSMenuItem(title: L("appLang"), action: nil, keyEquivalent: "")
        li.image = symbol("globe")
        li.submenu = langMenu
        m.addItem(li)
        m.addItem(.separator())

        if updateDue() {
            add(m, L("updateDue"), icon: "arrow.down.circle") {
                self.s.updateCheckedAt = Date().timeIntervalSince1970
                self.changed()
                Updater.check()
            }
        }
        add(m, L("settings"), icon: "gearshape", key: ",") { SettingsWindow.shared.show() }
        add(m, L("quit"), icon: "xmark.circle", key: "q") { NSApp.terminate(nil) }
    }
}

func symbol(_ name: String) -> NSImage? { NSImage(systemSymbolName: name, accessibilityDescription: nil) }

final class ClosureItem: NSMenuItem {
    var handler: (() -> Void)?
    init(title: String, action: (() -> Void)?, key: String = "") {
        handler = action
        super.init(title: title, action: #selector(run), keyEquivalent: key)
        target = self
    }
    required init(coder: NSCoder) { fatalError() }
    @objc func run() { handler?() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
