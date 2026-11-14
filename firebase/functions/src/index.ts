/**
 * Orion Finance — SnapTrade brokerage linking (READ-ONLY).
 *
 * The iOS app never sees SnapTrade API keys or the per-user SnapTrade secret.
 * It calls these callable functions with its Firebase ID token; the functions
 * hold the keys (Secret Manager) and talk to SnapTrade on the user's behalf.
 *
 *   snaptradeconnect    → returns a one-time Connection Portal URL (read-only)
 *   snaptradesync       → returns connections + all accounts (investment, bank deposit,
 *                         credit line, mortgage…) + positions + cash
 *   snaptradedisconnect → removes one brokerage connection
 *
 * Function names are lowercase on purpose: Cloud Functions (2nd gen) URLs are
 * case-sensitive and lowercase avoids any mismatch with the iOS client.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions, logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Snaptrade, SnaptradeAuth, SnaptradeError } from "snaptrade-typescript-sdk";
import type { Account, AccountPosition, Balance, BrokerageAuthorization } from "snaptrade-typescript-sdk";
import { ENCRYPTION_KEY as SNAPTRADE_ENCRYPTION_KEY, requireUid, encrypt, decrypt } from "./shared";
import { plaidAccountValues, plaidSecrets } from "./plaid";

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const SNAPTRADE_CLIENT_ID = defineSecret("SNAPTRADE_CLIENT_ID");
const SNAPTRADE_CONSUMER_KEY = defineSecret("SNAPTRADE_CONSUMER_KEY");
const secrets = [SNAPTRADE_CLIENT_ID, SNAPTRADE_CONSUMER_KEY, SNAPTRADE_ENCRYPTION_KEY];

/** Where the Connection Portal sends the user when done. Caught by ASWebAuthenticationSession. */
const APP_CALLBACK_URL = "orionfinance://snaptrade";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function snaptradeClient() {
  return new Snaptrade({
    auth: SnaptradeAuth.commercialApiKey({
      clientId: SNAPTRADE_CLIENT_ID.value(),
      consumerKey: SNAPTRADE_CONSUMER_KEY.value(),
    }),
  });
}

/** Server-only document. Firestore rules must deny client access to `snaptradeUsers`. */
const credsDoc = (uid: string) => getFirestore().collection("snaptradeUsers").doc(uid);

interface SnapCreds { userId: string; userSecret: string }

async function loadCreds(uid: string): Promise<SnapCreds | null> {
  const snap = await credsDoc(uid).get();
  const data = snap.data();
  if (!data?.userId || !data?.secretCipher) return null;
  return { userId: data.userId as string, userSecret: decrypt(data.secretCipher as string) };
}

/** Registers the Firebase user with SnapTrade on first connect. userId = Firebase uid (no PII). */
async function loadOrRegisterCreds(snaptrade: ReturnType<typeof snaptradeClient>, uid: string): Promise<SnapCreds> {
  const existing = await loadCreds(uid);
  if (existing) return existing;

  const res = await snaptrade.authentication.registerSnapTradeUser({ userId: uid });
  const userId = res.data.userId;
  const userSecret = res.data.userSecret;
  if (!userId || !userSecret) throw new HttpsError("internal", "SnapTrade registration returned no credentials.");

  await credsDoc(uid).set({
    userId,
    secretCipher: encrypt(userSecret),
    createdAt: FieldValue.serverTimestamp(),
  });
  return { userId, userSecret };
}

/** Never leak SnapTrade internals or secrets to the client; log details server-side. */
function toHttpsError(err: unknown, context: string): HttpsError {
  if (err instanceof HttpsError) return err;
  if (err instanceof SnaptradeError) {
    logger.error(`${context}: SnapTrade ${err.status}`, { status: err.status, body: err.responseBody });
    if (err.status === 401 || err.status === 403) {
      return new HttpsError("failed-precondition", "Brokerage service rejected the request. Check the server's SnapTrade keys.");
    }
    if (err.status === 429) return new HttpsError("resource-exhausted", "Too many requests. Please try again shortly.");
    return new HttpsError("unavailable", "The brokerage service is unavailable. Please try again.");
  }
  logger.error(`${context}: unexpected error`, err);
  return new HttpsError("internal", "Something went wrong. Please try again.");
}

// ---------------------------------------------------------------------------
// Normalizers — the iOS app decodes exactly these shapes.
// ---------------------------------------------------------------------------

function num(v: unknown): number | null {
  return typeof v === "number" && Number.isFinite(v) ? v : null;
}

function normalizeConnection(c: BrokerageAuthorization) {
  return {
    id: c.id ?? "",
    brokerageName: c.brokerage?.display_name ?? c.brokerage?.name ?? c.name ?? "Brokerage",
    disabled: c.disabled ?? false,
  };
}

/** Numbers arrive as numbers or numeric strings depending on the endpoint. */
function numish(v: unknown): number | null {
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

/** Kinds we can price with a ticker. Derivatives (options, futures, CFDs…) are not. */
const PRICEABLE = new Set(["stock", "etf", "adr", "cef", "mutualfund", "preferred_stock", "crypto", "other", "bond"]);

/**
 * Yahoo-style ticker so the app can fetch live quotes:
 * Canadian listings get an exchange suffix, crypto becomes "BTC-CAD".
 */
function quoteSymbol(kind: string, symbol: string, raw: string, exchange: string | null, currency: string): string {
  if (kind === "crypto") return `${(raw || symbol).toUpperCase()}-${currency}`;
  if (symbol.includes(".")) return symbol;
  const ex = (exchange ?? "").toUpperCase();
  if (ex.includes("TSXV") || ex === "XTSX" || ex === "CDNX") return `${symbol}.V`;
  if (ex.includes("TSX") || ex === "XTSE" || ex === "TO") return `${symbol}.TO`;
  if (ex.includes("NEO") || ex.includes("CBOE CANADA") || ex === "NEOE") return `${symbol}.NE`;
  if (ex.includes("CSE") || ex === "XCNQ") return `${symbol}.CN`;
  return symbol;
}

function normalizePositions(results: AccountPosition[]) {
  let unpriced = 0;
  const positions = results.flatMap((p) => {
    const inst = p.instrument as unknown as Record<string, unknown>;
    const kind = String(inst.kind ?? "");
    const units = numish(p.units) ?? 0;
    if (kind === "cash" || Math.abs(units) < 1e-9) return [];
    // Counted in the cash balance already — skip so it isn't added twice.
    if (p.cash_equivalent === true) return [];
    const symbol = typeof inst.symbol === "string" ? inst.symbol : "";
    if (!PRICEABLE.has(kind) || !symbol) { unpriced++; return []; }
    const raw = typeof inst.raw_symbol === "string" ? inst.raw_symbol : symbol;
    const currency = (p.currency ?? (inst.currency as string | null) ?? "USD").toUpperCase();
    return [{
      symbol: quoteSymbol(kind, symbol, raw, (inst.exchange as string | null) ?? null, currency),
      displaySymbol: raw || symbol,
      kind,
      description: (inst.description as string | null) ?? null,
      units,
      averageCost: numish(p.cost_basis),
      price: numish(p.price),
      currency,
    }];
  });
  return { positions, unpriced };
}

function normalizeCash(balances: Balance[]) {
  return balances.flatMap((b) => {
    const amount = numish(b.cash);
    const currency = b.currency?.code;
    return amount === null || !currency ? [] : [{ currency: currency.toUpperCase(), amount }];
  });
}

type AccountBase = {
  id: string;
  connectionId: string | null;
  kind: string;
  name: string;
  number: string | null;
  netValue: number | null;
  currency: string;
  /** Institution's account type, e.g. "TFSA", "RRSP", "Non-registered" (used for tax features). */
  rawType: string | null;
  /** Last successful sync reported by SnapTrade (ISO 8601). */
  syncedAt: string | null;
};

/** New unified account list (all kinds), with the legacy investment-only list as a fallback. */
async function listAccounts(snaptrade: ReturnType<typeof snaptradeClient>, creds: { userId: string; userSecret: string }): Promise<AccountBase[]> {
  try {
    const res = await snaptrade.accountInformation.listAllUserAccounts(creds);
    return res.data.results
      .map((a) => a as unknown as Record<string, unknown>)
      .filter((a) => a.status !== "closed" && a.status !== "archived")
      .map((a) => {
        const nv = (a.net_value ?? null) as { amount?: number | null; currency?: string | null } | null;
        const kind = String(a.kind ?? "investment");
        const sync = (a.sync_status ?? null) as { positions?: string | null; balances?: string | null } | null;
        return {
          id: String(a.id),
          connectionId: (a.connection_id as string | undefined) ?? null,
          kind,
          name: (a.display_name as string | null) ?? (a.raw_type as string | null) ?? defaultName(kind),
          number: (a.masked_account_number as string | undefined) ?? null,
          netValue: numish(nv?.amount),
          currency: (nv?.currency ?? "USD").toUpperCase(),
          rawType: (a.raw_type as string | null) ?? null,
          syncedAt: sync?.positions ?? sync?.balances ?? null,
        };
      });
  } catch (err) {
    logger.warn("snaptradesync: listAllUserAccounts failed, using legacy list", { reason: String(err) });
    const res = await snaptrade.accountInformation.listUserAccounts(creds);
    return res.data.map((a: Account) => ({
      id: a.id,
      connectionId: a.brokerage_authorization ?? null,
      kind: "investment",
      name: a.name ?? "Account",
      number: a.number ?? null,
      netValue: num(a.balance?.total?.amount),
      currency: (a.balance?.total?.currency ?? "USD").toUpperCase(),
      rawType: (a.raw_type as string | null | undefined) ?? null,
      syncedAt: null,
    }));
  }
}

function defaultName(kind: string): string {
  switch (kind) {
    case "deposit": return "Bank Account";
    case "line_of_credit": return "Line of Credit";
    case "mortgage": return "Mortgage";
    case "annuity": return "Annuity";
    default: return "Account";
  }
}

// ---------------------------------------------------------------------------
// Callable functions
// ---------------------------------------------------------------------------

/**
 * data: { reconnect?: string }  — pass a disabled connection's id to re-authorize it.
 * returns: { redirectURI: string }
 */
export const snaptradeconnect = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  try {
    const snaptrade = snaptradeClient();
    const { userId, userSecret } = await loadOrRegisterCreds(snaptrade, uid);
    const reconnect = typeof req.data?.reconnect === "string" && req.data.reconnect ? req.data.reconnect : undefined;

    const res = await snaptrade.authentication.loginSnapTradeUser({
      userId,
      userSecret,
      connectionType: "read",          // read-only: Orion can never place trades
      immediateRedirect: true,
      customRedirect: APP_CALLBACK_URL,
      reconnect,
    });
    const redirectURI = (res.data as { redirectURI?: string }).redirectURI;
    if (!redirectURI) throw new HttpsError("internal", "No connection link was returned.");
    return { redirectURI };
  } catch (err) {
    throw toHttpsError(err, "snaptradeconnect");
  }
});

/**
 * returns: { connections: [...], accounts: [...] }  (empty arrays if never connected)
 */
export const snaptradesync = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  try {
    const creds = await loadCreds(uid);
    if (!creds) return { connections: [], accounts: [] };

    const snaptrade = snaptradeClient();
    const [connRes, baseAccounts] = await Promise.all([
      snaptrade.connections.listBrokerageAuthorizations(creds),
      listAccounts(snaptrade, creds),
    ]);
    const connections = connRes.data.map(normalizeConnection);
    const institutionOf = new Map(connections.map((c) => [c.id, c.brokerageName]));

    // Positions + cash only exist for investment accounts. One failing account must not hide the others.
    const accounts = await Promise.all(baseAccounts.map(async (a) => {
      const common = {
        id: a.id,
        connectionId: a.connectionId,
        kind: a.kind,
        name: a.name,
        number: a.number,
        institution: (a.connectionId && institutionOf.get(a.connectionId)) || "Institution",
        totalValue: a.netValue,
        currency: a.currency,
        rawType: a.rawType,
        asOf: a.syncedAt,
      };
      if (a.kind !== "investment") {
        return { ...common, cash: [], positions: [], unpricedPositions: 0, error: null };
      }
      const [posRes, balRes] = await Promise.allSettled([
        snaptrade.accountInformation.getAllAccountPositions({ ...creds, accountId: a.id }),
        snaptrade.accountInformation.getUserAccountBalance({ ...creds, accountId: a.id }),
      ]);
      if (posRes.status === "rejected") {
        logger.warn("snaptradesync: positions failed", { accountId: a.id, reason: String(posRes.reason) });
      }
      if (balRes.status === "rejected") {
        logger.warn("snaptradesync: balances failed", { accountId: a.id, reason: String(balRes.reason) });
      }
      const pos = posRes.status === "fulfilled"
        ? normalizePositions(posRes.value.data.results ?? [])
        : { positions: [], unpriced: 0 };
      return {
        ...common,
        // How fresh SnapTrade's copy of this account is (it caches brokerage data daily).
        asOf: (posRes.status === "fulfilled" ? posRes.value.data.data_freshness?.as_of : null) ?? a.syncedAt,
        cash: balRes.status === "fulfilled" ? normalizeCash(balRes.value.data ?? []) : [],
        positions: pos.positions,
        unpricedPositions: pos.unpriced,
        // Without positions or cash the app falls back to the account's total value.
        error: posRes.status === "rejected" || balRes.status === "rejected"
          ? "Couldn't load holdings for this account."
          : null,
      };
    }));

    return { connections, accounts };
  } catch (err) {
    throw toHttpsError(err, "snaptradesync");
  }
});

/**
 * data: { connectionId: string }
 * returns: { ok: true }
 */
export const snaptradedisconnect = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  const connectionId = req.data?.connectionId;
  if (typeof connectionId !== "string" || !connectionId) {
    throw new HttpsError("invalid-argument", "connectionId is required.");
  }
  try {
    const creds = await loadCreds(uid);
    if (!creds) return { ok: true };
    // SnapTrade scopes the connection to this user's credentials, so a user can only remove their own.
    await snaptradeClient().connections.deleteConnection({ ...creds, connectionId });
    return { ok: true };
  } catch (err) {
    throw toHttpsError(err, "snaptradedisconnect");
  }
});

/** Activity types the app uses for contribution tracking and the superficial-loss check. */
const ACTIVITY_TYPES = new Set([
  "BUY", "SELL", "REI", "CONTRIBUTION", "WITHDRAWAL", "TRANSFER",
  "EXTERNAL_ASSET_TRANSFER_IN", "EXTERNAL_ASSET_TRANSFER_OUT", "SPLIT",
]);

/**
 * Trades and contributions for every investment account (read-only).
 * data: { since?: "YYYY-MM-DD" }  — default: all available history (needed to rebuild cost bases).
 * returns: { activities: [...] }
 */
export const snaptradeactivities = onCall({ secrets, timeoutSeconds: 120 }, async (req) => {
  const uid = requireUid(req);
  const since = typeof req.data?.since === "string" && /^\d{4}-\d{2}-\d{2}$/.test(req.data.since)
    ? req.data.since as string : undefined;
  try {
    const creds = await loadCreds(uid);
    if (!creds) return { activities: [] };
    const snaptrade = snaptradeClient();
    const accounts = (await listAccounts(snaptrade, creds)).filter((a) => a.kind === "investment");

    const perAccount = await Promise.allSettled(accounts.map(async (a) => {
      const out: Record<string, unknown>[] = [];
      const limit = 1000;
      // Paginated, newest first. Cap at 10 pages per account to bound the call.
      for (let page = 0; page < 10; page++) {
        const res = await snaptrade.accountInformation.getAccountActivities({
          ...creds, accountId: a.id, startDate: since, offset: page * limit, limit,
        });
        const rows = res.data.data ?? [];
        for (const r of rows) {
          const type = String(r.type ?? "").toUpperCase();
          if (!ACTIVITY_TYPES.has(type)) continue;
          out.push({
            id: r.id ?? `${a.id}-${page}-${out.length}`,
            accountId: a.id,
            type,
            date: (r.trade_date ?? r.settlement_date ?? "").slice(0, 10),
            symbol: r.symbol?.raw_symbol ?? r.symbol?.symbol ?? null,
            units: num(r.units),
            price: num(r.price),
            amount: num(r.amount),
            currency: (r.currency?.code ?? r.symbol?.currency?.code ?? "CAD").toUpperCase(),
            fee: num(r.fee),
          });
        }
        const total = res.data.pagination?.total ?? 0;
        if (rows.length < limit || (page + 1) * limit >= total) break;
      }
      return out;
    }));

    const activities = perAccount.flatMap((r, i) => {
      if (r.status === "fulfilled") return r.value;
      logger.warn("snaptradeactivities: failed", { accountId: accounts[i].id, reason: String(r.reason) });
      return [];
    });
    return { activities };
  } catch (err) {
    throw toHttpsError(err, "snaptradeactivities");
  }
});

// ---------------------------------------------------------------------------
// Nightly net-worth snapshot (real history for the chart)
// ---------------------------------------------------------------------------

/** Bank of Canada daily rates → multiplier from `currency` to USD. */
async function fxToUSDRates(currencies: Set<string>): Promise<Map<string, number>> {
  const rates = new Map<string, number>([["USD", 1]]);
  const valet = async (series: string): Promise<number | null> => {
    try {
      const res = await fetch(`https://www.bankofcanada.ca/valet/observations/${series}/json?recent=1`);
      if (!res.ok) return null;
      const body = await res.json() as { observations?: Array<Record<string, { v?: string }>> };
      const v = Number(body.observations?.[0]?.[series]?.v);
      return Number.isFinite(v) && v > 0 ? v : null;
    } catch { return null; }
  };
  const usdcad = await valet("FXUSDCAD");          // CAD per 1 USD
  if (!usdcad) return rates;
  rates.set("CAD", 1 / usdcad);
  for (const cur of currencies) {
    if (rates.has(cur)) continue;
    const toCad = await valet(`FX${cur}CAD`);       // CAD per 1 unit
    if (toCad) rates.set(cur, toCad / usdcad);
  }
  return rates;
}

function torontoDate(d = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "America/Toronto" }).format(d);   // YYYY-MM-DD
}

const DEBT_KINDS = new Set(["line_of_credit", "mortgage"]);

/**
 * Every night, store each linked user's net worth by institution in
 * users/{uid}/netWorthSnapshots/{YYYY-MM-DD} — so the chart shows real balances over time,
 * even on days the app isn't opened. Uses the institutions' own daily values.
 */
export const networthsnapshot = onSchedule({
  schedule: "every day 23:30",
  timeZone: "America/Toronto",
  timeoutSeconds: 540,
  secrets: [...secrets, ...plaidSecrets],
}, async () => {
  const db = getFirestore();
  const [snapUsers, plaidUsers] = await Promise.all([
    db.collection("snaptradeUsers").listDocuments(),
    db.collection("plaidUsers").listDocuments(),
  ]);
  const uids = [...new Set([...snapUsers, ...plaidUsers].map((d) => d.id))];
  const date = torontoDate();
  let written = 0;

  for (const uid of uids) {
    try {
      // Raw account values in native currency: [institution, amount, currency, mask]
      const rows: Array<{ inst: string; amount: number; currency: string; mask: string | null; bank: boolean }> = [];

      const creds = await loadCreds(uid);
      if (creds) {
        const snaptrade = snaptradeClient();
        const [connRes, accounts] = await Promise.all([
          snaptrade.connections.listBrokerageAuthorizations(creds),
          listAccounts(snaptrade, creds),
        ]);
        const instOf = new Map(connRes.data.map(normalizeConnection).map((c) => [c.id, c.brokerageName]));
        for (const a of accounts) {
          if (a.netValue === null) continue;
          rows.push({
            inst: (a.connectionId && instOf.get(a.connectionId)) || "Institution",
            amount: DEBT_KINDS.has(a.kind) ? -Math.abs(a.netValue) : a.netValue,
            currency: a.currency,
            mask: a.number ? a.number.replace(/[^0-9A-Za-z]/g, "").slice(-4) : null,
            bank: false,
          });
        }
      }
      for (const b of await plaidAccountValues(uid)) {
        rows.push({ inst: b.institution, amount: b.netValue, currency: b.currency, mask: b.mask, bank: true });
      }
      if (rows.length === 0) continue;

      // Same account linked through both services → count it once (mirrors the app).
      const firstWord = (s: string) => s.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean)[0] ?? "";
      const brokerRows = rows.filter((r) => !r.bank);
      const kept = rows.filter((r) => !r.bank || !r.mask ||
        !brokerRows.some((x) => x.mask === r.mask && firstWord(x.inst) === firstWord(r.inst)));

      const fx = await fxToUSDRates(new Set(kept.map((r) => r.currency)));
      const institutions: Record<string, number> = {};
      for (const r of kept) {
        const rate = fx.get(r.currency);
        if (rate === undefined) continue;
        institutions[r.inst] = (institutions[r.inst] ?? 0) + r.amount * rate;
      }
      const totalUSD = Object.values(institutions).reduce((a, b) => a + b, 0);

      await db.collection("users").doc(uid).collection("netWorthSnapshots").doc(date).set({
        date, totalUSD, institutions, source: "server", updatedAt: FieldValue.serverTimestamp(),
      });
      written++;
    } catch (err) {
      logger.warn("networthsnapshot: user failed", { uid, reason: String(err) });
    }
  }
  logger.info("networthsnapshot: done", { users: uids.length, written });
});

// Bank accounts (chequing, savings, credit cards, loans) via Plaid
export * from "./plaid";
