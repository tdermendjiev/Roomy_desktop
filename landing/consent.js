(function () {
  "use strict";

  var STORAGE_KEY = "roomy_cookie_consent_v1";
  var CONSENT_VERSION = 1;

  window.dataLayer = window.dataLayer || [];
  function gtag() {
    window.dataLayer.push(arguments);
  }
  window.gtag = gtag;

  gtag("consent", "default", {
    ad_storage: "denied",
    ad_user_data: "denied",
    ad_personalization: "denied",
    analytics_storage: "denied",
    functionality_storage: "denied",
    personalization_storage: "denied",
    security_storage: "granted",
    wait_for_update: 500,
  });

  function measurementId() {
    var cfg = window.ROOMY_SITE || {};
    var id = (cfg.gaMeasurementId || "").trim();
    if (!id || id === "G-XXXXXXXXXX") return "";
    return id;
  }

  function readStored() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (!parsed || parsed.version !== CONSENT_VERSION) return null;
      return parsed;
    } catch (e) {
      return null;
    }
  }

  function writeStored(analyticsGranted) {
    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          version: CONSENT_VERSION,
          analytics: !!analyticsGranted,
          updatedAt: new Date().toISOString(),
        })
      );
    } catch (e) {
      /* ignore quota / private mode */
    }
  }

  var gaScriptLoaded = false;

  function loadGoogleAnalytics() {
    var id = measurementId();
    if (!id || gaScriptLoaded) return;
    gaScriptLoaded = true;
    var script = document.createElement("script");
    script.async = true;
    script.src = "https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(id);
    document.head.appendChild(script);
    gtag("js", new Date());
    gtag("config", id, {
      anonymize_ip: true,
      allow_google_signals: false,
      allow_ad_personalization_signals: false,
    });
  }

  function applyAnalyticsConsent(granted) {
    gtag("consent", "update", {
      analytics_storage: granted ? "granted" : "denied",
      ad_storage: "denied",
      ad_user_data: "denied",
      ad_personalization: "denied",
    });
    if (granted) loadGoogleAnalytics();
  }

  function mountBanner(onChoice) {
    if (document.getElementById("roomy-consent")) return;

    var root = document.createElement("div");
    root.id = "roomy-consent";
    root.setAttribute("role", "dialog");
    root.setAttribute("aria-labelledby", "roomy-consent-title");
    root.setAttribute("aria-describedby", "roomy-consent-desc");
    root.innerHTML =
      '<p id="roomy-consent-title">Cookie preferences</p>' +
      '<p id="roomy-consent-desc">We use cookies and similar technologies on this marketing site. ' +
      "Optional analytics cookies (Google Analytics) help us understand traffic. " +
      'The Roomy macOS app does not use these cookies. ' +
      '<a href="privacy.html">Privacy Policy</a> · <a href="cookies.html">Cookie Policy</a></p>' +
      '<div id="roomy-consent-prefs" hidden>' +
      '<div class="roomy-consent-row">' +
      "<div><strong>Essential</strong><span>Stores your cookie choice. Always on.</span></div>" +
      '<button type="button" class="roomy-consent-toggle" aria-checked="true" aria-label="Essential cookies (required)" disabled></button>' +
      "</div>" +
      '<div class="roomy-consent-row">' +
      "<div><strong>Analytics</strong><span>Google Analytics — page views and usage on this site only.</span></div>" +
      '<button type="button" class="roomy-consent-toggle" id="roomy-consent-analytics-toggle" aria-checked="false" aria-label="Analytics cookies"></button>' +
      "</div>" +
      "</div>" +
      '<div class="roomy-consent-actions">' +
      '<button type="button" class="roomy-consent-btn roomy-consent-btn--primary" data-action="accept-all">Accept all</button>' +
      '<button type="button" class="roomy-consent-btn" data-action="reject-optional">Reject optional</button>' +
      '<button type="button" class="roomy-consent-btn" data-action="toggle-prefs">Manage</button>' +
      '<button type="button" class="roomy-consent-btn" data-action="save-prefs" hidden>Save choices</button>' +
      "</div>";

    document.body.appendChild(root);

    var prefs = root.querySelector("#roomy-consent-prefs");
    var analyticsToggle = root.querySelector("#roomy-consent-analytics-toggle");
    var saveBtn = root.querySelector('[data-action="save-prefs"]');

    function hideBanner() {
      root.hidden = true;
    }

    function setAnalyticsToggle(on) {
      analyticsToggle.setAttribute("aria-checked", on ? "true" : "false");
    }

    analyticsToggle.addEventListener("click", function () {
      var on = analyticsToggle.getAttribute("aria-checked") !== "true";
      setAnalyticsToggle(on);
    });

    root.addEventListener("click", function (event) {
      var btn = event.target.closest("[data-action]");
      if (!btn) return;
      var action = btn.getAttribute("data-action");

      if (action === "toggle-prefs") {
        var open = prefs.hidden;
        prefs.hidden = !open;
        saveBtn.hidden = open;
        btn.textContent = open ? "Manage" : "Hide";
        return;
      }

      if (action === "accept-all") {
        writeStored(true);
        applyAnalyticsConsent(true);
        hideBanner();
        onChoice(true);
        return;
      }

      if (action === "reject-optional") {
        writeStored(false);
        applyAnalyticsConsent(false);
        hideBanner();
        onChoice(false);
        return;
      }

      if (action === "save-prefs") {
        var granted = analyticsToggle.getAttribute("aria-checked") === "true";
        writeStored(granted);
        applyAnalyticsConsent(granted);
        hideBanner();
        onChoice(granted);
      }
    });
  }

  function initUi() {
    var stored = readStored();
    if (stored) {
      applyAnalyticsConsent(!!stored.analytics);
      return;
    }
    mountBanner(function () {});
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initUi);
  } else {
    initUi();
  }

  window.roomyOpenCookiePreferences = function () {
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch (e) {
      /* ignore */
    }
    applyAnalyticsConsent(false);
    var existing = document.getElementById("roomy-consent");
    if (existing) existing.remove();
    mountBanner(function () {});
    var banner = document.getElementById("roomy-consent");
    if (banner) banner.hidden = false;
  };
})();
