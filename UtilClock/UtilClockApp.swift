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
#endif

@main
struct UtilClockApp: App {
    #if os(macOS)
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    #endif

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .background(BorderlessWindowConfigurator(alwaysOnTop: alwaysOnTop))
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
