customElements.define('enhanced-navigation', class extends HTMLElement {
  constructor() {
    super();

    const document = this.ownerDocument;
    const features = this.dataset;

    function El(base, props, ...children) {
      const el = typeof base === 'string' ? document.createElement(base) : base.cloneNode(false);
      Object.assign(el, props);
      el.append(...children);
      return el;
    }

    if ('addArticleNavigation' in features) {
      const aside = this.querySelector('aside');
      aside.hidden = false;

      const navItemsSlot = this.querySelector('slot[name=nav-items]');
      const navItemsTemplates = navItemsSlot.querySelector('template').content;
      const linkTemplate = navItemsTemplates.querySelector('a');
      const ulTemplate = navItemsTemplates.querySelector('ul');
      const liTemplate = navItemsTemplates.querySelector('li');

      const article = this.querySelector('article');
      const headings = article.querySelectorAll('h2');
      const items = Array.from(headings, (headingEl) => {
        return El(liTemplate, {}, El(linkTemplate, { href: '#' + headingEl.id }, headingEl.innerText));
      });

      navItemsSlot.append(El(ulTemplate, {}, ...items));
    }

    if ('addAriaCurrentPage' in features) {
      const currentPath = document.location.pathname;
      for (const link of this.querySelectorAll(`a[href="${currentPath}"`)) {
        link.ariaCurrent = "page";
      }
    }
  }
});
