/** Helpers shared by the SnapTrade and Plaid functions. */
import { HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

/**
 * 32 random bytes, base64. Encrypts per-user provider credentials at rest
 * (SnapTrade user secrets, Plaid access tokens). Secret name kept for compatibility.
 */
export const ENCRYPTION_KEY = defineSecret("SNAPTRADE_ENCRYPTION_KEY");

export function requireUid(req: CallableRequest): string {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in first.");
  return uid;
}

function encryptionKey(): Buffer {
  const key = Buffer.from(ENCRYPTION_KEY.value(), "base64");
  if (key.length !== 32) {
    throw new HttpsError("failed-precondition", "Server encryption key is misconfigured.");
  }
  return key;
}

/** AES-256-GCM → base64(iv | tag | ciphertext) */
export function encrypt(plain: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", encryptionKey(), iv);
  const body = Buffer.concat([cipher.update(plain, "utf8"), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), body]).toString("base64");
}

export function decrypt(packed: string): string {
  const buf = Buffer.from(packed, "base64");
  const decipher = createDecipheriv("aes-256-gcm", encryptionKey(), buf.subarray(0, 12));
  decipher.setAuthTag(buf.subarray(12, 28));
  return Buffer.concat([decipher.update(buf.subarray(28)), decipher.final()]).toString("utf8");
}
