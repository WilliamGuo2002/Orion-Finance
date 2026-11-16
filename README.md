<p align="center">
  <img src="icons/4887BBCA-6D35-440B-A3A9-EA936D1F2C1E.png" alt="Orion Finance Banner" width="100%">
</p>

# Orion Finance

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-iOS%2018.5+-000000?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-007AFF?logo=swift&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?logo=google&logoColor=white)
![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

**A calm, approachable iOS app for your net worth, your investments and your taxes, with an AI that explains.**

> Built with SwiftUI | Powered by Google Gemini | Made in Canada

[**中文版**](#中文版)

---

## Overview

Orion Finance started as a way to make US stocks less intimidating for people who are just starting out. It has grown into a personal wealth app: it brings your brokerage and bank accounts into one net worth, tracks your cost basis and capital gains for Canadian taxes, and lets Orion, the built-in AI, explain what you're looking at in plain language.

Orion explains; it never trades. There is no order entry. When you want to act, the app hands you to your own broker.

Every advanced feature is available to everyone. One question during onboarding ("How familiar are you with investing?") only picks sensible defaults, such as line or candlestick charts and how much Orion explains.

---

## Features

### Net Worth and Linked Accounts
- **Brokerages** through SnapTrade (read-only), for example Wealthsimple and Questrade: accounts, holdings and cash
- **Banks** through Plaid (read-only balances): chequing, savings, credit cards and loans. Transactions are never read.
- Net worth chart with real daily history (a nightly snapshot) and a per-institution breakdown
- Display in USD or CAD, and a one-tap **hide amounts** mode
- Sync health: a banner when a connection needs to be reconnected or its data is stale
- All provider secrets live on the server (Firebase Cloud Functions). The app never sees them.

### Tax Assistant (Canada)
- **TFSA / RRSP / FHSA**: this year's contributions compared with the room you have
- **Adjusted cost base (ACB)**: identical shares are pooled across all your non-registered accounts. Each trade is converted to CAD at the Bank of Canada rate for its trade date, and commissions are included.
- **Capital gains by year**: proceeds, ACB, outlays, and gains or losses for each sale, with a CSV export for Schedule 3
- **Superficial loss**: alerts, plus the pro-rated denied loss added back to the pool's ACB
- Shares transferred in from another broker: enter their original cost once and everything is recalculated
- Informational only, not tax advice

### Market Data and Charts
- Stocks, ETFs, crypto, forex, precious metals and commodities
- Ranges from 1D to ALL. Scrub the chart and every number rolls along with your finger.
- **Line or Orion candles**: hollow up-candles, solid down-candles, and wicks that stop at the body
- Volume: hidden, a single colour, or up/down colours
- A dashed previous-close baseline on 1D, plus a market status label (open, pre-market, after-hours, closed)
- Today's Market: Hot, Gainers and Losers

### Orion AI
- Chat about stocks and money, with **voice conversation** (Gemini Live) and photo or document attachments
- Orion's tone follows your experience level: terms explained for beginners, straight to the data for experienced investors
- **Signal summary** on every stock: Positive, Mixed or Negative, with the bullish and bearish factors behind it. It is not a buy or sell call, and it gives no price targets.
- One-tap news summaries

### Learn and Practise
- "You might be interested in" picks instead of an empty home screen
- Recommendations based on your interests and risk profile, plus a portfolio-builder wizard
- **Paper trading**, stock comparison and first-time chart tips
- **Open in your broker**: linked brokers first, then Wealthsimple, Questrade, IBKR, the big-bank brokerages and Robinhood

### Research
- Key metrics (P/E, P/B, growth, ROE, dividend yield, beta, margins), the 52-week range, analyst ratings and peers
- **Famous investors' portfolios** from SEC 13F filings (EDGAR)
- A news feed with filters (Top, Your watchlist, Deals, Crypto) and company news
- Comments on each stock
- Price and index alerts, and a daily market summary

### 13 Languages
- English, 中文, 日本語, 한국어, Español, Français, Deutsch, Português, Italiano, Русский, Українська, العربية, עברית, हिन्दी, switchable in the app without restarting
- **Right-to-left layout** for Arabic and Hebrew, while charts and amounts stay left-to-right
- **Orion Serif**: bundled Source Han Serif subsets (SIL OFL) so that Chinese and Korean titles are truly serif. New York is used for Latin and Cyrillic.

---

## Design

- **Calm and warm**: a caramel accent, flat cards, and numbers that don't bounce or shout
- **Liquid Glass** on iOS 26 for the system tab bar, the floating action bar and the frosted cards, with solid fallbacks under Reduce Transparency
- Chart heroes stay pinned while you scroll: the cards slide over them as they sink and blur
- Light serif hero numbers with tabular digits
- Dynamic Type, Reduce Motion and VoiceOver support, with 44 pt touch targets
- Haptics only for outcomes, with a toggle
- iPhone (portrait and landscape) and iPad (sidebar)
- `scripts/design_lint.py` keeps the design system honest: the counts it tracks may only go down

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI** | SwiftUI, Swift Charts, TipKit |
| **Auth & Database** | Firebase Auth (Email, Google, Apple), Cloud Firestore |
| **Backend** | Firebase Cloud Functions (TypeScript), see `firebase/` |
| **Account Linking** | SnapTrade (brokerages), Plaid Hosted Link (banks) |
| **AI** | Google Gemini 2.5 Flash, Gemini Live (WebSocket) |
| **Market Data** | Yahoo Finance, Finnhub |
| **Tax Data** | Bank of Canada Valet API (daily FX rates) |
| **Investor Data** | SEC EDGAR 13F |
| **Background** | BGTaskScheduler, UNUserNotificationCenter |

---

## Getting Started

### Prerequisites
- Xcode 26 or later (the Liquid Glass APIs need the iOS 26 SDK; the app still runs on iOS 18.5 and later)
- A Firebase project
- API keys for [Finnhub](https://finnhub.io/) and [Google Gemini](https://ai.google.dev/) (both have free tiers)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/WilliamGuo2002/Equion-for-iOS.git
   ```

2. Create `Equion for iOS/Services/APIKeys.swift`. It is git-ignored, so keep it that way:
   ```swift
   import Foundation

   enum APIKeys {
       static let finnhub = "YOUR_FINNHUB_KEY"
       static let gemini = "YOUR_GEMINI_KEY"
   }
   ```

3. Add your `GoogleService-Info.plist` from the [Firebase Console](https://console.firebase.google.com/). It is also git-ignored.

4. Optional: to link brokerages and banks, deploy the Cloud Functions by following [`firebase/README.md`](firebase/README.md). Everything else works without them, including guest mode.

5. Open `Equion for iOS.xcodeproj`, choose your team under Signing & Capabilities, and run.

### Tests and Checks
- Unit tests, including the ACB and capital gains engine: run the **Equion for iOSTests** target in Xcode (⌘U)
- Design guardrail:
  ```bash
  python3 scripts/design_lint.py
  ```

---

## Project Structure

```
Equion for iOS/
├── Equion for iOS/
│   ├── Models/                    # Stocks, charts, holdings, news, investors, market clock
│   ├── Services/
│   │   ├── APIService.swift       # Market data and Gemini
│   │   ├── AppTheme.swift         # Design tokens, glass cards, fonts
│   │   ├── BrokerageService.swift # SnapTrade accounts and holdings
│   │   ├── BankService.swift      # Plaid balances
│   │   ├── NetWorthHistory.swift  # Daily net worth snapshots
│   │   ├── TaxCenter.swift        # Registered room, superficial loss
│   │   ├── CapitalGains.swift     # ACB engine, Bank of Canada FX
│   │   ├── Experience.swift       # Experience-based defaults
│   │   ├── Localization.swift     # 13-language tables
│   │   └── ...
│   ├── Views/                     # Home, stock detail, Orion chat, news, tax, accounts, ...
│   │   └── Components/            # Chart display, pinned hero, range picker, broker menu, ...
│   └── Resources/Fonts/           # Orion Serif (Source Han Serif subsets, OFL)
├── Equion for iOSTests/           # Unit tests
├── firebase/                      # Cloud Functions: SnapTrade, Plaid, nightly snapshots
├── scripts/                       # Design lint and its baseline
├── reports/, research_notes/      # Product and design research
└── icons/
```

---

## Acknowledgments

- **[ZhuLinsen/daily_stock_analysis](https://github.com/ZhuLinsen/daily_stock_analysis)**: an open-source daily stock analysis tool. It was a valuable reference for the structured AI analysis, the fundamental metrics and the sentiment patterns. Many thanks to the author for sharing it.
- **[Source Han Serif](https://github.com/adobe-fonts/source-han-serif)** by Adobe, used under the SIL Open Font License 1.1 (the bundled subsets are renamed "Orion Serif" as the license requires).

---

## License

**All Rights Reserved.**

Copyright &copy; 2025 Github@WilliamGuo2002. All rights reserved.

This software and associated documentation files are proprietary and confidential. No part of this software may be reproduced, distributed, or transmitted in any form or by any means without the prior written permission of the copyright holder.

Unauthorized copying, modification, merging, publishing, distribution, sublicensing, or sale of this software is strictly prohibited.

The bundled fonts in `Resources/Fonts` are licensed separately under the SIL Open Font License 1.1 (see `SourceHanSerif-OFL.txt`).

---

---

<a id="中文版"></a>

<p align="center">
  <img src="icons/4887BBCA-6D35-440B-A3A9-EA936D1F2C1E.png" alt="Orion Finance 横幅" width="100%">
</p>

# Orion Finance（猎户座金融）

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-iOS%2018.5+-000000?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-007AFF?logo=swift&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?logo=google&logoColor=white)
![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

**一款沉静、亲切的 iOS 应用：管理净资产、投资和税务，由 AI 为你讲解。**

> SwiftUI 构建 | Google Gemini 驱动 | 加拿大制造

[**English Version**](#orion-finance)

---

## 概述

Orion Finance 最初的想法，是让刚入门的人接触美股时不那么害怕。现在它已经成长为一款个人资产管理应用：把券商和银行账户汇总成一个净资产数字，按加拿大税务规则追踪成本基础和资本利得，并由内置的 AI「Orion」用大白话解释你看到的内容。

Orion 只负责解释，从不交易，应用里没有下单功能。需要买卖时，它会把你带到你自己的券商。

所有进阶功能对所有人开放。引导时只问一个问题：「你对投资有多熟悉？」答案只用来设定合适的默认值，比如显示折线图还是蜡烛图，以及 Orion 解释得多详细。

---

## 功能特色

### 净资产与账户连接
- **券商账户**通过 SnapTrade 只读连接（如 Wealthsimple、Questrade），可查看账户、持仓和现金
- **银行账户**通过 Plaid 只读读取余额，涵盖支票、储蓄、信用卡和贷款，不读取交易流水
- 净资产图表使用每晚快照记录的真实历史，可按机构拆分
- 可切换 USD 或 CAD 显示，一键**隐藏金额**
- 同步健康提示：连接需要重新授权或数据过期时，会显示横幅提醒
- 所有服务商密钥只存放在服务器（Firebase Cloud Functions）上，App 端拿不到

### 税务助手（加拿大）
- **TFSA / RRSP / FHSA**：今年的供款与可用额度对比
- **调整后成本基础（ACB）**：同一证券在所有非注册账户之间合并计算。每笔交易按成交当天的加拿大央行汇率换算成加元，佣金计入成本。
- **按年份的资本利得**：每笔卖出的收入、ACB、费用和盈亏，可导出 CSV，用来填 Schedule 3
- **表面亏损（Superficial loss）**：给出提醒，并把按比例计算出的被拒亏损加回持仓池的 ACB
- 从其他券商转入的股票：只需输入一次原始成本，所有数字会自动重新计算
- 仅供参考，不构成税务建议

### 行情与图表
- 股票、ETF、加密货币、外汇、贵金属、大宗商品
- 时间范围从 1 天到全部；滑动图表时，所有数字随手指滚动变化
- **折线图或 Orion 蜡烛图**：上涨为空心、下跌为实心，影线止于实体
- 成交量可选择不显示、单色或红绿双色
- 1 天视图显示昨收虚线，并显示市场状态（开盘、盘前、盘后、休市）
- 今日市场：热门、涨幅榜、跌幅榜

### Orion AI
- 聊股票、聊理财，支持**语音对话**（Gemini Live），可附上图片或文档
- 回答风格随经验程度调整：新手会先解释术语，老手直接给数据
- 每只股票都有**信号概览**：偏积极、中性或偏消极，并列出背后的看多和看空因素。这不是买卖建议，也不给目标价。
- 一键生成新闻摘要

### 学习与练习
- 新用户首页显示「你可能感兴趣」，而不是一片空白
- 根据兴趣和风险偏好推荐股票，另有组合构建向导
- **模拟交易**、股票对比、首次使用时的图表提示
- **在券商中打开**：优先列出已连接的券商，其次是 Wealthsimple、Questrade、IBKR、五大行券商和 Robinhood

### 研究
- 核心指标（市盈率、市净率、增长率、ROE、股息率、Beta、利润率）、52 周区间、分析师评级、同业对比
- **投资大师持仓**，数据来自 SEC 13F 文件（EDGAR）
- 新闻流，可按热门、我的关注、并购交易、加密货币筛选；另有个股新闻
- 个股评论区
- 股价和指数提醒，以及每日市场摘要

### 13 种语言
- English、中文、日本語、한국어、Español、Français、Deutsch、Português、Italiano、Русский、Українська、العربية、עברית、हिन्दी，在应用内切换，无需重启
- 阿拉伯语和希伯来语使用**从右到左布局**，图表和金额仍然保持从左到右
- **Orion Serif**：内置思源宋体子集（SIL OFL 许可），让中文和韩文标题真正以衬线体显示；拉丁和西里尔文字使用 New York

---

## 设计理念

- **沉静而温暖**：焦糖色强调色、扁平卡片，数字不跳动、不喧哗
- iOS 26 上，系统标签栏、悬浮操作栏和磨砂卡片使用 **Liquid Glass**；开启「降低透明度」时改为实色
- 图表区域在滚动时固定不动，卡片从上方滑过，图表随之下沉并变模糊
- 大号数字使用细衬线体和等宽数字
- 支持动态字体、减弱动态效果和 VoiceOver，触控区域不小于 44 pt
- 触感反馈只在操作有结果时出现，可以关闭
- 支持 iPhone（竖屏与横屏）和 iPad（侧边栏）
- `scripts/design_lint.py` 守护设计规范，它统计的违规数量只能减少

---

## 技术栈

| 层级 | 技术 |
|---|---|
| **UI** | SwiftUI、Swift Charts、TipKit |
| **身份验证与数据库** | Firebase Auth（邮箱、Google、Apple）、Cloud Firestore |
| **后端** | Firebase Cloud Functions（TypeScript），见 `firebase/` |
| **账户连接** | SnapTrade（券商）、Plaid Hosted Link（银行） |
| **AI** | Google Gemini 2.5 Flash、Gemini Live（WebSocket） |
| **行情数据** | Yahoo Finance、Finnhub |
| **税务数据** | 加拿大央行 Valet API（每日汇率） |
| **投资大师数据** | SEC EDGAR 13F |
| **后台** | BGTaskScheduler、UNUserNotificationCenter |

---

## 快速开始

### 环境要求
- Xcode 26 或以上（Liquid Glass 相关 API 需要 iOS 26 SDK；应用本身支持 iOS 18.5 及以上）
- 一个 Firebase 项目
- [Finnhub](https://finnhub.io/) 和 [Google Gemini](https://ai.google.dev/) 的 API 密钥（都有免费额度）

### 配置步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/WilliamGuo2002/Equion-for-iOS.git
   ```

2. 新建 `Equion for iOS/Services/APIKeys.swift`。该文件已被 git 忽略，请保持这样：
   ```swift
   import Foundation

   enum APIKeys {
       static let finnhub = "YOUR_FINNHUB_KEY"
       static let gemini = "YOUR_GEMINI_KEY"
   }
   ```

3. 从 [Firebase 控制台](https://console.firebase.google.com/) 下载 `GoogleService-Info.plist` 并加入项目（同样被 git 忽略）。

4. 可选：如需连接券商和银行，请按 [`firebase/README.md`](firebase/README.md) 部署 Cloud Functions。不部署时其他功能照常可用，包括访客模式。

5. 用 Xcode 打开 `Equion for iOS.xcodeproj`，在 Signing & Capabilities 中选择你的开发团队，然后运行。

### 测试与检查
- 单元测试（包括 ACB 和资本利得计算引擎）：在 Xcode 中运行 **Equion for iOSTests**（⌘U）
- 设计规范检查：
  ```bash
  python3 scripts/design_lint.py
  ```

---

## 致谢

- **[ZhuLinsen/daily_stock_analysis](https://github.com/ZhuLinsen/daily_stock_analysis)**：一个开源的每日股票分析工具，为我们的结构化 AI 分析、基本面指标和情绪分析思路提供了宝贵参考。衷心感谢作者的开源分享。
- **[思源宋体（Source Han Serif）](https://github.com/adobe-fonts/source-han-serif)**：由 Adobe 发布，按 SIL Open Font License 1.1 使用。按许可要求，内置的子集已改名为「Orion Serif」。

---

## 版权声明

**保留所有权利。**

Copyright &copy; 2025 Github@WilliamGuo2002. 保留所有权利。

本软件及相关文档为专有机密信息。未经版权所有者事先书面许可，不得以任何形式或方式复制、分发或传播本软件的任何部分。

严禁未经授权的复制、修改、合并、发布、分发、再许可或销售本软件。

`Resources/Fonts` 中的内置字体单独采用 SIL Open Font License 1.1 授权（见 `SourceHanSerif-OFL.txt`）。
