"use strict";
const test = require("node:test");
const assert = require("node:assert");
const crypto = require("node:crypto");
const { issueMacLicense, verifyStripeEvent } = require("./license");

function rawKeyPair() {
  const { privateKey, publicKey } = crypto.generateKeyPairSync("ed25519");
  const raw = privateKey.export({ format: "der", type: "pkcs8" }).subarray(-32).toString("base64");
  return { raw, publicKey };
}

test("license token has the RoomyFleet shape and a valid signature", () => {
  const { raw, publicKey } = rawKeyPair();
  const token = issueMacLicense({ id: "cs_test_abc", email: "a@b.c", issuedAt: new Date("2026-10-27T10:11:12.345Z"), privateKeyBase64: raw });
  const [prefix, body, sig] = token.split(".");
  assert.equal(prefix, "ROOMY1");
  const b64 = (s) => Buffer.from(s.replace(/-/g, "+").replace(/_/g, "/"), "base64");
  const payload = JSON.parse(b64(body));
  assert.deepEqual(payload, { edition: "mac", expiresAt: "2100-01-01T00:00:00Z", features: ["mac"], id: "cs_test_abc", issuedAt: "2026-10-27T10:11:12Z", maxHosts: 0, org: "a@b.c" });
  assert.ok(crypto.verify(null, b64(body), publicKey, b64(sig)));
  assert.ok(!/[+/=]/.test(token));
});

test("stripe signature: accepts valid, rejects tampered, stale and missing", () => {
  const secret = "whsec_test";
  const body = Buffer.from(JSON.stringify({ type: "checkout.session.completed" }));
  const t = Math.floor(Date.now() / 1000);
  const sig = crypto.createHmac("sha256", secret).update(`${t}.`).update(body).digest("hex");
  assert.equal(verifyStripeEvent(body, `t=${t},v1=${sig}`, secret).type, "checkout.session.completed");
  assert.throws(() => verifyStripeEvent(Buffer.from("{}"), `t=${t},v1=${sig}`, secret));
  assert.throws(() => verifyStripeEvent(body, `t=${t - 3600},v1=${sig}`, secret));
  assert.throws(() => verifyStripeEvent(body, undefined, secret));
});
