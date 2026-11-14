# Orion Finance — 券商账户连接后端(SnapTrade,只读)

iOS App 不保存任何 SnapTrade 密钥。App 带着 Firebase 登录令牌调用这里的 3 个 Cloud Functions,
由它们持有密钥去请求 SnapTrade:

| 函数 | 作用 |
|---|---|
| `snaptradeconnect` | 首次连接时注册 SnapTrade 用户，返回一次性的**只读**连接页面链接 |
| `snaptradesync` | 返回已连接的券商、账户、持仓、现金 |
| `snaptradedisconnect` | 断开某个券商连接 |

每个用户的 SnapTrade `userSecret` 用 AES-256-GCM 加密后存在 Firestore `snaptradeUsers/{uid}`,
从券商拿到的持仓数据**不落库**，只在内存里返回给 App。

## 一次性设置(这些步骤涉及你的账号和密钥，需要你自己操作)

### 1. 拿到 SnapTrade 密钥
在 <https://dashboard.snaptrade.com> 注册，拿到 **Client ID** 和 **Consumer Key**。
在后台确认 **Wealthsimple** 对你的 key 是开启状态。

### 2. Firebase 升级到 Blaze 计划
Firebase 控制台 → 项目 `equion-9463e` → Usage and billing → 升级到 Blaze。
Cloud Functions 和 Secret Manager 需要它(个人用量基本在免费额度内，但要绑卡)。

### 3. 安装并登录 Firebase CLI
```bash
npm install -g firebase-tools
```
```bash
firebase login
```

### 4. 设置三个密钥(在本目录 `firebase/` 下运行，每条会提示你粘贴值)
```bash
firebase functions:secrets:set SNAPTRADE_CLIENT_ID
```
```bash
firebase functions:secrets:set SNAPTRADE_CONSUMER_KEY
```
加密密钥用随机生成的 32 字节，先生成再粘贴进去:
```bash
openssl rand -base64 32
```
```bash
firebase functions:secrets:set SNAPTRADE_ENCRYPTION_KEY
```
> ⚠️ `SNAPTRADE_ENCRYPTION_KEY` 设好后不要再改，改了之前保存的用户凭证就解不开了，用户需要重新连接。

### 5. 部署
```bash
firebase deploy --only functions:snaptrade
```
只部署 `snaptrade` 这个 codebase,不会动项目里其他已有的函数。

### 6. Firestore 安全规则(必须做)
Firebase 控制台 → Firestore → Rules,在 `match /databases/{database}/documents { ... }` 里加上:
```
match /snaptradeUsers/{uid} {
  allow read, write: if false;
}
```
> ⚠️ Firestore 规则是"任一条允许就允许"。如果你现有规则里有类似
> `match /{document=**} { allow read, write: if request.auth != null; }` 的通配规则，
> 上面这条**挡不住**它。那样的话，需要把通配规则收紧成具体的集合。
> (即使被读到，`userSecret` 也是加密的，但仍然建议收紧。)

### 7. 在 App 里测试
**更多 → 券商账户 → 连接券商**,在 SnapTrade 页面里选 Wealthsimple 登录授权。
完成后回到 App,首页图表和持仓页会显示 Wealthsimple 的持仓。

## 本地开发
```bash
cd functions && npm install && npm run build
```
查看线上日志:
```bash
firebase functions:log
```

---

# 银行账户连接(Plaid,只读余额)

代码在 `functions/src/plaid.ts`，函数:`plaidlinktoken`、`plaidcomplete`、`plaidsync`、`plaidremove`。
用的是 Plaid **Hosted Link**:App 用 ASWebAuthenticationSession 打开 Plaid 托管的页面，回调 `orionfinance://plaid`，
所以 iOS 端不需要 Plaid SDK。Plaid `access_token` 只在服务器上，用同一把 `SNAPTRADE_ENCRYPTION_KEY`
加密后存在 Firestore `plaidUsers/{uid}/items/{itemId}`。只调用 `/accounts/get`(缓存余额),不读取交易流水。

## 设置
1. Plaid Dashboard → Developers → Keys，拿到 `client_id` 和 **Sandbox** `secret`。
2. 在本目录设置两个密钥:
   ```bash
   firebase functions:secrets:set PLAID_CLIENT_ID
   firebase functions:secrets:set PLAID_SECRET
   ```
3. 环境在 `functions/.env` 的 `PLAID_ENV`(`sandbox` / `production`)。切到 production 时，
   同时把 `PLAID_SECRET` 换成 production secret，再重新部署。
4. Firestore 规则里加上(和 snaptradeUsers 一样，客户端完全不可访问):
   ```
   match /plaidUsers/{document=**} {
     allow read, write: if false;
   }
   ```
5. 部署:`firebase deploy --only functions:snaptrade`(codebase 名字沿用 snaptrade,里面包含 Plaid 函数)。

## Sandbox 测试
在 App 里 更多 → 关联账户 → 连接银行，选任意测试银行(如 First Platypus Bank),
用户名 `user_good`，密码 `pass_good`。
