import SwiftUI
import UIKit

/// Explicit consent before any data goes to the third-party AI provider (Google Gemini).
/// Required by App Store Review Guideline 5.1.2(i) and good practice under PIPEDA / Quebec Law 25.
///
/// Every AI call path awaits `AIConsent.shared.ensure()` as a safety net. Screens must only reach
/// that path from an explicit user action (send, "Generate snapshot", "Explain with Orion AI") —
/// never on appear — so the consent sheet only ever answers something the user just asked for.
/// It's presented over whatever is on screen (works from sheets and full-screen covers too).
@MainActor
final class AIConsent: ObservableObject {
    static let shared = AIConsent()
    private init() {}

    /// Bump the version if what's shared changes, so users are asked again.
    private static let key = "aiDataConsent_v1"

    @Published private(set) var granted = UserDefaults.standard.bool(forKey: AIConsent.key)

    enum ConsentError: LocalizedError {
        case declined
        var errorDescription: String? {
            L("AI features are off. Allow sharing with Google Gemini in More → AI Data Sharing to use them.")
        }
    }

    private var pending: [CheckedContinuation<Bool, Never>] = []
    private weak var presented: UIViewController?
    /// Swiping the sheet down counts as "Not now".
    private lazy var dismissObserver = SheetDismissObserver { [weak self] in self?.finish(false, alreadyDismissed: true) }

    /// Returns once consent is given; throws if the user declines.
    func ensure() async throws {
        guard await request() else { throw ConsentError.declined }
    }

    /// Asks if needed. Concurrent callers share one prompt.
    func request() async -> Bool {
        if granted { return true }
        return await withCheckedContinuation { continuation in
            pending.append(continuation)
            if presented == nil { present() }
        }
    }

    func setGranted(_ value: Bool) {
        granted = value
        UserDefaults.standard.set(value, forKey: Self.key)
    }

    private func finish(_ allowed: Bool, alreadyDismissed: Bool = false) {
        guard presented != nil || !pending.isEmpty else { return }
        setGranted(allowed)
        if !alreadyDismissed { presented?.dismiss(animated: true) }
        presented = nil
        let waiting = pending
        pending = []
        waiting.forEach { $0.resume(returning: allowed) }
    }

    private func present() {
        guard let top = Self.topViewController() else { finish(false); return }
        let host = UIHostingController(rootView: AIConsentView(
            onAllow: { [weak self] in self?.finish(true) },
            onDecline: { [weak self] in self?.finish(false) }
        ))
        host.modalPresentationStyle = .pageSheet
        if let sheet = host.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        host.presentationController?.delegate = dismissObserver
        presented = host
        top.present(host, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let next = top?.presentedViewController, !next.isBeingDismissed { top = next }
        return top
    }
}

/// Forwards a user's swipe-to-dismiss of a sheet.
private final class SheetDismissObserver: NSObject, UIAdaptivePresentationControllerDelegate {
    let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { onDismiss() }
}

/// What is shared, with whom, and why — in plain language.
struct AIConsentView: View {
    let onAllow: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(.largeTitle))
                    .foregroundColor(AppTheme.accentText)
                    .padding(.top, 24)
                Text(L("Before you use Orion AI"))
                    .font(AppTheme.serifHeadline(24))
                    .foregroundColor(AppTheme.primaryText)
                Text(L("Orion's AI features are powered by Google Gemini, a third-party service. To answer you, Orion sends Google:"))
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.primaryText)

                VStack(alignment: .leading, spacing: 10) {
                    bullet("text.bubble", L("What you type or say to Orion, and any images or files you attach"))
                    bullet("chart.bar", L("Public market data for the stocks you ask about (prices, fundamentals, news headlines)"))
                    bullet("person.crop.circle", L("Your language and the investing preferences you chose"))
                }

                VStack(alignment: .leading, spacing: 10) {
                    bullet("lock.shield", L("Orion does not send your linked account balances, holdings, account numbers, name or email to the AI."))
                    bullet("graduationcap", L("Orion AI is for education and research. It is not a registered adviser and does not tell you what to buy or sell."))
                    bullet("arrow.uturn.backward", L("You can turn this off any time in More → AI Data Sharing."))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.subtleFill))

                Text(L("Google processes this data under its own terms and may handle it outside Canada."))
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)

                VStack(spacing: 10) {
                    Button(action: onAllow) {
                        Text(L("Allow and continue"))
                            .font(.system(.callout, weight: .semibold))
                            .foregroundColor(AppTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.accent))
                    }
                    Button(action: onDecline) {
                        Text(L("Not now"))
                            .font(.system(.subheadline))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(.subheadline))
                .foregroundColor(AppTheme.accentText)
                .frame(width: 20)
            Text(text)
                .font(.system(.subheadline))
                .foregroundColor(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
