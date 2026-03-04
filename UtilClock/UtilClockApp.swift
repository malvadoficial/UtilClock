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
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("utilclock.presentation.menuBarOnly") private var menuBarOnlyMode = false
    @State private var statusBarController = StatusBarController()
    @State private var pendingAccessoryActivation = false
    #endif

    init() {
        FontRegistrar.registerBundledFonts()
        #if os(macOS)
        disableLegacyLaunchAtLogin()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .background(BorderlessWindowConfigurator(alwaysOnTop: alwaysOnTop))
                .onAppear {
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
    func applyPresentationMode() {
        let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
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
        let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
        targetWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func toggleFullscreen() {
        let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
        targetWindow?.toggleFullScreen(nil)
    }

    func moveMainWindowToScreen(_ targetScreenID: UInt32) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first else { return }
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
            window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling, .canJoinAllSpaces]
            coordinator.configuredWindowNumber = window.windowNumber
        }

        window.level = alwaysOnTop ? .floating : .normal

    }
}
#endif
