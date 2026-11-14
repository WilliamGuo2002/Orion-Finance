# Canadian Market Context and White-Space for "Orion Finance" (Canadian investing and net-worth iOS app), as of November 2026

Research date: 2026-11-13. Most sources are from 2026. Older facts are dated inline. Vendor-authored claims are flagged as such.

## 1. Consumer-driven banking (open banking) status in 2026

### Takeaway
Canada has a law (the Consumer-Driven Banking Act, Royal Assent March 26, 2026, Bank of Canada as supervisor) and draft regulations (Canada Gazette, June 27, 2026). Accreditation guidelines are still in consultation (November 2 to December 8, 2026), and no official Phase 1 go-live date has been announced. Screen scraping remains legal for now. Investment accounts are last in the data-scope sequence. A solo developer will rely on aggregators (Plaid, SnapTrade) for the foreseeable future and will most likely not need its own accreditation if it works through an accredited intermediary.

### Cited Findings
- The Consumer-Driven Banking Act (passed via Bill C-15) received Royal Assent on March 26, 2026. It names the Bank of Canada as administrator and supervisor, replacing the earlier FCAC plan. — [consumerdrivenbanking.ca timeline](https://consumerdrivenbanking.ca/implementation-timeline/); [Flinks blog](https://www.flinks.com/blog/open-banking-canada-2026-launch-fintech-institutions)
- Finance Canada published the proposed Consumer-Driven Banking Regulations in Canada Gazette Part I on June 27, 2026. Comments closed August 26, 2026. — [Bennett Jones, July 2026](https://www.bennettjones.com/Insights/Blogs/2026/07/Canada-Advances-Consumer-Driven-Banking-Framework-with-Proposed-Regulations); [Bank of Canada CDB page](https://www.bankofcanada.ca/regulatory-oversight/consumer-driven-banking/)
- **Conflict or ambiguity:** Bennett Jones says the CDBA is "not yet in force" and refers to Bill C-36 (first reading June 15, 2026). Royal Assent and coming into force are different things, so this may simply mean the provisions await an in-force order. The role of Bill C-36 was not verified. — [Bennett Jones](https://www.bennettjones.com/Insights/Blogs/2026/07/Canada-Advances-Consumer-Driven-Banking-Framework-with-Proposed-Regulations)
- On November 2, 2026, the Bank of Canada launched a consultation on draft supervisory guidelines for accreditation. Third-party summaries put the comment deadline at December 8, 2026. Applicants would need to show compliance with the designated technical standard. — [Bank of Canada](https://www.bankofcanada.ca/regulatory-oversight/consumer-driven-banking/); [Fathom4sight summary](https://www.fathom4sight.ai/blog-articles/bank-of-canada-outlines-consumer-driven-banking-accreditation-rules)
- The Bank of Canada supervises "financial institutions, credit unions, payment service providers, fintechs, and third-party service providers." Its CDB page gives **no launch date**. — [Bank of Canada](https://www.bankofcanada.ca/regulatory-oversight/consumer-driven-banking/)
- **Accreditation pathways** in the draft regulations:
  - federal and provincial financial institutions;
  - entities registered under the Retail Payment Activities Act (RPAA), which may get streamlined accreditation;
  - all other entities, through a non-streamlined process;
  - third-party service providers.

  The application fee is C$2,500, submitted through the Bank's electronic system. Maximum penalties are C$1M for individuals and C$10M for entities or accredited third-party service providers (ATPSPs). Breaches must be reported to the Bank "as soon as feasible." — [Bennett Jones](https://www.bennettjones.com/Insights/Blogs/2026/07/Canada-Advances-Consumer-Driven-Banking-Framework-with-Proposed-Regulations)
- **Phasing (per Flinks):**
  - Phase 1 is read access, described as "2026" with no exact date.
  - Phase 2 is write access, which Budget 2025 targeted for mid-2027 and which is "contingent on Canada's Real-Time Rail being live." The June 2026 regulations "don't restate a date."

  — [Flinks](https://www.flinks.com/blog/open-banking-canada-2026-launch-fintech-institutions)
- **Data-scope order:** deposit and payment accounts first, then lending, then registered and non-registered **investment accounts**. At least 24 months of transaction history must be shareable. Derived (enriched) data is excluded. — [Flinks](https://www.flinks.com/blog/open-banking-canada-2026-launch-fintech-institutions); also [Bennett Jones](https://www.bennettjones.com/Insights/Blogs/2026/07/Canada-Advances-Consumer-Driven-Banking-Framework-with-Proposed-Regulations) (scope covers "deposit accounts, payment products, investment accounts and lending accounts")
- **Screen scraping:** The Act provides for a prohibition, but its start date awaits further consultation. Flinks says "screen scraping remains permitted during the initial rollout." — [Flinks](https://www.flinks.com/blog/open-banking-canada-2026-launch-fintech-institutions); [consumerdrivenbanking.ca](https://consumerdrivenbanking.ca/implementation-timeline/)
- **Operational requirements in the draft:**
  - 99.5% monthly API uptime;
  - consent renewal at least every 12 months;
  - consent records kept for five years;
  - any entity that outsources consent, authentication or data movement must use an ATPSP;
  - the technical-standards body must be "meaningfully Canadian" and is not yet named.

  — [Flinks](https://www.flinks.com/blog/open-banking-canada-2026-launch-fintech-institutions)
- **Timing doubts:** A March 2026 report said the Bank of Canada had not committed to a Phase 1 date. Final regulations are reportedly targeted for late 2026 or early 2027. Real-Time Rail (Q4 2026) is a separate instant-payments system. — [Open Banking Tracker](https://www.openbankingtracker.com/regulation/canada-open-banking) and [Fathom4sight](https://www.fathom4sight.ai/blog-articles/bank-of-canada-outlines-consumer-driven-banking-accreditation-rules), both secondary sources

### Inferences
- Investment accounts (TFSA, RRSP, non-registered brokerage) come last in the open-banking sequence. Realistically, regulated API access to investment holdings is likely 2027 or later. Until then, brokerage data in Canada keeps coming from bespoke or credential-based connectors (for example, SnapTrade's Wealthsimple connector) or broker OAuth APIs (Questrade).
- The four-party model, in which apps work through an ATPSP, suggests a solo developer can use an accredited aggregator rather than seek accreditation itself. Even so, the developer will probably be a "requesting entity" responsible for consent UX, which means 12-month consent renewal prompts and five-year consent records. Plan the consent and data-retention design now.
- The eventual scraping ban is a platform risk for any connector that relies on credentials (for example, Wealthsimple through SnapTrade). Diversifying data inputs (CSV/statement import, manual holdings) is a hedge.

### Gaps
- No official Bank of Canada Phase 1 go-live date was found.
- Final accreditation criteria for app developers versus intermediaries are not known, including whether a downstream app using an ATPSP needs its own accreditation. The draft guidelines were in consultation at research time.
- Insurance or capital requirements and Canadian-presence requirements for accreditation were not found.
- The 2024 history of the original CDBA framework under FCAC was not verified with a source in this pass.

## 2. Aggregation provider landscape in Canada

### Takeaway
Plaid covers Canadian **banks** well (it claims 99% of deposit accounts, including the Big 5) and is weaker on investments. SnapTrade is the developer-friendly brokerage layer: an official OAuth connection for Questrade, a bespoke password/PIN connector for Wealthsimple, and transparent pricing ($0 dev tier, then $100/month plus $1 to $2 per connected user). Flinks, a Montreal company now owned by National Bank, is the main domestic bank aggregator but is enterprise-oriented. Wealthica runs its own Canadian connectors (150+ institutions) and is both a potential data supplier and a direct consumer competitor.

### Cited Findings
- **Plaid:** Its support page claims coverage of "over 99% of deposit accounts," including all Big 5 banks and 100+ long-tail institutions. — [Plaid support](https://support.plaid.com/hc/en-us/articles/17549112773783-What-institutions-does-Plaid-support)
- **Plaid credit unions:** Past expansions added RBC, Scotiabank, TD, BMO, CIBC, Tangerine and credit unions such as Vancity, Coast Capital and Conexus (older reporting). — [BetaKit](https://betakit.com/silicon-valley-fintech-plaid-expands-coverage-in-canada)
- **Plaid investment coverage:** Wealthica (a competitor) says Plaid is "strong for banks, limited for investments," and that boutique brokerages "often return unsupported errors." This is a promotional claim, dated May 13, 2026. — [Wealthica blog](https://wealthica.com/blog/plaid-vs-wealthica/)
- **Flinks:** A Montreal data provider acquired by National Bank in a C$103M deal. It claims 10,000+ US and Canadian institutions, including wealth management. Wealthsimple uses Flinks for account funding and onboarding risk. Flinks' published coverage files were last updated in September 2024. — [SnapTrade "Flinks vs Plaid" (vendor)](https://snaptrade.com/blogs/flinks-vs-plaid); [Flinks coverage help](https://help.flinks.com/support/solutions/articles/43000735785-flinks-coverage-ca-and-us-)
- **SnapTrade and Questrade:** An official OAuth integration, described as one of SnapTrade's most complete. — [SnapTrade Questrade page](https://snaptrade.com/brokerage-integrations/questrade-api)
- **SnapTrade and Wealthsimple:** A "bespoke integration, requiring a password/PIN authentication," meaning it is not OAuth. — [SnapTrade Wealthsimple page](https://snaptrade.com/brokerage-integrations/wealthsimple-api)
- **SnapTrade pricing (USD, official page):**
  - **Build: $0**, up to 5 brokerage connections, real-time data, trading included.
  - **Launch, real-time: $100/month plus $2 per connected user per month**, with unlimited users and manual sync included.
  - **Launch, daily: $100/month plus $1 per user per month**, read-only, with manual sync at $0.05 per sync.
  - **Custom:** volume pricing.
  - Personal/OAuth users are free "for a limited time," with no end date given.
  - Pricing does not vary by brokerage.

  — [SnapTrade pricing](https://snaptrade.com/pricing)
- **Wealthica:** Connects to "more than 150 Canadian institutions," including Questrade and Wealthsimple. Its developer API has no free tier and no public pricing. — [Wealthica blog](https://wealthica.com/blog/plaid-vs-wealthica/)
- **Plaid in Canada:** Plaid's Canadian clients include Wealthsimple, Shopify and Clearco. Plaid has considered opening a Canadian office ahead of open banking. — [The Logic](https://thelogic.co/news/exclusive/with-open-banking-on-the-horizon-silicon-valley-giant-plaid-eyes-canadian-office/); [SnapTrade comparison](https://snaptrade.com/blogs/flinks-vs-plaid)

### Inferences
- **Unit economics:** On SnapTrade real-time, 500 connected users cost about $100 + $1,000 = **$1,100 USD/month**, or about $2.20 per user per month. Daily-sync read-only costs about $1.20 per user. A paid tier must therefore be priced well above about C$3 per user per month. Alternatively, brokerage linking can be gated behind the subscription, with free users limited to manual or CSV entry.
- Plaid's per-item pricing for small developers in Canada is not public (see Gaps). Bank-balance aggregation may be the costlier part, so consider making bank linking an optional premium feature.
- Wealthsimple's connector is credential-based, so it carries reliability and re-authentication risk, plus future regulatory risk from the scraping prohibition. Good UX for "connection broken, re-link" states is essential.

### Gaps
- Plaid's Canadian pricing and its minimums or production-access requirements for solo developers were not found.
- MX and Finicity Canadian coverage was not researched (no results surfaced). Both are believed to be US-focused, but this is unverified.
- IBKR, TD Direct Investing, RBC Direct Investing, BMO InvestorLine and CIBC Investor's Edge coverage via SnapTrade was not verified in this pass. Check SnapTrade's Broker Access Guide.
- No systematic reliability data was found (uptime, re-auth frequency). Reddit user sentiment was not collected.

## 3. Canada-specific investor needs and how existing tools serve them

### Takeaway
There is a cluster of Canada-only tax and account mechanics that US apps (Empower, Monarch, Copilot, Robinhood-style apps) ignore:
- TFSA, RRSP, FHSA and RESP room;
- ACB on an average-cost basis across all accounts;
- the 61-day superficial-loss window, including across TFSA and RRSP and spouses;
- US withholding tax that differs by account type;
- the T1135 foreign-property threshold;
- USD accounts and FX costs.

These are served piecemeal today. adjustedcostbase.ca (free tier, or $49/year) handles ACB and T1135. Wealthica (C$50 to C$250/year) handles aggregation. Passiv handles rebalancing. Spreadsheets fill the rest. No single mobile-first app combines aggregation, Canadian tax-aware analytics and AI.

### Cited Findings
- **US dividend withholding:**
  - The Canada-US treaty generally sets withholding at 15%.
  - RRSPs and RRIFs are exempt under Article XXI(2).
  - TFSAs are not recognized, so the 15% is withheld and cannot be recovered.
  - In non-registered accounts the withholding can be claimed as a foreign tax credit.
  - Canadian-listed ETFs holding US-listed ETFs can suffer two layers of unrecoverable withholding in a TFSA or RESP.

  — [Wealthsimple help](https://help.wealthsimple.com/hc/en-ca/articles/360056584994-Non-resident-withholding-taxes-and-how-to-minimize-them); [Questrade learning](https://www.questrade.com/learning/accounts-taxes/us-dividend-withholding-tax-canada); [Motley Fool Canada, Oct 15 2026](https://www.fool.ca/2026/10/15/your-tfsa-pays-15-tax-on-u-s-dividends-your-rrsp-doesnt/); [MoneySense](https://www.moneysense.ca/columns/ask-a-planner/withholding-tax-on-us-etfs)
- **Superficial loss rule:**
  - The window is 61 days: 30 days before the sale, the sale day, and 30 days after.
  - A loss is denied if the taxpayer or an affiliated person (spouse, controlled corporation) acquires identical property in the window and still holds it at the end.
  - The denied loss is added to the ACB of the replacement shares.
  - Buying back in a TFSA or RRSP triggers the rule and effectively destroys the loss.

  — [TaxTips.ca](https://www.taxtips.ca/personaltax/investing/taxtreatment/superficial-losses-and-other-disallowed-losses.htm); [RBC Wealth Management PDF](https://ca.rbcwealthmanagement.com/documents/1435520/3126711/NAV0072+-+Superficial+loss+rules.pdf/1b4aef6b-ae5f-4125-af6e-e106b1563fee); [MoneySense](https://www.moneysense.ca/columns/ask-moneysense/triggering-losses-by-transferring-investments-to-a-tfsa/); [Million Dollar Journey](https://milliondollarjourney.com/tax-loss-harvesting.htm)
- **T1135:**
  - Required if the total **cost** of specified foreign property exceeds **C$100,000** at any time in the year.
  - Part A (simplified) applies from $100k to under $250k. Part B (detailed) applies at $250k or more.

  — [CRA T1135 page](https://www.canada.ca/en/revenue-agency/services/tax/international-non-residents/information-been-moved/foreign-reporting/foreign-income-verification-statement.html)
- **NEW, Budget 2026 proposal:** Raise the T1135 threshold from $100,000 to **$200,000**, and the simplified-reporting ceiling from under $250k to **under $500k**. This is not yet confirmed as enacted. — [Budget 2026 Tax Measures: Supplementary Information](https://budget.canada.ca/2026/report-rapport/tm-mf-en.html)
- **adjustedcostbase.ca:**
  - Basic is **$0/year**: ACB and capital gains, two portfolios, foreign currency, superficial-loss tracking, CSV export.
  - Premium is **$49/year**: ten portfolios, spreadsheet import, "Connect Your Brokerage," exchange-rate lookup, a **T1135 assistant**, T3 preview and ETF tax-data import.

  — [adjustedcostbase.ca](https://www.adjustedcostbase.ca/)
- **Wealthica pricing (current plan structure):**
  - Connect: C$50/year
  - Unlimited Connect: C$75/year
  - Premium: C$150/year (delayed quotes, asset-class splits)
  - Prestige: C$250/year
  - 14-day trial on every plan

  Older reviews cite $11.99/month and $24.99/month. — [Genymoney Wealthica review 2026](https://genymoney.ca/wealthica-review-the-canadian-version-of-personal-capital/); [Savvy New Canadians](https://www.savvynewcanadians.com/wealthica-review-free-portfolio-tracker-canada/); [Wealthica](https://wealthica.com/)
- **Passiv:** Still operating as a privately held rebalancing tool based in New Brunswick. It "doesn't hold your money [or] make investing decisions." It is also a Wealthica "Power Up." — [Million Dollar Journey, Passiv Review 2026](https://milliondollarjourney.com/passiv-review.htm); [Wealthica review](https://genymoney.ca/wealthica-review-the-canadian-version-of-personal-capital/)
- **Competitor move:** Wealthsimple acquired Fey, a Montreal investment-research app, in 2025 to bolster in-app research. Separately, it acquihired Plenty in April 2025. — [BetaKit](https://betakit.com/wealthsimple-acquires-fey-to-bolster-its-investment-research-capabilities/); [The Logic](https://thelogic.co/briefing/wealthsimple-acquires-montreal-investment-research-firm-fey/)
- **New entrant:** Robinhood entered Canada via the WonderFi acquisition (2026). — [BetaKit](https://betakit.com/?p=406119)

### Inferences (white-space candidates for Orion)
1. **Cross-account ACB and superficial-loss guardrail.** Canadian ACB is averaged across all of a taxpayer's non-registered accounts at different brokers, and the superficial-loss window spans TFSA, RRSP and spouse accounts. A multi-broker aggregator is uniquely placed to warn: "you sold XEQT at a loss in your Questrade cash account; you bought XEQT in your Wealthsimple TFSA 12 days ago, so this loss will be denied." adjustedcostbase.ca calculates ACB but is web-only and depends on manual or premium import. No mobile app was found doing this live.
2. **Asset-location and withholding-tax leakage report.** For example: "You hold VFV in a TFSA and VOO in RRSP; estimated annual unrecoverable US withholding = $X; consider ...". Framing must stay educational (see Section 5).
3. **T1135 monitor.** Track the cost of US-listed holdings and USD cash in non-registered accounts against the $100k threshold (or $200k if Budget 2026 is enacted), with an alert. adjustedcostbase.ca has a T1135 assistant only in Premium on the web.
4. **CAD/USD-native net worth plus FX-cost awareness.** Show embedded FX drag (broker conversion spread) and Norbert's Gambit savings estimates. No source on broker FX fees was gathered in this pass (see Gaps).
5. **Registered-room tracker (TFSA, RRSP, FHSA, RESP).** Room cannot be pulled automatically (CRA has no API), so this requires user-entered starting room plus contribution tracking from linked accounts. That is still valuable, because over-contribution penalties are a common pain point. This is unsourced in this pass; see Gaps.
6. **Mobile-first, modern UX versus Wealthica** (web-centric, tiered pricing up to C$250/year). Pricing Orion around C$5 to C$10/month would sit between adjustedcostbase.ca ($49/year) and Wealthica Premium (C$150/year).

### Gaps
- CRA sources on TFSA, FHSA and RRSP room rules and over-contribution penalties (1% per month) were not fetched.
- No sourced data was gathered on broker FX fees (for example, Wealthsimple's 1.5% FX fee on non-USD accounts, or Questrade's fee) or on Norbert's Gambit mechanics and DLR/DLR.U.
- CDRs (Canadian Depositary Receipts) and the CAD-hedged ETF landscape were not researched.
- Reddit r/PersonalFinanceCanada sentiment on Wealthica reliability and on spreadsheet use was not collected.
- Whether Wealthica connectors use scraping or APIs was not stated by Wealthica.

## 4. Market size signals

### Takeaway
The DIY market is large and young. Wealthsimple alone had 3.6M clients and C$155.6B in assets at Q2 2026, and roughly 1 in 5 Canadians under 40 reportedly use it. Four in ten Canadian investors hold online or discount brokerage accounts. About 1.46M Canadians held an FHSA for the 2024 tax year. DIY investors are heavy AI users: 56% use AI for investment tasks.

### Cited Findings
- **Wealthsimple Q2 2026:** C$155.6B assets under administration, up 24.7% quarter on quarter and 84.1% year on year. 3.6M clients (excluding tax filers). About C$17B net inflows, driven by chequing and spending. — [Wealthsimple press release, Newsfile, July 29 2026](https://www.newsfilecorp.com/release/307150/Wealthsimple-Reports-17B-Net-Flows-in-Q2-Driven-by-High-Demand-for-Chequing-and-Spending-Products)
- **Wealthsimple Q1 2026:** C$124.8B AUA and 3.4M clients. Boilerplate says "more than 4 million Canadians," which likely includes tax-only users. — [Wealthsimple Q1 release](https://www.newsfilecorp.com/release/296531/Wealthsimple-Reports-Record-Q1-Growth-Driven-by-BestEver-RRSP-Season)
- "1 in 5 Canadians under 40 uses Wealthsimple" (May 2026). — [iPhone in Canada](https://www.iphoneincanada.ca/2026/05/09/1-in-5-canadians-under-40-uses-wealthsimple-and-it-just-had-a-record-quarter/)
- An unverified secondary figure puts Wealthsimple at C$169.2B AUA as of September 30, 2026. It is not confirmed against a company release.
- **SIMA/Pollara 2025 (n=5,400):** Four in ten investors hold online or discount brokerage accounts, most using them monthly or more. — [Wealth Professional](https://www.wealthprofessional.ca/news/industry-news/sima-poll-advisors-retain-strong-investor-trust-despite-rise-of-finfluencers/390476)
- **CSA 2025:** "1 in 8 Canadians are hybrid investors" (self-directed plus advised). — [CSA](https://www.securities-administrators.ca/?p=28588)
- **OSC (survey of 2,000 retail investors, late 2020):** 74% entirely self-directed. 60% of self-directed investors are men, and a quarter are aged 18 to 34. — [OSC](https://osc.ca/en/node/478041)
- **Global X / National Bank Direct Brokerage survey** (RKI, n=834 DIY investors including 402 in Quebec; published October 19, 2026):
  - **84%** use finfluencers, AI or both.
  - **56% use AI for investment-related tasks.**
  - Gen Z uses AI about 3x as often as Boomers, yet 95% of Gen Z see reasons to question AI advice.
  - Creator-content viewers make 9.9 portfolio adjustments per year versus 2.3 for non-viewers.

  — [Wealth Professional](https://www.wealthprofessional.ca/news/industry-news/finfluencers-and-ai-are-reshaping-how-canadian-diy-investors-make-decisions/393793)
- **Wealthsimple/Angus Reid survey of 1,000 DIY investors:** 38% trade regularly or intermittently (10 to 150 trades per quarter). DIY investors want advanced tools. — [Wealth Professional](https://www.wealthprofessional.ca/news/industry-news/canadian-diy-investors-push-for-advanced-tools-wealthsimple-survey-reveals/392353)
- **J.D. Power 2025:** 31% of DIY investors are likely to engage an advisor in the next 12 months. — [J.D. Power](https://www.jdpower.com/business/press-releases/2025-canada-investor-satisfaction-study)
- **FHSA:**
  - 1,455,280 Canadians held FHSAs (1,680,490 accounts) for the 2024 tax year, per a third-party summary of CRA data.
  - Finance Canada said nearly 1M had opened one by November 6, 2024.
  - CRA's official page (end of 2023) shows about 739,000 openers with an average balance of $3,899.

  — [BetterBooks summary](https://betterbookscanada.ca/fhsa-statistics-canada/); [CRA FHSA statistics](https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/first-home-savings-account/fhsa-statistics.html); [IG](https://www.ig.ca/en/insights/why-a-million-canadians-have-opened-an-fhsa)
- **BCSC 2024 DIY investing report:** n=4,272, including 1,579 DIY investors. — [BCSC PDF](https://www.bcsc.bc.ca/-/media/PWS/New-Resources/About/Reports-and-Publications/2024-DIY-Investing-Full-Report.pdf)

### Inferences
- Multi-account holders are the target users: Wealthsimple plus a big-bank account plus Questrade or IBKR. Wealthsimple's own app will never aggregate competitors' accounts, which keeps the aggregation niche open.
- The 56% AI-usage figure validates an AI assistant. The 95% Gen Z skepticism figure suggests positioning it as transparent, explanatory and grounded in the user's own data, rather than as tip-giving.
- The Canadian population is small (about 1/9 of the US). A Canada-only niche app has a ceiling, but Canada-specific depth is defensible against US apps.

### Gaps
- No authoritative 2025 or 2026 count of Canadian self-directed brokerage accounts was found (OSC data is from 2020/21).
- TFSA holder counts and unused-room statistics were not found.
- No data was found on paid adoption of Canadian net-worth apps (for example, Wealthica's paying-user count).

## 5. Regulatory constraints: AI and investment advice, plus privacy law

### Takeaway
In Canada, anyone "in the business of advising" on securities must register with provincial regulators. Personalized, tailored buy or sell recommendations from an unregistered app are the main risk. CSA Staff Notice 11-348 (December 2024) confirms that existing securities law applies to AI systems and creates no new safe harbour. The safe positioning is education and information: factual analytics on the user's own holdings, tax mechanics, and general explanations, with no tailored "buy X" or "sell Y" output. Privacy: PIPEDA applies federally. Quebec Law 25 adds mandatory privacy impact assessments (PIAs), including before transferring personal data outside Quebec (even to US cloud or AI vendors), and fines up to C$25M or 4% of turnover. Apple additionally requires disclosure of, and explicit consent for, sharing data with third-party AI.

### Cited Findings
- **Registration trigger:** Advisers must register if "in the business of advising anyone in Canada about investing in securities or buying or selling securities." Registration is per province or territory unless an exemption applies (2013 overview). — [Osler](https://www.osler.com/en/resources/cross-border/2013/giving-investment-advice-to-canadian-clients)
- **Publisher-type exclusion:** Securities legislation has historically excluded publishers and writers of financial publications "of general and regular paid circulation" whose advice is not tailored and who have no interest in the securities discussed. The only text surfaced was a federal bill's first reading, so the current wording in each provincial act was not verified. — [Bill S-214 text](https://www.parl.ca/documentviewer/en/40-2/bill/S-214/first-reading/page-86)
- **CSA Staff Notice and Consultation 11-348**, "Applicability of Canadian Securities Laws and the Use of Artificial Intelligence Systems in Capital Markets" (December 5, 2024):
  - Securities law applies to AI use by registrants and other market participants.
  - It does not create new requirements.
  - Registrants must disclose material AI use and may face tailored terms and conditions.
  - The consultation closed March 31, 2025.

  — [OSC PDF of notice](https://www.osc.ca/sites/default/files/2024-12/csa_20241205_11-348_artificial-intelligence-systems-capital-markets.pdf); [Goodmans](https://www.goodmans.ca/insights/article/applying-securities-laws-to-ai--key-takeaways-from-csa-guidance-for-market-participants); [Bennett Jones](https://www.bennettjones.com/Insights/Blogs/2024/12/Canadian-Securities-Administrators-Issue-Notice-on-Use-of-Artificial-Intelligence)
- **CIRO on DIY investing:** CIRO has published research on DIY investing influenced by friends, followers and family. This is regulator attention on finfluencer and social-driven investing. — [CIRO](https://www.ciro.ca/node/30096)
- **Quebec Law 25:**
  - A PIA is required before communicating personal information outside Quebec, including to other provinces. It must weigh sensitivity and purpose, and adequate protection plus a written agreement are required.
  - PIAs are also required for new information-system projects.
  - Penalties reach C$25M or 4% of global turnover, and there is a private right of action.

  — [McCarthy Tétrault](https://mccarthy.ca/en/insights/blogs/techlex/sweeping-privacy-reform-comes-force-quebec); [Private AI](https://private-ai.com/2024/05/13/law25-data-transfer/); [IAB Canada PIA guidance](https://iabcanada.com/wp-content/uploads/2022/06/IAB-Canada_BPG-Que-PIA-Guidance_June-2022.pdf). These are secondary sources.
- **Law 25 data portability:** Law 25 also introduced a data-portability right. — [NCFA primer](https://ncfacanada.org/primer-on-quebecs-new-data-portability-law/)
- **PIPEDA:** Does not mandate PIAs. One secondary source puts its fine maximum at C$100,000 per violation (not verified against the statute). — [Enzuzo](https://www.enzuzo.com/blog/quebec-law-25)
- **Apple 5.1.2(i):** "You must clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so." Under 5.1.2(ii), data may not be repurposed without further consent. — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences (positioning for a non-registered solo app)
- **Safe zone:**
  - Aggregation and display of the user's own data.
  - Factual calculations (ACB, superficial-loss window detection, withholding-tax estimates, T1135 threshold status).
  - Generic educational explanations.
  - Paper trading.
  - Stock data and research presented as information.
  - An AI assistant that explains and summarizes rather than recommends.
- **Danger zone:**
  - AI outputs like "you should buy/sell X," personalized allocation recommendations, or rebalancing instructions tied to the user's goals or risk profile. These look like tailored advice.
  - Charging for that advice. Compensation and holding out are typical "business trigger" factors.
- **Mitigations:**
  - System-prompt guardrails that refuse security-specific buy or sell recommendations.
  - "Not investment advice; Orion is not registered with any securities regulator or CIRO" disclaimers in onboarding and the AI chat.
  - Present tax features as "estimates; consult a tax professional."
- Sending users' holdings to an LLM API (US-hosted) triggers Apple 5.1.2 disclosure and consent. It also likely triggers a Law 25 PIA for Quebec users, plus PIPEDA accountability for cross-border processing. Minimize what is sent (aggregate or anonymize), document a PIA, and name processors in the privacy policy.

### Gaps
- No CIRO or CSA guidance specific to **unregistered AI chatbots** giving investment information was found. Notice 11-348 targets market participants (registrants, issuers). Whether an unregistered app's AI falls within "advising" is a legal question, and a Canadian securities lawyer should confirm it.
- The exact Ontario Securities Act s.34 publisher exemption wording and Companion Policy 31-103CP business-trigger factors were not retrieved (OSC site returned 403).
- No sourced status was found for federal PIPEDA reform (Bill C-27 died in 2025 and any successor bill is unknown).
- No CSA robo-advice-specific notice was retrieved.

## 6. Monetization benchmarks and App Store review rules

### Takeaway
App Store rules are the sharper constraint. Guideline 5.1.1(ix) says apps in "banking and financial services" or "that require sensitive user information **should be submitted by a legal entity** … and not by an individual developer." Guideline 3.2.1(viii) says trading, investing and money-management apps "should be submitted by the financial institution performing such services." Practically, a solo developer should ship under an incorporated entity (not an individual developer account) and must position Orion as a read-only tracker and education tool, not a service that executes trades. Pricing anchors in Canada: adjustedcostbase.ca at $49/year, Wealthica at C$50 to C$250/year, SnapTrade's cost floor of about US$1 to $2 per linked user per month. Finance-specific conversion benchmarks were not publicly available.

### Cited Findings
- **Apple 5.1.1(ix):** "Apps that provide services in highly regulated fields (such as banking and financial services ...) or that require sensitive user information should be submitted by a legal entity that provides the services, and not by an individual developer." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Apple 3.2.1(viii):** "Apps used for financial trading, investing, or money management should be submitted by the financial institution performing such services and must have necessary licensing and permissions in the locations where you make them available." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Apple 3.1.1:** Unlocking features or subscriptions must use in-app purchase. 3.1.2: auto-renewing subscriptions need ongoing value and a period of at least 7 days. "Clearly describe what the user will get for the price." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Apple 4.7 (chatbots):** The developer is responsible for chatbot output complying with the guidelines and the law. — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **RevenueCat State of Subscription Apps 2026** (115,000+ apps, $16B+ revenue):
  - Short trials (4 days or less) rose from 42.1% to 46.5% of apps.
  - Hard paywalls convert higher and faster than freemium.
  - Billing errors cause 15.2% of App Store cancellations.
  - A finance-category breakout exists only in the full report, if at all.

  — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/); [RevenueCat blog](https://revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026); [SaaStr summary](https://saastr.com/the-top-10-learnings-from-revenuecats-state-of-subscription-apps-how-115000-mobile-apps-deliver-16b-in-revenue-whats-working-whats-quietly-killing-growth)
- **Canadian price anchors:**
  - adjustedcostbase.ca: $0 or $49/year. — [adjustedcostbase.ca](https://www.adjustedcostbase.ca/)
  - Wealthica: C$50 / 75 / 150 / 250 per year. — [Genymoney](https://genymoney.ca/wealthica-review-the-canadian-version-of-personal-capital/)
  - SnapTrade cost: $100/month base plus $1 to $2 per user per month. — [SnapTrade pricing](https://snaptrade.com/pricing)

### Inferences
- **Entity:** Incorporate (federally or provincially) and enroll in the Apple Developer Program as an organization (D-U-N-S number) before submitting. An individual account is a likely rejection reason under 5.1.1(ix) for an app that links bank and brokerage credentials.
- **Positioning for review:** Describe Orion as a "portfolio tracker / net-worth dashboard" with "read-only connections via SnapTrade/Plaid" and "paper trading (simulated, no real orders)." Avoid enabling SnapTrade's trading endpoints in v1. Executing trades would push the app squarely into 3.2.1(viii).
- **Pricing:** The SnapTrade fixed $100/month means you need roughly 20 to 30 paying users at C$7 to C$10/month just to cover the aggregator. Free tier: manual or CSV holdings plus paper trading plus education. Paid tier (about C$7.99/month or C$59 to C$79/year): live brokerage and bank sync, cross-account ACB, superficial-loss alerts, the T1135 monitor and the AI assistant. This sits between adjustedcostbase.ca and Wealthica Premium. RevenueCat data suggests testing a hard paywall with a short trial for the sync features.

### Gaps
- No finance-category conversion rates, trial-to-paid rates or median prices from RevenueCat (behind the full PDF) or other sources were found.
- No published revenue figures for indie Canadian finance apps were found.
- No documented App Store rejection cases for solo-developer portfolio trackers citing 5.1.1(ix) were collected. Enforcement against read-only aggregators varies (anecdotal; unsourced).
