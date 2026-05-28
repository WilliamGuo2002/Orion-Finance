import SwiftUI

// MARK: - Paper Trading Models

struct PaperTrade: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    let shares: Double
    let buyPrice: Double
    let buyDate: Date

    var cost: Double { shares * buyPrice }

    init(symbol: String, name: String, shares: Double, buyPrice: Double, buyDate: Date = Date()) {
        self.id = UUID().uuidString
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.buyPrice = buyPrice
        self.buyDate = buyDate
    }
}

// MARK: - Paper Portfolio Manager

class PaperPortfolioManager: ObservableObject {
    static let shared = PaperPortfolioManager()

    @Published var cash: Double {
        didSet { save() }
    }
    @Published var holdings: [PaperTrade] {
        didSet { save() }
    }
    @Published var tradeHistory: [PaperTradeRecord] {
        didSet { save() }
    }

    static let initialCash: Double = 10000

    private init() {
        let defaults = UserDefaults.standard
        self.cash = defaults.object(forKey: "paper_cash") as? Double ?? Self.initialCash
        if let data = defaults.data(forKey: "paper_holdings"),
           let decoded = try? JSONDecoder().decode([PaperTrade].self, from: data) {
            self.holdings = decoded
        } else {
            self.holdings = []
        }
        if let data = defaults.data(forKey: "paper_history"),
           let decoded = try? JSONDecoder().decode([PaperTradeRecord].self, from: data) {
            self.tradeHistory = decoded
        } else {
            self.tradeHistory = []
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(cash, forKey: "paper_cash")
        if let data = try? JSONEncoder().encode(holdings) {
            defaults.set(data, forKey: "paper_holdings")
        }
        if let data = try? JSONEncoder().encode(tradeHistory) {
            defaults.set(data, forKey: "paper_history")
        }
    }

    func buy(symbol: String, name: String, shares: Double, price: Double) {
        let cost = shares * price
        guard cost <= cash else { return }
        cash -= cost

        // Merge with existing holding for same symbol
        if let idx = holdings.firstIndex(where: { $0.symbol == symbol }) {
            let existing = holdings[idx]
            let totalShares = existing.shares + shares
            let avgPrice = (existing.cost + cost) / totalShares
            holdings[idx] = PaperTrade(symbol: symbol, name: name, shares: totalShares, buyPrice: avgPrice, buyDate: existing.buyDate)
        } else {
            holdings.append(PaperTrade(symbol: symbol, name: name, shares: shares, buyPrice: price))
        }

        tradeHistory.insert(PaperTradeRecord(symbol: symbol, action: "buy", shares: shares, price: price, date: Date()), at: 0)
    }

    func sell(symbol: String, shares: Double, price: Double) {
        guard let idx = holdings.firstIndex(where: { $0.symbol == symbol }) else { return }
        let holding = holdings[idx]
        let sellShares = min(shares, holding.shares)
        cash += sellShares * price

        tradeHistory.insert(PaperTradeRecord(symbol: symbol, action: "sell", shares: sellShares, price: price, date: Date()), at: 0)

        let remaining = holding.shares - sellShares
        if remaining <= 0.0001 {
            holdings.remove(at: idx)
        } else {
            holdings[idx] = PaperTrade(symbol: symbol, name: holding.name, shares: remaining, buyPrice: holding.buyPrice, buyDate: holding.buyDate)
        }
    }

    func reset() {
        cash = Self.initialCash
        holdings.removeAll()
        tradeHistory.removeAll()
    }
}

struct PaperTradeRecord: Identifiable, Codable {
    let id: String
    let symbol: String
    let action: String  // "buy" or "sell"
    let shares: Double
    let price: Double
    let date: Date

    init(symbol: String, action: String, shares: Double, price: Double, date: Date) {
        self.id = UUID().uuidString
        self.symbol = symbol
        self.action = action
        self.shares = shares
        self.price = price
        self.date = date
    }
}

// MARK: - Paper Trading View

struct PaperTradingView: View {
    @ObservedObject private var portfolio = PaperPortfolioManager.shared
    @State private var currentPrices: [String: Double] = [:]
    @State private var isLoading = true
    @State private var showBuySheet = false
    @State private var showResetAlert = false

    private var totalValue: Double {
        let holdingsValue = portfolio.holdings.reduce(0.0) { sum, h in
            sum + h.shares * (currentPrices[h.symbol] ?? h.buyPrice)
        }
        return portfolio.cash + holdingsValue
    }

    private var totalPnL: Double {
        totalValue - PaperPortfolioManager.initialCash
    }

    private var totalPnLPercent: Double {
        totalPnL / PaperPortfolioManager.initialCash * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Portfolio summary card
                summaryCard

                // Holdings
                if !portfolio.holdings.isEmpty {
                    holdingsSection
                }

                // Trade history
                if !portfolio.tradeHistory.isEmpty {
                    historySection
                }

                // Empty state
                if portfolio.holdings.isEmpty && portfolio.tradeHistory.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(AppTheme.background)
        .navigationTitle(L("Paper Trading"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showBuySheet = true }) {
                        Label(L("Buy Stock"), systemImage: "plus.circle")
                    }
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        Label(L("Reset Portfolio"), systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showBuySheet) {
            PaperTradeSheet(mode: .buy, onTrade: { symbol, name, shares, price in
                portfolio.buy(symbol: symbol, name: name, shares: shares, price: price)
                Task { await refreshPrices() }
            })
        }
        .alert(L("Reset Portfolio"), isPresented: $showResetAlert) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Reset"), role: .destructive) {
                portfolio.reset()
                currentPrices.removeAll()
            }
        } message: {
            Text(L("This will reset your virtual portfolio to $10,000 and clear all trades."))
        }
        .task {
            await refreshPrices()
            isLoading = false
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Total Value"))
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(String(format: "$%.2f", totalValue))
                        .font(AppTheme.number(28, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("P&L"))
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(String(format: "%@$%.2f (%.1f%%)",
                                totalPnL >= 0 ? "+" : "",
                                totalPnL,
                                totalPnLPercent))
                        .font(AppTheme.number(16, weight: .bold))
                        .foregroundColor(totalPnL >= 0 ? AppTheme.positive : AppTheme.negative)
                }
            }

            Divider().overlay(AppTheme.border.opacity(0.4))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Cash"))
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(String(format: "$%.2f", portfolio.cash))
                        .font(AppTheme.number(15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L("Invested"))
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(String(format: "$%.2f", totalValue - portfolio.cash))
                        .font(AppTheme.number(15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
            }

            // Buy button
            Button(action: { showBuySheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(L("Buy Stock"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Capsule().fill(AppTheme.accent))
            }
        }
        .padding(16)
        .themeCardSurface()
    }

    // MARK: - Holdings

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AccentSectionTitle(L("Holdings"), icon: "briefcase")
                .padding(.horizontal, 4)

            ForEach(portfolio.holdings) { holding in
                holdingRow(holding)
            }
        }
    }

    private func holdingRow(_ holding: PaperTrade) -> some View {
        let currentPrice = currentPrices[holding.symbol] ?? holding.buyPrice
        let marketValue = holding.shares * currentPrice
        let pnl = (currentPrice - holding.buyPrice) * holding.shares
        let pnlPct = (currentPrice - holding.buyPrice) / holding.buyPrice * 100

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                Text(holding.name)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
                Text(String(format: "%.2f %@ × $%.2f", holding.shares, L("shares"), holding.buyPrice))
                    .font(AppTheme.number(11, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", marketValue))
                    .font(AppTheme.number(15, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(String(format: "%@$%.2f (%.1f%%)", pnl >= 0 ? "+" : "", pnl, pnlPct))
                    .font(AppTheme.number(12, weight: .medium))
                    .foregroundColor(pnl >= 0 ? AppTheme.positive : AppTheme.negative)
            }

            // Sell button
            Button {
                Haptic.light()
                portfolio.sell(symbol: holding.symbol, shares: holding.shares, price: currentPrice)
            } label: {
                Text(L("Sell"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.negative)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().stroke(AppTheme.negative, lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AccentSectionTitle(L("Trade History"), icon: "clock.arrow.circlepath")
                .padding(.horizontal, 4)

            ForEach(portfolio.tradeHistory.prefix(20)) { record in
                HStack(spacing: 10) {
                    Image(systemName: record.action == "buy" ? "arrow.down.left" : "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(record.action == "buy" ? AppTheme.positive : AppTheme.negative)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(
                                (record.action == "buy" ? AppTheme.positive : AppTheme.negative).opacity(0.1)
                            )
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(record.action == "buy" ? L("Bought") : L("Sold")) \(record.symbol)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                        Text(record.date, style: .date)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(String(format: "$%.2f", record.shares * record.price))
                            .font(AppTheme.number(13, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text(String(format: "%.2f × $%.2f", record.shares, record.price))
                            .font(AppTheme.number(11, weight: .regular))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppTheme.accent.opacity(0.4))
                .padding(.top, 40)

            Text(L("Start your practice portfolio"))
                .font(AppTheme.serifHeadline(18))
                .foregroundColor(AppTheme.primaryText)

            Text(L("You have $10,000 in virtual cash. Practice buying and selling stocks risk-free!"))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: { showBuySheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(L("Buy Your First Stock"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(AppTheme.accent))
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
            }
        }
    }

    // MARK: - Data Loading

    private func refreshPrices() async {
        let symbols = portfolio.holdings.map(\.symbol)
        guard !symbols.isEmpty else { return }
        await withTaskGroup(of: (String, Double)?.self) { group in
            for symbol in symbols {
                group.addTask {
                    guard let (price, _) = try? await APIService.shared.fetchStockQuote(symbol: symbol) else { return nil }
                    return (symbol, price)
                }
            }
            for await result in group {
                if let (symbol, price) = result {
                    await MainActor.run {
                        currentPrices[symbol] = price
                    }
                }
            }
        }
    }
}

// MARK: - Paper Trade Sheet (Buy)

struct PaperTradeSheet: View {
    enum Mode { case buy, sell }
    let mode: Mode
    let onTrade: (String, String, Double, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedSymbol = ""
    @State private var selectedName = ""
    @State private var currentPrice: Double = 0
    @State private var sharesText = ""
    @State private var isLoadingPrice = false

    private var shares: Double { Double(sharesText) ?? 0 }
    private var total: Double { shares * currentPrice }
    private var canTrade: Bool { shares > 0 && currentPrice > 0 && !selectedSymbol.isEmpty }

    private var filteredAssets: [AssetMeta] {
        let all = AssetMeta.popularStocks
        if searchText.isEmpty { return all }
        let q = searchText.lowercased()
        return all.filter { $0.symbol.lowercased().contains(q) || $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if selectedSymbol.isEmpty {
                    searchSection
                } else {
                    tradeForm
                }
            }
            .padding(20)
            .background(AppTheme.background)
            .navigationTitle(mode == .buy ? L("Buy Stock") : L("Sell Stock"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.secondaryText)
                TextField(L("Search stocks..."), text: $searchText)
                    .foregroundColor(AppTheme.primaryText)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.subtleFill)
            )

            // Manual entry
            if !searchText.isEmpty {
                let sym = searchText.trimmingCharacters(in: .whitespaces).uppercased()
                if !sym.isEmpty && !filteredAssets.contains(where: { $0.symbol == sym }) {
                    Button {
                        Haptic.light()
                        selectedSymbol = sym
                        selectedName = sym
                        loadPrice()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.accent)
                            Text(L("Buy") + " \"\(sym)\"")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredAssets, id: \.symbol) { asset in
                        Button {
                            Haptic.light()
                            selectedSymbol = asset.symbol
                            selectedName = asset.name
                            loadPrice()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(asset.symbol)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AppTheme.primaryText)
                                    Text(asset.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }

    private var tradeForm: some View {
        VStack(spacing: 20) {
            // Selected stock
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedSymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(selectedName)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
                if isLoadingPrice {
                    ProgressView()
                } else {
                    Text(String(format: "$%.2f", currentPrice))
                        .font(AppTheme.number(20, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                }
            }

            Button {
                selectedSymbol = ""
                selectedName = ""
                searchText = ""
            } label: {
                Text(L("Change stock"))
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.accent)
            }

            // Shares input
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Number of shares"))
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
                TextField("0", text: $sharesText)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                    .keyboardType(.decimalPad)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.subtleFill)
                    )
            }

            // Total
            if shares > 0 {
                HStack {
                    Text(L("Total"))
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Text(String(format: "$%.2f", total))
                        .font(AppTheme.number(18, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                }

                HStack {
                    Text(L("Cash available"))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Text(String(format: "$%.2f", PaperPortfolioManager.shared.cash))
                        .font(AppTheme.number(12, weight: .medium))
                        .foregroundColor(total > PaperPortfolioManager.shared.cash ? AppTheme.negative : AppTheme.secondaryText)
                }
            }

            Spacer()

            // Trade button
            Button {
                Haptic.success()
                onTrade(selectedSymbol, selectedName, shares, currentPrice)
                dismiss()
            } label: {
                Text(String(format: "%@ %@ %@",
                             mode == .buy ? L("Buy") : L("Sell"),
                             sharesText.isEmpty ? "" : sharesText,
                             selectedSymbol))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(canTrade && total <= PaperPortfolioManager.shared.cash ? AppTheme.accent : AppTheme.secondaryText.opacity(0.3))
                    )
            }
            .disabled(!canTrade || total > PaperPortfolioManager.shared.cash)
        }
    }

    private func loadPrice() {
        isLoadingPrice = true
        Task {
            if let (price, _) = try? await APIService.shared.fetchStockQuote(symbol: selectedSymbol) {
                await MainActor.run {
                    currentPrice = price
                    isLoadingPrice = false
                }
            }
        }
    }
}

