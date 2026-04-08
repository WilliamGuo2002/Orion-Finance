# Orion Finance

**A modern iOS stock portfolio & AI-powered investment assistant.**

> Built with SwiftUI | Powered by Google Gemini | Real-time Market Data

[**中文版**](#中文版)

---

## Overview

Orion Finance is a feature-rich iOS application designed to make stock investing accessible and intelligent. It combines real-time market data, AI-driven analysis, and a clean interface to help investors make informed decisions — whether you're a seasoned trader or just getting started.

---

## Features

### Real-Time Market Data
- Live price tracking for **stocks, crypto, forex, precious metals, and commodities**
- Interactive charts with multiple timeframes (1D, 5D, 1M, 6M, YTD, 1Y, ALL)
- Touch-enabled chart exploration with precise data point tracking
- Market status indicator (Open / Pre-Market / After-Hours / Closed)
- Today's Market overview: **Hot**, **Gainers**, and **Losers** tabs

### AI Decision Dashboard
- One-tap AI analysis powered by **Google Gemini**
- Structured output: **Buy / Watch / Sell** rating with confidence score (0–100)
- Suggested entry price, stop-loss, and target price
- Bullish & bearish factor breakdown
- Market sentiment gauge with visual indicator
- Results cached (1h) to minimize API usage

### Orion AI Chat Assistant
- Conversational AI for financial questions and stock research
- **Voice conversation** — real-time audio input/output via Gemini Live API
- **Photo & document analysis** — attach images or files for AI review
- Multi-turn conversation with session history
- Markdown-rendered responses

### Fundamental Analysis
- Key financial metrics: P/E, P/B, EPS Growth, Revenue Growth, ROE, Dividend Yield, Beta, Debt/Equity, Gross Margin, Operating Margin
- 52-week high/low range
- Analyst recommendations (Strong Buy → Strong Sell)
- Peer stock comparison
- Data cached (4h) for efficiency

### Famous Investor Portfolios
- Track holdings of legendary investors: **Warren Buffett, Michael Burry, Bill Ackman, Ray Dalio, George Soros**, and more
- Real-time SEC 13F filing data from **EDGAR**
- Portfolio composition with holding details (value, shares, weight)

### Smart Notifications
- Background stock price monitoring via `BGAppRefreshTask`
- Major index alerts (S&P 500, NASDAQ, Dow Jones) with customizable thresholds
- Watchlist price movement alerts
- Daily market summary push notification
- Rate-limited to avoid notification spam (30-min cooldown per symbol)

### Personalized Experience
- Interest-based onboarding across 14 categories (Tech, Finance, Healthcare, Energy, Crypto, Forex, ETFs, Dividends, and more)
- AI-powered stock recommendations based on selected interests
- Personalized news feed

### News & Research
- Real-time financial news feed
- Company-specific news articles
- AI-powered article summarization via context menu
- In-app article reading with share functionality

### Community
- Stock-specific comment sections
- User discussion on individual tickers

### Internationalization
- **12 languages** supported with runtime switching (no restart required):
  English, 中文, 日本語, 한국어, Español, Fran&ccedil;ais, Deutsch, Portugu&ecirc;s, Italiano, Русский, العربية, हिन्दी
- CJK-optimized serif typography (Songti, Hiragino Mincho, Apple Myungjo)
- System serif (New York) for Latin and Cyrillic scripts

---

## Design

- **Warm, approachable aesthetic** — earthy caramel accent tones with a frosted glass card system
- Light & Dark mode with full theme adaptation
- Interactive card animations: press-to-sink with shadow response and gloss highlight
- Haptic feedback throughout the interface
- Responsive layouts for iPhone (portrait & landscape) and iPad (sidebar navigation)
- Shimmer skeleton loading states

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | SwiftUI |
| **Authentication** | Firebase Auth (Email, Google, Apple Sign-In) |
| **Database** | Cloud Firestore |
| **AI Engine** | Google Gemini API + Gemini Live (WebSocket) |
| **Market Data** | Yahoo Finance API, Finnhub API |
| **Background Tasks** | BGTaskScheduler |
| **Notifications** | UNUserNotificationCenter (local push) |
| **Caching** | Actor-based in-memory cache + disk cache with TTL |

---

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Active API keys (see below)

### Setup

1. Clone the repository:
   ```bash
<<<<<<< HEAD
   git clone https://github.com/YOUR_USERNAME/Equion-for-iOS.git
=======
   git clone https://github.com/WilliamGuo2002/Equion-for-iOS.git
>>>>>>> 9987772ab937885b8f145f2a96712e4df9e7c7cc
   ```

2. Create `APIKeys.swift` from the template:
   ```bash
   cp "Equion for iOS/Services/APIKeys.example.swift" "Equion for iOS/Services/APIKeys.swift"
   ```

3. Fill in your API keys in `APIKeys.swift`:
   - [Finnhub](https://finnhub.io/) — free tier available
   - [Twelve Data](https://twelvedata.com/) — free tier available
   - [Google Gemini](https://ai.google.dev/) — free tier available

4. Add your `GoogleService-Info.plist` from [Firebase Console](https://console.firebase.google.com/)

5. Open `Equion for iOS.xcodeproj` in Xcode, select your team under Signing & Capabilities, and run.

---

## Project Structure

```
Equion for iOS/
├── Models/              # Data models (Stock, Chart, News, Investor, etc.)
├── Services/
│   ├── APIService.swift          # Market data & AI API integration
│   ├── APIKeys.swift             # API keys (git-ignored)
│   ├── AppTheme.swift            # Design system & interactive card modifiers
│   ├── FirebaseController.swift  # Auth & Firestore management
│   ├── GeminiLiveService.swift   # Real-time voice AI (WebSocket)
│   ├── NotificationService.swift # Background monitoring & push alerts
│   ├── SettingsManager.swift     # User preferences & app state
│   ├── Localization.swift        # 12-language translation engine
│   └── ...
├── Views/
│   ├── MyHoldingView.swift       # Watchlist & market overview
│   ├── StockDetailView.swift     # Stock analysis & AI dashboard
│   ├── ChatView.swift            # Orion AI assistant
│   ├── NewsView.swift            # Financial news feed
│   ├── InvestorsView.swift       # Famous investor portfolios
│   ├── MenuView.swift            # Settings & preferences
│   └── Components/               # Reusable UI components
└── Assets.xcassets/              # App icons, colors, images
```

---

## Acknowledgments

This project was inspired by and references ideas from the following open-source project:

- **[ZhuLinsen/daily_stock_analysis](https://github.com/ZhuLinsen/daily_stock_analysis)** — An open-source daily stock analysis tool that provided valuable reference for our AI-driven analysis features, including the structured decision dashboard approach, fundamental metrics integration, and market sentiment analysis patterns. We sincerely thank the author for sharing their work with the community.

---

## License

**All Rights Reserved.**

<<<<<<< HEAD
Copyright &copy; 2025 Orion Finance. All rights reserved.
=======
Copyright &copy; 2025 Github@WilliamGuo2002. All rights reserved.
>>>>>>> 9987772ab937885b8f145f2a96712e4df9e7c7cc

This software and associated documentation files are proprietary and confidential. No part of this software may be reproduced, distributed, or transmitted in any form or by any means without the prior written permission of the copyright holder.

Unauthorized copying, modification, merging, publishing, distribution, sublicensing, or sale of this software is strictly prohibited.

---

---

<a id="中文版"></a>

# Orion Finance（猎户座金融）

**一款现代化的 iOS 股票投资组合与 AI 智能投资助手。**

> SwiftUI 构建 | Google Gemini 驱动 | 实时行情数据

[**English Version**](#orion-finance)

---

## 概述

Orion Finance 是一款功能丰富的 iOS 应用，旨在让股票投资变得简单而智能。它将实时行情数据、AI 驱动的分析和简洁的界面相结合，帮助投资者做出明智的决策 — 无论你是经验丰富的交易者还是刚刚入门的新手。

---

## 功能特色

### 实时行情数据
- 支持**股票、加密货币、外汇、贵金属和大宗商品**的实时价格追踪
- 可交互式图表，支持多个时间范围（1天、5天、1月、6月、今年、1年、全部）
- 触摸式图表浏览，精确显示数据点信息
- 市场状态指示器（开盘 / 盘前 / 盘后 / 休市）
- 今日市场概览：**热门**、**涨幅榜**、**跌幅榜** 标签页

### AI 决策仪表盘
- 一键 AI 分析，由 **Google Gemini** 驱动
- 结构化输出：**买入 / 观望 / 卖出** 评级 + 信心评分（0–100）
- 建议入场价、止损位和目标价
- 看多与看空因素详细分解
- 市场情绪仪表盘（可视化指标）
- 结果缓存 1 小时，减少 API 调用

### Orion AI 聊天助手
- 对话式 AI，回答金融问题和股票研究
- **语音对话** — 通过 Gemini Live API 实现实时语音输入输出
- **图片与文档分析** — 上传图片或文件供 AI 分析
- 支持多轮对话与会话历史
- Markdown 渲染的回复内容

### 基本面分析
- 核心财务指标：市盈率、市净率、EPS 增长率、营收增长率、ROE、股息收益率、Beta、负债权益比、毛利率、营业利润率
- 52 周最高/最低价
- 分析师推荐（强烈买入 → 强烈卖出）
- 同业股票对比
- 数据缓存 4 小时

### 著名投资大师持仓
- 追踪传奇投资者的持仓：**沃伦·巴菲特、迈克尔·伯里、比尔·阿克曼、瑞·达利欧、乔治·索罗斯**等
- 来自 **SEC EDGAR** 的实时 13F 文件数据
- 持仓组合详情（市值、股数、权重）

### 智能通知推送
- 通过 `BGAppRefreshTask` 后台监控股价
- 主要指数提醒（标普500、纳斯达克、道琼斯），阈值可自定义
- 关注股票价格波动提醒
- 每日市场摘要推送
- 防骚扰机制：同一股票 30 分钟内不重复推送

### 个性化体验
- 基于兴趣的引导流程，覆盖 14 个类别（科技、金融、医疗、能源、加密货币、外汇、ETF、高股息等）
- AI 驱动的个性化选股推荐
- 个性化新闻推送

### 新闻与研究
- 实时金融新闻
- 个股相关新闻
- AI 驱动的文章摘要（长按快速生成）
- 应用内阅读，支持分享

### 社区互动
- 个股评论区
- 用户讨论功能

### 国际化
- 支持 **12 种语言**，运行时切换（无需重启）：
  English、中文、日本語、한국어、Espa&ntilde;ol、Fran&ccedil;ais、Deutsch、Portugu&ecirc;s、Italiano、Русский、العربية、हिन्दी
- CJK 优化的衬线字体（宋体、ヒラギノ明朝、애플명조）
- 拉丁/西里尔文使用系统衬线字体（New York）

---

## 设计理念

- **温暖、友好的视觉风格** — 大地色焦糖系强调色，毛玻璃质感卡片系统
- 明暗模式完整适配
- 交互式卡片动画：按压下沉、阴影联动、光泽高光
- 全界面触觉反馈
- 自适应布局：iPhone（竖屏与横屏）和 iPad（侧边栏导航）
- 骨架屏加载动画

---

## 技术栈

| 层级 | 技术 |
|---|---|
| **UI 框架** | SwiftUI |
| **身份验证** | Firebase Auth（邮箱、Google、Apple 登录） |
| **数据库** | Cloud Firestore |
| **AI 引擎** | Google Gemini API + Gemini Live（WebSocket） |
| **行情数据** | Yahoo Finance API、Finnhub API |
| **后台任务** | BGTaskScheduler |
| **通知推送** | UNUserNotificationCenter（本地推送） |
| **缓存系统** | Actor 线程安全内存缓存 + 磁盘缓存（TTL 机制） |

---

## 快速开始

### 环境要求
- Xcode 15.0+
- iOS 17.0+
- 有效的 API 密钥（见下方）

### 配置步骤

1. 克隆仓库：
   ```bash
<<<<<<< HEAD
   git clone https://github.com/YOUR_USERNAME/Equion-for-iOS.git
=======
   git clone https://github.com/WilliamGuo2002/Equion-for-iOS.git
>>>>>>> 9987772ab937885b8f145f2a96712e4df9e7c7cc
   ```

2. 从模板创建 `APIKeys.swift`：
   ```bash
   cp "Equion for iOS/Services/APIKeys.example.swift" "Equion for iOS/Services/APIKeys.swift"
   ```

3. 在 `APIKeys.swift` 中填入你的 API 密钥：
   - [Finnhub](https://finnhub.io/) — 有免费额度
   - [Twelve Data](https://twelvedata.com/) — 有免费额度
   - [Google Gemini](https://ai.google.dev/) — 有免费额度

4. 从 [Firebase 控制台](https://console.firebase.google.com/) 添加你的 `GoogleService-Info.plist`

5. 在 Xcode 中打开 `Equion for iOS.xcodeproj`，配置签名团队，运行即可。

---

## 致谢

本项目的部分功能设计参考了以下开源项目：

- **[ZhuLinsen/daily_stock_analysis](https://github.com/ZhuLinsen/daily_stock_analysis)** — 一个开源的每日股票分析工具，为我们的 AI 驱动分析功能提供了宝贵参考，包括结构化决策仪表盘、基本面指标整合和市场情绪分析等设计思路。在此向作者的开源分享表示衷心感谢。

---

## 版权声明

**保留所有权利。**

<<<<<<< HEAD
Copyright &copy; 2025 Orion Finance. 保留所有权利。
=======
Copyright &copy; 2025 Github@WilliamGuo2002. 保留所有权利。
>>>>>>> 9987772ab937885b8f145f2a96712e4df9e7c7cc

本软件及相关文档为专有机密信息。未经版权所有者事先书面许可，不得以任何形式或方式复制、分发或传播本软件的任何部分。

严禁未经授权的复制、修改、合并、发布、分发、再许可或销售本软件。
