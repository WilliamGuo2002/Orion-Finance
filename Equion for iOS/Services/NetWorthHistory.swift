import Foundation
import FirebaseAuth
import FirebaseFirestore

/// One day's net worth, as stored in users/{uid}/netWorthSnapshots/{YYYY-MM-DD}.
/// Written nightly by the `networthsnapshot` Cloud Function and refreshed by the app when opened.
struct NetWorthSnapshotRecord: Equatable {
    let date: String                    // YYYY-MM-DD (Toronto time)
    let totalUSD: Double
    let institutions: [String: Double]  // institution name → USD (debts negative)
}

/// Real net-worth history, so the chart's cash / bank / debt parts aren't flat lines.
@MainActor
final class NetWorthHistory {
    static let shared = NetWorthHistory()
    private init() {}

    /// date → record, for the signed-in user.
    private(set) var records: [String: NetWorthSnapshotRecord] = [:]
    private var loadedUid: String?

    /// Same calendar day as the server job (which runs on Toronto time).
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        return cal
    }()

    static func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func collection(_ uid: String) -> CollectionReference {
        Firestore.firestore().collection("users").document(uid).collection("netWorthSnapshots")
    }

    /// Loads up to ~13 months of snapshots once per signed-in user.
    func loadIfNeeded() async {
        guard let uid = Auth.auth().currentUser?.uid else { records = [:]; loadedUid = nil; return }
        guard loadedUid != uid else { return }
        do {
            let snap = try await collection(uid).order(by: "date", descending: true).limit(to: 400).getDocuments()
            var map: [String: NetWorthSnapshotRecord] = [:]
            for doc in snap.documents {
                let data = doc.data()
                guard let date = data["date"] as? String, let total = data["totalUSD"] as? Double else { continue }
                let inst = (data["institutions"] as? [String: Any] ?? [:]).compactMapValues { ($0 as? NSNumber)?.doubleValue }
                map[date] = NetWorthSnapshotRecord(date: date, totalUSD: total, institutions: inst)
            }
            records = map
            loadedUid = uid
        } catch {
            // No history yet (or offline) — the chart falls back to its estimate.
        }
    }

    /// Upserts today's snapshot with live values. Throttled so refreshes don't spam writes.
    func recordToday(totalUSD: Double, institutions: [String: Double]) {
        guard let uid = Auth.auth().currentUser?.uid, !institutions.isEmpty else { return }
        let day = Self.dayKey(Date())
        let key = "nwSnapshotLast_\(uid)"
        if let last = UserDefaults.standard.dictionary(forKey: key),
           last["day"] as? String == day,
           let value = last["value"] as? Double, abs(value - totalUSD) < 1,
           let at = last["at"] as? Double, Date().timeIntervalSince1970 - at < 300 {
            return
        }
        UserDefaults.standard.set(["day": day, "value": totalUSD, "at": Date().timeIntervalSince1970], forKey: key)

        let record = NetWorthSnapshotRecord(date: day, totalUSD: totalUSD, institutions: institutions)
        if loadedUid == uid { records[day] = record }
        collection(uid).document(day).setData([
            "date": day,
            "totalUSD": totalUSD,
            "institutions": institutions,
            "source": "app",
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    func reset() {
        records = [:]
        loadedUid = nil
    }
}
