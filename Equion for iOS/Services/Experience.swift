import Foundation

// MARK: - Investing experience
/// One onboarding question ("How familiar are you with investing?") that only sets DEFAULTS:
/// chart type, volume, and how much Orion explains. Never locks anything — every pro feature is
/// one tap away for everyone, and anything the user changes by hand wins over these defaults.
enum ExperienceLevel: String, CaseIterable, Identifiable {
    case beginner      // just getting started
    case some          // has bought a few stocks or funds
    case experienced   // has their own approach

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return L("Just getting started")
        case .some: return L("I've bought a few stocks or funds")
        case .experienced: return L("I have my own approach")
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return L("Simple charts, and terms explained along the way")
        case .some: return L("A bit more detail, still plain language")
        case .experienced: return L("Candlesticks, volume and straight-to-the-point answers")
        }
    }

    /// Settings row detail.
    var shortTitle: String {
        switch self {
        case .beginner: return L("Beginner")
        case .some: return L("Some experience")
        case .experienced: return L("Experienced")
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "leaf"
        case .some: return "chart.line.uptrend.xyaxis"
        case .experienced: return "chart.bar.xaxis"
        }
    }

    fileprivate var chartStyle: ChartDisplay.Style { self == .experienced ? .candles : .line }
    fileprivate var volume: ChartDisplay.Volume {
        switch self {
        case .beginner: return .off
        case .some: return .mono
        case .experienced: return .upDown
        }
    }

    /// Appended to Orion's system prompt.
    var aiTone: String {
        switch self {
        case .beginner:
            return "The user is new to investing. Use plain words, briefly explain any financial term the first time it appears, and prefer a short example over jargon."
        case .some:
            return "The user knows the basics of investing. Keep explanations plain, and explain only less common terms."
        case .experienced:
            return "The user is an experienced investor. Be concise and data-first; skip basic definitions unless asked."
        }
    }
}

enum Experience {
    static let key = "experienceLevel"
    /// Set once the user changes chart settings by hand; experience defaults never override it.
    static let chartCustomizedKey = "chartDisplayCustomized"

    /// nil for people who onboarded before the question existed — they keep today's defaults.
    static var current: ExperienceLevel? {
        UserDefaults.standard.string(forKey: key).flatMap(ExperienceLevel.init(rawValue:))
    }

    static func set(_ level: ExperienceLevel) {
        let d = UserDefaults.standard
        d.set(level.rawValue, forKey: key)
        guard !d.bool(forKey: chartCustomizedKey) else { return }
        d.set(level.chartStyle.rawValue, forKey: ChartDisplay.styleKey)
        d.set(level.volume.rawValue, forKey: ChartDisplay.volumeKey)
    }

    static func markChartCustomized() {
        UserDefaults.standard.set(true, forKey: chartCustomizedKey)
    }
}
