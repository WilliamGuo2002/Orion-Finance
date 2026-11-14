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
        // Switching tabs always restores the full-size bar
        .onChange(of: selectedTab) { _, _ in TabBarVisibility.shared.expand() }
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
            PhoneTabBar(selectedTab: $selectedTab)
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

}

/// Bottom bar for iPhone portrait. Observes the collapse state itself, so collapsing/expanding
/// during a scroll re-renders only the bar — not MainTabView and every tab beneath it.
struct PhoneTabBar: View {
    typealias AppTab = MainTabView.AppTab
    @Binding var selectedTab: AppTab?
    @ObservedObject private var tabBar = TabBarVisibility.shared

    /// Expanded bar (58) + top (6) and bottom (2) padding.
    static let reservedHeight: CGFloat = 66

    // MARK: - Custom Tab Bar (Phone Portrait)
    var body: some View {
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
                .padding(.vertical, tabBar.collapsed ? 5 : 8)
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
                    .padding(.vertical, tabBar.collapsed ? 5 : 8)
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
            // Tap anywhere on the (collapsed) bar to restore it to full size.
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    if tabBar.collapsed { tabBar.expand() }
                }
            )
        }
        .frame(height: tabBar.collapsed ? 46 : 58)
        .padding(.top, tabBar.collapsed ? 4 : 6)
        .padding(.bottom, 2)
        // Reserve the expanded height so the safe-area inset never changes. Animating the
        // inset relaid out the whole tab content every frame while the bar collapsed.
        .frame(height: Self.reservedHeight, alignment: .bottom)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button(action: {
            Haptic.light()
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
            tabBar.expand()
        }) {
            VStack(spacing: tabBar.collapsed ? 0 : 3) {
                Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                    .frame(height: 22)
                    .symbolRenderingMode(.hierarchical)
                // Label collapses to zero height (icons only) when scrolling up
                Text(tab.label())
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(tabBar.collapsed ? 0 : 1)
                    .frame(height: tabBar.collapsed ? 0 : 13)
                    .clipped()
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

// MARK: - Tab Bar Collapse State (driven by scroll direction)
/// App-level signal for the bottom bar: scroll up to collapse it to icons-only,
/// scroll down to bring the labels back. Scroll views feed it via `update(offset:delta:)`;
/// the tab bar observes `collapsed`. Only flips when the state actually changes, so
/// per-frame scroll callbacks are cheap and don't trigger re-renders.
final class TabBarVisibility: ObservableObject {
    static let shared = TabBarVisibility()

    /// When true, the bottom bar shows icons only (labels hidden) and shrinks.
    @Published var collapsed: Bool = false

    private init() {}

    /// `delta` > 0 means scrolling up (content moving up / deeper into the page).
    func update(offset: CGFloat, delta: CGFloat) {
        let next: Bool
        if offset < 28 {
            next = false            // near the top: always full size
        } else if delta > 2 {
            next = true             // scrolling up → collapse to icons
        } else if delta < -2 {
            next = false            // scrolling down → expand with labels
        } else {
            next = collapsed        // negligible movement: hold current state
        }
        guard next != collapsed else { return }
        withAnimation(.easeInOut(duration: 0.25)) { collapsed = next }
    }

    /// Force the bar back to full size (e.g. when switching tabs).
    func expand() {
        guard collapsed else { return }
        withAnimation(.easeInOut(duration: 0.25)) { collapsed = false }
    }
}

extension View {
    /// Lets any scroll view (ScrollView or List) drive the bottom bar's collapse:
    /// icons-only when scrolling up, labels back when scrolling down.
    func tracksTabBarCollapse() -> some View {
        onScrollGeometryChange(for: CGFloat.self) { geo in
            (geo.contentOffset.y + geo.contentInsets.top).rounded()
        } action: { oldValue, newValue in
            TabBarVisibility.shared.update(offset: max(0, newValue), delta: newValue - oldValue)
        }
    }
}
