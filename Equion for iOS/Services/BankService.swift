import Foundation
import SwiftUI
import FirebaseAuth

// MARK: - Models (mirror the normalizers in firebase/functions/src/plaid.ts)

struct BankSyncResponse: Decodable {
    let items: [BankItem]
    let accounts: [BankAccount]
}

/// One linked bank login (a Plaid "Item").
struct BankItem: Decodable, Identifiable, Hashable {
    let id: String
    let institution: String
    let needsReconnect: Bool
    let error: String?
    /// Last successful refresh from the bank (ISO 8601).
    let lastUpdated: String?
}

struct BankAccount: Decodable, Identifiable, Hashable {
    let id: String
    let itemId: String
    let name: String
    let mask: String?
    /// depository | credit | loan | investment | other
    let type: String
    let subtype: String?
    /// Credit / loan: amount owed (positive).
    let current: Double?
    let available: Double?
    let currency: String

    var isDebt: Bool { type == "credit" || type == "loan" }

    /// Signed contribution to net worth, in `currency` (debts negative).
    var netValue: Double? {
        if isDebt { return current.map { -abs($0) } }
        return current ?? available
    }

    var maskedNumber: String? { mask.map { "••" + $0 } }

    var icon: String {
        switch type {
        case "credit": return "creditcard.fill"
        case "loan": return "house.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        default: return "banknote.fill"
        }
    }
}

private struct LinkTokenResponse: Decodable { let linkToken: String; let url: String }
private struct CompleteResponse: Decodable { let added: Int }
private struct RemoveResponse: Decodable { let ok: Bool }

// MARK: - Bank Manager

/// Read-only bank balances from Plaid (via our Cloud Functions).
/// Held in memory only — nothing from the bank is persisted on the device.
@MainActor
final class BankManager: ObservableObject {
    static let shared = BankManager()

    @Published private(set) var items: [BankItem] = []
    @Published private(set) var accounts: [BankAccount] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastSynced: Date?

    /// The Firebase user these accounts belong to (prevents showing a previous user's data).
    private var ownerUid: String?

    private init() {}

    private var currentUid: String? { Auth.auth().currentUser?.uid }

    /// Accounts for the signed-in user only.
    var currentAccounts: [BankAccount] {
        guard let uid = currentUid, uid == ownerUid else { return [] }
        return accounts
    }

    var currentItems: [BankItem] {
        guard let uid = currentUid, uid == ownerUid else { return [] }
        return items
    }

    func institution(for account: BankAccount) -> String {
        items.first { $0.id == account.itemId }?.institution ?? L("Bank")
    }

    /// Remembered per user so app launch only calls the backend for users who linked a bank.
    private var linkedFlagKey: String? { currentUid.map { "bankLinked_\($0)" } }

    private var hasLinkedBefore: Bool {
        guard let key = linkedFlagKey else { return false }
        return UserDefaults.standard.bool(forKey: key)
    }

    private func setLinkedFlag(_ value: Bool) {
        guard let key = linkedFlagKey else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    func syncIfLinked() async {
        guard hasLinkedBefore else {
            if ownerUid != currentUid { reset() }
            return
        }
        await sync()
    }

    func sync() async {
        guard let uid = currentUid else { reset(); return }
        if ownerUid != uid { reset() }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let response = try await CloudFunctions.call("plaidsync", as: BankSyncResponse.self)
            ownerUid = uid
            items = response.items
            accounts = response.accounts
            lastError = nil
            lastSynced = Date()
            setLinkedFlag(!response.items.isEmpty)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Plaid Hosted Link page. Pass `reconnect` to re-authenticate an existing bank.
    func startLink(reconnect itemId: String? = nil) async throws -> (linkToken: String, url: URL) {
        var data: [String: Any] = [:]
        if let itemId { data["itemId"] = itemId }
        let response = try await CloudFunctions.call("plaidlinktoken", data: data, as: LinkTokenResponse.self)
        guard let url = URL(string: response.url) else { throw CloudFunctions.CallError.badResponse }
        return (response.linkToken, url)
    }

    /// Called after the Plaid page closes: exchanges any new bank logins on the server.
    @discardableResult
    func completeLink(linkToken: String) async throws -> Int {
        let response = try await CloudFunctions.call("plaidcomplete", data: ["linkToken": linkToken], as: CompleteResponse.self)
        if response.added > 0 { setLinkedFlag(true) }
        return response.added
    }

    func remove(itemId: String) async throws {
        _ = try await CloudFunctions.call("plaidremove", data: ["itemId": itemId], as: RemoveResponse.self)
        await sync()
    }

    func reset() {
        ownerUid = currentUid
        items = []
        accounts = []
        lastError = nil
        lastSynced = nil
    }
}
