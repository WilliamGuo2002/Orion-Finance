# What makes a digital interface feel premium (高级感): principles, evidence and measurable techniques

Scope note: research was done in November 2026 with web search and fetch. Some canonical sources (the Refactoring UI book and Schoger's Medium article, Apple HIG pages, Bringhurst's print text) could not be fetched directly: Medium returned 403 and Apple HIG loads its content with JavaScript. Where numbers come from secondary notes on those works, or from general knowledge, this is marked. Context for the inferences: an iOS personal-finance app (SwiftUI) with a warm beige/cream background, a tan/caramel accent, serif headlines, and rounded cards with shadows.

---

## 1. What do canonical design sources say produces a "premium" impression?

### Takeaway
The canonical sources agree on one mechanism: premium comes from **restraint plus finish**. Use fewer elements, colors, weights and effects, and execute what remains with obsessive consistency and detail ("Less, but better"; "Nothing must be arbitrary"). Hierarchy should come from *de-emphasising* secondary content (weight, colour, spacing), not from making everything bigger, bolder or more colourful.

### Cited Findings
**Restraint and reduction (Dieter Rams)**
- Rams' 10th principle is "As little design as possible": focus on essentials and leave out non-essentials, summarised as **"Less, but better"** and "Back to purity, back to simplicity." — [Vitsœ: Dieter Rams' ten principles](https://www.vitsoe.com/us/about/good-design)
- Principle 5, *Unobtrusive*: products are tools ("Products fulfilling a purpose are like tools"), so design should be neutral and restrained, leaving room for the user's self-expression. — [Vitsœ](https://www.vitsoe.com/us/about/good-design)
- Principle 8, *Thorough down to the last detail*: "Nothing must be arbitrary or left to chance"; care in the process shows respect for the user. — [Vitsœ](https://www.vitsoe.com/us/about/good-design)
- Principle 3, *Aesthetic*: "only well-executed objects can be beautiful." Principle 6, *Honest*: never claim to be more valuable or powerful than you are. Principle 7, *Long-lasting*: "It avoids being fashionable." — [Vitsœ](https://www.vitsoe.com/us/about/good-design)

**Hierarchy, whitespace and de-emphasis (Refactoring UI, Wathan & Schoger, via reader notes)**
- "De-emphasizing secondary information is as important as emphasizing primary information." — [Refactoring UI notes (rjseymour66)](https://rjseymour66.github.io/webdev/refactoring-ui/)
- "Size isn't everything." Build hierarchy with font weight and colour, not just size. Limit hierarchy to about 2–3 text colours and weights. — [Book summary: Refactoring UI (sglavoie)](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- "You rarely need more than two font weights … A regular and a semibold cover most cases." — [Refactoring UI notes (rjseymour66)](https://rjseymour66.github.io/webdev/refactoring-ui/). The sglavoie summary says "2–3", so the two notes differ slightly.
- Labels: make them smaller, lower in contrast and lighter. Better still, fold them into the value ("12 left in stock" instead of "In stock: 12"). — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- Whitespace: "Start with too much white space," then remove it until it feels right. Put more space between groups than within them. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- Use fewer borders. Separate with spacing, a subtle shadow, or a background-colour difference instead. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- On coloured backgrounds, don't use plain grey text. Use a colour of the same hue with lower saturation or lightness. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- Use a very dark grey rather than true black. Plan 8–10 grey shades. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/); [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)
- Corner radius carries personality: a small radius "reads as formal" (about 0–4px) and a large radius "reads as casual" (12–16px and up). — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)
- Align mixed font sizes on their baselines, not their centres. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)

**Typography (Bringhurst, Butterick)**
- Bringhurst on line length: "Anything from 45 to 75 characters is widely regarded as a satisfactory length of line … The 66-character line (counting both letters and spaces) is widely regarded as ideal." For multi-column layouts, 40–50 characters. — [The Elements of Typographic Style Applied to the Web, §2.1.2](http://webtypography.net/2.1.2)
- Bringhurst: "Genuine small caps are not simply shrunken versions of the full caps." They differ in stroke weight, letterfit and proportions. Faking typographic features is a detail failure. — [webtypography.net §3.2.2](http://webtypography.net/3.2.2)
- Butterick: body text "largely determines" overall typographic quality, so get body text right first. — [Practical Typography: Typography in ten minutes](https://practicaltypography.com/typography-in-ten-minutes.html)
- Butterick: web body text 15–25px, line spacing 120–145% of the point size, 45–90 characters per line. Buy a professional font and "never" use Times New Roman or Arial. — [Practical Typography](https://practicaltypography.com/typography-in-ten-minutes.html)

**Material and depth**
- Refactoring UI: assume a light source from above, so raised elements get a lighter top edge and a shadow below. Keep a fixed elevation system ("five shadow options is usually plenty"): small shadows for buttons, medium for dropdowns, large for modals. Combine a large diffuse shadow with a tight, darker one. "Don't overdo it." — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)

### Inferences
- The common thread across Rams, Refactoring UI and Bringhurst is that **"premium" is a by-product of discipline, not a style**. Fewer variables (colours, sizes, weights, radii, shadows), each applied identically everywhere, produce the "nothing arbitrary" impression.
- For a data-heavy finance app, the strongest single lever is **de-emphasis**. Push labels, metadata, currency codes and dates down in weight and colour so that one number per screen (net worth, month's spending) clearly dominates. That one dominant element is the "contrast of scale".
- The app's rounded cards plus shadows should follow the Refactoring UI elevation logic. Cards resting on the page get the smallest shadow, or none (a background-tone difference or a hairline instead). Larger shadows are reserved for floating sheets. Shadows on every card at a medium or large level read as "template", not "crafted".
- Rams' "avoids being fashionable" is a useful check on 2025–26 trends: adopt Liquid Glass only where the system provides it (see Q5), and keep the content layer quiet.

### Gaps
- Could not fetch Refactoring UI directly (Medium 403). The specific claims "avoid font weights under 400 for UI work" and "use 400–500 for normal, 600–700 for emphasis" are often attributed to the book but were not confirmed in the notes I fetched.
- Did not fetch Müller-Brockmann's *Grid Systems*, Tidwell's *Designing Interfaces*, or Norman's *Emotional Design* directly. Norman's visceral/behavioral/reflective framework is relevant: premium feel works at the visceral and reflective levels. That framework is cited here from general knowledge only. NN/g confirms Norman explored the aesthetic-usability idea in *Emotional Design* (2004) ([NN/g](https://www.nngroup.com/articles/aesthetic-usability-effect/)).
- Bringhurst's classical type scale (6, 7, 8, 9, 10, 11, 12, 14, 16, 18, 21, 24, 36, 48, 60, 72) and his 5–10% letterspacing rule for capitals were not confirmed from a fetched page. The webtypography.net §3.2.2 page covers small caps for abbreviations, not letterspacing.

---

## 2. What does empirical research say about premium, aesthetic and trust perception?

### Takeaway
People judge visual appeal within about 50ms. Those judgments are driven mostly by **visual complexity, more than colourfulness**, and they spill over into perceived usability and trust. Finance-site users lean on "design look" for credibility more than users of any other category studied. Marketing research supports **white space, quiet branding and (for heritage-positioned brands) lower saturation** as status signals, with caveats: the effects depend on culture and positioning.

### Cited Findings
**Aesthetic-usability effect**
- Kurosu & Kashimura (Hitachi, 1995) tested 26 ATM interface layouts with 252 participants. Aesthetics correlated more strongly with *perceived* ease of use than with *actual* ease of use. — [NN/g, Kate Moran, "The Aesthetic-Usability Effect" (2024, reviewed 2026)](https://www.nngroup.com/articles/aesthetic-usability-effect/)
- NN/g caveat: attractive design makes users forgive minor usability problems "but not large ones". It can also mask problems in usability tests, so watch what users do, not what they say. — [NN/g](https://www.nngroup.com/articles/aesthetic-usability-effect/)

**First impressions in about 50ms**
- Lindgaard, Fernandes, Dudek & Brown (2006), *Behaviour & Information Technology* 25(2):115–126: visual appeal can be assessed within 50ms, and 50ms judgments were consistent with judgments after longer viewing. — [SciSpace record](https://typeset.io/papers/attention-web-designers-you-have-50-milliseconds-to-make-a-3axej7ku89); [Nature news, Jan 2006](https://www.nature.com/news/2006/060109/full/news060109-13.html)
- Press coverage framed this as a halo effect: the first impression colours later judgments of credibility and usability. One critic noted that the study does not show whether users *stay*. — [Nature news](https://www.nature.com/news/2006/060109/full/news060109-13.html); [bit-tech coverage](https://www.bit-tech.net/news/website_hot_or_not/1/)

**Visual complexity and colourfulness (Reinecke & Gajos)**
- Reinecke et al., CHI 2013: 548 volunteers rated 450 websites seen for 500ms. Computational models of complexity and colourfulness, plus demographics, explain about half the variance in appeal. **Colourfulness matters, but "is not nearly as important as the overall visual complexity."** The first impression later affects perceived usability and trustworthiness. — [Harvard IIS paper page](https://www.eecs.harvard.edu/~kgajos/papers/2013/reinecke13predicting.shtml); [PDF](https://wildlab.cs.washington.edu/Publications_files/Reinecke_CHI2013.pdf)
- Reinecke & Gajos, CHI 2014 ("Quantifying Visual Preferences Around the World"): about 2.4 million ratings from nearly 40,000 participants. Preferences vary by demographics, and **higher education correlates negatively with liking colourful, complex sites**. — [PDF](https://kgajos.seas.harvard.edu/papers/reinecke14visual.pdf)

**Credibility and trust (Stanford / Fogg)**
- Stanford Web Credibility Guidelines include #6 "Design your site so it looks professional (or is appropriate for your purpose)", #9 "Use restraint with any promotional content (e.g., ads, offers)", and #10 "Avoid errors of all types, no matter how small they seem." People "quickly evaluate a site by visual design alone." — [Stanford Web Credibility Guidelines](https://credibility.stanford.edu/guidelines/index.html)
- Fogg et al. (2002, Consumer WebWatch, about 2,684 participants): **46.1%** of consumer comments cited overall design or look when judging credibility. For **finance sites the figure was 54.6%, the highest category** (search 52.6%, travel 50.5%, e-commerce 46.2%). Finance *experts* in the companion study mentioned the look in only 16.4% of comments. Summary line: "To look good is to be good." Caveat: these are shares of comments, not of people. — [ClickZ, "Study: For Site Cred, Looks Matter"](https://clickz.com/study-for-site-cred-looks-matter/56564/); [Wikipedia: Stanford Web Credibility Project](https://en.wikipedia.org/wiki/Stanford_Web_Credibility_Project); [Design for Hackers summary](https://designforhackers.com/?p=413)

**White space as a prestige signal (Pracejus, Olsen, O'Guinn)**
- *Journal of Consumer Research* 2006: white space takes its meaning from cultural history (minimalism and the corporate art of the late 1950s), and creative directors and ordinary consumers share that understanding. — [IDEAS/RePEc](https://ideas.repec.org/a/oup/jconrs/v33y2006i1p82-90.html)
- *Journal of Business Research* 2012: creative directors said they use mostly-white-space ads to look good, draw attention, focus on the product, and **convey brand prestige**. — [EconPapers](https://econpapers.repec.org/RePEc:eee:jbrese:v:65:y:2012:i:6:p:855-860)
- *International Journal of Research in Marketing* 2013, "When white space is more than 'burning money'": the effect works as visual rhetoric, not merely as a costly signal, and **its meanings differ across cultures**. — [IDEAS/RePEc](https://ideas.repec.org/a/eee/ijrema/v30y2013i3p211-218.html)

**Quiet vs. loud branding (status signalling)**
- Han, Nunes & Drèze (2010), *Journal of Marketing* 74(4):15–30: luxury brands **charge more for "quieter" products** with subtle, small logos, which appeal to wealthy "patricians" low in need for status. Counterfeiters mostly copy the cheaper, louder items. — [Gwern-hosted PDF](https://Www.Gwern.net/doc/culture/2010-han.pdf); [AcaWiki summary](https://acawiki.org/Signaling_Status_with_Luxury_Goods:_The_Role_of_Brand_Prominence); [ScienceDaily](https://www.sciencedaily.com/releases/2010/07/100726094917.htm)

**Colour saturation and perceived value**
- Zhou, Xiao, Yoon & Zhu (marketing research; seven experiments and field studies): **lower saturation increased perceived brand status**, mediated by a perception of heritage or continuity. The effect weakens for brands that stress a recent founding and **reverses for brands positioned as innovative**. Saturation also affected willingness to pay. — [ESCP library record (as surfaced by search; full text not read)](https://libraries.escp.eu/doc/bth/192754203)
- Contrary result: Bansal (2026, *International Journal of Humanities and Social Science*, single perfume stimulus) found *high* saturation increased perceived luxury, with no difference between low and medium. This is a lower-tier journal, so weigh it accordingly. — [IJHSS paper page](https://internationaljournalssrg.org/IJHSS/paper-details?Id=564)
- Brasel & Hagtvedt (*Journal of Consumer Research*): highly saturated colour raises arousal, captures attention and inflates perceived size. Saturation is a loudness and attention lever, not a neutral choice. — [Boston College news](https://www.bc.edu/content/bc-web/bcnews/nation-world-society/business-and-management/color-and-consumer-perception.html)
- A Dundee thesis found low-*value* (darker) logo colours increased luxury perception and high saturation reduced pleasure and luxury perception (secondhand summary). — [Dundee thesis record](https://discovery.dundee.ac.uk/en/studentTheses/the-influence-of-brands-logo-colours-on-consumer-emotions-and-lux/)
- Black-and-white imagery and luxury: Wang et al. (2022, *Journal of Consumer Behaviour*) studied whether black-and-white boosts luxury ad evaluations. Seen only via Kolenda's summary, which presents grayscale as reading luxurious. — [Nick Kolenda, "Grayscale luxury"](https://nickkolenda.com/tactics/grayscale-luxury)

**Typeface weight and luxury**
- I found **no rigorous primary study isolating font weight and price or luxury perception**. Popular claims ("thin fonts signal premium", a 2012 *Journal of Consumer Psychology* letter-spacing study) could not be verified. Brumberger (2003), cited secondhand, links light typefaces to "delicate, gentle, feminine" and heavy ones to "strong, aggressive". An unpublished serif-vs-sans logo experiment hypothesises that serifs raise luxury perception. — [Kolenda, "A thin, spacious, and uppercase font"](https://kolenda.io/tactics/luxury-fonts); [Marketing Trends Congress 2024 paper](https://archives.marketing-trends-congress.com/2024/pages/PDF/133.pdf)

### Inferences
- For a finance app, the evidence stacks: (a) users judge in about 50ms, (b) complexity is the main driver, (c) finance users rely on "look" for credibility more than any other category, and (d) a good first impression spills over into trust. **Reducing visual complexity on the home and overview screens is the highest-return premium move**, more than palette tweaks.
- The saturation research fits the current beige, caramel and serif direction. That aesthetic signals "heritage and continuity" (like a private bank), and low saturation reinforces it. The Zhou et al. moderator matters, though: if the app wants to feel *innovative* or *tech-forward*, extreme desaturation can work against it. Pick one positioning and stay consistent.
- Han et al.'s "quiet luxury" maps to UI as quiet branding: no logo splashes, no loud promotional banners or upsell cards (also Stanford guideline #9). Confidence is expressed through absence.
- Expert vs. consumer split (16.4% vs. 54.6%): looks win the first impression, but expert-level trust needs content signals too (accuracy, clear data sources, timestamps, no errors; Stanford #1, #8, #10).

### Gaps
- Did not verify Tuch et al. (2012), which reportedly finds that low complexity *and* high prototypicality maximise first-impression appeal. It is relevant to "don't be too novel", but not checked in this session.
- No peer-reviewed study found that directly measures "premium" perception in *mobile app* UI, as opposed to websites, ads or packaging. The transfer is inferred.
- Sample sizes and effect sizes of Zhou et al. were not checked, and the ESCP link was surfaced by search, not opened.

---

## 3. What do luxury, fashion and hospitality brand systems teach, and which lessons translate to app UI (and which are traps)?

### Takeaway
Luxury brand systems teach **quietness, editorial pacing, a narrow material/colour palette, and composed (not glamorous) typography**. Brand presence comes through consistency and craft rather than volume. The main trap in translating this to apps is **low-contrast, thin, small, light-grey text**, adopted precisely *because* it looks high-end. It fails legibility, accessibility and mobile-in-sunlight use.

### Cited Findings
**Aesop (example of quiet luxury)**
- Work & Co built Aesop's digital design system: layouts and typography "inspired by the iconic product packaging", and motion designed to echo the calm of the stores. — [Work & Co: Aesop](https://work.co/clients/aesop)
- Aesop typography is described as "composed, literate and deliberately unglamorous". — [Made Good Designs: Aesop brand guidelines](https://madegooddesigns.com/aesop-brand-guidelines/)
- Packaging: clean sans-serif in black ink on **white or cream** labels, with amber glass as the signature material. One material plus one ink colour is a tiny palette. — [The Enterprise World: Aesop case study](https://theenterpriseworld.com/aesop-case-study/); [Lazada Brand Wiki: Aesop](https://brandwiki.lazada.sg/aesop/)
- Aesop chose a "quieter path" of editorial content (its Library covers literature, architecture, design) rather than heavy advertising. Stores are each different yet unmistakably Aesop, so the brand lives in consistent principles, not identical templates. — [The Enterprise World](https://theenterpriseworld.com/aesop-case-study/)

**Apple / B&O / MUJI (as cited in Chinese 高级感 writing)**
- A digitaling article uses Apple's minimalism, B&O's "干脆" (crisp, decisive) speakers and MUJI's low-saturation "性冷淡" restraint as reference points for 克制 (restraint). It quotes Rams' "as little design as possible", and gives iPhone's labour-intensive symmetry as an example of "极致" (perfection) in detail. — [数英, 行若老沈, 《说一说"高级感"是什么鬼》 (2020)](https://www.digitaling.com/articles/315265.html)

**Trap: the low-contrast "elegant" grey text**
- NN/g: designers use light-grey text because it fits minimalism and suits brands wanting a "high-end, elite, or sophisticated" image. They often copy big brands assuming those choices were tested, which is "not always the case". — [NN/g, Katie Sherwin, "Low-Contrast Text Is Not the Answer" (2015)](https://www.nngroup.com/articles/low-contrast/)
- Harms: eye strain, **lower trust in hard-to-read text**, poor discoverability, dimmed text that looks disabled, and text "nearly impossible" to read in sunlight on mobile. It especially hurts users with low vision, presbyopia, cataracts and similar conditions. "Low-contrast text may be trendy, but it is also illegible, undiscoverable, and inaccessible." — [NN/g](https://www.nngroup.com/articles/low-contrast/)
- NN/g fix: reduce density by removing or relocating content, and change prominence through size, position and padding instead of dimming. — [NN/g](https://www.nngroup.com/articles/low-contrast/)
- WCAG 2.x SC 1.4.3 (AA): 4.5:1 for normal text and 3:1 for large text. Refactoring UI notes restate this as text under 18px needing 4.5:1. — [W3C Understanding SC 1.4.3](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html); [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)

**Trap: Liquid Glass translucency and readability (2025–26)**
- Apple's June 2025 redesign introduced "Liquid Glass", a translucent material that "refracts light and dynamically reacts", across iOS 26 and the other platforms. Tab bars shrink on scroll to give content focus. — [Apple Newsroom, 9 June 2025](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/); [MacRumors](https://www.macrumors.com/2025/06/09/apple-announces-liquid-glass/)
- Translucency drew readability complaints during beta, and Apple changed translucency levels between betas. — [TechRadar](https://www.techradar.com/tech/apple-reveals-major-visual-redesign-for-ios-26-macos-26-and-more-at-wwdc-2025); [MacRumors](https://www.macrumors.com/2025/06/09/apple-announces-liquid-glass/)

**Luxury typography folklore**
- Practitioner guidance says luxury wordmarks tend toward "thin, spacious, and uppercase" type. This is a brand-logo convention, not evidence for UI body text. — [Kolenda, luxury fonts](https://kolenda.io/tactics/luxury-fonts)

### Inferences
**Lessons that translate to app UI:**
- Editorial pacing: one idea per screen region, generous margins, a large serif display number or headline over quiet sans UI text.
- A materially narrow palette: one ground (cream), one ink (near-black warm grey), one accent (caramel).
- Calm motion: short, eased transitions with no bounce or confetti.
- Quiet branding: no logo repetition, no promotional modules.
- Consistent principles rather than identical screens.

**Lessons that are traps:**
- Thin or ultralight weights at small sizes.
- Light-grey-on-cream secondary text that falls below 4.5:1. Cream backgrounds *lower* the contrast of mid-greys versus pure white, so check every grey token against the actual beige.
- ALL-CAPS tracked-out labels used everywhere. They work for a logo, not for scannable data.
- Glass or blur layered over busy charts.
- "Mystery-meat" minimal icons without labels.

The fix pattern, from NN/g plus Refactoring UI: get the "quiet" feel from **less content and more space, not less contrast**.

### Gaps
- Not researched in this session, so no cited specifics: Hermès, Leica, Rolex, B&O and Kinfolk design systems, and Pentagram or Collins luxury case studies.
- No access to the official Aesop guidelines. Typeface names in fan-made "DESIGN.md" reconstructions (for example Suisse Int'l) are unverified and were excluded.

---

## 4. Which anti-patterns make UI look cheap?

### Takeaway
Cheapness comes mainly from **inconsistency and noise**: too many colours or gradients, heavy or dark shadows everywhere, mixed radii and icon styles, redundant strokes, arrows and badges, everything emphasised, and saturated, loud colour. The sources converge on the inverse of Rams' "nothing arbitrary".

### Cited Findings
- Stanford credibility: unrestrained promotional content and errors "no matter how small" reduce credibility. — [Stanford Guidelines #9, #10](https://credibility.stanford.edu/guidelines/index.html)
- Refactoring UI: avoid grey text on coloured backgrounds, avoid true black, use fewer borders, and keep to a constrained set of shadows ("Don't overdo it"). Don't rely solely on colour to convey information. Don't scale icons up or down; redraw them, or enclose them in a shape. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- A designer video, "7 UI/UX mistakes that SCREAM you're a beginner" (attributed to Kole Jain), lists these anti-patterns and fixes:
  - **Gradients:** multi-hue gradients clutter. Use variations of one colour, or none.
  - **Drop shadows:** make them light grey, "increase the blur significantly", or remove them. Lowering opacity alone isn't enough.
  - **Inconsistent components:** identical components must be identical. Example: all small components at one radius (10px in the video).
  - **Icons:** use one icon library and one stroke style.
  - **Redundant elements:** remove arrows and strokes the gesture already implies, or dim them.
  - **Charts:** avoid rounded bar tops that hide where values end, and include axes.
  - [SozAI transcript](https://sozai.app/transcript/ui-ux-mistakes-beginner/index.md); [Recapio digest](https://recapio.com/digest/7-ui-ux-mistakes-that-scream-youre-a-beginner-by-kole-jain)
- Developer and design blog roundups (low authority, but convergent): an ever-growing or random palette "reads as amateur". The most common cause is inconsistency across screens ("a different shade here, a new spacing value there"). The usual fix is design tokens defined once and reused. — [CareerFoundry: common UI mistakes](https://careerfoundry.com/en/blog/ui-design/common-ui-design-mistakes/); [What Makes an App Look Professional? (2026)](https://vp0.com/blogs/what-makes-an-app-look-professional.md)
- Chinese sources:
  - Highly saturated, highly bright colours cause visual fatigue (视觉疲劳). — [woshipm search result set](https://www.woshipm.com/pd/4325052.html)
  - Dividers easily become visual noise, so separate with whitespace (用留白代替分割线). — [woshipm 2064147](https://www.woshipm.com/ucd/2064147.html)
  - "没有细节的高级，都是虚伪的" ("premium without detail is fake"). — [数英 315265](https://www.digitaling.com/articles/315265.html)
- Butterick: system defaults such as Times New Roman and Arial are a typographic tell ("never"). — [Practical Typography](https://practicaltypography.com/typography-in-ten-minutes.html)

### Inferences
Checklist of "cheap" tells to audit in the finance app:
1. Medium or large shadows on every card.
2. More than one radius family, for example cards at 16, buttons at 8, chips at 20, sheets at 12, with no rule.
3. Saturated pure red (#FF0000-like) and green for gains and losses.
4. Coloured category pills and badges on every transaction row.
5. Emoji or mixed-style icons for categories.
6. Bold used for labels *and* values.
7. More than 5–6 distinct font sizes on one screen.
8. ALL-CAPS section headers without tracking.
9. Hairline dividers between every row *plus* card borders *plus* shadows (triple separation).
10. Centred body text and numbers. Right-align or tabular-align numbers instead.
11. Decorative illustrations in data screens.
12. Promotional or upsell cards on the home screen.

For gains and losses: desaturate toward the warm palette (for example an olive or sage green and a brick or terracotta red). Keep ≥3:1 non-text contrast against cream, and pair colour with a sign or arrow, since you shouldn't "rely solely on colour".

### Gaps
- No peer-reviewed study found that ranks specific UI anti-patterns by their effect on perceived cheapness. This list is practitioner consensus plus the complexity research in Q2.
- No sources were found that specifically discuss emoji icons or ALL-CAPS as cheap signals in UI. Bringhurst-style letterspacing of capitals was not verified in this session.

---

## 5. Concrete numeric heuristics (type, spacing, colour, shadow, radius)

### Takeaway
Use a **hand-picked, constrained scale** for each variable, with roughly 25% or more between neighbouring steps:
- body text around 15–17pt on iOS
- line-height about 1.4–1.5 for body text, falling toward 1.0–1.2 for display sizes
- tighter tracking for large headings and +0.05em for all-caps
- 8–10 neutrals, one primary with about 9 shades, and accents used sparingly
- shadows at about 5–10% opacity with a two-layer structure
- one radius family

Apple's Dynamic Type text styles should be the backbone on iOS.

### Cited Findings
**Type size and scale**
- Refactoring UI hand-crafted type scale (px): **12, 14, 16 (base), 18, 20, 24, 30, 36, 48, 60, 72**. Use a hand-picked scale rather than a strict modular ratio. — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/); [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/). Some reader notes recommend a 1.25 modular ratio instead, so the secondary notes conflict. See [search roundup](https://maibuith.pages.dev/notes/refactoring-ui).
- Butterick: web body text **15–25px**, line spacing **120–145%**, line length **45–90 characters**. — [Practical Typography](https://practicaltypography.com/typography-in-ten-minutes.html)
- Bringhurst: line length **45–75 characters, 66 ideal**; 40–50 for multi-column. — [webtypography.net §2.1.2](http://webtypography.net/2.1.2)
- Chinese practitioner rule: keep information hierarchy to **≤5 levels**, with a matching **≤5 font sizes**. — [woshipm 4045552 (via search summary)](https://www.woshipm.com/pd/4045552.html)
- Apple iOS text styles (Large Title 34, Title1 28, Title2 22, Title3 20, Headline 17 semibold, Body 17, Callout 16, Subhead 15, Footnote 13, Caption1 12, Caption2 11pt), which scale with Dynamic Type. — [Apple HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography). **Caveat:** the page is JavaScript-rendered and did not load in fetch. These values come from general knowledge of the HIG and should be checked against the live page. The same applies to "avoid Ultralight/Thin/Light weights at small sizes" and the 11pt minimum.

**Weight**
- Typically two weights (regular and semibold). Choose typefaces with **≥5 weights** so you have options. — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)

**Line-height**
- Shorter lines about 1.5, long lines "close to 2". Small text needs more line-height and large text "closer to 1". — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)

**Letter-spacing**
- Tighten headings (notes give **−0.05em** for headlines set in text faces). All-caps starts at **+0.05em**. — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/); [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)

**Spacing**
- Refactoring UI spacing scale (rem, base 16px): 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4, 6, 8, 12, 24, 32, 40, 48. "No two values in the scale should be closer than about 25% apart." — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)
- Put more space around groups than within them. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- Chinese practitioner (Japanese-market design language): whitespace between visual elements typically at **30–50%** of the layout. — [站酷, 西词, 《如何为日本市场打造多场景设计语言》](https://www.zcool.com.cn/article/ZMTY3ODA2OA==.html)

**Colour**
- **8–10 greys** (avoid true black), primary **5–10 shades (9 is the sweet spot)**, and accents "used sparingly". A complex UI may have up to 10 accent hues, each with 5–10 shades, mostly for states. — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/); [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)
- Blog rule of thumb: one primary, one accent, neutral backgrounds. — [CareerFoundry](https://careerfoundry.com/en/blog/ui-design/common-ui-design-mistakes/) (low authority)
- Interaction states: hover is a 5–10% lightness change; disabled is 40–50% opacity. — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)

**Shadows (Refactoring UI / Tailwind-style elevation scale)**
- sm `0 1px 2px` at 5% black
- md `0 4px 6px` at 7% + `0 2px 4px` at 5%
- lg `0 10px 15px` at 10% + `0 4px 6px` at 5%
- xl `0 20px 25px` at 10% + `0 10px 10px` at 4%
- 2xl `0 25px 50px` at 25%
- [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)
- Two-layer principle: a large, soft ambient shadow plus a tight, slightly darker contact shadow. About five levels is "plenty". — [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)
- Practitioner fix for "cheap" shadows: lighter colour and much larger blur, or remove the shadow. — [SozAI transcript](https://sozai.app/transcript/ui-ux-mistakes-beginner/index.md)

**Radius**
- Formal: about 0–4px. Casual: 12–16px and up. Pick one and apply it everywhere. — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/)

**Icons**
- 16 and 24px sizes. Don't scale icons; redraw them. — [rjseymour66 notes](https://rjseymour66.github.io/webdev/refactoring-ui/); [sglavoie summary](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)

**Contrast floor**
- WCAG AA 4.5:1 for normal text and 3:1 for large text (≥18pt, or ≥14pt bold). NN/g: never lower contrast to achieve a "clean" look. — [W3C SC 1.4.3](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html); [NN/g](https://www.nngroup.com/articles/low-contrast/)

### Inferences
Suggested token system for the SwiftUI app (an inference that applies the sources above, not prescribed by them):
- **Type:** use Dynamic Type text styles as the base (`.largeTitle`, `.title2`, `.headline`, `.body`, `.subheadline`, `.footnote`) and cap any one screen at about 5 sizes. Use the serif (`.fontDesign(.serif)` or a custom serif) only for display numbers and headlines at 28pt and up. Keep body text, labels and tables in SF Pro with **`.monospacedDigit()`** for amounts so columns align. Two weights: regular and semibold.
- **Tracking:** slightly negative tracking on the large serif numerals (about −0.5% to −2%, i.e. −0.005em to −0.02em). Small all-caps overlines at +0.05em, used sparingly.
- **Spacing:** a 4pt grid with steps 4, 8, 12, 16, 24, 32, 48, 64. Screen side margin 16–20pt, card inner padding 16–20pt, and section gaps of 32pt or more (groups more apart than their contents).
- **Colour:** cream ground, one slightly darker cream for card or grouped surfaces (instead of shadows), and a warm near-black for primary text. Two greys for secondary and tertiary text, *both verified ≥4.5:1 on the cream*. Caramel as the single accent, plus desaturated semantic gain/loss colours.
- **Shadows:** resting cards at the sm level or none, separated by tone. Sheets and popovers at lg. Tint the shadow warm (brown at low alpha) rather than pure black on a beige ground.
- **Radius:** one continuous-corner family, for example 12pt for small controls and 20pt for cards, nested radius = outer radius − padding. Never mix more than two values.
- **Liquid Glass:** let system bars use it, but don't stack custom glass over charts or numbers.

### Gaps
- No authoritative source gives a numeric "max accent colours = N" for premium feel. "1 primary + 1 accent" is blog consensus; Refactoring UI's "up to 10" accents refers to functional state colours in complex UIs.
- Material Design 3 elevation and tonal-surface values were not fetched. Apple HIG numeric values are unverified (see caveat above).
- No source found giving tracking values in pt specific to SF Pro or New York optical sizes (Apple's SF fonts apply automatic size-specific tracking). Not verified this session.

---

## 6. Chinese-language writing on 高级感: commonly cited rules, and where they agree or disagree with Western sources

### Takeaway
Chinese design writing reduces 高级感 to **降饱和、压对比、柔光影、增留白、暖灰/米白/大地色, 少用颜色, 克制, 统一/秩序, 细节极致, 独具风格**. Most of this aligns with Rams, Refactoring UI and the saturation and white-space research. Two points diverge: "压对比" (lowering contrast) conflicts with WCAG and NN/g, and the emphasis on 独具风格 (distinctiveness) is in tension with prototypicality and usability research. Recent Chinese writing itself (2026) criticises 高级感 as a formula that is not universal.

### Cited Findings
- 2026 woshipm essay《高级感的背后，是一层什么样的逻辑？》:
  - 高级感 began as a fashion-industry term for 低饱和、留白、哑光质感, and has since become a vague compliment and a catch-all prompt word for AI image generation.
  - The formula it lists: **降低饱和度、压低明暗对比、柔化光影、增加留白，色调偏向暖灰、米白等大地色**. 高级灰 works through the combination of light-dark relationships, texture and gradient, not grey alone.
  - Caveats: 纹理过重显脏, 留白过多显空, 低饱和若压没主体则找不到重点. "'高级感'没有一套放到任何图上都有效的零件." Dense compositions can also be well designed.
  - [人人都是产品经理, 数字泡泡～, 2026-09-28](https://www.woshipm.com/ai/6470787.html)
- 2020 digitaling essay《说一说"高级感"是什么鬼》:
  - Three dimensions: **克制、极致、独具风格**.
  - 克制 = 少即是多, 降低饱和度 (MUJI), 少用颜色 (黑白灰/单色/莫兰迪色; fewer colours mean weaker emotional signalling and a more upscale feel).
  - 极致 = 细节与质感 ("没有细节的高级，都是虚伪的"; "高级感不怒自威").
  - 独具风格: once a style becomes mainstream it "失去了高级感".
  - It cites Rams.
  - [数英, 行若老沈](https://www.digitaling.com/articles/315265.html)
- 站酷 article on a Japanese-market design language: low-saturation, low-brightness palettes from traditional colours, three main colours, **30–50% whitespace**, strict grid with pixel-level spacing, "板正" orderliness, and "rounded corners feel friendly, square corners professional". Notably, for a conversion-focused SaaS site the team **chose the "trust-first" option (blue plus yellow) over the "Japanese-aesthetic-first" option**. — [站酷, 西词](https://www.zcool.com.cn/article/ZMTY3ODA2OA==.html)
- woshipm articles surfaced in search: use whitespace instead of divider lines (dividers become noise) [woshipm 2064147](https://www.woshipm.com/ucd/2064147.html); hierarchy levels ≤5 and font sizes ≤5 [woshipm 4045552](https://www.woshipm.com/pd/4045552.html); size contrast creates a focal point [woshipm 1586317](https://www.woshipm.com/pd/1586317.html); lots of whitespace reads as simple and artistic [digitaling 1333667](https://www.digitaling.com/articles/1333667.html); "大文字大留白小图片" is a common premium combination, and high saturation and brightness cause visual fatigue [woshipm search set](https://www.woshipm.com/pd/4325052.html). These were seen through search summaries, not full reads.

### Inferences
**Where Chinese and Western sources agree:**
- Desaturation: Zhou et al. support it for heritage positioning, and Brasel & Hagtvedt show saturation equals arousal and loudness.
- Whitespace: Pracejus et al. find it signals prestige; Refactoring UI says "start with too much".
- Fewer colours: Refactoring UI; Reinecke finds less colourful and complex designs preferred by more educated users.
- Restraint and detail: Rams principles 8 and 10.
- Avoid pure black: Refactoring UI.
- Replace dividers with space: Refactoring UI's "fewer borders".
- Order and grids.

**Where they disagree or need care:**
1. **"压对比/降低对比"**: a global reduction of tonal contrast conflicts with WCAG 4.5:1 and NN/g's finding that low-contrast text lowers trust. The Western framing is to reduce *complexity and emphasis*, not *legibility contrast*. Keep text contrast high and soften *decorative* contrast (backgrounds, shadows, borders, chart gridlines).
2. **"独具风格" vs. prototypicality**: Chinese writing prizes distinctiveness. Reinecke's first-impression work and the aesthetic-usability caveats imply that users, especially in finance, reward familiar, legible structure. Distinctiveness should live in type, colour and tone, not in novel navigation or interaction patterns.
3. **Universality**: the 2026 woshipm piece and Pracejus 2013 (white-space meaning differs across cultures) both caution that 高级感 is not a universal formula. The 站酷 trust-first outcome mirrors Fogg's finding that, for finance, credibility outranks pure aesthetics.
4. **Morandi or 高级灰 everything** risks "低饱和压没主体". Refactoring UI's de-emphasis method keeps one clear focal point, which is the remedy.

**For this app:** the current cream, caramel and serif direction is squarely within the Chinese 高级感 formula (暖灰/米白/大地色 + 克制). The remaining risks:
- muddy low contrast on cream
- too many co-equal cards and shadows (complexity)
- lack of one dominant focal number per screen

### Gaps
- No uisdc.com (优设网) or 少数派 article on 高级感 was retrieved in full; search engines returned mostly woshipm and digitaling. No 知乎 threads were read.
- No Chinese source found giving specific numeric saturation or brightness targets (for example HSB S ≤ 30%). Commonly repeated rules of thumb of that kind are unverified and were excluded.
