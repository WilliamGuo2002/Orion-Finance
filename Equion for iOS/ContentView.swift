import SwiftUI

struct ContentView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var interests = InterestsManager.shared
    @State private var showOnboarding = false
    @State private var showRiskProfile = false
    @State private var checkingNewUser = true

    var body: some View {
        Group {
            if firebaseController.isLoggedIn {
                if showRiskProfile {
                    NavigationStack {
                        RiskProfileView(isOnboarding: true, onComplete: {
                            withAnimation {
                                showRiskProfile = false
                            }
                        })
                    }
                    .transition(.move(edge: .trailing))
                } else if showOnboarding {
                    NavigationStack {
                        InterestsSelectionView(isOnboarding: true, onComplete: {
                            withAnimation {
                                showOnboarding = false
                                showRiskProfile = true
                            }
                        })
                    }
                    .transition(.move(edge: .trailing))
                } else if checkingNewUser {
                    // Brief loading while we check onboarding status
                    ZStack {
                        AppTheme.background.ignoresSafeArea()
                        ProgressView()
                    }
                } else {
                    MainTabView()
                        .environmentObject(firebaseController)
                }
            } else {
                LoginView()
                    .environmentObject(firebaseController)
            }
        }
        .preferredColorScheme(settings.colorScheme)
        .onChange(of: firebaseController.isLoggedIn) { _, loggedIn in
            if loggedIn {
                checkOnboardingStatus()
            } else {
                showOnboarding = false
                checkingNewUser = true
            }
        }
        .onAppear {
            if firebaseController.isLoggedIn {
                checkOnboardingStatus()
            } else {
                checkingNewUser = false
            }
        }
    }

    private func checkOnboardingStatus() {
        // Already completed locally — skip
        if interests.hasCompletedOnboarding {
            checkingNewUser = false
            showOnboarding = false
            return
        }
        // Check Firestore
        Task {
            await interests.loadFromFirestore()
            await MainActor.run {
                if interests.hasCompletedOnboarding {
                    checkingNewUser = false
                    showOnboarding = false
                } else {
                    checkingNewUser = false
                    showOnboarding = true
                }
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct MainTabView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @State private var selectedTab: AppTab? = .holdings

    /// True on iPad OR iPhone landscape
    private var isWide: Bool { hSize == .regular || vSize == .compact }

    enum AppTab: String, CaseIterable {
        case holdings, news, gurus, more, orion

        var icon: String {
            switch self {
            case .holdings: return "house"
            case .news:     return "newspaper"
            case .gurus:    return "person.2"
            case .more:     return "line.3.horizontal"
            case .orion:    return "sparkles"
            }
        }
        var activeIcon: String {
            switch self {
            case .holdings: return "house.fill"
            case .news:     return "newspaper.fill"
            case .gurus:    return "person.2.fill"
            case .more:     return "line.3.horizontal"
            case .orion:    return "sparkles"
            }
        }
        func label() -> String {
            switch self {
            case .holdings: return L("My Holdings")
            case .news:     return L("News")
            case .gurus:    return L("Gurus")
            case .more:     return L("More")
            case .orion:    return "Orion"
            }
        }
    }

    var body: some View {
        Group {
            if hSize == .regular {
                // iPad / wide screen: sidebar navigation
                iPadLayout
            } else {
                // iPhone: custom tab bar
                phoneLayout
            }
        }
        .id(settings.appLanguage)
    }

    // MARK: - iPad Sidebar Layout
    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            List(selection: $selectedTab) {
                Label(AppTab.holdings.label(), systemImage: selectedTab == .holdings ? AppTab.holdings.activeIcon : AppTab.holdings.icon)
                    .tag(AppTab.holdings)
                Label(AppTab.news.label(), systemImage: selectedTab == .news ? AppTab.news.activeIcon : AppTab.news.icon)
                    .tag(AppTab.news)
                Label(AppTab.gurus.label(), systemImage: selectedTab == .gurus ? AppTab.gurus.activeIcon : AppTab.gurus.icon)
                    .tag(AppTab.gurus)

                Section {
                    Label(AppTab.orion.label(), systemImage: AppTab.orion.icon)
                        .tag(AppTab.orion)
                }

                Section {
                    Label(AppTab.more.label(), systemImage: AppTab.more.icon)
                        .tag(AppTab.more)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Orion Finance")
            .tint(AppTheme.accent)
        } detail: {
            NavigationStack {
                detailView(for: selectedTab ?? .holdings)
            }
        }
        .tint(AppTheme.accent)
    }

    @ViewBuilder
    private func detailView(for tab: AppTab) -> some View {
        switch tab {
        case .holdings: MyHoldingView()
        case .news:     NewsView()
        case .gurus:    InvestorsView()
        case .more:     MenuView().environmentObject(firebaseController)
        case .orion:    ChatView()
        }
    }

    // MARK: - iPhone Tab Bar Layout
    private var phoneLayout: some View {
        Group {
            if vSize == .compact {
                // iPhone landscape: side rail + content
                landscapePhoneLayout
            } else {
                // iPhone portrait: bottom tab bar
                portraitPhoneLayout
            }
        }
    }

    private var portraitPhoneLayout: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            tabContentStack
        }
        .safeAreaInset(edge: .bottom) {
            customTabBar
        }
    }

    private var landscapePhoneLayout: some View {
        HStack(spacing: 0) {
            // Slim side rail
            landscapeSideRail
            // Content
            ZStack {
                AppTheme.background.ignoresSafeArea()
                tabContentStack
            }
        }
    }

    private var tabContentStack: some View {
        ZStack {
            NavigationStack { MyHoldingView() }
                .opacity(selectedTab == .holdings ? 1 : 0)
                .allowsHitTesting(selectedTab == .holdings)

            NavigationStack { NewsView() }
                .opacity(selectedTab == .news ? 1 : 0)
                .allowsHitTesting(selectedTab == .news)

            NavigationStack { InvestorsView() }
                .opacity(selectedTab == .gurus ? 1 : 0)
                .allowsHitTesting(selectedTab == .gurus)

            NavigationStack { MenuView().environmentObject(firebaseController) }
                .opacity(selectedTab == .more ? 1 : 0)
                .allowsHitTesting(selectedTab == .more)

            NavigationStack { ChatView() }
                .opacity(selectedTab == .orion ? 1 : 0)
                .allowsHitTesting(selectedTab == .orion)
        }
    }

    // MARK: - Landscape Side Rail (iPhone)
    private var landscapeSideRail: some View {
        VStack(spacing: 6) {
            ForEach([AppTab.holdings, .news, .gurus, .more], id: \.self) { tab in
                sideRailButton(tab)
            }
            Spacer()
            sideRailButton(.orion)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedTab == .orion ? AppTheme.accent : Color.clear)
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(width: 62)
        .background(
            .ultraThinMaterial
                .shadow(.drop(color: AppTheme.primaryText.opacity(0.06), radius: 8, x: 2))
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 0.5)
        }
    }

    private func sideRailButton(_ tab: AppTab) -> some View {
        Button {
            Haptic.light()
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                    .frame(height: 22)
                    .symbolRenderingMode(.hierarchical)
                Text(tab.label())
                    .font(.system(size: 9, weight: selectedTab == tab ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(
                tab == .orion
                    ? (selectedTab == .orion ? .white : AppTheme.secondaryText)
                    : (selectedTab == tab ? AppTheme.accent : AppTheme.secondaryText)
            )
            .frame(width: 54, height: 44)
        }
    }

    // MARK: - Custom Tab Bar (Phone Portrait)
    private var customTabBar: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let hPad: CGFloat = 14
            let totalWidth = geo.size.width - hPad * 2 - spacing
            let circleSize: CGFloat = totalWidth / 5
            let capsuleWidth = totalWidth - circleSize

            HStack(spacing: spacing) {
                // Left capsule: 4 main tabs
                HStack(spacing: 0) {
                    tabButton(.holdings)
                    tabButton(.news)
                    tabButton(.gurus)
                    tabButton(.more)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .frame(width: capsuleWidth)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: AppTheme.primaryText.opacity(0.12), radius: 20, x: 0, y: 0)
                        .shadow(color: AppTheme.primaryText.opacity(0.06), radius: 6, x: 0, y: 3)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )

                // Right capsule: Orion
                tabButton(.orion)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .frame(width: circleSize)
                    .background(
                        Capsule()
                            .fill(selectedTab == .orion ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(.ultraThinMaterial))
                            .shadow(color: (selectedTab == .orion ? AppTheme.accent : AppTheme.primaryText).opacity(0.15), radius: 20, x: 0, y: 0)
                            .shadow(color: (selectedTab == .orion ? AppTheme.accent : AppTheme.primaryText).opacity(0.08), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        Capsule()
                            .stroke(selectedTab == .orion ? Color.clear : Color.white.opacity(0.15), lineWidth: 0.5)
                    )
            }
            .padding(.horizontal, hPad)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 58)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button(action: { Haptic.light(); withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
            VStack(spacing: 3) {
                Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                    .frame(height: 22)
                    .symbolRenderingMode(.hierarchical)
                Text(tab.label())
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(
                tab == .orion
                    ? (selectedTab == .orion ? .white : AppTheme.secondaryText)
                    : (selectedTab == tab ? AppTheme.accent : AppTheme.secondaryText)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
    }
}
