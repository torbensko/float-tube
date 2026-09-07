import Cocoa
import WebKit

// A Safari user-agent. This is the single most important line for the Google
// login flow: Google fingerprints embedded webviews and will otherwise refuse
// to sign you in with "This browser or app may not be secure."
let safariUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"

let homeURL = URL(string: "https://www.youtube.com")!

final class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate {

    var panel: NSPanel!
    var web: WKWebView!
    var popup: NSWindow?

    // Whole-window sizes for the snap button, measured off the screenshot.
    // First click gives that size; repeated clicks step down the same shape.
    let snapSizes = [NSSize(width: 1003, height: 560),
                     NSSize(width: 752,  height: 420),
                     NSSize(width: 501,  height: 280)]
    var snapIndex = -1

    var opacity: CGFloat = 1.0
    var pinned = true
    var clickThrough = false

    var pinItem: NSMenuItem!
    var clickThroughItem: NSMenuItem!

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // persistent: the login survives quit
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 360), configuration: config)
        web.customUserAgent = safariUA
        web.allowsBackForwardNavigationGestures = true
        web.uiDelegate = self
        web.navigationDelegate = self
        web.load(URLRequest(url: homeURL))

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false)

        panel.title = "FloatTube"
        panel.level = .floating                       // <- always on top
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false               // panels default to true; that would defeat the point
        panel.isMovableByWindowBackground = true
        panel.contentView = web
        panel.setFrameAutosaveName("FloatTubeMain")   // remembers size + position across launches
        if panel.frame.origin == .zero { panel.center() }
        addSnapButton()
        panel.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // Clicking the Dock icon is the escape hatch out of click-through mode:
    // it activates the app so the menu bar is reachable again.
    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.makeKeyAndOrderFront(nil)
        return true
    }

    // MARK: - snap to corner

    func addSnapButton() {
        let button = NSButton(title: "", target: self, action: #selector(snapTopRight))
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.toolTip = "Snap to top-right corner (Cmd-J)"
        if let img = NSImage(systemSymbolName: "arrow.up.right.square",
                             accessibilityDescription: "Snap to top-right corner") {
            button.image = img
            button.imagePosition = .imageOnly
        } else {
            button.title = "Snap"
        }
        button.frame = NSRect(x: 4, y: 0, width: 28, height: 22)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 36, height: 22))
        container.addSubview(button)

        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = container
        accessory.layoutAttribute = .right
        panel.addTitlebarAccessoryViewController(accessory)
    }

    @objc func snapTopRight() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame        // already excludes menu bar and Dock
        let margin: CGFloat = 16

        snapIndex = (snapIndex + 1) % snapSizes.count
        var frame = NSRect(origin: .zero, size: snapSizes[snapIndex])

        // Never let a snap push the window off a smaller display.
        frame.size.width  = min(frame.width,  visible.width  - margin * 2)
        frame.size.height = min(frame.height, visible.height - margin * 2)

        frame.origin.x = visible.maxX - frame.width  - margin
        frame.origin.y = visible.maxY - frame.height - margin

        panel.setFrame(frame, display: true, animate: true)
    }

    // MARK: - window behaviour

    @objc func opacityUp()   { setOpacity(opacity + 0.1) }
    @objc func opacityDown() { setOpacity(opacity - 0.1) }

    func setOpacity(_ v: CGFloat) {
        opacity = min(1.0, max(0.3, v))               // never fade to invisible
        panel.alphaValue = opacity
    }

    @objc func togglePin() {
        pinned.toggle()
        panel.level = pinned ? .floating : .normal
        pinItem.state = pinned ? .on : .off
    }

    @objc func toggleClickThrough() {
        clickThrough.toggle()
        panel.ignoresMouseEvents = clickThrough
        clickThroughItem.state = clickThrough ? .on : .off
        // Fade a little so it's obvious the window has gone inert.
        if clickThrough && opacity == 1.0 { setOpacity(0.85) }
    }

    // MARK: - popups (the Google sign-in flow uses one)

    func webView(_ wv: WKWebView,
                 createWebViewWith config: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        let popWeb = WKWebView(frame: NSRect(x: 0, y: 0, width: 500, height: 640), configuration: config)
        popWeb.customUserAgent = safariUA
        popWeb.uiDelegate = self
        popWeb.navigationDelegate = self

        let w = NSPanel(contentRect: popWeb.frame,
                        styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        w.title = "Sign in"
        w.level = .floating
        w.hidesOnDeactivate = false
        w.contentView = popWeb
        w.center()
        w.makeKeyAndOrderFront(nil)
        popup = w
        return popWeb
    }

    func webViewDidClose(_ wv: WKWebView) {
        popup?.close()
        popup = nil
    }

    // MARK: - menu

    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Home", action: #selector(goHome), keyEquivalent: "0")
        appMenu.addItem(withTitle: "Reload", action: #selector(reload), keyEquivalent: "r")
        appMenu.addItem(withTitle: "Back", action: #selector(goBack), keyEquivalent: "[")
        appMenu.addItem(withTitle: "Snap to top-right", action: #selector(snapTopRight), keyEquivalent: "j")
        appMenu.addItem(.separator())

        pinItem = appMenu.addItem(withTitle: "Float on top", action: #selector(togglePin), keyEquivalent: "t")
        pinItem.state = .on

        clickThroughItem = appMenu.addItem(withTitle: "Click through",
                                           action: #selector(toggleClickThrough), keyEquivalent: "i")
        clickThroughItem.state = .off

        appMenu.addItem(withTitle: "Less transparent", action: #selector(opacityUp), keyEquivalent: "=")
        appMenu.addItem(withTitle: "More transparent", action: #selector(opacityDown), keyEquivalent: "-")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Sign out of everything (clear cookies)",
                        action: #selector(clearData), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit FloatTube", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        // Standard Edit menu — without this, Cmd-V into YouTube's search box does nothing.
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)

        NSApp.mainMenu = main
    }

    @objc func goHome()  { web.load(URLRequest(url: homeURL)) }
    @objc func reload()  { web.reload() }
    @objc func goBack()  { web.goBack() }
    @objc func clearData() {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {
            self.web.load(URLRequest(url: homeURL))
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
