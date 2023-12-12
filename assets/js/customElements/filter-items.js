function cssForFilter(id, filter) {
  if (filter === "") {
    return ``;
  }

  return `
#{${id}} [data-filterable]:not([data-filterable*=${JSON.stringify(filter)}]) { display: none; }
`;
}

customElements.define('filter-items', class extends HTMLElement {
  get inputEl() {
    return this.querySelector("input[type=search]");
  }

  connectedCallback() {
    console.log(this);
    const aborter = new AbortController();
    const signal = aborter.signal;
    const id = this.id || `filter-items-${crypto.randomUUID()}`;

    const style = this.ownerDocument.createElement("style");

    function update(inputEl) {
      const filter = inputEl.value.trim();
      style.innerText = cssForFilter(id, filter);
      inputEl.insertAdjacentElement("afterend", style);
    }

    this.addEventListener("input", ({ target: inputEl }) => {
      if (inputEl.matches("input[type=search]")) {
        update(inputEl)
      }
    }, { signal });

    requestAnimationFrame(() => {
      update(this.inputEl);
    });

    // window.addEventListener("phx:page-loading-stop", () => {
    //   const { inputEl } = this;
    //   const filter = inputEl.value.trim();
    //   style.innerText = cssForFilter(id, filter);
    //   inputEl.insertAdjacentElement("afterend", style);
    // }, { signal });

    this.id = id;
    this.aborter = aborter;
  }

  disconnectedCallback() {
    if (this.aborter) {
      this.aborter.abort();
      this.aborter = undefined;
    }
  }
});
