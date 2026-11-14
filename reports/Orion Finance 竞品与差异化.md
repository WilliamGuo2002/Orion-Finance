# 让 Orion 赢下多账户加拿大投资者

Orion Finance 现有的核心卖点已经不独特。“Plaid 银行 + SnapTrade 券商 + CAD/USD 切换 + iPhone”这套组合，Mozaic Finance 已经以 **C$99/年** 在卖。Wealthsimple 给自家用户提供免费的净资产页，2026 年 11 月又推出了能在用户确认后下单的 AI 助手 **Penny**。Questrade 和 IBKR 已把账户通过 MCP 开放给 ChatGPT、Claude，ChatGPT、Claude、Perplexity 也都能通过 Plaid 读取账户。结果是“和我的投资组合聊天”正在变成免费的标配。真正还没人占住的位置是这样的：用户在多家机构都有账户，Orion 把这些跨账户数据，按加拿大的税务和账户规则变成具体提醒（超额亏损窗口、TFSA 里的美股股息预扣税泄漏、T1135 门槛），再由一个只解释、不荐股的 AI 讲清楚。用户的证据也指向同一结论：人们换应用，几乎都是被外部事件推着走（银行同步天天断开、涨价、停服、不支持加拿大），很少是被新功能吸引。所以 Orion 要赢，靠的是在这些时刻“刚好能用”，具体是：连接状态透明可见、以加元计价、有加拿大税务护栏。眼下最紧迫的反而是合规和生存。按风险画像给出的个性化荐股和组合构建，在加拿大可能构成需要注册的“投资建议”。App Store 也要求金融类应用以法人主体提交。建议先把这两件事改掉，再在 **C$69/年** 左右的单一付费档推出“加拿大税务护栏 + 有出处的 AI”，正面对抗 Mozaic，并承接对 Monarch 和 Wealthica 不满的用户。

## 十几款竞品各占一块，没有一家同时做聚合、加拿大税务和研究 AI

竞品可以分成四类，每一类都只覆盖 Orion 功能面的一部分。

第一类是美国的净资产和记账聚合器，包括 Monarch、Copilot、Empower、YNAB、Rocket Money 和 Simplifi。它们以美元为先，**Copilot、Empower、Rocket Money 基本不服务加拿大**。Monarch 虽然开设了加拿大页面，但仍以美元计费，帮助中心也写明它“不做任何货币转换” ([Monarch Help](https://help.monarch.com/hc/en-us/articles/360048393552-International-Accounts-and-Currency))。

第二类是加拿大本土工具。Wealthica 的 ACB 和税务报表最深，但从 2023 年 11 月起改为全付费 ([Unified](https://unifiedbankings.com/blog/wealthica-review))。Mozaic Finance 的技术栈与 Orion 几乎一样。adjustedcostbase.ca 和 AllInvestView 只做税务计算。

第三类是全球投资追踪和研究工具，包括 Snowball、Sharesight、Getquin、Stock Events、Seeking Alpha、Simply Wall St 和 Morningstar。它们对 Wealthsimple 大多只支持文件导入，也没有加拿大税务视角。

第四类正在快速变成主角：券商自带的 AI，以及接上银行账户的通用大模型。

| 产品 | 类型 | 价格（2026 年） | 加拿大支持 | 强项 | 弱点 | 来源 |
|---|---|---|---|---|---|---|
| Monarch Money | 美国记账/净资产 | US$99.99/年或 US$14.99/月，约 C$140/年；Plus 约 US$199.99/年（第三方） | 有加拿大页，美元计费；经 Plaid 接六大行 | 界面最精致，CSV 导出完整 | 不转换 CAD/USD；成本价仅约 50% 能自动拿到；加拿大银行频繁断开 | [定价](https://www.monarch.com/pricing)、[WealthNorth](https://wealthnorth.ca/personal-finance/budgeting/best-budgeting-apps-canada/) |
| Copilot Money | 美国记账 | 2026 年 11 月涨至 US$109 优惠价（原价 US$119）/年 | 只支持美国机构，只用美元 | UI、分类能力强，有 AI 助手 | 没有 Android，没有加拿大 | [Treasury.sh](https://treasury.sh/learn/how-much-does-copilot-money-cost)、[Borderless Budget](https://borderlessbudget.com/blog/copilot-money-review-expats) |
| Empower | 美国免费仪表板 | 免费，靠约 0.89% AUM 的财富管理导流 | 只能连美国机构，注册需要美国手机号 | 免费工具里投资分析最强 | 有顾问推销电话，加拿大用不了 | [Empower 支持](https://support-personalwealth.empower.com/hc/en-us/articles/201169680-Can-I-link-an-international-account-in-Empower-Personal-Dashboard)、[Sheetlink](https://sheetlink.app/empower-pricing-2026) |
| YNAB | 预算方法论 | US$109/年 | 可用，但官方称加拿大连接“更具挑战” | 零基预算体系成熟 | 每个预算只能用一种货币，不追踪投资 | [Mozaic（竞品自述）](https://mozaicfinance.com/blog/best-personal-finance-app-canada-2026/) |
| Quicken Simplifi | 美国/加拿大记账 | 常规约 US$83.88/年（价格来自搜索摘要，未在官网核实） | 2024 年 8 月进入加拿大，接五大行 | 比 Monarch 便宜 | 社区仍在请求多币种支持 | [Unified](https://unifiedbankings.com/blog/rocket-money-canada)、[Simplifi 社区](https://community.simplifimoney.com/discussion/comment/52050) |
| Lunch Money | 加拿大独立开发者做的记账工具 | US$10/月，或年费 US$60–150 自选 | Plaid，支持多币种 | 有开放 API，可定制 | 投资交易不自动导入，移动端较弱 | [Mozaic](https://mozaicfinance.com/blog/best-mint-alternatives-canada-2026/) |
| Kubera | 高净值全资产 | 约 US$249/年（由 US$150 涨价） | 多币种贯穿各层 | 资产类别覆盖广 | 贵，缺税务分析 | [Thalvi](https://thalvi.pages.dev/compare/pricing/kubera)、[Mezzi](https://www.mezzi.com/blog/kubera-price-hike-worth-it-alternatives-compared) |
| Wealthica | 加拿大投资聚合 | C$50 / 75 / 150 / 250 每年 | 自建连接器覆盖 150+ 家加拿大机构，含 Scotia iTRADE 和 BMO | ACB、汇兑损益、收入和费用报表最深 | 以网页为主，连接常要重新登录，导出需付费 | [Unified](https://unifiedbankings.com/blog/wealthica-review)、[Wealthica](https://wealthica.com/blog/plaid-vs-wealthica/) |
| **Mozaic Finance** | 加拿大独立开发者做的聚合器 | **C$99/年**或 C$12.99/月，手动追踪免费 | Plaid（自称覆盖 196 家机构）加 SnapTrade（Wealthsimple、Questrade、IBKR、TD），CAD 本位，每日汇率 | 数据存放在蒙特利尔，有网页版加 iPhone | 不做研究层，没有 Android | [Mozaic（自述）](https://mozaicfinance.com/blog/best-personal-finance-app-canada-2026/) |
| Wealthsimple 净资产页 + Penny | 券商原生 | 免费 | 原生 | 外部机构可无限关联；Penny 可在用户确认后转账、交易、再平衡 | 外部账户只显示余额，而且“可能不会自动更新” | [Wealthsimple Help](https://help.wealthsimple.com/hc/en-ca/articles/47404070566555)、[BNN Bloomberg](https://www.bnnbloomberg.ca/business/artificial-intelligence/2026/11/05/wealthsimple-launches-ai-banking-assistant-that-can-help-move-money-place-trades/) |
| Snowball Analytics | 股息/表现追踪 | 免费档 10 个持仓；US$79.99 / 149.99 / 249.99 每年 | IBKR 可自动连接，Wealthsimple 和 Questrade 只能导入文件 | Expert 档提供 MCP，可接 Claude | 不计算加拿大资本利得 | [Snowball](https://snowball-analytics.com/pricing)、[AllInvestView](https://www.allinvestview.com/best-portfolio-tracker-canada/) |
| Sharesight | 表现与税务追踪 | 约 CA$9/月起（年付） | Questrade 和 IBKR 自动连接，Wealthsimple 靠文件 | 按 CRA 规则出 ACB 资本利得报表 | 移动端体验和 AI 不突出 | [Sharesight](https://www.sharesight.com/ca/investment-portfolio-tax/) |
| Getquin | 欧洲追踪器 | 免费 / €89.99 / €149.99 每年 | 定价页没提加拿大 | 免费档就能无限连接；高档有“AI 财务代理” | 不针对加拿大账户类型 | [Getquin](https://www.getquin.com/pricing/) |
| Stock Events | 自选与事件 | Pro US$49.99/年；免费档每 24 小时 5 条 AI 消息 | 未明 | 用“AI 配额”做付费引导 | 券商同步要单独付费 | [Stock Events](https://stockevents.app/pricing) |
| AllInvestView / adjustedcostbase.ca | 加拿大税务专用 | 约 US$6.99/月起；ACB.ca 有免费档，付费 $49/年 | 直连 Wealthsimple、Questrade；按交易日用 Bank of Canada 汇率 | 汇总 ACB、跨 TFSA/RRSP 识别超额亏损、T1135 助手 | 工具型界面，没有 AI | [AllInvestView（自述）](https://www.allinvestview.com/best-portfolio-tracker-canada/)、[adjustedcostbase.ca](https://www.adjustedcostbase.ca/) |
| Seeking Alpha / Simply Wall St / Morningstar | 研究平台 | 约 US$299 / 约 120 / 约 249 每年（第三方数据，互相矛盾） | 不涉及加拿大税务 | 内容深；Simply Wall St 有 Charlie AI | 贵，不懂用户的实际持仓 | [StockUnlock](https://stockunlock.com/seeking-alpha-vs-simply-wall-st.html)、[PageCrawl](https://pagecrawl.io/blog/best-investment-research-tools) |
| Dataroma / WhaleWisdom | 13F 大师持仓 | 免费 | 不涉及 | 数据免费、覆盖广 | 网页为主，没有 iOS 应用 | [FindMyMoat](https://www.findmymoat.com/vs/13f-info-vs-dataroma)、[WhaleWisdom](https://whalewisdom.com/) |

把这张表按功能拆开看，结论很清楚。聚合器都不做研究，研究平台都不懂用户的真实持仓，加拿大税务工具都没有现代界面和 AI。Orion 的功能清单恰好横跨这三块，这是机会。但它目前在每一块都只是“也有”，没有一块做到“最好”。

几个细节对 Orion 很关键。

Gurus 标签页用的 13F 数据在 Dataroma 和 WhaleWisdom 上免费就能看，只能当留存功能，不能当付费理由。

Fey 曾被称为“Bloomberg 遇上 Apple 设计”，**2025 年 8 月被 Wealthsimple 收购**，计划把它的自然语言选股和个性化新闻并入 Wealthsimple 应用 ([BetaKit](https://betakit.com/wealthsimple-acquires-fey-to-bolster-its-investment-research-capabilities/))。这意味着市场上暂时没有一款独立、设计精良、懂加拿大的多券商投资应用。这个空位对原生 SwiftUI 的独立开发者有利。

## 用户最痛的是连接断开，其次是 CAD/USD 和税务账户

由于 Reddit 无法访问，下面的排序基于加拿大区 App Store 评论、Trustpilot、加拿大论坛和 Hacker News 的定性计数，不是统计意义上的频次。各类来源的方向高度一致：**“全景图”一旦断掉，用户就退订。**

| 排名 | 痛点 | 代表性证据 | 对 Orion 的含义 |
|---|---|---|---|
| 1 | 账户连接断开、反复重新验证 | Monarch 加拿大区约 10 条明确差评中有 8 条与同步有关，点名 CIBC“每天断开，无法使用”、RBC“显示已同步却缺交易” ([App Store CA](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews))；Wealthica 用户说“每天都得重新同步银行” ([Trustpilot](https://ca.trustpilot.com/review/wealthica.com))；Snowball 用户说“所有账户都不再同步” ([Trustpilot](https://ca.trustpilot.com/review/snowball-analytics.com)) | 根源是结构性的：加拿大还没有开放银行。Orion 的 Plaid 银行连接会继承同样的问题，必须把“连接健康度”做成功能 |
| 2 | 美国应用不支持加拿大 | Copilot、Empower、Rocket Money 只服务美国；Mint 停服后加拿大用户没有迁移路径 ([BetaKit](https://betakit.com/as-intuit-winds-down-mint-financial-planning-app-monarch-money-comes-to-canada/)) | 有一批想用 Copilot 却用不了的用户 |
| 3 | CAD/USD 不换算 | Monarch 直接把 CAD 和 USD 余额相加 ([Monarch Help](https://help.monarch.com/hc/en-us/articles/360048393552-International-Accounts-and-Currency))；HN 用户说“大多数记账应用根本处理不了多币种” ([HN](https://news.ycombinator.com/item?id=46006016))；加拿大博主的表格要手动加一行汇率 ([The Measure of a Plan](https://themeasureofaplan.com/getting-your-ducks-in-a-row/)) | Orion 的切换功能对 Monarch、YNAB、Simplifi 是真优势，对 Mozaic、Wealthica 不是 |
| 4 | 持仓和成本价不准，记账应用投资分析浅 | Monarch 承认自动连接只有“约 50%”能拿到成本价 ([Monarch Help](https://help.monarch.com/hc/en-us/articles/45946555058964-Adding-Gains-Losses-to-Investments))；Rob Berger 说投资追踪是 Monarch 在 Reddit 上被抱怨最多的部分 ([Rob Berger](https://robberger.com/monarch-money-review/)) | 投资深度是 Orion 相对记账类应用的主战场，但 SnapTrade 成本价数据的完整度还没验证 |
| 5 | 涨价、性价比和计费 | “不值 $100 年费”（Monarch）；Kubera 从 $150 涨到 $249；Wealthica 转为付费后，论坛有人回应“用户应该考虑电子表格” ([highinterestsavings.ca](https://www.highinterestsavings.ca/forum/general-financial-discussion/wealthica-portfolio-management-software-free-to-fee/))；有用户在取消订阅后仍被扣款 | 以 CAD 计价、价格透明、取消容易，本身就是卖点 |
| 6 | 隐私、卖数据和顾问推销 | Empower 的顾问电话被大量竞品拿来做“无推销”营销 ([CountAbout](https://countabout.com/empower-alternative/))；HN 用户说“Plaid……我完全不信任” ([HN](https://news.ycombinator.com/item?id=46006016)) | “只读、不存凭证、不卖数据、不推销”要写在首屏 |
| 7 | 停服和数据丢失 | “我在 Mint 里十多年的交易历史就这么没了” ([HN](https://news.ycombinator.com/item?id=46006016))；Hardbacon 2024 年 8 月破产 ([Mozaic](https://mozaicfinance.com/blog/best-personal-finance-app-canada-2026/)) | 一键导出能对冲“独立开发者会不会跑路”的疑虑 |
| 8 | 缺少 TFSA/RRSP/FHSA 和 CRA 口径的 ACB | 论坛用户为每只证券单开一个表格标签页算 ACB，并因不愿交出银行密码而拒用 Wealthica ([FWF](https://www.financialwisdomforum.org/forum/viewtopic.php?t=125668)) | 这是最清楚的空白，目前主要靠电子表格填补 |
| 9 | AI 华而不实 | 连厂商都承认，很多“AI 理财”只是“自动分类加一个外挂聊天机器人”，新鲜感“大约六分钟” ([Origin](https://useorigin.com/resources/blog/is-an-ai-finance-app-better-than-a-budgeting-app))；用户在 AI 给出不透明预测时信任“迅速下降” ([diyai 的 Reddit 汇总](https://diyai.io/ai-tools/reddit/best-ai-finance-tools-on-reddit/)) | Orion 的 AI 要解释用户自己的数据并给出出处，不要“预测”和“荐股” |

两点值得特别注意。

第一，电子表格才是 Orion 最大的“竞品”。用户坚持用表格，是因为不愿交出密码、应用处理不了 CAD/USD 和 ACB、应用会突然收费或停服。可用户也承认，手动录入“最终会杀死电子表格” ([MyFinanceTools](https://myfinancetools.io/personal-finance/how-to-track-net-worth-spreadsheet-vs-app/))。Orion 最好的定位之一，就是“自动化的那张表格”。

第二，付费意愿是有条件的。US$50–110/年是被接受的区间，但前提是同步真的能用。“作为付费服务，这相当不合格”是典型说法 ([App Store CA](https://apps.apple.com/ca/app/monarch-money-budget-track/id1459319842?see-all=reviews))。

## 五股力量正在压缩 Orion 的空间

### Wealthsimple 正在把 Orion 的功能清单做进自家应用

Orion 的开发者本人就是 Wealthsimple 用户，而这恰恰是 Wealthsimple 最想留住的人群。Wealthsimple 在 2026 年第二季度有 **360 万客户、C$155.6B 资产** ([Newsfile](https://www.newsfilecorp.com/release/307150/Wealthsimple-Reports-17B-Net-Flows-in-Q2-Driven-by-High-Demand-for-Chequing-and-Spending-Products))，大约每 5 个 40 岁以下的加拿大人就有 1 个在用 ([iPhone in Canada](https://www.iphoneincanada.ca/2026/05/09/1-in-5-canadians-under-40-uses-wealthsimple-and-it-just-had-a-record-quarter/))。另有报道称截至 9 月 30 日 AUA 为 C$169.2B，用户超过 400 万 ([Advisor.ca](https://www.advisor.ca/industry-news/wealthsimple-embraces-ai-with-new-chatbot-connections-to-chatgpt-and-claude/))。这些年它补齐了 Orion 的几乎每一项功能：2025 年 4 月收购情侣净资产应用 Plenty ([iPhone in Canada](https://www.iphoneincanada.ca/2025/04/10/wealthsimple-acquires-financial-planning-app-for-couples/))，同年 8 月收购 Fey 补研究，又上线了可关联外部机构的免费净资产页。2026 年 11 月 5 日发布的 Penny 能在用户确认后买卖股票和 ETF、自动再平衡。2027 年初还会推出新应用，并支持把账户连到 ChatGPT 和 Claude ([BNN Bloomberg](https://www.bnnbloomberg.ca/business/artificial-intelligence/2026/11/05/wealthsimple-launches-ai-banking-assistant-that-can-help-move-money-place-trades/))。

它的短板也很明确。外部账户**只有余额，没有持仓和交易，而且“可能不会自动更新”** ([Wealthsimple Help](https://help.wealthsimple.com/hc/en-ca/articles/47404070566555))。Penny 只在 Wealthsimple 内部运行，不能访问外网 ([CTV](https://www.ctvnews.ca/business/article/wealthsimple-launches-ai-banking-assistant-that-can-help-move-money-place-trades/))。对资产全在 Wealthsimple 的用户，Orion 几乎没有理由存在。对“Wealthsimple 加大银行加 Questrade 或 IBKR”的多账户用户，Wealthsimple 结构上永远不会把竞争对手的持仓做深。

### 券商的 MCP 和通用大模型让“和组合聊天”变成免费标配

IBKR 在 2026 年 6 月把账户接入了 Claude、ChatGPT 和 Grok。Questrade 在 7 月推出“agentic finance”，通过 MCP 让 AI 助手分析组合、起草交易，并计划推出一个能**汇总其他机构持仓的“Balance Sheet”**，这是直接的净资产聚合竞品 ([BetaKit](https://betakit.com/questrade-is-remaking-its-platform-for-an-ai-driven-investing-market/)、[NCFA](https://ncfacanada.org/questrade-mcp-ai-brokerage-accounts/))。

通用大模型方面，ChatGPT 在 2026 年 5 月面向美国 Pro 用户开放了 Plaid 账户连接 ([OpenAI Help](https://help.openai.com/articles/20001222-finances-in-chatgpt))，Claude 在 11 月推出了仅限美国的 Personal Finance 中心 ([iPhone in Canada](https://www.iphoneincanada.ca/2026/11/06/claude-ai-gains-bank-account-access-to-help-fix-your-budget/))。Perplexity 的 Plaid 组合页有来源称加拿大用户也能连 ([CFOtech](https://cfotech.co.uk/story/plaid-perplexity-launch-ai-powered-portfolio-tool))，但也有来源相互矛盾。

加拿大目前处在一个短暂的窗口期：通用大模型的财务功能大多还没进入加拿大。但一旦 Wealthsimple 在 2027 年初开放 ChatGPT 和 Claude 连接，单纯的“AI 聊天”就不再构成差异。另外，Robinhood 已通过收购 WonderFi 进入加拿大 ([BetaKit](https://betakit.com/?p=406119))，它的 Cortex 和 Digests 有可能随之而来。

### Mozaic Finance 是几乎一模一样的直接对手

| 维度 | Mozaic Finance（自述） | Orion Finance（现状） |
|---|---|---|
| 聚合栈 | Plaid 银行 + SnapTrade 券商 | 相同 |
| 货币 | CAD 本位，每日汇率 | CAD/USD 显示切换 |
| 平台 | 网页 + iPhone | 仅 iPhone（SwiftUI） |
| 手动追踪 | 免费 | **刚刚移除** |
| 数据驻留 | Google Cloud 蒙特利尔，强调符合 PIPEDA 和 Law 25 | 未公开 |
| 价格 | C$99/年、C$12.99/月，14 天试用 | 待定 |
| 研究层（自选、新闻、Gurus、比较、模拟盘） | 未见 | 有 |
| AI | 未见 | 有 |
| 获客 | 发布大量面向加拿大 SEO 的对比文章 | 未知 |

Mozaic 的信息全部来自它自己的博客 ([Mozaic](https://mozaicfinance.com/blog/best-personal-finance-app-canada-2026/))，需要打折看待。它也指出，SnapTrade 在加拿大接不到 Scotia iTrade、National Bank Direct Brokerage、Qtrade 和 Disnat，RBC Direct Investing 只能经 Plaid 拿到余额和持仓。Orion 用的是同一套供应商，大概率继承同样的覆盖缺口。

结论是，Orion 不应该在“聚合”这条线上跟 Mozaic 硬碰。Mozaic 有网页版、有手动追踪、有数据驻留叙事，聚合本身是它的主场。Orion 要赢，靠的是 Mozaic 没做的“投资者层”，以及更低的价格。

### 平台风险：银行封堵 AI 代理、禁止屏幕抓取、券商限制接入

2026 年 10 月下旬，RBC 把第三方个人 AI 代理访问认证服务定性为“不可接受的客户风险”并予以封堵。TD 封堵所有需要认证的第三方个人 AI 代理，BMO 据报道不允许，Scotiabank 将加以限制，CIBC 不支持 ([MoneySense/CP](https://www.moneysense.ca/?p=377865)、[Global News](https://globalnews.ca/news/12124433/ai-agents-canadian-banks/))。这批封堵针对的是代用户登录的 AI 代理，**目前没有证据表明 Plaid 的 API 聚合受到影响**，但监管气候在收紧。

开放银行这边，《Consumer-Driven Banking Act》已于 2026 年 3 月 26 日获得御准 ([consumerdrivenbanking.ca](https://consumerdrivenbanking.ca/implementation-timeline/))，认证指引的征求意见期到 12 月 8 日 ([Bank of Canada](https://www.bankofcanada.ca/regulatory-oversight/consumer-driven-banking/))。投资账户排在数据范围的最后，初期仍允许屏幕抓取 ([Flinks](https://www.flinks.com/blog/open-banking-canada-2026-launch-fintech-institutions))。

这对 Orion 最直接的风险是：SnapTrade 的 Wealthsimple 连接是“需要密码/PIN 的定制集成”，不是 OAuth ([SnapTrade](https://snaptrade.com/brokerage-integrations/wealthsimple-api))。将来一旦禁止屏幕抓取，或 Wealthsimple 限制第三方接入，Orion 最核心的数据源就会受影响。笔记里没有找到 Wealthsimple 是否会限制 SnapTrade 类接入的任何信息。

### 监管和 App Store：“个性化推荐”是最大的雷

在加拿大，凡是“以就证券投资向任何人提供建议为业务”的，都需要在省级监管机构注册 ([Osler](https://www.osler.com/en/resources/cross-border/2013/giving-investment-advice-to-canadian-clients))。CSA Staff Notice 11-348（2024 年 12 月）确认现行证券法同样适用于 AI 系统，不提供新的豁免，并对“黑箱”AI 持保留态度 ([CSA/OSC](https://www.osc.ca/sites/default/files/2024-12/csa_20241205_11-348_artificial-intelligence-systems-capital-markets.pdf))。

Orion 现有的“按兴趣和风险画像个性化荐股”和“组合构建向导”，形式上非常接近“针对个人情况的买卖建议”。如果这些功能放在付费墙后面，“收取报酬”这一业务触发因素就更明显。这属于推断，不是法律意见，笔记也没找到专门针对未注册 AI 聊天机器人的 CSA 或 CIRO 指引，需要请加拿大证券律师确认。

App Store 方面有四条规则直接相关 ([App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/))：

| 条款 | 要求 | 对 Orion 的影响 |
|---|---|---|
| 5.1.1(ix) | 涉及金融服务或敏感信息的应用“应由法人主体提交，而非个人开发者” | 需要先注册公司，用组织身份的开发者账号提交 |
| 3.2.1(viii) | 交易、投资和理财应用应由提供该服务的持牌机构提交 | Orion 必须定位成只读追踪和教育工具，不能执行真实交易 |
| 5.1.2(i) | 把个人数据共享给第三方 AI 前必须明确披露并取得许可 | AI 助手需要单独的同意流程 |
| 4.7 | 开发者要对聊天机器人的输出合规负责 | AI 的回答内容由 Orion 担责 |

## 唯一没人占住的高地：跨账户的加拿大税务护栏

只有把多家机构的持仓放在一起，才能算对加拿大的几条规则，单一券商的应用在结构上做不到。

第一条是 ACB。非注册账户里的同一只证券，即使分散在不同券商，也共用一个平均成本，券商显示的“账面价值”并不是你的 ACB ([TraderSight](https://tradersight.pages.dev/blog/what-is-adjusted-cost-base-canada/))。

第二条是超额亏损规则（superficial loss），覆盖买卖前后共 **61 天**的窗口，也覆盖配偶，以及 TFSA 和 RRSP。在 TFSA 里买回会让这笔亏损实际上永久作废 ([TaxTips.ca](https://www.taxtips.ca/personaltax/investing/taxtreatment/superficial-losses-and-other-disallowed-losses.htm)、[MoneySense](https://www.moneysense.ca/columns/ask-moneysense/triggering-losses-by-transferring-investments-to-a-tfsa/))。

第三条是美股股息预扣税。RRSP 享受协定豁免，TFSA 被预扣的 **15% 无法收回**，在 TFSA 里持有“加拿大上市、内部再持有美国 ETF”的产品还可能被扣两层 ([Wealthsimple Help](https://help.wealthsimple.com/hc/en-ca/articles/360056584994-Non-resident-withholding-taxes-and-how-to-minimize-them)、[Motley Fool Canada](https://www.fool.ca/2026/10/15/your-tfsa-pays-15-tax-on-u-s-dividends-your-rrsp-doesnt/))。

第四条是 T1135。境外资产**成本**超过 C$100,000 就要申报 ([CRA](https://www.canada.ca/en/revenue-agency/services/tax/international-non-residents/information-been-moved/foreign-reporting/foreign-income-verification-statement.html))。Budget 2026 提议把门槛提高到 C$200,000，但尚未确认立法 ([Budget 2026](https://budget.canada.ca/2026/report-rapport/tm-mf-en.html))。

这些规则目前是零散地被服务的。adjustedcostbase.ca 只有网页版，T1135 助手放在付费档。AllInvestView 能跨 TFSA/RRSP 识别超额亏损，但界面偏工具化，也没有 AI。Wealthica 的 ACB 只在付费档提供。笔记没有找到任何一款移动优先的应用能实时做下面这种提醒：**“你在 Questrade 现金账户亏损卖出了 XEQT，但 12 天前你在 Wealthsimple TFSA 买过 XEQT，这笔亏损会被拒绝。”** 这正好接上排名第 8 的痛点，也让 AI 有了真正“基于你的数据”的话题。

需求规模也有支撑。加拿大 DIY 投资者中 **56% 已经在用 AI 处理投资相关任务**，但 **95% 的 Z 世代认为有理由质疑 AI 建议** ([Wealth Professional](https://www.wealthprofessional.ca/news/industry-news/finfluencers-and-ai-are-reshaping-how-canadian-diy-investors-make-decisions/393793))。也就是说，用户想要 AI，但要的是能核对、讲道理的 AI。2024 纳税年度约有 **146 万**加拿大人持有 FHSA ([BetterBooks](https://betterbookscanada.ca/fhsa-statistics-canada/))，笔记里没有任何产品被证实做了 FHSA 或 TFSA 额度追踪。

另外三个次要空白同样适合独立开发者：

1. **原生 iOS 的设计和隐私体验。** Fey 被收购后，Wealthica、AllInvestView 和 Sharesight 都偏工具风格。Orion 的隐藏金额模式、按机构拆分的图表和拖动查看，在笔记中没有看到竞品强调。
2. **“无风投、无推销、只读”的信任叙事。** HN 和论坛上对 Plaid 和风投 SaaS 的不信任是真实存在的。
3. **以 CAD 计价。** Monarch 至今仍按美元计费，对加拿大用户来说这是一个低成本的差异点。

需要说明的是，汇总 ACB 加上按交易日的 Bank of Canada 汇率很难做对，而 SnapTrade 能提供多完整的历史交易和成本价，笔记并没有验证。Monarch 的经验是自动连接只有约一半能拿到成本价。所以建议先做不依赖完整成本价的护栏，比如超额亏损窗口检测和预扣税估算，把完整 ACB 留到后面。

## 行动清单：先做合规和可靠性，再做税务护栏，把“荐股”改成“教育”

下表按“独立开发者能真正做完”的标准排序。工作量是基于功能复杂度的粗略判断，不来自笔记数据。

| 优先级 | 动作 | 理由与证据 | 估计工作量 |
|---|---|---|---|
| **P0 合规** | 注册公司，用组织身份的 Apple 开发者账号提交；App Store 描述写成“只读投资组合追踪与净资产仪表板 + 模拟交易（不下真实订单）”；SnapTrade 只申请只读权限，不开交易端点 | 规避 App Store 5.1.1(ix) 和 3.2.1(viii)；曾有审计专门指出某 SnapTrade 集成申请了不必要的交易权限 ([ClawHub](https://clawhub.ai/brendanwood/skills/snaptrade/security-audit)) | 低（以行政工作为主） |
| **P0 合规** | **改造“个性化推荐”**：去掉“按风险画像匹配个股”，改成规则透明的“主题和筛选探索”，例如“股息率高于 3% 的加拿大银行股”，并展示筛选条件；组合构建向导改成“模拟组合沙盒”，与模拟盘合并，不输出“适合你的配置”；AI 系统提示词拒绝给出具体证券的买卖建议，入门和聊天中都声明“非投资建议，未在任何证券监管机构或 CIRO 注册” | 规避注册风险，符合 CSA 11-348 对黑箱 AI 的态度；也符合用户“讨厌不透明预测”的反馈 | 中 |
| **P0 合规** | AI 首次使用时弹出单独同意，说明会把哪些数据发给哪家模型供应商；尽量只发汇总或去标识化的数据；隐私政策列出所有数据处理方；为魁北克用户准备 Law 25 隐私影响评估（PIA） | Apple 5.1.2(i)；Law 25 罚款最高 C$25M 或全球营业额的 4% ([McCarthy Tétrault](https://mccarthy.ca/en/insights/blogs/techlex/sweeping-privacy-reform-comes-force-quebec)) | 低到中 |
| **P0 可靠性** | 做“连接健康中心”：每个机构显示最后同步时间、过期标记、一键重新连接，出问题时净资产图标注“部分数据过期”，而不是悄悄显示错的数字 | 排名第 1 的痛点；用户在“全景图”断掉时退订 | 中 |
| **P0 可靠性** | **恢复一个轻量的手动兜底**：允许手动添加“只记余额”的账户（房产、养老金、SnapTrade 接不到的 Scotia iTrade、NBDB、Qtrade），以及 CSV 持仓导入；不必恢复完整的手动持仓编辑 | SnapTrade 的加拿大覆盖有缺口；屏幕抓取禁令和 Wealthsimple 接入风险需要对冲；Mozaic 和 Wealthsimple 都支持手动资产；免费档也可以借此不产生聚合成本 | 中 |
| **P1 差异化** | 推出“加拿大税务护栏”v1：每个账户打标签（TFSA / RRSP / FHSA / RESP / 非注册 / USD）；跨券商、跨账户的超额亏损 61 天窗口提醒；按账户类型估算美股预扣税泄漏；T1135 门槛监控，可在 $100k 和 $200k 之间切换。全部标注“估算，请咨询税务专业人士” | 这是第 4 节里唯一没人占住的高地；只有多账户聚合才做得到 | 中到高 |
| **P1 差异化** | 把 AI 助手 Orion 的上下文固定在“用户的跨机构持仓 + 税务护栏结果 + 新闻”上，每个回答都附数据来源；新增一条每日简报，回答“我的净资产今天为什么变了”，按机构、汇率、个股做归因 | 通用大模型和券商 AI 只看得到单一来源；用户信任“有出处、讲解型”的 AI | 中 |
| **P1 信任** | 一键导出 CSV（免费档也能用），一键删除账户和数据；首屏写明“只读 · 不存银行密码 · 不卖数据 · 没有理财顾问会给你打电话” | 对应排名第 6、7 的痛点；Wealthica 把导出放在付费档被当成缺点 | 低 |
| **P2** | TFSA、RRSP、FHSA 额度追踪：用户输入起始额度，App 根据已关联账户的入金自动扣减 | 有 146 万 FHSA 持有人；但 CRA 没有 API，罚则数据笔记也没有核实 | 中 |
| **P2** | iOS 小组件和锁屏净资产（配合隐藏金额模式）；家庭视图 | 发挥原生开发优势；Wealthsimple 已收购情侣应用 Plenty，说明家庭视图有需求 | 低到中 |
| **降级** | Gurus、新闻、个股比较、今日涨跌榜保留为免费的留存功能，不再投入大开发 | 13F 数据在 Dataroma 和 WhaleWisdom 免费；新闻已商品化 | — |
| **不做** | 记账和预算（分类、信封预算）；真实下单；Android | 那是 Monarch、YNAB、Copilot 的主场；下单会撞上 3.2.1(viii)；独立开发者的精力有限 | — |

背后的取舍逻辑是：Orion 现在的功能面太宽，每个功能都在和一个免费或者更强的对手竞争。把资源从“看起来像荐股 App”的功能（推荐、组合构建）挪到“只有多账户聚合才做得到”的功能（税务护栏、跨机构 AI 归因）上，既降低了监管风险，也做出了唯一性。

## 为什么要换到 Orion：按竞品类型拆解切换时刻

建议的一句话定位：**Orion 是给同时把钱放在 Wealthsimple、大银行和其他券商的加拿大投资者用的 iPhone 驾驶舱，用加元和美元看清全部身家，并由懂 TFSA、RRSP 和 CRA 规则、只讲解不推销的 AI 告诉你每一个变化意味着什么。**

切换的证据很一致：几乎都是事件驱动的。Mint 停服，Monarch 因此加速进入加拿大，很快获得约 3,500 名加拿大活跃用户 ([BetaKit](https://betakit.com/as-intuit-winds-down-mint-financial-planning-app-monarch-money-comes-to-canada/))。Wealthica 从免费转为付费，用户开始讨论电子表格和 Passiv。Kubera 涨价、Snowball 同步失败，也都直接引发了退订。因此 Orion 的获客要盯住这些“事件时刻”，话术要直接回应那个事件。

| 竞品类型 | 典型用户 | 切换触发点 | 给 Orion 的一句话话术 | 前提（Orion 必须先做到） |
|---|---|---|---|---|
| Monarch、YNAB、Simplifi（在加拿大用美国记账应用） | 从 Mint 迁过来的加拿大人 | CIBC、RBC 天天断开；CAD 和 USD 被直接相加；续费时觉得“不值 US$100” | “你要的是投资净资产，不是记账：CAD/USD 真换算，投资持仓看得到明细，价格以加元计，不到 Monarch 的一半。” | 连接健康中心；以 CAD 计价；如实说明银行连接同样依赖 Plaid |
| Copilot、Empower、Rocket Money（在加拿大用不了） | 看过美国测评、想用却下载不了的人 | 在加拿大 App Store 搜不到，或注册需要美国手机号 | “Copilot 级别的原生 iOS 体验，但从第一天起就为加拿大账户而做。” | 设计品质要达到这个水准；Wealthsimple 和 Questrade 开箱即连 |
| Wealthica | 老牌加拿大 DIY 投资者 | 转为付费后的价格档位；连接要频繁重新登录；网页为主 | “手机优先，C$69 拿到跨券商的超额亏损和 T1135 提醒，导出免费。” | 税务护栏 v1；免费导出。注意 Wealthica 的 ACB 报表更深，不要在完整 ACB 上正面竞争 |
| Mozaic Finance | 刚找到 Mozaic 的加拿大聚合用户 | 想要的不只是净资产数字，还想要研究和 AI | “同样的连接，再加一层投资者大脑：税务护栏、有出处的 AI、模拟盘，而且更便宜。” | 价格低于 C$99；研究层和 AI 质量要过硬 |
| Wealthsimple 自带净资产页 + Penny | 以 Wealthsimple 为主、另有银行或 Questrade 账户的用户 | 发现外部账户只显示余额、不自动刷新；Penny 看不到 Questrade 和 IBKR | “Penny 只懂 Wealthsimple，Orion 懂你所有的账户，包括 TFSA 在别家买回导致的超额亏损。” | 外部券商要有持仓明细，同步要稳定 |
| Snowball、Sharesight、Getquin、Delta | 全球追踪器的加拿大用户 | Wealthsimple 只能导入文件；拆分成 TFSA/RRSP/LIRA 后被迫升级；Delta 免费档收紧到 10 个资产 | “Wealthsimple 和 Questrade 直接同步，账户类型原生支持，不用每月导一次 CSV。” | SnapTrade 同步稳定；账户类型标签 |
| Seeking Alpha、Simply Wall St、Morningstar | 付费研究用户 | 每年 US$120–300，却不知道这些研究和自己的持仓有什么关系 | “研究直接接在你的真实持仓上：哪条新闻影响了你的哪个账户、影响多少。” | AI 归因和新闻与持仓的关联 |
| ChatGPT、Claude、Perplexity 和券商 MCP | 已经在用 AI 的技术型投资者 | 通用大模型的财务功能大多还只在美国；MCP 要逐个券商拼接，又不懂加拿大税务 | “一个地方连好所有加拿大账户，AI 懂 TFSA 预扣税和超额亏损，不用自己拼 MCP。” | 要赶在 2027 年 Wealthsimple 开放 ChatGPT/Claude 连接之前建立差异 |
| 电子表格 | 不信任聚合器、追求掌控感的用户 | 手动录入的负担终于压垮了表格；需要每月的汇率和快照 | “就是你那张表格，只是自动的：只读、可随时导出、可随时删除。” | 免费导出；隐私叙事；手动兜底 |

最后一点要诚实面对：对于资产几乎全在 Wealthsimple 的用户，Orion 不应该试图说服他们切换。笔记里的证据都表明，这部分人用 Wealthsimple 自带的功能就“够好了”。Orion 的目标客群是持有多家机构账户的人，并且应该在入门流程里直接问“你有几家机构”来筛选。

## 定价：约 C$69/年的单一付费档，免费档只放不产生聚合成本的功能

成本结构决定了免费档能放什么。SnapTrade 的正式价格是 **每月 US$100 基础费，再加每个连接用户每月 US$1（每日只读）或 US$2（实时）** ([SnapTrade](https://snaptrade.com/pricing))。Plaid 在加拿大的价格笔记没有查到，LLM 的成本也没有估算。

据此粗算：按年付 C$69（约 C$5.75/月）、每用户 SnapTrade 成本约 C$1.4/月（每日同步，按约 1.4 的汇率）计算，单靠 SnapTrade 一项，**大约要 30–40 个付费用户**才能覆盖基础费。这还没有扣除 Apple 佣金、Plaid 和 AI 的成本。因此**实时同步并不必要**，净资产场景用每日同步就够了。也正因如此，免费用户不应该拿到 SnapTrade 或 Plaid 连接。

| 档位 | 价格 | 内容 | 理由 |
|---|---|---|---|
| 免费 | C$0 | 自选与行情、涨跌榜、新闻、Gurus、个股比较、模拟盘和模拟组合沙盒、手动余额账户和 CSV 导入、导出；AI 每天 3–5 条 | 留存功能本身已商品化；不产生聚合成本；参照 Stock Events 免费档“每 24 小时 5 条 AI 消息”的做法 ([Stock Events](https://stockevents.app/pricing)) |
| Orion Plus | **C$7.99/月或 C$69/年**，试用 7–14 天 | SnapTrade 和 Plaid 不限机构同步、CAD/USD 历史净资产图、按机构拆分、加拿大税务护栏、每日 AI 净资产简报、更高的 AI 额度 | 低于 Mozaic 的 C$99 和 Monarch 的约 C$140，高于 adjustedcostbase.ca 的 $49，与 Wealthica 的 Connect/Unlimited 档（C$50–75）相当 |
| 早鸟年费（限时） | 首年 C$49 | 同 Plus | 用来积累第一批评论和口碑；这是事件驱动市场里常见的一次性促销 |

有四条配套原则。

1. **以 CAD 定价并在 App Store 显示加元**，这直接对比 Monarch 的美元计费。
2. **不提供终身买断**。笔记里确实有一批反订阅用户，但每个连接用户都有持续的成本，买断对独立开发者是负现金流。
3. **不要把“推荐”或“建议”当作付费卖点**。收费会强化“以建议为业务”的监管解读，付费理由应该落在“同步、税务护栏、额度”上。
4. RevenueCat 2026 年的数据显示，硬付费墙比免费增值模式转化更快，4 天及以下的短试用占比也在上升 ([RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2026/))。可以对“同步功能”用硬付费墙加短试用做 A/B 测试。不过这份报告没有金融类应用的分类数据。

## 证据缺口与可信度说明

**Reddit 完全无法访问。** reddit.com 和所有 Redlib 镜像都无法读取，r/PersonalFinanceCanada、r/CanadianInvestor、r/Wealthsimple 的帖子都没能直接阅读。少量 Reddit 内容只来自搜索结果的标题或元数据。用户痛点的排序因此是基于加拿大区 App Store、Trustpilot、加拿大论坛和 HN 的定性计数，不是频次统计。

**很多价格来自第三方，而且互相矛盾。** Simplifi 的价格来自搜索摘要，PocketSmith 的免费档、Monarch Plus 的 US$199.99、Seeking Alpha、Simply Wall St（$120、$131.40 和 €119.40 三种说法）、TipRanks（$99–359）、Koyfin、Ziggma、Kubera 的价格都来自第三方或互相冲突，用于决策前应到官网核实。Wealthica 的定价页没有标明币种，本报告默认是 CAD。

**大量加拿大对比文章出自竞品之手**，包括 Mozaic、Unified、Greenline、Waypoint、Richify、WealthWise 和 AllInvestView。它们对第三方的事实描述通常引用了官方帮助中心，但对自己的说法（例如 Mozaic 的 196 家机构、AllInvestView 的功能清单）是营销性质的。Monarch 的帮助中心拒绝直接抓取，部分内容经由搜索摘要和第三方转述。

**数据存在冲突。** Wealthsimple 的 AUA，Q2 官方数字是 C$155.6B，9 月 30 日的 C$169.2B 只见于媒体报道。Perplexity 是否支持加拿大，来源互相矛盾。Questrade MCP 支持哪些助手，各来源说法不一。开放银行法是“已获御准”还是“尚未生效”，表述也有出入。Copilot 是否在加拿大 App Store 上架，来源同样冲突。

**有几项关键事实没有验证：**

1. SnapTrade 对 Wealthsimple 和 Questrade 的成本价和历史交易完整度。这决定税务护栏能做多深。
2. SnapTrade 对 IBKR、TD、RBC DI、BMO InvestorLine 的实际覆盖。
3. Plaid 对加拿大独立开发者的定价和准入门槛。
4. Wealthsimple 是否会限制 SnapTrade 类的第三方接入。
5. 10 月的银行 AI 代理封堵是否波及 Plaid 连接。
6. CRA 关于 TFSA/FHSA/RRSP 超额供款罚则的原文。
7. 券商换汇费率。
8. 未注册 AI 应用在加拿大是否构成“advising”，需要证券律师判断。
9. CSA 在 11-348 之后有没有出台正式规则。
10. Penny 的全面上线时间（预计 2026 年底到 2027 年初）。
11. Robinhood 在加拿大的产品范围。

**市场数据不足。** 没有找到加拿大用户对净资产应用付费意愿的调查，也没有找到流失率或切换规模的数据、金融类订阅的转化率，以及 Wealthica、Mozaic 的付费用户数。Orion 自身的用户和留存数据不在研究范围内。

## 结论

这次研究改变的关键认识是：Orion 的护城河不在于“连得多”，而在于“算得懂”。聚合正在被三方同时商品化：Mozaic 的同构产品，Wealthsimple 和 Questrade 自己做的净资产页，以及通过 Plaid 和 MCP 直接读账户的通用大模型。连接的可靠性又受制于加拿大开放银行迟迟落地，这不是一个独立开发者能赢下的战场。真正结构性的优势在于，**加拿大税法本身就是跨账户的**：ACB 跨券商汇总，超额亏损窗口跨越 TFSA、RRSP 和配偶账户，预扣税因账户类型而不同。任何单一券商的 AI，哪怕像 Penny 那样能直接下单，都看不到全貌。Orion 的 AI 不该和它们比“会不会聊天”，而该比“能不能指出你在另一家券商里刚踩到的税务坑”。

第二个启示是，合规约束和产品差异化在这里指向同一个方向。把“按风险画像荐股”改成“规则透明的筛选和教育”，把组合构建改成模拟沙盒，既避开了加拿大的注册风险和 App Store 的审核风险，又正好贴合用户“信任讲解、不信任预测”的心态。窗口期很短：Wealthsimple 计划在 2027 年初开放 ChatGPT 和 Claude 连接，并推出新应用。Orion 最好在那之前，让“加拿大税务护栏 + 有出处的 AI”成为用户提起它时的第一印象。
