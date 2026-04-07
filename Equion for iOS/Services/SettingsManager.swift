import SwiftUI
import UserNotifications

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("appearanceMode") var appearanceMode: String = "system" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("appLanguage") var appLanguage: String = "English" {
        didSet { objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    static let supportedLanguages = [
        "English", "中文", "日本語", "한국어",
        "Español", "Français", "Deutsch", "Português",
        "Italiano", "Русский", "العربية", "हिन्दी"
    ]

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
        }
    }
}
