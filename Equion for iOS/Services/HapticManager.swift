import UIKit

// MARK: - Centralized Haptic Feedback
// Provides consistent tactile feedback across the app.
// Use sparingly: only for outcomes the user caused (added, removed, failed) — not for every tap,
// tab switch or scroll. Standard controls already provide their own feedback.

enum Haptic {
    /// More → Haptics. Default on. Read straight from defaults so this stays usable off the main actor.
    static var isEnabled: Bool { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }

    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private static let softGen = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let notificationGen = UINotificationFeedbackGenerator()

    /// Lightest tap — tab switch, card select/deselect, scroll snap
    static func light() { guard isEnabled else { return }; lightGen.impactOccurred() }

    /// Medium tap — add/remove item, confirm action
    static func tap() { guard isEnabled else { return }; mediumGen.impactOccurred() }

    /// Very soft — chart data point hover, subtle feedback
    static func soft() { guard isEnabled else { return }; softGen.impactOccurred(intensity: 0.4) }

    /// Selection changed — picker, scrubbing through chart
    static func selection() { guard isEnabled else { return }; selectionGen.selectionChanged() }

    /// Success — item added, action completed
    static func success() { guard isEnabled else { return }; notificationGen.notificationOccurred(.success) }

    /// Error — something failed
    static func error() { guard isEnabled else { return }; notificationGen.notificationOccurred(.error) }

    /// Warning — destructive action about to happen
    static func warning() { guard isEnabled else { return }; notificationGen.notificationOccurred(.warning) }
}
