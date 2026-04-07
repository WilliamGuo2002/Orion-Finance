import SwiftUI
import UIKit

// MARK: - Orion Finance Theme System
// Warm, approachable design for stock beginners

struct AppTheme {

    // =====================
    // MARK: - Colors
    // =====================

    /// Main page background
    static let background = Color("ThemeBackground")

    /// Card / module background
    static let cardBackground = Color("ThemeCardBackground")

    /// Card border / divider color
    static let border = Color("ThemeBorder")

    /// Accent / CTA color (warm caramel)
    static let accent = Color("ThemeAccent")

    /// Accent hover / pressed state
    static let accentDark = Color("ThemeAccentDark")

    /// Primary text
    static let primaryText = Color("ThemePrimaryText")

    /// Secondary / caption text
    static let secondaryText = Color("ThemeSecondaryText")

    /// Stock up (green) — adapts to dark mode
    static let positive = Color("ThemePositive")

    /// Stock down (red) — adapts to dark mode
    static let negative = Color("ThemeNegative")

    /// Warning / error
    static let warning = Color("ThemeNegative")

    /// Tab bar / navigation bar background
    static let barBackground = Color("ThemeBarBackground")

    /// Subtle fill for interval selectors, tag backgrounds etc.
    static let subtleFill = Color("ThemeSubtleFill")

    /// Ad placeholder background
    static let adBackground = Color("ThemeAdBackground")

    // =====================
    // MARK: - Design Tokens
    // =====================

    /// Standard card corner radius
    static let cardRadius: CGFloat = 18

    /// Standard card inner padding
    static let cardPadding: CGFloat = 16

    /// Standard module spacing (between cards)
    static let moduleSpacing: CGFloat = 22

    /// Card shadow
    static func cardShadow() -> some View {
        Color.clear
            .shadow(color: primaryText.opacity(0.10), radius: 10, y: 5)
    }

    // =====================
    // MARK: - Fonts
    // =====================

    /// Current CJK script type based on app language
    private enum CJKScript {
        case simplifiedChinese, japanese, korean, none
    }

    private static var cjkScript: CJKScript {
        switch SettingsManager.shared.appLanguage {
        case "中文": return .simplifiedChinese
        case "日本語": return .japanese
        case "한국어": return .korean
        default: return .none
        }
    }

    /// Serif title font
    /// - CJK languages: appropriate serif/mincho font + New York fallback
    /// - Others: New York (system serif)
    static func serifTitle(_ size: CGFloat = 22, weight: Font.Weight = .bold) -> Font {
        if cjkScript != .none {
            return serifCJKFont(size: size, bold: true)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    /// Serif headline
    static func serifHeadline(_ size: CGFloat = 17, weight: Font.Weight = .semibold) -> Font {
        if cjkScript != .none {
            return serifCJKFont(size: size, bold: weight == .bold || weight == .heavy || weight == .black || weight == .semibold)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    /// Default body text
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, design: .default)
    }

    /// Monospaced for numbers / prices
    static func number(_ size: CGFloat = 15, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Caption text
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, design: .default)
    }

    /// Build a CJK serif font with Latin serif fallback using UIKit font descriptor cascade
    /// - Chinese: Songti SC (宋体)
    /// - Japanese: Hiragino Mincho ProN (ヒラギノ明朝)
    /// - Korean: Apple Myungjo (애플명조) or Nanum Myeongjo
    /// - Latin/numbers: New York (system serif)
    private static func serifCJKFont(size: CGFloat, bold: Bool) -> Font {
        // Primary: New York (system serif) for Latin characters
        let nyDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.serif)?
            .withSize(size) ?? UIFontDescriptor(name: "NewYork-Regular", size: size)

        // CJK serif font name based on language
        let cjkFontName: String
        switch cjkScript {
        case .simplifiedChinese:
            cjkFontName = bold ? "STSongti-SC-Bold" : "STSongti-SC-Regular"
        case .japanese:
            cjkFontName = bold ? "HiraMinProN-W6" : "HiraMinProN-W3"
        case .korean:
            cjkFontName = bold ? "AppleMyungjo" : "AppleMyungjo"
        case .none:
            cjkFontName = bold ? "STSongti-SC-Bold" : "STSongti-SC-Regular"
        }
        let cjkDescriptor = UIFontDescriptor(name: cjkFontName, size: size)

        // Cascade: New York for Latin, CJK serif for CJK glyphs
        let cascadeDescriptor = nyDescriptor.addingAttributes([
            .cascadeList: [cjkDescriptor]
        ])

        // Apply bold trait if needed
        var traits = cascadeDescriptor.symbolicTraits
        if bold { traits.insert(.traitBold) }
        let finalDescriptor = cascadeDescriptor.withSymbolicTraits(traits) ?? cascadeDescriptor

        let uiFont = UIFont(descriptor: finalDescriptor, size: size)
        return Font(uiFont)
    }

    // =====================
    // MARK: - Greeting
    // =====================

    /// Time-based greeting with optional user name
    static func greeting(userName: String? = nil) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greet: String
        switch hour {
        case 5..<12:   greet = L("Good morning")
        case 12..<17:  greet = L("Good afternoon")
        case 17..<22:  greet = L("Good evening")
        default:       greet = L("Good evening")
        }
        if let name = userName, !name.isEmpty {
            return "\(greet), \(name)"
        }
        return greet
    }

    /// Random subtitle for the greeting
    static func greetingSubtitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let subs: [String]
        switch hour {
        case 5..<10:
            subs = [
                L("Let's see how the market opens today"),
                L("A fresh start for your portfolio"),
                L("Ready for a new trading day?")
            ]
        case 10..<16:
            subs = [
                L("Markets are moving — stay informed"),
                L("Here's what's happening today"),
                L("Keep an eye on your investments")
            ]
        case 16..<22:
            subs = [
                L("How did your portfolio do today?"),
                L("Time to review today's moves"),
                L("Markets are winding down")
            ]
        default:
            subs = [
                L("Rest well, markets will be here tomorrow"),
                L("Planning ahead for tomorrow?"),
                L("Take it easy tonight")
            ]
        }
        return subs.randomElement() ?? subs[0]
    }

    // =====================
    // MARK: - Animation Tokens
    // =====================
    static let quickDuration: Double = 0.2
    static let standardDuration: Double = 0.35
    static let slowDuration: Double = 0.5

    static var quickEase: Animation { .easeInOut(duration: quickDuration) }
    static var standardEase: Animation { .easeOut(duration: standardDuration) }
    static var gentleSpring: Animation { .spring(response: 0.4, dampingFraction: 0.75) }

    // =====================
    // MARK: - Accessibility Helpers
    // =====================

    /// Returns ▲ for positive, ▼ for negative, — for zero
    static func changeArrow(_ value: Double) -> String {
        if value > 0 { return "▲" }
        if value < 0 { return "▼" }
        return "—"
    }

    /// Formatted change string with arrow: "▲ +1.23%"
    static func formattedChange(_ value: Double, isPercent: Bool = true) -> String {
        let arrow = changeArrow(value)
        let sign = value >= 0 ? "+" : ""
        let suffix = isPercent ? "%" : ""
        return "\(arrow) \(sign)\(String(format: "%.2f", value))\(suffix)"
    }

    // =====================
    // MARK: - Market Status
    // =====================

    private static let etZone = TimeZone(identifier: "America/New_York")!

    /// US market holidays for current year (month, day)
    /// Covers: New Year, MLK Day, Presidents Day, Good Friday, Memorial Day,
    ///         Juneteenth, Independence Day, Labor Day, Thanksgiving, Christmas
    static var marketHolidays: Set<String> {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etZone
        let year = cal.component(.year, from: Date())
        // Fixed holidays
        var holidays: Set<String> = [
            "\(year)-01-01", // New Year's Day
            "\(year)-06-19", // Juneteenth
            "\(year)-07-04", // Independence Day
            "\(year)-12-25", // Christmas
        ]
        // MLK Day: 3rd Monday of January
        holidays.insert(nthWeekday(nth: 3, weekday: 2, month: 1, year: year, cal: cal))
        // Presidents Day: 3rd Monday of February
        holidays.insert(nthWeekday(nth: 3, weekday: 2, month: 2, year: year, cal: cal))
        // Memorial Day: last Monday of May
        holidays.insert(lastWeekday(weekday: 2, month: 5, year: year, cal: cal))
        // Labor Day: 1st Monday of September
        holidays.insert(nthWeekday(nth: 1, weekday: 2, month: 9, year: year, cal: cal))
        // Thanksgiving: 4th Thursday of November
        holidays.insert(nthWeekday(nth: 4, weekday: 5, month: 11, year: year, cal: cal))
        return holidays
    }

    private static func nthWeekday(nth: Int, weekday: Int, month: Int, year: Int, cal: Calendar) -> String {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.weekday = weekday; comps.weekdayOrdinal = nth
        comps.timeZone = etZone
        if let date = cal.date(from: comps) {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = etZone
            return fmt.string(from: date)
        }
        return ""
    }

    private static func lastWeekday(weekday: Int, month: Int, year: Int, cal: Calendar) -> String {
        var comps = DateComponents()
        comps.year = year; comps.month = month + 1; comps.day = 0
        comps.timeZone = etZone
        guard let lastDay = cal.date(from: comps) else { return "" }
        let wd = cal.component(.weekday, from: lastDay)
        var diff = wd - weekday
        if diff < 0 { diff += 7 }
        guard let date = cal.date(byAdding: .day, value: -diff, to: lastDay) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = etZone
        return fmt.string(from: date)
    }

    /// Returns a closure reason if market is closed today, or nil if it's a normal trading day.
    static func marketClosedReason() -> String? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etZone
        let now = Date()
        let weekday = cal.component(.weekday, from: now)

        // Weekend
        if weekday == 1 { return L("Markets are closed today — enjoy your Sunday") }
        if weekday == 7 { return L("Markets are closed today — enjoy your Saturday") }

        // Holiday
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = etZone
        let today = fmt.string(from: now)
        if marketHolidays.contains(today) {
            return L("Markets are closed today for a holiday")
        }

        return nil
    }
}

// MARK: - Shared card background builder
private struct CardBackgroundContent: View {
    let colorScheme: ColorScheme
    var glossPosition: UnitPoint? = nil // nil = no gloss active

    var body: some View {
        ZStack {
            // Frosted glass base
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(
                    colorScheme == .dark
                        ? AppTheme.cardBackground.opacity(0.85)
                        : AppTheme.cardBackground.opacity(0.75)
                )
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .fill(.ultraThinMaterial)
                )

            // Warm diagonal gradient overlay
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.06), Color.clear]
                            : [Color(red: 0.98, green: 0.96, blue: 0.93).opacity(0.6), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Light mode: subtle bottom vignette for depth
            if colorScheme == .light {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color(red: 0.90, green: 0.88, blue: 0.85).opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Gloss highlight following finger
            if let pos = glossPosition {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(
                        RadialGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.12), Color.clear]
                                : [Color.white.opacity(0.55), Color.clear],
                            center: pos,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .blendMode(.overlay)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

// MARK: - Interactive Card Modifier
struct ThemeCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var pressedAt: Date? = nil

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(CardBackgroundContent(colorScheme: colorScheme, glossPosition: isPressed ? .center : nil))
            .cornerRadius(AppTheme.cardRadius)
            // Outer glow border
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.12), Color.white.opacity(0.04)]
                                : [Color.white.opacity(0.9), AppTheme.border.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: colorScheme == .dark ? 0.5 : 1.0
                    )
            )
            // 1. Press scale
            .scaleEffect(isPressed ? 0.97 : 1.0)
            // 4. Shadow shrinks on press, expands on release
            .shadow(color: Color.black.opacity(colorScheme == .dark
                ? (isPressed ? 0.15 : 0.35)
                : (isPressed ? 0.05 : 0.12)), radius: isPressed ? 6 : 16, y: isPressed ? 3 : 8)
            .shadow(color: Color.black.opacity(colorScheme == .dark
                ? (isPressed ? 0.1 : 0.2)
                : (isPressed ? 0.03 : 0.06)), radius: isPressed ? 1 : 4, y: isPressed ? 1 : 2)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            // Press detection with minimum visible duration
            .onLongPressGesture(minimumDuration: 60, pressing: { pressing in
                if pressing {
                    pressedAt = Date()
                    withAnimation(.easeIn(duration: 0.1)) { isPressed = true }
                } else {
                    // Ensure animation is visible for at least 150ms
                    let elapsed = Date().timeIntervalSince(pressedAt ?? Date())
                    let delay = max(0, 0.15 - elapsed)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
                    }
                }
            }, perform: {})
    }
}

/// Surface-only modifier — no padding, with interaction
struct ThemeCardSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var pressedAt: Date? = nil

    func body(content: Content) -> some View {
        content
            .background(CardBackgroundContent(colorScheme: colorScheme, glossPosition: isPressed ? .center : nil))
            .cornerRadius(AppTheme.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.12), Color.white.opacity(0.04)]
                                : [Color.white.opacity(0.9), AppTheme.border.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: colorScheme == .dark ? 0.5 : 1.0
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: Color.black.opacity(colorScheme == .dark
                ? (isPressed ? 0.15 : 0.35)
                : (isPressed ? 0.05 : 0.12)), radius: isPressed ? 6 : 16, y: isPressed ? 3 : 8)
            .shadow(color: Color.black.opacity(colorScheme == .dark
                ? (isPressed ? 0.05 : 0.05)
                : (isPressed ? 0.03 : 0.06)), radius: isPressed ? 1 : 4, y: isPressed ? 1 : 2)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: 60, pressing: { pressing in
                if pressing {
                    pressedAt = Date()
                    withAnimation(.easeIn(duration: 0.1)) { isPressed = true }
                } else {
                    let elapsed = Date().timeIntervalSince(pressedAt ?? Date())
                    let delay = max(0, 0.15 - elapsed)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
                    }
                }
            }, perform: {})
    }
}

extension View {
    func themeCard() -> some View {
        self.modifier(ThemeCardModifier())
    }

    /// Apply card surface (gradient bg, shadow, highlight) without extra padding
    func themeCardSurface() -> some View {
        self.modifier(ThemeCardSurface())
    }
}

// MARK: - Chat Bubble Shape (with tail)
struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16
        let tailW: CGFloat = 8
        let tailH: CGFloat = 10

        var path = Path()

        if isUser {
            // Rounded rect with tail on bottom-right
            path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - tailW, height: rect.height), cornerSize: CGSize(width: r, height: r))
            // Tail
            path.move(to: CGPoint(x: rect.width - tailW, y: rect.height - 20))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height),
                control: CGPoint(x: rect.width - tailW + 2, y: rect.height - 4)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.width - tailW - 4, y: rect.height),
                control: CGPoint(x: rect.width - tailW - 2, y: rect.height)
            )
        } else {
            // Rounded rect with tail on bottom-left
            path.addRoundedRect(in: CGRect(x: tailW, y: 0, width: rect.width - tailW, height: rect.height), cornerSize: CGSize(width: r, height: r))
            // Tail
            path.move(to: CGPoint(x: tailW, y: rect.height - 20))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height),
                control: CGPoint(x: tailW - 2, y: rect.height - 4)
            )
            path.addQuadCurve(
                to: CGPoint(x: tailW + 4, y: rect.height),
                control: CGPoint(x: tailW + 2, y: rect.height)
            )
        }

        return path
    }
}

// MARK: - Live Pulse Dot (breathing dot at chart end / live indicator)
struct LivePulseDot: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: pulse ? 16 : 8, height: pulse ? 16 : 8)
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.5), radius: 3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Section Label (e.g. "WATCHLIST · 5 items")
struct SectionLabel: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Accent vertical bar — thick & vivid
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.accent)
                .frame(width: 4, height: 16)

            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(AppTheme.secondaryText)
                .tracking(1.2)
            if let count {
                Text("·")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.accent)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

// MARK: - Accent Section Header (for card module titles)
struct AccentSectionTitle: View {
    let icon: String?
    let title: String

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            // Accent bar — bold and vivid
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.accent)
                .frame(width: 4, height: 20)

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }

            Text(title)
                .font(AppTheme.serifHeadline())
                .foregroundColor(AppTheme.primaryText)
        }
    }
}

// MARK: - Change Badge (SF Symbol arrow + percentage pill)
/// A rich badge showing change direction with icon + percentage
struct ChangeBadge: View {
    let value: Double
    var showBackground: Bool = true
    var size: ChangeBadgeSize = .regular

    enum ChangeBadgeSize {
        case compact    // for lists, tight spaces
        case regular    // standard
        case large      // for hero areas
    }

    private var changeColor: Color {
        value > 0 ? AppTheme.positive : (value < 0 ? AppTheme.negative : AppTheme.secondaryText)
    }

    private var arrowIcon: String {
        value > 0 ? "arrow.up.right" : (value < 0 ? "arrow.down.right" : "minus")
    }

    private var changeText: String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }

    private var iconSize: CGFloat {
        switch size {
        case .compact: return 8
        case .regular:  return 9
        case .large:    return 11
        }
    }

    private var fontSize: CGFloat {
        switch size {
        case .compact: return 11
        case .regular:  return 12
        case .large:    return 14
        }
    }

    private var circleSize: CGFloat {
        switch size {
        case .compact: return 18
        case .regular:  return 22
        case .large:    return 26
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            // Arrow icon in vivid tinted circle
            ZStack {
                Circle()
                    .fill(changeColor.opacity(0.18))
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: arrowIcon)
                    .font(.system(size: iconSize, weight: .black))
                    .foregroundColor(changeColor)
            }

            Text(changeText)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(changeColor)
        }
        .padding(.horizontal, showBackground ? 8 : 0)
        .padding(.vertical, showBackground ? 4 : 0)
        .background(
            Group {
                if showBackground {
                    Capsule().fill(changeColor.opacity(0.1))
                }
            }
        )
    }
}

// MARK: - Backward Compatibility (bridge AppColors → AppTheme)
enum AppColors {
    static var uiBackground: Color { AppTheme.background }
    static var buttonColor: Color { AppTheme.secondaryText }
    static var textColor: Color { AppTheme.primaryText }
    static var warningColor: Color { AppTheme.warning }
    static var positiveColor: Color { AppTheme.positive }
    static var negativeColor: Color { AppTheme.negative }
}
