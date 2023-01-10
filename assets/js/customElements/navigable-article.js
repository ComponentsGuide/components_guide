customElements.define('navigable-article', class extends HTMLElement {
  constructor() {
    super();

    const document = this.ownerDocument;

    function El(base, props, ...children) {
      const el = typeof base === 'string' ? document.createElement(base) : base.cloneNode(false);
      Object.assign(el, props);
      el.append(...children);
      return el;
    }
    
    const aside = this.querySelector('aside');
    aside.hidden = false;

    const navItemsSlot = this.querySelector('slot[name=article-navigation-items]');
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
});
