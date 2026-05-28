import SwiftUI

// MARK: - Portfolio Wizard
// "Help me pick stocks" — a step-by-step wizard that generates an AI portfolio recommendation
struct PortfolioWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = SettingsManager.shared

    // Steps
    @State private var currentStep = 0
    @State private var budget: String = ""
    @State private var horizon: String = ""       // "short", "mid", "long"
    @State private var goal: String = ""          // "safety", "growth", "income", "aggressive"

    // Result
    @State private var isLoading = false
    @State private var resultText = ""
    @State private var recommendations: [PortfolioItem] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentStep ? AppTheme.accent : AppTheme.subtleFill)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                if currentStep == 0 {
                    budgetStep
                } else if currentStep == 1 {
                    horizonStep
                } else if currentStep == 2 {
                    goalStep
                } else {
                    resultStep
                }
            }
            .background(AppTheme.background)
            .navigationTitle(L("Portfolio Builder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Close")) { dismiss() }
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }

    // MARK: - Step 1: Budget

    private var budgetStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(AppTheme.accent)
            }

            Text(L("How much do you want to invest?"))
                .font(AppTheme.serifTitle(24))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(L("Enter an approximate budget in USD"))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)

            HStack {
                Text("$")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                TextField("1,000", text: $budget)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 60)

            // Quick select
            HStack(spacing: 12) {
                quickBudgetButton("$500", value: "500")
                quickBudgetButton("$1,000", value: "1000")
                quickBudgetButton("$5,000", value: "5000")
                quickBudgetButton("$10,000", value: "10000")
            }
            .padding(.horizontal, 20)

            Spacer()

            nextButton(enabled: !budget.isEmpty) {
                currentStep = 1
            }
        }
    }

    private func quickBudgetButton(_ label: String, value: String) -> some View {
        Button {
            Haptic.light()
            budget = value
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(budget == value ? .white : AppTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(budget == value ? AppTheme.accent : AppTheme.accent.opacity(0.1))
                )
        }
    }

    // MARK: - Step 2: Time Horizon

    private var horizonStep: some View {
        stepLayout(
            icon: "calendar",
            question: "How long will you hold these investments?",
            options: [
                ("short", "Less than 1 year", "⏱️", "Short-term trading"),
                ("mid", "1 to 3 years", "📅", "Medium-term growth"),
                ("long", "3+ years", "🏔️", "Long-term wealth building"),
            ],
            selection: $horizon,
            nextStep: 2
        )
    }

    // MARK: - Step 3: Goal

    private var goalStep: some View {
        stepLayout(
            icon: "target",
            question: "What's your primary goal?",
            options: [
                ("safety", "Safety first — protect my money", "🛡️", "Low-risk, stable investments"),
                ("growth", "Balanced growth", "🌱", "Mix of growth and stability"),
                ("income", "Passive income from dividends", "💰", "Regular dividend payments"),
                ("aggressive", "Maximum growth potential", "🚀", "High-risk, high-reward picks"),
            ],
            selection: $goal,
            nextStep: 3
        )
    }

    // MARK: - Step Layout Helper

    private func stepLayout(icon: String, question: String, options: [(id: String, label: String, emoji: String, desc: String)], selection: Binding<String>, nextStep: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accent)
                Text(L(question))
                    .font(AppTheme.serifHeadline(20))
                    .foregroundColor(AppTheme.primaryText)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(options, id: \.id) { option in
                    let isSelected = selection.wrappedValue == option.id
                    Button {
                        Haptic.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection.wrappedValue = option.id
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(option.emoji)
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L(option.label))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(L(option.desc))
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                                .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 2 : 0.5)
                        )
                        .scaleEffect(isSelected ? 1.01 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    Haptic.light()
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L("Back"))
                    }
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(Capsule().fill(AppTheme.subtleFill))
                }

                Spacer()

                nextButton(enabled: !selection.wrappedValue.isEmpty) {
                    if nextStep == 3 {
                        generatePortfolio()
                    }
                    currentStep = nextStep
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 4: Result

    private var resultStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.accent)
                        Text(L("Orion is building your portfolio..."))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    // Summary header
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.accent)
                        Text(L("Your Recommended Portfolio"))
                            .font(AppTheme.serifHeadline(20))
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .padding(.top, 8)

                    Text(String(format: L("Budget: $%@  •  Horizon: %@  •  Goal: %@"),
                                budget,
                                L(horizonLabel),
                                L(goalLabel)))
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)

                    // Portfolio items
                    if !recommendations.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(recommendations) { item in
                                portfolioItemCard(item)
                            }
                        }
                    }

                    // AI explanation
                    if !resultText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.accent)
                                Text(L("Why this allocation?"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.accent)
                            }
                            Text(resultText)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(4)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.accent.opacity(0.06))
                        )
                    }

                    // Disclaimer
                    Text(L("This is AI-generated advice for educational purposes only. Always do your own research before investing."))
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.top, 8)

                    // Redo button
                    Button {
                        Haptic.light()
                        withAnimation {
                            currentStep = 0
                            budget = ""
                            horizon = ""
                            goal = ""
                            recommendations = []
                            resultText = ""
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(L("Start Over"))
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accent, lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
    }

    private func portfolioItemCard(_ item: PortfolioItem) -> some View {
        HStack(spacing: 12) {
            // Percentage circle
            ZStack {
                Circle()
                    .stroke(AppTheme.subtleFill, lineWidth: 3)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: CGFloat(item.percentage) / 100)
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                Text("\(item.percentage)%")
                    .font(AppTheme.number(11, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(item.name)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                Text(item.reason)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            if let amount = item.amount {
                Text(String(format: "$%.0f", amount))
                    .font(AppTheme.number(14, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
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

    // MARK: - Helpers

    private var horizonLabel: String {
        switch horizon {
        case "short": return "Short-term"
        case "mid":   return "1-3 years"
        case "long":  return "3+ years"
        default:      return ""
        }
    }

    private var goalLabel: String {
        switch goal {
        case "safety":     return "Safety"
        case "growth":     return "Balanced growth"
        case "income":     return "Dividends"
        case "aggressive": return "Aggressive growth"
        default:           return ""
        }
    }

    private func nextButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptic.light()
            withAnimation(.easeInOut(duration: 0.3)) { action() }
        } label: {
            HStack(spacing: 4) {
                Text(L("Next"))
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Capsule().fill(enabled ? AppTheme.accent : AppTheme.secondaryText.opacity(0.3)))
            .shadow(color: enabled ? AppTheme.accent.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(!enabled)
        .padding(.bottom, 24)
    }

    // MARK: - AI Generation

    private func generatePortfolio() {
        isLoading = true
        Task {
            do {
                let budgetNum = Double(budget.replacingOccurrences(of: ",", with: "")) ?? 1000
                let riskProfile = settings.riskProfile.isEmpty ? "moderate" : settings.riskProfile
                let lang = settings.appLanguage

                let prompt = """
                You are a portfolio advisor for a beginner investor. Build a diversified portfolio.

                User profile:
                - Budget: $\(Int(budgetNum))
                - Time horizon: \(horizonLabel)
                - Goal: \(goalLabel)
                - Risk profile: \(riskProfile)

                Return ONLY valid JSON (no markdown, no code fences):
                {
                  "items": [
                    {
                      "symbol": "TICKER",
                      "name": "Company or ETF Name",
                      "percentage": 30,
                      "amount": 300.0,
                      "reason": "Short reason why"
                    }
                  ],
                  "explanation": "2-3 sentence overall explanation of why this allocation makes sense"
                }

                Rules:
                - Include 3-6 items that add up to 100%
                - Use real, well-known tickers (prefer ETFs for beginners with small budgets)
                - amount = budget × percentage / 100
                - reason should be 1 sentence, in plain language, no jargon
                - explanation should be in plain language for a complete beginner
                - All text (reason, explanation) in \(lang)
                - For conservative/small budgets, prefer ETFs (VOO, QQQ, SCHD) over individual stocks
                - ONLY return the JSON object
                """

                let response = try await APIService.shared.sendGeminiMessage(text: prompt, language: lang)
                let cleaned = response
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let data = cleaned.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    let items = json["items"] as? [[String: Any]] ?? []
                    let explanation = json["explanation"] as? String ?? ""

                    let parsed = items.compactMap { item -> PortfolioItem? in
                        guard let symbol = item["symbol"] as? String,
                              let name = item["name"] as? String,
                              let pct = item["percentage"] as? Int else { return nil }
                        return PortfolioItem(
                            symbol: symbol,
                            name: name,
                            percentage: pct,
                            amount: item["amount"] as? Double,
                            reason: item["reason"] as? String ?? ""
                        )
                    }

                    await MainActor.run {
                        recommendations = parsed
                        resultText = explanation
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        resultText = response
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    resultText = L("Unable to generate recommendations. Please try again.")
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Portfolio Item Model
struct PortfolioItem: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let percentage: Int
    let amount: Double?
    let reason: String
}
