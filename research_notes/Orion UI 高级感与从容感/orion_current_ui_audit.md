# Orion Finance: current UI audit for premium feel (高级感) and calm (从容感)

Citation convention, used instead of URLs because the sources are local:
- `src: <path>:<line>` is relative to `/Users/kuoihsuan2002/Desktop/prev/MyProject/Equion for iOS/Equion for iOS/`.
- `shot: <file>` is in `/private/tmp/claude-501/-Users-kuoihsuan2002-Desktop-prev-MyProject/aade60a2-bcd7-4d38-ae6e-f618c0ee1a37/scratchpad/ui_shots/`. Screenshots are 1206×2622 px (iPhone 17 Pro simulator, @3x, so 3 px = 1 pt), guest account, no linked accounts.
- Counts come from `grep` over all `*.swift` files (≈18.3k lines; MyHoldingView.swift is 2,313 lines and StockDetailView.swift is 2,202).
- Hex values for tokens come from `Assets.xcassets/Theme*.colorset/Contents.json`. I checked rendered colors by decoding screenshot pixels: light bg renders as #F5F2EE, dark bg as #1C1916 and dark card as #262220, all exactly matching the tokens.
- Contrast ratios are WCAG 2.x luminance ratios I computed from those hex values.

## 1. Design tokens: colors, hues, type, spacing, radii, shadows, materials

### Takeaway
The token layer is small and warm: a beige/caramel neutral palette with one accent, a serif display face, and SF Mono for numbers. Views bypass it heavily, though. The code uses 21 distinct numeric font sizes, 26 distinct padding values, 10 distinct corner radii, about 24 distinct shadow recipes, 12 opacity levels of the accent and 6 of the secondary text. At least 12 off-palette hues (system orange, blue, red, purple, etc.) appear outside the theme. The palette reads as one family, but its application doesn't follow a consistent system.

### Cited Findings

#### Color tokens (asset catalog; light / dark)
| Token (AppTheme name → asset) | Light | Dark | Uses in code |
|---|---|---|---|
| background → ThemeBackground | #F5F2EE | #1C1916 | 40 |
| cardBackground → ThemeCardBackground | #FFFFFF | #262220 | 66 |
| border → ThemeBorder | #E3DED7 | #3A3430 | 31 |
| accent → ThemeAccent ("warm caramel") | #C4956A | #D4A574 | 218 |
| accentDark → ThemeAccentDark | #A87B52 | #B8895C | **0 (unused)** |
| primaryText → ThemePrimaryText | #2C2520 | #F0EBE5 | 183 |
| secondaryText → ThemeSecondaryText | #8A8078 | #9A9088 | 242 |
| positive → ThemePositive | #4CB07D | #61C78F | 53 |
| negative → ThemeNegative | #E35C5C | #F2736B | 58 |
| warning → **same asset as negative** (ThemeNegative) | #E35C5C | #F2736B | 24 |
| barBackground → ThemeBarBackground | #FFFFFF | #1C1916 | 5 |
| subtleFill → ThemeSubtleFill | #EDE9E2 | #2A2622 | 47 |
| adBackground → ThemeAdBackground | #F0EDE8 | #2A2622 | 1 |
(src: Services/AppTheme.swift:14-50; asset JSON; AccentColor.colorset = #C4956A / #D4A574)

- Error/warning and "price down" are the same color: `static let warning = Color("ThemeNegative")` (src: Services/AppTheme.swift:41).
- The card surface is not flat. In light mode it is a top-leading→bottom-trailing gradient from `Color.white` to `Color(red:0.97, green:0.95, blue:0.93)` (= #F7F2ED); in dark mode it goes from cardBackground to cardBackground@0.92. Stroke is border@0.6 at 0.8 pt (light) or white@0.08 at 0.5 pt (dark) (src: Services/AppTheme.swift:335-374).
- Opacity variants act as extra, untokenized color levels. secondaryText appears at 6 opacities (0.3×4, 0.35×1, 0.4×5, 0.5×7, 0.6×1, 0.7×4). Accent appears at 12 distinct opacities (0, 0.05, 0.06, 0.08, 0.1, 0.12, 0.15, 0.3, 0.35, 0.4, 0.5, 0.6; most common 0.3×13, 0.1×11, 0.12×10) (grep `secondaryText.opacity`, `accent.opacity`).
- The pull-to-refresh tint is hard-coded `UIColor(red:0.82, green:0.58, blue:0.35)` = #D1945A. That is not the accent token (#C4956A) and has no dark variant (src: Views/Components/OrionRefreshView.swift:10; applied app-wide at Equion_for_iOSApp.swift:9).

#### Off-token hues used in views (outside AppTheme)
- **System orange**: crypto asset icon tint (src: Views/MyHoldingView.swift:1794, 2013), risk result "Moderate" (src: Views/RiskProfileView.swift:105, 333), interests category color (src: Views/InterestsSelectionView.swift:167), voice/video chat status (src: Views/ChatView.swift:631, 792), NotificationSettingsView.swift:64, investor chart palette (src: Views/InvestorsView.swift:131).
- **System blue**: forex icon tint (src: Views/MyHoldingView.swift:1795, 2014), risk "Conservative" (src: Views/RiskProfileView.swift:102, 332), interests (src: Views/InterestsSelectionView.swift:164), voice-chat orb rings and gradient (src: Views/ChatView.swift:647, 654, 663), video transcript bubble (src: Views/ChatView.swift:834).
- **System red**: risk "Aggressive" (src: Views/RiskProfileView.swift:108, 334), interests (src: Views/InterestsSelectionView.swift:166), record buttons (src: Views/ChatView.swift:708, 718, 843, 866).
- **Purple, teal, indigo, gray, cyan, yellow, pink, mint**: interests categories (src: Views/InterestsSelectionView.swift:164-173) and the investor-detail chart palette, which has 11 colors including orange, purple, cyan, yellow, pink, mint and indigo (src: Views/InvestorsView.swift:128-135).
- **RGB literals**: metal gold (0.85, 0.75, 0.40) = #D9BF66 and commodity sage (0.55, 0.75, 0.55) = #8CBF8C (src: Views/MyHoldingView.swift:1796-1797, 2015-2016); interests green #33B366, brown #996633 and yellow #D9BF4D (src: Views/InterestsSelectionView.swift:165, 169, 172); video-chat navy #0D0D26 (src: Views/ChatView.swift:604).
- **Net-worth categorical palette**: 6 hex per mode, light 0x2a78d6, 0xeb6834, 0x1baf7a, 0xeda100, 0xe87ba4, 0x6250d6 and dark 0x3987e5, 0xd95926, 0x199e70, 0xc98500, 0xd55181, 0x9085e9. The comment says it was validated for these surfaces and for CVD (src: Views/NetWorthChartModule.swift:5-23).
- **Visible on captured screens**: system orange plus pastel blue and pink on the risk result (shot: 02_onboarding_result_light.png; the icon circle samples #F6E6D6, i.e. orange at 12%). Third-party purple Motley Fool logos sit in stock-detail news (shot: 11_stock_detail_scrolled2_light.png). Saturated news photos appear in the News feed (shot: 12_news_light.png).

#### Typography
- Four families/designs are in use:
  - New York (system serif) via `serifTitle` and `serifHeadline` (src: Services/AppTheme.swift:92-105).
  - SF Pro via `body`, `caption` and raw `.system(size:)`.
  - SF Mono via `number()` for every price and percentage (src: Services/AppTheme.swift:113-115) and inside ChangeBadge (src: Services/AppTheme.swift:597).
  - CJK serif fallbacks for zh/ja/ko (Songti SC, Hiragino Mincho ProN, AppleMyungjo) at a fixed size (src: Services/AppTheme.swift:127-160).
- SF Mono renders slashed zeros and wide "." spacing in hero numbers: "$162.85", "0.03%" (shot: 08_stock_detail_top_light.png; 05_add_asset_sheet_light.png ticker "-0.36%"). There are 0 uses of `.monospacedDigit()`.
- 261 `.system(size: N)` call sites span 20 sizes: 9×9, 10×22, 11×34, 12×43, 13×36, 14×32, 15×28, 16×12, 17×1, 18×8, 20×13, 22×4, 24×2, 28×4, 32×5, 34×1, 36×3, 40×1, 44×1, 48×2.
- The AppTheme helpers add more fixed sizes:
  - caption: 10/11/12/13/14 plus default 12 (75 calls)
  - number: 10–32 (80 calls)
  - serifHeadline: 16/17/18/20/22/24 plus default 17 (18 calls)
  - serifTitle: 22/24/26/28/32 plus default 22 (11 calls)
- Union of numeric sizes: **21 distinct** (9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 26, 28, 32, 34, 36, 40, 44, 48).
- 103 calls use semantic text styles: .caption 34, .subheadline 25(+1), .caption2 12, .body 8, .title2 7(+1), .headline 4, .footnote 4, .title 3, .title3 2, .callout 2.
- Weights: semibold 105, bold 69, medium 59, light 10, black 4, regular 2, heavy 1, so **7 weights** (grep `weight:` and `.fontWeight`).
- Page-title sizes are inconsistent:
  - Home greeting serif 26 (src: Views/MyHoldingView.swift:109); News 26 (src: Views/NewsView.swift:33); Gurus 26 (src: Views/InvestorsView.swift:23)
  - Orion AI 22 (src: Views/ChatView.swift:27); stock name 24 (src: Views/StockDetailView.swift:1376)
  - Login 32 (src: Views/LoginView.swift:50); risk 28 (src: Views/RiskProfileView.swift:155); risk result 32 (src: Views/RiskProfileView.swift:319)
  - More has no page title at all (shot: 14_more_light.png); Accounts and Tax use the system inline nav title (src: Views/MyHoldingView.swift:1359-1360; Views/TaxCenterView.swift:36).

#### Spacing and layout tokens
- Tokens: `cardRadius 18`, `cardPadding 16`, `moduleSpacing 22` (src: Services/AppTheme.swift:57-63). `cardPadding` is used 5× and `moduleSpacing` only 3×, and only in the iPad/wide stock-detail layout (src: Views/StockDetailView.swift:276, 288, 300).
- 430 numeric `.padding()` calls use **26 distinct values**: -16, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 30, 32, 40, 50, 60, 64, 80, 100. The most common are 16×68, 12×54, 14×41, 8×39, 4×36, 20×33, 24×30 and 10×25.
- Stack `spacing:` uses 17 distinct values: 0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 50.
- Screen horizontal margins vary: 20 pt on the home, News and Gurus headers; 16 pt on the Orion AI header and stock-detail header (src: Views/MyHoldingView.swift:139; Views/NewsView.swift:48; Views/InvestorsView.swift:30; Views/ChatView.swift:36; Views/StockDetailView.swift:1445). Cards use 16 outer + 14 inner (src: Views/MyHoldingView.swift:899-902).

#### Corner radii
- 10 distinct numeric radii (counts): 1.5×1, 2×2, 4×8, 6×9, 8×10, 10×25, 12×21, 14×1, 16×8, 18×2. On top of that, `AppTheme.cardRadius` (18) is used 17× and `Capsule()` 58×.
- Buttons use three shapes:
  - Capsules: Get Started, Add Stock, Start a new chat, risk Back/Next (src: Views/RiskProfileView.swift:353; Views/MyHoldingView.swift:431; Views/ChatView.swift:78).
  - Radius-10 rects: Log In, Google, Apple (src: Views/LoginView.swift:110, 164, 247).
  - Radius-12 rect: Allow and continue (src: Services/AIConsent.swift:124).
- The login card is radius 16 and its text fields radius 6 (src: Views/LoginView.swift:70, 122). `BubbleShape` (r16 with tails) is defined but unused (src: Services/AppTheme.swift:408-448; grep finds 0 uses).

#### Shadows (35 `.shadow(` calls, ~24 distinct recipes)
- Every themeCard / themeCardSurface (23 uses) carries black@0.10, r10, y5 in light mode and black@0.30 in dark (src: Services/AppTheme.swift:351). `AppTheme.cardShadow()` (primaryText@0.10 r10 y5) is defined but never used (src: Services/AppTheme.swift:66-69).
- Colored glows on CTAs:
  - accent@0.3 r8 y4 ×5: Add Stock, Start a new chat, risk Next, Get Started, a Paper Trading button (src: Views/MyHoldingView.swift:432; Views/ChatView.swift:79; Views/RiskProfileView.swift:242, 354; Views/PaperTradingView.swift:426), plus a conditional copy on the Interests continue button (src: Views/InterestsSelectionView.swift:106)
  - FAB accent@0.35 r12 y6 (src: Views/MyHoldingView.swift:171)
  - login sparkle accent@0.4 r12 (src: Views/LoginView.swift:45)
  - empty-state sparkle accent@0.4 r8 (src: Views/MyHoldingView.swift:407)
  - constellation stars accent@0.5 with radius = star size (src: Views/MyHoldingView.swift:2211)
- A red/green glow sits under the stock-detail change pill: color@0.3 r4 y2 (src: Views/StockDetailView.swift:1425).
- The tab bar has two stacked shadows per capsule, primaryText@0.12 r20 and @0.06 r6 y3. The Orion capsule glows accent-colored when selected (src: ContentView.swift:336-337, 352-353).
- Smaller recipes: MoverChip primaryText@0.03 r4 y2, toolbar pills primaryText@0.08 r2 y1 ×4, risk-quiz bottom bar primaryText@0.05 r10 y-4 (src: Views/MyHoldingView.swift:2055; Views/StockDetailView.swift:1469; Views/RiskProfileView.swift:250).

#### Materials
- `.ultraThinMaterial` is the only material in code (no `glassEffect` or other material APIs), at 7 sites:
  - tab-bar capsule (src: ContentView.swift:335) and unselected Orion capsule (src: ContentView.swift:351)
  - landscape side rail (src: ContentView.swift:267)
  - market ticker strip (src: Views/MyHoldingView.swift:1613)
  - News refresh button (src: Views/NewsView.swift:41)
  - chat input bar (src: Views/ChatView.swift:294)
  - chart "Touch to explore" hint (src: Views/StockDetailView.swift:1655)
- The round back button and the sheet's "Cancel" capsule appear to be system-provided glass chrome (iOS 26 style) rather than app code (shot: 08, 03). That is inferred from their look, since the code doesn't draw them.

#### Section-title component
- `AccentSectionTitle` = a 4×20 pt accent bar (radius 2) + a 14 pt semibold accent SF Symbol + serif 17 semibold title (src: Services/AppTheme.swift:505-531). It has 11 call sites. One is inside `moduleCard`, which stock detail uses 10× (src: Views/StockDetailView.swift:319-329), so 20 accent-bar titles can render in total.
- `SectionLabel` (12 pt heavy, uppercase, tracking 1.2, 4×16 bar; comment says "thick & vivid") is used 1× (src: Services/AppTheme.swift:474-502; Views/MyHoldingView.swift:317).
- On screen: home shows 1 bar (Today's Market). Stock detail shows 2 bars on the first screen (AI Research Snapshot, Fundamentals) and 3 on the next (Upcoming Earnings, Key Data, Analyst Recommendations) (shot: 08, 10).

#### Change indicators (4 different visual systems for the same datum)
1. **ChangeBadge** (src: Services/AppTheme.swift:536-610): arrow.up.right/down.right at weight `.black` inside a circle tinted color@0.18 (18/22/26 pt), text SF Mono bold 11/12/14, capsule color@0.1. Used on home chips, rows, ticker (no bg) and peers.
2. **Solid gradient pill** with "▲/▼" glyphs, white SF Pro bold 13 and a colored glow on the stock-detail hero (src: Views/StockDetailView.swift:1407-1426; shot: 08 "▼ -2.59 (-1.57%)").
3. **Plain colored caption** in the collapsed toolbar pill (src: Views/StockDetailView.swift:1463-1466; shot: 10 "-1.57%").
4. **Colored mono text** with no icon in P&L and holdings rows (src: Views/MyHoldingView.swift:735-749, 1493-1495).

### Inferences
- The tokens themselves (warm off-white #F5F2EE, near-black brown #2C2520, muted caramel accent, serif headings) are a sound base for a premium look. The perceived inconsistency comes from the long tail: 21 sizes, 26 paddings, 13 accent opacities, 4 change-indicator systems, 3 button shapes and system hues leaking in on onboarding and asset icons.
- Because warning and negative share one red, an error banner and a falling price look identical, which blurs "something is wrong" with "a stock went down".
- The tokens include unused pieces (accentDark, cardShadow, BubbleShape) and barely used ones (moduleSpacing, the animation tokens; see §2). That suggests the design system was started but never enforced.

### Gaps
- I did not inspect the AppIcon PNGs or Info.plist for launch-screen styling.
- Off-palette colors in PaperTradingView, PortfolioWizardView, StockCompareView and NotificationSettingsView appear only in the counts; I didn't audit those screens.
- The dark-mode hex values of the off-palette system colors depend on iOS and were not sampled.

## 2. Motion and attention inventory

### Takeaway
The app has 7 perpetual `repeatForever` loops, one always-on auto-scrolling marquee at the top of the home screen, a scroll-driven blur/sink parallax, a scroll-direction tab-bar collapse, 14 `numericText` transitions and bouncy springs (damping 0.6) on price badges. It has 61 haptic call sites, mostly `light` and medium-impact `tap`. One modal appears without the user asking: the AI consent sheet on stock detail, which can't be swiped away and comes back on every visit after "Not now". None of this motion is gated by Reduce Motion. The animation tokens exist but are almost never used; there are about 19 ad-hoc timing literals instead.

### Cited Findings

#### Perpetual / repeating animations (7 `repeatForever` sites)
| # | What | Params | Where it shows | src |
|---|---|---|---|---|
| 1 | Market ticker marquee (auto-scrolling) | `.linear(duration: itemsWidth/40).repeatForever(autoreverses:false)`; 40 pt/s; starts 0.3 s after appear; strip 36 pt tall on ultraThinMaterial; items spaced 32 pt | Top of home, always (shot: 05, 06) | Views/MyHoldingView.swift:1579-1651 |
| 2 | ConstellationView glow on empty watchlist | `.easeInOut(2.5).repeatForever(autoreverses:true)`; lines accent 0.12↔0.25, stars 0.4↔0.8 | Home empty state (shot: 05) | Views/MyHoldingView.swift:2175-2221 |
| 3 | Chart "Touch to explore" hint pulse | `.easeInOut(1.2)` forever; rings 20↔36 pt and 14↔22 pt; appears 0.8 s after load, auto-hides at 6 s; first use only (`@AppStorage hasUsedChartTouch`) | Stock detail chart | Views/StockDetailView.swift:1587-1601, 1608-1665 |
| 4 | LivePulseDot at end of 1D line | `.easeInOut(1.2)` forever, 8↔16 pt halo | Stock detail, only when market open and 1D | Services/AppTheme.swift:451-471; Views/StockDetailView.swift:1563-1570 |
| 5–6 | Voice-chat orb rings | 0.8 s and 0.6 s forever, blue/purple | Gemini Live full-screen | Views/ChatView.swift:646-657 |
| 7 | Skeleton shimmer | `.linear(1.5)` forever | Watchlist, News, chart and AI-dashboard skeletons | Views/Components/ShimmerView.swift:6-33 |

#### Scroll-driven and state motion
- **Parallax blur on the home net-worth chart.** Offset up to +20 pt, `.blur` up to 6 pt, opacity down to 0.7 and scale down to 0.97. It ramps in after a third of the chart height has scrolled, over a further 45% of chart height, quantized to 1/40 steps (src: Views/MyHoldingView.swift:11-23, 1091-1106). The effect only exists when holdings are linked (`portfolioChartHeight` = 220 or 0; src: Views/MyHoldingView.swift:97-99), so it isn't visible in the guest screenshots.
- **Tab-bar collapse.** Scrolling up shrinks the bar to icons only (58→46 pt, labels to 0 height) with `.easeInOut(0.25)`. It expands when scrolling down, near the top (<28 pt), or on tab switch (src: ContentView.swift:370-375, 414-443).
- **Stock-detail toolbar pill.** The compact "NVDA $162.85 -1.57%" pill fades in once the header scrolls off, `.easeInOut(0.2)` (src: Views/StockDetailView.swift:142-146, 1446-1455; shot: 10).
- **numericText: 14 sites.** MyHoldingView 5, NetWorthChartModule 5, StockDetailView 4. Scrubbing uses 0.05 s ease and price updates 0.3 s (src: Views/MyHoldingView.swift:693, 1722-1723; Views/StockDetailView.swift:1386, 1404-1405, 1411).
- **Springs: 4 parameter sets.**
  - (0.3, 0.7) ×3, e.g. risk option select (src: Views/RiskProfileView.swift:259)
  - **(0.35, 0.6) ×3 on price-change badges**: StockRow, MoverChip, hero pill (src: Views/MyHoldingView.swift:1726, 2048; Views/StockDetailView.swift:1426)
  - (0.35, 0.75) ×2, interval capsule and asset category (src: Views/StockDetailView.swift:1340; Views/MyHoldingView.swift:1986)
  - (0.4, 0.75) = `AppTheme.gentleSpring`, used 2× in chat (src: Services/AppTheme.swift:224; Views/ChatView.swift:469, 493)
- **Ease/linear literals.** About 19 distinct numeric curve/duration literals from 0.05 s to 2.5 s (easeInOut ×9 durations, easeOut ×7, easeIn ×2, linear ×1); most common easeInOut 0.3 ×8, 0.05 ×7, 0.2 ×6, 0.25 ×4. The animation tokens quickDuration 0.2, standardDuration 0.35 and slowDuration 0.5 (src: Services/AppTheme.swift:218-224) are referenced only inside AppTheme itself. Only gentleSpring is used, 2×.
- **matchedGeometryEffect: 2.** Stock-detail interval capsule and add-asset category pill (src: Views/StockDetailView.swift:1356; Views/MyHoldingView.swift:2001).
- **Login entrance stagger.** Logo 0.7 s, title 0.6 s at +0.3, form 0.6 s at +0.6 (src: Views/LoginView.swift:198-200).
- **Unused motion component.** `StaggeredItem` (0.4 s fade-up, 0.06 s per-item stagger) has 0 uses outside its own doc comment (src: Views/Components/StaggeredFadeIn.swift:9-27).
- **Risk-quiz page change.** Switches `currentPage` inside `withAnimation(.easeInOut(0.3))` with no `.id`/`.transition`, so old and new question content crossfade on top of each other (src: Views/RiskProfileView.swift:117-124, 208-231; shot: 01c).

#### Haptics: 61 call sites (excluding the doc comment in HapticManager)
- **By type:**
  - `light()` 23 (UIImpact .light)
  - `tap()` 10 (UIImpact **.medium**)
  - `error()` 8
  - `selection()` 7
  - `success()` 7
  - `soft()` 4 (.soft at intensity 0.4)
  - `warning()` 2
  (src: Services/HapticManager.swift:7-34)
- **By file:** MyHoldingView 14, LinkedAccountsView 8, RiskProfileView 5, PortfolioWizardView 5, StockDetailView 5, NewsView 4, ChatView 4, PaperTradingView 4, LoginView 3, NetWorthChartModule 3, ContentView 2, InterestsSelectionView 2, StockCompareView 1, ErrorStateView 1.
- **Triggers:**
  - Every tab switch (light; src: ContentView.swift:279, 380).
  - Each Today's Market pill (light; src: Views/MyHoldingView.swift:838).
  - Each stock interval change (light; src: Views/StockDetailView.swift:1339).
  - Each fundamentals metric tap (light; src: Views/StockDetailView.swift:1075).
  - FAB, Add Stock and Help Me Pick Stocks (medium `tap`; src: Views/MyHoldingView.swift:163, 421, 435).
  - Chart scrubbing: `selection()` every time the finger crosses a data point, then `soft()` on release (src: Views/StockDetailView.swift:1549-1556; Views/MyHoldingView.swift:260-270; Views/NetWorthChartModule.swift:200).
  - Remove from watchlist fires `warning()` and then `tap()`, so two haptics for one action (src: Views/MyHoldingView.swift:360 → 618).
  - Every risk-quiz option select, Back and Next (light) and the final save (success) (src: Views/RiskProfileView.swift:209, 229, 258, 393).
  - New chat and send (medium; src: Views/ChatView.swift:129, 450).
  - AI summary arrival (soft; src: Views/NewsView.swift:305).
- No in-app setting turns haptics off; there are no references to a haptics preference (src: Services/SettingsManager.swift is 48 lines; grep).

#### Modals and sheets
- **Unrequested modal.** Opening any stock detail calls `loadAllModules()`, which then calls `Task { await loadAIDashboard() }` → `APIService.streamAIDecisionDashboard` → `AIConsent.shared.ensure()` (src: Views/StockDetailView.swift:147-151, 1735, 1768-1785; Services/APIService.swift:995-1007).
  - That presents a `.pageSheet` at the `.large()` detent with `isModalInPresentation = true`, so it can't be swiped away (src: Services/AIConsent.swift:57-67; shot: 07_ai_consent_auto_popup_on_stock_detail_light.png).
  - "Not now" persists `granted=false`, and `request()` only short-circuits when `granted` is true. With no "already asked" flag, the sheet comes back on every later stock-detail open and on every fundamentals metric tap, which also calls Gemini (src: Services/AIConsent.swift:35-55; Views/StockDetailView.swift:1082).
- **Modal counts:** 17 `.sheet(`, 2 `.fullScreenCover(`, 2 `.alert(`, 2 `.confirmationDialog(`.

#### Pull-to-refresh, loading states, layout shifts
- **`.refreshable`: 7 sites** (home ×2, Accounts, Tax, Linked Accounts, News, Chat list). All use the hard-coded #D1945A tint (src: Views/MyHoldingView.swift:310, 377, 1361; Views/NewsView.swift:113; Views/ChatView.swift:98; Views/TaxCenterView.swift:39; Views/LinkedAccountsView.swift:131).
- **Skeleton + shimmer: 4 places.** Watchlist (4 cards), News (6 cards), stock chart (sine-wave path) and AI dashboard (partial) (src: Views/MyHoldingView.swift:295; Views/NewsView.swift:52-61; Views/StockDetailView.swift:1474-1478, 1003-1012).
- **Spinners: 24 `ProgressView(` sites.** Examples: Today's Market header spinner at 0.6 scale (src: Views/MyHoldingView.swift:829-831), recommendations at 0.7 (src: Views/MyHoldingView.swift:1057-1060), chat "Thinking..." (src: Views/ChatView.swift:224-233), InvestorDetail "Loading..." (src: Views/InvestorsView.swift:164).
- **Stock-detail price placeholder.** Before the quote loads, the 32 pt bold mono hero shows the word "Loading..." (src: Views/StockDetailView.swift:118-120, 1401-1403).
- **Stock-detail layout shifts.** Loading runs in sequence: chart, then quote, then modules (src: Views/StockDetailView.swift:147-151). Almost every module is conditional (`if let` or `if !isEmpty`): Key Data, Analyst, News, Peers, Company Info, Fundamentals, Holdings, Earnings (src: Views/StockDetailView.swift:336, 455, 496, 586, 728, 1050, 1123, 1250). Each one pops in as its request finishes, and the AI module streams partial results (src: Views/StockDetailView.swift:1778-1781). Content below the fold grows and jumps while loading.
- **Home layout shifts.** `linkAccountsPrompt` only appears after `holdingsLoaded` (src: Views/MyHoldingView.swift:210-212); My Movers and Ideas to Explore are conditional (src: Views/MyHoldingView.swift:908, 306, 372).
- **Risk-quiz layout shift.** The page-1 header (80 pt icon circle, 28 pt title, subtitle) exists only when `currentPage == 0` (src: Views/RiskProfileView.swift:143-163). On Q2 the progress bar and question jump up by roughly 175 pt (shot: 01 progress bar at y≈780 px, versus 01b at y≈250 px; 3 px = 1 pt).

### Inferences
- From a calm-design standpoint the strongest attention-pullers on the default (guest) home are:
  - the perpetually moving index marquee at the very top, showing red arrows on a down day
  - the perpetually breathing constellation
  - the glowing FAB
- A first stock-detail visit adds an unrequested, non-dismissable full-screen sheet. After a decline, the same sheet becomes a nag on every visit.
- Medium-impact haptics on routine taps (FAB, copy, send, new chat), plus a selection tick for every data point crossed while scrubbing, make the app feel busy in the hand. Consistent soft/light feedback would feel calmer.
- Damping 0.6 springs on red/green badges make price changes "bounce", which emphasizes volatility.

### Gaps
- I didn't observe motion at runtime, only in code. Perceived marquee speed, how "breathy" the constellation feels, and parallax smoothness are unverified.
- Haptic intensity on a real device can't be measured from the simulator.
- Home with linked accounts (parallax chart, net-worth header) was not captured, so the blur-on-scroll is audited from code only.
- I didn't trace the full sheet/alert triggers in PaperTradingView, PortfolioWizardView or StockCompareView.

## 3. Screen-by-screen observations (screenshots + code)

### Takeaway
Each screen has the same warm surface and serif headings, but few have a single dominant element. Home stacks a marquee, greeting, closed-market pill, link card, market card, a 160 pt animated illustration, two "add" CTAs and a FAB, plus a third CTA hidden under the tab bar. Stock detail runs 12 modules, 3 ad slots and 3 dividers, each module with an accent bar, icon and serif title. Red/green is strong on stock detail: a saturated pill with glow, a red area chart, red→green range bars and colored endpoint labels. Several placeholders and broken states ship visibly: "?" icon boxes, an empty AI card, "Ad" boxes, an options placeholder and "—" volume. The quieter screens are Gurus, More and the Orion empty state.

### Cited Findings

#### Screenshot inventory / naming mismatches
- `03_home_top_light.png` actually shows the **Add Asset sheet** (medium detent) over home in light mode.
- `04_home_top_dark.png` actually shows the **Add Asset sheet in dark mode**. Only the top of dark home (ticker, greeting, link card, Today's Market) shows behind it.
- `05_add_asset_sheet_light.png` actually shows **home without the sheet** (light).
- `06_home_after_add_light.png` is visually identical to 05: the watchlist is still empty and nothing indicates success or failure.
- So there is no full dark-home screenshot and no sheet-less home in 03/04.
- `07` shows the consent sheet at full height. The stock detail behind it isn't visible, so the screenshot alone can't prove it was automatic. The code path does (§2).
- The status bar shows "◀ StatsWatch" in every shot, meaning the app was opened from another app. That is irrelevant to the UI.

#### 00 Login (shot: 00_login_light.png; src: Views/LoginView.swift)
- **Elements, top to bottom:** sparkle (36 pt light, accent, glow r12 inside a 100 pt radial halo); "Orion Finance" serif 32 (a hard-coded literal, not localized, src: Views/LoginView.swift:49-50); "Your investment companion" caption 14; a white card (radius 16, 1 pt border) holding Email and Password fields (radius 6) and a "Log In" caramel button (radius 10, white text); "Forgot Password?"; an "or" divider; "Continue with Google" (white, 1 pt border, **generic `globe` SF Symbol instead of the Google mark**, src: Views/LoginView.swift:239); a black "Sign in with Apple" system button (radius 10, 50 pt); "Don't have an account? Sign Up" with Sign Up in accent; "Skip Login (Beta)" at secondaryText@0.5.
- **Hierarchy:** the black Apple button is the highest-contrast block on the page and outweighs the caramel "Log In" (white on #C4956A = 2.67:1).
- **Contrast:** "Skip Login (Beta)" computes to 1.74:1.
- **Tone:** "(Beta)" is visible to users.

#### 01 / 01b / 01c Risk quiz (shots 01_onboarding_risk_light, 01b_onboarding_q2_light, 01c_onboarding_transition_overlap_light; src: Views/RiskProfileView.swift)
- **Q1 (01):**
  - The header has `person.fill.questionmark` (32 light) in an 80 pt accent@0.1 circle, "Investment Style" serif 28 and the subtitle "Help Orion tailor what it explains and shows you" (.subheadline).
  - The progress bar is 5 capsules 4 pt tall.
  - The question row has a `calendar.badge.clock` icon (20 pt, rendered two-tone) and "How long do you plan to invest?" serif 20, followed by "1 / 5".
  - Each option card is white, radius 18, 0.5 pt border and a soft shadow.
  - **The option "icon" is a "?" missing-glyph box.** The code renders emoji characters (⏱️ 📅 🏔️ 🛡️ ⚖️ 🎢 🏃 🧘 🛒 🏦 🌱 🚀 🐣 📚 🎯) as `Text(option.emoji)` at 28 pt (src: Views/RiskProfileView.swift:44-86, 264-265).
  - Labels start about 129 pt from the left edge, an unusually wide gap after the icon box.
  - The bottom nav bar on Q1 is empty (no Back, and Next only appears after a selection) but still draws its background and upward shadow, a faint band near the bottom (src: Views/RiskProfileView.swift:205-251).
- **Q2 (01b):** The header block is gone (`currentPage == 0` only), so the whole layout shifts up. A Back capsule (subtleFill) appears. Next is hidden until an option is selected (src: Views/RiskProfileView.swift:227-244).
- **Transition (01c), Q3→Q4:**
  - Ghost text of "If your stock drops 15% in a week, you would:" overlaps "What's your primary investment goal?".
  - Both icons (warning triangle and target) are visible side by side.
  - The ghost option "Hold and wait for recovery" sits under "Steady growth over time", which still carries the previous answer's accent selection border, and its checkmark ghosts at the right.
  - A faint "Next" capsule is mid-fade at the bottom right.
- **Option-card selection style:** accent 2 pt stroke, accent@0.12 shadow, scale 1.01, spring (0.3, 0.7) (src: Views/RiskProfileView.swift:286-291).

#### 02 Risk result (shot: 02_onboarding_result_light.png)
- **Elements:** a 100 pt circle at color@0.12 with a 40 pt light icon; "Your Investment Style" serif 16 secondary; **"Moderate" serif 32 in system orange**; body copy; a score bar of 3 segments (blue/orange/red at 0.2) with a 14 pt orange dot; "Get Started →" full-width caramel capsule with glow; "Retake Quiz" (src: Views/RiskProfileView.swift:298-373).
- **Color:** orange, blue and pink introduce hues that appear nowhere else in the main UI. The Moderate orange (~#FF9500 system) clashes with the caramel CTA directly below it.
- **Advice-like copy** (src: Views/RiskProfileView.swift:103, 106, 109):
  - Moderate: "We'll suggest a mix of growth stocks and stable investments." (the one visible here)
  - Conservative: "We'll focus on blue-chip stocks, bonds, and dividend-paying investments."
  - Aggressive: "We'll highlight high-growth opportunities and emerging trends."
- **Code detail:** the score dot is positioned with `offset(x: width*fraction)` and no centering compensation (src: Views/RiskProfileView.swift:375-388).

#### 05 / 06 Home, guest, light (shots 05_add_asset_sheet_light, 06_home_after_add_light; src: Views/MyHoldingView.swift)
- **Ticker:** an auto-scrolling strip (36 pt, ultraThinMaterial) showing "S&P 500 754.37 ↘ -0.36%" and "NASDAQ 679.89 ↘ -1.20%". Prices and percentages are SF Mono, the arrows sit in pink circles, and the figures are red.
  - These are **SPY/QQQ ETF prices labeled as index names** (src: Views/MyHoldingView.swift:507).
- **Greeting:**
  - "Good morning" serif 26 bold.
  - "Ready for a new trading day?" (.subheadline), with "Sunday, November 15" on the right (11 pt at secondary@0.7 = 2.25:1, `en_US` locale hard-coded; src: Views/MyHoldingView.swift:81-86, 117-119).
  - Directly below is the pill "Markets are closed today — enjoy your Sunday" (moon.zzz.fill 11 pt, caption 12, capsule accent@0.08). The two lines **contradict each other**. The subtitle is a random pick from an hour bucket (5–10 am) that ignores weekends and holidays (src: Services/AppTheme.swift:183-213; Views/MyHoldingView.swift:31, 113, 123-137).
- **"See your net worth" card:** a 38 pt accent@0.12 circle holding building.columns.fill, a 15 semibold title, and an 11 pt subtitle "Link your brokerage and bank accounts · read-only" that wraps and leaves "read-only" orphaned on its own line. A chevron sits at the right (src: Views/MyHoldingView.swift:475-503).
- **"Today's Market" card:**
  - Accent bar + `chart.bar.xaxis` + serif 17 title.
  - Pills: "Hot" (filled accent, white flame.fill), "Gainers" and "Losers" (subtleFill, 11 pt medium) (src: Views/MyHoldingView.swift:823-903).
  - Mover chips (radius 12): "NVDA NVIDIA Corporation ↘ -2.01%" in a pink capsule, then "NU Nu Holdings Ltd.", whose green badge is almost erased by the right-edge fade.
  - **The fade is a pure-white gradient (`cardBackground` #FFFFFF) over a card whose surface ends at #F7F2ED.** That leaves a hard white block and a seam: pixel #FEFEFE at x=1108 px, then #F8F3EF at x=1118 px (src: Views/MyHoldingView.swift:889-895 vs Services/AppTheme.swift:344).
- **Empty state:**
  - A 160 pt accent radial glow, a breathing 120 pt constellation (10 dots, 11 lines) and a 28 pt sparkle with glow.
  - "Your watchlist is empty" (serif 20) and "Start building your constellation of investments" (.subheadline).
  - "+ Add Stock" caramel capsule (15 semibold, 28×12 padding, glow).
  - **A second button, "✦ Help Me Pick Stocks" (outlined capsule), sits behind the floating tab bar.** Only its right rounded end shows: the tan arc between the tab capsule and the Orion circle (src: Views/MyHoldingView.swift:435-449).
- **FAB:** a 52 pt caramel "+" circle with a 0.35 r12 y6 glow overlaps the empty-state area to the right of "Add Stock". It duplicates "Add Stock" (src: Views/MyHoldingView.swift:161-176).
- **Tab bar:**
  - A floating ultraThinMaterial capsule with My Holdings / News / Gurus / More (18 pt icons, 10 pt labels; selected uses accent + .fill symbol).
  - A separate Orion capsule with sparkles; selected becomes a filled accent capsule with white label (src: ContentView.swift:305-407).
  - The tab label reads "My Holdings" while a guest's screen holds no holdings.
- **Hierarchy:** no single dominant element. The largest object is the decorative constellation and the most saturated objects are the red ticker figures. The accent appears as fills on Hot, Add Stock and the FAB at the same time.
- **06:** identical to 05 after an add attempt. No toast, no inline error and no row appeared (see Bug B3).

#### 03 / 04 Add Asset sheet, light/dark (shots 03_home_top_light, 04_home_top_dark; src: Views/MyHoldingView.swift:1803-2019)
- **Layout:** medium detent with a grabber. "Cancel" sits in a system glass capsule in accent color; "Add Asset" is the system inline title.
- **Category pills:** Stocks (filled accent) / Crypto / Forex / Metals, each 13 pt with an icon. "Commodities" is clipped at the right edge with no fade.
- **Search:** field on subtleFill, radius 12, placeholder "Search stocks  (AAPL, MSFT...)" with a double space (src: Views/MyHoldingView.swift:1954).
- **List:** "Popular" caption, then rows of Apple/Microsoft/Alphabet/Amazon. **Every row uses the same generic `building.2` tile** (`AssetType.stock.icon`, src: Models/AssetMeta.swift:20; 40 pt, radius 10, accent@0.1) instead of a logo, with a 20 pt `plus.circle` in accent. There are no separators, only whitespace.
- **Dark (04):** unselected pills (subtleFill #2A2622 on the #262220 sheet) are almost invisible. Behind the sheet, the home's Today's Market pills "Gainers/Losers" have the same problem (fill vs card 1.05:1).

#### 07 AI consent (shot: 07_ai_consent_auto_popup_on_stock_detail_light.png; src: Services/AIConsent.swift:81-154)
- **Content:**
  - A sparkles icon (34 pt) and "Before you use Orion AI" serif 24.
  - A 15 pt paragraph, then three accent-icon bullets (14 pt) about what is sent to Google Gemini.
  - An inset panel (subtleFill, radius 12) with three reassurances: no balances or holdings sent; "education and research… not a registered adviser"; how to turn it off in More → AI Data Sharing.
  - The footnote "Google processes this data under its own terms and may handle it outside Canada." (caption 12).
  - "Allow and continue" (radius 12, 16 semibold) and "Not now" (15 medium secondary).
- **Assessment:** the copy and layout are clear and calm in themselves. The problem is the trigger (§2, Bug B4).

#### 08 / 09 Stock detail top, light/dark (shots 08_stock_detail_top_light, 09_stock_detail_top_dark; src: Views/StockDetailView.swift)
- **Header:**
  - A system glass back button (circle).
  - "NVIDIA Corporation" serif 24. **No ticker symbol appears in the hero**; it only shows in the collapsed pill.
  - "$" (SF Mono 20 medium, secondary) + "162.85" (SF Mono 32 bold).
  - Next to it, a saturated red gradient capsule "▼ -2.59 (-1.57%)" in white SF Pro bold 13, with a red glow.
  - Below: "🌙 Closed · 11/15 9:05 AM ET".
- **Empty band:** about 95–100 pt of empty space sits between the status line and the visible top of the line chart.
- **Chart:** edge-to-edge (`padding(.horizontal, -16)`), 250 pt, no axes or baseline. A 2 pt red line with a red@0.2→0 area fills most of the upper half of the screen (src: Views/StockDetailView.swift:1473-1604).
- **Interval row:** 1D (filled accent capsule) / 5D / 1M / 6M / YTD / 1Y / ALL, 13 pt, then a gradient accent hairline divider (src: Views/StockDetailView.swift:1335-1365, 203-213).
- **"AI Research Snapshot" card:** **title + divider + nothing** (consent was declined). See Bug B5.
- **"Fundamentals" card:**
  - A two-column grid: label 12 pt secondary + a 10 pt `questionmark.circle` at accent@0.6 + value SF Mono 14 semibold (src: Views/StockDetailView.swift:1049-1112).
  - Growth values are green ("125.2%", "83.4%"); "Revenue Growth" wraps to two lines and breaks row alignment.
  - Two columns of label/?/value pairs make four aligned text columns across about 360 pt, which is dense.
- **Tab bar overlap:** the tab bar floats over the content. "Div Yield 0.03% Beta 2.36" and "Gross Margin 74.7% Op Margin 65.2%" are partly hidden behind or below it.
- **Dark (09):** the same layout on #1C1916 / #262220 cards. The red line becomes salmon #F2736B and the white-on-#F2736B badge drops to 2.82:1.

#### 10 / 11 Stock detail scrolled (shots 10_stock_detail_scrolled_light, 11_stock_detail_scrolled2_light)
- **Sticky header:** the white `barBackground` capsule pill "NVDA $162.85 -1.57%" appears in the nav bar. Content shows faintly through the soft top edge ("Fundamentals" ghost text behind the status bar).
- **Upcoming Earnings:**
  - A calendar chip ("NOV" white 10 bold on an accent strip, "17" in 18 bold mono on subtleFill).
  - "Earnings Report" 13 semibold with an "After Close" accent pill, and "EPS Estimate: $2.52".
  - A tip box (accent@0.05, lightbulb) with **advice-like copy**: "Stock prices often move sharply around earnings dates. If you're new to investing, consider waiting until after the report to make decisions." (src: Views/StockDetailView.swift:1298-1313).
- **Key Data:**
  - Open $169.91 / Prev Close $166.19 / High $170.00 / Low $158.39 / **Volume "—"**, hard-wired to return "—" (src: Views/StockDetailView.swift:343, 444-448).
  - Day Range and 52W Range bars: a 5 pt capsule fading red@0.2→green@0.2, a 12 pt accent knob with glow, and low/high endpoint labels colored red/green (src: Views/StockDetailView.swift:360-438).
- **Analyst Recommendations:** 8 pt bars in green / green@0.6 / accent / red@0.6 / red (src: Views/StockDetailView.swift:454-489).
- **Bleed-through:** the Strong Buy green tints the tab-bar material in shot 10.
- **Related News (11):**
  - Motley Fool thumbnails are a saturated purple/navy "fi" logo cropped into 56×42.
  - Headlines render **center-aligned** across two lines; the NavigationLink has no `.buttonStyle(.plain)` (src: Views/StockDetailView.swift:499-517).
  - Third-party clickbait such as "Bloom Energy Is Down 43% From Its High. Should You Buy the Dip?"
- **Options Activity:** "Options data requires a premium data subscription." above a placeholder grid of 3 green-tinted and 3 red-tinted cells, each containing "—" (src: Views/StockDetailView.swift:532-579).
- **Ad slot:** a gray box with megaphone + "Ad" (src: Services/AdManager.swift:6-23). Stock detail has 3 of them (src: Views/StockDetailView.swift:240, 251, 262).
- **Similar Companies:**
  - 128 pt cards (AVGO $347.01, MU $778.31) with ChangeBadges and a full-width accent "+ Add" capsule.
  - The Add capsule shows through the gap between the tab capsule and the Orion button as a tan blob.
  - The back button's glass picks up a pink/purple tint from the logo scrolling under it.
- **Module count** (compact layout, src: Views/StockDetailView.swift:215-271):
  - header, chart, intervals, [holdings], divider
  - AI, Fundamentals, Earnings, Key Data, Analyst, ad, divider
  - News, Options, ad, divider
  - Peers, Comments, ad, Company Info
  - Totals: 12 content modules + 3 ads + 3 gradient dividers.

#### 12 News (shot: 12_news_light.png; src: Views/NewsView.swift)
- **Header:** "News" serif 26, "November 15" caption 12 (`en_US` hard-coded; src: Views/NewsView.swift:20-25), and a 30 pt refresh circle (ultraThinMaterial, accent `arrow.clockwise`).
- **Cards:**
  - 80×64 thumbnails (radius 10).
  - Headline 14 medium, up to 3 lines with truncation ("afte…", "cont…").
  - Time "1h ago" at 11 pt secondary@0.7 (2.40:1). The English "m ago"/"h ago" strings are hard-coded (src: Views/NewsView.swift:215-227).
  - A chevron at secondary@0.4, and no source name.
- **Thumbnails:** Reuters logo images are aspect-filled and cropped to **"REUT"** in large white letters on black. Three consecutive cards show it.
- **Ads:** the "Ad" placeholder repeats after every 5 items (src: Views/NewsView.swift:103-106).
- **Content:** general and geopolitical (Rivian/Lucid policy, flight delays, US midterms, Yemen, Iran/Bahrain attacks, Saudi missile intercepts), not portfolio- or market-specific. The feed is visually heavy with dark Reuters blocks.

#### 13 Gurus (shot: 13_gurus_light.png; src: Views/InvestorsView.swift)
- **Header:** "Guru Portfolios" serif 26 and "SEC 13F filings from top investors" caption 12.
- **Cards:** seven identical cards. Each has a 48 pt monogram circle (serif bold 16 initials in accent on a light accent fill), name serifHeadline 16, firm caption 12, and tagline caption 11 at secondary@0.6 (**2.08:1**). A "13F" accent capsule (10 pt) is stacked above a chevron at secondary@0.4 (src: Views/InvestorsView.swift:55-103).
- **Overall:** the most consistent and quiet screen.
- **Tone:** taglines lean on celebrity ("The Big Short", "The Man Who Broke the Bank of England", "Distressed Debt King").

#### 14 / 15 More, light/dark (shots 14_more_light, 15_more_dark; src: Views/MenuView.swift)
- **Layout:** no page title. An insetGrouped List with a hidden scroll background.
- **Profile card:** a 60 pt `person.circle.fill` in accent and "User" serif 18. The guest has no email, so the caption is blank and the right side of the card is empty (src: Views/MenuView.swift:21-39).
- **Settings rows:** accent SF Symbols in a mix of outline and filled styles (building.columns, doc.text.magnifyingglass, dollarsign.circle, paintbrush, bell.badge, globe, star.circle, shield.checkered, sparkles, arrow.left.arrow.right, chart.line.uptrend.xyaxis). Text is the default 17 pt body, with .subheadline detail values.
- **Double chevrons ("> >")** on Linked Accounts, Tax Assistant and Notifications (Bug B6).
- **Bleed-through:** Paper Trading's detail text bleeds through the gap between the tab capsules as ")C".
- **AI Data Sharing:** the toggle sits below the fold.
- **Dark (15):** the cards (#262220) read well. The off-state toggle shows a white knob.
- **Count:** 17 rows plus Log Out (src: Views/MenuView.swift:42-178).

#### 16 / 17 Orion AI chat list, light/dark (shots 16_orion_chat_light, 17_orion_chat_dark; src: Views/ChatView.swift:17-110)
- **Header:** "Orion AI" serif 22 at a 16 pt margin, which is smaller and shifted left compared with News/Gurus (26 pt, 20 pt margin). The compose icon (`square.and.pencil`, .title3) is **primaryText-colored**, while the News refresh icon is accent (inconsistent).
- **Empty state:** two concentric circles (120 pt @0.08 and 80 pt @0.12), bubble icon 32 light, "No conversations yet" serif 18, "Ask Orion anything about stocks, markets, or investing" (.subheadline) and "+ Start a new chat" caramel capsule with glow.
- **Space:** about 235 pt of empty space between the header and the illustration, and no example prompts.
- **Tab state:** the Orion tab is a filled accent capsule.
- **Dark (17):** the accent #D4A574 carries white text at **2.23:1**, and the selected Orion capsule has an accent glow.
- **Conversation view (code only):**
  - User bubbles are accent@0.12; AI bubbles are white with a 0.5 pt border, radius 18, 15 pt text and a 28 pt sparkles avatar.
  - The input bar is ultraThinMaterial with **5 icon buttons** (photo, doc, mic, video, send) at 18–20 pt with 6 pt spacing, around a `.roundedBorder` system text field (src: Views/ChatView.swift:253-298, 518-588).
  - The voice-chat screen switches to a blue/purple orb on a near-black navy gradient, off-brand (src: Views/ChatView.swift:604-664).

#### Code-only screens (not reachable as guest / not captured)
- **Home with holdings** (src: Views/MyHoldingView.swift:665-819, 1192-1224):
  - Pinned header: "My Net Worth" 11 medium; a currency symbol (16 mono medium, secondary) + value (24 mono bold, numericText); P&L 12 mono semibold red/green; "Today ±…" 11.
  - Right-hand controls: an "Accounts" accent@0.12 capsule pill, a USD|CAD toggle and a 34×27 eye button.
  - A 110 pt chart with a dashed gray cost-basis line.
  - Intervals 1D/5D/1M/6M/1Y as 10 pt radius-6 rects (filled accent / subtleFill). This differs from stock detail's 7 capsule intervals at 13 pt and NetWorthChartModule's 11 pt radius-6 pills (src: Views/NetWorthChartModule.swift:303-312).
  - Hide-values mode swaps the chart for a gray placeholder curve.
- **Accounts page, HoldingsListPage** (src: Views/MyHoldingView.swift:1264-1500):
  - System inline title "Accounts", then NetWorthChartModule (28 pt mono total, 180 pt chart, 6-hue institution lines, "Split" toggle), SyncHealthBanner, TaxAssistantCard, one card per account and a "Link your accounts" card.
  - Institution names are accent Labels at 12 pt semibold; holdings rows show symbol 14 bold, shares 11 and value 14 mono.
  - Empty state: just "No accounts linked yet" in a 13 pt caption.
- **Tax Assistant:** a system nav title and long explanatory paragraphs (e.g. the superficial-loss rule; src: Views/TaxCenterView.swift:70, 161). Progress bars are tinted accent, or warning red when over the limit.
- **Linked Accounts:** "See your real holdings" serif 18, a long trust paragraph, two spinners and a "Something went wrong" alert (src: Views/LinkedAccountsView.swift:129-235).

#### Copy-tone inventory (where 从容 is undercut or advice is implied)
- Hype or attention framing:
  - "Hot" tab with a flame (src: Views/MyHoldingView.swift:62, 69)
  - "Ready for a new trading day?" (src: Services/AppTheme.swift:191)
  - "Markets are moving — stay informed" (src: Services/AppTheme.swift:195)
  - "Help Me Pick Stocks" (src: Views/MyHoldingView.swift:439)
  - "Start building your constellation of investments" (src: Views/MyHoldingView.swift:414)
- Advice-adjacent copy:
  - risk-result "We'll suggest/focus/highlight…" (src: Views/RiskProfileView.swift:103-109)
  - earnings tip "consider waiting…" (src: Views/StockDetailView.swift:1304)
  - AI snapshot pieces (src: Views/StockDetailView.swift:797-1018): rating badge colored by "buy"/"sell" keywords (src: Views/StockDetailView.swift:1020-1025), 0–100 score ring, "Bullish Factors"/"Bearish Factors", "What to Watch"
- Disclaimers already present:
  - "Popular names in your interests · not a recommendation" (src: Views/MyHoldingView.swift:1051)
  - "AI-generated research summary for education. Not a recommendation to buy or sell." (src: Views/StockDetailView.swift:971)
  - Portfolio Wizard "not a recommendation" (src: Views/PortfolioWizardView.swift:281)
  - The Disclaimer sheet (src: Views/MenuView.swift:277-280)
- Price targets (entry/stop/target) were deliberately disabled with `if false` (src: Views/StockDetailView.swift:829-830).

### Inferences
- **Premium feel:** the serif titles, warm neutrals and generous card radius already signal "considered". What lowers the feel:
  - visible placeholders (?, Ad, options, "—", empty AI card)
  - generic icons (globe for Google, identical building tiles)
  - bleed-through artifacts at the tab bar
  - mixed numeric typography in the hero (SF Mono price next to an SF Pro badge)
  - per-card decoration (accent bar + icon + serif title on all 12 modules)
  - third-party imagery (REUT crops, purple logos)
- **Calm:** what works against it:
  - motion that never stops (marquee, constellation)
  - saturated red/green surfaces (hero pill with glow, filled red area chart, red→green range bars)
  - three or four competing primary actions on home
  - an unrequested modal
  - contradictory or "trading-day" copy on a closed-market Sunday
  - a general-news feed heavy on conflict
- **Quietest screens:** Gurus (13) and More (14/15) are the most composed and could serve as internal reference points for density and consistency.

### Gaps
- I couldn't confirm whether the "?" boxes for emoji reproduce on a physical device. They may be specific to the simulator's font set, but either way the emoji are a style mismatch.
- Not captured: home with holdings, the Accounts page, the chat conversation view, the AI dashboard in its loaded state, the Gemini voice/video screens, Interests onboarding, Portfolio Builder, Paper Trading, Compare and the iPad/landscape layouts.
- The root cause of the empty band above the stock chart isn't confirmed (see B17).

## 4. Accessibility basics (Dynamic Type, contrast, Reduce Motion, tap targets)

### Takeaway
Roughly 80% of font declarations are fixed point sizes that won't scale with Dynamic Type. The most-used text color (secondaryText, 242 uses) fails 4.5:1 on the beige background (3.46:1), and its faded variants fall to 1.6–2.4:1. White-on-caramel CTAs measure 2.67:1 in light mode and 2.23:1 in dark. Neither Reduce Motion nor Reduce Transparency is checked anywhere. There are only 5 `accessibilityLabel`s, and several controls are well under 44 pt.

### Cited Findings
- **Dynamic Type:**
  - 261 `.system(size:)` sites plus 185 fixed-size AppTheme helper calls (caption 75, number 80, serifHeadline 18, serifTitle 11, body 1) give **≈446 fixed-size declarations**, against **≈103 text-style declarations**.
  - The helpers themselves wrap `.system(size:)` (src: Services/AppTheme.swift:92-120). The CJK serif path builds a `UIFont` at a fixed size (src: Services/AppTheme.swift:127-160).
  - 0 uses of `@ScaledMetric` or `dynamicTypeSize`.
  - Mixed within one header: the home greeting subtitle uses `.subheadline` (scales) while the date beside it is fixed at 11 pt (src: Views/MyHoldingView.swift:113-119).
- **Contrast** (computed from token hex; light unless noted):

  | Pair | Ratio |
  |---|---|
  | primaryText on bg | 13.51:1 |
  | secondaryText on bg | **3.46:1** |
  | secondaryText on white card | 3.86:1 |
  | secondaryText on subtleFill pill | 3.19:1 |
  | secondary@0.7 on bg (home date) | **2.25:1** |
  | secondary@0.7 on white (news time) | 2.40:1 |
  | secondary@0.6 on white (guru tagline) | **2.08:1** |
  | secondary@0.5 on bg (Skip Login, Ad label) | **1.74:1** |
  | secondary@0.4 on white (chevrons) | 1.59:1 |
  | accent text on bg | **2.40:1** (accent labels, selected tab, Sign Up) |
  | accent text on white | 2.67:1 |
  | white on accent (all caramel buttons) | **2.67:1** |
  | positive #4CB07D on white | **2.69:1** |
  | negative #E35C5C on white | 3.53:1 |
  | white on negative (stock hero pill) | 3.53:1 |
  | negative on its 10% badge fill | 3.14:1 |
  | positive on its 10% badge fill | **2.46:1** |
  | Dark: primaryText | 14.77:1 |
  | Dark: secondary on bg / on card | 5.60:1 / 5.04:1 |
  | Dark: accent on bg | 7.86:1 |
  | Dark: **white on accent** | **2.23:1** |
  | Dark: positive on card / negative on card | 7.56:1 / 5.59:1 |
  | Dark: white on negative pill | 2.82:1 |

- **Non-text contrast:** dark subtleFill vs dark card is 1.05:1, which makes pills invisible in shot 04. Light subtleFill vs white card is 1.21:1. Light border vs bg is 1.20:1.
- **Reduce Motion / Transparency:** 0 references to `accessibilityReduceMotion` / `reduceMotion` (grep). None of the 7 `repeatForever` loops, the marquee, the parallax blur or the springs are conditional. The 7 `.ultraThinMaterial` surfaces have no Reduce Transparency fallback.
- **Labels:** 5 `accessibilityLabel` and 4 other accessibility modifiers across the codebase. Icon-only controls without labels include the FAB "+" (src: Views/MyHoldingView.swift:163-173), News refresh (src: Views/NewsView.swift:36-42), chat compose (src: Views/ChatView.swift:30-34) and the 5 chat input-bar icons (src: Views/ChatView.swift:255-290). Sparklines and the placeholder chart are correctly `accessibilityHidden` (src: Views/Sparkline.swift:28; Views/MyHoldingView.swift:1258).
- **Color-only signals:** ChangeBadge pairs color with an arrow icon and sign, and the hero pill has ▲/▼. Range-bar endpoint labels (low red / high green) and the Calls/Puts tints rely on color alone (src: Views/StockDetailView.swift:364-374, 544-566).
- **Tap targets** (estimated from code geometry):

  | Control | Approx. size | src |
  |---|---|---|
  | HideValuesButton | 34×27 pt | Views/MyHoldingView.swift:1149 |
  | Home chart interval pills (10 pt text, 8×4 padding) | ≈30×20 pt | Views/MyHoldingView.swift:788-798 |
  | Today's Market pills (11 pt, 9×5 padding) | ≈24 pt tall | Views/MyHoldingView.swift:841-852 |
  | USD/CAD toggle (11 pt, 10×5 padding) | ≈25 pt tall | Views/MyHoldingView.swift:1170-1178 |
  | News refresh (14 pt icon + 8 padding) | ≈30 pt | Views/NewsView.swift:37-41 |
  | RecommendationCard add (20 pt glyph, no frame) | — | Views/MyHoldingView.swift:2094-2098 |
  | Chat input-bar icons (18–20 pt glyphs, 6 pt spacing, no frames) | — | Views/ChatView.swift:253-291 |
  | Collapsed tab bar | 46 pt | ContentView.swift:370 |
  | Stock interval pills (13 pt, 12×7 padding) | ≈30 pt tall | Views/StockDetailView.swift:1347-1350 |

### Inferences
- The secondary-text color is used for meaningful information (dates, timestamps, labels, subtitles), and its 0.4–0.7 opacity variants push that information to about 2:1. Low contrast reads as "soft" on a warm background, but here it is unreadable.
- The caramel-with-white-text CTA (2.67:1 light, 2.23:1 dark) is the brand's primary action color. Any palette refinement should probably start there.
- Fixed type sizes and an always-moving top strip also matter for older or low-vision users, a likely segment for a "calm, beginner-friendly" finance app. That is an inference, not measured.

### Gaps
- I didn't run the app with large Dynamic Type sizes, VoiceOver, Reduce Motion or Increase Contrast, so the effects are inferred from code.
- Tap-target sizes are estimated from font and padding values, not measured in the view hierarchy.
- The 44 pt minimum and 4.5:1 / 3:1 thresholds are standard WCAG/HIG figures that I didn't re-fetch for this note.

## 5. Concrete bugs and defects (separate from taste)

### Takeaway
Fifteen issues are clearly defects: wrong or missing rendering, wrong data, silent failures, or flows that misbehave. Several more are placeholder content shipped to users. These should be fixed regardless of any redesign direction.

### Cited Findings

#### Defects
- **B1. Risk-quiz option icons render as "?" boxes.** Emoji `Text` at 28 pt (shot: 01, 01b, 01c; src: Views/RiskProfileView.swift:44-86, 264-265).
- **B2. Risk-quiz question transition overlaps.** Old and new question text, icons and option labels crossfade on top of each other because the page swap happens inside `withAnimation` with the same view identity (shot: 01c; src: Views/RiskProfileView.swift:117-124, 208-231).
- **B3. Adding a stock fails silently.**
  - The sheet dismisses before the network call (src: Views/MyHoldingView.swift:183-186).
  - On error, only `Haptic.error()` and a `print` happen (src: Views/MyHoldingView.swift:606-608). The duplicate guard also returns silently (src: Views/MyHoldingView.swift:592).
  - Result in shot 06: no feedback, empty watchlist.
  - Separately, the peer-card "Add" calls `addStockToWatchlist` with no feedback or state change (src: Views/StockDetailView.swift:619-635).
- **B4. AI consent sheet auto-presents on stock-detail open.** It can't be swiped away (`isModalInPresentation = true`). After "Not now" it comes back on every later visit and every fundamentals tap, because only `granted == true` short-circuits (shot: 07; src: Views/StockDetailView.swift:1735; Services/APIService.swift:1007; Services/AIConsent.swift:35-67).
- **B5. Empty "AI Research Snapshot" card.** When consent is declined or the AI call fails, the card still renders (title + divider, empty body) because the module has no branch for "not loading and no data", and errors are swallowed (shot: 08, 09; src: Views/StockDetailView.swift:791-1017, 1782-1784).
- **B6. Double chevrons in More.** A NavigationLink adds a system disclosure on top of `menuRow`'s own chevron (shot: 14, 15; src: Views/MenuView.swift:44-59, 86-92, 125-130, 250-252).
- **B7. Dead More rows.** "Share", "Support", "Contact" and "Copyright Info" show chevrons but have no action (src: Views/MenuView.swift:158-165).
- **B8. Day change disagrees between screens.**
  - Stock detail shows NVDA "-2.59 (-1.57%)" (shot: 08), but home Today's Market shows NVDA -2.01% (shot: 05).
  - Key Data's own numbers (price $162.85, Prev Close $166.19; shot: 10) give -3.34 / -2.01%.
  - Cause: the hero computes change as last minus *first chart bar*, not against previous close (src: Views/StockDetailView.swift:61-67, 1407-1408).
- **B9. Status line shows "now", not the last-trade time.** "Closed · 11/15 9:05 AM ET" uses `Date()`, so on a Sunday it implies a Sunday-morning price (shot: 08; src: Views/StockDetailView.swift:93-105).
- **B10. Ticker labels ETF prices as indexes.** "S&P 500 754.37" and "NASDAQ 679.89" are SPY/QQQ, and "Dow Jones" is DIA (shot: 05; src: Views/MyHoldingView.swift:507).
- **B11. Contradictory greeting.** "Ready for a new trading day?" appears above "Markets are closed today — enjoy your Sunday" (shot: 05; src: Services/AppTheme.swift:183-213 vs 314-331).
- **B12. Hard seam at the Today's Market right edge.** The fade uses `cardBackground` (#FFFFFF) while the card surface is a #FFFFFF→#F7F2ED gradient. This makes a visible white block that also hides the NU change badge (shot: 05, pixel-verified; src: Views/MyHoldingView.swift:889-895; Services/AppTheme.swift:344).
- **B13. Content hidden under the floating tab bar.**
  - The empty-state "Help Me Pick Stocks" button sits behind the bar; its outline shows as a tan arc in the 10 pt gap between the two tab capsules (shot: 05, 06; src: Views/MyHoldingView.swift:435-449; ContentView.swift:316-360).
  - The same gap shows the peer "Add" button (shot: 11) and Paper Trading row text (shot: 14).
  - Fundamentals rows are partly hidden behind the bar (shot: 08).
- **B14. Dark-mode pills are invisible.** subtleFill #2A2622 on card #262220 = 1.05:1 (shot: 04 Gainers/Losers and the sheet's category pills).
- **B15. Hard-coded English and locale.**
  - `en_US` date formatters (src: Views/MyHoldingView.swift:81-86; Views/NewsView.swift:20-25).
  - "m ago"/"h ago" strings (src: Views/NewsView.swift:215-227).
  - Literals "Orion Finance" (src: Views/LoginView.swift:49), "Ad" (src: Services/AdManager.swift:15) and "13F".
  - Market status uses an `M/d h:mm a` format (src: Views/StockDetailView.swift:96).

#### Shipped placeholders / incomplete features
- **B16. Options Activity placeholder grid** with "requires a premium data subscription" (shot: 11; src: Views/StockDetailView.swift:532-579).
- **B17. Volume hard-coded to "—"** (shot: 10; src: Views/StockDetailView.swift:444-448).
- **B18. "Ad" placeholder boxes:** 3 per stock detail and 1 per 5 news items (shot: 11, 12; src: Services/AdManager.swift:3-23).
- **B19. Stock price shows the word "Loading..."** in the 32 pt hero numeral style while loading (src: Views/StockDetailView.swift:118-120).

#### Probable defects (cause inferred from code; verify)
- **B20. Chart is cropped at both screen edges.** The stock chart is laid out 16 pt wider than the screen on each side (`.padding(.horizontal, -16)` on a full-width chart), so the first and last ~16 pt of the line, including the latest price and the LivePulseDot position, fall off-screen (src: Views/StockDetailView.swift:1585-1586; shot 08 shows the line leaving the right edge while still rising). This may also explain the empty band above the visible line.
- **B21. Centered headlines in stock-detail news.** Default NavigationLink button styling centers multi-line text (shot: 11; src: Views/StockDetailView.swift:499-517).
- **B22. Reuters thumbnails cropped to "REUT".** `aspectRatio(.fill)` into 80×64 crops wide logo images (shot: 12; src: Views/NewsView.swift:159-167).

#### Code-hygiene items that feed inconsistency (not user-visible bugs)
- Unused: `accentDark` token, `AppTheme.cardShadow()`, `BubbleShape`, `StaggeredItem`. Animation tokens are effectively unused (§1, §2).
- `warning` is aliased to `negative` (src: Services/AppTheme.swift:41).
- The refresh tint is hard-coded, off-token and not adaptive (src: Views/Components/OrionRefreshView.swift:10).

### Inferences
- B4 (consent nag) and B3 (silent failure) are the two most damaging to calm. One interrupts without being asked; the other leaves the user unsure whether an action worked.
- B8–B11 are trust defects: wrong or contradictory numbers and labels in a finance app.
- B1, B5, B6, B12, B13 and B16–B19 are the main premium-feel defects: visible seams, placeholders and duplicated chrome.

### Gaps
- I didn't check whether B3's failure in shot 06 came from network/API limits in the simulator or from a logic error. The code only shows that failures produce no UI.
- B20/B21 causes are inferred, not confirmed with the view debugger.
- I didn't audit iPad/landscape layouts (NavigationSplitView sidebar, landscape side rail) for these defects.
