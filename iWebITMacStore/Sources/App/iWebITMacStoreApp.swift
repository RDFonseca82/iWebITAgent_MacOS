import SwiftUI

@main
struct iWebITMacStoreApp: App {
    @NSApplicationDelegateAdaptor(MacStoreAppDelegate.self) private var appDelegate
    @StateObject private var runtime = MacStoreRuntime()

    var body: some Scene {
        WindowGroup {
            MacStoreGateView()
                .environmentObject(runtime)
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}
