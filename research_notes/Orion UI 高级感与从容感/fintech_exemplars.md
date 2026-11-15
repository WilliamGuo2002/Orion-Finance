# Finance & Productivity UI Exemplars: Reusable Patterns for a Premium, Calm UI (compared against Orion Finance)

Research date: 2026-11-15. About 21 search and fetch calls. Primary sources (company blogs, Apple pages, agency case studies) are preferred and labelled. Third-party "design token" or "style reference" sites reconstruct values by sampling, so treat their hex codes and specs as **unverified**. Several requested exemplars could not be covered in the call budget; they are listed under Gaps, not filled in from memory.

---

## 1. Exemplar-by-exemplar: defining visual and interaction choices

### Takeaway
The best-documented exemplars (Robinhood's 2024 rebrand, Linear's 2026 "calmer interface" refresh, Copilot Money, Monzo, Wealthsimple/Fey) share a few moves: **restraint as an explicit principle**, a **serif-for-headlines and sans-for-data type split** (Robinhood, Wealthsimple), a **near-neutral palette plus one signature accent**, **dimming secondary chrome**, and **fewer separators**. Copilot and the Wealthsimple/Fey team also say outright that being fully native and building custom on top of UIKit is part of their premium feel.

### Cited Findings

**Robinhood (2020 identity; 2024 rebrand, rolled out to all surfaces by early 2025)**
- 2024 rebrand by the agency PORTO ROCHA (creative directors Felipe Rocha and Leo Porto). The identity was to be "fully integrated across all surfaces by early 2025." — [PORTO ROCHA case study](https://www.portorocha.com/robinhood)
- Typefaces: **RH Phonic / "Robinhood Phonic"** (sans, by Schick Toikka), whose "delicate ink-traps" add personality while keeping precision, and **Martina Plantijn** (serif, Klim Type) for headlines, described as a "warm yet intelligent serif." — [PORTO ROCHA](https://www.portorocha.com/robinhood). A secondary source credits Martina Plantijn to a different foundry, and madegooddesigns.com names "Manifold" as the serif. Both look like outliers against the agency's own credit. — [designcompass](https://designcompass.org/en/2024/10/18/robinhood-rebranding/); [madegooddesigns](https://madegooddesigns.com/robinhood-font/)
- Palette: "black, white, and mature neutrals" with pops of **"Robin Neon,"** a new electric yellow-green. The agency says this deliberately departs from competitors' "rainbow" palettes. — [PORTO ROCHA](https://www.portorocha.com/robinhood)
- Illustration moved from a futuristic, richly detailed style to a "technical style inspired by financial graphs." Photography uses single subjects with luxury-fashion cues. Guiding phrases: "less is more," "sharp, sophisticated, and built to scale," "from scrappy disruptor to a financial platform of the future." — [PORTO ROCHA](https://www.portorocha.com/robinhood)
- The earlier 2020 identity (by COLLINS) used **Capsule Sans**, a modified Maison/Milieu Grotesque with a custom "R", plus a serif called **Nib**. — [Robinhood Newsroom, Aug 5 2020](https://robinhood.com/us/en/newsroom/a-visual-identity-that-better-reflects-our-vision/); [The Brand Identity](https://the-brandidentity.com/feed/collins-robinhood-combine-make-investing-accessible-affordable-engaging/). The Capsule Sans/Nib/Maison details come from the search summary of these pages and were not fetched in full.
- Line chart colour rule (official help center): the line is green if the frame's last close is above its first close, red if below. Baseline charts draw a solid horizontal baseline that separates the green and red areas. — [Robinhood: Using charts](https://robinhood.com/us/en/support/articles/using-charts/)
- Robinhood's team built animations that make the live ticker and price charts "flash green and red in real time." Bloomberg covers this in a piece critical of gamified trading. — [Bloomberg, 2021](https://www.bloomberg.com/features/2021-robinhood-stock-trading-design)
- Critique (Pratt IXD, Feb 2025): the Trade button changes colour with the stock's performance, which the reviewer praises as a "perceptual affordance." The same reviewer criticises Buy, Sell and Options being hidden behind one Trade dropdown ("cognitive friction") and suggests an odometer-style micro-interaction for price updates. — [Pratt IXD critique](https://ixd.prattsi.org/2025/02/design-critique-robinhood-ios-app/)
- Robinhood offers colour themes that improve contrast for red-green colour-blind users. — [Robinhood accessibility options](https://robinhood.com/support/articles/accessibility-options) (via search summary)

**Linear (March 2024 redesign; March 12 2026 "calmer interface" refresh)**
- "A calmer interface for a product in motion" (Charlie Aufmann and Maxime Heckel, Mar 12 2026). Goal: keep information density without the interface feeling overwhelming. Principles: **"Don't compete for attention you haven't earned"** and **"Structure should be felt not seen."** Success measure: most users shouldn't notice the changes. — [Linear blog](https://linear.app/now/behind-the-latest-design-refresh)
- Specific moves: the navigation sidebar is "a few notches dimmer"; there are fewer separators, and the remaining dividers have softer contrast and rounded ends; icon use is reduced and icons are smaller; coloured team-icon backgrounds are gone; the palette moved from cool, blue-leaning grays to a **warmer gray that is less saturated**. The team warns that going too warm "risks a muddy look." — [Linear blog](https://linear.app/now/behind-the-latest-design-refresh)
- Process: feature-flag toggles for side-by-side comparison, and an in-app colour picker for tuning hue, chroma and lightness per token. — [Linear blog](https://linear.app/now/behind-the-latest-design-refresh)
- Earlier full redesign: "How we redesigned the Linear UI" (March 2024) redefined hierarchy, balance and density. Linear has also published "A Linear spin on Liquid Glass" (seen only as a title in an aggregator; content not fetched). — [Linear changelog 2024-03-20](https://linear.app/changelog/2024-03-20-new-linear-ui); [plushcap index](https://www.plushcap.com/content/linear/blog/linear-a-linear-spin-on-liquid-glass)

**Copilot Money (iOS/macOS budgeting)**
- **Confirmed: Apple Design Award finalist, 2024**, plus App Store Editors' Choice. — [Apple Developer article, Jun 9 2025](https://developer.apple.com/articles/copilot-money/); [App Store listing](https://apps.apple.com/us/app/id1447330651). No evidence it *won* an ADA.
- Founder quotes: "The app is fully native; we've just managed to take core UIKit components and mold them to what we want them to look like." "We tend to do things very custom. We're very picky when it comes to the design." "Users can tell if you're doing something with passion and love." The Cash Flow feature (2024) is the team's first SwiftUI feature, built with **Swift Charts** and "a lot of interactive charts." Team of 28. — [Apple Developer article](https://developer.apple.com/articles/copilot-money/)
- Third-party sampled palette (**unverified**): a near-black navy canvas `#000814` ("never `#000000`"), stepped navy surfaces (`#001533` card, `#00204D` elevated), semantic data colours (green `#00CC4B` income, red-orange `#FF4433` spending, yellow `#FECE4C` pending, blue `#1C6CFF` interactive), and primary text at about 90% white. Charts act as primary interface rather than as summaries, with tap-to-reveal breakdowns and swipe to change period. — [blakecrosley.com guide](https://blakecrosley.com/guides/design/copilot-money). The author cites no sampling method or research for the eye-strain claims.

**Wealthsimple (and Fey, which it acquired in 2025)**
- Wealthsimple's own launch post for its earlier identity: "Our typography uses the timeless **Caslon and Futura** typefaces to convey the security of your money." The redesign covered logo, typeface, colour, websites, mobile apps and blog. — [Wealthsimple Magazine, "Introducing the new Wealthsimple"](https://www.wealthsimple.com/en-ca/magazine/new-wealthsimple-15)
- Typewolf (2016): headlines use the logo's display serif, **Caslon Graphique**. — [Typewolf](https://www.typewolf.com/blog/favorite-sites-of-march-2016)
- Current type, per third-party sites only (**unverified**): Tiempos (headlines) with "The Future" or Futura PT (body). — [getdesign.md](https://getdesign.md/design-md/wealthsimple); [saaslandingpage](https://saaslandingpage.com/wealthsimple/)
- The rebrand was led internally by head of brand Rudy Adler. — [BetaKit](https://betakit.com/wealthsimple-rebrands-as-the-fintech-company-sheds-its-startup-skin/). A 2026 job posting describes a 30+ person design team that includes editors and copywriters. — [Design Director job posting](https://careers.inovia.vc/companies/wealthsimple/jobs/68555211-design-director-brand-design)
- **Wealthsimple acquired Fey in 2025.** Fey co-founder Thiago Costa, a minimalist product designer who also co-founded the studio Narative, is previewing a **rebuilt Wealthsimple iOS/Android app due early 2027**. It is built on **UIKit, not SwiftUI**, has an order flow "reworked completely from scratch," uses **swipe-up to confirm a trade**, and had "loooots of thought" put into its gestures. More Home Screen widgets are teased. — [iPhone in Canada, Nov 5 2026](https://www.iphoneincanada.ca/2026/11/05/wealthsimple-fey-uikit-trading-app-sneak-peek/)

**Fey (fey.com)**
- Review (Feb 27 2025): available on browser and Mac. It is described as a "command center" for filings and insider activity in "one elegantly crafted space," with keyboard-first navigation (typing "/AAPL"), progressive disclosure from simple screening filters to advanced metrics, and a premium price. — [Artisan Apps](https://artisan-apps.beehiiv.com/p/fey-where-bloomberg-meets-apple-s-design)
- Third-party style references (**unverified**): a cinematic near-pure-black canvas, white text, an 8px base grid, a monoline white icon dock, and sparse vivid accents reserved for key insights. — [Refero style reference](https://styles.refero.design/style/a0630421-7b66-48b4-aa14-6194a3b2c2b9); [Kombai](https://kombai.com/examples/design-systems/feyapp-kombai)
- A designer who rebuilt Fey as a Figma UI kit says it taught them about "shadows, gradients, and the craftsmanship" of premium design. — [Design Systems Collective](https://www.designsystemscollective.com/crafting-a-detailed-ui-kit-from-inspiration-breaking-down-feys-design-2d2761649e40). Product Hunt reviewers of Fey 2.0 repeatedly praise its design and polish. — [Product Hunt](https://www.producthunt.com/products/fey/reviews)

**Monzo (2019 app redesign; 2022 rebrand; Nov 2023 Home screen)**
- The 2022 rebrand (Ragged Edge) kept the "hot coral" card. **Oldschool Grotesk** is the hero typeface and **Monzo Sans** (a custom cut of Universal Sans) is the functional typeface. — [It's Nice That](https://www.itsnicethat.com/news/ragged-edge-monzo-graphic-design-021122); [Monzo blog](https://monzo.com/blog/weve-had-a-little-makeover)
- Community pushback: users said the numbers in the new font look "too playful for a banking app." This is anecdotal forum sentiment. — [Monzo Community "New font"](https://community.monzo.com/t/new-font/142936)
- 2019 app redesign: the "Pulse" wavy balance graph was removed from home. — [Monzo blog, Sept 2019](https://monzo.com/blog/2019/09/20/the-monzo-app-is-changing)
- New Home screen (Nov 6 2023): the app had "outgrown its own design and architecture." Early concepts tested as "overwhelming and confusing," so the team added **home customisation** ("control what they see"). The project involved 1,000+ customers, 4 major and 2 minor experiments over 7 months, and "snooze"-able rollout so customers mid-task aren't interrupted. — [Monzo blog](https://www.monzo.com/blog/how-we-built-the-new-home-screen)

**Apple (Stocks, as documented in the HIG)**
- The HIG uses Stocks as its line-chart example (performance over a chosen one-month period). Stocks pairs small static repeating thumbnail charts in lists with larger interactive charts on detail screens. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md); [HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts.md) (thumbnail and interactive detail via search summary)
- Green for gains and red for losses fits the US, but "in some countries like China, people expect the opposite." — [HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts.md) (via search summary)

### Inferences
- The clearest premium-calm statements of intent are Linear's "Don't compete for attention you haven't earned" and Robinhood's "less is more" with neutrals plus one signature accent. Both describe *subtraction*: dimmer chrome, fewer dividers, fewer icons, fewer hues.
- Wealthsimple bringing in Fey's team suggests that the "editorial serif + calm" brand (Wealthsimple) is converging with the "cinematic dark data" product craft (Fey). Both teams chose UIKit for the most gesture-heavy surfaces.
- Orion's serif headlines, warm cream background and single caramel accent fit the Robinhood 2024 recipe (serif headlines over a precise sans, neutrals plus one accent) and Wealthsimple's historical Caslon/Futura pairing.

### Gaps
- Not researched within the call budget: **Apple Wallet / Apple Card / Apple Invites, Revolut, Stripe Dashboard, Arc, Things 3, Bear, Craft, Public.com, Kubera, Origin, Rocket Money, Monarch.** None of the claims about them below were verified in this session. Leads from background knowledge that need checking: Things 3 and Bear were Apple Design Award winners (believed 2017); Craft received Mac App of the Year recognition (believed 2021); Apple Card/Wallet use SF Pro with a large balance and colour-coded spending categories. **Do not cite these without verification.**
- Wealthsimple's *current* app typeface and its 2021+ in-house redesign could not be confirmed from a primary source. The Tiempos claim is third-party only.
- Robinhood Legend's (desktop) visual specifics were not found beyond the existence of help pages ([Widgets in Robinhood Legend](https://robinhood.com/us/en/support/articles/widgets-in-robinhood-legend)).
- Fey's official design documentation does not appear to exist publicly, and its mobile app status is unclear after the Wealthsimple acquisition.

---

## 2. Numbers & data typography

### Takeaway
Evidence is thin for exact balance-rendering specs at named exemplars. What can be established: **tabular (fixed-width) figures are the consensus for money and live values** because they stop jitter and keep amounts aligned. Premium brands pair a serif display face with a precise sans for data, and Robinhood picked a sans specifically for "precision." Monzo shows the risk: a characterful face makes numbers look "too playful."

### Cited Findings
- Robinhood's data/UI sans (RH Phonic) was chosen for "precision," and ink-traps supply personality. The serif (Martina Plantijn) is for headlines, not figures. — [PORTO ROCHA](https://www.portorocha.com/robinhood)
- Monzo users criticised numerals set in the new brand type as "too playful for a banking app," especially on screens that mix two fonts. — [Monzo Community](https://community.monzo.com/t/new-font/142936)
- Tabular figures are recommended for every currency, percentage and account value. Proportional digits make columns hard to scan and make live-updating values jitter horizontally. Inter's default numerals are proportional, so tabular figures must be enabled explicitly. These are secondary and practitioner sources. — [fontalternatives: legible numerals](https://fontalternatives.com/blog/best-fonts-legible-numerals-ui/); [fontalternatives: fintech fonts](https://fontalternatives.com/best-fonts-for/fintech/)
- Stripe is cited as a reference for financial tables with tabular figures (secondary source). — [AdminLTE fintech dashboards](https://adminlte.io/blog/fintech-dashboard-design-examples/)
- Copilot's third-party analysis says nothing about numeral styling. Primary text is about 90% white rather than pure white (unverified). — [blakecrosley.com](https://blakecrosley.com/guides/design/copilot-money)
- A critique argues Robinhood uses the same red for a 0.02% loss and a 20% loss and suggests graded shades. This is opinion, not an official change. — [Chris Goldammer, "The curse of same-day changes"](https://chrisgoldammer.notion.site/Stock-price-charts-4-22-2021-179a9339afd544eebee8fbd88d8d7dd1) (via search summary)

### Inferences
- For Orion: keep the serif for headlines and section titles, and render balances and prices in SF Pro (or another precise sans) with monospaced digits. Avoid setting large balances in the serif, which is the Monzo "too playful" failure mode. Implementation notes, using API references that were not fetched this session: SwiftUI `Font.monospacedDigit()` and `.contentTransition(.numericText())` support tabular digits and rolling-number updates.
- A de-emphasised currency symbol and cents (smaller or lighter) is a common pattern in finance UIs, but **no primary source was found in this session**. Treat it as unverified until checked against screenshots of Apple Card, Robinhood or Copilot.

### Gaps
- No verified source for: exact balance font sizes and weights at Robinhood, Copilot or Apple Card; whether they shrink cents or the currency symbol; letter-spacing on large numerals; whether change values sit in pill backgrounds. These need Mobbin or screenshot inspection, which was not done.

---

## 3. Charts

### Takeaway
Apple's HIG and the exemplars converge on these rules: **one simple line, with detail revealed progressively**; a **small static sparkline in lists and a large interactive chart on detail**; **line colour set by period start vs. end** (Robinhood), with an optional baseline; a **descriptive headline above the chart**; and **consistent style across every chart**. Robinhood's real-time green/red flashing is the documented example of chart motion slipping into gamification.

### Cited Findings
- HIG: "Keep a chart simple, letting people choose when they want additional details." "Resist the temptation to pack as much data as possible into a chart." Reveal detail gradually. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)
- HIG: "Match the size of a chart to its functionality." Use small charts for glanceable previews and large ones for exploration. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)
- HIG: "Aid comprehension by adding descriptive text." For example, Weather's summary headline ("Chance of light rain in the next hour") sits above the chart. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)
- HIG: "Prefer consistency across multiple charts." Keep continuity when a small chart expands, as Health Trends does when small charts expand into the same style, colours and marks. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)
- HIG: "Make every chart in your app accessible." Provide accessibility labels and elements. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)
- Robinhood: the line's colour follows the period's last close vs. first close, and baseline charts separate green and red areas with a solid horizontal line. — [Robinhood: Using charts](https://robinhood.com/us/en/support/articles/using-charts/)
- Robinhood offers 1 Day / 1 Week / 1 Month timeframe switching. The critique faults the lack of a custom range and of an allocation view. — [Pratt IXD](https://ixd.prattsi.org/2025/02/design-critique-robinhood-ios-app/)
- Robinhood's 2024 illustration language is itself "inspired by financial graphs," so the chart line is part of the brand. — [PORTO ROCHA](https://www.portorocha.com/robinhood)
- Copilot builds its interactive charts with Swift Charts and treats charts as primary navigation, with tap-to-reveal breakdowns and swipe to change period (third-party description). — [Apple Developer](https://developer.apple.com/articles/copilot-money/); [blakecrosley.com](https://blakecrosley.com/guides/design/copilot-money)
- Monzo removed its home-screen "Pulse" balance graph in its 2019 redesign. — [Monzo blog](https://monzo.com/blog/2019/09/20/the-monzo-app-is-changing)

### Inferences
- For Orion's net-worth header: colour the line from the selected range's start vs. end, not today's change alone. Consider a dashed baseline at the period's start value instead of gridlines. Put a one-line summary ("Up $1,240 this month") above the chart, following HIG guidance. Watchlist sparklines should match the detail chart's style.
- Monzo's removal of its home balance graph is a counterpoint: a decorative chart on home can be noise. Orion's header chart earns its place only if it's interactive and tied to a range selector.

### Gaps
- **Not verified:** stroke widths, whether Robinhood or Apple Stocks use gradient fills, haptic ticks during scrubbing, and default time ranges. Search found no official statement on scrubbing haptics; direct app testing would be needed.

---

## 4. Layout & navigation

### Takeaway
Calm layouts rely on **hierarchy by dimming and spacing rather than lines and boxes** (Linear 2026: fewer separators, dimmer sidebar, smaller icons). Home screens are **curated and often user-customisable** rather than all-modules-at-once (Monzo 2023), and detail sits one interaction deeper (Copilot, Fey).

### Cited Findings
- Linear: "Structure should be felt not seen." Fewer separators, softer dividers, rounded tabs that no longer span full width, and consistent header action placement. — [Linear blog](https://linear.app/now/behind-the-latest-design-refresh)
- Monzo Home (2023): early concepts were "overwhelming and confusing," which led to a customisation element. Goal: "bringing order to complexity." — [Monzo blog](https://www.monzo.com/blog/how-we-built-the-new-home-screen)
- Copilot's dashboard opens to a summary with contextual cards and progress bars, not spreadsheet grids; detail is one interaction deeper (third-party). — [blakecrosley.com](https://blakecrosley.com/guides/design/copilot-money)
- Fey uses progressive disclosure from simple filters to advanced metrics, plus a keyboard-first command palette. — [Artisan Apps](https://artisan-apps.beehiiv.com/p/fey-where-bloomberg-meets-apple-s-design)
- HIG: not every dataset needs a chart; a scrollable, sortable list may be better. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)

### Inferences
- Orion's home (net worth, accounts by institution, watchlist, movers, news, AI assistant) has six or more modules, which is more than the evidence favours. Options: (a) collapse movers and news into one "Markets" section, or (b) offer Monzo-style home customisation.
- Rounded cards with drop shadows *and* dividers inside would double the structure cues. Linear's direction suggests picking one: soft tonal card fills with no shadow, or flat sections with whitespace. If shadows stay, keep them very diffuse and low-opacity.

### Gaps
- Not verified: how many modules Robinhood, Copilot or Apple Wallet show on home; tab-bar vs. floating-bar choices; **iOS 26 Liquid Glass adoption** by these finance apps. Only Linear's "Liquid Glass" post was found, and only its title.

---

## 5. Color & material

### Takeaway
The pattern is **neutrals plus one signature accent**: Robinhood uses black, white and mature neutrals plus Robin Neon; Linear warmed its grays but kept saturation low; Fey uses near-black with sparse vivid accents. **Avoid pure black and pure white** (Copilot, per third-party sampling). Warmth works only in moderation; Linear warns of "muddy" results.

### Cited Findings
- Robinhood 2024: "black, white, and mature neutrals" plus "Robin Neon," explicitly rejecting competitors' rainbow palettes. — [PORTO ROCHA](https://www.portorocha.com/robinhood)
- Linear 2026: moved from cool blue-leaning gray to a warmer, less saturated gray. "Going too warm risks a muddy look." Tokens were tuned in hue, chroma and lightness. — [Linear blog](https://linear.app/now/behind-the-latest-design-refresh)
- Copilot (unverified sampled values): navy-black `#000814` instead of `#000000`, tonal elevation steps, about 90% white text, and four semantic data colours. — [blakecrosley.com](https://blakecrosley.com/guides/design/copilot-money)
- Fey (unverified): near-black canvas, white text, sparse vivid accents for critical insights. — [Refero](https://styles.refero.design/style/a0630421-7b66-48b4-aa14-6194a3b2c2b9)
- Monzo kept its "hot coral" card as the signature brand colour through the 2022 rebrand. — [It's Nice That](https://www.itsnicethat.com/news/ragged-edge-monzo-graphic-design-021122)
- HIG: the meaning of green and red is regional. — [HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts.md)
- Robinhood offers alternative colour themes for red-green colour blindness. — [Robinhood accessibility](https://robinhood.com/support/articles/accessibility-options)

### Inferences
- Orion's beige/cream background with a caramel accent fits the "neutral plus one accent" pattern. Linear's "muddy" warning applies directly: tune the cream's chroma low, check it in OKLCH/LCH, and make sure the gain/loss green and red don't clash with caramel. A slightly desaturated green and red would read calmer on warm backgrounds; verify contrast.
- Dark mode should use a tinted warm near-black (Copilot uses navy) rather than `#000000`.
- Add a gain/loss colour-swap setting (regional convention plus colour blindness), as Robinhood and the HIG suggest.

### Gaps
- No primary source on blur and material use (Liquid Glass) in these finance apps. No verified hue counts for Apple Card, Revolut or Monarch.

---

## 6. Motion & feedback

### Takeaway
Little verified detail. What is documented: Robinhood's real-time green/red flashing, which was criticised in a gamification context; an odometer-style number roll proposed as a calm alternative; and custom gestures (swipe-to-confirm) in the Wealthsimple/Fey rebuild. Monzo treats *rollout* as part of calm design (snoozable upgrade).

### Cited Findings
- Robinhood developed animations so ticker and price charts "flash green and red in real time." Bloomberg frames this as part of the trading-game critique. — [Bloomberg 2021](https://www.bloomberg.com/features/2021-robinhood-stock-trading-design)
- Pratt critique proposes an odometer-style micro-interaction for live prices. — [Pratt IXD](https://ixd.prattsi.org/2025/02/design-critique-robinhood-ios-app/)
- New Wealthsimple app (early 2027): swipe-up to confirm a trade, guards against accidental orders, "loooots of thought went into our new gestures," built on UIKit. — [iPhone in Canada](https://www.iphoneincanada.ca/2026/11/05/wealthsimple-fey-uikit-trading-app-sneak-peek/)
- Monzo: the new Home screen rollout can be "snoozed" so it doesn't interrupt someone mid-task. — [Monzo blog](https://www.monzo.com/blog/how-we-built-the-new-home-screen)
- Copilot: "smooth animations" and native rendering, with no specifics (third-party). — [blakecrosley.com](https://blakecrosley.com/guides/design/copilot-money)

### Inferences
- For Orion: animate balances with a rolling-number transition only on real value changes, and don't flash row backgrounds. Use light haptics at scrub start and when a range is selected rather than continuous ticks (unverified as exemplar practice). Show skeleton placeholders in the final card shapes.

### Gaps
- No verified source on scrubbing haptics (Robinhood, Apple Stocks), on loading skeletons in any exemplar, or on Copilot's specific transitions.

---

## 7. Microcopy, tone & empty states

### Takeaway
Tone evidence is mostly brand-level. Robinhood moved to "sharp, sophisticated" and "trust over disruption." Wealthsimple's type was chosen to "convey the security of your money," and the company employs editors and copywriters on its design team. The HIG endorses a plain-language summary headline above data.

### Cited Findings
- Robinhood 2024 tone: "less is more," "sharp, sophisticated," a brand that signals trust over disruption. — [PORTO ROCHA](https://www.portorocha.com/robinhood)
- Wealthsimple: type chosen "to convey the security of your money." The design team includes editors and copywriters. — [Wealthsimple Magazine](https://www.wealthsimple.com/en-ca/magazine/new-wealthsimple-15); [job posting](https://careers.inovia.vc/companies/wealthsimple/jobs/68555211-design-director-brand-design)
- HIG: descriptive summary text ("Chance of light rain in the next hour") helps people grasp essentials at a glance. — [HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data.md)
- Linear: success is when "most users don't notice" the changes, i.e. quiet, non-announcing change. — [Linear blog](https://linear.app/now/behind-the-latest-design-refresh)

### Inferences
- For Orion: a one-line plain-language summary under the net-worth figure ("Up 2.1% this month, mostly from VTI") follows the HIG Weather pattern and gives the AI assistant a calm, non-chat entry point.

### Gaps
- No verified empty-state examples from Copilot, Monarch, Rocket Money or Apple Wallet. No microcopy guidelines from the exemplars were found.

---

## 8. Synthesis: strong signals (3+ exemplars), one-offs, anti-patterns

### Takeaway
Strong recurring signals: **subtraction and hierarchy by dimming**, **neutrals plus one accent**, **progressive disclosure and simple charts**, **avoiding pure black and white**, and **native craft**. One-offs: Robinhood's neon, Monzo's coral and playful grotesk, Fey's cinematic black. Documented anti-patterns: real-time green/red flashing and gamified trading, characterful numerals, overloaded home screens, and uniform red for small and large losses.

### Cited Findings
- Restraint and subtraction as explicit principle: Linear ("Don't compete for attention you haven't earned"), Robinhood ("less is more"), HIG ("Resist the temptation to pack as much data…"), Monzo ("bringing order to complexity"). — [Linear](https://linear.app/now/behind-the-latest-design-refresh); [PORTO ROCHA](https://www.portorocha.com/robinhood); [HIG](https://developer.apple.com/design/human-interface-guidelines/charting-data.md); [Monzo](https://www.monzo.com/blog/how-we-built-the-new-home-screen)
- Progressive disclosure: HIG, Fey, Copilot (third-party), Monzo customisation. — sources as above.
- Neutral palette plus single signature accent: Robinhood (Robin Neon), Monzo (coral card), Fey (sparse vivid accents, unverified), Linear (low-saturation warm grays). — sources as above.
- Serif display plus sans for UI/data: Robinhood (Martina Plantijn plus Phonic), Wealthsimple (Caslon plus Futura; possibly Tiempos now, unverified). — [PORTO ROCHA](https://www.portorocha.com/robinhood); [Wealthsimple](https://www.wealthsimple.com/en-ca/magazine/new-wealthsimple-15)
- Native craft as a premium driver: Copilot ("fully native," "very picky"), Wealthsimple/Fey (UIKit, custom gestures). — [Apple Developer](https://developer.apple.com/articles/copilot-money/); [iPhone in Canada](https://www.iphoneincanada.ca/2026/11/05/wealthsimple-fey-uikit-trading-app-sneak-peek/)
- Anti-patterns:
  - Real-time flashing colour: [Bloomberg](https://www.bloomberg.com/features/2021-robinhood-stock-trading-design).
  - Playful numerals: [Monzo Community](https://community.monzo.com/t/new-font/142936).
  - Overwhelming home concepts: [Monzo](https://www.monzo.com/blog/how-we-built-the-new-home-screen).
  - Hidden trade actions behind one ambiguous button: [Pratt IXD](https://ixd.prattsi.org/2025/02/design-critique-robinhood-ios-app/).
  - Same red regardless of magnitude: [Goldammer](https://chrisgoldammer.notion.site/Stock-price-charts-4-22-2021-179a9339afd544eebee8fbd88d8d7dd1).
  - Over-warm "muddy" palettes: [Linear](https://linear.app/now/behind-the-latest-design-refresh).

### Inferences
Checklist against Orion:
1. Audit separators and shadows; keep one structural device.
2. Set balances in a sans with monospaced digits and keep the serif for headings.
3. Lower the chroma of the cream and caramel and test them against the green and red.
4. Trim or make customisable the six-plus home modules.
5. Add a summary headline above the chart and colour the line by range start vs. end.
6. Use rolling numbers instead of flashes.
7. Use warm near-black in dark mode.
8. Add a gain/loss colour-swap setting.

### Gaps
- The "3+ exemplars" threshold is met only for the restraint, neutral-plus-accent and progressive-disclosure patterns. Numeral rendering, chart stroke and fill, haptics, skeletons and Liquid Glass adoption remain unverified for every named app.
- Unresearched exemplars (Apple Wallet/Card/Invites, Revolut, Stripe, Arc, Things 3, Bear, Craft, Public, Kubera, Origin, Rocket Money, Monarch) need a follow-up pass, ideally with Mobbin screenshots and primary sources.
