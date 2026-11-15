import SwiftUI
import UIKit

// MARK: - Orion Refresh Style
// Customizes the system pull-to-refresh indicator color globally.

enum OrionRefreshStyle {
    static func apply() {
        // Use hardcoded accent color to ensure it works
        UIRefreshControl.appearance().tintColor = UIColor(named: "ThemeAccentText")
        UIRefreshControl.appearance().attributedTitle = NSAttributedString(
            string: "",
            attributes: [.foregroundColor: UIColor.clear]
        )
    }
}
