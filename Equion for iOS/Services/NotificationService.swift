import Foundation
import UserNotifications
import BackgroundTasks
import UIKit

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - Notification Service
// Monitors major US indices + user watchlist in background,
// sends local push notifications when thresholds are triggered.

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private init() {
        self.priceAlertEnabled = UserDefaults.standard.bool(forKey: "notif_priceAlert")
        self.marketAlertEnabled = UserDefaults.standard.bool(forKey: "notif_marketAlert")
        self.dailySummaryEnabled = UserDefaults.standard.bool(forKey: "notif_dailySummary")
        self.bigMoveThreshold = UserDefaults.standard.double(forKey: "notif_bigMoveThreshold").nonZero ?? 5.0
        self.indexMoveThreshold = UserDefaults.standard.double(forKey: "notif_indexMoveThreshold").nonZero ?? 2.0
    }

    // Background task identifier
    static let bgTaskId = "com.equion.stockPriceCheck"

    // Major indices always monitored
    private let majorIndices = [
        ("SPY", "S&P 500"),
        ("QQQ", "NASDAQ"),
        ("DIA", "Dow Jones")
    ]

    // MARK: - Notification Preferences (persisted via UserDefaults)

    @Published var priceAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(priceAlertEnabled, forKey: "notif_priceAlert") }
    }
    @Published var marketAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(marketAlertEnabled, forKey: "notif_marketAlert") }
    }
    @Published var dailySummaryEnabled: Bool {
        didSet { UserDefaults.standard.set(dailySummaryEnabled, forKey: "notif_dailySummary") }
    }
    @Published var bigMoveThreshold: Double {
        didSet { UserDefaults.standard.set(bigMoveThreshold, forKey: "notif_bigMoveThreshold") }
    }
    @Published var indexMoveThreshold: Double {
        didSet { UserDefaults.standard.set(indexMoveThreshold, forKey: "notif_indexMoveThreshold") }
    }

    // Track last notified prices to avoid spamming
    private var lastNotifiedPrices: [String: Double] = [:]
    private var lastNotifiedTime: [String: Date] = [:]
    // Minimum interval between notifications for same symbol (30 min)
    private let minNotifInterval: TimeInterval = 1800

    // Foreground periodic check timer
    private var foregroundTimer: Timer?
    // Interval between foreground checks (10 minutes)
    private let foregroundCheckInterval: TimeInterval = 600

    // MARK: - Foreground Timer

    /// Start periodic price checks while app is in foreground
    func startForegroundMonitoring() {
        stopForegroundMonitoring()
        guard SettingsManager.shared.notificationsEnabled else { return }

        // Immediately perform a check
        Task { await performPriceCheck() }

        // Schedule repeating timer on main run loop
        DispatchQueue.main.async {
            self.foregroundTimer = Timer.scheduledTimer(withTimeInterval: self.foregroundCheckInterval, repeats: true) { [weak self] _ in
                guard let self else { return }
                Task { await self.performPriceCheck() }
            }
        }
    }

    /// Stop foreground monitoring when app goes to background
    func stopForegroundMonitoring() {
        foregroundTimer?.invalidate()
        foregroundTimer = nil
    }

    /// Check if US market is currently in trading hours (roughly 9:30 AM – 4:00 PM ET, weekdays)
    private var isMarketHours: Bool {
        let ny = TimeZone(identifier: "America/New_York")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ny
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        // 1 = Sunday, 7 = Saturday
        guard weekday >= 2 && weekday <= 6 else { return false }
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let minuteOfDay = hour * 60 + minute
        // 9:30 AM = 570, 4:00 PM = 960
        return minuteOfDay >= 570 && minuteOfDay <= 960
    }

    // MARK: - Init preferences from UserDefaults

    func loadPreferences() {
        priceAlertEnabled = UserDefaults.standard.object(forKey: "notif_priceAlert") as? Bool ?? true
        marketAlertEnabled = UserDefaults.standard.object(forKey: "notif_marketAlert") as? Bool ?? true
        dailySummaryEnabled = UserDefaults.standard.object(forKey: "notif_dailySummary") as? Bool ?? true
        bigMoveThreshold = UserDefaults.standard.object(forKey: "notif_bigMoveThreshold") as? Double ?? 5.0
        indexMoveThreshold = UserDefaults.standard.object(forKey: "notif_indexMoveThreshold") as? Double ?? 2.0
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                SettingsManager.shared.notificationsEnabled = granted
            }
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Background Task Registration

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.bgTaskId,
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskId)
        // Request execution no earlier than 15 min from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[NotificationService] Background task scheduled")
        } catch {
            print("[NotificationService] Failed to schedule: \(error)")
        }
    }

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        // Schedule next check
        scheduleBackgroundTask()

        let checkTask = Task {
            await performPriceCheck()
        }

        task.expirationHandler = {
            checkTask.cancel()
        }

        Task {
            await checkTask.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Core Price Check Logic

    func performPriceCheck() async {
        guard SettingsManager.shared.notificationsEnabled else { return }
        // Skip checks outside market hours to save API calls
        guard isMarketHours else { return }

        // 1. Check major indices
        if marketAlertEnabled {
            await checkIndices()
        }

        // 2. Check user watchlist
        if priceAlertEnabled {
            await checkWatchlist()
        }
    }

    private func checkIndices() async {
        for (symbol, name) in majorIndices {
            do {
                let quote = try await APIService.shared.fetchFullQuote(symbol: symbol)
                let changePct = quote.changePercent

                // Alert if index moves more than threshold
                if abs(changePct) >= indexMoveThreshold {
                    if shouldNotify(symbol: symbol) {
                        let direction = changePct > 0 ? "up" : "down"
                        let emoji = changePct > 0 ? "📈" : "📉"
                        await sendNotification(
                            title: "\(emoji) \(name) \(L("Big Move"))",
                            body: String(format: "%@ %@ %.2f%% ($%.2f)",
                                         name,
                                         changePct > 0 ? L("is up") : L("is down"),
                                         abs(changePct),
                                         quote.price),
                            symbol: symbol,
                            category: "market_alert"
                        )
                        markNotified(symbol: symbol)
                    }
                }
            } catch {
                print("[NotificationService] Index check failed for \(symbol): \(error)")
            }
        }
    }

    private func checkWatchlist() async {
        let symbols = await FirebaseController.shared.getWatchlistSymbols()
        guard !symbols.isEmpty else { return }

        // Check each symbol concurrently (limit to 5 at a time)
        await withTaskGroup(of: Void.self) { group in
            for symbol in symbols.prefix(20) { // Cap at 20 to stay within rate limits
                group.addTask {
                    await self.checkSingleStock(symbol: symbol)
                }
            }
        }
    }

    private func checkSingleStock(symbol: String) async {
        do {
            let (price, previousClose) = try await APIService.shared.fetchStockQuote(symbol: symbol)
            guard previousClose > 0 else { return }
            let changePct = (price - previousClose) / previousClose * 100

            if abs(changePct) >= bigMoveThreshold {
                if shouldNotify(symbol: symbol) {
                    let profile = try? await APIService.shared.fetchCompanyProfile(symbol: symbol)
                    let name = profile?.0 ?? symbol
                    let emoji = changePct > 0 ? "🟢" : "🔴"
                    await sendNotification(
                        title: "\(emoji) \(symbol) \(changePct > 0 ? L("surging") : L("dropping"))",
                        body: String(format: "%@ %@ %.2f%% → $%.2f",
                                     name,
                                     changePct > 0 ? "+" : "",
                                     changePct,
                                     price),
                        symbol: symbol,
                        category: "price_alert"
                    )
                    markNotified(symbol: symbol)
                }
            }
        } catch {
            // Silently skip failed checks
        }
    }

    // MARK: - Notification Delivery

    private func sendNotification(title: String, body: String, symbol: String, category: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        content.userInfo = ["symbol": symbol]

        // Badge count +1
        let current = await UIApplication.shared.applicationIconBadgeNumber
        content.badge = NSNumber(value: current + 1)

        let request = UNNotificationRequest(
            identifier: "\(category)_\(symbol)_\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil // Fire immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[NotificationService] Sent: \(title)")
        } catch {
            print("[NotificationService] Failed to send: \(error)")
        }
    }

    // MARK: - Daily Summary

    func scheduleDailySummary() {
        guard dailySummaryEnabled else { return }

        // Schedule for 4:05 PM ET (market close + 5 min)
        var dateComponents = DateComponents()
        dateComponents.hour = 16
        dateComponents.minute = 5
        dateComponents.timeZone = TimeZone(identifier: "America/New_York")

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "📊 \(L("Market Closed"))"
        content.body = L("Tap to see today's market summary and your portfolio performance.")
        content.sound = .default
        content.categoryIdentifier = "daily_summary"

        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Daily summary schedule failed: \(error)")
            }
        }
    }

    func cancelDailySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_summary"])
    }

    // MARK: - Rate Limiting Helpers

    private func shouldNotify(symbol: String) -> Bool {
        if let lastTime = lastNotifiedTime[symbol] {
            return Date().timeIntervalSince(lastTime) >= minNotifInterval
        }
        return true
    }

    private func markNotified(symbol: String) {
        lastNotifiedTime[symbol] = Date()
    }

    // MARK: - Clear Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
