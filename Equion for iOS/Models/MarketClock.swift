import Foundation

/// The US equity session calendar, in one place. The home status line, stock detail status and
/// anything else that talks about "the market" read from here, so they can't contradict each other
/// (e.g. "Ready for a new trading day?" next to "Markets are closed today").
enum MarketClock {
    enum Session: Equatable {
        case preMarket      // 4:00–9:30 ET
        case open           // 9:30–16:00 ET
        case afterHours     // 16:00–20:00 ET
        case closed         // overnight on a trading day
        case weekend
        case holiday
    }

    static var eastern: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = AppLocale.easternTime
        return cal
    }

    private static let dayKey: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = AppLocale.easternTime
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func session(at date: Date = Date()) -> Session {
        let cal = eastern
        let weekday = cal.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 { return .weekend }
        if AppTheme.marketHolidays.contains(dayKey.string(from: date)) { return .holiday }
        let minutes = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        switch minutes {
        case 570..<960:  return .open
        case 240..<570:  return .preMarket
        case 960..<1200: return .afterHours
        default:         return .closed
        }
    }

    static var isTradingSessionOpen: Bool { session() == .open }

    /// One calm line for the home header. Facts only — no prompts to trade.
    static func statusLine(at date: Date = Date()) -> String {
        let cal = eastern
        let minutes = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        switch session(at: date) {
        case .open:
            return L("Markets are open · close at 4:00 PM ET")
        case .preMarket:
            return L("Markets open at 9:30 AM ET")
        case .closed where minutes < 240:
            return L("Markets open at 9:30 AM ET")
        case .afterHours, .closed:
            return L("Markets have closed for the day")
        case .weekend:
            return L("Markets are closed for the weekend")
        case .holiday:
            return L("Markets are closed today for a holiday")
        }
    }
}
