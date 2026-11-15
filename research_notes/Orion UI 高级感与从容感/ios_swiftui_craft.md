# iOS / SwiftUI Design Craft for a Premium, Refined, Calm App (iOS 26 "Liquid Glass" era, as of Nov 2026)

Scope note for the report writer: Apple HIG pages were read through their JSON data endpoints (developer.apple.com/tutorials/data/design/human-interface-guidelines/<page>.json). Citations below use the canonical HIG URLs. "Apple official" means HIG, WWDC transcripts, or developer documentation. "Community" means third-party writers and is labeled as such. Items marked **[iOS 26 change]** were introduced or changed with the June 2025 Liquid Glass redesign or in later HIG updates.

The audited app uses: a custom serif headline font plus SF Pro body; a custom capsule tab bar on `.ultraThinMaterial`; rounded cards with drop shadows and gradient fills; a custom auto-scrolling market ticker; Swift Charts line charts; SF Symbols; haptics on many taps; and `contentTransition(.numericText())`. Inferences tie findings back to those features.

---

## 1. Typography: text styles, optical sizes, tracking, serif use, custom fonts

### Takeaway
Apple's rule is to use the built-in text styles, which give Dynamic Type, automatic optical sizing and automatic tracking. Keep the number of typefaces small, and avoid Light, Thin and Ultralight weights. A custom serif headline font is allowed, but it has to scale with Dynamic Type (`.custom(_:size:relativeTo:)`), and it doesn't get Apple's automatic tracking tables. New York, the system serif, is available with `.fontDesign(.serif)`. **[iOS 26 change]** Type is now bolder and left-aligned in key moments such as alerts and onboarding.

### Cited Findings
- **iOS/iPadOS Dynamic Type sizes at the default (Large) setting.** Columns are style, weight, size and leading in pt, followed by the emphasized weight:
  - Large Title: Regular, 34/41, emphasized Bold
  - Title 1: Regular, 28/34, emphasized Bold
  - Title 2: Regular, 22/28, emphasized Bold
  - Title 3: Regular, 20/25, emphasized Semibold
  - Headline: Semibold, 17/22, emphasized Semibold
  - Body: Regular, 17/22, emphasized Semibold
  - Callout: Regular, 16/21, emphasized Semibold
  - Subhead: Regular, 15/20, emphasized Semibold
  - Footnote: Regular, 13/18, emphasized Semibold
  - Caption 1: Regular, 12/16, emphasized Semibold
  - Caption 2: Regular, 11/13, emphasized Semibold

  Source: [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- The iOS/iPadOS default text size is **17 pt** and the minimum is **11 pt**. — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- **[iOS 26-era HIG update]** The page metadata records a 2025-12-16 alert: "Added emphasized weights to the Dynamic Type style specifications for each platform." — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- On weights: "avoid Ultralight, Thin, and Light font weights, which can be difficult to see, especially when text is small". The HIG prefers Regular, Medium, Semibold or Bold. — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- On typeface count: "Minimize the number of typefaces you use, even in a highly customized interface. Mixing too many different typefaces can obscure your information hierarchy…" — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- New York "is a serif typeface family designed to work well by itself and alongside the SF fonts". iOS apps can use it, and the developer note says to "use serif to get the New York font" (SwiftUI `.fontDesign(.serif)` / `Font.Design.serif`). — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- On custom fonts: "System fonts automatically support Dynamic Type… and respond when people turn on accessibility features, such as Bold Text. If you use a custom font, make sure it implements the same behaviors." — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- **Optical sizes.** The system fonts use "dynamic optical sizes, which merge discrete optical sizes (like Text and Display)… into a single, continuous design". In code you don't pick Text or Display. The system "dynamically adjusts tracking at every point size". — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- Historically, "SF Text for small sizes below 20 points and SF Display for 20 points and above". Since the 2020 variable SF Pro, "There is no hard break around 20 points anymore and the design now transitions from Text to Display between 17 and 28 points." — [WWDC20 "The details of UI typography"](https://developer.apple.com/videos/play/wwdc2020/10175/)
- **Tracking.** Apple publishes tracking tables in the Apple Design Resources. Third-party fonts get automatic tracking only if the font vendor adds tracking tables and a STAT table. Custom tracking should be size-specific: "a tracking you provided for small sizes may not look good on large sizes." SwiftUI provides `Text(...).tracking(-0.5)` and `.allowsTightening(true)`. Use the tracking API rather than kerning. — [WWDC20 "The details of UI typography"](https://developer.apple.com/videos/play/wwdc2020/10175/)
- **Leading.** On iOS, tight leading reduces line height by 2 pt and loose leading increases it by 2 pt. For example, Body's 22 pt becomes 20 pt (tight) or 24 pt (loose). SwiftUI supports leading adjustments for text-style fonts. — [WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)
- **Custom fonts in SwiftUI.** `Text("…").font(.custom("Avenir-Medium", size: 34, relativeTo: .title))` scales against the given style. Without `relativeTo:` the font scales relative to body. `.custom(_, fixedSize:)` never scales. `@ScaledMetric(relativeTo: .body) var padding: CGFloat = 20` scales constants such as padding with Dynamic Type. — [WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)
- **Design variants.** "When picking a text style with a design, everything else besides the design stays the same, including font size, weight and line height". The talk's example is `Font.system(.body, design: .rounded)`, and `.serif` gives New York while `.monospaced` gives SF Mono. — [WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)
- Guiding principle: "You should only override the default system behavior in exceptional cases, and let the system do the right thing for you for the rest of them." — [WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)
- **[iOS 26 change]** Type is "now bolder and left-aligned to improve readability in key moments like alerts and onboarding." — [WWDC25 "Get to know the new design system"](https://developer.apple.com/videos/play/wwdc2025/356/)
- Dynamic Type should allow text enlargement of "at least 200 percent". — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

### Inferences
- The custom serif headline font plus SF Pro body pairing is acceptable under the "minimize typefaces" rule, since two families is the practical ceiling. Every headline use should still map to a text style through `.custom(name, size: X, relativeTo: .largeTitle / .title / .title2 …)`. Sizes should match the table above (34, 28, 22, 20), and line height should follow the paired style.
- A custom serif doesn't get Apple's automatic per-size tracking, so large display sizes (28 pt and up) often need slightly negative `.tracking`, tuned per size. Alternatively, New York (`.fontDesign(.serif)`) gets automatic optical sizing and tracking. Use `.fontDesign(.serif)` if the custom font has no optical-size axis or tracking tables.
- Paddings around text, such as card insets, should use `@ScaledMetric` so the layout breathes correctly at large Dynamic Type sizes.
- Any hard-coded `.font(.system(size: N))` without a text style is a red flag in an audit.

### Gaps
- The HIG's numeric "Tracking values" table for SF Pro wasn't read; that part of the JSON was truncated. It is published in the Apple Design Resources.
- `.fontWidth(.condensed/.expanded)` (SF Pro width variants, iOS 16+) wasn't checked against an Apple source this session, and no HIG guidance on width variants was found.

---

## 2. Number and data typography (prices, percentages, tickers)

### Takeaway
For values that change in place, Apple's documented mechanism is `contentTransition(.numericText(...))` inside an animation context. Community practice pairs it with `.monospacedDigit()` so digits keep a fixed width and the layout doesn't jitter. No Apple guidance was found on de-emphasizing currency symbols or decimals; that is a design choice.

### Cited Findings
- "Content transitions only take effect within the context of an Animation block." Wrap the change in `withAnimation` or use `.animation(_:value:)`. — [Apple ContentTransition docs](https://developer.apple.com/documentation/swiftui/contenttransition)
- Apple's WidgetKit guidance recommends `numericText(countsDown:)` for timer or count text so digits roll in the right direction. — [Apple: Animating data updates in widgets and Live Activities](https://developer.apple.com/tutorials/data/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities.md)
- Community pattern: `.contentTransition(.numericText(value: value))`, which tells the transition which direction the number moved, combined with `.monospacedDigit()` so each digit has the same width and nothing shifts. — [Create with Swift: Animating numeric text](https://createwithswift.com/animating-numeric-text-in-swiftui-with-the-content-transition-modifier); [Design+Code handbook: numeric text animation](https://designcode.io/swiftui-handbook-numeric-text-animation-using-contenttransition); [Michael Tsai: Monospaced digits in SwiftUI](https://mjtsai.com/blog/2022/09/28/monospaced-digits-in-swiftui)
- A forum report describes high CPU use when `.animation` repeatedly triggers `.numericText()` on a fast-updating clock. The cause wasn't confirmed. — [Apple Developer Forums thread 733047](https://developer.apple.com/forums/thread/733047)
- Rounded and monospaced designs keep the text style's size, weight and line height. — [WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)

### Inferences
- In a market app, any column or ticker of prices should use `.monospacedDigit()`. This keeps proportional SF Pro letters while making figures tabular, so decimals line up and values don't jitter on update. SF Mono (`.monospaced`) changes the look of the letters too and is usually unnecessary.
- `numericText` rolls should run only on meaningful updates, not on every tick of a fast stream. Throttle or batch updates, or drop the transition for live-streaming values. Rolling digits that never stop work against a calm feel and can cost CPU.
- To de-emphasize currency symbols and trailing decimals (design practice, not Apple guidance), combine `Text` pieces or use `AttributedString`: the main digits in the primary style, and the symbol or decimals in `.secondary` foreground style or a smaller text style. All pieces should keep `.monospacedDigit()`.
- A custom serif font for large hero numbers needs its own tabular figures (OpenType `tnum`). Otherwise `.monospacedDigit()` may have no effect. Check this in the audit.

### Gaps
- No Apple HIG text was found on number formatting, currency-symbol scale, or decimal de-emphasis.
- Whether `.monospacedDigit()` works with a given custom font depends on that font's OpenType features. This wasn't verified.

---

## 3. Layout, spacing, safe areas, hit targets

### Takeaway
Apple asks for consistent spacing and alignment, respect for safe areas and system layout guides, and grouping through negative space and containers. Apple publishes hard numbers for hit targets and control padding: 44×44 pt default, 28×28 pt minimum, about 12 pt of padding around bezeled elements and about 24 pt around non-bezeled ones. The HIG layout page doesn't state iOS margin values.

### Cited Findings
- "Respecting the safe area is essential to make sure system UI and hardware features like the Dynamic Island don't obstruct content and controls." — [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- "The system includes predefined layout guides that make it easy to apply standard margins around content and restrict the width of text for optimal readability." — [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- "Use consistent spacing. When content isn't consistently spaced, it no longer looks like a grid and it's harder for people to scan." — [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- "Group related items… you might use negative space, container shapes, or separator lines". "Align elements to make them easier to scan, and use indentation to convey hierarchy." — [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- **[iOS 26 change]** "Instead of applying a solid or semi-opaque background color beneath controls, use a scroll edge effect to visually elevate controls above content." Full-screen background content should extend under sidebars, toolbars and tab bars. — [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- HIG Layout change log: June 9, 2025, "Added guidance for Liquid Glass". September 9, 2026, "Updated guidance to reflect current best practices." — [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- On iOS and iPadOS the default control size is **44×44 pt** and the minimum is **28×28 pt**. Add "about 12 points of padding around elements that include a bezel" and "about 24 points" around elements without one. — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- On optical balance, views are "mathematically centered when it makes sense — and subtly offset when it doesn't." — [WWDC25 "Get to know the new design system"](https://developer.apple.com/videos/play/wwdc2025/356/)
- "Instead of relying on decoration, hierarchy should be expressed through layout and grouping." — [WWDC25 "Get to know the new design system"](https://developer.apple.com/videos/play/wwdc2025/356/)
- Fluid-interface tap targets: "add an extra margin around the tap area". Gesture hysteresis "is usually 10 points in iOS". — [WWDC18 "Designing Fluid Interfaces"](https://developer.apple.com/videos/play/wwdc2018/803/)

### Inferences
- A spacing-token scale such as 4/8/12/16/20/24/32 is a common practice that fits the HIG's "consistent spacing" rule and its 12/24 pt padding figures. The specific scale is not Apple-mandated.
- Small icon-only buttons on cards, including ticker items, need at least a 44×44 pt hit area even if the glyph is smaller. In SwiftUI, use `.contentShape(Rectangle())` with a `.frame(minWidth: 44, minHeight: 44)`.
- "Hierarchy through layout and grouping, not decoration" bears directly on the shadowed gradient cards. Spacing, grouping and type weight should carry the hierarchy before shadows or gradients do.

### Gaps
- The HIG layout page gives **no numeric iOS margins**. The widely cited 16 pt (most iPhones) and 20 pt (larger or regular-width) values come from UIKit `systemMinimumLayoutMargins` and `readableContentGuide`. They weren't verified against an Apple source this session. SwiftUI's default `.padding()` value also wasn't verified.

---

## 4. Corner radii, continuous corners, and concentricity [iOS 26 change]

### Takeaway
iOS 26 formalizes three shape types: fixed, capsule and concentric. The concentric rule is **inner radius = outer radius − padding**, and SwiftUI computes it with `ConcentricRectangle` and `.containerShape(...)` (iOS 26+). Mismatched nested radii read as "pinched" or "flared".

### Cited Findings
- Apple defines three shape types. "fixed shapes have a constant corner radius". "Capsules use a radius that's half the height of the container". "concentric shapes calculate their radius by subtracting padding from the parent's." — [WWDC25 "Get to know the new design system"](https://developer.apple.com/videos/play/wwdc2025/356/)
- Watch for corners that "feel too pinched — or flared," because they "create tension and break the sense of balance". Nested containers, such as artwork in a card, should use concentric shapes. — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- On iPhone, use a capsule with extra margin near the screen edge. For components that appear both nested and standalone, use a concentric shape with a fallback radius: "The concentric value adapts when nested, and the fallback kicks in when the component stands alone." — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- Touch-friendly layouts use capsules, which are "best used for standout actions" in dense desktop contexts. — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- **API.** `containerShape(_:)` takes a `RoundedRectangularShape`, and a `ConcentricRectangle` inside it gets corners concentric with the container. `ConcentricRectangle.init()` is iOS 26.0+. — [Apple containerShape docs](https://developer.apple.com/documentation/swiftui/view/containershape(_:)); [Apple ConcentricRectangle docs](https://developer.apple.com/documentation/swiftui/concentricrectangle)
- Community worked example: set `.containerShape(.rect(cornerRadius: 24))` on the card and use `ConcentricRectangle(corners: .concentric, isUniform: true)` inside it with `.padding(12)`, which gives an inner radius 12 pt smaller. Use `.rect(corners: .concentric(minimum: 24), isUniform: true)` so corners never collapse to 0. At the app root or in a full-screen cover the container is the device display shape, and sheets give their own container shape. `isUniform: true` is recommended for cards. — [Nil Coalescing: Corner concentricity in SwiftUI on iOS 26](https://nilcoalescing.com/blog/ConcentricRectangleInSwiftUI) (community)
- If the container shape isn't a `RoundedRectangularShape`, `ConcentricRectangle` falls back to `ContainerRelativeShape`. `RoundedRectangle`, `Capsule` and `Circle` conform. — [Nil Coalescing](https://nilcoalescing.com/blog/ConcentricRectangleInSwiftUI) (community)
- `glassEffect(_:in:)` defaults to a `Capsule`, and Apple suggests "a rounded rectangle if you're applying the effect to larger components that would look odd as a Capsule". — [Apple: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

### Inferences
- Audit rule: for every card containing an inner element with a background (chart plot area, image, pill or inner tile), check inner radius = outer radius − inset. Example: a card radius of 24 with a 12 pt inset gives an inner radius of 12.
- Use `RoundedRectangle(cornerRadius:, style: .continuous)` or `.rect(cornerRadius:)` for the squircle look. A circular `.cornerRadius()` is deprecated and looks less native (not verified this session; see Gaps).
- The tab bar capsules are already the shape Apple prescribes for touch controls. The issue is the material and behavior, not the shape (see section 7).

### Gaps
- The default corner style of SwiftUI's `.rect(cornerRadius:)` / `RoundedRectangle` (continuous vs circular) wasn't confirmed this session, nor was the deprecation status of `.cornerRadius(_:)`.
- No Apple-published numeric radius scale for cards was found.

---

## 5. Color and contrast

### Takeaway
Use semantic and dynamic system colors, especially system or grouped background colors for hierarchy, rather than hard-coded values. Keep color sparing. In iOS 26, decorative color belongs in the content layer, while Liquid Glass controls stay mostly monochrome with tint only on the primary action. Minimum contrast is 4.5:1 for text up to 17 pt and 3:1 for 18 pt and larger or bold text.

### Cited Findings
- "Avoid hard-coding system color values in your app… The actual color values may fluctuate from release to release". — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- iOS defines *system* and *grouped* background sets, each with primary, secondary and tertiary levels. Use grouped (`systemGroupedBackground`, `secondarySystemGroupedBackground`, `tertiarySystemGroupedBackground`) for grouped layouts and the system set otherwise. Primary is for the overall view, secondary for grouping inside it, and tertiary for grouping inside secondary elements. — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- "Avoid redefining the semantic meanings of dynamic system colors… don't use the separator color as a text color, or secondary label color as a background color." — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- **[iOS 26 change]** "Apply color sparingly to the Liquid Glass material… reserve it for elements that truly benefit from emphasis, such as status indicators or primary actions… apply color to the background rather than to symbols or text… Refrain from adding color to the background of multiple controls." — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- "If your app features colorful backgrounds or visually rich content, prefer a monochromatic appearance for toolbars and tab bars". In monochromatic apps a brand accent color can work well. — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- "Even if your app ships in a single appearance mode, provide both light and dark colors to support Liquid Glass adaptivity". The resting state at the top of scrollable content must keep clear legibility under controls. — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- **[iOS 26 change]** Change log: June 9, 2025, "Updated system color values, and added guidance for Liquid Glass". December 16, 2025, "Updated guidance for Liquid Glass." — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color). WWDC25 says system colors were tuned "across Light, Dark and Increased Contrast appearances… improving hue differentiation". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- "If you want to imbue color into your app, do it in the content layer instead". "When every element is tinted, nothing stands out." — [WWDC25 "Meet Liquid Glass"](https://developer.apple.com/videos/play/wwdc2025/219/)
- Contrast minimums (WCAG AA): **4.5:1** for text up to 17 pt, **3:1** at 18 pt and above, and 3:1 for bold text at any size. Check both light and dark appearances, and provide a higher-contrast scheme under Increase Contrast if the defaults fall short. — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- "Avoid relying solely on color to differentiate…". Add text labels or glyph shapes. — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)

### Inferences
- For a finance app, red/green gain/loss coloring should be paired with an arrow glyph or a +/− sign so it isn't color-only.
- Gradient fills on many cards spread color everywhere, which works against "color sparingly". A calmer approach is a grouped background with secondary-level card fills and color reserved for data (chart line, gain/loss) and the single primary action.

### Gaps
- The second half of the HIG Color JSON (system color value tables) wasn't read.

---

## 6. Materials and Liquid Glass: navigation layer only [iOS 26 change]

### Takeaway
Liquid Glass is reserved for the floating navigation and control layer (tab bars, toolbars, sidebars, floating buttons). Don't use it in the content layer, never stack glass on glass, use it sparingly on custom controls, and tint only primary actions. The standard materials (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`) remain for the *content* layer. A custom bar built on `.ultraThinMaterial` is therefore the wrong material for the navigation layer in iOS 26.

### Cited Findings
- "Liquid Glass forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer". "**Don't use Liquid Glass in the content layer.**… Instead, use standard materials for elements in the content layer, such as app backgrounds." Sliders and toggles are exceptions: they take on glass while being manipulated. — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- "**Use Liquid Glass effects sparingly.**… overusing this material in multiple custom controls can provide a subpar user experience… Limit these effects to the most important functional elements in your app." — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- Liquid Glass is "best reserved for the navigation layer that floats above the content of your app". "Always avoid glass on glass." For elements on top of glass, "use fills, transparency, and vibrancy". — [WWDC25 "Meet Liquid Glass"](https://developer.apple.com/videos/play/wwdc2025/219/)
- **Variants.** Regular is the default, works at any size over any content, and is used by most system components. Clear is "permanently more transparent" with no adaptive behaviors. Use Clear only when all three hold: the element is over media-rich content, the content won't be hurt by dimming, and the content on the glass is bold and bright. "They should never be mixed." — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)
- For Clear glass over bright content, "consider adding a dark dimming layer of 35% opacity". — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- Small glass elements, such as tab and navigation bars, flip light/dark with the content underneath. Large ones, such as menus and sidebars, don't. In steady states, "avoid intersections between content and Liquid Glass". — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)
- iOS keeps "four standard materials — ultra-thin, thin, regular (default), and thick — which you can use in the content layer". Avoid `quaternaryLabel` on thin and ultraThin materials because "the contrast is too low". Choose materials by semantic use, not by the color they produce. — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- Accessibility adaptations are automatic for system glass: Reduce Transparency makes glass "frostier", Increase Contrast makes it "predominantly black or white… with a contrasting border", and Reduce Motion "disables any elastic properties". — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)
- **SwiftUI API.** `glassEffect(_:in:)` defaults to `.regular` in a `Capsule`. Variants include `.regular.tint(.orange).interactive()`, `.buttonStyle(.glass)` for standard buttons, and `GlassEffectContainer(spacing:)` for blending and morphing (spacing controls when shapes merge). Morphing uses `glassEffectID(_:in:)` and `glassEffectUnion(id:namespace:)`. "Apply the glassEffect(_:in:) modifier after other modifiers that affect the appearance of the view". "Limit the use of Liquid Glass effects onscreen at the same time" for performance. — [Apple: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- Custom controls should "apply the material directly to the control, not its inner views". Remove custom backgrounds and borders added to bars, "making customizations like these unnecessary". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- **Scroll edge effects** "replace hard dividers with subtle blur". They are "not decorative". Soft is the iOS default. Use one style per view and don't stack them. — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- HIG Materials change log: June 9, 2025, "Added guidance for Liquid Glass"; September 9, 2025, "Updated guidance for Liquid Glass." — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- Community/expert view: the Lux (Halide) team, whose author says they worked on iOS at Apple, argues the problem with old shadows was that they were *static*. They favor responsive materials but warn that "It can be overwhelming for all elements in the interface to have a particularly rich treatment" and "We do not have to go overboard". — [Lux: Physicality, the new age of UI](https://lux.camera/physicality-the-new-age-of-ui) (community, pre-iOS 26 speculative essay)

### Inferences
- `.ultraThinMaterial` under a floating tab bar in iOS 26 doesn't get glass's lensing, light/dark flipping, automatic accessibility adaptations or interactive response. Next to system sheets and alerts it will look like an iOS 15–18 holdover.
- `.ultraThinMaterial` *on cards* in the content layer is allowed (standard materials belong there). Material cards over a scrolling or animating background, such as the ticker, will shimmer, though, so solid grouped fills are calmer.
- The market ticker should not sit under or inside a glass element in its resting state ("avoid intersections between content and Liquid Glass").

### Gaps
- Exact SwiftUI API names for scroll edge effect styles (e.g., `scrollEdgeEffectStyle(_:for:)`) and for `backgroundExtensionEffect()` weren't checked against Apple docs this session. `.buttonStyle(.glassProminent)` wasn't verified either; only `.glass` appears in the fetched doc.
- How `.ultraThinMaterial` responds to Reduce Transparency compared with Liquid Glass wasn't found in Apple sources.

---

## 7. Tab bars: should the custom capsule tab bar be replaced with system `TabView`? [iOS 26 change]

### Takeaway
On iOS 26 the system tab bar is itself a floating Liquid Glass capsule. It brings minimize-on-scroll, a dedicated search tab, a bottom accessory slot and automatic accessibility adaptations. A custom capsule bar on `.ultraThinMaterial` reproduces the look without the behavior. Unless the custom bar does something `TabView` can't, Apple guidance and API availability point to replacing it with `TabView` plus `Tab`, `.tabBarMinimizeBehavior(.onScrollDown)` and SF Symbols.

### Cited Findings
- "A tab bar floats above content at the bottom of the screen. Its items rest on a Liquid Glass background that allows content beneath to peek through." — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- Minimize behavior: with an attached accessory, "you can choose to minimize the tab bar and move the accessory inline with it when a person scrolls down… exit the minimized state by tapping a tab or scrolling to the top". The APIs are `TabBarMinimizeBehavior` and `UITabBarController.MinimizeBehavior`. — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- "A tab bar can include a dedicated search tab at the trailing end." — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- "Use a tab bar to support navigation, not to provide actions… use a toolbar instead." "Don't disable or hide tab bar buttons". "Make sure the tab bar is visible when people navigate to different sections". Reserve badges for critical information. — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- "Consider using SF Symbols… Prefer filled symbols or icons for consistency with the platform." — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- Avoid screen-specific actions in the tab bar: "A checkout button, for example, belongs with the content it supports." — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- HIG Tab bars change log: July 28, 2025, "Added guidance for Liquid Glass"; December 16, 2025, "Updated guidance for Liquid Glass"; **June 8, 2026**, "Updated terminology and art." — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- **API (community examples).** `TabView { … }.tabBarMinimizeBehavior(.onScrollDown).tabViewBottomAccessory { … }` and `Tab("Search", systemImage: "magnifyingglass", value: …, role: .search) { … }`. Minimizing has no effect unless content scrolls under the bar, and the author recommends letting content extend under it. For a floating action button the article uses `.glassEffect(.regular.interactive())` in a `ZStack`, outside the tab bar. — [Donny Wals: Exploring tab bars on iOS 26 with Liquid Glass](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/) (community)
- Known issues reported by developers: minimizing needs enough scrollable content; crashes with a conditionally rendered `tabViewBottomAccessory` (FB18479195, early seed); the bar animating from the first tab to the restored selection at launch with `.onScrollDown` (FB23998635). — [Apple Developer Forums 790913](https://developer.apple.com/forums/thread/790913); [Forums 839224](https://developer.apple.com/forums/thread/839224); [Classmethod (JP)](https://dev.classmethod.jp/articles/ios-26-liquid-glass-tab-bar/)
- `.tabBarMinimizeBehavior(_:)` documentation exists on Apple's site. — [Apple docs](https://developer.apple.com/tutorials/data/documentation/swiftui/view/tabbarminimizebehavior(_:).md)

### Inferences
- **Recommendation for the audit:** replace the custom capsule tab bar with the system `TabView`. Keep at most 5 tabs, use filled SF Symbols, add `.tabBarMinimizeBehavior(.onScrollDown)`, and put any persistent mini-status (such as a compact market summary) in `tabViewBottomAccessory`, not in the bar. This also removes custom haptics on tab taps, since the system handles tab feedback.
- If a custom bar is kept for brand reasons, build it with `glassEffect` inside a `GlassEffectContainer` rather than `.ultraThinMaterial`, apply glass to the container rather than to each capsule's inner views, and tint only the selected or primary item.

### Gaps
- The full enum of `TabBarMinimizeBehavior` cases (`.automatic`, `.onScrollDown`, `.onScrollUp`, `.never`) wasn't confirmed from Apple's page this session.

---

## 8. Sheets, alerts, toolbars, onboarding [iOS 26 changes]

### Takeaway
iOS 26 sheets, action sheets and toolbars are system-driven glass. Action sheets spring from their source, toolbars group items automatically, and alerts and onboarding use bolder, left-aligned type. Pair modal glass with a dimming layer, and keep text buttons and icon buttons in separate groups.

### Cited Findings
- Action sheets now "spring from the action itself," not from the bottom of the screen. When a sheet is dragged up, the glass "subtly recedes, becoming more opaque and gently growing in size". For modal tasks, pair glass with a dimming layer "to help center attention". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- Toolbars: keep them uncrowded and move secondary actions into a menu. Group by function and frequency. "Don't group symbols with text… it could be perceived as a single button". Primary actions such as Done stay separate and tinted, "often as a blue checkmark on iOS". Items grouped with the correct API "will automatically update to share a background". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- Alerts and onboarding type is "bolder and left-aligned". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- Use the Regular glass variant for components with significant text, "such as alerts, sidebars, or popovers". — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- In sheets, a `ConcentricRectangle` with `.ignoresSafeArea()` adopts the sheet's own container corner radius. — [Nil Coalescing](https://nilcoalescing.com/blog/ConcentricRectangleInSwiftUI) (community)

### Inferences
- Use standard `.sheet` with `.presentationDetents` and system `.alert` / `.confirmationDialog` rather than custom overlays, so the iOS 26 glass, morph-from-source and dimming come for free.

### Gaps
- The HIG Onboarding, Sheets and Alerts pages weren't fetched within the tool budget. No Apple text was retrieved on "no modals on launch" or "keep onboarding short". Those remain unverified best practices.

---

## 9. Depth, shadows, and cards

### Takeaway
No Apple text in this session prescribes card drop-shadow values. Apple's iOS 26 guidance says hierarchy should come from "layout and grouping" rather than decoration, that depth and shadow belong to the glass layer (where the system adjusts shadows dynamically), and that content uses grouped background colors. Heavy static drop shadows plus gradient fills on content cards are the opposite of that guidance. This conclusion is an inference from Apple's principles, not a direct Apple rule.

### Cited Findings
- "Instead of relying on decoration, hierarchy should be expressed through layout and grouping." — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- Liquid Glass shadows are adaptive: "opacity increases over text and decreases over a solid light background". Larger glass "casts deeper, richer shadows". Depth effects are system-managed on the navigation layer. — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)
- Use system vs grouped background colors at primary, secondary and tertiary levels to show grouping hierarchy. — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- Reduce Motion guidance includes "Avoiding animating depth changes in z-axis layers". — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- Community/expert: the old problem with shadows was that they were *static*. Rich treatments should be selective, not applied to every element. — [Lux: Physicality, the new age of UI](https://lux.camera/physicality-the-new-age-of-ui)
- Community (low authority): commentary on the iOS 7 redesign notes Apple removed drop shadows and gradients that "distract from the content". One design-system guide suggests a single faint shadow such as `0 1px 3px rgba(0,0,0,0.08)` when shadows are used. — [Gizmodo: shadows in flat UI](https://gizmodo.com/designers-shadows-are-totally-fine-in-a-flat-ui-633686703); [Frequency brand guidelines: Depth & Shadows](https://brand.frequency.media/guidelines/depth-shadows) (generic web, not iOS-specific)

### Inferences
- **Native-feeling card recipe** (inference): `systemGroupedBackground` page, cards filled with `secondarySystemGroupedBackground`, continuous corners (concentric where nested), and no shadow in light mode. If depth is needed, use at most one very soft shadow, e.g. `.shadow(color: .black.opacity(0.06–0.08), radius: 8–12, y: 2–4)`, and no shadow in dark mode, where shadows are invisible and elevation comes from lighter fills. These numbers are designer convention, not Apple values.
- Gradient fills on every card compete with the chart lines and the gain/loss colors. Keep gradients for a single hero element, or as a very low-contrast wash within one hue.
- `.shadow` on many views inside a `ScrollView` also costs rendering performance. Apple's glass doc separately warns about too many effects onscreen.

### Gaps
- No Apple HIG text giving shadow values or explicitly discouraging shadows on content cards was found. No Bjango or Marc Edwards article on iOS shadows was located; a search returned nothing attributable.

---

## 10. Charts (Swift Charts HIG)

### Takeaway
Keep charts simple and consistent. Use few, light grid lines when the chart is interactive. Choose a fixed or dynamic Y range by meaning (Y doesn't need to start at 0 for line charts). Make the whole plot area scrubbable, and make every chart accessible. Swift Charts provides Audio Graphs and per-mark accessibility elements by default.

### Cited Findings
- "Keep a chart simple, letting people choose when they want additional details." "Resist the temptation to pack as much data as possible into a chart." — [HIG Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data)
- "Prefer consistency across multiple charts… Maintain continuity among multiple charts that use the same data" by using the same chart type, colors, annotations and layouts. — [HIG Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data)
- Axis range: "Use a fixed or dynamic axis range depending on the meaning of your chart". A dynamic range suits widely varying values "and you want the marks to fill the available plot area". A zero lower bound is suggested for bar charts. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- Grid lines: "Too many grid lines can be visually overwhelming… if people can inspect individual data points by interacting with a chart, you might use fewer grid lines and light label colors". "Prefer familiar sequences of values" for tick labels. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- Interactivity: "don't require interaction to reveal critical information". "Consider expanding the hit target to include the entire plot area, letting people scrub". The Stocks app's vertical indicator is the example. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- In compact environments, "maximize the width of the plot area" and keep vertical-axis labels short. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- Accessibility: "Make every chart in your app accessible". Swift Charts gives "a default implementation of Audio Graphs" and default accessibility elements per mark. Hide visible axis and tick text from assistive technologies. Prefer unambiguous formats ("June 6" over "6/6"). A small chart in a button can use one succinct label. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- Color: don't rely on color alone, and supplement with shapes or patterns. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- Changes should also be highlighted in ways other than animation, for VoiceOver users and people with animations off. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)

### Inferences
- For market line charts, use a dynamic Y domain (`.chartYScale(domain:)` fitted to min/max with a little padding), 3–4 light horizontal grid lines or none, hidden or minimal X labels on small charts, and `chartXSelection` scrubbing across the full plot with a vertical `RuleMark`. Play one `.selection` haptic per snapped point if any.
- Sparklines on cards should be non-interactive with a single accessibility summary, e.g. "Up 2.3% today".

### Gaps
- WWDC22 "Design an effective chart" and "Design app experiences with charts", and WWDC25 session 313 on Swift Charts, weren't read this session.

---

## 11. SF Symbols

### Takeaway
Match symbol weight to the adjacent text weight. Symbols use the same nine weights as SF, and their scale (small, medium or large) sets emphasis. Pick the rendering mode for legibility; Hierarchical conveys depth. Use symbol animations judiciously and only with a clear purpose. **[iOS 26 / SF Symbols 7]** adds Draw On/Off and gradient rendering.

### Cited Findings
- "Each of the nine symbol weights… corresponds to a weight of the San Francisco system font, helping you achieve precise weight matching between symbols and adjacent text". The scales "are defined relative to the cap height". "Specifying a scale lets you adjust a symbol's emphasis compared to adjacent text, without disrupting the weight matching". — [HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)
- Rendering modes: Monochrome (one color), Hierarchical (one color at varying opacity by layer), Palette (one color per layer) and Multicolor (intrinsic colors). "Confirm that a symbol's rendering mode works well in every context". System colors let symbols adapt to Dark Mode and accessibility. — [HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)
- "Use variable color to communicate change — don't use it to communicate depth… use Hierarchical rendering mode" for depth. — [HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)
- Animations: Bounce "plays once by default… communicate that an action occurred". Pulse is for ongoing activity, "playing it continuously until a condition is met". Replace (down-up, up-up, off-up) and Magic Replace are the defaults for related symbols. Draw On/Off arrived in SF Symbols 7. "**Apply symbol animations judiciously.**… too many animations can overwhelm an interface". "Consider your app's tone when adding animations." — [HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)
- **[iOS 26 era]** Change log: July 28, 2025, "Updated with guidance for Draw animations and gradient rendering in SF Symbols 7." — [HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)
- Use the same symbol consistently for a meaning. Ambiguous symbols need text labels. In menus, "use the symbol once to introduce the group, and let text do the rest". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)

### Inferences
- In SwiftUI, symbols inherit `.font(...)`, so `Label` or `Image(systemName:)` placed next to text with the same text style matches weight automatically. Avoid `.resizable().frame(...)` on symbols, which breaks optical weight matching. Use `.imageScale(.small/.medium/.large)` and `.symbolRenderingMode(.hierarchical)` instead.
- Gain/loss arrows next to prices should share the price text's style and weight, with `.imageScale(.small)`.

### Gaps
- None material.

---

## 12. Haptics

### Takeaway
Apple's rule is to use haptics sparingly, consistently, and by their documented meaning. "The best haptic experience is one that people may not be conscious of, but miss when it's turned off." Standard controls already play system haptics, so adding custom haptics to ordinary button taps is overuse.

### Cited Findings
- Standard toggles, sliders and pickers "play Apple-designed system haptics by default". Use a feedback generator only "when it makes sense". — [HIG Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- **Notification** (outcome of a task): Success means "a task or action has completed", Warning means it produced a warning, and Error means "an error has occurred". **Impact** (physical metaphor for a visual event, "a tap when a view snaps into place"): Light, Medium, Heavy, Rigid and Soft collisions. **Selection**: "a UI element's values are changing". — [HIG Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- "**Avoid overusing haptics.** Sometimes a haptic can feel just right when it happens occasionally, but become tiresome when it plays frequently… the best haptic experience is one that people may not be conscious of, but miss when it's turned off." — [HIG Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- Use them consistently to "build a clear, causal relationship between each haptic and the action". Use them to complement visual and audio feedback. Prefer short haptics for discrete events. "Make haptics optional." — [HIG Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- **SwiftUI API** (iOS 17+): `.sensoryFeedback(_:trigger:)` with `SensoryFeedback` values `.success`, `.warning`, `.error`, `.selection`, `.increase` ("an important value increased above a significant threshold"), `.decrease`, `.start`, `.stop`, `.alignment` ("alignment of a dragged item"), `.levelChange`, `.pathComplete`, `.impact`, `.impact(weight:intensity:)` and `.impact(flexibility:intensity:)`. Newer `press(_:)`, `release(_:)` and `selection(_:)` variants are listed for touch-down, touch-up and value-change feedback. — [Apple SensoryFeedback docs](https://developer.apple.com/documentation/swiftui/sensoryfeedback)

### Inferences
- **Audit mapping for a market app:**
  - `.selection` while scrubbing a chart or changing a segmented time range.
  - `.success` or `.error` when an action such as adding to the watchlist or a refresh completes or fails.
  - `.increase` / `.decrease` only for user-set price alerts crossing a threshold.
  - Nothing on plain navigation taps, tab switches, card taps or ticker items.
- Use `sensoryFeedback` tied to state changes rather than calling `UIImpactFeedbackGenerator` in every button action. This keeps the haptics causal and consistent.
- Consider an in-app toggle to turn haptics off, per "Make haptics optional".

### Gaps
- iOS availability of the `press`/`release`/`selection(_:)` structured variants wasn't shown on the page; they may be iOS 26 or 27 additions.

---

## 13. Motion: springs, fluid interfaces, Reduce Motion

### Takeaway
Springs are SwiftUI's default animation (since iOS 17). For calm UI, use bounce 0 by default (`.smooth`), small bounce (`.snappy`, 0.15) for quick UI responses, and reserve visible bounce (`.bouncy`, 0.3) for gesture-driven moments with momentum. Avoid bounce above about 0.4. Every animation should be interruptible, and under Reduce Motion should become a fade or a tighter spring.

### Cited Findings
- **Preset values (Apple docs):**
  - `.smooth(duration: 0.5, extraBounce: 0.0)`: base bounce **0** — [Apple docs](https://developer.apple.com/documentation/swiftui/animation/smooth(duration:extrabounce:))
  - `.snappy(duration: 0.5, extraBounce: 0.0)`: base bounce **0.15** — [Apple docs](https://developer.apple.com/documentation/swiftui/animation/snappy(duration:extrabounce:))
  - `.bouncy(duration: 0.5, extraBounce: 0.0)`: base bounce **0.3** — [Apple docs](https://developer.apple.com/documentation/swiftui/animation/bouncy(duration:extrabounce:))
  - Duration is the perceptual duration, "approximately equal to the settling duration".
  - Note: one third-party table listing snappy at 0.3 s is contradicted by Apple's 0.5 s default.
- Springs are the default: "we now use them as the default animation in SwiftUI, so all you need to do is call withAnimation". Springs "maintain continuity both for static cases and cases with an initial velocity". — [WWDC23 "Animate with springs"](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Bounce guidance:
  - Bounce 0 gives "a smooth, gradual change".
  - About 0.15 "doesn't feel very bouncy yet, but… a little more brisk".
  - About 0.3 gives "noticeable bounciness".
  - "be cautious about using values higher than around 0.4, since they may feel too exaggerated for a UI element."
  - "When you're not sure, use a spring with bounce 0".
  - Tune duration first, then bounce.
  - Bounce suits playfulness or "the end of a gesture".

  Source: [WWDC23 #10158](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Don't wait for the settling duration before user-facing changes. Use SwiftUI completion handlers, which use the perceptual duration. SwiftUI tracks gesture velocity automatically and carries it into the spring. — [WWDC23 #10158](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Spring conversion with mass = 1: stiffness = (2π ÷ duration)²; damping = 1 − 4π × bounce ÷ duration for bounce ≥ 0. — [WWDC23 #10158](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Fluid interfaces:
  - "Everything needs to respond instantly". Highlight on touch-down but confirm on touch-up.
  - One-to-one tracking during drags.
  - Fully interruptible and redirectable motion.
  - "start with 100% damping, or no overshoot". Use about 80% damping only when "the gesture that's driving the motion itself has momentum". Example: Music mini-player tap-to-expand uses 100%, swipe-to-dismiss uses 80%.
  - Use consistent paths on- and off-screen.
  - Avoid timers and the single-tap delay caused by double-tap recognizers (about 0.5 s).

  Source: [WWDC18 "Designing Fluid Interfaces"](https://developer.apple.com/videos/play/wwdc2018/803/)
- **Reduce Motion** (Apple): "reducing automatic and repetitive animations, including zooming, scaling, and peripheral motion". Other recommendations:
  - Tighten springs to reduce bounce.
  - Track animations directly with gestures.
  - Avoid z-axis depth animation.
  - Replace x/y/z transitions with fades.
  - Avoid "animating into and out of blurs".

  Source: [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- Liquid Glass under Reduce Motion "disables any elastic properties for the material". — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)

### Inferences
- A "calm" motion token set: `.smooth` (0.5 s, bounce 0) for content and layout changes, `.snappy(duration: 0.3–0.4)` for small control state changes, and `.bouncy` only on gesture release. Using `.spring(response:dampingFraction:)` with low damping, or `.interpolatingSpring` with low damping, is the most common source of "cheap" overshoot.
- **The auto-scrolling ticker** is exactly the "automatic and repetitive… peripheral motion" Apple says to reduce. Under `@Environment(\.accessibilityReduceMotion)` it should stop and become a static, swipeable row or a periodic crossfade. Even without Reduce Motion, a slow speed, a pause on touch, and stopping when off-screen fit a calm feel better. (The environment key name is standard SwiftUI but wasn't re-verified this session.)
- Avoid `.repeatForever` animations (shimmer, pulsing dots) on idle screens. Apple's own Pulse symbol animation is meant to run only "until a condition is met".

### Gaps
- `Animation.default` changed to a spring in iOS 17, but its exact parameters weren't confirmed from Apple docs this session.

---

## 14. Accessibility as part of the premium feel

### Takeaway
Apple treats Dynamic Type (at least 200%), contrast minimums, 44 pt targets, Reduce Motion, Reduce Transparency, Increase Contrast and VoiceOver as baseline quality. iOS 26 system glass adapts automatically, but custom materials and custom controls don't.

### Cited Findings
- Dynamic Type of at least 200%. Contrast minimums of 4.5:1 and 3:1. Controls 44×44 pt (minimum 28×28 pt). The Reduce Motion practices listed in section 13. — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- HIG Accessibility change log: March 7, 2025, "Expanded and refined all guidance. Moved Dynamic Type guidance to the Typography page, and moved VoiceOver guidance to a new VoiceOver page". June 9, 2025, Assistive Access and Accessibility Nutrition Labels added. — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- System Liquid Glass gets Reduce Transparency, Increase Contrast and Reduce Motion treatments "across the board". — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)
- Custom fonts must implement Dynamic Type and Bold Text behaviors themselves. — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- Every chart needs accessibility labels, and Swift Charts provides Audio Graphs. — [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)

### Inferences
- Custom pieces such as the tab bar, cards, ticker and serif font each need manual handling of Reduce Transparency (switch to opaque fills), Reduce Motion (stop the ticker, use fades), Bold Text (`legibilityWeight`) and the AX Dynamic Type sizes (wrap rows into stacks via `ViewThatFits` or `dynamicTypeSize` checks). Moving to system components removes most of that burden.

### Gaps
- The HIG VoiceOver page wasn't fetched.

---

## 15. What expert iOS designers and developers recommend (community, distinct from Apple)

### Takeaway
Within the tool budget, citable expert material was limited. Where found, community iOS writers (Donny Wals, Nil Coalescing, Swift with Majid, the Lux/Halide team) recommend adopting system components and iOS 26 APIs (TabView minimize behavior, `ConcentricRectangle`, `glassEffect`) rather than recreating them, and using rich material treatments with restraint.

### Cited Findings
- Donny Wals recommends letting content scroll under the iOS 26 tab bar so the glass reads correctly, and uses a `.glassEffect(.regular.interactive())` floating button for primary actions instead of putting actions in the tab bar. — [Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- Nil Coalescing recommends `isUniform: true` for cards, `.concentric(minimum:)` when Dynamic Type can change sizes, and setting `containerShape` on custom containers. — [Nil Coalescing](https://nilcoalescing.com/blog/ConcentricRectangleInSwiftUI)
- Swift with Majid has published on adopting Liquid Glass tabs ("Glassifying tabs in SwiftUI", June 2025); this was not read in detail. — [Swift with Majid](https://swiftwithmajid.com/2025/06/24/glassifying-tabs-in-swiftui/)
- The Lux/Halide team prefers dynamic, responsive materials over static decoration, with restraint: "It can be overwhelming for all elements in the interface to have a particularly rich treatment." They suggest elevating only core actions. — [Lux](https://lux.camera/physicality-the-new-age-of-ui)

### Inferences
- The consistent community message matches Apple's: fewer custom controls, more system components, and decoration subordinate to content.

### Gaps
- No citable statements were retrieved this session from Mike Stern, Linda Dong, Marc Edwards/Bjango, Rafael Conde, Jordan Singer, Paul Hudson, Kavsoft, Sarunw or Meng To on these specific topics. A Bjango/Marc Edwards search returned nothing attributable.
- No sources were retrieved on custom back buttons breaking the interactive swipe-back gesture, preserving large titles, or avoiding modals on launch. These are widely held practices but are unverified here.
- WWDC25 "Design foundations from idea to interface" and WWDC17 "Essential Design Principles" were not read.

---

## 16. Common SwiftUI pitfalls, mapped to the audited app (synthesis)

### Takeaway
Each "cheap or janky" pattern below has a direct Apple counter-rule. Most of the audited app's custom elements (material tab bar, shadowed gradient cards, perpetual ticker, frequent haptics) conflict with iOS 26 guidance on restraint, layering and system components.

### Cited Findings
- **Hard-coded font sizes:** text should scale at least 200%; custom fonts need `relativeTo:`. — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility); [WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)
- **Materials on custom navigation and glass misuse:** glass belongs to navigation only; don't stack glass on glass; remove custom bar backgrounds; limit the number of glass effects onscreen. — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials); [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/); [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/); [Apple: Applying Liquid Glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- **Perpetual or automatic animations:** reduce "automatic and repetitive animations… peripheral motion". — [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- **Decoration-led hierarchy (shadows and gradients):** "hierarchy should be expressed through layout and grouping". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- **Mismatched corner radii:** pinched or flared corners "break the sense of balance". — [WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)
- **Haptic overload:** "Avoid overusing haptics". — [HIG Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- **Spring overshoot:** bounce above about 0.4 is "too exaggerated". Use 100% damping unless the gesture has momentum. — [WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/); [WWDC18](https://developer.apple.com/videos/play/wwdc2018/803/)
- **Over-tinting:** "When every element is tinted, nothing stands out." — [WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)
- **Actions in the tab bar, or hidden or disabled tabs:** both are disallowed. — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- **Too many typefaces or light weights:** avoid both. — [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- **Latency:** respond instantly on touch-down and avoid double-tap delays. — [WWDC18](https://developer.apple.com/videos/play/wwdc2018/803/)

### Inferences
**Audit checklist for this app:**
1. Replace the custom capsule tab bar with system `TabView` and `.tabBarMinimizeBehavior(.onScrollDown)`.
2. Remove `.ultraThinMaterial` from navigation chrome.
3. Cards: use grouped background fills, concentric continuous radii, and no shadow or one faint shadow. Remove gradients except on one hero element.
4. Ticker: respect Reduce Motion, pause on touch, slow it down, and keep it off glass.
5. Numbers: `.monospacedDigit()` everywhere, and `numericText(value:)` only on discrete updates.
6. Haptics: cut to selection (scrubbing), success/error (outcomes) and threshold alerts.
7. Springs: standardize on `.smooth` and `.snappy`.
8. Typography: serif headlines through `relativeTo:`, with per-size tracking checked.
9. SF Symbols: match text weight and use hierarchical rendering.
10. Charts: light or few grid lines, dynamic Y range, full-area scrubbing, and accessibility labels.
11. Layout shift on load (inference, no source retrieved): reserve space with `.redacted(reason: .placeholder)` or fixed-height skeletons so cards don't jump when data arrives.

### Gaps
- No Apple source was retrieved on layout shift during loading, on custom back buttons breaking swipe-back, or on launch-time modals.

---

## 17. iOS 27 (WWDC26, June 2026) changes affecting the above

### Takeaway
iOS 27 refines Liquid Glass rather than replacing it. Press reports say the headline change is a user-facing transparency control ranging from clear to fully tinted, and that apps on standard components pick up refinements automatically. This favors using system components over custom glass or material imitations. HIG-level documentation of iOS 27 changes wasn't found beyond change-log entries (Tab bars, June 8, 2026; Layout, September 9, 2026).

### Cited Findings
- iOS 27 adds a Liquid Glass transparency slider "after a year of user complaints about readability". — [TweakTown](https://www.tweaktown.com/news/112090/apple-is-adding-a-liquid-glass-slider-in-ios-27-after-a-year-of-user-complaints-about-readability/index.html); [Cult of Mac](https://www.cultofmac.com/news/liquid-glass-changes-ios-27-macos-27); [Neowin](https://www.neowin.net/news/apple-finally-brings-the-slider-for-liquid-glass-and-many-other-changes/) (press)
- Post-WWDC coverage says standard components get the refinements without app changes. — [Yanko Design: WWDC 2026, six weeks later](https://www.yankodesign.com/2026/07/28/wwdc-2026-six-weeks-later-what-actually-shipped/) (press; details not independently verified)
- HIG pages updated in 2026: Tab bars (June 8, 2026, "Updated terminology and art") and Layout (September 9, 2026, "Updated guidance to reflect current best practices"). — [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars); [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- The HIG Materials page already notes that glass variants "can differ in response to certain system settings, like if people choose a preferred look for Liquid Glass in their device's settings". — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

### Inferences
- Because users can now set glass opacity system-wide, a custom `.ultraThinMaterial` bar will *not* follow the user's preference while system bars will. That inconsistency is another reason to adopt the system `TabView` and `glassEffect`.

### Gaps
- No Apple primary source (WWDC26 session transcript or HIG text) on iOS 27 design changes was read. Press details such as the exact slider range and the "no recompile" claim are unverified.
