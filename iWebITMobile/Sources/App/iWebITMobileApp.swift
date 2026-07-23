import SwiftUI

@main
struct iWebITMobileApp: App {
    @UIApplicationDelegateAdaptor(MobileAppDelegate.self) private var appDelegate
    @StateObject private var runtime = MobileRuntime()

    var body: some Scene {
        WindowGroup {
            MobileGateView()
                .environmentObject(runtime)
        }
    }
}
