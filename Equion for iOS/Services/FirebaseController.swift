import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class FirebaseController: ObservableObject {
    static let shared = FirebaseController()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false

    // Used for Apple Sign-In nonce
    private var currentNonce: String?

    private init() {
        self.currentUser = auth.currentUser
        self.isLoggedIn = auth.currentUser != nil

        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isLoggedIn = user != nil
            }
        }
    }

    // MARK: - Email/Password Auth
    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        try await ensureUserDoc(user: result.user, email: email)
    }

    func register(email: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        try await db.collection("users").document(result.user.uid).setData([
            "email": email,
            "username": email.components(separatedBy: "@").first ?? "",
            "avatarUrl": "",
            "createdAt": Timestamp()
        ])
    }

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Google Sign-In
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        let authResult = try await auth.signIn(with: credential)
        let email = authResult.user.email ?? ""
        try await ensureUserDoc(user: authResult.user, email: email)
    }

    // MARK: - Apple Sign-In
    func prepareAppleSignIn() -> (nonce: String, hashedNonce: String) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashed = sha256(nonce)
        return (nonce, hashed)
    }

    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let tokenData = appleCredential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingToken
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        let authResult = try await auth.signIn(with: credential)
        let email = authResult.user.email ?? appleCredential.email ?? ""
        try await ensureUserDoc(user: authResult.user, email: email)
    }

    // MARK: - Helpers
    private func ensureUserDoc(user: User, email: String) async throws {
        let docRef = db.collection("users").document(user.uid)
        let doc = try await docRef.getDocument()
        if !doc.exists {
            try await docRef.setData([
                "email": email,
                "username": email.components(separatedBy: "@").first ?? "",
                "avatarUrl": "",
                "createdAt": Timestamp()
            ])
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    enum AuthError: LocalizedError {
        case missingClientID, missingToken
        var errorDescription: String? {
            switch self {
            case .missingClientID: return "Missing Firebase client ID"
            case .missingToken: return "Missing authentication token"
            }
        }
    }

    // MARK: - User Document (with auth fallback)
    /// Returns the uid, waiting briefly for auth if needed
    private func resolvedUid() async -> String? {
        // Fast path: already have user
        if let uid = currentUser?.uid ?? auth.currentUser?.uid {
            return uid
        }
        // Auth state listener may not have fired yet — wait up to 2 seconds
        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            if let uid = auth.currentUser?.uid {
                return uid
            }
        }
        return nil
    }

    private func userDocRef(uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    // MARK: - Watchlist
    func addStockToWatchlist(symbol: String) {
        guard let uid = currentUser?.uid ?? auth.currentUser?.uid else { return }
        userDocRef(uid: uid).collection("watchlist").document(symbol).setData(["addedAt": Timestamp()])
    }

    func removeStockFromWatchlist(symbol: String) {
        guard let uid = currentUser?.uid ?? auth.currentUser?.uid else { return }
        userDocRef(uid: uid).collection("watchlist").document(symbol).delete()
    }

    func getWatchlistSymbols() async -> [String] {
        guard let uid = await resolvedUid() else {
            print("[Watchlist] No authenticated user")
            return []
        }
        let ref = userDocRef(uid: uid).collection("watchlist")

        // Try server first, fall back to cache
        do {
            let snapshot = try await ref.getDocuments(source: .default)
            let symbols = snapshot.documents.map { $0.documentID }
            if !symbols.isEmpty {
                print("[Watchlist] Loaded \(symbols.count) symbols from server")
                return symbols
            }
        } catch {
            print("[Watchlist] Server fetch failed: \(error.localizedDescription)")
        }

        // Fallback: try cache
        do {
            let snapshot = try await ref.getDocuments(source: .cache)
            let symbols = snapshot.documents.map { $0.documentID }
            print("[Watchlist] Loaded \(symbols.count) symbols from cache")
            return symbols
        } catch {
            print("[Watchlist] Cache fetch also failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Chat History
    func saveChatMessage(chatId: String, messages: [[String: String]]) {
        guard let uid = currentUser?.uid ?? auth.currentUser?.uid else { return }
        userDocRef(uid: uid).collection("chats").document(chatId).setData([
            "timestamp": Timestamp(),
            "messages": messages
        ])
    }

    func deleteChatHistory(chatId: String) {
        guard let uid = currentUser?.uid ?? auth.currentUser?.uid else { return }
        userDocRef(uid: uid).collection("chats").document(chatId).delete()
    }

    // MARK: - Stock Comments
    func postComment(symbol: String, text: String) {
        guard let user = currentUser ?? auth.currentUser else { return }
        let commentData: [String: Any] = [
            "userId": user.uid,
            "userName": user.displayName ?? "Anonymous",
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("stockComments").document(symbol).collection("comments").addDocument(data: commentData)
    }

    func fetchComments(symbol: String, limitCount: Int = 5) async -> [StockComment] {
        do {
            let snapshot = try await db.collection("stockComments").document(symbol).collection("comments")
                .order(by: "timestamp", descending: true)
                .limit(to: limitCount)
                .getDocuments()
            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                return StockComment(
                    id: doc.documentID,
                    userId: data["userId"] as? String ?? "",
                    userName: data["userName"] as? String ?? "Anonymous",
                    text: data["text"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - User Interests
    func saveUserInterests(_ interests: [String]) {
        guard let uid = currentUser?.uid ?? auth.currentUser?.uid else { return }
        userDocRef(uid: uid).updateData([
            "interests": interests,
            "interestsUpdatedAt": Timestamp()
        ])
    }

    func getUserInterests() async -> [String] {
        guard let uid = await resolvedUid() else { return [] }
        do {
            let doc = try await userDocRef(uid: uid).getDocument()
            return doc.data()?["interests"] as? [String] ?? []
        } catch {
            return []
        }
    }

    /// Check if this is a brand-new user (no interests set yet)
    func isNewUser() async -> Bool {
        guard let uid = await resolvedUid() else { return false }
        do {
            let doc = try await userDocRef(uid: uid).getDocument()
            let interests = doc.data()?["interests"] as? [String]
            return interests == nil || interests?.isEmpty == true
        } catch {
            return false
        }
    }

    /// Fetch all chat sessions, sorted by timestamp descending
    func getChatSessions() async -> [(id: String, messages: [[String: String]], timestamp: Date)] {
        guard let uid = await resolvedUid() else { return [] }
        let ref = userDocRef(uid: uid).collection("chats")
        do {
            let snapshot = try await ref.order(by: "timestamp", descending: true).getDocuments()
            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let msgs = data["messages"] as? [[String: String]] else { return nil }
                let ts = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                return (id: doc.documentID, messages: msgs, timestamp: ts)
            }
        } catch {
            return []
        }
    }
}
