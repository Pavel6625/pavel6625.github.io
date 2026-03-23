document.addEventListener("DOMContentLoaded", (event) => {
    gsap.from("#hero > .container", {x: "-100", opacity: 0, ease: "circ.out", duration: 1});
});
