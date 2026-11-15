import Foundation
import SwiftUI
import FirebaseAuth
import UserNotifications

/// A linked connection that needs the user's attention.
struct SyncIssue: Identifiable, Hashable {
    enum Kind: String { case reconnect, stale, failed }
    let id: String              // "<kind>-<connection or item id>"
    let connectionId: String
    let institution: String
    let kind: Kind
    let lastUpdated: Date?

    var message: String {
        switch kind {
        case .reconnect:
            return String(format: L("%@ needs you to sign in again"), institution)
        case .stale:
            if let lastUpdated {
                return String(format: L("%@ hasn't updated since %@"), institution,
                              lastUpdated.formatted(.relative(presentation: .named)))
            }
            return String(format: L("%@ hasn't updated recently"), institution)
        case .failed:
            return String(format: L("%@ couldn't be loaded"), institution)
        }
    }
}

/// Connection freshness for every linked brokerage (SnapTrade) and bank (Plaid).
@MainActor
enum SyncHealth {
    /// Institutions refresh at least daily; three days without new data means something is wrong.
    static let staleAfter: TimeInterval = 3 * 24 * 3600

    // Formatters are costly to create and parse() runs inside view bodies (banner, footers).
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain = ISO8601DateFormatter()
    private static let dayOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static func parse(_ iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        if let d = withFraction.date(from: iso) { return d }
        if let d = plain.date(from: iso) { return d }
        // Some providers send "YYYY-MM-DD" only
        return dayOnly.date(from: String(iso.prefix(10)))
    }

    /// Most recent data among a brokerage connection's accounts.
    static func lastUpdated(connection: BrokerageConnection) -> Date? {
        BrokerageManager.shared.currentAccounts
            .filter { $0.connectionId == connection.id }
            .compactMap { parse($0.asOf) }
            .max()
    }

    static func lastUpdated(item: BankItem) -> Date? { parse(item.lastUpdated) }

    static func issues() -> [SyncIssue] {
        var out: [SyncIssue] = []
        let now = Date()
        let brokerage = BrokerageManager.shared
        let ownsAccounts = !brokerage.currentAccounts.isEmpty || brokerage.connections.isEmpty
        if ownsAccounts {
            for c in brokerage.connections {
                let updated = lastUpdated(connection: c)
                if c.disabled {
                    out.append(SyncIssue(id: "reconnect-\(c.id)", connectionId: c.id, institution: c.brokerageName,
                                         kind: .reconnect, lastUpdated: updated))
                } else if let updated, now.timeIntervalSince(updated) > staleAfter {
                    out.append(SyncIssue(id: "stale-\(c.id)", connectionId: c.id, institution: c.brokerageName,
                                         kind: .stale, lastUpdated: updated))
                }
            }
        }
        for item in BankManager.shared.currentItems {
            let updated = lastUpdated(item: item)
            if item.needsReconnect {
                out.append(SyncIssue(id: "reconnect-\(item.id)", connectionId: item.id, institution: item.institution,
                                     kind: .reconnect, lastUpdated: updated))
            } else if item.error != nil {
                out.append(SyncIssue(id: "failed-\(item.id)", connectionId: item.id, institution: item.institution,
                                     kind: .failed, lastUpdated: updated))
            } else if let updated, now.timeIntervalSince(updated) > staleAfter {
                out.append(SyncIssue(id: "stale-\(item.id)", connectionId: item.id, institution: item.institution,
                                     kind: .stale, lastUpdated: updated))
            }
        }
        return out
    }

    /// "Updated 5 hours ago" for list footers.
    static func freshnessText(_ date: Date?) -> String? {
        guard let date else { return nil }
        return String(format: L("Updated %@"), date.formatted(.relative(presentation: .named)))
    }
}

// MARK: - Background check → local notification

/// Runs from the existing background refresh task: re-syncs linked accounts and notifies once
/// per newly broken connection (so users fix it before their net worth goes stale).
@MainActor
enum ConnectionMonitor {
    private static let lastCheckKey = "connMonitor_lastCheck"
    private static func notifiedKey(_ uid: String) -> String { "connMonitor_notified_\(uid)" }

    static func checkAndNotify() async {
        guard SettingsManager.shared.notificationsEnabled, let uid = Auth.auth().currentUser?.uid else { return }
        // At most every 6 hours — syncing calls the providers.
        let last = UserDefaults.standard.double(forKey: lastCheckKey)
        guard Date().timeIntervalSince1970 - last > 6 * 3600 else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)

        async let b: Void = BrokerageManager.shared.syncIfLinked()
        async let p: Void = BankManager.shared.syncIfLinked()
        _ = await (b, p)

        let issues = SyncHealth.issues().filter { $0.kind != .failed }
        let alreadyNotified = Set(UserDefaults.standard.stringArray(forKey: notifiedKey(uid)) ?? [])
        for issue in issues where !alreadyNotified.contains(issue.id) {
            let content = UNMutableNotificationContent()
            content.title = L("Account connection")
            content.body = issue.message
            content.sound = .default
            let request = UNNotificationRequest(identifier: "conn_\(issue.id)", content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
        }
        // Remember current issues only, so a connection that breaks again later notifies again.
        UserDefaults.standard.set(issues.map(\.id), forKey: notifiedKey(uid))
    }
}

// MARK: - Banner

/// Shown on home and the Accounts page when a connection needs attention. Observes the
/// managers itself so the heavy parent views don't re-render on sync updates.
struct SyncHealthBanner: View {
    @ObservedObject private var brokerage = BrokerageManager.shared
    @ObservedObject private var bank = BankManager.shared

    var body: some View {
        let issues = SyncHealth.issues()
        if !issues.isEmpty {
            NavigationLink {
                LinkedAccountsView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(.callout))
                        .foregroundColor(AppTheme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issues.count == 1 ? issues[0].message
                             : String(format: L("%d connections need attention"), issues.count))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.leading)
                        Text(L("Your net worth may be out of date. Tap to fix."))
                            .font(AppTheme.caption(11))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(14)
                .themeCardSurface()
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }
}
