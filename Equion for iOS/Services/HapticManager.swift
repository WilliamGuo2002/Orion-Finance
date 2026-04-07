import UIKit

// MARK: - Centralized Haptic Feedback
// Provides consistent tactile feedback across the app.
// Usage: Haptic.light()  Haptic.tap()  Haptic.success()

enum Haptic {
    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private static let softGen = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let notificationGen = UINotificationFeedbackGenerator()

    /// Lightest tap — tab switch, card select/deselect, scroll snap
    static func light() { lightGen.impactOccurred() }

    /// Medium tap — add/remove item, confirm action
    static func tap() { mediumGen.impactOccurred() }

    /// Very soft — chart data point hover, subtle feedback
    static func soft() { softGen.impactOccurred(intensity: 0.4) }

    /// Selection changed — picker, scrubbing through chart
    static func selection() { selectionGen.selectionChanged() }

    /// Success — item added, action completed
    static func success() { notificationGen.notificationOccurred(.success) }

    /// Error — something failed
    static func error() { notificationGen.notificationOccurred(.error) }

    /// Warning — destructive action about to happen
    static func warning() { notificationGen.notificationOccurred(.warning) }
}
