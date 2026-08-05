// Colour-mode toggle. The initial mode is set by an inline script in <head>
// so there is no flash; this only handles switching and persistence.
(function () {
  var root = document.documentElement;
  var button = document.getElementById("theme-toggle");
  if (!button) return;

  function current() {
    return root.getAttribute("data-bs-theme") === "dark" ? "dark" : "light";
  }

  function apply(theme) {
    root.setAttribute("data-bs-theme", theme);
    button.setAttribute("aria-pressed", String(theme === "dark"));
    try {
      localStorage.setItem("theme", theme);
    } catch (e) {
      /* private mode: the choice just will not persist */
    }
  }

  button.setAttribute("aria-pressed", String(current() === "dark"));

  button.addEventListener("click", function () {
    apply(current() === "dark" ? "light" : "dark");
  });

  // Follow the OS while the visitor has not made an explicit choice.
  var media = window.matchMedia("(prefers-color-scheme: dark)");
  var listener = function (e) {
    var stored = null;
    try {
      stored = localStorage.getItem("theme");
    } catch (err) { /* ignore */ }
    if (!stored) apply(e.matches ? "dark" : "light");
  };

  if (media.addEventListener) {
    media.addEventListener("change", listener);
  } else if (media.addListener) {
    media.addListener(listener);
  }
})();
