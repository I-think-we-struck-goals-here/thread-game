import Foundation
import UIKit

@MainActor
final class ThreadAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    @Published var latestRemotePushToken: String?
    @Published var remotePushRegistrationError: String?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        latestRemotePushToken = deviceToken.map { String(format: "%02x", $0) }.joined()
        remotePushRegistrationError = nil
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        remotePushRegistrationError = error.localizedDescription
    }
}
