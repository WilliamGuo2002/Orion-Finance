# Calm, composure and unhurriedness (从容感) in interfaces, with a focus on personal-finance / investing apps

Scope: principles and concrete techniques (with values where available) for making an iOS SwiftUI finance app (net worth, watchlist with red/green changes, scrolling market ticker, market movers, news, AI assistant) feel calm, confident and unhurried rather than noisy, urgent or anxious. Research date: November 2026. "Inferences" are the researcher's own application of the cited material to this app; they are not sourced claims.

---

## 1. Calm Technology (Weiser & Brown 1995; Amber Case) and how it translates to mobile UI

### Takeaway
Calm technology is about attention placement, not minimalism. Information should live in the periphery and move to the center only when it matters, and the user (not the system) should decide when that happens: "offer, but not demand." On a phone, that means ambient, glanceable status in place of interruptions, popups reserved for destructive, emergency or opted-in events, and a design that still works when the data fails.

### Cited Findings
- Weiser & Brown define the **center** (what we attend to explicitly) and the **periphery** (what we are attuned to without attending). Calm technology "engages both" and moves easily between them. They call designing for the periphery the core challenge and describe the result as "encalming": more peripheral awareness while staying in control. — [Weiser & Brown, "Designing Calm Technology" (1995), via calmtech.com](https://calmtech.com/papers/designing-calm-technology.html)
- Two reasons calm technology works: (1) the periphery handles large amounts of information without overburdening us, and (2) moving something from periphery to center lets us act on it, which gives a sense of control. Short quote: "the periphery is informing without overburdening." — [Weiser & Brown 1995](https://calmtech.com/papers/designing-calm-technology.html)
- Three signs of calm technology: easy movement between center and periphery, expanded "peripheral reach" without overload, and "locatedness" (feeling connected to familiar surroundings). — [Weiser & Brown 1995](https://calmtech.com/papers/designing-calm-technology.html)
- On real-time streams (Multicast), the authors say the user, not the environment, should control attention: a well-designed real-time tool "will offer, but not demand." Also: "Less is more, when less bandwidth provides more calmness." — [Weiser & Brown 1995](https://calmtech.com/papers/designing-calm-technology.html)
- Dangling String example: an 8-foot string that whirls under heavy network traffic and barely twitches under light traffic. It begins as a new center of attention and then recedes into the periphery. The authors argue that physical, continuous displays suit peripheral perception better than screen symbols that need interpretation. — [Weiser & Brown 1995](https://calmtech.com/papers/designing-calm-technology.html)
- Amber Case's Calm Technology principles: (1) require the smallest possible amount of attention; (2) inform and create calm ("Give people what they need to solve their problem, and nothing more"); (3) use the periphery; (4) amplify the best of technology and humanity; (5) communicate without necessarily speaking; (6) keep working when it fails, falling back to a usable state; (7) use the minimum technology needed; (8) respect social norms by introducing features gradually. — [calmtech.com](https://calmtech.com/)
- Calm notification methods Case lists: haptics, trend graphs, status lights, status tones, timed triggers and delays. "Status shouts" such as smoke alarms are reserved for very important information. Popups "can overwhelm" and should be kept for deleting important content, emergencies, or content the user explicitly opted into. — [calmtech.com](https://calmtech.com/)
- The Calm Tech Institute, a standards and certification body, launched in May 2024. "Calm Tech Certified" is a registered trademark. — [calmtech.com](https://calmtech.com/)

### Inferences
- **Net worth / portfolio header as a "dangling string":** treat it as a peripheral instrument. Show a stable value and a long-range trend line. Do not show a flashing, ticking daily P&L that demands focus. Detail (daily change, per-holding breakdown) moves to the center only when the user taps.
- **Market ticker:** a perpetual marquee breaks "offer, but not demand." It is a continuous stream the user cannot ignore. Calm alternatives: a static, horizontally scrollable strip the user drives, or a compact "market mood" summary such as "S&P 500 +0.4% · Nasdaq −0.2%" that updates in place without animation.
- **Popups and modals:** following Case's rule, reserve them for destructive actions, security events, or alerts the user explicitly set up. Everything else (market news, AI suggestions, feature announcements) should be inline and dismissible.
- **"Keep working when it fails":** with stale or failed data, keep the last known values, add a quiet "Updated 3 min ago" label, and avoid red error banners. Apple's alerts guidance below makes the same recommendation.

### Gaps
- I did not access the full text of Amber Case's book (*Calm Technology*, O'Reilly), so book-level patterns beyond the calmtech.com principles are not captured here.
- I found no published Calm Tech Institute certification criteria to use as a checklist.

---

## 2. Cognitive load and information density: progressive disclosure, Hick's law, glanceability, "professional" vs. stressful density

### Takeaway
Density itself is not the problem. Incoherent density is. Calm comes from consistent geometry, a clear attention hierarchy (the primary task loud, navigation and chrome dim) and progressive disclosure with at most two levels. Bloomberg's density works because of expert users, speed (temporal density) and carefully concealed complexity. Consumers need summary-first, glanceable views with secondary detail one tap away.

### Cited Findings
- **Progressive disclosure:** defer "advanced or rarely used features to a secondary screen." Keep the initial display short and limited to what most users frequently need. Designs with more than two levels "typically have low usability." Benefits: learnability, efficiency and lower error rate. — [Nielsen, NN/g, "Progressive Disclosure" (2006)](https://www.nngroup.com/articles/progressive-disclosure/)
- **Hick's law:** decision time increases with the number and complexity of choices (Hick & Hyman, 1952). Takeaways: minimize choices when response time matters, break complex tasks into steps, highlight recommended options, use progressive onboarding, and don't oversimplify. — [Laws of UX, Hick's Law](https://lawsofux.com/hicks-law/)
- **Dashboards and glanceability:** dashboards should present information that "can be consumed fast, with a minimum of interaction or cognitive processing," as an "at-a-glance, single-screen view." Use length and 2D position for quantities. Color should "only be used to reinforce information that is already communicated in a different way." Avoid pie/donut charts "most of the time" and avoid gauges. About 8% of men and 0.5% of women have some form of color blindness. — [Laubheimer, NN/g, "Dashboards: Making Charts and Graphs Easier to Understand" (2017)](https://www.nngroup.com/articles/dashboards-preattentive/)
- **Density taxonomy (Matt Ström):** visual density, information density (Tufte data-ink), design density (the "gestalt ratio" of decisions that do necessary work), temporal density (what users can accomplish per unit of time, dominated by speed), and value density, defined as "the value a user gets from the interface divided by the time and space the interface occupies." Bloomberg is the canonical example of visual density, but the essay argues its real advantage is temporal density: data loads almost instantly. A trader with four monitors tolerates more density than a novice. — [Matt Ström, "UI Density" (c. 2024)](https://mattstromawn.com/writing/ui-density)
- **Bloomberg conceals complexity:** Bloomberg's CTO says the secret to rising complexity is "to conceal it from the user." The team notes that even a font change or a moved button can disrupt users. — [Tech at Bloomberg, "How Bloomberg Terminal UX designers conceal complexity"](https://www.bloomberg.com/company/stories/how-bloomberg-terminal-ux-designers-conceal-complexity)
- Critics argue that the Terminal's look persists partly because users take pride in mastering a complex interface and it works as a status symbol. — [UX Magazine, "The Impossible Bloomberg Makeover" (2010)](https://uxmag.com/articles/the-impossible-bloomberg-makeover)
- **Calm comes from geometry, not emptiness:** calm is "the absence of spatial confusion." Use predictable margins and columns, stable proportions, shared alignment ("invisible rails"), tight spacing within groups and wider spacing between them, and consistent rhythm across states. Competing layout systems, over-compression, off-grid nudges and transitions that break the mental map destroy calm. Dense dashboards can feel calm when the density follows a consistent pattern. The article gives no numeric values. — [Shapochka, UXmatters, "The Hidden Geometry of Calm Screens" (Jan 2026)](https://www.uxmatters.com/mt/archives/2026/01/the-hidden-geometry-of-calm-screens.php)
- **Case study, Linear's "calmer interface" (Mar 2026):** the navigation sidebar was made "a few notches dimmer" so the main content leads. Tabs, icons and text got smaller. Colored icon backgrounds and unexplained dividers were removed. Separators were rounded and their contrast lowered ("Structure should be felt not seen"). The palette moved from cool blue-gray to a warmer, less saturated gray, with the caveat that too warm looks "muddy." The stated principle: task-central elements stay prominent while orientation and navigation recede, which keeps density high without overwhelming. — [Linear, "A calmer interface for a product in motion" (Mar 12, 2026)](https://linear.app/now/behind-the-latest-design-refresh); [Linear changelog 2026-03-12](https://linear.app/changelog/2026-03-12-ui-refresh)

### Inferences
- **Home screen, summary first:** (1) net worth and a long-range trend, (2) a short watchlist (about 5 to 7 rows visible), (3) everything else (movers, news, AI) below the fold or behind "See all." Movers in particular belong in the second level (see section 4).
- **Attention hierarchy:** primary numbers use the strongest type and color. Tab bar, section headers, timestamps and secondary metrics use secondary/tertiary label colors, following Linear's "dim the chrome" approach. Use spacing and background grouping instead of hairline dividers everywhere.
- **Color is never the only channel:** watchlist changes should carry a sign (+/−) and optionally an arrow glyph as well as color, per NN/g's guidance and the color-blindness figures.
- **Density "professional mode":** if power users want Bloomberg-like density, offer it as an opt-in compact layout. Density reads as professional when it is fast and coherent, and as stressful when it is slow, inconsistent or animated.

### Gaps
- I found no NN/g article specifically on consumer finance-app density, and no controlled study comparing dense and sparse finance dashboards on anxiety.
- No source gave a numeric "optimal item count" for mobile dashboards. The 5 to 7 rows suggestion above is an inference.

---

## 3. Motion and pacing: durations, springs, perpetual motion, interruptibility

### Takeaway
Composed motion is short, critically damped or nearly so, interruptible, and absent from high-frequency interactions. Frantic motion is long, bouncy, decorative, perpetual (marquees, pulsing, shimmer) or in the periphery. Default to `.smooth` springs (bounce 0) with roughly 0.3 to 0.5 s perceptual duration. Use small bounce (≤0.15) only where a gesture carries momentum. Never run auto-moving content for more than 5 s without a pause control.

### Cited Findings
**Durations (NN/g)**
- General range 100 to 500 ms. Simple feedback (toggle, checkbox) is about 100 ms. Substantial changes such as a modal entering take 200 to 300 ms. 400 ms is "very slow," and 500 ms "starts to feel like a drag." Entrances should run slightly longer than exits (e.g., 300 ms in, 200 to 250 ms out). Ease-out is the default. Linear motion feels unnatural. "It is far more common for animations to be too long than too short." The more often an animation is seen, the more subtle and brief it should be. Respect Reduce Motion. — [Laubheimer, NN/g, "Executing UX Animations: Duration and Motion Characteristics" (2020)](https://www.nngroup.com/articles/animation-duration/)

**Springs (WWDC23 "Animate with springs")**
- Springs have two parameters, `duration` (perceptual) and `bounce` (−1.0 to 1.0). Bounce 0 is critically damped and smooth. Bounce below 0 is overdamped. SwiftUI's default animation is now a spring. "When you're not sure, use a spring with bounce 0." About 0.15 is "not very bouncy" but brisker, about 0.30 is noticeably bouncy, and above about 0.4 "may feel too exaggerated for a UI element." Ask whether the app is "serious or playful… relaxed or fast-paced." — [Apple WWDC23 "Animate with springs"](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Conversion: mass = 1; stiffness = (2π / duration)²; damping = 1 − 4π·bounce / duration for bounce ≥ 0. — [WWDC23 "Animate with springs"](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Springs preserve velocity and retarget smoothly when interrupted. "Springs are the only type of animation that maintains continuity both for static cases and cases with an initial velocity." Don't wait for the settling duration before user-facing changes; use the completion handler, which is based on perceptual duration. — [WWDC23 "Animate with springs"](https://developer.apple.com/videos/play/wwdc2023/10158/)
- **SwiftUI presets:** `Animation.snappy(duration: TimeInterval = 0.5, extraBounce: Double = 0.0)`, where extraBounce is "added to the base bounce of 0.15." `smooth` has "no bounce." `bouncy` has a "higher amount of bounce." — [Apple docs, Animation.snappy(duration:extraBounce:)](https://developer.apple.com/documentation/swiftui/animation/snappy(duration:extrabounce:)); [Apple docs, Spring.snappy](https://developer.apple.com/documentation/swiftui/spring/snappy). Third-party tables commonly list bouncy at bounce 0.3 with duration 0.5. One community guide lists snappy at duration 0.3, which conflicts with Apple's documented 0.5 default. — [nilcoalescing, "SwiftUI animation timing"](https://nilcoalescing.com/blog/AnimationTimingInSwiftUI)

**Fluid interfaces (WWDC18 "Designing Fluid Interfaces")**
- Start with **100% damping** (no overshoot). Apple's Music app uses 100% damping for tap-to-open Now Playing and **80% damping** for swipe-to-dismiss, where momentum exists. "You don't need to use springy springs," but if a gesture has momentum and there is no overshoot, "it can often feel broken or unsatisfying." Bounce must be purposeful. — [Apple WWDC18 "Designing Fluid Interfaces"](https://developer.apple.com/videos/play/wwdc2018/803/)
- Latency: "People are really, really sensitive to latency," in taps, presses and every interaction. Build "fully redirectable" interfaces so "the thought and gesture happen in parallel." Use velocity projection, with a deceleration rate matching UIScrollView, to choose gesture endpoints. Rubber-band at boundaries so a frozen phone and a boundary feel different. iOS touch hysteresis is about 10 pt, and double-tap recognition delays single taps by about 0.5 s. — [WWDC18 "Designing Fluid Interfaces"](https://developer.apple.com/videos/play/wwdc2018/803/)
- Spatial consistency: "if something disappears one way, we expect it to emerge from where it came." Treat behaviors "as a family." Lighter objects have less "mass." — [WWDC18](https://developer.apple.com/videos/play/wwdc2018/803/)

**Apple HIG Motion (updated Sep 9, 2025 for Liquid Glass)**
- "Add motion purposefully, supporting the experience without overshadowing it." "Don't add motion for the sake of adding motion." "Gratuitous or excessive animation can distract people and may make them feel disconnected or physically uncomfortable." "Aim for brevity and precision in feedback animations." "In apps, generally avoid adding motion to UI interactions that occur frequently." "Let people cancel motion." Make motion optional, never the only carrier of important information. — [Apple HIG, Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- visionOS guidance relevant to peripheral motion: "avoid displaying motion at the edges of a person's field of view," and avoid sustained oscillation, particularly around 0.2 Hz. Liquid Glass responds to direct touch "with greater emphasis" and more subdued with a trackpad. — [Apple HIG, Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- Liquid Glass (iOS 26): secondary summaries say the material should elevate content rather than compete with it. Avoid layering multiple glass elements. Use tint sparingly. Under Reduce Motion, elasticity and morphing are reduced, but custom elements need their own fallbacks. — [Create with Swift, "Liquid Glass: hierarchy, harmony and consistency"](https://www.createwithswift.com/liquid-glass-redefining-design-through-hierarchy-harmony-and-consistency/); [WWDC25 "Meet Liquid Glass" notes](https://wwdcnotes.com/documentation/wwdc25-219-meet-liquid-glass/) (secondary sources)

**Perpetual and peripheral motion**
- WCAG 2.2.2 Pause, Stop, Hide (Level A): moving, blinking or scrolling content that starts automatically, lasts more than 5 seconds and appears alongside other content must be pausable, stoppable or hideable. Auto-updating content (explicitly including "stock price updates") must be pausable, hideable, or have a controllable update frequency, with no 5-second exception. The intent is to avoid distraction, especially for people with attention deficits. Stock-ticker example: provide pause and restart. On resume, jump to current data, because resuming with old data "would present misleading information." — [W3C, Understanding SC 2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)
- Auto-forwarding carousels "annoy users." Moving elements take control away, users read moving boxes as ads, low-literacy and non-native readers can't finish reading, and accessibility suffers. In one test a 5-second rotation showed a key offer only about 20% of the time. Recommendation: content should "stand still" unless the user requests change. — [Nielsen, NN/g, "Auto-Forwarding Carousels and Accordions Annoy Users" (2013)](https://www.nngroup.com/articles/auto-forwarding/)
- Moving icons ("moticons") are detected better than color or shape codes, especially in the periphery. Motion's attention-getting power "falls off much less towards the periphery" than other cues, and some motion types are more distracting and irritating than others. — [Bartram, Ware & Calvert, "Moticons: Detection, Distraction and Task," IJHCS 2003](https://www.interruptions.net/literature/Bartram-IJHCS03.pdf); [Bartram et al., Interact 2001](https://www.interruptions.net/literature/Bartram-Interact01.pdf)
- Prior work summarized by the Stasko group found that animation in peripheral displays was "typically disruptive to primary tasks," particularly fast search tasks. — [Plaue & Stasko / Georgia Tech, Interact 2001 paper](https://faculty.cc.gatech.edu/~john.stasko/papers/interact01.pdf) (via search abstract; full text not read)

**Practitioners**
- Val Head (*Designing Interface Animation*, Rosenfeld 2016): animation balances form and function, serving feedback, orientation, directing attention and showing cause and effect. Durations are judged empirically by prototyping. Her slide notes suggest matching velocities rather than durations for similar objects. — [Rosenfeld Media FAQ](https://rosenfeldmedia.com/designing-interface-animation-frequently-asked-questions/); [Val Head, "Purpose and Style" slides](https://noti.st/valhead/eNy3nY/slides); [Adobe, Six principles interview](https://blog.adobe.com/en/publish/2019/06/19/designing-animation-six-principles-using-animation-ux)

### Inferences
- **Motion token set for a calm finance app (proposed):**
  - Default: `.smooth` (bounce 0), about 0.35 to 0.45 s for in-place state changes, 0.5 s for sheet/screen-level changes.
  - Touch feedback (pressed state, toggles): about 0.1 to 0.15 s, or the implicit system behavior.
  - User-driven gestures with momentum (sheet dismiss, card swipe): `.snappy` (bounce 0.15) or `.spring(duration: 0.4, bounce: 0.1)`. This mirrors WWDC18's 80% damping for momentum and 100% for taps.
  - Avoid `.bouncy` (about 0.3) and anything above 0.3 for financial data. Bouncing numbers read as playful or gamified.
  - Exits about 20 to 30% shorter than entrances.
- **Number changes:** update prices in place with a subtle numeric content transition (e.g., SwiftUI `.contentTransition(.numericText(value:))` with `.smooth`). Do not flash cell backgrounds red/green; the FCA flagged flashing red/green prices as a feature of concern (section 4). Coalesce ticks so a given row changes at most every few seconds.
- **Ticker:** default to static. If auto-scroll is kept, it must have a visible pause, stop when the user scrolls or touches it, pause for Reduce Motion and when VoiceOver is running, and jump to fresh data on resume (WCAG 2.2.2). The research on peripheral motion suggests a top-of-screen marquee steals attention from the primary content continuously.
- **No perpetual decorative motion:** no pulsing "live" dots, glowing gain badges, breathing gradients or shimmering skeletons that loop indefinitely. If a live indicator is needed, use a static dot plus a timestamp. The visionOS 0.2 Hz oscillation warning is a useful proxy for why slow pulsing feels uneasy.
- **Choreography:** animate one element group per state change. Avoid staggered cascades of 10+ rows. Stagger, if used at all, should be ≤30 to 40 ms per item and capped at a few items (this is a design heuristic, not sourced).
- **Reduce Motion:** read `accessibilityReduceMotion` and swap spatial transitions for cross-fades, and auto-scroll for static.

### Gaps
- Material Design 3 motion tokens: the official m3.material.io table was not retrievable. Secondary sources state M3 durations run from 50 ms (short1) to 1000 ms (extra-long4), with standard easing cubic-bezier(0.2, 0, 0, 1) ([skill-wiki Compose easing rule](https://skill-wiki.github.io/atom/android-compose/rule-motion-easing-tokens); [M3 motion skill summary](https://skills.sh/shelbeely/shelbeely-agent-skills/material-design-3-motion)). Emphasized-decelerate values are unverified.
- Rachel Nabors' guidance was not researched in depth.
- The full text of Bartram et al. 2003 (exact detection and distraction rates by motion type) could not be extracted from the PDF.
- I found no experimental study specifically on scrolling stock tickers and user anxiety.

---

## 4. Emotional design of money: anxiety, loss aversion, red/green, real-time flicker, notifications, gamification, and what calmer apps do

### Takeaway
Regulators and experiments converge: push notifications, points/prizes, celebration (confetti), top-mover and top-traded lists, social feeds and flashing red/green prices raise trading frequency and risk-taking. Separately, behavioral finance shows that frequent evaluation and red coloring increase loss-averse, pessimistic responses. Calm designs reduce evaluation frequency (longer default ranges, de-emphasized daily change, privacy modes), neutralize color, remove celebration, and use notification urgency honestly.

### Cited Findings
**Regulatory record**
- **SEC (Aug 2021)** requested comment on "digital engagement practices" (DEPs): behavioral prompts, differential marketing, game-like features (gamification) and other design elements aimed at retail investors. Chair Gensler said such features "may encourage investors to trade more often" and are often "designed with an optimization function to increase revenues," which "may lead to conflicts." — [SEC press release 2021-167](https://www.sec.gov/news/press-release/2021-167)
- The SEC Investor Advisory Committee held a DEP panel on June 22, 2023 and drafted recommendations, approved in early 2024. — [SEC IAC draft recommendation (Nov 2023)](https://www.SEC.gov/files/20231117-recommendation-use-dep.pdf); [IAC approved recommendation (2024)](https://www.SEC.gov/files/approved-20240214-draft-recs-use-dep.pdf)
- The SEC's 2023 proposal on conflicts from predictive data analytics (covering DEPs and AI) was **formally withdrawn on June 12, 2025**, along with 13 other proposals. No new DEP-specific SEC rule is in force. Commentators expect continued exam scrutiny. — [Proskauer, "SEC Withdraws Fourteen Rule Proposals"](https://www.proskauer.com/alert/sec-withdraws-fourteen-rule-proposals); [Alston & Bird (Jun 2025)](https://www.alston.com/en/insights/publications/2025/06/sec-withdraws-multiple-rule-proposals); [ACA Group](https://www.acaglobal.com/industry-insights/sec-withdraws-14-rule-proposals-from-its-agenda/)
- **Robinhood confetti:** Massachusetts regulators cited the confetti animation in a December 2020 complaint as gamification aimed at inexperienced investors. Robinhood removed it in late March / early April 2021 and replaced it with "new celebratory designs." — [CNBC (Mar 31, 2021)](https://www.cnbc.com/2021/03/31/robinhood-gets-rid-of-confetti-feature-amid-scrutiny-over-gamification.html). In January 2024 Robinhood agreed to a $7.5M settlement with Massachusetts that requires it to stop using celebratory imagery for Massachusetts customers. — [Boston Globe (Jan 18, 2024)](https://www.bostonglobe.com/2024/01/18/business/robinhood-agrees-pay-75-million-settle-complaints-over-its-sales-practices/)
- **OSC/BIT 2022** (*Digital Engagement Practices in Retail Investing*): in a simulated trading experiment with $10,000 play money, users rewarded with points (no economic value) made **39% more trades**. Users shown a "top-traded" list were **14% more likely** to trade those stocks. Trading more frequently hurts returns on average. — [OSC news release](https://www.osc.ca/en/news-events/news/osc-study-finds-gamification-techniques-influence-retail-investors); [OSC Staff Notice 11-796 (Nov 2022)](https://www.osc.ca/sites/default/files/2022-11/sn_20221117_11-796_gamification-report.pdf)
- **OSC/BIT 2024** (*Gamification Revisited*): an RCT with 2,430 participants tested social feeds, copy trading, leaderboards and social-norms messaging. Seeing promoted stocks in a social feed increased trading by about 12%, and copy-trading increased trading in promoted stocks by about 18%. One secondary summary reports the social-feed effect as 11%, so the figure is inconsistent across summaries. — [OSC, Gamification Revisited](https://osc.ca/en/gamification-revisited-new-experimental-findings-retail-investing); [BIT report PDF](https://www.bi.team/wp-content/uploads/2024/10/Gamification-Revisited-Final-Report-V11-09.24.2024.docx.pdf); [Wealth Professional coverage](https://wealthprofessional.ca/investments/wealth-technology/osc-explores-impact-of-gamification-on-investors-with-new-report-and-simulation-tool/387247)
- **OSC 2026** (*Gamification and Retail Investing: Positive Use Cases*): in a simulation with 4,000+ Canadians, four positive gamification techniques raised portfolio diversification by a modest 3.5 to 4.5%. Gamification aimed at good behavior has small positive effects. — [Mondo Visione (2026)](https://mondovisione.com/media-and-resources/news/ontario-securities-commission-publishes-research-on-using-gamification-to-improv-202623/); [Wealth Professional](https://www.wealthprofessional.ca/news/industry-news/osc-research-finds-gamification-can-support-better-investor-decisions/391530)
- **UK FCA 2022** ("Gaming trading"): features of concern included celebratory messages and confetti, points/badges/leaderboards, frequent push notifications, **live price lists that flash red and green**, lists of the largest 24-hour movers, and high default amounts. In a survey of 3,000+ users of 4 apps, 3.75% showed problem-gambling behavior (vs. 3.5% of online gamblers), and over 20% when "at-risk" users are included. On the 2 crypto-offering apps with features of concern, almost 50% had invested beyond their risk appetite. The FCA notes the research is correlational. — [FCA, "Gaming trading" (Nov 21, 2022)](https://www.fca.org.uk/publications/research-articles/gaming-trading-how-trading-apps-could-be-engaging-consumers-worse)
- **UK FCA 2024 experiment:** in an FCA-built trading app with 9,000+ consumers, four DEPs were tested: flashing prices, push notifications, a trader leaderboard, and points with prize draws. Push notifications raised trades by **11%** and points/prize draws by **12%**. The share of trades in risky investments rose **8%** (push) and **6%** (points). Young people increased riskiness more for every tactic except flashing prices. Women increased frequency more under push and points. — [FCA Research Note (Jun 2024)](https://www.fca.org.uk/publications/research-notes/research-note-digital-engagement-practices-trading-apps-experiment); [Investment Executive coverage](https://www.investmentexecutive.com/news/trading-games-drive-heavier-riskier-activity-fca/)
- FINRA's Foundation (Dec 2022) found that younger investors take more risk (36% of under-35s trade options vs. 8% of 55+) and that trading-app use rose 30% from 2018. — [FINRA news release (Dec 2022)](https://www.finra.org/media-center/newsreleases/2022/new-finra-foundation-research-examines-changing-investor-landscape)

**Behavioral finance: color, evaluation frequency, attention**
- **Red suppresses risk-taking:** across 8 experiments with 1,451 people, presenting financial data in red rather than black reduced risk-taking by **15 to 30%** and prolonged pessimistic expectations after negative returns. Blue and yellow had no such effect. The effect was absent in color-blind participants and **muted in China**, where red signifies prosperity. — [Bazley, Cronqvist & Mormann, "Visual Finance: The Pervasive Effects of Red on Investor Behavior," *Management Science* 67(9), 2021](https://econpapers.repec.org/RePEc:inm:ormnsc:v:67:y:2021:i:9:p:5616-5641); [KU News (2021)](https://news.ku.edu/news/article/2021/03/29/red-color-impacts-investor-behavior-financial-research-reveals)
- **Convention:** mainland China (and Taiwan, Japan) uses red for up and green for down, the reverse of Western convention. Hong Kong follows the Western scheme. — [Benzinga explainer](https://www.benzinga.com/general/education/21/10/23258001/did-you-know-you-dont-want-to-be-in-the-green-if-youre-trading-in-china-japan-or-taiwan); [Fortune (2015)](https://fortune.com/2015/09/02/heres-what-you-may-not-know-about-the-chinese-stock-market)
- **Myopic loss aversion:** the more often people review returns, the more risk-averse they become (Gneezy & Potters 1997, QJE). A market follow-up found prices of risky assets were higher when feedback frequency was reduced (Gneezy, Kapteyn & Potters 2003, JF). Professional traders showed an even stronger effect (Haigh & List). Some replications are mixed. — [Gneezy & Potters 1997 (PDF)](https://Rady.ucsd.edu/_files/faculty-research/uri-gneezy/risk-taking.pdf); [Gneezy, Kapteyn & Potters 2003](https://econpapers.repec.org/RePEc:bla:jfinan:v:58:y:2003:i:2:p:821-837)
- **Longer horizons change choices:** workers allocate more to stocks when shown simulated 30-year return distributions instead of one-year returns. Replications are mixed, and some argue the effect reflects misestimation of long-run returns. — [Benartzi & Thaler 1999, *Management Science* 45(3)](https://econpapers.repec.org/RePEc:inm:ormnsc:v:45:y:1999:i:3:p:364-381); [Myopic loss aversion replication discussion, JDM](https://dlab.sauder.ubc.ca/sjdm/journal/12/121229/jdm121229.html)
- **Ostrich effect:** investors check portfolios less in flat or falling markets (Karlsson, Loewenstein & Seppi 2009). Retirement-account logins fall 9.5% after market declines (Sicherman et al., RFS). A counter-finding among active online traders ("meerkat effect," Gherzi et al. 2014) shows monitoring rises after both positive and negative days. — [Karlsson, Loewenstein & Seppi (CMU PDF)](https://www.cmu.edu/tepper/faculty-and-research/assets/docs/ppaper-61264983153898-ostrich-effect-1.pdf); [Sicherman et al., "Financial Attention"](https://business.columbia.edu/sites/default/files-efs/pubfiles/25997/sicherman_financial_attention.pdf); [Gherzi et al. 2014 (RePEc)](https://econpapers.repec.org/RePEc:eee:jeborg:v:107:y:2014:i:pb:p:512-526)

**What calmer products do**
- **Privacy mode / hide P&L:** Zerodha (Kite) added Privacy Mode in Aug 2024, explicitly because "Constantly seeing real-time changes in P&L can often be distracting and may tempt you to overtrade." — [Zerodha Z-Connect (Aug 22, 2024)](https://zerodha.com/z-connect/?p=387662). Trading 212 offers a "Visual Privacy Mode," including a phone-flip gesture. — [Trading 212 Help Centre](https://helpcentre.trading212.com/hc/en-us/articles/34887476742045-Introducing-Visual-Privacy-Mode). Persistence across launches matters to users; Bitstack preserves the setting, while one Trading 212 user complained it didn't persist. — [Bitstack help](https://help.bitstack-app.com/en/articles/14322200-how-do-i-hide-my-balance-on-bitstack); [Trading 212 community](https://community.trading212.com/t/introducing-privacy-mode/91187)
- **"Boring by design":** Wealthsimple's CIO described the Invest app as intentionally boring, encouraging saving and showing outcomes over time rather than inviting constant checking, in contrast to the "variable reward" mechanics of day-trading apps. — [Wealth Professional interview](https://www.wealthprofessional.ca/news/features/what-wealthsimple-thinks-of-robinhood/331239)
- Morningstar research titled "No Bells, No Whistles, No Problem" reports that investors do not necessarily want gamified features (title and snippet only; not read in full). — [Morningstar](https://www.morningstar.com/business/insights/research/what-investors-want-from-digital-trading-platforms)

### Inferences
- **Default time range:** make the net worth and portfolio chart default to 1Y (or ALL), with 1D available but not the default. This lowers evaluation frequency (Gneezy & Potters; Benartzi & Thaler).
- **Daily change hierarchy:** show total value large and daily change small, in secondary weight and muted tone. Consider a setting such as "Show daily change: Always / On tap / Never."
- **Red/green treatment:**
  - Desaturate both gain and loss hues, especially the loss color. Use them only on the change figure and arrow, never on whole rows or backgrounds.
  - Always pair color with +/− signs.
  - Offer a convention setting (Western green-up vs. China/Taiwan/Japan red-up), plus a "neutral" option that uses monochrome with sign and arrow only.
  - Because Bazley et al. found red's effect muted in China, a red-up setting is not automatically "alarming" to mainland users. The main risk is a mismatch with their convention.
- **Market movers:** both OSC (top-traded lists, +14%) and FCA (largest 24-hour movers) flag these. Place movers below the fold and title them neutrally ("Notable moves today," not "🔥 Top gainers"). Default to sector or index context rather than leaderboards, with no rank numbers or celebratory styling.
- **No celebration mechanics:** no confetti, streaks, badges, points or "You're up 12%!" toasts. Milestones, if any, should be quiet and informational ("Your net worth passed $100k on Oct 3").
- **Notifications:** off by default for price moves. When enabled, use the passive interruption level (section 5) and a daily or weekly digest. Never use Time Sensitive for price movement. The FCA experiment ties push notifications to +11% trades and +8% risky-trade share.
- **Privacy mode:** offer one tap or long-press on the net worth to blur all amounts, persisted across launches, keeping percentages optional (users asked for this on Trading 212).
- **Real-time cadence:** for a personal-finance (not trading) app, refresh on a calm cadence (e.g., pull-to-refresh plus background refresh every minute or so) and show "As of 10:42" rather than streaming ticks. Calm Tech's "delays" pattern and WCAG's "control update frequency" support a user-selectable refresh rate.
- **AI assistant:** apply the same rules. No urgency language ("Act now"), no trade nudges, and describe moves in context ("Down 2.1% today; still up 14% over 12 months"), which is a "zoom out" framing.

### Gaps
- I found no published A/B data from a major app on the effect of hiding daily change or defaulting to longer chart ranges. The evidence is from lab and behavioral-finance studies.
- I found no study on "muted" vs. saturated red specifically. Bazley et al. compared red vs. black/blue, not saturation levels.
- I could not verify a Wealthsimple feature that hides daily returns. Search results suggest Wealthsimple has refreshed returns every 15 minutes (2019 update), the opposite of hiding ([Wealthsimple magazine](https://wealthsimple.com/en-us/magazine/portfolio-dashboard-update), via search snippet only).
- I found no regulator-published "calm design" checklist. Regulators describe harms, not prescriptive UI patterns. The 2026 OSC positive-use-case report is closest but was only read through secondary coverage.

---

## 5. Tone of voice / microcopy and interruptions (modals, permissions, notifications, onboarding)

### Takeaway
Calm copy is plain, specific, active, owns mistakes once, and never manufactures urgency. Banking-style voice should "convey trust and stability." Calm interruptions are contextual and user-initiated: ask for permissions at the point of use, never at launch unless essential; use alerts only for actionable, uncommon or irreversible situations; and match notification interruption levels to real urgency.

### Cited Findings
**Voice and copy**
- Apple: "The words for a banking app might convey trust and stability." Be clear ("If you can use fewer words, do so"). Use plain language without jargon. Use verbs on buttons ("just saying 'Send' often works better than 'Let's do it!'"). Prefer "Unable to load content" over "We're having trouble…". Place errors near the problem, "avoid blame," and say how to fix it. Interjections like "'oops!' or 'uh-oh' are typically unnecessary and can sound insincere." Empty states should guide people to next actions and not hold crucial information, since they are temporary. Keep a term list for consistency. — [Apple HIG, Writing](https://developer.apple.com/design/human-interface-guidelines/writing)
- Monzo: write as you'd speak face to face. "There's no room at all for unexplained financial jargon." Use active voice and put what matters to the reader first. Handle money worries with care and never make light of them; keep humor out of sensitive topics. When at fault, say "We're sorry" (not "We'd like to apologise") once, then focus on the fix. For bad news that isn't Monzo's fault, don't apologize, but stay warm. Humor is "a pinch… not a dollop," with none in customer service and very little in operational comms. — [Monzo, Tone of voice](https://monzo.com/tone-of-voice)
- Headspace: no official tone guide found. Secondary analyses describe "calm" as the core attribute with a touch of quirkiness, and frame benefits around sleep, focus and anxiety. — [standards.site, Headspace brand guidelines summary](https://standards.site/examples/headspace); [Marketing Monk analysis](https://www.marketingmonk.so/p/headspace-s-growth-marketing-strategies) (secondary)

**Alerts and modals**
- "Use alerts sparingly." "Avoid using an alert merely to provide information." "Avoid showing an alert when your app starts"; instead "show cached or placeholder data and a nonintrusive label that describes the problem." Avoid alerts for common, undoable actions, even destructive ones. Tone: "be direct, and use a neutral, approachable tone," neither "oblique or accusatory" nor "masking the severity." Titles should not read like "Error 329347 occurred" and should not wrap past two lines. Use one- or two-word verb buttons. Apply the destructive style only to actions people didn't deliberately choose, and always include Cancel. — [Apple HIG, Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)

**Permission prompts and consent**
- "Request permission only when your app clearly needs access." "Ideally, wait to request permission until people actually use an app feature that requires access." "Avoid requesting permission at launch unless the data or resource is required for your app to function." A pre-alert screen should have only one button ("Continue"/"Next"), no Cancel, never mimic the system alert, never use "Allow," and never offer incentives. Purpose strings should be "a brief, complete sentence… straightforward, specific," in active voice. Good: "The app records during the night to detect snoring sounds." Poor: "Microphone access is needed for a better experience." — [Apple HIG, Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)

**Notifications**
- Interruption levels: **Passive** ("view at their leisure"), **Active** (default), **Time Sensitive** (needs immediate attention, "like an account security issue"; relevant now or "within an hour"; breaks through Focus), **Critical** (health and safety, entitlement required). "Build trust by accurately representing the urgency of each notification." "Never use the Time Sensitive interruption level to send a marketing notification." Marketing pushes require explicit opt-in. Provide in-app notification settings. Scheduled Summary lets people batch notifications. — [Apple HIG, Managing notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)

**Onboarding**
- Onboarding should be "fast, fun, and optional." "Teach through interactivity." "If you try to teach too much, people can feel overwhelmed." Prefer context-specific tips (TipKit) to a single flow. "Postpone nonessential setup." Provide reasonable defaults. Ask for permissions at first use of the feature unless the app can't function without them. Let people experience the app before asking for ratings or purchases. — [Apple HIG, Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)

### Inferences
**Copy rules for this app**
- No exclamation marks in system copy.
- No hype words ("soaring," "crashing," "🔥," "Don't miss").
- No countdowns or "act now."
- Numbers come before adjectives: "Down 2.1% today," not "Big drop!"
- On bad days, add context in the same line ("Down 2.1% today · up 14% this year").

**Error and empty states**
- Stale data: show "Prices as of 10:42 · Pull to refresh," with no red banner.
- Empty watchlist: "Add a few companies you follow. You'll see them here." with a single Add button.
- AI assistant failure: "Couldn't get an answer right now. Try again." with no "Oops!"

**Interruptions**
- Ask for notification permission only when the user creates their first price alert or turns on a digest, with a one-button explainer. Never ask at first launch.
- Use the Passive level for market digests. Reserve Time Sensitive for security and login events only.

**Consent and disclosure sheets** (AI disclaimer, data linking)
- Present them when the feature is first used.
- Keep a single primary action plus a clear secondary "Not now." The no-Cancel rule applies only to pre-permission screens.

### Gaps
- I found no primary Headspace, Calm or Wealthsimple voice guide. Their tone claims are secondary or absent.
- Apple's HIG doesn't explicitly ban exclamation marks; the closest guidance is avoiding interjections and "cute or clever" labels.

---

## 6. Loading and waiting: skeletons vs. spinners, perceived performance, layout shift, Doherty threshold

### Takeaway
The calmest load is the one users never notice. Respond within 0.1 to 0.4 s, show cached content immediately, use layout-matched placeholders (not blank screens or frame-only skeletons) for full-page loads under 10 s, reserve space so nothing jumps, and avoid perpetual shimmer or staggered pop-ins that make the screen feel unsettled.

### Cited Findings
- Response-time limits: **0.1 s** feels instantaneous (direct manipulation). **1 s** keeps the flow of thought, though the delay is noticed. **10 s** is the limit of attention. Above 1 s, show that work is happening. From 2 to 10 s, a full percent-done bar may be excessive. Above 10 s, use a percent-done indicator and a way to interrupt. — [Nielsen, NN/g, "Response Times: The 3 Important Limits" (1993/2014)](https://www.nngroup.com/articles/response-times-3-important-limits/)
- Doherty threshold: productivity soars when system response is under **400 ms** (Doherty & Thadani, IBM 1982, replacing a 2 s standard). Use perceived-performance techniques. A deliberately added short delay can make a process feel more valuable and build trust. — [Laws of UX, Doherty Threshold](https://lawsofux.com/doherty-threshold/)
- Skeleton screens: unnecessary under about 1 s. Use for full-page loads under 10 s, spinners for single modules (e.g., one dashboard card), and progress bars above 10 s or for process tasks. Use content placeholders that mirror the final layout, not "frame-display" skeletons, which are "essentially equivalent to a spinner." Skeleton animation is optional and "can be distracting." — [Tankala, NN/g, "Skeleton Screens 101" (2023; reviewed 2026)](https://www.nngroup.com/articles/skeleton-screens/)
- Apple: "The best content-loading experience finishes before people become aware of it." Show something as soon as possible (placeholder text, graphics), or people "can interpret the lack of content as a problem." Let people do other things while loading. Use determinate progress when duration is known. — [Apple HIG, Loading](https://developer.apple.com/design/human-interface-guidelines/loading)
- Layout stability (web metric, transferable principle): CLS of ≤0.1 is good, 0.1 to 0.25 needs improvement, and >0.25 is poor. Shifts within 500 ms of a discrete user input are excluded as expected. When a user action triggers a slow request, "create some space right away and show a loading indicator." Animate with transforms rather than layout properties. — [web.dev, Cumulative Layout Shift](https://web.dev/articles/cls)
- Temporal density (speed) is the main reason dense pro tools like Bloomberg feel usable. Responses under about 100 ms feel simultaneous, and waits over a minute are better handled with later notification. — [Matt Ström, "UI Density"](https://mattstromawn.com/writing/ui-density)

### Inferences
- **Cold launch:** render the last cached snapshot immediately (net worth, watchlist values with an "as of" time), then update in place with a `.smooth` numeric transition. Avoid a spinner over a blank screen.
- **Placeholders:**
  - Use fixed-height rows that match final dimensions, so rows don't jump when logos or prices arrive.
  - Prefer a static or very slow shimmer, to avoid perpetual motion. Under about 1 s, show nothing special.
  - Avoid revealing sections one by one as each API returns (staggered pop-in). Either batch the reveal of a section, or reserve the space so late arrivals fill in without moving neighbors.
- **AI assistant:** acknowledge within about 100 ms (send state, user bubble in place). Stream text into a bubble whose height grows smoothly while the scroll stays anchored. Avoid indefinite "typing" dots past about 1 s without progress text such as "Looking at your holdings…", which follows NN/g's absolute-progress guidance for unknown durations.
- **Optimistic UI:** adding or removing a watchlist item or toggling privacy mode should update instantly and reconcile silently. Show an inline revert message only on failure.

### Gaps
- I found no primary, authoritative source on optimistic UI and anxiety, or on staggered pop-ins causing anxiety. Those points are inferences from response-time and layout-stability principles.
- Apple's HIG gives no numeric thresholds for when to show a placeholder.

---

## 7. Haptics and sound restraint

### Takeaway
Haptics should be rare, consistent, causally tied to a user action, and matched in intensity to the visual. The ideal is haptics "people may not be conscious of, but miss when it's turned off." In a calm finance app, haptics belong on deliberate user actions, never on market events or price ticks.

### Cited Findings
- Use system haptic patterns according to their documented meanings, and don't repurpose them. Use haptics consistently to build "a clear, causal relationship between each haptic and the action that causes it." "If a haptic doesn't reinforce a cause-and-effect relationship, it can be confusing and seem gratuitous." — [Apple HIG, Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- "Prefer using haptics to complement other feedback." "Match the intensity and sharpness of a haptic with the intensity and sharpness of the animation it accompanies." — [Apple HIG, Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- "Avoid overusing haptics… a haptic can feel just right when it happens occasionally, but become tiresome when it plays frequently." "The best haptic experience is one that people may not be conscious of, but miss when it's turned off." Prefer short haptics for discrete events, since long-running haptics "dilute the meaning… and distract people." Make haptics optional. — [Apple HIG, Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- Calm Technology lists haptics as a calm channel that can "communicate without speaking." — [calmtech.com](https://calmtech.com/)
- Make motion optional and don't rely on it alone. Supplement with haptics and audio. — [Apple HIG, Motion](https://developer.apple.com/design/human-interface-guidelines/motion)

### Inferences
- **Allowed:**
  - `.selection` while scrubbing a chart, ideally only when crossing a day, month or year boundary rather than every data point.
  - A light `.impact` (soft or light style) when a sheet snaps to a detent.
  - `.success` once when a user-initiated save completes, such as a new alert created.
  - `.warning` only before a deliberate destructive confirmation.
- **Not allowed:** haptics on price updates, market open or close, AI message streaming tokens, or arrivals of movers or news.
- **Sound:** none by default. A finance app has no need for UI sounds. Respect the system haptics setting and offer an in-app toggle.

### Gaps
- I found no study measuring haptic frequency against perceived anxiety in finance apps.
- Apple's HIG gives no numeric frequency limits for haptics.

---

## 8. Chinese-language design writing on 从容感 / 松弛感 / 呼吸感

### Takeaway
Chinese practitioner writing mostly expresses 从容感 through 留白 (whitespace) creating 呼吸感. Recurring techniques: macro and micro whitespace, spacing and background tone instead of divider lines, generous whitespace on top-level pages but moderate on deeper pages, clear type hierarchy through size, weight and color, and 克制 (restraint) in three areas: color, information and commercial desire. This tradition is explicitly contrasted with China's portal-era habit of cramming. I found no rigorous, numeric 从容感 framework on uisdc, zcool, zhihu or sspai.

### Cited Findings
- 留白 creates 呼吸感 and need not be white; any color or texture works. Dark whitespace can spotlight a core element. Whitespace has two kinds: **宏空间** (around layout elements, page margins, between blocks) and **微空间** (between and within elements: line spacing, letter spacing). Whitespace defines boundaries and relationships through Gestalt principles, without boxes or tables. Don't cram everything onto one page. Work out the information architecture and user flows before whitespace. — [人人都是产品经理, 《从头开始梳理：设计中的留白，该如何用好？》 (2018, translated from Tubik Studio)](https://www.woshipm.com/ucd/1049110.html)
- Current trends favor "大的留白让页面更有'呼吸感'," but second- and third-level pages should not overuse big whitespace. Use spacing or light-gray backgrounds instead of divider lines to form modules. Separate hierarchy by font size, weight and color, with a large heavy title of up to 32 pt (at 1×). Use frosted glass (毛玻璃) with restraint. — [柚子皮的设计笔记, 《提升UI界面质感的小技巧们》, 人人都是产品经理 (2021-01-15)](https://www.woshipm.com/pd/4339133.html)
- 克制 has three levels: 颜色克制 (fewer colors and variations, no fighting for attention), 信息克制 (trim primary information, remove noise) and 欲望克制 (restrain commercial desire and don't over-stimulate users). Good interfaces are like 山水画 (shan-shui painting), leaving room for thought and emotion: "需要为用户留下思考的空间". Airbnb's calm home screen is contrasted with Ctrip's ad-heavy one. Warning: "切忌形式大于内容" (form must not override content). — [一直产品汪, 《产品"无"之道(五)——表现篇》, 人人都是产品经理 (2021-12-18)](https://www.woshipm.com/pd/5256416.html)
- The same author notes that Chinese internet design has, since the portal era, habitually piled up information and features, which runs against 呼吸感. — [人人都是产品经理 (search summary)](https://www.woshipm.com/pd/5256416.html)
- A UXmatters article surfaced for 从容感 queries argues that calm does not require emptiness: dense screens with regular geometry and consistent spacing feel calm, and crowded headers create tension while wide margins create calm. — [UXmatters, "The Hidden Geometry of Calm Screens" (2026)](https://www.uxmatters.com/mt/archives/2026/01/the-hidden-geometry-of-calm-screens.php); [UXmatters, "The Emotional Map of User Interface Zones" (2025)](https://www.uxmatters.com/mt/archives/2025/11/the-emotional-map-of-user-interface-zones.php)
- Motion restraint (中文): functional motion should help users understand and get through the current state, and delay effects should not be abused. — [人人都是产品经理, 动效 article](https://www.woshipm.com/pd/809190.html) (via search summary; not fetched)
- "松弛是最好的高级感" circulates as a Douyin hashtag, mostly about fashion. It reflects the cultural mood but has no UI substance. — [Douyin hashtag page](https://www.douyin.com/hashtag/7628515304519239695)

### Inferences
- **Mapping to this app:**
  - Use larger macro spacing between home sections (net worth / watchlist / movers / news) and tighter micro spacing within rows.
  - Drop row dividers in favor of grouped backgrounds or insets.
  - Use one accent color.
  - Reduce red/green to small change labels only (颜色克制).
  - Keep the home screen to three or four modules (信息克制).
  - No promotional banners, trading nudges or celebration (欲望克制).
- 从容感 in Chinese usage also implies the product isn't hurrying the user, which matches the motion (section 3) and interruption (section 5) findings: no countdowns, no auto-advancing content, no urgency copy.
- For Chinese-speaking users, the red-up convention must be supported. Calm comes from desaturation and small color areas, not from swapping meanings.

### Gaps
- I could not retrieve primary articles from 优设网 (uisdc.com), 站酷 (zcool), 知乎 or 少数派 on 从容感, 松弛感 or 呼吸感. Searches returned mostly 人人都是产品经理 (woshipm) articles, which are summarized above.
- One phrase seen in search snippets, "疏比密更精致、对齐比错位更简约、少技巧比多技巧更高级," could not be matched to a verified source page, so it is not cited above.
- I found no Chinese-language source giving numeric spacing scales for 呼吸感. The only concrete number found was the 32 pt (1×) large title in the woshipm 2021 article.
- I found no Chinese-language research on 涨跌色 (up/down colors) and investor anxiety, beyond the Bazley et al. finding that red's effect is muted in China.
