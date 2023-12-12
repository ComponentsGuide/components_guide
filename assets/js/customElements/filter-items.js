function cssForFilter(id, filter) {
  if (filter === "") {
    return ``;
  }

  return `
#{${id}} [data-filterable]:not([data-filterable*=${JSON.stringify(filter)}]) { display: none; }
`;
}

customElements.define('filter-items', class extends HTMLElement {
  connectedCallback() {
    console.log(this);
    const aborter = new AbortController();
    const signal = aborter.signal;
    const id = this.id || `filter-items-${crypto.randomUUID()}`;

    const input = this.querySelector("input[type=search]");
    console.log(input);

    const style = this.ownerDocument.createElement("style");
    style.innerText = cssForFilter(id, "");
    input.insertAdjacentElement("afterend", style);

    this.addEventListener("input", ({ target }) => {
      const filter = target.value.trim();
      console.log(filter)
      style.innerText = cssForFilter(id, filter);
    }, { signal });

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
