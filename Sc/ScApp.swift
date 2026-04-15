import AppKit
import SwiftUI

@main
struct ScApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel.shared

    var body: some Scene {
        WindowGroup("Sc") {
            ControlCenterView()
                .environmentObject(appModel)
                .frame(minWidth: 760, minHeight: 760)
        }
        .defaultSize(width: 860, height: 860)
        .commands {
            CommandGroup(after: .appTermination) {
                Button(L10n.string("menu.stop_current_session")) {
                    appModel.leaveCurrentSession()
                }
                .disabled(!appModel.hasActiveSession)
                .keyboardShortcut(.escape, modifiers: [.command, .shift])
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppModel.shared.installSystemServices()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        AppModel.shared.refreshHotKeyMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppModel.shared.shutdown()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
