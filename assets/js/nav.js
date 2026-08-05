// Navigation behaviour: the collapsing mobile menu and the language dropdown.
//
// These are the only two things the site used Bootstrap's JavaScript for, and
// the bundle cost 80 KB (plus Popper) to provide them. This is the same
// behaviour, including the height transition, the aria state, click-outside
// and Escape.
(function () {
  "use strict";

  var reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // ---- Collapse ---------------------------------------------------------

  function collapseTargets(trigger) {
    var sel = trigger.getAttribute("data-bs-target") || trigger.getAttribute("href");
    return sel ? document.querySelectorAll(sel) : [];
  }

  function isShown(el) {
    return el.classList.contains("show");
  }

  function setExpanded(trigger, open) {
    trigger.setAttribute("aria-expanded", String(open));
    trigger.classList.toggle("collapsed", !open);
  }

  function show(el, trigger) {
    if (el.classList.contains("collapsing")) return;
    setExpanded(trigger, true);

    if (reduced) {
      el.classList.remove("collapse");
      el.classList.add("collapse", "show");
      return;
    }

    el.classList.remove("collapse");
    el.classList.add("collapsing");
    el.style.height = "0px";

    // Force layout so the transition has a starting value to animate from.
    void el.offsetHeight;
    el.style.height = el.scrollHeight + "px";

    el.addEventListener("transitionend", function done() {
      el.classList.remove("collapsing");
      el.classList.add("collapse", "show");
      el.style.height = "";
    }, { once: true });
  }

  function hide(el, trigger) {
    if (el.classList.contains("collapsing")) return;
    setExpanded(trigger, false);

    if (reduced) {
      el.classList.remove("show");
      return;
    }

    el.style.height = el.getBoundingClientRect().height + "px";
    void el.offsetHeight;

    el.classList.remove("collapse", "show");
    el.classList.add("collapsing");
    el.style.height = "0px";

    el.addEventListener("transitionend", function done() {
      el.classList.remove("collapsing");
      el.classList.add("collapse");
      el.style.height = "";
    }, { once: true });
  }

  document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(function (trigger) {
    trigger.addEventListener("click", function (e) {
      e.preventDefault();
      collapseTargets(trigger).forEach(function (el) {
        (isShown(el) ? hide : show)(el, trigger);
      });
    });
  });

  // ---- Dropdown ---------------------------------------------------------

  var dropdownToggles = Array.prototype.slice.call(
    document.querySelectorAll('[data-bs-toggle="dropdown"]')
  );

  function menuFor(toggle) {
    var parent = toggle.closest(".dropdown, .nav-item, .btn-group") || toggle.parentNode;
    return parent ? parent.querySelector(".dropdown-menu") : null;
  }

  function closeDropdown(toggle) {
    var menu = menuFor(toggle);
    if (menu) menu.classList.remove("show");
    toggle.classList.remove("show");
    toggle.setAttribute("aria-expanded", "false");
  }

  function closeAllDropdowns(except) {
    dropdownToggles.forEach(function (t) {
      if (t !== except) closeDropdown(t);
    });
  }

  dropdownToggles.forEach(function (toggle) {
    toggle.addEventListener("click", function (e) {
      e.preventDefault();
      e.stopPropagation();

      var menu = menuFor(toggle);
      if (!menu) return;

      var open = menu.classList.contains("show");
      closeAllDropdowns(toggle);

      if (open) {
        closeDropdown(toggle);
      } else {
        menu.classList.add("show");
        toggle.classList.add("show");
        toggle.setAttribute("aria-expanded", "true");
      }
    });
  });

  document.addEventListener("click", function (e) {
    dropdownToggles.forEach(function (toggle) {
      var menu = menuFor(toggle);
      if (menu && menu.classList.contains("show") && !menu.contains(e.target)) {
        closeDropdown(toggle);
      }
    });
  });

  document.addEventListener("keydown", function (e) {
    if (e.key !== "Escape") return;
    dropdownToggles.forEach(function (toggle) {
      var menu = menuFor(toggle);
      if (menu && menu.classList.contains("show")) {
        closeDropdown(toggle);
        toggle.focus();
      }
    });
  });
})();
