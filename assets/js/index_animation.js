// Hero entrance. A short fade-and-lift rather than the old full-width slide:
// the hero is now half the screen, so a 100px horizontal throw read as a jolt.
document.addEventListener("DOMContentLoaded", function () {
  var reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduced || typeof gsap === "undefined") return;

  gsap.from("#hero > .container", {
    y: 16,
    opacity: 0,
    ease: "power2.out",
    duration: 0.6
  });
});
