// Issues Roomy for Mac license keys in RoomyFleet's token format:
//   ROOMY1.<base64url JSON payload>.<base64url Ed25519 signature over the payload bytes>
// The app verifies them offline (Roomy/RoomyLicense.swift) and decodes dates as ISO 8601
// without fractional seconds, so dates must not carry milliseconds.
"use strict";

const crypto = require("node:crypto");

// PKCS#8 DER prefix for a raw 32-byte Ed25519 private key.
const PKCS8_ED25519_PREFIX = Buffer.from("302e020100300506032b657004220420", "hex");

// Perpetual license: the payload format requires an expiry.
const EXPIRES_AT = "2100-01-01T00:00:00Z";

function base64url(buf) {
  return Buffer.from(buf).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function isoSeconds(date) {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function privateKeyFromBase64(rawBase64) {
  const raw = Buffer.from(rawBase64.trim(), "base64");
  if (raw.length !== 32) throw new Error("mac license signing key must be 32 raw bytes, base64");
  return crypto.createPrivateKey({ key: Buffer.concat([PKCS8_ED25519_PREFIX, raw]), format: "der", type: "pkcs8" });
}

/** @param {{id: string, email: string, issuedAt?: Date, privateKeyBase64: string}} p */
function issueMacLicense({ id, email, issuedAt = new Date(), privateKeyBase64 }) {
  // Key order is irrelevant to verification (the signature covers these exact bytes).
  const payload = Buffer.from(JSON.stringify({
    edition: "mac",
    expiresAt: EXPIRES_AT,
    features: ["mac"],
    id,
    issuedAt: isoSeconds(issuedAt),
    maxHosts: 0,
    org: email,
  }));
  const signature = crypto.sign(null, payload, privateKeyFromBase64(privateKeyBase64));
  return ["ROOMY1", base64url(payload), base64url(signature)].join(".");
}

/**
 * Verifies a Stripe-Signature header (scheme v1) against the raw request body.
 * Returns the parsed event, or throws.
 */
function verifyStripeEvent(rawBody, header, secret, toleranceSeconds = 300, now = Date.now()) {
  if (!header) throw new Error("missing Stripe-Signature header");
  const parts = Object.create(null);
  const v1 = [];
  for (const item of header.split(",")) {
    const [k, v] = item.split("=");
    if (k === "v1") v1.push(v); else parts[k] = v;
  }
  const t = Number(parts.t);
  if (!t || v1.length === 0) throw new Error("malformed Stripe-Signature header");
  if (Math.abs(now / 1000 - t) > toleranceSeconds) throw new Error("Stripe signature timestamp outside tolerance");
  const expected = crypto.createHmac("sha256", secret).update(`${t}.`).update(rawBody).digest();
  const ok = v1.some((sig) => {
    const given = Buffer.from(sig, "hex");
    return given.length === expected.length && crypto.timingSafeEqual(given, expected);
  });
  if (!ok) throw new Error("Stripe signature does not match");
  return JSON.parse(Buffer.from(rawBody).toString("utf8"));
}

module.exports = { issueMacLicense, verifyStripeEvent, isoSeconds };
