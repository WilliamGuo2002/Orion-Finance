import SwiftUI

// MARK: - Stock Compare View
struct StockCompareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbolA = ""
    @State private var symbolB = ""
    @State private var nameA = ""
    @State private var nameB = ""
    @State private var pickingSide: PickSide? = nil

    // Data
    @State private var quoteA: StockQuote?
    @State private var quoteB: StockQuote?
    @State private var metricsA: FundamentalMetrics?
    @State private var metricsB: FundamentalMetrics?
    @State private var aiVerdict = ""
    @State private var isLoading = false
    @State private var isLoadingAI = false
    @State private var dataLoaded = false

    enum PickSide { case a, b }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stock pickers
                    stockPickerRow

                    if dataLoaded {
                        // Price comparison
                        if let qA = quoteA, let qB = quoteB {
                            priceCompareCard(qA, qB)
                        }

                        // Fundamentals comparison
                        if metricsA != nil || metricsB != nil {
                            fundamentalsCompareCard
                        }

                        // AI verdict
                        aiVerdictCard
                    } else if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(AppTheme.accent)
                            Text(L("Loading data..."))
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        emptyPrompt
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle(L("Compare Stocks"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Close")) { dismiss() }
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .sheet(item: $pickingSide) { side in
                StockPickerSheet(onSelect: { symbol, name in
                    if side == .a {
                        symbolA = symbol; nameA = name
                    } else {
                        symbolB = symbol; nameB = name
                    }
                    pickingSide = nil
                    if !symbolA.isEmpty && !symbolB.isEmpty {
                        loadComparison()
                    }
                })
            }
        }
    }

    // MARK: - Stock Picker Row

    private var stockPickerRow: some View {
        HStack(spacing: 12) {
            stockPickerButton(symbol: symbolA, name: nameA, placeholder: L("Stock A"), side: .a)

            ZStack {
                Circle()
                    .fill(AppTheme.subtleFill)
                    .frame(width: 36, height: 36)
                Text("VS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(AppTheme.secondaryText)
            }

            stockPickerButton(symbol: symbolB, name: nameB, placeholder: L("Stock B"), side: .b)
        }
    }

    private func stockPickerButton(symbol: String, name: String, placeholder: String, side: PickSide) -> some View {
        Button {
            Haptic.light()
            pickingSide = side
        } label: {
            VStack(spacing: 4) {
                if symbol.isEmpty {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.accent.opacity(0.5))
                    Text(placeholder)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)
                } else {
                    Text(symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(name)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(symbol.isEmpty ? AppTheme.border : AppTheme.accent, lineWidth: symbol.isEmpty ? 0.5 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Price Compare

    private func priceCompareCard(_ qA: StockQuote, _ qB: StockQuote) -> some View {
        VStack(spacing: 12) {
            AccentSectionTitle(L("Price"), icon: "dollarsign.circle")

            HStack(spacing: 0) {
                priceColumn(symbol: symbolA, price: qA.price, change: qA.changePercent)
                Divider().frame(height: 60)
                priceColumn(symbol: symbolB, price: qB.price, change: qB.changePercent)
            }
        }
        .padding(16)
        .themeCardSurface()
    }

    private func priceColumn(symbol: String, price: Double, change: Double) -> some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            Text(String(format: "$%.2f", price))
                .font(AppTheme.number(20, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            Text(String(format: "%@%.2f%%", change >= 0 ? "+" : "", change))
                .font(AppTheme.number(13, weight: .semibold))
                .foregroundColor(change >= 0 ? AppTheme.positive : AppTheme.negative)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fundamentals Compare

    private var fundamentalsCompareCard: some View {
        VStack(spacing: 12) {
            AccentSectionTitle(L("Fundamentals"), icon: "chart.bar.xaxis")

            let rows: [(String, (FundamentalMetrics?) -> String?)] = [
                ("P/E", { m in m?.peRatio.map { String(format: "%.1f", $0) } }),
                ("P/B", { m in m?.pbRatio.map { String(format: "%.1f", $0) } }),
                ("EPS Growth", { m in m?.epsGrowth.map { String(format: "%.1f%%", $0) } }),
                ("ROE", { m in m?.roe.map { String(format: "%.1f%%", $0) } }),
                ("Div Yield", { m in m?.dividendYield.map { String(format: "%.2f%%", $0) } }),
                ("Beta", { m in m?.beta.map { String(format: "%.2f", $0) } }),
                ("D/E", { m in m?.debtToEquity.map { String(format: "%.1f", $0) } }),
            ]

            ForEach(rows.indices, id: \.self) { i in
                let row = rows[i]
                let valA = row.1(metricsA)
                let valB = row.1(metricsB)
                if valA != nil || valB != nil {
                    HStack {
                        Text(valA ?? "—")
                            .font(AppTheme.number(14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                        Text(L(row.0))
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 80)
                        Text(valB ?? "—")
                            .font(AppTheme.number(14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                    if i < rows.count - 1 {
                        Divider().overlay(AppTheme.border.opacity(0.3))
                    }
                }
            }

            // Column headers
            HStack {
                Text(symbolA)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: 80)
                Text(symbolB)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .themeCardSurface()
    }

    // MARK: - AI Verdict

    private var aiVerdictCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.accent)
                Text(L("AI Verdict"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.accent)
            }

            if isLoadingAI {
                HStack(spacing: 10) {
                    ProgressView().tint(AppTheme.accent)
                    Text(L("Analyzing..."))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
            } else if !aiVerdict.isEmpty {
                Text(aiVerdict)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCardSurface()
    }

    // MARK: - Empty Prompt

    private var emptyPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(AppTheme.accent.opacity(0.4))
                .padding(.top, 40)

            Text(L("Pick two stocks to compare"))
                .font(AppTheme.serifHeadline(18))
                .foregroundColor(AppTheme.primaryText)

            Text(L("Get a side-by-side comparison with an AI recommendation"))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Data Loading

    private func loadComparison() {
        isLoading = true
        dataLoaded = false
        aiVerdict = ""
        Task {
            async let qA = try? APIService.shared.fetchFullQuote(symbol: symbolA)
            async let qB = try? APIService.shared.fetchFullQuote(symbol: symbolB)
            async let mA = try? APIService.shared.fetchFundamentalMetrics(symbol: symbolA)
            async let mB = try? APIService.shared.fetchFundamentalMetrics(symbol: symbolB)

            let (rQA, rQB, rMA, rMB) = await (qA, qB, mA, mB)

            await MainActor.run {
                quoteA = rQA
                quoteB = rQB
                metricsA = rMA
                metricsB = rMB
                isLoading = false
                dataLoaded = true
            }

            // Generate AI verdict
            await MainActor.run { isLoadingAI = true }
            await generateAIVerdict()
        }
    }

    private func generateAIVerdict() async {
        let lang = SettingsManager.shared.appLanguage
        let riskProfile = SettingsManager.shared.riskProfile.isEmpty ? "moderate" : SettingsManager.shared.riskProfile

        var context = "\(nameA) (\(symbolA)) vs \(nameB) (\(symbolB))\n"
        if let qA = quoteA { context += "\(symbolA): $\(String(format: "%.2f", qA.price)), change: \(String(format: "%.2f%%", qA.changePercent))\n" }
        if let qB = quoteB { context += "\(symbolB): $\(String(format: "%.2f", qB.price)), change: \(String(format: "%.2f%%", qB.changePercent))\n" }
        if let mA = metricsA { context += "\(symbolA) P/E: \(mA.peRatio.map { String(format: "%.1f", $0) } ?? "N/A"), ROE: \(mA.roe.map { String(format: "%.1f%%", $0) } ?? "N/A")\n" }
        if let mB = metricsB { context += "\(symbolB) P/E: \(mB.peRatio.map { String(format: "%.1f", $0) } ?? "N/A"), ROE: \(mB.roe.map { String(format: "%.1f%%", $0) } ?? "N/A")\n" }

        let prompt = """
        Compare these two stocks for a beginner investor (risk profile: \(riskProfile)):

        \(context)

        Write a clear, concise comparison (3-4 sentences max) in plain language for someone who knows nothing about investing.
        - State which one you'd recommend and why in ONE clear sentence
        - Mention one key difference between them that matters for beginners
        - End with a specific, actionable suggestion
        - No jargon, no technical terms
        - Respond in \(lang)
        """

        do {
            let result = try await APIService.shared.sendGeminiMessage(text: prompt, language: lang)
            await MainActor.run {
                aiVerdict = result
                isLoadingAI = false
            }
        } catch {
            await MainActor.run {
                aiVerdict = L("Unable to generate comparison. Please try again.")
                isLoadingAI = false
            }
        }
    }
}

// MARK: - PickSide Identifiable
extension StockCompareView.PickSide: Identifiable {
    var id: String {
        switch self {
        case .a: return "a"
        case .b: return "b"
        }
    }
}

// MARK: - Stock Picker Sheet (simple list)
struct StockPickerSheet: View {
    let onSelect: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [AssetMeta] {
        let all = AssetMeta.popularStocks
        if searchText.isEmpty { return all }
        let q = searchText.lowercased()
        return all.filter { $0.symbol.lowercased().contains(q) || $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.secondaryText)
                    TextField(L("Search stocks..."), text: $searchText)
                        .autocapitalization(.allCharacters)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(AppTheme.subtleFill)
                .cornerRadius(12)
                .padding(16)

                // Manual entry
                if !searchText.isEmpty {
                    let sym = searchText.trimmingCharacters(in: .whitespaces).uppercased()
                    if !sym.isEmpty {
                        Button {
                            onSelect(sym, sym)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").foregroundColor(AppTheme.accent)
                                Text("\(L("Select")) \"\(sym)\"")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                            }
                            .padding(12)
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // List
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filtered, id: \.symbol) { asset in
                            Button {
                                onSelect(asset.symbol, asset.name)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(asset.symbol)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(asset.name)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 20)
                        }
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle(L("Select Stock"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }
}
