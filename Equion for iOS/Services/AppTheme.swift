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

    /// Secondary / caption text. ≥4.5:1 on background, cards and fills — never fade it with opacity.
    static let secondaryText = Color("ThemeSecondaryText")

    /// Icons, chevrons and other non-text marks that should sit back (≥3:1). Not for body text.
    static let tertiaryText = Color("ThemeTertiaryText")

    /// Accent as text or small icons (≥4.5:1). `accent` itself is for fills and large graphics.
    static let accentText = Color("ThemeAccentText")

    /// Text and icons placed on an `accent` fill (dark ink — white on caramel is only 2.7:1).
    static let onAccent = Color("ThemeOnAccent")

    /// Stock up (green) — adapts to dark mode
    static let positive = Color("ThemePositive")

    /// Stock down (red) — adapts to dark mode
    static let negative = Color("ThemeNegative")

    /// Warnings and errors — ochre, deliberately not the "price down" red.
    static let warning = Color("ThemeWarning")

    /// Tab bar / navigation bar background
    static let barBackground = Color("ThemeBarBackground")

    /// Subtle fill for interval selectors, tag backgrounds etc.
    static let subtleFill = Color("ThemeSubtleFill")

    // =====================
    // MARK: - Design Tokens
    // =====================

    /// Standard card corner radius
    static let cardRadius: CGFloat = 18

    /// Standard card inner padding
    static let cardPadding: CGFloat = 16

    /// Standard module spacing (between cards)
    static let moduleSpacing: CGFloat = 24

    /// Spacing scale. Neighbouring steps differ by ≥25%; space between groups > space within.
    enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        /// Leading/trailing margin for page content.
        static let screenMargin: CGFloat = 20
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

    // ---------------------------------------------------------------
    // Type scale. Every helper maps its size onto one of 9 iOS text styles, so all text follows
    // Dynamic Type and the app uses one consistent scale instead of 21 ad-hoc sizes:
    //   largeTitle 34 · title 28 · title2 22 · title3 20 · body 17 · callout 16 · subheadline 15
    //   footnote 13 · caption 12 · caption2 11
    // Weights collapse to regular / semibold, with bold kept only for hero-sized text.
    // ---------------------------------------------------------------

    /// The text style a legacy point size belongs to.
    static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11.5: return .caption2
        case ..<12.5: return .caption
        case ..<13.5: return .footnote
        case ..<15.5: return .subheadline
        case ..<16.5: return .callout
        case ..<17.5: return .body
        case ..<21.5: return .title3
        case ..<25.5: return .title2
        case ..<31.5: return .title
        default:      return .largeTitle
        }
    }

    /// Regular / semibold / bold (hero only). Light weights are avoided for text.
    static func normalizedWeight(_ weight: Font.Weight, size: CGFloat) -> Font.Weight {
        switch weight {
        case .ultraLight, .thin, .light, .regular, .medium: return .regular
        case .semibold: return .semibold
        default: return size >= 28 ? .bold : .semibold   // bold, heavy, black
        }
    }

    /// Serif title font
    /// - CJK languages: appropriate serif/mincho font + New York fallback
    /// - Others: New York (system serif)
    static func serifTitle(_ size: CGFloat = 22, weight: Font.Weight = .bold) -> Font {
        let style = textStyle(for: size)
        if cjkScript != .none {
            return serifCJKFont(style: style, bold: true)
        }
        return .system(style, design: .serif, weight: weight == .bold ? .semibold : normalizedWeight(weight, size: size))
    }

    /// Serif headline
    static func serifHeadline(_ size: CGFloat = 17, weight: Font.Weight = .semibold) -> Font {
        let style = textStyle(for: size)
        if cjkScript != .none {
            return serifCJKFont(style: style, bold: weight == .bold || weight == .heavy || weight == .black || weight == .semibold)
        }
        return .system(style, design: .serif, weight: normalizedWeight(weight, size: size))
    }

    /// Default body text
    static func body(_ size: CGFloat = 15) -> Font {
        .system(textStyle(for: size))
    }

    /// Numbers and prices: SF Pro with tabular (fixed-width) digits, so columns align and values
    /// don't jitter when they change. (Was SF Mono — slashed zeros, wide punctuation.)
    static func number(_ size: CGFloat = 15, weight: Font.Weight = .medium) -> Font {
        .system(textStyle(for: size), weight: normalizedWeight(weight, size: size)).monospacedDigit()
    }

    /// Caption text
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(textStyle(for: size))
    }

    /// Build a CJK serif font with Latin serif fallback using UIKit font descriptor cascade
    /// - Chinese: Songti SC (宋体)
    /// - Japanese: Hiragino Mincho ProN (ヒラギノ明朝)
    /// - Korean: Apple Myungjo (애플명조) or Nanum Myeongjo
    /// - Latin/numbers: New York (system serif)
    private static func serifCJKFont(style: Font.TextStyle, bold: Bool) -> Font {
        let uiStyle = uiTextStyle(style)
        // Base size at the default content size, then scaled for the user's Dynamic Type setting.
        let size = UIFontDescriptor.preferredFontDescriptor(withTextStyle: uiStyle,
                                                            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize

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
            cjkFontName = "AppleMyungjo"
        case .none:
            cjkFontName = bold ? "STSongti-SC-Bold" : "STSongti-SC-Regular"
        }
        let cjkDescriptor = UIFontDescriptor(name: cjkFontName, size: size)

        // Cascade: New York for Latin, CJK serif for CJK glyphs
        let cascadeDescriptor = nyDescriptor.addingAttributes([
            .cascadeList: [cjkDescriptor]
        ])

        var traits = cascadeDescriptor.symbolicTraits
        if bold { traits.insert(.traitBold) }
        let finalDescriptor = cascadeDescriptor.withSymbolicTraits(traits) ?? cascadeDescriptor

        let base = UIFont(descriptor: finalDescriptor, size: size)
        return Font(UIFontMetrics(forTextStyle: uiStyle).scaledFont(for: base))
    }

    private static func uiTextStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
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

    private static let etDayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = etZone
        return fmt
    }()

}

// MARK: - Card surfaces
/// Resting cards are flat: a solid surface one step off the page background plus a hairline.
/// No drop shadow, no gradient — hierarchy comes from layout and grouping (WWDC25 #356), and a
/// cream-on-cream gradient read as muddy.
private struct CardSurfaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
            .fill(AppTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : AppTheme.border, lineWidth: 0.5)
            )
    }
}

// MARK: - Card Modifier
struct ThemeCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .background(CardSurfaceBackground())
    }
}

/// Surface-only modifier — no padding
struct ThemeCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .background(CardSurfaceBackground())
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

// MARK: - Live Dot (marks the latest point while the market is open)
/// Static on purpose: a pulse that never stops competes with the chart for attention.
struct LivePulseDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

// MARK: - Page header (tab roots)
/// The same title treatment on every tab root: 28pt serif, 20pt margins, optional subtitle and a
/// trailing control slot.
struct PageHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.serifTitle(28))
                    .foregroundColor(AppTheme.primaryText)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

extension PageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// A plain icon button for page headers: 44pt hit target, accent ink, labelled for VoiceOver.
struct HeaderIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(AppTheme.accentText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Section Label (e.g. "Watchlist  2")
/// Section heading for lists on a page background. Hierarchy comes from the serif type, not from
/// accent bars, caps and tracking.
struct SectionLabel: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(AppTheme.serifHeadline(17))
                .foregroundColor(AppTheme.primaryText)
            if let count {
                Text("\(count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Module title (inside cards)
/// Card/module heading: serif headline in primary ink. The `icon` parameter is kept for call-site
/// compatibility but no longer drawn — a bar + icon + title on every card competed for attention.
struct AccentSectionTitle: View {
    let icon: String?
    let title: String

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        Text(title)
            .font(AppTheme.serifHeadline(17))
            .foregroundColor(AppTheme.primaryText)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Change label (the one way to show a price change)
/// Arrow + signed percentage, coloured text only (optionally on a faint tint). Tabular digits,
/// sized by text style, read by VoiceOver as one phrase ("Down 2.01 percent").
/// Every change on every screen uses this — the app previously had four different treatments.
struct ChangeBadge: View {
    let value: Double
    /// Optional absolute change, shown as "−3.34 (−2.01%)".
    var amount: Double? = nil
    var showBackground: Bool = false
    var size: ChangeBadgeSize = .regular

    enum ChangeBadgeSize {
        case compact    // lists, tight spaces
        case regular    // standard
        case large      // hero areas
    }

    private var color: Color {
        value > 0 ? AppTheme.positive : (value < 0 ? AppTheme.negative : AppTheme.secondaryText)
    }

    private var arrow: String {
        value > 0 ? "arrow.up.right" : (value < 0 ? "arrow.down.right" : "minus")
    }

    private var font: Font {
        switch size {
        case .compact: return .footnote.weight(.semibold).monospacedDigit()
        case .regular: return .subheadline.weight(.semibold).monospacedDigit()
        case .large:   return .body.weight(.semibold).monospacedDigit()
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: arrow)
                .imageScale(.small)
                .fontWeight(.semibold)
            if let amount {
                Text(String(format: "%@%.2f (%@%.2f%%)", amount >= 0 ? "+" : "−", abs(amount), value >= 0 ? "+" : "−", abs(value)))
            } else {
                Text(String(format: "%@%.2f%%", value >= 0 ? "+" : "−", abs(value)))
            }
        }
        .font(font)
        .foregroundColor(color)
        .padding(.horizontal, showBackground ? 8 : 0)
        .padding(.vertical, showBackground ? 3 : 0)
        .background {
            if showBackground { Capsule().fill(color.opacity(0.1)) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(value))
    }

    static func spoken(_ value: Double) -> String {
        let pct = String(format: "%.2f", abs(value))
        if value > 0 { return String(format: L("Up %@ percent"), pct) }
        if value < 0 { return String(format: L("Down %@ percent"), pct) }
        return L("Unchanged")
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

// MARK: - Motion tokens
/// The app's five animations. Durations follow NN/g (100–300 ms for in-place changes; entrances a
/// little longer than exits) and WWDC23 spring guidance (bounce 0 by default, never above ~0.15).
/// With Reduce Motion on, everything becomes a short cross-fade.
enum Motion {
    static var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }
    /// Cross-fade used in place of movement when Reduce Motion is on.
    static let fade: Animation = .easeInOut(duration: 0.2)

    /// Press states, selection, toggles.
    static var tap: Animation { reduceMotion ? fade : .snappy(duration: 0.2) }
    /// In-place state changes, expand/collapse.
    static var standard: Animation { reduceMotion ? fade : .smooth(duration: 0.35) }
    /// Page-level changes (entrances); exits use `standard`.
    static var screen: Animation { reduceMotion ? fade : .smooth(duration: 0.45) }
    /// Price and balance changes — no bounce, no colour flash.
    static var number: Animation { reduceMotion ? fade : .smooth(duration: 0.3) }
    /// Release of a momentum gesture.
    static var gesture: Animation { reduceMotion ? fade : .spring(duration: 0.4, bounce: 0.1) }
}

// MARK: - Materials that respect Reduce Transparency
/// `.ultraThinMaterial`, or a solid surface when the user turned on Reduce Transparency
/// (custom materials don't adapt on their own).
struct AdaptiveMaterialBackground<S: Shape>: View {
    let shape: S
    var fallback: Color = AppTheme.cardBackground
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            shape.fill(fallback)
        } else {
            shape.fill(.ultraThinMaterial)
        }
    }
}
