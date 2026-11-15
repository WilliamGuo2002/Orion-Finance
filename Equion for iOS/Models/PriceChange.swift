import Foundation

/// One definition of "how much did it move", shared by home, watchlist, stock detail and ticker.
///
/// Daily change is always measured against the previous session's close. Measuring against the
/// first bar of today's chart (the old stock-detail behaviour) silently drops the overnight gap,
/// so the same stock showed −1.57% on one screen and −2.01% on another.
struct PriceChange: Equatable {
    /// Absolute move in price units.
    let amount: Double
    /// Move in percent units: −2.01 means −2.01%.
    let percent: Double

    init?(price: Double, reference: Double) {
        guard price.isFinite, reference.isFinite, price > 0, reference > 0 else { return nil }
        amount = price - reference
        percent = amount / reference * 100
    }

    /// Daily change, or 0 when the reference is missing (keeps list rows from disappearing).
    static func dailyPercent(price: Double, previousClose: Double) -> Double {
        PriceChange(price: price, reference: previousClose)?.percent ?? 0
    }

    var isUp: Bool { amount >= 0 }
}

/// Locale matching the in-app language picker (not the device language), for dates and numbers.
enum AppLocale {
    static var current: Locale {
        switch SettingsManager.shared.appLanguage {
        case "中文": return Locale(identifier: "zh-Hans")
        case "日本語": return Locale(identifier: "ja")
        case "한국어": return Locale(identifier: "ko")
        case "Español": return Locale(identifier: "es")
        case "Français": return Locale(identifier: "fr")
        case "Deutsch": return Locale(identifier: "de")
        case "Português": return Locale(identifier: "pt")
        case "Italiano": return Locale(identifier: "it")
        case "Русский": return Locale(identifier: "ru")
        case "العربية": return Locale(identifier: "ar")
        case "हिन्दी": return Locale(identifier: "hi")
        default: return Locale(identifier: "en_US")
        }
    }

    static let easternTime = TimeZone(identifier: "America/New_York")!
}
