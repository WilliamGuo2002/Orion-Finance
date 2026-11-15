# 用减法为 Orion 换来高级与从容

Orion 的底子已经站在高级与从容这一边。暖米白 #F5F2EE、近黑暖棕 #2C2520、单一的焦糖色 accent，加上 New York 衬线标题，正好符合 Robinhood 2024 年改版、Wealthsimple 和中文「高级感」写作共同指向的配方：中性色，加一个签名色，再用衬线标题配精确的无衬线数据字。真正拉低观感、让人不安的是两类东西。一类是没有被执行的长尾：21 个字号、26 个 padding 值、约 24 种阴影配方、7 个永不停止的动画、61 处触感。另一类是一批破坏信任的缺陷：AI 同意页会自动弹出且无法下滑关闭，「添加自选」失败时没有任何提示，涨跌幅与昨收对不上，行情条还把 SPY/QQQ 的价格标成了指数。研究给出的方向很一致。视觉第一印象在约 50 毫秒内形成，起主导作用的是**视觉复杂度而不是色彩**（[Reinecke et al., CHI 2013](https://www.eecs.harvard.edu/~kgajos/papers/2013/reinecke13predicting.shtml)）。评价金融网站可信度时，**54.6%** 的用户评论提到了「外观」，在所有网站类别中最高（[ClickZ 报道 Fogg 等 2002](https://clickz.com/study-for-site-cred-looks-matter/56564/)）。安大略证券委员会（OSC）用加拿大投资者做的实验显示，积分奖励让交易次数增加 **39%**，「热门交易榜」让用户交易榜上股票的可能性提高 **14%**（[OSC 2022](https://www.osc.ca/en/news-events/news/osc-study-finds-gamification-techniques-influence-retail-investors)）。所以对一个面向加拿大用户、由个人开发者维护的产品，最划算的路线是分三步做减法，而不是换品牌。第一步，用约 5–7 个工作日清掉 P0 级缺陷和打扰，其中大多数是「小」工作量。第二步，把现有 token 收敛到一套，并接入 Dynamic Type 和对比度标准。第三步，精简首页和股票详情，把导航交给 iOS 26 的系统 TabView。做完这些，不需要新的视觉语言，Orion 就会显得更贵、更稳。

## 一句话结论：Orion 缺的是减法和执行，不是风格

**一句话结论：对 Orion 来说，高级感和从容感是同一件事。先删掉不该出现的东西（缺陷、占位、永动动画、光晕、多余入口），再把留下来的部分按同一套 token 一致地执行。** 下面五件事按投入产出排序，覆盖了审计中的绝大多数问题。编号（如 A1、M1）对应第六节的差距表。

| # | 要做的事 | 为什么（核心依据） | 优先级 · 工作量 |
|---|---|---|---|
| 1 | **修掉错误数字和静默失败**：涨跌幅改用昨收计算（A1），行情条不再把 ETF 标成指数（A3），收盘状态显示最后成交时间（A2），「添加自选」失败要有反馈（A4），下线所有占位内容（A7） | 金融用户最依赖「外观」判断可信度；Stanford 可信度指南要求「避免任何错误，不论多小」（[Stanford](https://credibility.stanford.edu/guidelines/index.html)）；好看只能让人原谅小问题，原谅不了大问题（[NN/g](https://www.nngroup.com/articles/aesthetic-usability-effect/)） | P0 · 小 |
| 2 | **不再不请自来地打断用户**：AI 同意页改为用户点 AI 卡片时才出现，可下滑关闭，并记住「暂不」（A5、A6） | Apple 要求等用户真正使用相关功能时再请求权限（[HIG Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)）；Calm Technology 主张弹窗只留给删除、紧急或用户主动选择的事（[calmtech.com](https://calmtech.com/)） | P0 · 中 |
| 3 | **让首页停下来**：行情条改为静止或由用户滑动，星座插画不再循环「呼吸」，脉冲点改为静态；所有动效接入「减弱动态效果」（M1–M3、M8） | WCAG 2.2.2（A 级）要求自动更新的股价必须可以暂停（[W3C](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)）；视野边缘的运动最抢注意力（[Bartram et al. 2003](https://www.interruptions.net/literature/Bartram-IJHCS03.pdf)） | P0 · 小（Reduce Motion 在 P1） |
| 4 | **修可读性，收敛 token**：secondaryText 从 #8A8078 改为 #706861；焦糖按钮的文字改为深色；21 个字号映射到 Dynamic Type 文字样式；padding 26 种收到 8 档；阴影约 24 种收到 2 种以内 | 低对比文字会降低信任，「也许时髦，但不可读」（[NN/g](https://www.nngroup.com/articles/low-contrast/)）；「Nothing must be arbitrary」（[Rams](https://www.vitsoe.com/us/about/good-design)） | P1 · 中到大 |
| 5 | **做减法，并把导航交给系统**：首页只留一个主角、一个 CTA；股票详情从「12 个模块 + 3 个广告位」收到约 8 个模块；改用系统 TabView；触感从 61 处收到约 12 处 | 「不要争夺你没有赢得的注意力」（[Linear](https://linear.app/now/behind-the-latest-design-refresh)）；FCA 把涨跌榜和红绿闪烁列为关注特征（[FCA 2022](https://www.fca.org.uk/publications/research-articles/gaming-trading-how-trading-apps-could-be-engaging-consumers-worse)）；「避免过度使用触感」（[HIG Haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)） | P2 · 中到大 |

**怎么读这份报告。** 每条结论都标注了依据类型。**【实证】** 指有实验、调查或监管研究数据支持的结论。**【Apple】** 指 HIG、WWDC 或开发者文档。**【标准】** 指 W3C/WCAG。**【社区】** 指设计师、从业者、书籍读书笔记、博客和媒体的观点，Rams 和 Refactoring UI 也归在这里。**【推断】** 是笔者把这些依据套用到 Orion 上的判断，没有直接来源。Orion 的现状证据全部来自代码与截图审计。代码位置是相对 `/Users/kuoihsuan2002/Desktop/prev/MyProject/Equion for iOS/Equion for iOS/` 的路径，文件名在项目里唯一，下文只写文件名和行号。截图在 `research_notes/Orion UI 高级感与从容感/screenshots/`（已压缩为 .jpg，文件名同 .png），原图是 iPhone 17 Pro 模拟器、访客账户下截取的 1206×2622 px 图。**注意截图文件名有误**：`03_home_top_light.png` 和 `04_home_top_dark.png` 实际是浅色和深色的「添加资产」sheet；`05_add_asset_sheet_light.png` 实际是没有 sheet 的访客首页；`06_home_after_add_light.png` 与 05 视觉上完全相同（添加后没有任何反馈）；`07` 单看截图无法证明是自动弹出，自动弹出由代码路径证实。下文一律按截图的实际内容称呼，比如「截图 05（访客首页）」。

## 高级感的原理：少而一致，复杂度比颜色更决定第一印象

经典设计文献对「高级」的解释几乎是同一个机制：**克制加上完成度**。Dieter Rams 的第十条原则是「尽可能少的设计」（Less, but better），第八条要求「细节上一丝不苟」，「Nothing must be arbitrary」（[Vitsœ](https://www.vitsoe.com/us/about/good-design)）【社区】。Refactoring UI 把这条原则落到界面层级上：「弱化次要信息和强调主要信息同样重要」，层级应主要靠字重和颜色建立，而不是靠放大（[Refactoring UI 读书笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)）【社区】。所以对一个数据密集的理财 App，最有力的单一杠杆是**去强调**：把标签、元数据、货币代码和日期在字重与颜色上往下压，让每屏只有一个数字明显占主导。

### 50 毫秒里，复杂度比颜色更重要

实证研究支持这条路线。Lindgaard 等人 2006 年发现，人们在 **50 毫秒**内就能完成对视觉吸引力的判断，而且这个判断与长时间浏览后的判断一致（[Nature news](https://www.nature.com/news/2006/060109/full/news060109-13.html)）【实证】。Reinecke 等人让 548 名志愿者对 450 个网站各看 500 毫秒后打分，发现色彩丰富度有影响，但「远不如整体视觉复杂度重要」，而且第一印象会延续到对可用性和可信度的判断上（[Harvard IIS](https://www.eecs.harvard.edu/~kgajos/papers/2013/reinecke13predicting.shtml)）【实证】。2014 年的后续研究收集了约 240 万次评分、近 4 万名参与者，发现**受教育程度越高，越不喜欢色彩多、结构复杂的页面**（[Reinecke & Gajos 2014](https://kgajos.seas.harvard.edu/papers/reinecke14visual.pdf)）【实证】。在金融领域这个效应被放大：Stanford 的可信度研究中，消费者评论里有 46.1% 提到设计或外观，金融网站达到 **54.6%**，为所有类别最高；但金融专家的评论里只有 16.4% 提到外观（[ClickZ](https://clickz.com/study-for-site-cred-looks-matter/56564/)）【实证】。这说明外观赢得第一印象，专家级的信任还要靠准确性、数据来源、时间戳和零错误。Stanford 指南第 6、9、10 条分别是「看起来专业」「克制推广内容」「避免任何错误」（[Stanford Guidelines](https://credibility.stanford.edu/guidelines/index.html)）【实证】。NN/g 的提醒也要记住：好看的设计能让用户原谅小的可用性问题，但「原谅不了大问题」（[NN/g](https://www.nngroup.com/articles/aesthetic-usability-effect/)）【实证】。这正是第一件事要先修缺陷、再谈美化的原因。

营销研究补充了三点信号。创意总监和普通消费者对白空间的含义有共同理解（[Pracejus et al., JCR 2006](https://ideas.repec.org/a/oup/jconrs/v33y2006i1p82-90.html)），创意总监明确用大面积白空间来传达品牌声望（[JBR 2012](https://econpapers.repec.org/RePEc:eee:jbrese:v:65:y:2012:i:6:p:855-860)），但白空间的含义因文化而异（[IJRM 2013](https://ideas.repec.org/a/eee/ijrema/v30y2013i3p211-218.html)）【实证】。奢侈品牌给标识更小、更「安静」的产品定更高的价（[Han, Nunes & Drèze 2010](https://acawiki.org/Signaling_Status_with_Luxury_Goods:_The_Role_of_Brand_Prominence)）【实证】。放到 UI 上就是不重复品牌、不放推广模块，用「缺席」表达自信。Zhou 等人的七项实验显示，**较低饱和度会提升品牌的地位感**，中介机制是「传承与延续」的联想；但对强调「新创」的品牌效应减弱，对定位为「创新」的品牌甚至反转（[ESCP 记录](https://libraries.escp.eu/doc/bth/192754203)，全文未读）【实证】。另外，高饱和度会提高唤醒度、抓取注意力（[Brasel & Hagtvedt](https://www.bc.edu/content/bc-web/bcnews/nation-world-society/business-and-management/color-and-consumer-perception.html)）【实证】。也有反例：2026 年一篇单刺激、期刊层级较低的研究发现高饱和度提升了奢侈感（[Bansal 2026](https://internationaljournalssrg.org/IJHSS/paper-details?Id=564)），权重应放低。对 Orion【推断】：米白、焦糖、衬线这套组合传达的是「私人银行式的传承与稳重」，而 Orion AI 又带着「科技前沿」的气质。两者都要的话，Zhou 的反转效应提醒我们必须选一个主定位。建议以「从容、稳重」为主，让 AI 以安静的工具身份出现，不做视觉主角。

### 可以直接使用的数值

下表的数值可以直接写进 token。iOS 字号以 Apple 文字样式为准，其余来自从业者经典。

| 变量 | 推荐值 | 来源与类型 |
|---|---|---|
| 字号 | 用 iOS 文字样式：Large Title 34/41、Title1 28/34、Title2 22/28、Title3 20/25、Headline 17/22 semibold、Body 17/22、Callout 16/21、Subhead 15/20、Footnote 13/18、Caption1 12/16、Caption2 11/13；默认 17pt，最小 11pt | 【Apple】[HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography) |
| 单屏字号数 | 信息层级 ≤5 级，对应字号 ≤5 个 | 【社区】[人人都是产品经理](https://www.woshipm.com/pd/4045552.html) |
| 字重 | 通常两种（Regular + Semibold）；避免在小字上用 Ultralight/Thin/Light | 【社区】[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)；【Apple】[HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography) |
| 行高与行长 | 正文行高为字号的 120–145%，大标题接近 1.0；行长 45–75 字符，66 最理想 | 【社区】[Butterick](https://practicaltypography.com/typography-in-ten-minutes.html)；[Bringhurst §2.1.2](http://webtypography.net/2.1.2) |
| 字距 | 大标题略收紧（读书笔记给出 −0.05em 为上限），全大写从 +0.05em 起；系统字体会按字号自动调整字距 | 【社区】[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)；【Apple】[WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/) |
| 间距刻度 | 4/8/12/16/24/32/48/64，相邻两档至少相差约 25%；组与组之间的距离大于组内距离 | 【社区】[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/) |
| 中性色与主色 | 8–10 级灰，不用纯黑；主色约 9 级明度；accent「少用」；在有色背景上用同色相的灰 | 【社区】[Refactoring UI 摘要](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/) |
| 文字对比 | 正文 ≥4.5:1；18pt 以上或粗体 ≥3:1 | 【标准】[WCAG 1.4.3](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)；【Apple】[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |
| 阴影 | 约 5 级「已经足够」；小：0 1 2 @5%；中：0 4 6 @7% + 0 2 4 @5%；大：0 10 15 @10% + 0 4 6 @5%；结构为一层大而柔的环境影加一层小而实的接触影 | 【社区】[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/) |
| 圆角 | 只用一个家族；0–4 显得正式，12–16 以上显得亲和；嵌套时内圆角 = 外圆角 − 内边距 | 【社区】[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)；【Apple】[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/) |
| 命中区 | 默认 44×44pt，最小 28×28pt | 【Apple】[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |
| 留白占比 | 视觉元素之间的留白约占版面 30–50%（日本市场设计语言实践） | 【社区】[站酷](https://www.zcool.com.cn/article/ZMTY3ODA2OA==.html) |

### 中文「高级感」配方与西方证据的三处冲突

中文设计写作把高级感归纳为「降低饱和度、压低明暗对比、柔化光影、增加留白，色调偏向暖灰、米白等大地色」（[人人都是产品经理 2026](https://www.woshipm.com/ai/6470787.html)），以及「克制、极致、独具风格」三个维度（[数英](https://www.digitaling.com/articles/315265.html)）【社区】。降饱和、多留白、少用颜色、追求细节、用留白替代分割线，这几条都能在 Rams、Refactoring UI 和上面的实证研究里找到对应。但有三处需要警惕，而且每一处都正好落在 Orion 身上。

**第一，「压对比」与 WCAG 和 NN/g 直接冲突。** NN/g 指出，设计师爱用浅灰字，是因为它符合极简风格，也适合想显得「高端、精英」的品牌；但低对比文字会造成眼疲劳、**降低信任**、在阳光下的手机上几乎无法阅读，对老花、白内障等低视力用户伤害尤其大（[NN/g](https://www.nngroup.com/articles/low-contrast/)）【实证/社区】。米白背景还会进一步拉低中灰字的对比度。Orion 的 secondaryText 在背景上只有 3.46:1，透明度变体更降到 1.6–2.4:1，正是这个陷阱。解决办法是只压**装饰性**对比（背景、阴影、边框、网格线），文字对比保持在标准以上；「安静」应该来自更少的内容和更多的留白，而不是更低的对比。**第二，暖色调有「发闷」的风险。** Linear 2026 年把灰色调改得更暖、更低饱和，同时明确警告「太暖会显得浑浊（muddy）」（[Linear](https://linear.app/now/behind-the-latest-design-refresh)）【社区】。中文作者也提醒「纹理过重显脏，留白过多显空，低饱和若压没主体则找不到重点」（[人人都是产品经理 2026](https://www.woshipm.com/ai/6470787.html)）【社区】。Orion 浅色卡片从白色渐变到 #F7F2ED，等于在米白上又加了一层米白，这正是浑浊感的来源（见 S4）。**第三，「独具风格」与「熟悉感」之间有张力。** 中文写作推崇独特性，而第一印象研究和金融场景的可信度研究更奖励熟悉、易读的结构。站酷一篇日本市场案例中，团队面对转化导向的 SaaS 网站，最终选了「信任优先」的蓝黄方案，放弃了「日式美学优先」的方案（[站酷](https://www.zcool.com.cn/article/ZMTY3ODA2OA==.html)）【社区】。【推断】Orion 的独特性应该放在字体、色彩和语气里，而不是放在自制导航和非标准交互里。这也是第五节建议改用系统 TabView 的原因之一。

## 从容感的原理：只提供、不索取，金融场景里尤其如此

从容感的核心是**注意力放在哪里**，不等于极简。Weiser 和 Brown 1995 年把注意力分为「中心」和「外围」：平静的技术让信息待在外围，只在重要时、并且由用户决定时才进入中心。面向实时信息流，他们的说法是好的设计「will offer, but not demand」（[Weiser & Brown](https://calmtech.com/papers/designing-calm-technology.html)）【社区】。Amber Case 的 Calm Technology 原则进一步要求：只占用最小限度的注意力；弹窗只用于删除重要内容、紧急情况或用户明确订阅的内容；数据失效时要退回一个仍可用的状态（[calmtech.com](https://calmtech.com/)）【社区】。

### 密度不是问题，没有秩序的密度才是

NN/g 主张把高级、少用的功能放到次级页面，并指出超过两层的渐进披露「通常可用性很低」（[NN/g Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/)）【实证/社区】。仪表盘应当「一眼可读」，颜色只用来强化已经通过其他方式传达的信息，因为约 8% 的男性和 0.5% 的女性有某种色觉缺陷（[NN/g Dashboards](https://www.nngroup.com/articles/dashboards-preattentive/)）【实证】。Matt Ström 指出，Bloomberg 终端的密集之所以可用，关键是「时间密度」，也就是数据几乎瞬间加载，而且它的用户是专家（[UI Density](https://mattstromawn.com/writing/ui-density)）【社区】。Bloomberg 的 CTO 也说，应对复杂度的秘诀是把它「对用户藏起来」（[Tech at Bloomberg](https://www.bloomberg.com/company/stories/how-bloomberg-terminal-ux-designers-conceal-complexity)）【社区】。UXmatters 2026 年的文章把平静定义为「没有空间上的混乱」：可预测的边距与列、共享的对齐线、组内紧组间松、各状态之间节奏一致；而互相竞争的布局系统、过度压缩和破坏心智地图的转场会摧毁平静（[UXmatters](https://www.uxmatters.com/mt/archives/2026/01/the-hidden-geometry-of-calm-screens.php)）【社区】。中文写作给出了同样的结构：留白分宏空间与微空间（[人人都是产品经理](https://www.woshipm.com/ucd/1049110.html)），克制分「颜色克制、信息克制、欲望克制」三层，好的界面像山水画，「需要为用户留下思考的空间」（[人人都是产品经理](https://www.woshipm.com/pd/5256416.html)）【社区】。

### 动效：100–300 毫秒、零回弹、不做永动

NN/g 给出的时长区间是 100–500 毫秒：开关、勾选等简单反馈约 100 毫秒，模态弹出这类实质性变化 200–300 毫秒；400 毫秒已经「很慢」，500 毫秒「开始拖沓」。入场应略长于退场，见得越频繁的动画越要短，「动画过长远比过短常见」（[NN/g](https://www.nngroup.com/articles/animation-duration/)）【实证/社区】。Apple 在 WWDC23 中说明：bounce 0 是平滑的临界阻尼，约 0.15「还不算有弹性，但更利落」，约 0.3 有明显弹性，超过约 0.4「对 UI 元素来说可能过于夸张」；「拿不准时就用 bounce 0」（[WWDC23 Animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/)）【Apple】。WWDC18 举的例子是 Music：点按展开用 100% 阻尼，带动量的下滑关闭才用 80% 阻尼（[WWDC18](https://developer.apple.com/videos/play/wwdc2018/803/)）【Apple】。HIG Motion 要求「不要为了动而动」，对频繁发生的交互「通常避免加动效」，并允许用户取消动效（[HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion)）【Apple】。永动内容的证据更硬。WCAG 2.2.2（A 级）规定：自动开始、持续超过 5 秒、并与其他内容同时出现的移动内容，必须可暂停、停止或隐藏；**自动更新的内容（原文明确包括股价更新）必须可暂停或可控制更新频率，而且没有 5 秒豁免**；恢复时应跳到最新数据，因为继续显示旧数据「会造成误导」（[W3C](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)）【标准】。NN/g 的测试中，5 秒自动轮播只有约 20% 的时间展示了关键信息，用户还会把会动的框当成广告（[NN/g Carousels](https://www.nngroup.com/articles/auto-forwarding/)）【实证】。Bartram 等人发现，运动的吸引力在视野边缘衰减得远比颜色和形状少（[Bartram et al. 2003](https://www.interruptions.net/literature/Bartram-IJHCS03.pdf)）【实证】。这正是屏幕顶部永动行情条的问题所在。

这里有一处需要调和的冲突：NN/g 认为 500 毫秒「开始拖沓」，而 SwiftUI 的 `.smooth`、`.snappy`、`.bouncy` 默认时长都是 0.5 秒（[Apple docs](https://developer.apple.com/documentation/swiftui/animation/smooth(duration:extrabounce:))）【Apple】。弹簧的 duration 是「感知时长」，与定时动画并不完全可比。【推断】实践上，原位变化建议取 0.3–0.4 秒，0.5 秒只作页面级动画的上限。据此建议 Orion 采用以下动效 token【推断】：

| Token | 值 | 用途 | 依据 |
|---|---|---|---|
| `Motion.tap` | `.snappy(duration: 0.2)` | 按下态、选中、开关 | 简单反馈约 100–200ms；snappy 的基础 bounce 为 0.15 |
| `Motion.standard` | `.smooth(duration: 0.35)` | 原位状态变化、展开与收起 | 实质性变化 200–300ms；bounce 0 |
| `Motion.screen` | 入场 `.smooth(duration: 0.45)`，退场 0.3 | sheet、整页切换 | 入场略长于退场；0.5 为上限 |
| `Motion.number` | `.smooth(duration: 0.3)` + `.contentTransition(.numericText(value:))` | 价格、净资产变化（需节流） | 不用弹跳，不做红绿闪烁 |
| `Motion.gesture` | `.spring(duration: 0.4, bounce: 0.1)` | 带动量的手势松手 | WWDC18：只有带动量的手势才用约 80% 阻尼 |
| Reduce Motion 回退 | `.easeInOut(duration: 0.2)`，只改透明度 | 全部 | [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |

### 金融场景：红色、频繁查看和游戏化都会改变投资行为

在钱的问题上，「不安」会变成真实的行为改变，而且相关证据就是在加拿大测得的。OSC 与英国行为洞察团队（BIT）2022 年用 1 万美元模拟资金做实验：获得积分（没有任何经济价值）的用户交易次数多了 **39%**，看到「热门交易」榜的用户交易这些股票的可能性高 **14%**（[OSC 2022](https://www.osc.ca/en/news-events/news/osc-study-finds-gamification-techniques-influence-retail-investors)）【实证】。2024 年 2,430 人的随机对照试验中，社交信息流里推广的股票使交易增加约 12%（另一份二手摘要写作 11%，两处数字不一致），跟单交易使被推广股票的交易增加约 18%（[OSC Gamification Revisited](https://osc.ca/en/gamification-revisited-new-experimental-findings-retail-investing)）【实证】。OSC 2026 年对 4,000 多名加拿大人的模拟研究也发现，引导良性行为的「正向游戏化」能把分散化提高 3.5–4.5%，效果温和（[Wealth Professional](https://www.wealthprofessional.ca/news/industry-news/osc-research-finds-gamification-can-support-better-investor-decisions/391530)）【实证】。英国 FCA 2022 年列出的关注特征包括庆祝动画与彩带、积分徽章排行榜、频繁推送、**红绿闪烁的实时价格列表**和**24 小时涨跌榜**（[FCA 2022](https://www.fca.org.uk/publications/research-articles/gaming-trading-how-trading-apps-could-be-engaging-consumers-worse)）。FCA 2024 年在自建的交易 App 中对 9,000 多人做实验，推送使交易增加 **11%**，积分抽奖使交易增加 **12%**，高风险交易的占比分别上升 8% 和 6%（[FCA 2024](https://www.fca.org.uk/publications/research-notes/research-note-digital-engagement-practices-trading-apps-experiment)）【实证】。Robinhood 的彩带动画被马萨诸塞州监管方点名后于 2021 年下线（[CNBC](https://www.cnbc.com/2021/03/31/robinhood-gets-rid-of-confetti-feature-amid-scrutiny-over-gamification.html)）；美国 SEC 2023 年针对「数字互动实践」的规则提案已于 2025 年 6 月撤回，目前没有专门规则生效（[Proskauer](https://www.proskauer.com/alert/sec-withdraws-fourteen-rule-proposals)）【实证】。

行为金融学的结论指向同一方向。8 项实验、1,451 名参与者显示，用红色而非黑色呈现财务数据会使风险承担降低 **15–30%**，并延长负收益后的悲观预期。这个效应在色盲参与者中消失，在中国（红色象征兴旺）则减弱（[Bazley, Cronqvist & Mormann 2021](https://econpapers.repec.org/RePEc:inm:ormnsc:v:67:y:2021:i:9:p:5616-5641)）【实证】。查看收益越频繁，人越厌恶风险，即「短视损失厌恶」（[Gneezy & Potters 1997](https://Rady.ucsd.edu/_files/faculty-research/uri-gneezy/risk-taking.pdf)）；看到 30 年收益分布而非 1 年收益时，人们会配置更多股票（[Benartzi & Thaler 1999](https://econpapers.repec.org/RePEc:inm:ormnsc:v:45:y:1999:i:3:p:364-381)），不过部分复现结果不一【实证】。行为相反的证据也存在：市场下跌后退休账户登录减少 9.5%（[Sicherman et al.](https://business.columbia.edu/sites/default/files-efs/pubfiles/25997/sicherman_financial_attention.pdf)），而活跃的在线交易者在涨跌两种日子里都会更频繁地查看（「猫鼬效应」，[Gherzi et al. 2014](https://econpapers.repec.org/RePEc:eee:jeborg:v:107:y:2014:i:pb:p:512-526)）【实证】。产品侧，Zerodha 2024 年加入隐私模式，理由是「持续看到实时盈亏变化容易分心，还可能诱使你过度交易」（[Zerodha](https://zerodha.com/z-connect/?p=387662)）；Trading 212 有用户抱怨隐私模式在重启后不保留（[Trading 212 社区](https://community.trading212.com/t/introducing-privacy-mode/91187)）；加拿大的 Wealthsimple 则把它的投资 App 形容为刻意「无聊」（[Wealth Professional](https://www.wealthprofessional.ca/news/features/what-wealthsimple-thinks-of-robinhood/331239)）【社区】。需要说明的是，目前没有找到主流 App 公开「隐藏当日涨跌」或「默认更长区间」的 A/B 数据，上述证据来自实验室和行为金融研究。【推断】对 Orion 来说，这些研究指向几件事：首页的「Hot」火焰榜和 Gainers/Losers 正是监管点名的那类列表；下跌日顶部永动的红色行情条，同时叠加了运动、红色和高频查看三种效应；净资产图的默认区间、当日涨跌的视觉权重，以及「隐藏金额」是否持久化，都是从容感的直接杠杆。

### 文案、打断、加载与触感的从容标准

Apple 写作指南明确说「银行 App 的措辞应传达信任与稳定」，错误提示要放在问题附近、不归咎于用户、说明如何解决，「oops」一类感叹词「通常没有必要，听起来也不真诚」；空状态应引导用户的下一步（[HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)）【Apple】。Monzo 要求不使用未解释的金融术语，涉及钱的担忧时不开玩笑，确实是自己的错时只说一次「对不起」，然后专注于解决（[Monzo Tone of voice](https://monzo.com/tone-of-voice)）【社区】。打断方面，HIG 要求「谨慎使用警告框」，避免在 App 启动时弹警告框，改为显示缓存或占位数据，加一个不打扰的标签（[HIG Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)）；只在功能真正需要时请求权限，避免启动即请求（[HIG Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)）；通知要如实反映紧急程度，「绝不」把 Time Sensitive 级别用于营销（[HIG Notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)）；引导流程应当「快速、有趣、可选」，优先用 TipKit 做情境提示（[HIG Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)）【Apple】。加载方面，0.1 秒感觉即时，1 秒不打断思路，10 秒是注意力的极限（[NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/)）；不到 1 秒的加载不需要骨架屏，不到 10 秒的整页加载用与最终版式一致的占位，骨架动画是可选的且「可能分散注意力」（[NN/g Skeleton](https://www.nngroup.com/articles/skeleton-screens/)）【实证/社区】；布局偏移 CLS ≤0.1 为良好（[web.dev](https://web.dev/articles/cls)）【标准/社区】。触感方面，Apple 的原话是「避免过度使用触感」，最好的触感是「人们意识不到、但关掉后会怀念」，每个触感都要和触发它的操作有清晰的因果关系，并且可以关闭（[HIG Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)）【Apple】。

## 优秀产品的共性：Robinhood、Linear、Copilot、Wealthsimple 都在公开做减法

文档最充分的几个范例有几个共同动作：把克制写成明文原则，用中性色加一个签名色，标题用衬线、数据用精确的无衬线体，用变暗和留白代替线框建立层级。Robinhood 2024 年由 PORTO ROCHA 主导改版，标题用 Klim 的衬线体 Martina Plantijn（「温暖而智性」），数据和 UI 用为「精确」而选的 Phonic 无衬线体；配色是「黑、白与成熟的中性色」加一抹 Robin Neon，刻意避开竞品的「彩虹」调色板，口号是「less is more」（[PORTO ROCHA](https://www.portorocha.com/robinhood)）【社区】。Linear 2026 年 3 月的刷新把原则写成两句话：「Don't compete for attention you haven't earned」和「Structure should be felt not seen」。具体做法是导航侧栏调暗「几档」，减少分隔线并降低其对比，减少图标并缩小尺寸，去掉彩色图标底，把冷灰换成更暖、更低饱和的灰，同时提醒过暖会「浑浊」（[Linear](https://linear.app/now/behind-the-latest-design-refresh)）【社区】。Copilot Money 入围 2024 年 Apple 设计奖，创始人强调 App「完全原生」、「对设计很挑剔」，第一个 SwiftUI 功能用 Swift Charts 实现，团队 28 人（[Apple Developer](https://developer.apple.com/articles/copilot-money/)）【社区】。加拿大本土的 Wealthsimple 曾用 Caslon 与 Futura「传达资金的安全感」（[Wealthsimple Magazine](https://www.wealthsimple.com/en-ca/magazine/new-wealthsimple-15)），2025 年收购 Fey 后，据媒体报道正在用 UIKit 重建将于 2027 年初推出的新 App，重点打磨手势（[iPhone in Canada](https://www.iphoneincanada.ca/2026/11/05/wealthsimple-fey-uikit-trading-app-sneak-peek/)）【社区】。Monzo 2023 年重做首页时，早期方案在测试中被认为「令人不知所措、困惑」，最后加入了首页自定义（[Monzo](https://www.monzo.com/blog/how-we-built-the-new-home-screen)）。Monzo 2022 年改版后，有用户嫌新字体的数字「对银行来说太俏皮」（[Monzo Community](https://community.monzo.com/t/new-font/142936)）【社区】。

| 模式 | 例证 | 对 Orion 意味着什么【推断】 |
|---|---|---|
| 把克制写成原则 | Linear「Don't compete for attention you haven't earned」；Robinhood「less is more」；HIG「抵制把尽可能多的数据塞进图表」（[HIG Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data)） | 每加一个模块先问「它赢得注意力了吗」；股票详情和首页都要减（H1、H4） |
| 中性色 + 一个签名色 | Robinhood 中性色 + Robin Neon；Monzo 珊瑚色卡；Linear 低饱和暖灰 | 米白 + 焦糖已经符合；真正的问题是系统橙、蓝、紫的泄漏（C6） |
| 衬线标题 + 精确的无衬线数据 | Robinhood Martina Plantijn + Phonic；Wealthsimple Caslon + Futura | 保留 New York 标题；数字从 SF Mono 改为 SF Pro 等宽数字（T3）；大额数字不要用衬线 |
| 用变暗和留白建立层级 | Linear 调暗侧栏、减少分隔线和图标 | 去掉模块标题的竖条与图标、渐变分割线（T6） |
| 渐进披露、图表简单 | HIG；Fey 从简单筛选到高级指标（[Artisan Apps](https://artisan-apps.beehiiv.com/p/fey-where-bloomberg-meets-apple-s-design)） | 关键数据合并，「全部指标」放进 sheet（H4） |
| 图表颜色由区间决定 | Robinhood：区间末收盘高于首收盘为绿、反之为红，基线图用水平实线分隔（[Robinhood Help](https://robinhood.com/us/en/support/articles/using-charts/)）；HIG：涨跌色的含义因地区而异（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)） | 线色按所选区间计算，1D 加昨收基线（H6）；P3 提供涨跌配色设置 |
| 原生工艺 | Copilot「完全原生」；Wealthsimple/Fey 在 UIKit 上重做手势 | 个人开发者靠系统组件获得原生感，不去复刻自定义材质（S5） |

反模式同样清楚：实时红绿闪烁被 Bloomberg 放在「游戏化交易」的批评框架里讨论（[Bloomberg 2021](https://www.bloomberg.com/features/2021-robinhood-stock-trading-design)）；带个性的品牌字体用在数字上显得「俏皮」；首页堆满模块会「令人不知所措」；暖色调过头会「浑浊」【社区】。还有两点需要提醒。第一，Copilot 的 #000814 等色值和 Fey 的视觉规格来自第三方取样网站，未经核实。第二，Apple Card/Wallet、Revolut、Monarch、Things 3 等本应纳入的范例在本次研究中未覆盖，不能据此下结论。【推断】Copilot 用 28 人做到「完全原生的定制」，个人开发者不可能在定制工艺上与之比拼。Orion 的杠杆在于让系统组件承担导航和材质，把有限的精力花在数字、字体和文案这三处最能体现品味的地方。

## iOS 26 落地要点：内容层安静，导航层交给系统

iOS 26 的分工很明确。Liquid Glass 只属于漂浮在内容之上的导航与控件层，**「不要在内容层使用 Liquid Glass」**，内容层继续用标准材质；玻璃效果要「节制使用」，不要玻璃叠玻璃（[HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)、[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)）【Apple】。层级应「通过布局与分组表达，而不是依赖装饰」（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)）；装饰性颜色放在内容层，因为「当每个元素都被着色，就没有东西突出」（[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)）【Apple】。系统玻璃会自动适配「减弱透明度」「增强对比度」「减弱动态效果」，自定义材质和控件则不会（[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)）【Apple】。媒体报道 iOS 27 加入了用户可调的玻璃透明度滑杆，标准组件会自动跟随（[TweakTown](https://www.tweaktown.com/news/112090/apple-is-adding-a-liquid-glass-slider-in-ios-27-after-a-year-of-user-complaints-about-readability/index.html)）【社区，细节未核实】。【推断】这又是一个改用系统组件的理由：Orion 自制的 `.ultraThinMaterial` tab bar 不会跟随这个设置。

| 主题 | Apple 的规则 | SwiftUI 落地 | 备注 |
|---|---|---|---|
| 文字样式 | 使用内建文字样式，自动获得 Dynamic Type、光学尺寸和字距；放大至少支持 200%；避免细字重（[HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)） | `.font(.system(.title, design: .serif, weight: .semibold))`；自定义字体用 `.custom(name, size:, relativeTo:)`；常量用 `@ScaledMetric(relativeTo: .body)`（[WWDC20](https://developer.apple.com/videos/play/wwdc2020/10175/)） | Orion 的衬线已经是 New York，换成文字样式即可自动获得光学尺寸和字距 |
| 数字 | 内容过渡只在动画上下文中生效（[ContentTransition](https://developer.apple.com/documentation/swiftui/contenttransition)） | `.monospacedDigit()` + `.contentTransition(.numericText(value:))`【社区】（[Michael Tsai](https://mjtsai.com/blog/2022/09/28/monospaced-digits-in-swiftui)） | 论坛报告高频触发 numericText 时 CPU 偏高（[Forums 733047](https://developer.apple.com/forums/thread/733047)），需要节流 |
| 命中区与间距 | 默认 44×44pt、最小 28×28pt；有边框元素周围约 12pt 留白，无边框约 24pt；间距保持一致（[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)、[HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)） | `.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())` | HIG 没有给出 iOS 屏幕边距的数值；16/20pt 是 UIKit 惯例，未核实 |
| 形状 | 三类形状：固定、胶囊、同心；同心形状的半径 = 父形状半径 − 内边距；不匹配的嵌套圆角会显得「捏紧或外翻」（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)） | `ConcentricRectangle()` + `.containerShape(.rect(cornerRadius: 18))`（iOS 26）（[Apple docs](https://developer.apple.com/documentation/swiftui/concentricrectangle)）；卡片用 `isUniform: true`（[Nil Coalescing](https://nilcoalescing.com/blog/ConcentricRectangleInSwiftUI)，社区） | 若部署目标低于 iOS 26，用 `if #available(iOS 26, *)` 包裹，回退时手算半径 |
| 颜色 | 节制用色；Liquid Glass 上只给主操作着色；即使只支持一种外观，也要同时提供浅色和深色色值（[HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)） | 资产目录的语义 token | 不要用透明度充当色阶 |
| 材质 | 玻璃只用在导航层，最重要的控件才用；内容层用标准材质（[HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)） | `glassEffect(_:in:)`、`GlassEffectContainer(spacing:)`、`.buttonStyle(.glass)`（[Applying Liquid Glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)） | `.glassProminent`、`scrollEdgeEffectStyle` 等 API 名未核实 |
| Tab bar | 系统 tab bar 浮于内容之上，提供滚动最小化、搜索 tab、底部附件槽；tab 只做导航，不放操作；用实心 SF Symbols（[HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)） | `TabView { Tab(...) }.tabBarMinimizeBehavior(.onScrollDown)`；`tabViewBottomAccessory`（[Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)，社区） | 内容要足够长才会最小化；已知问题见 S5 |
| Sheet 与警告框 | 模态玻璃要配暗化层；警告框和引导页的文字更粗、左对齐（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)） | 系统 `.sheet` + `.presentationDetents`、`.alert`、`.confirmationDialog` | 不要自绘遮罩 |
| 深度与阴影 | 层级靠布局和分组；阴影属于玻璃层，由系统动态调节（[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)） | 分组背景 + 卡片填充 | Apple 没有给卡片阴影数值，下文数值为设计惯例 |
| 图表 | 保持简单，多张图风格一致；可交互的图用更少、更淡的网格线；整个绘图区都可拖动；每张图都要可访问（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)） | `chartXSelection`、`RuleMark`、`.chartYScale(domain:)`；Swift Charts 默认提供 Audio Graphs | 用「June 6」这类无歧义日期格式，而不是「6/6」 |
| SF Symbols | 九种字重与 SF 字重一一对应，用 scale 调整强调程度；符号动画要克制（[HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)） | `.imageScale(.small)`、`.symbolRenderingMode(.hierarchical)`；不要用 `.resizable().frame()` 缩放符号 | 同一含义始终用同一个符号 |
| 触感 | 少用、一致、有因果、可关闭；标准控件已经自带触感（[HIG Haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)） | `.sensoryFeedback(.selection/.success/.error, trigger:)`（[SensoryFeedback](https://developer.apple.com/documentation/swiftui/sensoryfeedback)） | 把触感绑定到状态变化，不在每个按钮动作里手动调用 |
| 弹簧 | `.smooth` bounce 0、`.snappy` 0.15、`.bouncy` 0.3，默认时长 0.5；超过 0.4 过于夸张（[Apple docs](https://developer.apple.com/documentation/swiftui/animation/bouncy(duration:extrabounce:))、[WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)） | 第三节的 5 个 Motion token | NN/g 认为 500ms 已经拖沓，见第三节 |
| 减弱动态效果与透明度 | 减少自动、重复和外围的运动；用淡入淡出代替位移；避免动画进入或退出模糊（[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)） | `@Environment(\.accessibilityReduceMotion)`、`@Environment(\.accessibilityReduceTransparency)` | 系统玻璃会自动适配，自制材质不会 |

## 差距分析：问题集中在长尾与缺陷，而不在底色

先说 Orion 做对的部分，它们决定了改进方向是「收敛」而不是「推倒」。审计显示 token 本身成体系：深色背景 #1C1916 是带暖色调的近黑，符合范例中「不用纯黑」的共识。Gurus（截图 13）和 More（截图 14、15）是全 App 最安静、最一致的两页，可以作为内部的密度参照。AI 同意页的文案本身清晰克制。已经有多处「not a recommendation」免责声明，价格目标被刻意用 `if false` 关闭（StockDetailView.swift:829-830）。净资产图表的 6 色分类调色板已经做过色盲验证（NetWorthChartModule.swift:5-23）。「隐藏金额」按钮已经存在。审计的总判断是「设计系统开了头，但从未被执行」：`accentDark`、`cardShadow()`、`BubbleShape`、`StaggeredItem` 都定义了却没有使用，动效 token 只在 AppTheme 内部被引用。下面七张表按「现状证据 → 依据 → 建议改法」逐项列出差距。「建议改法」一栏本身是笔者的方案：除非另外注明了来源，其中的具体数值和组件命名都属于【推断】；而「依据」一栏的标签，说明的是这条建议背后那条原则的来源类型。

### 信任与正确性：错误的数字比难看的卡片更伤高级感

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| A1 涨跌幅算错 | 股票详情 hero 显示 NVDA「-2.59 (-1.57%)」，首页 Today's Market 显示 -2.01%；按 Key Data 的现价 $162.85 与昨收 $166.19 应为 -3.34 / -2.01%。原因是 hero 用「最后价 − 图表第一根 K 线」计算（StockDetailView.swift:61-67, 1407-1408；截图 08、截图 05 访客首页、截图 10） | 【实证】Stanford #10「避免任何错误」（[Stanford](https://credibility.stanford.edu/guidelines/index.html)）；金融专家更看重准确性（[ClickZ](https://clickz.com/study-for-site-cred-looks-matter/56564/)） | 统一按 `previousClose` 计算：`change = last − previousClose`，`pct = change / previousClose`。抽成一个共享函数，首页、详情、行情条共用，并用截图中的 162.85 / 166.19 写单元测试（期望 −3.34 / −2.01%） |
| A2 收盘状态显示「现在」的时间 | 「Closed · 11/15 9:05 AM ET」由 `Date()` 生成，周日看起来像存在周日早盘价（StockDetailView.swift:93-105；截图 08） | 【Apple】使用无歧义的日期格式（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)）；【实证】Stanford #10 | 用报价中的最后成交时间，并显式设置 `America/New_York` 时区，例如显示「Closed · Fri, Nov 13, 4:00 PM ET」 |
| A3 ETF 冒充指数 | 行情条的「S&P 500 754.37」「NASDAQ 679.89」其实是 SPY、QQQ，「Dow Jones」是 DIA（MyHoldingView.swift:507；截图 05 访客首页） | 【社区】Rams「诚实：不夸大自身价值」（[Vitsœ](https://www.vitsoe.com/us/about/good-design)）；【实证】Stanford #10 | 标签改为「SPY」「QQQ」「DIA」，并加小字「ETF」；或者接入真实指数数据源。宁可少显示，不要错标 |
| A4 添加自选静默失败 | sheet 在网络请求发出前就关闭；失败时只有 `Haptic.error()` 和 `print`；重复添加直接 return（MyHoldingView.swift:183-186, 592, 606-608）。同类公司卡片的「Add」同样没有反馈（StockDetailView.swift:619-635）。截图 06 与截图 05 完全相同 | 【Apple】错误提示放在问题附近，并说明如何修复（[HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)）；【推断】乐观更新，失败时原位回滚 | 乐观插入新行（立即出现）；失败时回滚，并在列表顶部显示一行 `.footnote`「未能添加 NVDA · 重试」，不用红色横幅，同时触发 `.sensoryFeedback(.error, trigger:)`；重复添加时显示「已在自选中」；同类公司卡片的 Add 成功后变为 `checkmark` |
| A5 AI 同意页自动弹出并反复出现 | 打开任意股票详情会依次触发 `loadAllModules()` → `loadAIDashboard()` → `AIConsent.shared.ensure()`，以 large 尺寸的 pageSheet 呈现，并设置了 `isModalInPresentation = true`，无法下滑关闭。「Not now」只保存 `granted=false`，所以下次进入、以及每次点 Fundamentals 指标都会再次弹出（StockDetailView.swift:147-151, 1082, 1735, 1768-1785；APIService.swift:995-1007；AIConsent.swift:35-67；截图 07） | 【Apple】「最好等人们真正使用需要该权限的功能时再请求」（[HIG Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)）；【社区】弹窗只留给删除、紧急或用户主动订阅的内容（[calmtech.com](https://calmtech.com/)） | 从加载链路中移除 `ensure()`。未同意时，AI 卡片显示一行说明和「开启 AI 研究摘要」按钮，点按后才弹出同意页。同意页设置 `isModalInPresentation = false`，detents 设为 `[.medium(), .large()]`。新增 `declinedAt` 记录，用户选「Not now」后不再自动询问。未同意时，点 Fundamentals 指标只显示静态释义，不调用 Gemini。同意页文案保持不变 |
| A6 AI 卡片为空 | 拒绝同意或调用失败后，「AI Research Snapshot」仍然渲染出标题、分割线和一片空白（StockDetailView.swift:791-1017, 1782-1784；截图 08、09） | 【Apple】出错时显示缓存或占位数据，加一个不打扰的标签（[HIG Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)） | 给模块一个四态枚举：`.loading`、`.loaded`、`.needsConsent`、`.failed`。失败态显示「暂时无法生成摘要 · 重试」，不渲染空卡 |
| A7 占位内容上了线 | Options Activity 是占位网格，配文「Options data requires a premium data subscription.」（StockDetailView.swift:532-579）；Volume 写死为「—」（343, 444-448）；「Ad」灰盒在详情页有 3 个，新闻每 5 条出现 1 个（AdManager.swift:3-23；StockDetailView.swift:240, 251, 262；NewsView.swift:103-106）；加载时 32pt 价格位显示单词「Loading...」（StockDetailView.swift:118-120）（截图 10、11、12） | 【实证】Stanford #9「克制推广内容」；【实证】安静的品牌溢价更高（[Han et al.](https://acawiki.org/Signaling_Status_with_Luxury_Goods:_The_Role_of_Brand_Prominence)）；【社区】「没有细节的高级，都是虚伪的」（[数英](https://www.digitaling.com/articles/315265.html)） | 在有真实内容之前，删除 Options 模块和全部 Ad 占位。【推断】如果将来上广告，每屏最多 1 个，放在首屏以下。没有成交量数据就隐藏该行。价格位改用 `.redacted(reason: .placeholder)`，或显示上次缓存的价格加「截至」时间 |
| A8 问候与市场状态矛盾 | 周日首页同时出现「Ready for a new trading day?」和「Markets are closed today — enjoy your Sunday」。副标题按小时段随机抽取，不考虑周末和假日（AppTheme.swift:183-213, 314-331；MyHoldingView.swift:31, 113, 123-137；截图 05 访客首页） | 【Apple】银行 App 的措辞应「传达信任与稳定」（[HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)）；【社区】不制造紧迫感（[Monzo](https://monzo.com/tone-of-voice)） | 只保留一行问候和一行市场状态，两者由同一个交易日历函数生成。删除「Ready for a new trading day?」「Markets are moving — stay informed」等以交易为导向的文案 |
| A9 问卷图标显示为「?」方块 | 选项图标是 28pt 的 emoji `Text`，截图中渲染成缺字方块，图标后还留出约 129pt 空白（RiskProfileView.swift:44-86, 264-265；截图 01、01b、01c） | 【社区】只用一套图标库、一种描边风格（[Kole Jain 视频笔记](https://sozai.app/transcript/ui-ux-mistakes-beginner/index.md)）；【推断】即使在真机上能显示（审计未在真机复现），emoji 也与衬线加焦糖的语气不符 | 换成 SF Symbols，使用 `.symbolRenderingMode(.hierarchical)`、accent 色、`.font(.title3)`；或者干脆去掉图标，让文字按 16pt 内边距左对齐 |
| A10 问卷转场叠影与跳动 | 换题时在 `withAnimation` 中修改 `currentPage`，但视图身份不变，新旧题目、图标和选项叠在一起（截图 01c）。第 1 题顶部有 80pt 的图标区，第 2 题没有，整体上跳约 175pt（RiskProfileView.swift:117-124, 143-163, 208-231；截图 01 对比 01b） | 【Apple】「东西从哪里消失，就应该从哪里出现」（[WWDC18](https://developer.apple.com/videos/play/wwdc2018/803/)）；【社区】破坏心智地图的转场会摧毁平静（[UXmatters](https://www.uxmatters.com/mt/archives/2026/01/the-hidden-geometry-of-calm-screens.php)） | 内容容器加 `.id(currentPage)` 和 `.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))`，减弱动态效果时只用 `.opacity`。进度条固定在顶部，头部区域在所有题目中保持同一高度 |
| A11 More 页双箭头与无效行 | NavigationLink 自带的箭头叠加了 `menuRow` 自己画的 chevron（MenuView.swift:44-59, 86-92, 125-130, 250-252；截图 14、15）；Share、Support、Contact、Copyright 四行有箭头但没有任何动作（158-165） | 【社区】去掉手势已经隐含的多余箭头（[Kole Jain](https://sozai.app/transcript/ui-ux-mistakes-beginner/index.md)）；【实证】Stanford #10 | 删除 `menuRow` 里的 chevron。Share 用 `ShareLink`，Support/Contact 用 `mailto:`，暂时不做的行直接隐藏 |
| A12 Today's Market 右边缘的白块接缝 | 渐隐层用纯白 `cardBackground`，而卡片表面是 #FFFFFF→#F7F2ED 的渐变，像素在 x=1108 px 处为 #FEFEFE、在 x=1118 px 处跳到 #F8F3EF，还遮住了 NU 的涨跌徽章（MyHoldingView.swift:889-895；AppTheme.swift:344；截图 05 访客首页） | 【社区】「Nothing must be arbitrary」（[Vitsœ](https://www.vitsoe.com/us/about/good-design)） | 不要在上面再盖一层颜色，改为给滚动内容加透明度遮罩：`.mask(LinearGradient(stops: [.init(color: .black, location: 0.85), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))`。S4 把卡片改为纯色后，接缝也会随之消失 |
| A13 内容被浮动 tab bar 挡住 | 空状态的「Help Me Pick Stocks」按钮被 tab bar 盖住，只露出一段焦糖色圆弧；同类公司的「Add」、Paper Trading 行的文字、Fundamentals 的几行都从两个胶囊之间的缝隙露出来（MyHoldingView.swift:435-449；ContentView.swift:316-360；截图 05、08、11、14） | 【Apple】必须尊重安全区，避免系统 UI 遮挡内容和控件（[HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)） | 短期：在根滚动视图上加 `.safeAreaInset(edge: .bottom) { Color.clear.frame(height: 72) }`（tab bar 高度加间距）。长期：迁移到系统 `TabView`（S5），由系统处理安全区 |
| A14 图表裁切、新闻居中、REUT 裁图 | 图表加了 `.padding(.horizontal, -16)`，两端各约 16pt 落在屏幕外，最新价和脉冲点看不到，这可能也是图表上方出现 95–100pt 空带的原因，需用 view debugger 确认（StockDetailView.swift:1585-1586；截图 08）。相关新闻标题居中显示（499-517；截图 11）。Reuters 的 logo 图被 `.fill` 裁成「REUT」（NewsView.swift:159-167；截图 12） | 【Apple】紧凑布局要「最大化绘图区宽度」，但不能牺牲关键信息（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)）；【社区】正文和数字居中显得廉价 | 去掉负 padding，用 `.chartPlotStyle` 控制绘图区，最后一个数据点右侧留 ≥8pt。新闻行加 `.buttonStyle(.plain)` 和 `.multilineTextAlignment(.leading)`。出版方 logo 用 `.fit` 放在中性底色的方块里，或者不显示缩略图、只显示来源名 |
| A15 像投资建议的文案 | 风险结果页写着「We'll suggest a mix of growth stocks…」「We'll focus on blue-chip stocks…」「We'll highlight high-growth opportunities…」（RiskProfileView.swift:103-109）；财报提示写着「consider waiting until after the report to make decisions」（StockDetailView.swift:1298-1313；截图 10）；而同意页明确说自己「not a registered adviser」 | 【Apple】「信任与稳定」（[HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)）；【推断】与 App 自己的免责声明不一致，会削弱信任。这不是法律意见，合规边界需另行确认 | 改成描述性文案，例如「Orion 在讲解时会多介绍稳定收益类资产和分散配置的概念」。财报提示改为「财报发布前后，股价波动通常更大。」删除「consider waiting」 |

### 打扰与动效：七个永动循环和一个不请自来的弹窗

审计在代码里统计到 7 处 `repeatForever`、一条永不停止的行情条、滚动驱动的模糊视差、14 处 numericText 过渡和阻尼 0.6 的弹簧，而且没有一处受「减弱动态效果」控制。需要说明，动效只做了代码审计，没有在运行时观察，实际观感（行情条速度、星座的「呼吸感」）尚未验证。

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| M1 首页永动行情条 | 自动滚动的 marquee：`.linear(duration: itemsWidth/40).repeatForever`，速度 40pt/s，出现 0.3 秒后启动，36pt 高，底为 ultraThinMaterial；下跌日满屏是红色数字和粉色箭头圈（MyHoldingView.swift:1579-1651；截图 05 访客首页） | 【标准】WCAG 2.2.2 要求自动更新的股价可暂停（[W3C](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)）；【实证】边缘运动最抢注意力（[Bartram](https://www.interruptions.net/literature/Bartram-IJHCS03.pdf)）；红色会延长悲观预期（[Bazley](https://econpapers.repec.org/RePEc:inm:ormnsc:v:67:y:2021:i:9:p:5616-5641)）；【Apple】减少「自动、重复的外围运动」（[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)） | 默认静止：改为用户可横向滑动的 `ScrollView(.horizontal)`，末尾注明「截至 4:00 PM ET」；或者压缩成一行「SPY −0.36% · QQQ −1.20%」原位更新、不做动画。如果坚持自动滚动，必须做到触摸即停、离屏即停、减弱动态效果和 VoiceOver 下停止，恢复时跳到最新数据 |
| M2 空自选的「呼吸」星座 | ConstellationView 使用 `.easeInOut(2.5).repeatForever(autoreverses: true)`，即 5 秒一个周期，**正好 0.2 Hz**；另有 160pt 径向光晕和发光 sparkle（MyHoldingView.swift:2175-2221；截图 05 访客首页） | 【Apple】visionOS 的动效指南要求避免持续振荡，「尤其是约 0.2 Hz」（[HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion)）。这是 visionOS 语境，【推断】可作为外围呼吸动画令人不安的旁证 | 去掉 `repeatForever` 和光晕，最多保留一张 ≤80pt 的静态小插画；空状态只留一句说明和一个按钮（H1） |
| M3 「实时」脉冲点 | LivePulseDot 使用 `.easeInOut(1.2)` 永久循环，光圈在 8pt 与 16pt 之间变化（AppTheme.swift:451-471；StockDetailView.swift:1563-1570） | 【Apple】Pulse 类动画只应持续到「某个条件满足」为止（[HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)） | 换成静态 6pt 圆点，加「实时 · 10:42」时间标签 |
| M4 其余循环动画 | 图表的「Touch to explore」脉冲提示（StockDetailView.swift:1587-1665，只在首次出现，6 秒后自动隐藏）；骨架屏 shimmer 使用 `.linear(1.5)` 永久循环（ShimmerView.swift:6-33）；语音聊天的蓝紫光球（ChatView.swift:646-657） | 【实证/社区】骨架屏动画是可选的，而且「可能分散注意力」（[NN/g](https://www.nngroup.com/articles/skeleton-screens/)）；【Apple】用 TipKit 做情境提示（[HIG Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)） | 图表提示改成一次性的 TipKit 提示；shimmer 在减弱动态效果时静止，平时周期放慢到 ≥2 秒或直接静态；光球的处理放在 P3 |
| M5 价格徽章会弹跳 | 价格变化徽章使用 `.spring(response: 0.35, dampingFraction: 0.6)`，涉及 StockRow、MoverChip 和 hero 胶囊（MyHoldingView.swift:1726, 2048；StockDetailView.swift:1426） | 【Apple】bounce 超过约 0.4「过于夸张」（[WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)）；【推断】阻尼比 0.6 大约相当于 bounce 0.4（ζ ≈ 1 − bounce），正好卡在上限；【实证】FCA 把红绿闪烁列为关注特征 | 统一改为 `Motion.number`；只在数值真正变化时触发，每行的更新节流到几秒一次 |
| M6 动效参数散落各处 | 4 套弹簧参数，外加约 19 个时长字面量（0.05–2.5 秒）。`quickDuration`、`standardDuration`、`slowDuration` 只在 AppTheme 内部被引用；`StaggeredItem` 一次都没用过（AppTheme.swift:218-224；StaggeredFadeIn.swift:9-27） | 【实证/社区】见得越频繁的动画越要短（[NN/g](https://www.nngroup.com/articles/animation-duration/)）；【Apple】同类行为要「成族」（[WWDC18](https://developer.apple.com/videos/play/wwdc2018/803/)） | 采用第三节的 5 个 Motion token，用全局搜索替换掉所有字面量；删除 `StaggeredItem` 和旧的时长常量 |
| M7 滚动时的模糊视差 | 净资产图表在滚动时偏移最多 20pt，模糊到 6pt，透明度降到 0.7，缩放到 0.97（MyHoldingView.swift:11-23, 1091-1106；只在有持仓时出现，没有截图） | 【Apple】减弱动态效果时「避免动画进入或退出模糊」，避免 z 轴深度动画（[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)） | 去掉 blur 和 scale，最多保留轻微的透明度变化；减弱动态效果时完全关闭 |
| M8 没有处理减弱动态效果与减弱透明度 | 全代码 0 处引用 `accessibilityReduceMotion`；7 处 `.ultraThinMaterial` 都没有降级方案 | 【Apple】自定义材质和控件不会自动适配这些设置（[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)） | 在 Motion token 层读取 `accessibilityReduceMotion`，开启时返回只改透明度的动画；材质层读取 `accessibilityReduceTransparency`，开启时降级为不透明的 `cardBackground` |
| M9 股票详情加载时布局跳动 | 先加载图表，再加载报价，最后加载各模块，全部串行；Key Data、Analyst、News、Peers 等几乎都是 `if let` 条件渲染，各自完成时弹入页面，AI 模块还在流式增长（StockDetailView.swift:147-151, 336, 455, 496, 586, 728, 1050, 1123, 1250, 1778-1781） | 【标准/社区】CLS ≤0.1 为良好（[web.dev](https://web.dev/articles/cls)）；【Apple】最好的加载体验是在用户察觉之前就已结束（[HIG Loading](https://developer.apple.com/design/human-interface-guidelines/loading)） | 用 `async let` 并行请求；为每个模块预留固定高度的 `.redacted` 占位，数据到达后原位替换；没有数据的模块整块隐藏，但要在首次布局前就决定好（批量揭示），不要先出现再消失 |
| M10 登录入场动画太长 | Logo 0.7 秒，标题延迟 0.3 秒，表单延迟 0.6 秒，合计约 1.2 秒后才能操作（LoginView.swift:198-200） | 【实证/社区】500ms「开始拖沓」（[NN/g](https://www.nngroup.com/articles/animation-duration/)） | 合并成一次 ≤0.35 秒的整体淡入，或者直接去掉 |

### 颜色与对比度：「柔和」已经滑到了看不清

表中的候选色值由笔者按 WCAG 2.x 亮度公式计算，属于【推断】，落地前需要在真机和「增强对比度」模式下目视复核。

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| C1 次要文字看不清 | `secondaryText` #8A8078 共 242 处使用，在背景上 3.46:1、白卡上 3.86:1、subtleFill 上 3.19:1。它的 0.3–0.7 透明度变体被用于日期、时间戳和标语，对比降到 1.59–2.40:1：首页日期 2.25、新闻时间 2.40、Gurus 标语 2.08、「Skip Login (Beta)」1.74（截图 00、05、12、13） | 【标准】正文 ≥4.5:1（[W3C](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)）；【实证/社区】低对比文字会降低信任（[NN/g](https://www.nngroup.com/articles/low-contrast/)），这正是「压对比」的陷阱 | 浅色 `secondaryText` 改为 **#706861**（背景 4.90、白卡 5.47、subtleFill 4.52:1）；深色保持 #9A9088（5.60 / 5.04:1）。删除所有文字上的 `.opacity()`。新增 `tertiary` 色，取现在的 #8A8078，**只用于图标和箭头**（≥3:1）。文字层级改由字号和字重区分 |
| C2 焦糖按钮上的白字 | 所有焦糖色 CTA 的白字对比都是 2.67:1，深色模式 2.23:1（截图 00、02、05、16、17） | 【Apple】粗体或 ≥18pt 的文字至少 3:1，其余至少 4.5:1（[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)） | 首选：保留焦糖填充，按钮文字改为 `primaryText` #2C2520（**5.64:1**）；深色模式在 #D4A574 上用 #1C1916（**7.86:1**）。品牌色不变，改动最小。备选：把按钮填充加深到 #9D6C3E 以保留白字（4.52:1），但颜色会更偏棕 |
| C3 accent 被当作文字色 | accent 文字在背景上 2.40:1、白卡上 2.67:1，用在选中的 tab、Sign Up、机构名标签等处 | 【标准】同上 | 新增 `accentText` = **#94653A**（背景 4.50、白卡 5.02:1），专门用于文字和小图标；#C4956A 只用于填充和大面积图形。启用一直没用的 `accentDark` 作为按下态 |
| C4 浅色模式的涨跌色太亮 | positive #4CB07D 在白底上 2.69:1，在它自己的 10% 徽章底上 2.46:1；negative #E35C5C 在白底上 3.53:1 | 【实证】高饱和度会提升唤醒度（[Brasel & Hagtvedt](https://www.bc.edu/content/bc-web/bcnews/nation-world-society/business-and-management/color-and-consumer-perception.html)）；【社区】涨跌色向暖色系降饱和，例如橄榄或鼠尾草绿配砖红 | 浅色 positive 改为 **#3D7A55**（背景 4.57、白卡 5.11、10% 徽章底 4.50:1），negative 改为 **#B0473B**（4.94 / 5.51 / 4.79:1）。两者饱和度都比现值低，更贴近焦糖色系。深色模式现值已达标（7.56 / 5.59:1），保留。数字始终带 +/− 号 |
| C5 警告色与下跌色相同 | `static let warning = Color("ThemeNegative")`（AppTheme.swift:41），错误横幅和下跌的股价长得一模一样 | 【Apple】不要改变语义色的含义（[HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)） | 新增 `ThemeWarning`，取赭石色 **#946516**（背景 4.55、白卡 5.08:1），配合 `exclamationmark.triangle` 图标；错误态以图标和文字为主，不用大面积色块 |
| C6 调色板之外的系统色 | 至少 12 种。风险结果「Moderate」用 32pt 系统橙，配蓝、粉色块（RiskProfileView.swift:102-108, 332-334；截图 02）。加密、外汇、金属、商品图标分别用橙、蓝、金、鼠尾草绿（MyHoldingView.swift:1794-1797, 2013-2016）。兴趣分类用了 10 种颜色（InterestsSelectionView.swift:164-173）。语音聊天用藏青和蓝紫（ChatView.swift:604-664）。下拉刷新的颜色写死为 #D1945A（OrionRefreshView.swift:10） | 【Apple】「当每个元素都被着色，就没有东西突出」（[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)）；【社区】Robinhood 刻意拒绝「彩虹」调色板（[PORTO ROCHA](https://www.portorocha.com/robinhood)） | 风险等级改用同一个 accent 的 3 个明度，或者纯中性色加文字标签；资产类型图标统一为 accent 单色、`hierarchical` 渲染；兴趣分类去掉色块，只留文字；刷新色改为 `Color.accentColor`。净资产图表的 6 色分类调色板**保留**，它服务于数据，且已做色盲验证 |
| C7 用透明度当色阶，深色 pill 看不见 | accent 有 12 级透明度，secondaryText 有 6 级。深色 subtleFill #2A2622 对卡片 #262220 只有 1.05:1，Gainers/Losers 和分类 pill 几乎看不见（截图 04 深色「添加资产」sheet） | 【社区】先定好有限的色阶，不要随手取值（[Refactoring UI 摘要](https://sglavoie-github-io.pages.dev/posts/2023/09/09/book-summary-refactoring-ui/)） | accent 只保留 3 级：`fill` 0.08、`selectedFill` 0.16、实色。深色 `subtleFill` 改为 **#38322D**（对卡片 1.25:1，与浅色模式的 1.21:1 相当） |

### 字体与数字：21 个字号、7 种字重、4 套涨跌样式

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| T1 字号写死，不支持 Dynamic Type | 约 446 处固定字号（261 处 `.system(size:)` + 185 处 AppTheme 固定尺寸助手），只有约 103 处使用文字样式；`@ScaledMetric` 0 处；共有 21 个不同字号，仅 `.system(size:)` 中就有 31 处使用 9–10pt，低于 Apple 规定的 11pt 下限 | 【Apple】最小 11pt，放大至少 200%（[HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)）；【社区】单屏字号 ≤5（[人人都是产品经理](https://www.woshipm.com/pd/4045552.html)） | 采用下文的 7 级字阶，全部映射到文字样式。`serifTitle`、`serifHeadline`、`number`、`caption` 这些助手改为接收 `Font.TextStyle`，不再接收数字。9–10pt 一律改为 `.caption2`（11pt）或直接删除 |
| T2 字重多达 7 种 | semibold 105 处、bold 69、medium 59、light 10、black 4、regular 2、heavy 1 | 【社区】「很少需要两种以上的字重」（[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)）；【Apple】小字避免用 Light 及更细的字重 | 只用 regular 和 semibold，hero 数字可以用 bold；删除 ChangeBadge 箭头的 `.black` 和 SectionLabel 的 `.heavy` |
| T3 数字全用 SF Mono | 所有价格和百分比都走 SF Mono（AppTheme.swift:113-115, 597），带斜杠零和很宽的小数点（截图 08 的「$162.85」、截图 05 访客首页行情条的「-0.36%」）；`.monospacedDigit()` 0 处使用 | 【社区】金额和实时数值用等宽数字，以对齐、防抖动（[fontalternatives](https://fontalternatives.com/blog/best-fonts-legible-numerals-ui/)）；Robinhood 为数据选择「精确」的无衬线体；Monzo 的数字被嫌「太俏皮」（[Monzo Community](https://community.monzo.com/t/new-font/142936)） | `number()` 改为 `.system(style, weight: .semibold).monospacedDigit()`，即 SF Pro 字形加等宽数字。货币符号可以拆成单独的 `Text`，用 `.secondary` 色并小一级字号（【推断】常见做法，未找到一手来源） |
| T4 同一个数据，四套涨跌样式 | ChangeBadge（圆形箭头 + 胶囊）；hero 的渐变实心胶囊 + ▲▼ + 光晕；折叠工具条里的纯色文字；持仓行里不带图标的彩色文字（AppTheme.swift:536-610；StockDetailView.swift:1407-1426, 1463-1466；MyHoldingView.swift:735-749, 1493-1495） | 【社区】相同的组件必须完全相同（[Kole Jain](https://sozai.app/transcript/ui-ux-mistakes-beginner/index.md)）；【Apple】不要只靠颜色区分（[HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)） | 合并为一个 `ChangeLabel` 组件：`Image(systemName: "arrow.up.right").imageScale(.small)` 加 `Text(pct, format: .percent.precision(.fractionLength(2)).sign(strategy: .always()))`，使用 `.monospacedDigit()`；只给文字上色，不加背景或最多加 0.08 的填充，不加光晕；尺寸跟随文字样式 |
| T5 页面标题与边距不统一 | 页面标题字号 22、24、26、28、32 混用（首页 26、Orion AI 22、股票名 24、登录 32、风险页 28/32）；More 页没有标题；左右边距在首页、News、Gurus 是 20pt，在 Orion AI 和股票详情是 16pt | 【Apple】使用一致的间距（[HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)）；【社区】一致的几何带来平静（[UXmatters](https://www.uxmatters.com/mt/archives/2026/01/the-hidden-geometry-of-calm-screens.php)） | 所有 tab 根页面的标题统一为 `.system(.title, design: .serif, weight: .semibold)`（28pt），边距统一 20pt；股票名用 `.title2` 衬线（22pt）；More 页补上标题 |
| T6 模块标题装饰太重 | `AccentSectionTitle` 由 4×20pt 的 accent 竖条、14pt accent 图标和 17pt 衬线标题组成，详情页最多会渲染 20 个（AppTheme.swift:505-531；StockDetailView.swift:319-329；截图 08、10） | 【社区】弱化次要信息和强调主要信息同样重要（[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)）；Linear 减少图标、去掉彩色图标底 | 去掉竖条和图标，只保留 `.system(.headline, design: .serif)` 标题，用主文字色；模块之间用 32pt 间距代替渐变分割线 |
| T7 中日韩衬线字号固定 | Songti SC、Hiragino Mincho ProN、AppleMyungjo 都以固定尺寸构造 `UIFont`（AppTheme.swift:127-160） | 【Apple】自定义字体必须自己实现 Dynamic Type 和粗体文本（[HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)） | 先用 `UIFontMetrics(forTextStyle:).scaledFont(for:)` 缩放，再转成 `Font`；或者中日韩直接回退到系统字体 |

建议的 Orion 字阶【推断，基于 HIG 文字样式表】共 7 级。hero 数字（净资产、股价）用 `.largeTitle` 34pt semibold 加 `.monospacedDigit()`。tab 根页面标题用 `.title` 28pt 衬线 semibold。股票名等次级标题用 `.title2` 22pt 衬线。模块标题用 `.headline` 17pt 衬线。正文和列表用 `.body` 17pt 或 `.subheadline` 15pt。元数据和时间戳用 `.footnote` 13pt。最小注释用 `.caption` 12pt，`.caption2` 11pt 只留给图表坐标。单屏实际出现的字号控制在 5 个以内。

### 间距、圆角、阴影、材质与导航：设计系统开了头，却没有执行

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| S1 间距 | `.padding()` 用了 26 个不同的数值（从 -16 到 100），stack 的 spacing 用了 17 个；`cardPadding` 只用了 5 次，`moduleSpacing` 只用了 3 次（AppTheme.swift:57-63） | 【社区】相邻两档至少相差约 25%，组间距离大于组内距离（[Refactoring UI 笔记](https://rjseymour66.github.io/webdev/refactoring-ui/)） | 定义 `Space` 刻度：4、8、12、16、24、32、48，另设 `screenMargin = 20`。卡片内边距 16，并用 `@ScaledMetric(relativeTo: .body)` 随字号缩放；模块之间 32，组内 8–12 |
| S2 圆角与按钮形状 | 10 个不同的圆角值（1.5–18），加上 `cardRadius` 18 和 58 处 Capsule。按钮有三种形状：胶囊（Get Started 等）、圆角 10（Log In、Google、Apple）、圆角 12（Allow and continue）。登录卡圆角 16，输入框圆角 6 | 【Apple】形状分固定、胶囊、同心三类，嵌套时内圆角 = 外圆角 − 内边距（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)） | 只保留三种：所有按钮、pill、chip 用 `Capsule()`；卡片和 sheet 内容用 18pt 的 `.continuous` 圆角；卡片内的嵌套元素用 `ConcentricRectangle()`（iOS 26），或手算 18 − 8 = 10 |
| S3 阴影与光晕 | 35 处 `.shadow(`，约 24 种配方。每张卡片在浅色下是 black@0.10 r10 y5，深色下 @0.30。5 个 CTA 带 accent@0.3 的光晕，FAB 是 @0.35，登录页 sparkle 是 @0.4，涨跌胶囊下还有红绿光晕；tab bar 的每个胶囊有两层阴影；`AppTheme.cardShadow()` 定义了却没用 | 【Apple】「层级应通过布局与分组表达，而不是依赖装饰」（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)）；【社区】约 5 级阴影「已经足够」，「不要过度」 | 静置的卡片不加阴影，靠白卡与 #F5F2EE 背景的色差（1.12:1，和 iOS 分组背景是同一个思路）加 0.5pt 的 `border` 发丝线来区分。如果需要一点浮起感，只用一种 `primaryText.opacity(0.06), radius: 8, y: 2`（【推断】设计惯例值）。深色模式不加阴影。删除所有彩色光晕 |
| S4 卡片渐变 | 浅色卡片从白色斜向渐变到 #F7F2ED；深色卡片从 cardBackground 渐变到它的 0.92（AppTheme.swift:335-374） | 【Apple】节制用色（[HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)）；【社区】Linear 提醒暖色过头会「浑浊」 | 卡片改为纯色 `cardBackground`；渐变如果要保留，只用在一个 hero 元素上 |
| S5 自制胶囊 tab bar | `.ultraThinMaterial` 胶囊加两层阴影，Orion 是单独的胶囊，选中时用 accent 填充并发光；向上滚动时自制收起（58→46pt）；切换 tab 有触感（ContentView.swift:267-443） | 【Apple】iOS 26 的系统 tab bar 本身就是浮动的 Liquid Glass，并提供最小化、底部附件槽和自动无障碍适配（[HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)）；自制导航栏的背景应该去掉（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)） | 改用系统 `TabView`：5 个 `Tab`，实心 SF Symbols，`.tint` 设为 accent，加 `.tabBarMinimizeBehavior(.onScrollDown)`；删除切换 tab 的触感和自制的收起逻辑。已知问题有两个：条件渲染 `tabViewBottomAccessory` 在早期 seed 上会崩溃；使用 `.onScrollDown` 时启动会从第一个 tab 动画到恢复的选中项（[Forums 839224](https://developer.apple.com/forums/thread/839224)）。如果出于品牌原因必须保留自制栏，改用 `GlassEffectContainer` 加 `glassEffect`，只给选中项着色 |
| S6 内容层的材质 | 行情条、新闻刷新按钮、图表提示、聊天输入栏都用了 `.ultraThinMaterial`（MyHoldingView.swift:1613；NewsView.swift:41；StockDetailView.swift:1655；ChatView.swift:294） | 【Apple】标准材质可以用在内容层，但内容不要长时间与玻璃相交（[WWDC25 #219](https://developer.apple.com/videos/play/wwdc2025/219/)） | 行情条改为纯色（【推断】压在滚动内容上的材质会闪烁）；新闻刷新按钮移到工具栏（使用系统玻璃），或者只靠下拉刷新；聊天输入栏可以保留材质，但要在减弱透明度时降级 |
| S7 FAB 和重复的入口 | 52pt 的焦糖色「+」FAB 带 0.35 r12 y6 的光晕，与空状态的「Add Stock」功能重复（MyHoldingView.swift:161-176；截图 05 访客首页） | 【Apple】操作应和它服务的内容放在一起（[WWDC25 #356](https://developer.apple.com/videos/play/wwdc2025/356/)）；【实证】选项越多，决策越慢（[Hick's Law](https://lawsofux.com/hicks-law/)） | 删除 FAB；添加入口放在自选模块标题右侧，做成 `plus` 按钮（命中区 44×44）；空状态只保留一个「Add Stock」 |

### 信息密度：首页没有主角，股票详情有 12 个主角

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| H1 首页没有主角 | 访客首页从上到下依次是：滚动行情条、问候、休市 pill、链接账户卡、Today's Market 卡、160pt 光晕加 120pt 星座加 sparkle、两个 CTA（第二个被 tab bar 挡住）、FAB。最大的元素是装饰性的星座，最饱和的是红色行情数字；Hot、Add Stock、FAB 同时用 accent 实色填充（截图 05 访客首页） | 【实证】复杂度主导第一印象（[Reinecke 2013](https://www.eecs.harvard.edu/~kgajos/papers/2013/reinecke13predicting.shtml)）；【社区】颜色、信息、欲望三层克制（[人人都是产品经理](https://www.woshipm.com/pd/5256416.html)）；【Apple】空状态应引导用户的下一步（[HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)） | 访客首页的顺序改为：问候加市场状态（一行）→ 链接账户卡（唯一的 hero）→ 自选（空状态只有一句说明和一个按钮）→ 市场概览（放在首屏以下）。每屏只出现一个 accent 实色填充。「Help Me Pick Stocks」改名为「按兴趣浏览」，做成次级文字按钮 |
| H2 「Hot」榜单 | Today's Market 默认停在带火焰图标的「Hot」，另有 Gainers 和 Losers 榜（MyHoldingView.swift:62, 69, 823-903；截图 05 访客首页） | 【实证】看到「热门交易」榜的用户交易这些股票的可能性高 14%（[OSC 2022](https://www.osc.ca/en/news-events/news/osc-study-finds-gamification-techniques-influence-retail-investors)）；FCA 把 24 小时涨跌榜列为关注特征（[FCA 2022](https://www.fca.org.uk/publications/research-articles/gaming-trading-how-trading-apps-could-be-engaging-consumers-worse)） | 改名为「市场概览」，默认显示指数或板块，而不是榜单；榜单改为 Most active / Up / Down 这类中性措辞，不要火焰图标，不显示排名数字；整个模块移到自选下方 |
| H3 有持仓时的首页（只审计了代码） | 有三套不同的区间选择器：首页是 10pt、圆角 6 的矩形，股票详情是 13pt 胶囊，NetWorthChartModule 是 11pt、圆角 6（MyHoldingView.swift:788-798；StockDetailView.swift:1335-1365；NetWorthChartModule.swift:303-312）。隐藏金额按钮只有 34×27pt（MyHoldingView.swift:1149）。审计没有记录默认区间 | 【实证】查看收益越频繁，人越厌恶风险（[Gneezy & Potters](https://Rady.ucsd.edu/_files/faculty-research/uri-gneezy/risk-taking.pdf)）；【社区】隐私模式能减少「诱使过度交易」的干扰（[Zerodha](https://zerodha.com/z-connect/?p=387662)） | 统一成一个 `RangePicker` 组件（胶囊、`.subheadline`、高 44pt）。净资产图默认显示 1Y（如果当前默认是 1D）。当日涨跌放在总额下方，用 `.footnote` 和次要色。隐藏金额按钮改为 44×44，并用 `@AppStorage` 记住状态 |
| H4 股票详情模块太多 | 紧凑布局里有 12 个内容模块、3 个广告位和 3 条渐变分割线，最多 20 个带 accent 竖条的标题（StockDetailView.swift:215-271） | 【Apple】「抵制把尽可能多的数据塞进来的诱惑」（[HIG Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data)）；【实证/社区】渐进披露超过两层，可用性就会变差（[NN/g](https://www.nngroup.com/articles/progressive-disclosure/)） | 目标约 8 个模块：头部 → 图表与区间 →（持仓）→ 关键数据（合并 Key Data 和 Fundamentals，默认显示 6 项，其余放进「全部指标」sheet）→ AI 摘要（按需开启）→ 财报 → 分析师 → 新闻（3 条加「查看全部」）→ 同类公司 → 公司简介。删除 Options 占位、广告位和渐变分割线 |
| H5 股票详情头部 | hero 只有公司名，没有股票代码。SF Mono 价格旁边是饱和的红色渐变胶囊，白字，带红色光晕。状态行与图表之间有约 95–100pt 的空白（StockDetailView.swift:1376-1426；截图 08、09） | 【实证】红色呈现会降低风险承担（[Bazley](https://econpapers.repec.org/RePEc:inm:ormnsc:v:67:y:2021:i:9:p:5616-5641)）；【社区】数据用精确的无衬线体（[PORTO ROCHA](https://www.portorocha.com/robinhood)） | 公司名上方加股票代码「NVDA」，用 `.subheadline` 和次要色；价格用 `.largeTitle` semibold 加 `.monospacedDigit()`；涨跌用 T4 的 `ChangeLabel`；修复 A14 之后再检查空白是否消失 |
| H6 图表 | 2pt 红线加 red@0.2→0 的面积填充，占了上半屏；没有基线，也没有坐标（StockDetailView.swift:1473-1604；截图 08） | 【社区】Robinhood 按区间首尾收盘价决定线的颜色，用基线区分涨跌（[Robinhood Help](https://robinhood.com/us/en/support/articles/using-charts/)）；【Apple】可交互的图可以用更少、更淡的网格线，并让整个绘图区都能拖动（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)） | 线宽 2pt，面积填充不超过 0.08 或直接去掉；线的颜色按所选区间首尾比较决定；1D 加一条 `RuleMark(y: previousClose)` 虚线基线；`.chartYScale(domain:)` 按最小值和最大值各留 5% 余量；用 `chartXSelection` 加竖向 `RuleMark` 实现拖动查看；整张图加一句 `.accessibilityLabel` 摘要 |
| H7 区间条用了红绿渐变 | Day Range 和 52W Range 的轨道是 red@0.2→green@0.2 渐变，旋钮是带光晕的 accent，两端的高低价标签分别染成红色和绿色（StockDetailView.swift:360-438；截图 10） | 【Apple】不要只靠颜色区分信息（[HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)）；【推断】最高价和最低价不代表「好」或「坏」 | 轨道改用 `subtleFill`，旋钮用 `primaryText` 且不加光晕，两端标签用 `secondaryText` |
| H8 新闻 | 不显示来源名；Reuters 的 logo 连续三条被裁成「REUT」黑块；时间是 11pt、对比 2.40:1；每 5 条插一个 Ad；内容以地缘政治为主（NewsView.swift；截图 12） | 【实证】Stanford #9 要求克制推广内容；【推断】与投资无关的冲突类新闻会推高焦虑 | 每条显示「Reuters · 2 小时前」，用 `.footnote` 和 C1 的新次要色；缩略图只用文章配图；删除 Ad；按市场或商业类别、或按与自选的相关性过滤（【推断】） |
| H9 Orion AI 页 | 标题 22pt、边距 16pt，与其他 tab 不一致；新建对话按钮用主文字色，而新闻的刷新按钮用 accent；标题与插画之间有约 235pt 空白，没有示例问题；输入栏有 5 个 18–20pt 的图标，间距只有 6pt（ChatView.swift:17-110, 253-298；截图 16、17） | 【Apple】通过交互来教（[HIG Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)）；控件至少 44×44pt | 标题和边距按 T5 统一；空状态放 3 个示例问题 chip（例如「NVDA 今天为什么跌？」）填掉空白；输入栏只保留文本框、一个「+」菜单（照片和文件）、麦克风和发送按钮，命中区 44pt |
| H10 登录页 | 黑色的 Sign in with Apple 是全页对比最强的块，压过了焦糖色的「Log In」；Google 按钮用的是通用的 `globe` 图标；「Skip Login (Beta)」对比只有 1.74:1，而且把「Beta」露给了用户；「Orion Finance」是硬编码字符串（LoginView.swift:49-50, 110-247；截图 00） | 【实证】Stanford #6 要求「看起来专业」，#10 要求避免错误 | 按真实意图排主次：Apple 登录放第一位（它本来就最醒目），邮箱登录排第二；Google 使用官方品牌标识（【推断】）；「Skip Login (Beta)」改为「Continue as guest」，用新的 `secondaryText`；字面量全部本地化 |
| H11 风险结果页 | 「Moderate」用 32pt 系统橙，下面是蓝、橙、红三段的分数条和一个橙色圆点，紧挨着下方的焦糖色 CTA；圆点用 `offset(x: width*fraction)` 定位，没有减去自身宽度（RiskProfileView.swift:298-388；截图 02） | 同 C6 | 结果标题改用 `primaryText`；分数条用 accent 的 3 个明度；圆点的 offset 减去自身宽度的一半 |
| H12 More 页 | 没有页面标题；访客卡片显示「User」，邮箱一栏空白；各行图标混用描边和实心两种风格；AI Data Sharing 的开关在首屏以下（MenuView.swift:21-178；截图 14、15） | 【Apple】同一含义用同一个符号，渲染方式保持一致（[HIG SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)） | 补上标题；访客卡片改为「访客 · 登录以同步」加一个按钮；图标统一为 `.hierarchical` 渲染的描边风格；AI Data Sharing 移到隐私分组的顶部 |

### 触感、无障碍与本地化

| # | 现状证据 | 依据 | 建议改法 |
|---|---|---|---|
| X1 触感太多 | 共 61 处：`light` 23 处，中等强度的 `tap` 10 处，`error` 8 处，`selection` 7 处，`success` 7 处，`soft` 4 处，`warning` 2 处。触发场景包括：每次切换 tab、点每个 Today's Market pill、每次换区间、点每个指标、拖动图表时每越过一个数据点；移除自选会连响两次；AI 摘要加载完成也会震动；没有关闭开关（HapticManager.swift:7-34；ContentView.swift:279, 380；StockDetailView.swift:1549-1556；MyHoldingView.swift:360, 618；NewsView.swift:305） | 【Apple】「避免过度使用触感」，最好的触感是「人们意识不到、但关掉后会怀念」；要有清晰的因果关系，并且可以关闭（[HIG Haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)） | 保留约 10–15 处：拖动图表时 `.selection` 只在开始和跨日、跨月时触发；切换区间用 `.selection`；添加或移除自选的结果用 `.success` 或 `.error`；破坏性操作确认前用 `.warning`。删除 tab、pill、指标、FAB、问卷每个选项、聊天发送和 AI 摘要完成处的触感；中等强度全部降为 `.soft` 或直接删除。统一改用 `.sensoryFeedback(_:trigger:)`，并在 `SettingsManager` 里加 `hapticsEnabled` 开关 |
| AX1 命中区太小 | 隐藏金额按钮 34×27；首页区间选择约 30×20；Today's Market pill 高约 24；USD/CAD 切换高约 25；新闻刷新按钮约 30；股票区间选择高约 30；聊天输入栏的图标没有设置 frame | 【Apple】默认 44×44pt，最小 28×28pt（[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)） | 统一加 `.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())`，视觉尺寸可以保持更小 |
| AX2 缺少无障碍标签 | 整个代码库只有 5 处 `accessibilityLabel`；FAB、新闻刷新、新建对话和输入栏的 5 个图标都没有标签（MyHoldingView.swift:163-173；NewsView.swift:36-42；ChatView.swift:30-34, 255-290） | 【Apple】每个图表和控件都要可访问（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)） | 所有纯图标按钮都加 `.accessibilityLabel`；涨跌组件合并成一句朗读，例如「下跌 1.57%」 |
| L1 英文和区域写死 | 日期格式器写死为 `en_US`，「m ago」「h ago」是硬编码字符串，「Orion Finance」「Ad」「13F」是字面量，市场状态用 `M/d h:mm a` 格式（MyHoldingView.swift:81-86；NewsView.swift:20-25, 215-227；StockDetailView.swift:96） | 【Apple】使用无歧义的日期格式；【推断】代码里已有中日韩衬线回退，说明预期会有中日韩用户 | 日期改用跟随系统区域的 `Date.FormatStyle`；相对时间用 `Text(date, style: .relative)` 或 `.formatted(.relative(presentation: .named))`；字面量放进 String Catalog |

## 路线图：P0 一周清零，P1 是一次机械迁移

工作量按一人全职估算【推断】：小 = 半天以内，中 = 1–3 天，大 = 1 周以上。排序的原则是先修破坏信任和打扰用户的问题，再做 token 收敛，因为 token 收敛会碰到几乎每个文件，越晚做冲突越少。每一项都附了一个可以用 grep 或截图检查的「完成标准」，这样「品味」也能被验证。

**P0：明显缺陷，以及破坏信任或从容感的问题（合计约 5–7 个工作日）**

| 顺序 | 项目 | 对应 | 工作量 | 完成标准 |
|---|---|---|---|---|
| 1 | 涨跌幅统一按昨收计算，并补单元测试 | A1 | 小 | 同一只股票在首页、详情、行情条显示同一个数字 |
| 2 | 收盘状态显示最后成交时间；行情条改标为 SPY/QQQ/DIA | A2、A3 | 小 | 周末不再出现当天的时间；不再出现「S&P 500 754」 |
| 3 | AI 同意页改为按需触发；AI 卡片改为四态 | A5、A6 | 中 | 连续打开 10 只股票不弹出任何窗口；拒绝后不再自动询问；不出现空卡 |
| 4 | 添加自选改为乐观更新并提示失败，包括同类公司的 Add | A4 | 小到中 | 断网时添加，会出现内联提示并回滚 |
| 5 | 下线全部占位：Options、Volume「—」、Ad 灰盒、「Loading...」 | A7 | 小 | 视图里不再调用 Ad 占位；hero 加载时显示 redacted 占位 |
| 6 | 停掉首页的永动：行情条静止，星座去掉循环和光晕，脉冲点改为静态 | M1–M3 | 小 | 首页静置 10 秒，屏幕上没有任何运动 |
| 7 | 修正互相矛盾和像投资建议的文案 | A8、A15 | 小 | 周末首页不出现交易日文案；代码中搜不到「We'll suggest」「consider waiting」 |
| 8 | 问卷图标与转场 | A9、A10 | 小 | 不再有「?」方块；换题时没有叠影，也没有 175pt 的跳动 |
| 9 | 一批小 bug：tab bar 遮挡（临时用 safeAreaInset）、渐隐遮罩、图表负 padding、新闻左对齐、REUT 裁图、More 双箭头与无效行 | A11–A14 | 小（合计约 1 天） | 截图 05、08、11、14 中不再有内容从 tab bar 缝隙露出 |
| 10 | 深色 pill 看不见 | C7 | 小 | 深色 subtleFill 对卡片 ≥1.2:1 |

**P1：设计系统收敛（字号、颜色、圆角、阴影、内边距 token 化，Dynamic Type，对比度）**

| 顺序 | 项目 | 对应 | 工作量 | 完成标准 |
|---|---|---|---|---|
| 1 | 颜色 token：secondaryText、tertiary、accentText、按钮文字、涨跌色、warning、刷新色；删除文字上的透明度变体 | C1–C5、C7 | 中 | 所有文字对其背景 ≥4.5:1（大字或粗体 ≥3:1）；搜索 `secondaryText.opacity` 结果为 0 |
| 2 | 字阶第一步：AppTheme 助手改为接收文字样式 | T1 | 中 | 185 处助手调用都能随 Dynamic Type 缩放 |
| 3 | 字阶第二步：替换 261 处 `.system(size:)`；补 `@ScaledMetric`；辅助功能大字号下用 `ViewThatFits` 让行换行 | T1、T7 | 大 | `.system(size:` 只剩下图标在用；在 AX3 字号下截屏，没有文字被截断 |
| 4 | 字重收敛；数字改为 SF Pro 等宽数字；统一 ChangeLabel；统一页面标题和边距；模块标题去掉装饰 | T2–T6 | 中 | 只剩 3 种字重；涨跌只剩一种组件 |
| 5 | 间距和圆角 token，并替换现有写法 | S1、S2 | 中 | padding 只剩 ≤8 种取值；圆角只剩 Capsule、18 和同心三种 |
| 6 | 阴影和渐变：卡片改为纯色、不加阴影，删除所有光晕 | S3、S4 | 小 | `.shadow(` 不超过 3 处 |
| 7 | 动效 token，加上减弱动态效果和减弱透明度的处理；价格去掉弹跳 | M5、M6、M8 | 中 | 打开「减弱动态效果」后，没有位移和模糊动画 |
| 8 | 命中区和无障碍标签 | AX1、AX2 | 小到中 | VoiceOver 能读出所有图标按钮 |
| 9 | 本地化 | L1 | 中 | 把系统切换到中文后，日期和相对时间都显示正确 |
| 10 | 护栏：写一个 grep 脚本或 SwiftLint 的 `custom_rules`，禁止新增 `.system(size:`、`repeatForever`、数字 padding 和 `.shadow(` | 全部 | 小 | 提交前脚本报告 0 处违规 |

**P2：结构性改进（首页精简、动效与触感收敛、系统 TabView、数字排版、图表）**

| 顺序 | 项目 | 对应 | 工作量 |
|---|---|---|---|
| 1 | 首页重排：删除 FAB，Hot 改为市场概览并下移，只保留一个 CTA；考虑给访客显示更合适的 tab 名称 | H1、H2、S7 | 中 |
| 2 | 迁移到系统 TabView，同时彻底解决 A13 并去掉 tab 切换的触感 | S5 | 中 |
| 3 | 股票详情精简到约 8 个模块；改为并行加载，并为模块预留高度 | H4、M9 | 大 |
| 4 | 股票头部和图表：ChangeLabel、基线、按区间着色、动态 Y 轴、可访问摘要；区间条改为中性色 | H5–H7 | 中 |
| 5 | 触感收敛到约 12 处，并加设置开关 | X1 | 小到中 |
| 6 | 有持仓的首页：RangePicker 组件、默认 1Y、当日涨跌降级显示、隐藏金额持久化 | H3 | 中 |
| 7 | 新闻：显示来源名、调整缩略图策略、按类别过滤 | H8 | 中 |
| 8 | Orion AI：示例问题、精简输入栏、统一标题 | H9 | 中 |
| 9 | 打磨登录页、风险结果页和 More 页；清理调色板外的颜色 | H10–H12、C6 | 小到中 |
| 10 | 处理剩余动效：视差、图表提示改为 TipKit、shimmer、登录入场 | M4、M7、M10 | 小 |

**P3：品牌与长期**

| 顺序 | 项目 | 工作量 |
|---|---|---|
| 1 | 在 OKLCH 色彩空间里微调米白和焦糖的彩度，检查是否「浑浊」、与新的涨跌色是否协调；补「增强对比度」下的色值 | 中 |
| 2 | 涨跌配色设置：绿涨红跌、红涨绿跌、中性（只用符号和箭头），并照顾色盲用户（[HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts)、[Robinhood](https://robinhood.com/support/articles/accessibility-options)） | 中 |
| 3 | 在净资产图上方加一句白话摘要，参照 HIG 中「天气」App 的模式（例如「本月上涨 2.1%」）；可以由 AI 生成，但默认显示静态文字 | 中 |
| 4 | 通知策略：价格类通知默认关闭；开启后使用 Passive 级别加每日摘要，绝不使用 Time Sensitive（[HIG Notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)） | 中 |
| 5 | 品牌插画和语音聊天界面回到暖色系；Gurus 的标语去掉名人化的表述 | 中 |
| 6 | 首页模块支持自定义（参照 Monzo 的做法） | 大 |
| 7 | 可选：只针对分散配置这类良性行为做「正向游戏化」；OSC 2026 的效果只有 +3.5–4.5%，优先级低 | 大 |
| 8 | 补齐未验证的部分：深色首页和有持仓首页的截图、辅助功能大字号、VoiceOver、真机触感、iPad 与横屏布局 | 中 |

有几件事刻意没有放进路线图。第一，不建议换品牌、换字体或新做插画体系，现有的底色就是正确答案。第二，在系统 TabView 可用的情况下，不建议自己复刻 Liquid Glass。第三，在 P0 和 P1 完成之前，不建议再加新模块，否则每加一个模块，收敛的成本就会增加一点。

## 结论

这次分析最重要的发现是：在 Orion 身上，「高级」和「从容」几乎是同一份待办清单。永动的行情条和星座、彩色光晕、占位广告位、20 个带竖条的模块标题、61 处触感，既让产品显得廉价，也让用户无法放松。删掉其中任何一项，两种感受会同时改善。第二个发现更利于个人开发者：Orion 的设计系统已经存在，缺的只是执行。所以通往高级感最便宜的路是先把已有的系统执行下去，而不是去发明新风格。一条 grep 护栏，让 `.system(size:`、`repeatForever`、`.shadow(` 的数量只减不增，就能把「品味」变成可以检查的约束。

第三个发现关乎产品立场。对一个面向加拿大用户的投资 App，从容不只是美学选择。加拿大本地监管机构 OSC 已经用加拿大投资者证实，积分和热门榜会改变交易行为，而 Wealthsimple 公开把「无聊」当作设计目标。去掉火焰图标的「Hot」榜、静止的行情条、默认更长的图表区间，既是品牌表达，也是降低风险的姿态。此外，大公司正在把钱投入原生定制工艺（Copilot、Wealthsimple 与 Fey），个人开发者赢不了这场竞赛。Orion 应该把导航和材质交给 iOS 26 的系统组件，这些组件会自动获得 iOS 27 的透明度设置和无障碍适配；有限的精力集中投入数字、字体和文案这三处最能体现用心的地方。仍然不确定的是：本报告的候选色值、动效观感和触感强度，都还没有在真机、大字号和 VoiceOver 下验证，有持仓时的首页也只审计了代码。P3 的最后一项就是为了补上这些空白。
