import SwiftUI
import Cocoa
import ServiceManagement
import UniformTypeIdentifiers

// Settings window (SwiftUI, macOS 13): sidebar on the left, content on the right — like Keychain Access.
// To add a section: a case in `Pane` (+ its title/icon/section) and a branch in `SettingsView.detail`.
// To add a column to a list: one more `TableColumn` in the pane's `columns` closure (see `ListPane`).

// MARK: - Model

/// One observable wrapper over `engine.settings`, so the menu and the window never disagree:
/// every change is written through at once (the engine reads settings on use), `reload()` pulls changes made elsewhere.
final class SettingsModel: ObservableObject {
    static let shared = SettingsModel()
    private var loading = false
    private var s: Settings { engine.settings }

    @Published var enabled = true { didSet { guard !loading else { return }; s.enabled = enabled; delegate.updateTitle() } }
    @Published var auto = true { didSet { guard !loading else { return }; s.auto = auto } }
    @Published var caseFix = true { didSet { guard !loading else { return }; s.caseFix = caseFix } }
    @Published var sound = true { didSet { guard !loading else { return }; s.sound = sound; if sound { Sounds.play(Sounds.auto) } } }
    @Published var uiLang: String? = nil { didSet { guard !loading else { return }; s.uiLang = uiLang; delegate.updateTitle() } }
    @Published var words: [String] = [] { didSet { guard !loading else { return }; s.words = words } }
    @Published var abbrevs: [String] = [] { didSet { guard !loading else { return }; s.abbrevs = abbrevs } }
    @Published var excluded: [String] = [] { didSet { guard !loading else { return }; s.excluded = excluded } }
    @Published var bindings: [String: String] = [:] { didSet { guard !loading else { return }; s.bindings = bindings } }
    @Published var login = false
    @Published var updateIsDue = false

    init() { reload() }

    func reload() {
        loading = true; defer { loading = false }
        enabled = s.enabled; auto = s.auto; caseFix = s.caseFix; sound = s.sound; uiLang = s.uiLang
        words = s.words; abbrevs = s.abbrevs; excluded = s.excluded; bindings = s.bindings
        login = SMAppService.mainApp.status == .enabled
        updateIsDue = updateDue()
    }

    func setLogin(_ on: Bool) {
        if on { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        login = SMAppService.mainApp.status == .enabled
    }
}

// MARK: - App helpers

func appDisplayName(_ id: String) -> String {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return id }
    return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
}

func appIcon(_ id: String) -> NSImage {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else {
        return NSWorkspace.shared.icon(for: .applicationBundle)
    }
    return NSWorkspace.shared.icon(forFile: url.path)
}

/// «Choose app…» → bundle id of the picked .app
func pickAppBundleID() -> String? {
    let p = NSOpenPanel()
    p.allowedContentTypes = [.applicationBundle]
    p.allowsMultipleSelection = false
    p.directoryURL = URL(fileURLWithPath: "/Applications")
    p.prompt = L("add")
    guard p.runModal() == .OK, let url = p.url else { return nil }
    return Bundle(url: url)?.bundleIdentifier
}

private func noEllipsis(_ s: String) -> String { s.replacingOccurrences(of: "…", with: "").trimmingCharacters(in: .whitespaces) }

// MARK: - Sidebar structure

enum Pane: Hashable {
    case general, shortcuts, words, abbrevs, excluded, bindings, about

    /// sidebar sections in order: (title key or nil, panes)
    static let sections: [(String?, [Pane])] = [
        ("secGeneral", [.general, .shortcuts]),
        ("secWords", [.words, .abbrevs]),
        ("secApps", [.excluded, .bindings]),
        (nil, [.about]),
    ]

    var title: String {
        switch self {
        case .general: return L("secGeneral")
        case .shortcuts: return L("secShortcuts")
        case .words: return noEllipsis(L("words"))
        case .abbrevs: return noEllipsis(L("abbrevs"))
        case .excluded: return L("exclusions")
        case .bindings: return L("bindings")
        case .about: return L("secAbout")
        }
    }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .words: return "text.book.closed"
        case .abbrevs: return "textformat.size"
        case .excluded: return "nosign"
        case .bindings: return "globe"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Root view

struct SettingsView: View {
    @EnvironmentObject var m: SettingsModel
    @State private var pane: Pane? = .general

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {   // always visible: no collapse
            List(selection: $pane) {
                ForEach(Array(Pane.sections.enumerated()), id: \.offset) { _, sec in
                    Section(sec.0.map { L($0) } ?? "") {
                        ForEach(sec.1, id: \.self) { p in Label(p.title, systemImage: p.icon).tag(p) }
                    }
                }
            }
            .id(m.uiLang ?? "")   // a List keeps its rows: rebuild them when the menu language changes
            .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 260)
        } detail: {
            detail(pane ?? .general).navigationTitle((pane ?? .general).title)
        }
    }

    @ViewBuilder func detail(_ p: Pane) -> some View {
        switch p {
        case .general: GeneralPane()
        case .shortcuts: ShortcutsPane()
        case .words: WordsPane(info: L("wordsDesc"), prompt: "хз, ща, яж", keyPath: \.words)
        case .abbrevs: WordsPane(info: L("abbrevsDesc"), prompt: "ттн, pdf, ДСТУ", keyPath: \.abbrevs)
        case .excluded: ExcludedPane()
        case .bindings: BindingsPane()
        case .about: AboutPane()
        }
    }
}

// MARK: - General / Shortcuts / About

struct GeneralPane: View {
    @EnvironmentObject var m: SettingsModel
    var body: some View {
        Form {
            Section {
                Toggle(L("enabled"), isOn: $m.enabled)
                Toggle(L("auto"), isOn: $m.auto).disabled(!m.enabled)
                Toggle(L("caseFix"), isOn: $m.caseFix).disabled(!m.enabled || !m.auto)
                Toggle(L("sound"), isOn: $m.sound).disabled(!m.enabled)
            }
            Section {
                Toggle(L("login"), isOn: Binding(get: { m.login }, set: { m.setLogin($0) }))
                Picker(L("uiLang"), selection: $m.uiLang) {
                    Text(L("system")).tag(String?.none)
                    Divider()
                    ForEach(Array(zip(uiLangs, uiLangNames)), id: \.0) { c, n in Text(n).tag(String?.some(c)) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutsPane: View {
    @EnvironmentObject var m: SettingsModel
    /// «Double ⇧ — convert word/selection» → ("Double ⇧", "convert word/selection")
    private func split(_ s: String) -> (String, String) {
        guard let r = s.range(of: " — ") else { return (s, "") }
        return (String(s[..<r.lowerBound]), String(s[r.upperBound...]))
    }
    var body: some View {
        Form {
            Section {
                ForEach(["hint", "caseHint"], id: \.self) { k in
                    let (keys, what) = split(L(k))
                    LabeledContent {
                        Text(keys).font(.system(.body, design: .rounded).weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                    } label: { Text((what.isEmpty ? keys : what).prefix(1).uppercased() + (what.isEmpty ? keys : what).dropFirst()) }
                }
            } footer: { Text(L("shNote")) }
        }
        .formStyle(.grouped)
    }
}

struct AboutPane: View {
    @EnvironmentObject var m: SettingsModel
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AURA Switcher").font(.title2.weight(.semibold))
                        Text("\(L("version")) \(version) beta · 🇺🇦").foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
            }
            Section {
                Button { check() } label: {
                    Label(m.updateIsDue ? L("updateDue") : L("update"), systemImage: "arrow.triangle.2.circlepath")
                }
                Button { delegate.reportProblem() } label: { Label(L("report"), systemImage: "envelope") }
                Button { NSWorkspace.shared.open(URL(string: "https://donatello.to/aura-switcher")!) } label: {
                    Label(L("donate"), systemImage: "cup.and.saucer")
                }
                Button { NSWorkspace.shared.open(URL(string: "https://github.com/klbk/aura-switcher-app")!) } label: {
                    Label(L("origRepo"), systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            .buttonStyle(.link)
        }
        .formStyle(.grouped)
    }
    private func check() {
        engine.settings.updateCheckedAt = Date().timeIntervalSince1970
        delegate.updateTitle()
        m.reload()
        Updater.check()
    }
}

// MARK: - Reusable list (3B: add columns / sidebar items here)

enum AddMode {
    /// «+» shows a text field; Enter commits
    case text(prompt: String, commit: (String) -> Void)
    /// «+» is a menu (apps: choose / recent)
    case menu(AnyView)
}

/// Table + search + «+» / «−» bar. A pane supplies rows, columns and what add/remove do.
struct ListPane<Row: Identifiable & Hashable, Columns: TableColumnContent>: View
    where Row.ID == String, Columns.TableRowValue == Row, Columns.TableColumnSortComparator == Never {
    let info: String
    let rows: [Row]
    let matches: (Row, String) -> Bool
    let add: AddMode
    let remove: (Set<String>) -> Void
    @TableColumnBuilder<Row, Never> let columns: () -> Columns

    @State private var query = ""
    @State private var selection = Set<String>()
    @State private var adding = false
    @State private var text = ""
    @FocusState private var focused: Bool

    private var shown: [Row] { query.isEmpty ? rows : rows.filter { matches($0, query) } }

    var body: some View {
        VStack(spacing: 0) {
            Text(info).font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).padding([.horizontal, .top], 16).padding(.bottom, 10)
            Table(shown, selection: $selection) {
                columns()
                TableColumn("") { (r: Row) in
                    Button { remove([r.id]); selection.remove(r.id) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.secondary).help(L("remove"))
                }.width(28)
            }
                .overlay { if rows.isEmpty { Text(L("empty")).foregroundStyle(.secondary) } }
            Divider()
            HStack(spacing: 6) {
                switch add {
                case .text:
                    Button { adding.toggle(); focused = adding } label: { Image(systemName: "plus") }.help(L("add"))
                case .menu(let menu):
                    Menu { menu } label: { Image(systemName: "plus") }.menuStyle(.borderlessButton).fixedSize().help(L("add"))
                }
                Button { remove(selection); selection = [] } label: { Image(systemName: "minus") }
                    .disabled(selection.isEmpty).help(L("remove"))
                if adding, case .text(let prompt, let commit) = add {
                    TextField(prompt, text: $text).textFieldStyle(.roundedBorder).focused($focused)
                        .onSubmit { commit(text); text = ""; adding = false }
                        .onExitCommand { text = ""; adding = false }
                }
                Spacer()
            }
            .buttonStyle(.borderless).padding(8)
        }
        .searchable(text: $query, prompt: L("search"))
    }
}

struct WordRow: Identifiable, Hashable { let id: String }

/// «My words» and «Abbreviations»: both are lists of lowercase strings
struct WordsPane: View {
    @EnvironmentObject var m: SettingsModel
    let info: String, prompt: String
    let keyPath: ReferenceWritableKeyPath<SettingsModel, [String]>

    var body: some View {
        let list = m[keyPath: keyPath]
        ListPane(info: info,
                 rows: list.sorted { $0.localizedStandardCompare($1) == .orderedAscending }.map(WordRow.init),
                 matches: { $0.id.localizedCaseInsensitiveContains($1) },
                 add: .text(prompt: prompt) { input in
                     let new = parseWords(input).filter { !list.contains($0) }
                     if !new.isEmpty { m[keyPath: keyPath] = list + new }
                 },
                 remove: { ids in m[keyPath: keyPath] = list.filter { !ids.contains($0) } }) {
            TableColumn(L("colWord"), value: \WordRow.id)
        }
    }
}

// MARK: - Apps

struct AppRow: Identifiable, Hashable { let id: String }

struct AppCell: View {
    let id: String
    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: appIcon(id)).resizable().frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 0) {
                Text(appDisplayName(id))
                Text(id).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

/// «+» menu for apps: pick a .app, or one of the recent apps (a full-screen game is only reachable after leaving it)
struct AppAddMenu: View {
    let taken: [String]
    let pick: (String) -> Void
    var body: some View {
        Button(L("chooseApp")) { if let id = pickAppBundleID() { pick(id) } }
        let recent = engine.recent.filter { !taken.contains($0) }
        if !recent.isEmpty {
            Divider()
            Section(L("recentApps")) {
                ForEach(recent, id: \.self) { id in Button(appDisplayName(id)) { pick(id) } }
            }
        }
    }
}

struct ExcludedPane: View {
    @EnvironmentObject var m: SettingsModel
    var body: some View {
        ListPane(info: L("excludeDesc"),
                 rows: m.excluded.map(AppRow.init),
                 matches: { appDisplayName($0.id).localizedCaseInsensitiveContains($1) || $0.id.localizedCaseInsensitiveContains($1) },
                 add: .menu(AnyView(AppAddMenu(taken: m.excluded) { id in if !m.excluded.contains(id) { m.excluded.append(id) } })),
                 remove: { ids in m.excluded.removeAll { ids.contains($0) } }) {
            TableColumn(L("colApp")) { (r: AppRow) in AppCell(id: r.id) }
        }
    }
}

struct BindingsPane: View {
    @EnvironmentObject var m: SettingsModel
    private var langs: [String] { engine.layouts.map(\.lang) }

    var body: some View {
        ListPane(info: L("bindDesc"),
                 rows: m.bindings.keys.sorted().map(AppRow.init),
                 matches: { appDisplayName($0.id).localizedCaseInsensitiveContains($1) || $0.id.localizedCaseInsensitiveContains($1) },
                 add: .menu(AnyView(AppAddMenu(taken: Array(m.bindings.keys)) { id in
                     if m.bindings[id] == nil, let l = currentLang() ?? langs.first { m.bindings[id] = l }
                 })),
                 remove: { ids in for id in ids { m.bindings[id] = nil } }) {
            TableColumn(L("colApp")) { (r: AppRow) in AppCell(id: r.id) }
            TableColumn(L("colLang")) { (r: AppRow) in
                let cur = m.bindings[r.id] ?? ""
                Picker("", selection: Binding(get: { cur }, set: { m.bindings[r.id] = $0 })) {
                    ForEach(langs.contains(cur) ? langs : [cur] + langs, id: \.self) { Text(langName($0)).tag($0) }
                }.labelsHidden()
            }
        }
    }
}

// MARK: - Window

final class SettingsWindow: NSObject, NSWindowDelegate {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        SettingsModel.shared.reload()
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 560),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            w.title = "AURA Switcher"
            w.contentViewController = NSHostingController(rootView: SettingsView().environmentObject(SettingsModel.shared))
            w.contentMinSize = NSSize(width: 760, height: 500)
            w.isReleasedWhenClosed = false
            w.titlebarSeparatorStyle = .none
            w.delegate = self
            w.center()
            w.setFrameAutosaveName("AURASettings")
            window = w
        }
        NSApp.setActivationPolicy(.regular)   // Dock icon + ⌘Tab while the window is open
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        for d in [0.05, 0.3, 1.0] { DispatchQueue.main.asyncAfter(deadline: .now() + d) { self.stripToolbar() } }
    }

    /// NavigationSplitView puts «hide sidebar» and its separator into the toolbar (the sidebar is always shown here): remove them
    private func stripToolbar() {
        guard let tb = window?.toolbar else { return }
        for (i, it) in tb.items.enumerated().reversed() where it.itemIdentifier.rawValue.localizedCaseInsensitiveContains("sidebar")
            || it.itemIdentifier.rawValue.localizedCaseInsensitiveContains("separator") { tb.removeItem(at: i) }
    }

    func windowWillClose(_ n: Notification) { NSApp.setActivationPolicy(.accessory) }
    func windowDidBecomeKey(_ n: Notification) { SettingsModel.shared.reload(); stripToolbar() }
}
