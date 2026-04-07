import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        OrionRefreshStyle.apply()

        // Notification setup
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.loadPreferences()
        NotificationService.shared.registerBackgroundTask()

        // Schedule background task if notifications are enabled
        if SettingsManager.shared.notificationsEnabled {
            NotificationService.shared.scheduleBackgroundTask()
            NotificationService.shared.scheduleDailySummary()
        }

        return true
    }

    // Handle Google Sign-In redirect URL
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Remote Notifications (for future FCM support)

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[AppDelegate] APNs token: \(token)")
        // Future: Forward to Firebase Messaging
        // Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let symbol = userInfo["symbol"] as? String {
            // Post notification to navigate to stock detail
            NotificationCenter.default.post(
                name: .didTapStockNotification,
                object: nil,
                userInfo: ["symbol": symbol]
            )
        }
        NotificationService.shared.clearBadge()
        completionHandler()
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let didTapStockNotification = Notification.Name("didTapStockNotification")
}

@main
struct Equion_for_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firebaseController = FirebaseController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseController)
                .onAppear {
                    NotificationService.shared.clearBadge()
                }
        }
    }
}
