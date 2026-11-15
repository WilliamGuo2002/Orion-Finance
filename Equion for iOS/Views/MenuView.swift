import SwiftUI

struct MenuView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var brokerage = BrokerageManager.shared
    @ObservedObject private var bank = BankManager.shared
    @ObservedObject private var aiConsent = AIConsent.shared
    @State private var showDisclaimer = false
    @State private var showAbout = false

    @State private var showAppearance = false
    @State private var showLanguage = false
    @State private var showInterests = false
    @State private var showRiskProfile = false
    @State private var showPortfolioWizard = false
    @State private var showStockCompare = false

    var body: some View {
        List {
            // Profile section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(AppTheme.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(firebaseController.currentUser?.email?.components(separatedBy: "@").first ?? "User")
                            .font(AppTheme.serifHeadline(18))
                            .foregroundColor(AppTheme.primaryText)
                        Text(firebaseController.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(AppTheme.cardBackground)
            }

            // Settings section
            Section(L("Settings")) {
                // Linked brokerages (SnapTrade, read-only)
                NavigationLink {
                    LinkedAccountsView()
                } label: {
                    let linkedCount = brokerage.connections.count + bank.currentItems.count
                    menuRow(icon: "building.columns", title: L("Linked Accounts"),
                            detail: linkedCount == 0 ? nil : "\(linkedCount)", accessory: .none)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Canadian registered accounts + superficial loss watch
                NavigationLink {
                    TaxCenterView()
                } label: {
                    menuRow(icon: "doc.text.magnifyingglass", title: L("Tax Assistant"), detail: nil, accessory: .none)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Display currency for portfolio amounts (USD default)
                Menu {
                    ForEach(SettingsManager.supportedCurrencies, id: \.self) { currency in
                        Button {
                            Task { await HoldingsManager.shared.setDisplayCurrency(currency) }
                        } label: {
                            if currency == settings.displayCurrency {
                                Label(currencyName(currency), systemImage: "checkmark")
                            } else {
                                Text(currencyName(currency))
                            }
                        }
                    }
                } label: {
                    menuRow(icon: "dollarsign.circle", title: L("Display Currency"), detail: settings.displayCurrency, accessory: .menu)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Appearance
                Button(action: { showAppearance = true }) {
                    menuRow(icon: "paintbrush", title: L("Appearance"), detail: appearanceLabel)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Notifications
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    menuRow(icon: "bell.badge", title: L("Notifications"),
                            detail: settings.notificationsEnabled ? L("On") : L("Off"), accessory: .none)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Language
                Button(action: { showLanguage = true }) {
                    menuRow(icon: "globe", title: L("Language"), detail: settings.appLanguage)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Interests
                Button(action: { showInterests = true }) {
                    menuRow(icon: "star.circle", title: L("My Interests"), detail: interestsDetail)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Risk Profile
                Button(action: { showRiskProfile = true }) {
                    menuRow(icon: "shield.checkered", title: L("Investment Style"), detail: riskProfileDetail)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Portfolio Builder
                Button(action: { showPortfolioWizard = true }) {
                    menuRow(icon: "sparkles", title: L("Portfolio Builder"), detail: nil)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Stock Compare
                Button(action: { showStockCompare = true }) {
                    menuRow(icon: "arrow.left.arrow.right", title: L("Compare Stocks"), detail: nil)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Paper Trading
                NavigationLink {
                    PaperTradingView()
                } label: {
                    menuRow(icon: "chart.line.uptrend.xyaxis", title: L("Paper Trading"), detail: String(format: "$%.0f", PaperPortfolioManager.shared.cash + PaperPortfolioManager.shared.holdings.reduce(0) { $0 + $1.cost }), accessory: .none)
                }
                .listRowBackground(AppTheme.cardBackground)

                // AI data sharing (Google Gemini) — consent can be withdrawn any time
                Toggle(isOn: Binding(
                    get: { aiConsent.granted },
                    set: { aiConsent.setGranted($0) }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("AI Data Sharing"))
                                .foregroundColor(AppTheme.primaryText)
                            Text(L("Send your AI questions to Google Gemini"))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .tint(AppTheme.accent)
                .listRowBackground(AppTheme.cardBackground)

                Button(action: { showDisclaimer = true }) {
                    menuRow(icon: "info.circle", title: L("Disclaimer"), detail: nil)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Rows without a destination were removed — a row with a chevron must go somewhere.
                Button(action: { showAbout = true }) {
                    menuRow(icon: "doc.text", title: L("About & Data Sources"))
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            // Logout
            Section {
                Button(action: logout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text(L("Log Out"))
                    }
                    .foregroundColor(AppTheme.warning)
                }
                .listRowBackground(AppTheme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .tracksTabBarCollapse()
        .sheet(isPresented: $showAppearance) {
            AppearanceSheet(selected: $settings.appearanceMode)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showLanguage) {
            LanguageSheet(selected: $settings.appLanguage)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showInterests) {
            NavigationStack {
                InterestsSelectionView(isOnboarding: false)
            }
        }
        .sheet(isPresented: $showRiskProfile) {
            NavigationStack {
                RiskProfileView(isOnboarding: false)
            }
        }
        .sheet(isPresented: $showPortfolioWizard) {
            PortfolioWizardView()
        }
        .sheet(isPresented: $showStockCompare) {
            StockCompareView()
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerSheet()
                .presentationDetents([.medium, .large])
        }
    }

    private var interestsDetail: String {
        let count = InterestsManager.shared.selectedInterests.count
        return count > 0 ? "\(count) \(L("selected"))" : L("Not set")
    }

    private var riskProfileDetail: String {
        switch settings.riskProfile {
        case "conservative": return L("Conservative")
        case "moderate":     return L("Moderate")
        case "aggressive":   return L("Aggressive")
        default:             return L("Not set")
        }
    }

    private var appearanceLabel: String {
        switch settings.appearanceMode {
        case "light": return L("Light")
        case "dark": return L("Dark")
        default: return L("System")
        }
    }

    enum RowAccessory { case none, chevron, menu }

    /// - accessory: `.none` inside NavigationLink (the list draws its own chevron), `.chevron` for
    ///   rows that open a sheet, `.menu` for pop-up menus.
    @ViewBuilder
    private func menuRow(icon: String, title: String, detail: String? = nil, accessory: RowAccessory = .chevron) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundColor(AppTheme.secondaryText)
                    .font(.subheadline)
            }
            switch accessory {
            case .none: EmptyView()
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.6))
            case .menu:
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.6))
            }
        }
        .contentShape(Rectangle())
    }

    private func currencyName(_ code: String) -> String {
        switch code {
        case "USD": return L("US Dollar") + " (USD)"
        case "CAD": return L("Canadian Dollar") + " (CAD)"
        default:    return code
        }
    }

    private func logout() {
        try? firebaseController.signOut()
    }
}

// MARK: - Disclaimer
struct DisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L("Orion Finance provides information and education only. It is not a registered investment adviser, dealer or tax professional, and nothing in the app is a recommendation to buy, sell or hold any security."))
                    Text(L("AI-generated content can be wrong or out of date. Market data may be delayed. Linked account data comes from your institutions through SnapTrade and Plaid and may not match your official statements."))
                    Text(L("Tax features are estimates to help you spot issues. Confirm your contribution room in CRA My Account and talk to a qualified professional before making decisions."))
                    Text(L("Orion only reads your accounts. It cannot trade, move money or change anything at your institutions."))
                }
                .font(.system(size: 14))
                .foregroundColor(AppTheme.primaryText)
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle(L("Disclaimer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Appearance Sheet
struct AppearanceSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let options = [
        ("system", "System", "iphone"),
        ("light", "Light", "sun.max"),
        ("dark", "Dark", "moon")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.0) { key, label, icon in
                    Button(action: { selected = key; dismiss() }) {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 24)
                            Text(L(label))
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if selected == key {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(L("Appearance"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Language Sheet
struct LanguageSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(SettingsManager.supportedLanguages, id: \.self) { lang in
                    Button(action: { selected = lang; dismiss() }) {
                        HStack {
                            Text(lang)
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if selected == lang {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(L("Language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - About & data sources
struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return b.isEmpty ? v : "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(L("Version"), value: version)
                }
                Section {
                    Text(L("Market data: Yahoo Finance and Finnhub. Prices may be delayed."))
                    Text(L("Brokerage accounts: SnapTrade (read-only)."))
                    Text(L("Bank accounts: Plaid (read-only)."))
                    Text(L("AI features: Google Gemini, only if you turn them on."))
                } header: {
                    Text(L("Data sources"))
                }
                Section {
                    Text("© \(Calendar.current.component(.year, from: Date())) Orion Finance")
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .font(.subheadline)
            .navigationTitle(L("About & Data Sources"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(L("Done")) { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
