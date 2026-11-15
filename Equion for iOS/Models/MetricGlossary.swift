import Foundation

/// Plain-language definitions for the Fundamentals metrics. Shown instantly and offline, so tapping
/// a metric never needs the AI (or an AI consent prompt). The AI explanation for the specific
/// company is an opt-in extra below it.
enum MetricGlossary {
    /// Keyed by the English metric label used in the Fundamentals grid.
    static func definition(for key: String) -> String? {
        entries[key].map(L)
    }

    private static let entries: [String: String] = [
        "P/E": "Price-to-earnings ratio: the share price divided by the company's earnings per share over the last year. It shows how many dollars investors pay for each dollar of profit. A higher number often means investors expect faster growth — or that the stock is expensive. It's most useful compared with similar companies.",
        "P/B": "Price-to-book ratio: the share price divided by the company's book value (assets minus liabilities) per share. Below 1 means the market values the company at less than its accounting net worth. It's more meaningful for banks and asset-heavy businesses than for software companies.",
        "EPS Growth": "How much earnings per share grew compared with a year earlier. Sustained growth tends to support a higher valuation; a single strong year can come from one-off items.",
        "Revenue Growth": "How much the company's sales grew compared with a year earlier. It shows demand for the business before costs — pair it with margins to see whether the growth is profitable.",
        "Div Yield": "Dividend yield: yearly dividends per share divided by the share price. A 2% yield pays about $2 a year for every $100 invested. An unusually high yield can mean the market expects the dividend to be cut.",
        "Beta": "How much the stock has tended to move relative to the overall market. 1 moves with the market, above 1 swings more, below 1 swings less. It describes past volatility, not future returns.",
        "ROE": "Return on equity: yearly profit divided by shareholders' equity. It shows how efficiently the company turns invested capital into profit. Very high ROE can also come from heavy borrowing.",
        "D/E": "Debt-to-equity: total debt divided by shareholders' equity. A higher number means the company relies more on borrowing, which magnifies both gains and risks. Normal levels vary widely by industry.",
        "Gross Margin": "The share of revenue left after the direct cost of making the product or service. A 70% gross margin keeps $70 of every $100 in sales to pay for everything else.",
        "Op Margin": "Operating margin: the share of revenue left after all operating costs such as salaries, research and marketing. It shows how profitable the core business is before interest and taxes.",
    ]
}
