// Roomy purchase backend (Firebase Functions v2).
//
//   stripeWebhook      POST /api/stripe-webhook   Stripe checkout.session.* events → issue key, store, email
//   licenseForSession  GET  /api/license?session_id=cs_...   used by /thanks to show the key
//
// Secrets (firebase functions:secrets:set NAME):
//   STRIPE_WEBHOOK_SECRET    whsec_... of the webhook endpoint
//   MAC_LICENSE_SIGNING_KEY  contents of ~/.roomy-issuer/mac-license.key (base64 raw Ed25519)
//   RESEND_API_KEY           re_... for sending the license email from getroomy.dev
"use strict";

const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { issueMacLicense, verifyStripeEvent } = require("./license");

// Next to the Firestore database (nam5).
setGlobalOptions({ region: "us-central1" });

initializeApp();
const db = getFirestore();

const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");
const MAC_LICENSE_SIGNING_KEY = defineSecret("MAC_LICENSE_SIGNING_KEY");
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

const FROM = "Roomy <license@getroomy.dev>";
const REPLY_TO = "hello@getroomy.dev";
const HANDLED = new Set(["checkout.session.completed", "checkout.session.async_payment_succeeded"]);
// The Roomy for Mac Payment Link. Its metadata is copied onto sessions; the id is a fallback.
const MAC_PAYMENT_LINK = "plink_1UVEtcAf0kKiakzkrEpMEX3G";

exports.stripeWebhook = onRequest(
  { secrets: [STRIPE_WEBHOOK_SECRET, MAC_LICENSE_SIGNING_KEY, RESEND_API_KEY], maxInstances: 5 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("POST only");
    let event;
    try {
      event = verifyStripeEvent(req.rawBody, req.get("stripe-signature"), STRIPE_WEBHOOK_SECRET.value());
    } catch (err) {
      logger.warn("rejected webhook", { reason: err.message });
      return res.status(400).send("bad signature");
    }
    if (!HANDLED.has(event.type)) return res.status(200).send("ignored");
    // Test-mode events would otherwise mint keys the shipped app accepts.
    if (!event.livemode) return res.status(200).send("test mode ignored");

    const session = event.data.object;
    const isMac = session.metadata?.roomy_edition === "mac" || session.payment_link === MAC_PAYMENT_LINK;
    // "no_payment_required": a 100%-off promotion code (giveaways, reviewers).
    if (!isMac || !["paid", "no_payment_required"].includes(session.payment_status)) {
      return res.status(200).send("not a paid Roomy purchase");
    }
    const email = session.customer_details?.email;
    if (!email) {
      logger.error("paid session without email", { session: session.id });
      return res.status(200).send("no email");
    }

    const ref = db.collection("licenses").doc(session.id);
    const record = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return snap.data();
      const created = {
        email,
        key: issueMacLicense({ id: session.id, email, privateKeyBase64: MAC_LICENSE_SIGNING_KEY.value() }),
        amountTotal: session.amount_total ?? null,
        currency: session.currency ?? null,
        livemode: !!event.livemode,
        emailed: false,
        createdAt: FieldValue.serverTimestamp(),
      };
      tx.set(ref, created);
      return created;
    });

    if (!record.emailed) {
      try {
        await sendLicenseEmail(record.email, record.key, RESEND_API_KEY.value());
        await ref.update({ emailed: true, emailedAt: FieldValue.serverTimestamp() });
      } catch (err) {
        // Non-2xx makes Stripe retry; the stored key is reused, only the email is re-attempted.
        logger.error("license email failed", { session: session.id, reason: err.message });
        return res.status(500).send("email failed");
      }
    }
    logger.info("license issued", { session: session.id, livemode: record.livemode });
    return res.status(200).send("ok");
  }
);

exports.licenseForSession = onRequest({ maxInstances: 5 }, async (req, res) => {
  res.set("Cache-Control", "no-store");
  const id = String(req.query.session_id || "");
  if (!/^cs_(test|live)_[A-Za-z0-9]{10,}$/.test(id)) return res.status(400).json({ error: "bad session id" });
  const snap = await db.collection("licenses").doc(id).get();
  // 404 while the webhook has not arrived yet; /thanks polls.
  if (!snap.exists) return res.status(404).json({ error: "pending" });
  const { email, key } = snap.data();
  return res.json({ email, key });
});

async function sendLicenseEmail(to, key, apiKey) {
  const text = [
    "Thanks for buying Roomy.",
    "",
    "Your license key:",
    "",
    key,
    "",
    "To activate: press Clean in Roomy and paste the key when asked, or go to Settings → About → License.",
    "It works on all the Macs you use, and includes free updates through Roomy 2.x.",
    "",
    "Need a refund within 14 days, or lost this email? Reply to this message.",
    "",
    "Roomy · https://getroomy.dev",
  ].join("\n");
  const html = `<div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;font-size:15px;line-height:1.5;color:#1d1d1f;max-width:560px">
<p>Thanks for buying Roomy.</p>
<p>Your license key:</p>
<p style="font-family:ui-monospace,Menlo,monospace;font-size:12px;word-break:break-all;background:#f2f2f5;border-radius:8px;padding:12px">${key}</p>
<p>To activate: press <b>Clean</b> in Roomy and paste the key when asked, or go to <b>Settings → About → License</b>. It works on all the Macs you use, and includes free updates through Roomy 2.x.</p>
<p style="color:#6e6e73">Need a refund within 14 days, or lost this email? Reply to this message.</p>
<p style="color:#6e6e73">Roomy · <a href="https://getroomy.dev">getroomy.dev</a></p>
</div>`;
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: FROM, to: [to], reply_to: REPLY_TO, subject: "Your Roomy license key", text, html }),
  });
  if (!r.ok) throw new Error(`Resend ${r.status}: ${(await r.text()).slice(0, 200)}`);
}
