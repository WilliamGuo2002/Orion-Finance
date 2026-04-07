import SwiftUI
import Charts

// MARK: - Investors List View
struct InvestorsView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    private var isWide: Bool { hSize == .regular || vSize == .compact }

    private var gridColumns: [GridItem] {
        if isWide {
            return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        }
        return [GridItem(.flexible())]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header — matching watchlist style
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Guru Portfolios"))
                    .font(AppTheme.serifTitle(26))
                    .foregroundColor(AppTheme.primaryText)
                Text(L("SEC 13F filings from top investors"))
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Investor list — card style
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(InvestorService.investors) { investor in
                        NavigationLink(destination: InvestorDetailView(investor: investor)) {
                            InvestorCardView(investor: investor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 80)
            }
        }
        .background(AppTheme.background)
    }
}

// MARK: - Investor Card View (matches watchlist card style)
struct InvestorCardView: View {
    let investor: FamousInvestor

    var body: some View {
        HStack(spacing: 14) {
            // Avatar circle with initials
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(initials(investor.name))
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.accent)
            }

            // Name & fund
            VStack(alignment: .leading, spacing: 4) {
                Text(investor.name)
                    .font(AppTheme.serifHeadline(16))
                    .foregroundColor(AppTheme.primaryText)
                Text(investor.fund)
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
                Text(investor.description)
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // SEC badge + chevron
            VStack(spacing: 6) {
                Text("13F")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(AppTheme.accent.opacity(0.1))
                    )
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .themeCardSurface()
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Investor Detail View
struct InvestorDetailView: View {
    let investor: FamousInvestor
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    private var isWide: Bool { hSize == .regular || vSize == .compact }

    @State private var portfolio: InvestorPortfolio?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let chartColors: [Color] = [
        AppTheme.accent,
        AppTheme.positive,
        Color.orange,
        AppTheme.negative,
        Color.purple,
        Color.cyan, Color.yellow, Color.pink, Color.mint, Color.indigo,
        AppTheme.secondaryText
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Investor info header — card style
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Text(initials(investor.name))
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(investor.name)
                            .font(AppTheme.serifTitle(22))
                            .foregroundColor(AppTheme.primaryText)
                        Text(investor.fund)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                if isLoading {
                    ProgressView(L("Loading..."))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(AppTheme.warning)
                        Text(error)
                            .foregroundColor(AppTheme.warning)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else if let portfolio = portfolio {
                    portfolioContent(portfolio)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPortfolio()
        }
    }

    // MARK: - Portfolio Content
    @ViewBuilder
    private func portfolioContent(_ portfolio: InvestorPortfolio) -> some View {
        // Filing date + total value — card style
        filingInfoCard(portfolio)

        if isWide {
            // iPad: pie chart and holdings side by side
            HStack(alignment: .top, spacing: 16) {
                pieChartSection(portfolio)
                    .frame(maxWidth: .infinity)
                holdingsListSection(portfolio)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        } else {
            // iPhone: stacked
            pieChartSection(portfolio)
            holdingsListSection(portfolio)
        }
    }

    @ViewBuilder
    private func filingInfoCard(_ portfolio: InvestorPortfolio) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Filing Date"))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
                Text(portfolio.filingDate)
                    .font(AppTheme.number(14))
                    .foregroundColor(AppTheme.primaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(L("Total Value"))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
                Text(formatValue(portfolio.totalValue))
                    .font(AppTheme.number(14))
                    .foregroundColor(AppTheme.primaryText)
            }
            Spacer()
            Text("SEC 13F")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(AppTheme.accent.opacity(0.1)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .themeCardSurface()
        .padding(.horizontal, 16)
    }

    // MARK: - Pie Chart
    @ViewBuilder
    private func pieChartSection(_ portfolio: InvestorPortfolio) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AccentSectionTitle(L("Top Holdings"), icon: "chart.pie")

            let top = Array(portfolio.holdings.prefix(10))
            let otherValue = portfolio.holdings.dropFirst(10).reduce(0.0) { $0 + $1.value }

            Chart {
                ForEach(Array(top.enumerated()), id: \.element.id) { idx, holding in
                    SectorMark(
                        angle: .value(holding.name, holding.value),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(chartColors[idx % chartColors.count])
                    .annotation(position: .overlay) {
                        if holding.percentage > 5 {
                            Text(String(format: "%.0f%%", holding.percentage))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                if otherValue > 0 {
                    SectorMark(
                        angle: .value("Other", otherValue),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.4))
                }
            }
            .frame(height: 250)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(Array(top.enumerated()), id: \.element.id) { idx, holding in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(chartColors[idx % chartColors.count])
                            .frame(width: 8, height: 8)
                        Text(holding.name)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                if otherValue > 0 {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.secondaryText.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text(L("Other"))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                    }
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .themeCardSurface()
        .padding(.horizontal, isWide ? 0 : 16)
    }

    // MARK: - Holdings List
    @ViewBuilder
    private func holdingsListSection(_ portfolio: InvestorPortfolio) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AccentSectionTitle("\(L("All Holdings")) (\(portfolio.holdings.count))", icon: "list.bullet")
                .padding(.horizontal, 16)

            // Column headers
            HStack {
                Text(L("Company"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(L("Value"))
                    .frame(width: 80, alignment: .trailing)
                Text(L("Shares"))
                    .frame(width: 70, alignment: .trailing)
                Text("%")
                    .frame(width: 45, alignment: .trailing)
            }
            .font(AppTheme.caption(11))
            .foregroundColor(AppTheme.secondaryText)
            .padding(.horizontal, 30)

            // Holdings rows — card style
            VStack(spacing: 0) {
                ForEach(Array(portfolio.holdings.enumerated()), id: \.element.id) { idx, holding in
                    HStack {
                        Text(holding.name)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatValue(holding.value))
                            .font(AppTheme.number(12))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(width: 80, alignment: .trailing)
                        Text(formatShares(holding.shares))
                            .font(AppTheme.number(12))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 70, alignment: .trailing)
                        Text(String(format: "%.1f%%", holding.percentage))
                            .font(AppTheme.number(12))
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if idx < portfolio.holdings.count - 1 {
                        Divider()
                            .overlay(AppTheme.border.opacity(0.5))
                            .padding(.horizontal, 14)
                    }
                }
            }
            .themeCardSurface()
            .padding(.horizontal, isWide ? 0 : 16)
        }
    }

    // MARK: - Helpers
    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }

    private func formatShares(_ shares: Int) -> String {
        if shares >= 1_000_000 {
            return String(format: "%.1fM", Double(shares) / 1_000_000)
        } else if shares >= 1_000 {
            return String(format: "%.0fK", Double(shares) / 1_000)
        } else {
            return "\(shares)"
        }
    }

    private func loadPortfolio() async {
        isLoading = true
        errorMessage = nil
        do {
            let p = try await InvestorService.shared.fetchPortfolio(for: investor)
            await MainActor.run {
                portfolio = p
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
