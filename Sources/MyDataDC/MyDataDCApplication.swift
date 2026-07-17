import SwiftUI
import MyDataDCAppShell

@main
struct MyDataDCApplication: App {
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
