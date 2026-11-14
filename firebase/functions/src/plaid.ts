/**
 * Orion Finance — bank account linking via Plaid (READ-ONLY balances).
 *
 * Uses Plaid Hosted Link: the app opens a Plaid-hosted page in ASWebAuthenticationSession,
 * so the iOS app needs no Plaid SDK. Plaid access tokens never leave the server; they are
 * encrypted (AES-256-GCM) in Firestore under plaidUsers/{uid}/items/{itemId}.
 *
 *   plaidlinktoken → { linkToken, url }       start linking (or re-auth with { itemId })
 *   plaidcomplete  → { added }                after the page closes: exchange public tokens
 *   plaidsync      → { items, accounts }      balances for every linked bank account
 *   plaidremove    → { ok }                   unlink one bank (Item)
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  Configuration, PlaidApi, PlaidEnvironments, Products, CountryCode,
} from "plaid/legacy";
import type { AccountBase, LinkTokenCreateRequest } from "plaid/legacy";
import { ENCRYPTION_KEY, requireUid, encrypt, decrypt } from "./shared";

const PLAID_CLIENT_ID = defineSecret("PLAID_CLIENT_ID");
const PLAID_SECRET = defineSecret("PLAID_SECRET");
/** "sandbox" or "production" — set in functions/.env. The secret must match the environment. */
const PLAID_ENV = defineString("PLAID_ENV", { default: "sandbox" });
const secrets = [PLAID_CLIENT_ID, PLAID_SECRET, ENCRYPTION_KEY];
/** For other modules' functions that read bank balances (e.g. the nightly snapshot). */
export const plaidSecrets = [PLAID_CLIENT_ID, PLAID_SECRET];

/** Where Hosted Link sends the user when done. Caught by ASWebAuthenticationSession. */
const APP_CALLBACK_URL = "orionfinance://plaid";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function plaidClient(): PlaidApi {
  const env = PLAID_ENV.value() === "production" ? "production" : "sandbox";
  return new PlaidApi(new Configuration({
    basePath: PlaidEnvironments[env],
    baseOptions: {
      headers: {
        "PLAID-CLIENT-ID": PLAID_CLIENT_ID.value(),
        "PLAID-SECRET": PLAID_SECRET.value(),
      },
    },
  }));
}

/** Server-only documents. Firestore rules must deny client access to `plaidUsers`. */
const userDoc = (uid: string) => getFirestore().collection("plaidUsers").doc(uid);
const itemsCol = (uid: string) => userDoc(uid).collection("items");

interface PlaidErrorBody { error_code?: string; error_type?: string; error_message?: string }

function plaidErrorBody(err: unknown): PlaidErrorBody | null {
  const data = (err as { response?: { data?: unknown } })?.response?.data;
  return data && typeof data === "object" ? data as PlaidErrorBody : null;
}

/** Never leak Plaid internals or tokens to the client; log details server-side. */
function toHttpsError(err: unknown, context: string): HttpsError {
  if (err instanceof HttpsError) return err;
  const body = plaidErrorBody(err);
  if (body) {
    // Message inline: structured fields get dropped when the log line carries a stack.
    logger.error(`${context}: Plaid ${body.error_type}/${body.error_code}: ${body.error_message ?? ""}`);
    if (body.error_type === "INVALID_INPUT" && body.error_code?.includes("API_KEYS")) {
      return new HttpsError("failed-precondition", "Bank service rejected the request. Check the server's Plaid keys.");
    }
    if (body.error_type === "RATE_LIMIT_EXCEEDED") {
      return new HttpsError("resource-exhausted", "Too many requests. Please try again shortly.");
    }
    // Configuration problems: Plaid's message says what to fix (it never contains tokens).
    if (body.error_type === "INVALID_REQUEST" && body.error_message) {
      return new HttpsError("failed-precondition", `Plaid: ${body.error_message}`);
    }
    return new HttpsError("unavailable", "The bank service is unavailable. Please try again.");
  }
  logger.error(`${context}: unexpected error`, err);
  return new HttpsError("internal", "Something went wrong. Please try again.");
}

/** Errors that mean the user has to sign in to their bank again (update mode). */
const RELINK_CODES = new Set([
  "ITEM_LOGIN_REQUIRED", "PENDING_EXPIRATION", "PENDING_DISCONNECT",
  "ACCESS_NOT_GRANTED", "INSUFFICIENT_CREDENTIALS", "USER_PERMISSION_REVOKED",
]);

function normalizeAccount(itemId: string, a: AccountBase) {
  return {
    id: a.account_id,
    itemId,
    name: a.name || a.official_name || "Account",
    mask: a.mask ?? null,
    type: String(a.type),                 // depository | credit | loan | investment | other
    subtype: a.subtype ? String(a.subtype) : null,
    current: a.balances.current ?? null,  // credit/loan: amount owed (positive)
    available: a.balances.available ?? null,
    currency: (a.balances.iso_currency_code ?? a.balances.unofficial_currency_code ?? "USD").toUpperCase(),
  };
}

/** Signed balance per bank account (debts negative), for the nightly snapshot. Never throws. */
export async function plaidAccountValues(uid: string):
  Promise<Array<{ institution: string; netValue: number; currency: string; mask: string | null }>> {
  const snap = await itemsCol(uid).get();
  if (snap.empty) return [];
  const client = plaidClient();
  const out: Array<{ institution: string; netValue: number; currency: string; mask: string | null }> = [];
  for (const doc of snap.docs) {
    try {
      const res = await client.accountsGet({ access_token: decrypt(doc.data().accessTokenCipher as string) });
      for (const a of res.data.accounts.map((x) => normalizeAccount(doc.id, x))) {
        const debt = a.type === "credit" || a.type === "loan";
        const v = debt ? (a.current === null ? null : -Math.abs(a.current)) : (a.current ?? a.available);
        if (v === null) continue;
        out.push({ institution: (doc.data().institutionName as string) ?? "Bank", netValue: v, currency: a.currency, mask: a.mask });
      }
    } catch (err) {
      logger.warn("plaidAccountValues: item failed", { itemId: doc.id, code: plaidErrorBody(err)?.error_code });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Callable functions
// ---------------------------------------------------------------------------

/**
 * data: { itemId?: string }  — pass a linked bank's id to re-authenticate it (update mode).
 * returns: { linkToken: string, url: string }
 */
export const plaidlinktoken = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  const itemId = typeof req.data?.itemId === "string" && req.data.itemId ? req.data.itemId as string : null;
  try {
    const request: LinkTokenCreateRequest = {
      client_name: "Orion Finance",
      language: "en",
      country_codes: [CountryCode.Ca, CountryCode.Us],
      user: { client_user_id: uid },            // Firebase uid only — no PII sent to Plaid
      // is_mobile_app is left off: it would require a registered OAuth redirect_uri.
      // Without it, bank OAuth pages stay inside the same in-app browser session.
      hosted_link: {
        completion_redirect_uri: APP_CALLBACK_URL,
        url_lifetime_seconds: 900,
      },
    };
    if (itemId) {
      // Update mode: re-authenticate an existing Item (no products allowed).
      const item = await itemsCol(uid).doc(itemId).get();
      const cipher = item.data()?.accessTokenCipher as string | undefined;
      if (!cipher) throw new HttpsError("not-found", "That bank connection no longer exists.");
      request.access_token = decrypt(cipher);
    } else {
      // Transactions covers chequing, savings, credit cards and loans at almost every institution.
      // We only read balances (/accounts/get); transaction history is never fetched.
      request.products = [Products.Transactions];
      request.transactions = { days_requested: 30 };
    }

    const res = await plaidClient().linkTokenCreate(request);
    const url = res.data.hosted_link_url;
    if (!url) throw new HttpsError("failed-precondition", "Plaid Hosted Link isn't enabled for this account.");

    // Only tokens this user created can be completed by this user.
    await userDoc(uid).set({
      pendingLinkToken: res.data.link_token,
      pendingCreatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return { linkToken: res.data.link_token, url };
  } catch (err) {
    throw toHttpsError(err, "plaidlinktoken");
  }
});

/**
 * data: { linkToken: string }
 * returns: { added: number }
 */
export const plaidcomplete = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  const linkToken = req.data?.linkToken;
  if (typeof linkToken !== "string" || !linkToken) {
    throw new HttpsError("invalid-argument", "linkToken is required.");
  }
  try {
    const pending = (await userDoc(uid).get()).data()?.pendingLinkToken;
    if (pending !== linkToken) return { added: 0 };   // not ours, or already completed

    const client = plaidClient();
    const res = await client.linkTokenGet({ link_token: linkToken });
    const results = (res.data.link_sessions ?? []).flatMap((s) => s.results?.item_add_results ?? []);

    let added = 0;
    for (const r of results) {
      const exchange = await client.itemPublicTokenExchange({ public_token: r.public_token });
      await itemsCol(uid).doc(exchange.data.item_id).set({
        accessTokenCipher: encrypt(exchange.data.access_token),
        institutionId: r.institution?.institution_id ?? null,
        institutionName: r.institution?.name ?? "Bank",
        createdAt: FieldValue.serverTimestamp(),
      });
      added++;
    }
    await userDoc(uid).set({ pendingLinkToken: FieldValue.delete() }, { merge: true });
    return { added };
  } catch (err) {
    throw toHttpsError(err, "plaidcomplete");
  }
});

/**
 * returns: { items: [...], accounts: [...] }  (empty arrays if nothing linked)
 */
export const plaidsync = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  try {
    const snap = await itemsCol(uid).get();
    if (snap.empty) return { items: [], accounts: [] };

    const client = plaidClient();
    // One call per bank; a single failing bank must not hide the others.
    const perItem = await Promise.all(snap.docs.map(async (doc) => {
      const data = doc.data();
      const base = { id: doc.id, institution: (data.institutionName as string) ?? "Bank" };
      try {
        // Cached balances (free); refreshed by Plaid several times a day.
        const accessToken = decrypt(data.accessTokenCipher as string);
        const [res, status] = await Promise.all([
          client.accountsGet({ access_token: accessToken }),
          client.itemGet({ access_token: accessToken }).catch(() => null),
        ]);
        const balanceTimes = res.data.accounts
          .map((a) => a.balances.last_updated_datetime)
          .filter((t): t is string => !!t)
          .sort();
        const lastUpdated = status?.data.status?.transactions?.last_successful_update
          ?? balanceTimes[balanceTimes.length - 1] ?? null;
        return {
          item: { ...base, needsReconnect: false, error: null, lastUpdated },
          accounts: res.data.accounts.map((a) => normalizeAccount(doc.id, a)),
        };
      } catch (err) {
        const body = plaidErrorBody(err);
        logger.warn("plaidsync: accounts failed", { itemId: doc.id, code: body?.error_code, type: body?.error_type });
        const relink = !!body?.error_code && RELINK_CODES.has(body.error_code);
        return {
          item: {
            ...base,
            lastUpdated: null,
            needsReconnect: relink,
            error: relink ? "Sign in to this bank again to keep it updated." : "Couldn't load this bank right now.",
          },
          accounts: [],
        };
      }
    }));

    return {
      items: perItem.map((p) => p.item),
      accounts: perItem.flatMap((p) => p.accounts),
    };
  } catch (err) {
    throw toHttpsError(err, "plaidsync");
  }
});

/**
 * data: { itemId: string }
 * returns: { ok: true }
 */
export const plaidremove = onCall({ secrets }, async (req) => {
  const uid = requireUid(req);
  const itemId = req.data?.itemId;
  if (typeof itemId !== "string" || !itemId) {
    throw new HttpsError("invalid-argument", "itemId is required.");
  }
  try {
    // Looked up under this user's own path, so a user can only remove their own banks.
    const ref = itemsCol(uid).doc(itemId);
    const cipher = (await ref.get()).data()?.accessTokenCipher as string | undefined;
    if (!cipher) return { ok: true };
    try {
      await plaidClient().itemRemove({ access_token: decrypt(cipher) });
    } catch (err) {
      // Already gone on Plaid's side → still delete our copy.
      if (plaidErrorBody(err)?.error_code !== "ITEM_NOT_FOUND") throw err;
    }
    await ref.delete();
    return { ok: true };
  } catch (err) {
    throw toHttpsError(err, "plaidremove");
  }
});
