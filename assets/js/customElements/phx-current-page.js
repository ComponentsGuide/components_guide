customElements.define('phx-current-page', class extends HTMLElement {
  linksWithHref(href) {
    return Array.from(this.querySelectorAll("a[href]"))
      .filter(a => a.href === href);
  }
  linksWithCurrentPage() {
    return Array.from(this.querySelectorAll("a[aria-current=page]"));
  }

  connectedCallback() {
    const aborter = new AbortController();
    const signal = aborter.signal;

    const update = () => {
      for (const el of this.linksWithCurrentPage()) {
        el.removeAttribute("aria-current");
      }
      for (const el of this.linksWithHref(window.location.href)) {
        el.setAttribute("aria-current", "page");
      }
    }

    requestAnimationFrame(update);
    window.addEventListener("phx:page-loading-stop", update, { signal });

    this.disconnectedCallback = () => {
      aborter.abort();
    }
  }

  // disconnectedCallback() {
  //   if (this.aborter) {
  //     this.aborter.abort();
  //     this.aborter = undefined;
  //   }
  // }
});
