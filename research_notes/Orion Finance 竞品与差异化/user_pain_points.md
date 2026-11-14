# User Pain Points and Switching Triggers: Personal Finance, Net Worth and Portfolio Apps (Canadian focus, 2024–2026)

> **Method note (important for the report writer):** Reddit (reddit.com and old.reddit.com) blocks this research tool, and every Redlib mirror tried failed (psf.lt, birdcat.cafe, hf.space). So **no r/PersonalFinanceCanada, r/CanadianInvestor or r/MonarchMoney threads could be read directly**. The voice of the user here comes from other sources:
> - Canadian App Store reviews of Monarch, read directly
> - Trustpilot reviews of Wealthica and Snowball Analytics, read directly
> - A Canadian forum thread on highinterestsavings.ca, read directly
> - Hacker News threads, read directly
> - Financial Wisdom Forum and RedFlagDeals threads, seen only as search snippets
> - Vendor documentation and help centres
> - Competitor and affiliate comparison blogs, flagged as biased wherever they are cited
>
> Reddit titles below are taken from search-result metadata only. Today's date is 2026-11-13.

---

## 1. The most common complaints, ranked roughly by frequency

### Takeaway
Broken or flaky account connections and repeated re-authentication are by far the most frequent complaint, especially for Canadian big banks (CIBC, RBC). The other recurring complaints are:
- No real CAD/USD multi-currency handling
- Holdings and cost-basis data that is incomplete or wrong
- Price increases and price-to-value doubts
- Billing and cancellation problems
- Budgeting apps that are weak at investments

Canadian registered-account features (TFSA, RRSP, FHSA contribution room, CRA-style ACB) are almost entirely missing from mainstream apps and appear mainly as spreadsheet workarounds.

### Cited Findings

**Rank 1: Broken connections and re-authentication (dominant theme across every source type)**

Monarch, Canadian App Store, critical reviews from 2024–2025. 8 of the ~10 clearly negative reviews on the CA review page are about sync or disconnects, and several name Canadian banks:
- "Several of my accounts disconnect on a daily basis" (aaardvarkkk, 2025-11-10). Each reconnect needs security questions or a one-time code. — [App Store CA, Monarch reviews](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- "CIBC sync: Daily disconnects make it unusable" (Nadonpal, 2025-09-11). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- "Not good with CIBC (Canada): It keeps disconnecting my bank accounts", and full history doesn't import (Cra-ZGuy, 2025-08-03). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- "CIBC never syncs": needs manual fixes almost daily and the reviewer is considering cancelling (KrissyKus, 2024-09-22). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- "Doesn't work well with RBC": accounts show as synced but transactions are missing (theyurinator, 2024-11-05). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- "Constantly disconnecting… never showed the full picture." The reviewer paid for a year and stopped using it (Kiyomiee, 2025-12-06). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- Monarch's standard developer reply (Aug–Sep 2025) says most banks work well, but some institutions don't work well with its data providers, and asks the user to file a ticket. — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)

Wealthica, Trustpilot, 2022–2026 (overall 3.8 from 15 reviews; 6 of the 15 are 1-star):
- "connection with institution (core feature) does not work" (2026-04-12). — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- "there are real syncing issues that don't keep your account up to date" and "customer support is horrendous" (2025-08-12). — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- "You have to sync the bank every day" (2024-12-24). — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- Wealthica's own reply (Jan 2025) concedes that bank sessions sometimes need renewal and that 2FA codes can require re-entry on each sync. — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- Positive counter-review: "only Wealthica actually worked!" (2025-03-11). — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- Another positive review describes a BMO connection fix that took about a week (2026-03-27). — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- Wealthica's status page and blog record recurring connector incidents with Wealthsimple Trade/Invest, Questrade API tokens (2018) and Qtrade (July 2026). — [Wealthica blog: Wealthsimple connection issue](https://wealthica.com/blog/connection-issue-with-wealthsimple-invest-and-trade/); [Wealthica status: Qtrade incident](https://status.wealthica.com/incidents/qg3tbm58)

Snowball Analytics, Trustpilot:
- "Now, none of the accounts sync ever so it has been a waste of money" (1-star, 2026-11-12). The vendor blamed the broker's "outdated API". — [Trustpilot CA, Snowball Analytics](https://ca.trustpilot.com/review/snowball-analytics.com)
- An earlier review calls sync "inconsistent", which "discourages use", and says a brokerage shows incorrect balances and profits. — [Trustpilot via search summary](https://ca.trustpilot.com/review/snowball-analytics.com)

Getquin and HN context:
- A user summary says Getquin "can be sync with most brokers, but its slow". — [GummySearch Reddit-review aggregator](https://gummysearch.com/tools/best-products/portfolio-trackers/)
- On HN, a commenter says bank sync is US-centric and "mostly use a single provider" (amrawad). Sync is a dealbreaker: "If an app doesn't include syncing it's not worth it" (bix6). — [HN: Wealthfolio 2.0 Show HN](https://news.ycombinator.com/item?id=46006016)

Root cause in Canada: no open banking yet, so apps rely on screen scraping.
- The government estimates "approximately nine million Canadians" rely on screen scraping. — [money.ca](https://money.ca/banking/bank-of-canada-open-banking-consumer-driven-banking-regulations); [openbankingtracker](https://openbankingtracker.com/blog/open-banking-canada-what-is-coming-in-2026-and-2027)
- Status of the regime:
  - The Consumer-Driven Banking Act received Royal Assent (Bill C-15).
  - Draft regulations were published in the Canada Gazette on 2026-06-27.
  - Budget 2025 targeted a Q3 2026 launch, and observers expect slippage to late 2026 or 2027.
  - — [openbankingtracker](https://openbankingtracker.com/blog/open-banking-canada-what-is-coming-in-2026-and-2027); [dev.to](https://dev.to/hash02/canadas-open-banking-law-just-turned-on-nobody-will-say-when-the-apis-do-5hdh)
- Sources conflict on whether the screen-scraping ban is already in force. The more recent sources say it is not. — [money.ca](https://money.ca/banking/bank-of-canada-open-banking-consumer-driven-banking-regulations)
- Lunch Money (vendor) says RBC, TD, Scotiabank, CIBC, Tangerine and others are "still operating on older authentication methods while awaiting final open banking and OAuth regulatory guidance", leaving "broken bank connections". — [Lunch Money blog, 2025-12-02](https://lunchmoney.app/blog/the-only-personal-finance-app-canadians-need)
- Wealthsimple's own help centre says that, because open banking isn't yet supported in Canada, external account balances in its net worth feature "may not update automatically" and must be refreshed by hand. — [Wealthsimple Help](https://help.wealthsimple.com/hc/en-ca/articles/47404070566555)

**Rank 2: Canadian coverage gaps (many US apps don't work in Canada at all)**
- **Copilot Money:** Its help centre reportedly limits support to US institutions, and the app is reportedly not in the Canadian App Store as of September 2026. The source is a competitor, Waypoint Budget; a March 2025 Bremo guide claimed broader Canadian support, so sources conflict. — [Waypoint Budget](https://waypointbudget.com/copilot-alternative); [Bremo](https://bremo.io/mint-alternatives-canada)
- **Empower:** A Canadian forum answer says "as a Canadian you cannot use Empower" because it only links US institutions. This is from a 2023 Q&A, not official policy. — [StockTrades.ca](https://www.stocktrades.ca/answers/unsure-as-how-to-use-empower-as-it-only-links-to-us-institutions-any-thoughts/)
- **Mint's shutdown:** Mint closed in early 2024; sources conflict between Jan 1 and Mar 23, 2024. US users were moved to Credit Karma, but Canadians got no migration path. Monarch's CEO said "in Canada, there weren't as many options". — [BetaKit, 2023-12-14](https://betakit.com/as-intuit-winds-down-mint-financial-planning-app-monarch-money-comes-to-canada/); [money.ca](https://money.ca/managing-money/budgeting/alternatives-to-mint)
- **Monarch's Canadian service:** "Customer Service is practically useless for Canadian customers" on keeping bank connections, and refunds were refused (MalcyGla, 2024-10-06). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)

**Rank 3: CAD/USD and multi-currency handling**
- Monarch's help centre says it "does not differentiate between currencies behind the scenes and does not perform any currency conversion". — [Monarch Help: International Accounts and Currency](https://help.monarch.com/hc/en-us/articles/360048393552-International-Accounts-and-Currency)
- BetaKit (Dec 2023) reported that Monarch at its Canadian launch billed only in USD by credit card and did not support multiple currencies. — [BetaKit](https://betakit.com/as-intuit-winds-down-mint-financial-planning-app-monarch-money-comes-to-canada/)
- A Reddit user (r/mintuit, title from search metadata: "Any trackers that convert CAD values to USD…") added CAD and USD accounts, expected conversion, and found "no". — [r/mintuit via mirror](https://reddit.birdcat.cafe/r/mintuit/comments/1ketytz/any_trackers_that_convert_cad_values_to_usd_when)
- HN: "I've noticed most budget apps cannot handle multiple currencies at all" (iancarroll). — [HN Wealthfolio 2.0](https://news.ycombinator.com/item?id=46006016)
- A Canadian blogger's Google Sheets net worth tracker adds manual rows for "USD value of investments" and the "CAD/USD exchange rate". This is the typical spreadsheet workaround. — [The Measure of a Plan](https://themeasureofaplan.com/getting-your-ducks-in-a-row/)
- Lunch Money markets automatic CAD conversion, which is evidence that vendors see this as a selling point for Canadians. — [Lunch Money blog](https://lunchmoney.app/blog/the-only-personal-finance-app-canadians-need)

**Rank 4: Holdings and cost-basis inaccuracy, and weak investment analysis in budgeting apps**
- Monarch's help centre admits it receives cost-basis data from brokerages only "~50% of the time" through automated connections, and recommends manual entry. — [Monarch Help: Adding Gains & Losses](https://help.monarch.com/hc/en-us/articles/45946555058964-Adding-Gains-Losses-to-Investments)
- Monarch also warns that pricing and performance may be inaccurate for unsupported tickers. — [Monarch Help: Investments](https://help.monarch.com/hc/en-us/articles/41855507661076-Investments-in-Monarch)
- Rob Berger's Monarch review says investment tracking gets the most complaints on Reddit, from connection issues and limited analysis. — [Rob Berger](https://robberger.com/monarch-money-review/)
- Motley Fool: "some users report that it's difficult to monitor investment transactions". — [The Ascent](https://www.fool.com/the-ascent/personal-finance/monarch-money-review)
- Snowball: reinvested cash was still reported as "cash" after a broker sync (2026-01-14). — [Trustpilot CA, Snowball](https://ca.trustpilot.com/review/snowball-analytics.com)
- Kubera lacks tax planning and detailed investment analysis (comparison blog). — [Mezzi](https://www.mezzi.com/blog/kubera-price-hike-worth-it-alternatives-compared)

**Rank 5: Pricing, price hikes and billing practices**
- Monarch, CA reviews: "Not worth the $100 annual fee" (2024-09-04); "Complete waste of money" (2025-08-03). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- YNAB raised its annual price to $109 in September 2024. Users complained the email gave no reason. — [r/ynab top-of-year listing via mirror](https://lr.sudovanilla.org/r/ynab/top/?t=year) (search metadata only)
- A secondary site reports a June 2026 backlash over in-app ads for the CEO's book. This is a low-credibility source. — [mwm.ai](https://mwm.ai/articles/ynab-v26-20-adds-ceo-book-ads-sparks-user-outrage-over-ui-changes-in-june-2026)
- Kubera Essentials is now $249/yr, up from $150/yr, and its Black tier is $2,499/yr. — [Mezzi](https://www.mezzi.com/blog/kubera-price-hike-worth-it-alternatives-compared); [Wallet Hacks](https://wallethacks.com/kubera-review/)
- Wealthica went from free to paid in Nov 2023: $50 / $75 / $150 / $250 per year tiers, with Wealthscope as a $15.95/mo add-on. Exports require a paid plan. — [Wealthica pricing](https://wealthica.com/pricing); [Savvy New Canadians](https://www.savvynewcanadians.com/wealthica-review-free-portfolio-tracker-canada/)
- Billing complaints: two Wealthica reviewers (Nov and Dec 2024) say they were charged after cancelling. — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- Snowball: Canadians with TFSA/RRSP/LIRA split accounts are pushed to the paid tier, and "Full price is too much" (2026-10-07). — [Trustpilot CA, Snowball](https://ca.trustpilot.com/review/snowball-analytics.com)

**Rank 6: Privacy, data monetization and advisor sales calls**
- Empower's advisor team reportedly reaches out once linked investable assets cross about $100k, and calls recur even after users opt out. Many competitors now market themselves as "no sales calls" (CountAbout, Fuego, BankSync, MyFinanceTools); all are vendor sources. — [CountAbout](https://countabout.com/empower-alternative/); [Fuego](https://www.fuego.money/empower-alternative); [BankSync](https://banksync.io/blog/empower-personal-dashboard-alternative)
- HN: "Trusting some random VC-backed SAAS not to sell my data is… as mad as trusting that the tide won't come in" (danielheath); "Plaid… I don't trust them at all" (nirvdrum). — [HN Wealthfolio 2.0](https://news.ycombinator.com/item?id=46006016)

**Rank 7: Data loss and app shutdown risk**
- "The decade+ of transaction history I had in Mint was just GONE" (cortesoft). — [HN Wealthfolio 2.0](https://news.ycombinator.com/item?id=46006016)
- Monarch CA: "Transactions are randomly lost", even after manual re-entry, so the app is worse than a CSV import (andrewnt219, 2024-09-04). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)

**Rank 8: No support for Canadian tax accounts or ACB**
- One review says Wealthica "doesn't compute ACB with as much depth", and Sharesight's tax logic is "oriented toward ATO/HMRC, not the CRA". The source is WealthWise, a competitor. — [WealthWise](https://mywealthwise.ca/en/blog/best-portfolio-tracker-canada-2026)
- Contradicting that, Greenline (also a competitor) says Sharesight offers a Canadian capital gains/ACB report on its Standard plan. — [Greenline](https://usegreenline.com/en-ca/articles/best-portfolio-tracker-canada)
- Financial Wisdom Forum (2023): Wealthica tracks ACB but requires bank login credentials, which some users refuse. Users instead build per-security ACB spreadsheets. — [FWF: How to better track ACB?](https://www.financialwisdomforum.org/forum/viewtopic.php?t=125668)
- Getquin "doesn't have specific features for Canadian account types, tax rules" (biased competitor source). — [Greenline vs getquin](https://greenline-corporate-vibe.pages.dev/en-ca/compare/getquin)

**Rank 9: AI features feel gimmicky**
- Even vendors concede that "half the tools calling themselves AI are just budgeting apps with slightly better auto-categorization and a chatbot bolted on", and that such products feel impressive "for about six minutes". — [Origin blog](https://useorigin.com/resources/blog/is-an-ai-finance-app-better-than-a-budgeting-app); [Finny](https://getfinny.app/blog/ai-budget-management-tools-2026)
- A Cleo review criticizes its "full bank access" privacy trade-off. — [PocketClear](https://pocketclear.app/blog/cleo-app-review-2026.html)
- GoBankingRates warns that AI finance apps push upsells and loans. — [GoBankingRates](https://www.gobankingrates.com/?p=2435706)

### Inferences
- In Canada, connection reliability for big-bank chequing and credit cards (CIBC and RBC are named repeatedly) is the #1 churn driver for Monarch. The cause is structural (screen scraping, no open banking), not just a Monarch problem.
- Brokerage connections through SnapTrade (Wealthsimple, Questrade) may be a relative strength for Orion, because they use OAuth or an API where available. Orion should still expect Plaid-for-Canadian-banks to inherit the same daily re-authentication complaints.
- What Canadian users actively work around is the combination of CAD/USD conversion, registered-account labelling (TFSA/RRSP/FHSA) and CRA-style ACB. Spreadsheets currently fill that niche, and no mainstream consumer app does it well.
- Graceful degradation (manual balance entry, CSV import, clear staleness indicators) matters because users rage-quit when the "full picture" breaks.

### Gaps
- No quantitative frequency ranking was possible; the Reddit API and site were blocked. The ranking above is qualitative, based on counts within the sampled App Store and Trustpilot pages.
- No direct reads of r/PersonalFinanceCanada, r/CanadianInvestor or r/Wealthsimple threads.
- No Google Play reviews were read. The Wealthica iOS review page returned 404; its Google Play rating is reportedly 4.1 from 557 reviews, per [App Pricing Lab](https://www.apppricinglab.com/app/google_play/com.wealthica).
- Not covered: Rocket Money's Canadian availability, Delta's Canadian sync quality, Sharesight user complaints, bank- and broker-native app complaints.
- No evidence was found of a 2025–2026 Monarch price increase; its listing price is about $99.99 USD/yr. This is unverified.

---

## 2. Why people still use spreadsheets

### Takeaway
Canadian investors use spreadsheets because:
- They refuse to share credentials
- Apps can't handle CAD/USD and CRA-style ACB
- Apps go paid or shut down
- They want full control and longevity

The cost is manual entry, which users admit eventually kills spreadsheets.

### Cited Findings
- When Wealthica moved from free to paid (Nov 2023), users replied "Users should consider a spreadsheet" (mordko, 2023-11-26) and "this is exactly why I built my own spreadsheet" (kesa, 2023-12-01). — [highinterestsavings.ca forum](https://www.highinterestsavings.ca/forum/general-financial-discussion/wealthica-portfolio-management-software-free-to-fee/)
- Financial Wisdom Forum users keep one spreadsheet tab per security to track every ACB-affecting transaction. Wealthica's need for login credentials is a cited reason (2023). — [FWF t=125668](https://www.financialwisdomforum.org/forum/viewtopic.php?t=125668)
- A 2019 FWF Google Sheet handles dividend alerts, ACB, and time- and money-weighted returns, with ACB in a Schedule 3-ready format (dated). — [FWF t=122135](https://www.financialwisdomforum.org/forum/viewtopic.php?t=122135)
- Canadian blog trackers add manual CAD/USD rows. — [The Measure of a Plan](https://themeasureofaplan.com/getting-your-ducks-in-a-row/); [Blueprint Financial free Canadian tracker](https://blueprintfinancial.ca/net-worth-tracker-canada-free-download-walkthrough/)
- Template sellers target people "who'd rather not link bank accounts to yet another app", promising "no bank logins, no app subscription". — [search summary of SpendWise and similar templates](https://superprofile.bio/vp/6ae41e0f0200c400076ed629)
- A spreadsheet guide argues that typing in each balance "forces you to look at every account". — [MyFinanceTools](https://myfinancetools.io/personal-finance/how-to-track-net-worth-spreadsheet-vs-app/)
- The same guide's counterpoint: "an app doesn't track anything a spreadsheet can't; it just does the fetching, converting, and snapshotting for you", and manual work is what "eventually kills a spreadsheet". — [MyFinanceTools](https://myfinancetools.io/personal-finance/how-to-track-net-worth-spreadsheet-vs-app/)
- HN: "manually importing data from dozens of accounts every day… is simply too much of a burden" (paxys). — [HN Wealthfolio 2.0](https://news.ycombinator.com/item?id=46006016)
- RedFlagDeals "Tracking net worth" thread: users describe spreadsheet methods (snippet only). — [RFD](https://forums.redflagdeals.com/tracking-net-worth-2743582/)

### Inferences
- Orion's opportunity is "the spreadsheet, but automatic". That means:
  - Auto-fetch balances and holdings
  - Auto FX conversion with a CAD/USD toggle
  - Monthly net worth snapshots
  - Per-account tax-type tags
  - Easy export to CSV or Sheets, so spreadsheet users don't feel locked in
- Free export is valued because Wealthica gating exports behind a paid plan was noted as a con.

### Gaps
- Could not verify the specific popular r/PersonalFinanceCanada Google Sheets trackers (e.g. community-shared templates) or their usage counts.

---

## 3. Concrete switching stories and triggers

### Takeaway
Switching is overwhelmingly triggered by external events, not by attraction to a new product:
- A shutdown (Mint)
- A free-to-paid change (Wealthica, YNAB legacy users)
- A price hike (Kubera, YNAB)
- Persistent sync failures (Monarch, Snowball)
- Sales-call annoyance (Empower)

The common destinations are Monarch (from Mint and Empower), Copilot (from Mint, US only), spreadsheets, and self-hosted or local-first tools.

### Cited Findings
- **Mint → Monarch (Canada):** Monarch "fast-tracked" its Canadian launch after the Mint shutdown news, reaching about 3,500 active Canadian users shortly after rollout (Dec 2023). — [BetaKit](https://betakit.com/as-intuit-winds-down-mint-financial-planning-app-monarch-money-comes-to-canada/)
- **Mint → Copilot or Monarch (US):** One blog commenter: "when informed of the change to Credit Karma we switched to Copilot". A Reddit user found Monarch "costs money, but I actually like it a lot more than I liked Mint". — [MyMoneyBlog](https://www.mymoneyblog.com/mint-to-credit-karma-transition-alternatives.html); [r/mintuit via mirror](https://lr.eu.psf.lt/r/mintuit/comments/1dykju5/is_anyone_else_outraged_over_the_mint_to_credit) (search metadata)
- **Mint data loss as a trigger for local-first:** "decade+ of transaction history… just GONE". — [HN](https://news.ycombinator.com/item?id=46006016)
- **Monarch → considering cancelling or churned (Canada):** These are sync-triggered (CIBC, RBC). A user stopped using Monarch after paying for a year (2025-12-06). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- **Monarch/Quicken → back to YNAB:** An r/ynab thread from Jul 2024 is titled "I've tried Monarch, Quicken and others, they're crap" (title only). — [r/ynab via mirror](https://rl.blitzw.in/r/ynab/comments/1dt70p7/ive_tried_monarch_quicken_and_others_theyre_crap)
- **YNAB → elsewhere after the subscription move:** "I happily paid for v4 (one-time purchase), but was/am not willing to pay for v5"; "I don't like renting software" (throw0101c). — [HN](https://news.ycombinator.com/item?id=46006016)
- **Wealthica free → paid (Nov 2023):** Users discussed spreadsheets, Passiv, and Quicken's investing site; the last "works for Canadians but tracks investments only". — [highinterestsavings.ca](https://www.highinterestsavings.ca/forum/general-financial-discussion/wealthica-portfolio-management-software-free-to-fee/)
- **Empower/Personal Capital → Monarch:** Comparison blogs call Monarch "the strongest single switch for most ex-Personal Capital users", with sales calls as the trigger (vendor or affiliate source). — [People & Media](https://www.peopleandmedia.com/personal-capital-alternatives/); [BankSync](https://banksync.io/blog/empower-personal-dashboard-alternative)
- **Snowball → cancel:** Triggered by sync failure (2026-11-12) and price ("Full price is too much", 2026-10-07). — [Trustpilot CA, Snowball](https://ca.trustpilot.com/review/snowball-analytics.com)
- **Kubera → alternatives:** Triggered by the price rise from $150 to $249. — [Mezzi](https://www.mezzi.com/blog/kubera-price-hike-worth-it-alternatives-compared)
- **Wealthsimple as an emerging native competitor:**
  - Wealthsimple now has a net worth feature (personal plus household) with external accounts linked or added manually.
  - It acquired Plenty, a couples net worth app, in April 2025.
  - This reduces the need for a third-party tracker among Wealthsimple-centric users.
  - — [Wealthsimple Help](https://help.wealthsimple.com/hc/en-ca/articles/47404070566555); [iPhone in Canada](https://www.iphoneincanada.ca/2025/04/10/wealthsimple-acquires-financial-planning-app-for-couples/)

Features users say would make them switch (wish list):
- Automatic sync without daily re-authentication
- Multi-currency conversion
- Bring-your-own Plaid key (codegeek)
- Local, no-cloud storage
- No subscription
- — [HN](https://news.ycombinator.com/item?id=46006016)

### Inferences
- Orion's natural acquisition moments:
  - Monarch users in Canada frustrated by CIBC and RBC disconnects
  - Wealthica users unhappy with paid tiers or sync
  - Copilot-curious Canadians who can't get the app
  - Spreadsheet users who want automation
- Wealthsimple's native net worth feature is a serious "good enough" threat for Wealthsimple-only investors. Orion's differentiation must be multi-institution plus CAD/USD plus research.

### Gaps
- No direct Reddit switching stories from r/PersonalFinanceCanada or r/CanadianInvestor (access blocked).
- No data on churn rates or switching volumes.

---

## 4. Willingness to pay

### Takeaway
Roughly USD 50–110 a year is the accepted band for a mainstream tool:
- Monarch about $99.99 and YNAB $109 are tolerated but heavily scrutinized against reliability.
- Higher prices draw "not worth it" responses: Kubera at $249, Wealthica's top tiers at $150–250, Snowball's full price.

A vocal minority strongly prefers one-time purchases, and Canadian users resent USD billing. Willingness to pay is conditional on sync actually working: "for a paid service" disconnects are framed as unacceptable.

### Cited Findings
- "I don't think it is worth the $150 annual fee" for Wealthica (Kirk, 2023-11-21). Another user replied that "the $75 annual plan will likely suffice" (musicalmaestro). — [highinterestsavings.ca](https://www.highinterestsavings.ca/forum/general-financial-discussion/wealthica-portfolio-management-software-free-to-fee/)
- Others there argued the free model was unsustainable and only a small group would pay (mordko). — [highinterestsavings.ca](https://www.highinterestsavings.ca/forum/general-financial-discussion/wealthica-portfolio-management-software-free-to-fee/)
- Wealthica's 2022 reviewer complained: "now you need to pay $5/month or $50/year" for more than two accounts. — [Trustpilot CA, Wealthica](https://ca.trustpilot.com/review/wealthica.com)
- Monarch: "Not worth the $100 annual fee"; "for a paid service, this is fairly unsatisfactory" (2023-12-20, dated). — [App Store CA, Monarch](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews)
- YNAB $109: one r/ynab poster said that under $10 a month is cheap compared with streaming services; others called it overpriced (2024, search metadata). — [r/ynab via mirror](https://lr.in.psf.lt/r/ynab/comments/1f3hy2s/my_ynab_hot_take_the_price_is_perfectly_reasonable)
- HN on paying: "i would happily pay. i already pay for monarch" (onelesd); "I renewed my annual Quicken Simplify for $40" (sakopov); one-time purchase preferred over subscription (throw0101c); "no subscription, no cloud" as a positioning goal. — [HN](https://news.ycombinator.com/item?id=46006016)
- Monarch billed only in USD at its Canadian launch, with CAD billing "in development" (Dec 2023). — [BetaKit](https://betakit.com/as-intuit-winds-down-mint-financial-planning-app-monarch-money-comes-to-canada/)
- Kubera: Essentials at $249/yr is criticized as expensive when free tools exist. — [Wallet Hacks](https://wallethacks.com/kubera-review/); [Mezzi](https://www.mezzi.com/blog/kubera-price-hike-worth-it-alternatives-compared)
- Copilot is about $14.99/mo, per a Canadian comparison. — [WealthNorth](https://wealthnorth.ca/personal-finance/budgeting/best-ai-budgeting-apps-canada/)
- Snowball: Canadians with split TFSA/RRSP/LIRA accounts must upgrade to paid. — [Trustpilot CA, Snowball](https://ca.trustpilot.com/review/snowball-analytics.com)

### Inferences
- For a solo-developer iOS app, a CAD-priced plan around CAD $5–8/mo or CAD $50–80/yr sits inside the accepted band. A free tier covering one or two accounts would mirror Wealthica's historical $50/yr entry point.
- A lifetime or one-time option could win the vocal anti-subscription segment, but data-aggregator costs (Plaid/SnapTrade per-connection fees) make an unlimited lifetime plan risky.
- Billing in CAD is a cheap differentiator.

### Gaps
- No survey-quality data on willingness to pay among Canadians.
- Could not verify current Monarch CAD pricing or any 2025–2026 price change.

---

## 5. Trust: credentials, aggregators and local data

### Takeaway
Trust concerns cluster around four things:
- Handing bank credentials to a third party, since Canadian banks still lack OAuth and open banking
- Distrust of Plaid's data practices
- VC-backed SaaS selling data or pushing advisors (Empower)
- Shutdown risk

Users are more comfortable when access is explicitly read-only, credentials are not stored, the vendor is SOC 2 audited, and data stays local or exportable.

### Cited Findings
- FWF users decline Wealthica because "it requires bank login credentials" (2023). — [FWF t=125668](https://www.financialwisdomforum.org/forum/viewtopic.php?t=125668)
- About nine million Canadians use screen scraping, which means credential sharing. The regulator's goal is to replace it with a consumer-driven banking (CDB) framework. — [money.ca](https://money.ca/banking/bank-of-canada-open-banking-consumer-driven-banking-regulations)
- HN: "Plaid… I don't trust them at all" (nirvdrum); "Trusting some random VC-backed SAAS not to sell my data…" (danielheath). — [HN Wealthfolio 2.0](https://news.ycombinator.com/item?id=46006016)
- In older HN threads, users dispute whether Plaid sells data or stores credentials where banks lack OAuth. Plaid states it shares data only to power chosen services or prevent fraud. — [HN: Are you terrified of Plaid's verification approach? (2021, dated)](https://news.ycombinator.com/item?id=28389576)
- Ask HN (about 2026): "How do you handle personal finance without giving data to third parties?" The OP rejects both Plaid/Tink-based tools and spreadsheets. A commenter builds a browser-local app where "nothing enters a cloud service". — [HN](https://news.ycombinator.com/item?id=47388256)
- A Show HN "privacy-first" finance app markets "no Plaid" and end-to-end encryption, evidence that privacy is used as a wedge. — [HN Show HN privacy-first finance app](https://news.ycombinator.com/item?id=46386652)
- Wealthfolio (open-source, local-first investment tracker) drew strong HN interest in both 2024 and 2025 Show HNs. — [HN 2024](https://news.ycombinator.com/item?id=41465735); [HN 2025](https://news.ycombinator.com/item?id=46006016)
- SnapTrade: read-only or trade access is configurable per connection. Integrators state credentials are never stored. SnapTrade claims SOC 2 Type II. Where a broker lacks OAuth, SnapTrade must use credentials. — [SnapTrade brokerage API](https://snaptrade.com/brokerage-api); [Blossom help](https://intercom.help/blossom-social-inc/en/articles/8134374-how-to-link-your-brokerage-to-blossom)
- A security audit of one third-party SnapTrade integration flagged that it requested "trade" scope when read-only would suffice. Users and reviewers do check scope. — [ClawHub audit](https://clawhub.ai/brendanwood/skills/snaptrade/security-audit)
- Empower sales calls are cited as a privacy and trust negative; a whole category of competitors markets itself as "no sales calls" (vendor sources). — [CountAbout](https://countabout.com/empower-alternative/); [Fuego](https://www.fuego.money/empower-alternative)
- Wealthica's ownership of the Vezgo API, and its 10-year track record with 65k users, is used as a credibility signal (vendor PR via search). — [CB Insights / Wealthica](https://www.cbinsights.com/company/wealthica)

### Inferences
- Orion should prominently communicate:
  - Read-only scopes, requested explicitly for SnapTrade
  - No credential storage
  - No data selling and no advisor upsell
  - On-device or local caching
  - One-tap export and delete
- "Built by a Canadian solo developer, no VC, no sales calls" could be a positive trust story. Shutdown risk is the counter-concern, which an easy export mitigates.
- An AI assistant that sends financial data to a third-party LLM may trigger the same distrust. Users will need clear disclosure and an opt-in.

### Gaps
- No direct user sentiment found on Flinks (a Canadian aggregator) or on SnapTrade specifically from end users.
- No Canadian survey data on aggregator trust.
- Could not read Reddit threads on Wealthsimple/Questrade linking trust.
