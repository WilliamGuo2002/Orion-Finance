import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth

// MARK: - Cloud Functions (callable protocol over HTTPS)

/// Minimal client for Firebase callable functions, so we don't need the FirebaseFunctions SDK.
/// Protocol: POST {"data": …} with the user's Firebase ID token → {"result": …} or {"error": …}.
enum CloudFunctions {
    static let region = "us-central1"

    enum CallError: LocalizedError {
        case notSignedIn
        case server(String)
        case badResponse

        var errorDescription: String? {
            switch self {
            case .notSignedIn: return L("Please sign in first.")
            case .server(let message): return message
            case .badResponse: return L("Unexpected response from server.")
            }
        }
    }

    static func call<T: Decodable>(_ name: String, data: [String: Any] = [:], as type: T.Type) async throws -> T {
        guard let user = Auth.auth().currentUser else { throw CallError.notSignedIn }
        guard let projectID = FirebaseApp.app()?.options.projectID,
              let url = URL(string: "https://\(region)-\(projectID).cloudfunctions.net/\(name)") else {
            throw CallError.badResponse
        }
        let token = try await user.getIDToken()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": data])

        let (body, _) = try await URLSession.shared.data(for: request)
        let envelope: CallableEnvelope<T>
        do {
            envelope = try JSONDecoder().decode(CallableEnvelope<T>.self, from: body)
        } catch {
            // Non-JSON body usually means the function isn't deployed (404 HTML page).
            throw CallError.server(L("Brokerage service isn't available yet."))
        }
        if let error = envelope.error { throw CallError.server(error.message) }
        guard let result = envelope.result else { throw CallError.badResponse }
        return result
    }
}

private struct CallableEnvelope<T: Decodable>: Decodable {
    let result: T?
    let error: CallableErrorBody?
}

private struct CallableErrorBody: Decodable {
    let message: String
}

// MARK: - Models (mirror the normalizers in firebase/functions/src/index.ts)

struct BrokerageSyncResponse: Decodable {
    let connections: [BrokerageConnection]
    let accounts: [LinkedAccount]
}

struct BrokerageConnection: Decodable, Identifiable, Hashable {
    let id: String
    let brokerageName: String
    let disabled: Bool
}

struct LinkedAccount: Decodable, Identifiable, Hashable {
    let id: String
    let connectionId: String?
    /// "investment", "deposit", "line_of_credit", "mortgage", "annuity" (nil from older servers).
    let kind: String?
    let name: String
    let number: String?
    let institution: String
    let totalValue: Double?
    let currency: String
    let cash: [LinkedCash]
    let positions: [LinkedPosition]
    /// Institution's account type, e.g. "TFSA", "RRSP", "FHSA", "Non-registered".
    let rawType: String?
    /// When SnapTrade last got fresh data from the brokerage (ISO 8601).
    let asOf: String?
    /// Positions the server couldn't express as a ticker (options, futures…).
    let unpricedPositions: Int?
    let error: String?

    enum Kind { case investment, cash, debt, other }

    var accountKind: Kind {
        switch kind ?? "investment" {
        case "investment": return .investment
        case "deposit": return .cash
        case "line_of_credit", "mortgage": return .debt
        default: return .other
        }
    }

    /// "••••1234" — never show the full account number.
    var maskedNumber: String? {
        guard let number, number.count >= 4 else { return nil }
        return "••••" + number.suffix(4)
    }
}

struct LinkedCash: Decodable, Hashable {
    let currency: String
    let amount: Double
}

struct LinkedPosition: Decodable, Hashable {
    /// Yahoo-style ticker for quotes (e.g. "XEQT.TO", "BTC-CAD").
    let symbol: String
    /// Ticker as the broker shows it (e.g. "XEQT").
    let displaySymbol: String?
    let description: String?
    let units: Double
    let averageCost: Double?
    let price: Double?
    let currency: String
}

private struct ConnectResponse: Decodable { let redirectURI: String }
private struct OkResponse: Decodable { let ok: Bool }

// MARK: - Money formatting

enum Money {
    /// e.g. "$1,234.56" for USD, "CA$1,234.56" for CAD.
    static func format(_ value: Double, currency: String) -> String {
        value.formatted(.currency(code: currency).precision(.fractionLength(2)))
    }

    /// Short prefix for layouts that draw the symbol separately from the number.
    static func symbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "CAD": return "CA$"
        default:    return currency + " "
        }
    }
}

// MARK: - Brokerage Manager

/// Read-only brokerage data from SnapTrade (via our Cloud Functions).
/// Held in memory only — nothing from the broker is persisted on the device.
@MainActor
final class BrokerageManager: ObservableObject {
    static let shared = BrokerageManager()

    @Published private(set) var connections: [BrokerageConnection] = []
    @Published private(set) var accounts: [LinkedAccount] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastSynced: Date?

    /// The Firebase user these accounts belong to (prevents showing a previous user's data).
    private var ownerUid: String?

    private init() {}

    private var currentUid: String? { Auth.auth().currentUser?.uid }

    /// Accounts for the signed-in user only.
    var currentAccounts: [LinkedAccount] {
        guard let uid = currentUid, uid == ownerUid else { return [] }
        return accounts
    }

    /// Remembered per user so app launch only calls the backend for users who linked something.
    private var linkedFlagKey: String? { currentUid.map { "brokerageLinked_\($0)" } }

    var hasLinkedBefore: Bool {
        guard let key = linkedFlagKey else { return false }
        return UserDefaults.standard.bool(forKey: key)
    }

    private func setLinkedFlag(_ value: Bool) {
        guard let key = linkedFlagKey else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    /// Cheap no-op for users who never linked a brokerage.
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
            let response = try await CloudFunctions.call("snaptradesync", as: BrokerageSyncResponse.self)
            ownerUid = uid
            connections = response.connections
            accounts = response.accounts
            lastError = nil
            lastSynced = Date()
            setLinkedFlag(!response.connections.isEmpty)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// One-time Connection Portal URL. Pass `reconnect` to re-authorize a disabled connection.
    func connectionPortalURL(reconnect connectionId: String? = nil) async throws -> URL {
        var data: [String: Any] = [:]
        if let connectionId { data["reconnect"] = connectionId }
        let response = try await CloudFunctions.call("snaptradeconnect", data: data, as: ConnectResponse.self)
        guard let url = URL(string: response.redirectURI) else { throw CloudFunctions.CallError.badResponse }
        setLinkedFlag(true)   // so the next launch syncs even if the portal didn't redirect back
        return url
    }

    func disconnect(connectionId: String) async throws {
        _ = try await CloudFunctions.call("snaptradedisconnect", data: ["connectionId": connectionId], as: OkResponse.self)
        await sync()
    }

    func reset() {
        ownerUid = currentUid
        connections = []
        accounts = []
        lastError = nil
        lastSynced = nil
    }
}
