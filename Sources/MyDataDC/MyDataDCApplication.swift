import SwiftUI
import MyDataDCAppShell
#if os(macOS)
import AppKit
#endif

#if os(macOS)
@MainActor
private final class MyDataDCAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
#endif

@main
struct MyDataDCApplication: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(MyDataDCAppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
#if os(macOS)
        WindowGroup {
            MyDataDCRootView()
        }
        .defaultSize(width: 1280, height: 820)
#else
        WindowGroup {
            MyDataDCRootView()
        }
#endif
    }
}
