//
//  UtilClockApp.swift
//  UtilClock
//
//  Created by José Manuel Rives on 19/2/26.
//

import SwiftUI

#if os(iOS) || os(tvOS)
import UIKit
#endif
#if os(macOS)
import AppKit
import ServiceManagement
#endif

@main
struct UtilClockApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("utilclock.presentation.menuBarOnly") private var menuBarOnlyMode = false
    @AppStorage("utilclock.window.preferredFullscreen") private var preferredFullscreen = true
    @State private var statusBarController = StatusBarController()
    @State private var windowCoordinator = WindowCoordinator()
    @State private var pendingAccessoryActivation = false
    #endif

    init() {
        FontRegistrar.registerBundledFonts()
        #if os(macOS)
        disableLegacyLaunchAtLogin()
        #endif
    }

    var body: some Scene {
        WindowGroup(id: WindowCoordinator.mainWindowID) {
            ContentView()
                #if os(macOS)
                .background(BorderlessWindowConfigurator(alwaysOnTop: alwaysOnTop))
                .background(MainWindowRegistrationView(windowCoordinator: windowCoordinator))
                .onAppear {
                    appDelegate.reopenHandler = { [self] in
                        recoverMainWindowVisibility(triggeredByWake: false)
                    }
                    appDelegate.didBecomeActiveHandler = { [self] in
                        recoverMainWindowVisibility(triggeredByWake: false)
                    }
                    applyPresentationMode()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
                    applyPresentationMode()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
                    applyPresentationMode()
                }
                .onChange(of: menuBarOnlyMode) { _, isMenuBarOnly in
                    applyPresentationMode()
                    if isMenuBarOnly == false {
                        showMainWindow()
                    }
                }
                .onChange(of: alwaysOnTop) { _, _ in
                    applyPresentationMode()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                    recoverMainWindowVisibility(triggeredByWake: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.screensDidWakeNotification)) { _ in
                    recoverMainWindowVisibility(triggeredByWake: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.screensDidSleepNotification)) { _ in
                    recoverMainWindowVisibility(triggeredByWake: true, remainingAttempts: 6)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                    recoverMainWindowVisibility(triggeredByWake: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didUnhideNotification)) { _ in
                    recoverMainWindowVisibility(triggeredByWake: false)
                }
                #endif
                #if os(iOS) || os(tvOS)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                #endif
        }
        #if os(macOS)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button(L10n.toggleFullScreen) {
                    let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
                    targetWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [])

                Divider()

                Button(alwaysOnTop ? L10n.disableAlwaysOnTop : L10n.enableAlwaysOnTop) {
                    alwaysOnTop.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
            }
        }
        #endif
    }
}

#if os(macOS)
private extension UtilClockApp {
    var startupDisplaySelectionKey: String { "utilclock.startup.selectedDisplayID" }

    func applyPresentationMode() {
        let targetWindow = mainAppWindow()
        let isFullscreen = targetWindow?.styleMask.contains(.fullScreen) ?? false

        let targetPolicy: NSApplication.ActivationPolicy
        if menuBarOnlyMode {
            if isFullscreen {
                // Defer accessory activation until windowed mode to avoid breaking fullscreen.
                targetPolicy = .regular
                pendingAccessoryActivation = true
            } else {
                targetPolicy = .accessory
                pendingAccessoryActivation = false
            }
        } else {
            targetPolicy = .regular
            pendingAccessoryActivation = false
        }

        if NSApp.activationPolicy() != targetPolicy {
            NSApp.setActivationPolicy(targetPolicy)
        }

        let targetPresentationOptions: NSApplication.PresentationOptions = isFullscreen
            ? [.autoHideMenuBar, .autoHideDock]
            : []
        if NSApp.presentationOptions != targetPresentationOptions {
            NSApp.presentationOptions = targetPresentationOptions
        }

        if pendingAccessoryActivation, isFullscreen == false, menuBarOnlyMode {
            pendingAccessoryActivation = false
            if NSApp.activationPolicy() != .accessory {
                NSApp.setActivationPolicy(.accessory)
            }
        }

        statusBarController.update(
            isVisible: menuBarOnlyMode,
            toggleFullscreen: { toggleFullscreen() },
            moveToScreen: { screenID in moveMainWindowToScreen(screenID) }
        )
    }

    func showMainWindow() {
        guard let targetWindow = ensureMainWindowAvailable() else { return }
        bringWindowToFront(targetWindow)
    }

    func mainAppWindow() -> NSWindow? {
        NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) ?? NSApp.windows.first
    }

    func ensureMainWindowAvailable() -> NSWindow? {
        if let window = mainAppWindow() {
            return window
        }

        windowCoordinator.openMainWindowIfNeeded()
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.arrangeInFront(nil)

        return mainAppWindow()
    }

    func bringWindowToFront(_ window: NSWindow) {
        restoreWindowVisualState(window)
        window.collectionBehavior = mainWindowCollectionBehavior()
        NSApp.unhide(nil)
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        window.order(.above, relativeTo: 0)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.displayIfNeeded()
        NSApp.activate(ignoringOtherApps: true)
    }

    func recoverMainWindowVisibility(triggeredByWake: Bool, remainingAttempts: Int = 4) {
        applyPresentationMode()

        guard menuBarOnlyMode == false else { return }
        guard remainingAttempts > 0 else { return }

        if let targetWindow = ensureMainWindowAvailable() {
            recoverExistingWindowVisibility(targetWindow, triggeredByWake: triggeredByWake, remainingAttempts: remainingAttempts)
            return
        }

        if triggeredByWake {
            scheduleRecoveryRetry(triggeredByWake: true, remainingAttempts: remainingAttempts - 1, delay: 0.9)
        }
    }

    func recoverExistingWindowVisibility(_ targetWindow: NSWindow, triggeredByWake: Bool, remainingAttempts: Int) {
        guard remainingAttempts > 0 else { return }

        NSApp.unhide(nil)

        if targetWindow.isMiniaturized {
            targetWindow.deminiaturize(nil)
        }

        restoreWindowVisualState(targetWindow)
        normalizeWindowPositionIfNeeded(targetWindow)
        bringWindowToFront(targetWindow)

        if triggeredByWake {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let windowIsVisible = targetWindow.isVisible &&
                    targetWindow.alphaValue > 0.01 &&
                    targetWindow.contentView?.isHidden != true &&
                    (targetWindow.occlusionState.contains(.visible) || targetWindow.styleMask.contains(.fullScreen))
                if windowIsVisible == false {
                    hardResetWindowVisibility(targetWindow)
                    scheduleRecoveryRetry(triggeredByWake: true, remainingAttempts: remainingAttempts - 1, delay: 0.7)
                }
            }
        }
    }

    func scheduleRecoveryRetry(triggeredByWake: Bool, remainingAttempts: Int, delay: TimeInterval) {
        guard remainingAttempts > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            recoverMainWindowVisibility(triggeredByWake: triggeredByWake, remainingAttempts: remainingAttempts)
        }
    }

    func toggleFullscreen() {
        let targetWindow = mainAppWindow()
        targetWindow?.toggleFullScreen(nil)
    }

    func moveMainWindowToScreen(_ targetScreenID: UInt32) {
        guard let window = mainAppWindow() else { return }
        guard let targetScreen = NSScreen.screens.first(where: { screenID(for: $0) == targetScreenID }) else { return }

        let wasFullscreen = window.styleMask.contains(.fullScreen)
        if wasFullscreen {
            window.toggleFullScreen(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                window.setFrame(targetScreen.frame, display: true, animate: false)
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                window.toggleFullScreen(nil)
            }
        } else {
            window.setFrame(targetScreen.frame, display: true, animate: false)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func screenID(for screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    func normalizeWindowPositionIfNeeded(_ window: NSWindow) {
        let availableScreens = NSScreen.screens
        guard let fallbackScreen = NSScreen.main ?? availableScreens.first else { return }

        let windowFrame = window.frame
        let isOnAnyScreen = availableScreens
            .map(\.visibleFrame)
            .contains { $0.intersects(windowFrame) }

        guard window.screen == nil || isOnAnyScreen == false else { return }

        window.setFrame(fallbackScreen.visibleFrame, display: true, animate: false)
    }

    func hardResetWindowVisibility(_ window: NSWindow) {
        guard let fallbackScreen = preferredRecoveryScreen(for: window) else { return }
        let restoreFullscreen = preferredFullscreen
        let isFullscreen = window.styleMask.contains(.fullScreen)

        let relocateWindow = {
            restoreWindowVisualState(window)
            window.setFrame(restoreFullscreen ? fallbackScreen.frame : fallbackScreen.visibleFrame, display: true, animate: false)
            bringWindowToFront(window)
            if restoreFullscreen && window.styleMask.contains(.fullScreen) == false {
                window.toggleFullScreen(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    restoreWindowVisualState(window)
                    bringWindowToFront(window)
                }
            }
        }

        if isFullscreen {
            if NSApp.activationPolicy() != .regular {
                NSApp.setActivationPolicy(.regular)
            }
            bringWindowToFront(window)
            window.toggleFullScreen(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                relocateWindow()
            }
        } else {
            relocateWindow()
        }
    }

    func preferredRecoveryScreen(for window: NSWindow) -> NSScreen? {
        if let savedScreenID = UserDefaults.standard.object(forKey: startupDisplaySelectionKey) as? Int,
           let selectedScreen = NSScreen.screens.first(where: { screenID(for: $0) == UInt32(savedScreenID) }) {
            return selectedScreen
        }

        if let currentScreen = window.screen,
           NSScreen.screens.contains(where: { screenID(for: $0) == screenID(for: currentScreen) }) {
            return currentScreen
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    func restoreWindowVisualState(_ window: NSWindow) {
        window.alphaValue = 1
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = true
        window.contentView?.isHidden = false
        window.contentView?.needsDisplay = true
    }

    func mainWindowCollectionBehavior() -> NSWindow.CollectionBehavior {
        [.fullScreenPrimary, .fullScreenAllowsTiling, .moveToActiveSpace]
    }

    func disableLegacyLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Ignore errors; the app must continue even if cleanup fails.
        }
    }
}

private final class MacAppDelegate: NSObject, NSApplicationDelegate {
    var reopenHandler: (() -> Void)?
    var didBecomeActiveHandler: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("Keep UtilClock alive while restoring its main window.")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        reopenHandler?()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        didBecomeActiveHandler?()
    }
}

private final class WindowCoordinator {
    static let mainWindowID = "main-window"

    var openMainWindow: (() -> Void)?

    func openMainWindowIfNeeded() {
        openMainWindow?()
    }
}

private final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var toggleFullscreenAction: (() -> Void)?
    private var moveToScreenAction: ((UInt32) -> Void)?

    func update(
        isVisible: Bool,
        toggleFullscreen: @escaping () -> Void,
        moveToScreen: @escaping (UInt32) -> Void
    ) {
        toggleFullscreenAction = toggleFullscreen
        moveToScreenAction = moveToScreen

        if isVisible {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                statusItem?.button?.image = makeStatusBarImage()
                statusItem?.button?.imagePosition = .imageOnly
            }
            statusItem?.menu = buildMenu()
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let monitorItem = NSMenuItem(title: L10n.menuChangeMonitor, action: nil, keyEquivalent: "")
        monitorItem.submenu = buildScreensSubmenu()
        menu.addItem(monitorItem)

        let fullscreenItem = NSMenuItem(title: fullscreenMenuTitle(), action: #selector(toggleFullScreen), keyEquivalent: "")
        fullscreenItem.target = self
        menu.addItem(fullscreenItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: L10n.menuQuit, action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        quitItem.image = NSImage(
            systemSymbolName: "rectangle.portrait.and.arrow.right",
            accessibilityDescription: L10n.menuQuit
        )
        menu.addItem(quitItem)

        return menu
    }

    private func buildScreensSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let currentScreenID = currentWindowScreenID()

        for screen in NSScreen.screens {
            guard let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value else { continue }
            let frame = screen.frame
            let title = "\(screen.localizedName) (\(Int(frame.width))x\(Int(frame.height)))"
            let item = NSMenuItem(title: title, action: #selector(selectScreen(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = NSNumber(value: id)
            item.state = (currentScreenID == id) ? .on : .off
            submenu.addItem(item)
        }

        return submenu
    }

    private func currentWindowScreenID() -> UInt32? {
        let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
        guard let screen = targetWindow?.screen else { return nil }
        return (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    private func makeStatusBarImage() -> NSImage? {
        let preferred = NSImage(
            systemSymbolName: "timer.circle.fill",
            accessibilityDescription: "UtilClock"
        )
        let fallback = NSImage(
            systemSymbolName: "clock.fill",
            accessibilityDescription: "UtilClock"
        )
        let image = preferred ?? fallback
        image?.isTemplate = true
        return image
    }

    private func fullscreenMenuTitle() -> String {
        let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
        let isFullscreen = targetWindow?.styleMask.contains(.fullScreen) ?? false
        return isFullscreen
            ? L10n.menuDisableFullscreen
            : L10n.menuEnableFullscreen
    }

    @objc
    private func toggleFullScreen() {
        toggleFullscreenAction?()
    }

    @objc
    private func selectScreen(_ sender: NSMenuItem) {
        guard let idValue = sender.representedObject as? NSNumber else { return }
        moveToScreenAction?(idValue.uint32Value)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

private struct BorderlessWindowConfigurator: NSViewRepresentable {
    let alwaysOnTop: Bool

    final class Coordinator {
        var configuredWindowNumber: Int?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window, coordinator: context.coordinator)
        }
    }

    private func configure(window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }

        if coordinator.configuredWindowNumber != window.windowNumber {
            window.styleMask = [.titled, .fullSizeContentView, .resizable]
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            window.isMovableByWindowBackground = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling, .moveToActiveSpace]
            coordinator.configuredWindowNumber = window.windowNumber
        }

        window.level = alwaysOnTop ? .floating : .normal
        window.alphaValue = 1
        window.contentView?.isHidden = false

    }
}

private struct MainWindowRegistrationView: View {
    @Environment(\.openWindow) private var openWindow
    let windowCoordinator: WindowCoordinator

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                registerOpenWindowAction()
            }
    }

    private func registerOpenWindowAction() {
        windowCoordinator.openMainWindow = {
            openWindow(id: WindowCoordinator.mainWindowID)
        }
    }
}
#endif
