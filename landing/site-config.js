/**
 * Site configuration for the Roomy marketing site.
 *
 * After enabling Google Analytics in Firebase, paste your GA4 Measurement ID
 * (Project settings → Integrations → Google Analytics, or Analytics → Data streams).
 * Example: "G-ABC123XY12"
 *
 * buyUrl: where Buy buttons (data-buy) go. /buy is a Firebase Hosting redirect to the
 * Stripe Payment Link (firebase.json), which the Mac app also opens.
 */
window.ROOMY_SITE = window.ROOMY_SITE || {
  gaMeasurementId: "G-Y1DDG8XTJD",
  buyUrl: "/buy",
};
