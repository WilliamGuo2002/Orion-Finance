import SwiftUI
import UIKit

// MARK: - Orion Refresh Style
// Customizes the system pull-to-refresh indicator color globally.

enum OrionRefreshStyle {
    static func apply() {
        // Use hardcoded accent color to ensure it works
        UIRefreshControl.appearance().tintColor = UIColor(red: 0.82, green: 0.58, blue: 0.35, alpha: 1.0)
        UIRefreshControl.appearance().attributedTitle = NSAttributedString(
            string: "",
            attributes: [.foregroundColor: UIColor.clear]
        )
    }
}
