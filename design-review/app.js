(function () {
  const root = document.documentElement;
  const stored = localStorage.getItem("roomy-design-theme");
  const prefersLight = window.matchMedia("(prefers-color-scheme: light)").matches;
  if (stored === "light" || (!stored && prefersLight)) {
    root.setAttribute("data-theme", "light");
  }

  const btn = document.getElementById("theme-toggle");
  function label() {
    const t = root.getAttribute("data-theme");
    btn.textContent = t === "light" ? "Dark mode" : "Light mode";
  }
  label();

  btn.addEventListener("click", () => {
    const next = root.getAttribute("data-theme") === "light" ? "dark" : "light";
    root.setAttribute("data-theme", next);
    localStorage.setItem("roomy-design-theme", next);
    label();
  });

  // Destructive countdown demo (2s total: 2 → 1 → confirm)
  const countdownBtn = document.getElementById("btn-countdown");
  if (countdownBtn) {
    let timer = null;
    countdownBtn.addEventListener("click", () => {
      if (timer) return;
      countdownBtn.disabled = true;
      const orig = countdownBtn.textContent;
      countdownBtn.textContent = "Hold… 2s";
      let step = 0;
      timer = setInterval(() => {
        if (step === 0) {
          countdownBtn.textContent = "Hold… 1s";
          step += 1;
          return;
        }
        clearInterval(timer);
        timer = null;
        countdownBtn.textContent = "Confirmed (demo)";
        setTimeout(() => {
          countdownBtn.textContent = orig;
          countdownBtn.disabled = false;
        }, 900);
      }, 1000);
    });
  }
})();
