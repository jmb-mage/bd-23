import Foundation
import AppKit
import SpriteKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var window: NSWindow!
    public var skView: SKView!
    public var scene: MoodMapScene!

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        setupWindow()
    }

    private func setupWindow() {
        let initialWidth: CGFloat = 1100
        let initialHeight: CGFloat = 850

        let windowRect = NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MoodMap — Geometric Shape & Color Wave Engine"
        window.minSize = NSSize(width: 800, height: 600)
        window.center()
        window.isReleasedWhenClosed = false

        // Configure SpriteKit SKView
        skView = SKView(frame: windowRect)
        skView.autoresizingMask = [.width, .height]
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        // Initialize Scene
        scene = MoodMapScene(size: CGSize(width: initialWidth, height: initialHeight))
        skView.presentScene(scene)

        window.contentView = skView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupMenu() {
        let mainMenu = NSMenu()

        // Application Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let appName = ProcessInfo.processInfo.processName
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // View Menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu

        let toggleHUDItem = NSMenuItem(title: "Toggle HUD", action: #selector(toggleHUDAction), keyEquivalent: "h")
        viewMenu.addItem(toggleHUDItem)

        let togglePauseItem = NSMenuItem(title: "Pause / Resume Animation", action: #selector(togglePauseAction), keyEquivalent: " ")
        viewMenu.addItem(togglePauseItem)

        let randomizeItem = NSMenuItem(title: "Randomize Map & Mood", action: #selector(randomizeAction), keyEquivalent: "r")
        viewMenu.addItem(randomizeItem)

        viewMenu.addItem(NSMenuItem.separator())
        let increaseNodeItem = NSMenuItem(title: "Increase Node Size", action: #selector(increaseNodeSizeAction), keyEquivalent: "+")
        let decreaseNodeItem = NSMenuItem(title: "Decrease Node Size", action: #selector(decreaseNodeSizeAction), keyEquivalent: "-")
        viewMenu.addItem(increaseNodeItem)
        viewMenu.addItem(decreaseNodeItem)

        viewMenu.addItem(NSMenuItem.separator())
        let fullScreenItem = NSMenuItem(title: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.control, .command]
        viewMenu.addItem(fullScreenItem)

        // Navigation Menu
        let navMenuItem = NSMenuItem()
        mainMenu.addItem(navMenuItem)
        let navMenu = NSMenu(title: "Navigation")
        navMenuItem.submenu = navMenu

        let nextMapItem = NSMenuItem(title: "Next Map", action: #selector(nextMapAction), keyEquivalent: String(UnicodeScalar(NSRightArrowFunctionKey)!))
        let prevMapItem = NSMenuItem(title: "Previous Map", action: #selector(prevMapAction), keyEquivalent: String(UnicodeScalar(NSLeftArrowFunctionKey)!))
        let nextMoodItem = NSMenuItem(title: "Next Mood", action: #selector(nextMoodAction), keyEquivalent: String(UnicodeScalar(NSUpArrowFunctionKey)!))
        let prevMoodItem = NSMenuItem(title: "Previous Mood", action: #selector(prevMoodAction), keyEquivalent: String(UnicodeScalar(NSDownArrowFunctionKey)!))

        navMenu.addItem(nextMapItem)
        navMenu.addItem(prevMapItem)
        navMenu.addItem(NSMenuItem.separator())
        navMenu.addItem(nextMoodItem)
        navMenu.addItem(prevMoodItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func nextMapAction() {
        scene?.nextMap()
    }

    @objc private func prevMapAction() {
        scene?.previousMap()
    }

    @objc private func nextMoodAction() {
        scene?.nextMood()
    }

    @objc private func prevMoodAction() {
        scene?.previousMood()
    }

    @objc private func toggleHUDAction() {
        scene?.toggleHUD()
    }

    @objc private func togglePauseAction() {
        scene?.togglePause()
    }

    @objc private func randomizeAction() {
        scene?.randomize()
    }

    @objc private func increaseNodeSizeAction() {
        scene?.increaseNodeSize()
    }

    @objc private func decreaseNodeSizeAction() {
        scene?.decreaseNodeSize()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
