(function () {
  "use strict";

  var nav = document.getElementById("site-nav");
  var heroWindow = document.getElementById("hero-window");

  function onScrollNav() {
    if (!nav) return;
    var y = window.scrollY || document.documentElement.scrollTop;
    nav.classList.toggle("nav--scrolled", y > 60);
  }

  window.addEventListener("scroll", onScrollNav, { passive: true });
  onScrollNav();

  if (heroWindow) {
    window.requestAnimationFrame(function () {
      setTimeout(function () {
        heroWindow.classList.add("hero-window--ready");
      }, 200);
    });
  }

  var revealEls = document.querySelectorAll("[data-reveal]");
  if ("IntersectionObserver" in window && revealEls.length) {
    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("reveal--visible");
          io.unobserve(entry.target);
        });
      },
      { root: null, rootMargin: "0px 0px -8% 0px", threshold: 0.08 }
    );
    revealEls.forEach(function (el) {
      io.observe(el);
    });
  } else {
    revealEls.forEach(function (el) {
      el.classList.add("reveal--visible");
    });
  }

  var parallaxEls = document.querySelectorAll("[data-parallax]");
  var prefersReduced =
    window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (!prefersReduced && parallaxEls.length) {
    var maxOffset = 40;
    function updateParallax() {
      if (window.innerWidth < 901) {
        parallaxEls.forEach(function (el) {
          el.style.transform = "";
        });
        return;
      }
      var vh = window.innerHeight || 1;
      parallaxEls.forEach(function (el) {
        var rect = el.getBoundingClientRect();
        var center = rect.top + rect.height / 2;
        var t = (center - vh / 2) / vh;
        var offset = Math.max(-maxOffset, Math.min(maxOffset, t * maxOffset * 0.85));
        el.style.transform = "translateY(" + offset.toFixed(2) + "px)";
      });
    }
    window.addEventListener("scroll", updateParallax, { passive: true });
    window.addEventListener("resize", updateParallax, { passive: true });
    updateParallax();
  }
})();
