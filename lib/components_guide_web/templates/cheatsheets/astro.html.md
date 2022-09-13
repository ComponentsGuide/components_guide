---
a = 4 + 3
class = "italic"
---

# Astro

<p class={class}><%= a %>?</p>
<p class={class}><%= class %></p>

<script>
window.customElements.define('custom-element', class extends HTMLElement {
  connectedCallback() {
    console.log('connectedCallback called');
    const name = this.getAttribute('name');
    const source = this;

    // Attempt to wait until the inner template has been added as a child node.
    const observer = new MutationObserver((mutationList, observer) => {
      outer: for (const mutation of mutationList) {
        for (const node of mutation.addedNodes.values()) {
          if (node instanceof HTMLTemplateElement) {
            doDefine();
            observer.disconnect();
            break outer;
          }
        }
      }
    });
    observer.observe(this, { childList: true });

    // class NewElement extends HTMLElement {

    // }

    function doDefine() {
      window.customElements.define(name, class extends HTMLElement {
        ensureTemplate() {
          if (this.hasAddedTemplate) return;

          const template = source.querySelector('template');
          const fragment = template.content.cloneNode(true);
          this.attachShadow({mode: 'open'}).appendChild(fragment);
          // this.append(fragment);

          this.hasAddedTemplate = true;
        }

        connectedCallback() {
          this.ensureTemplate();
        }

        static get observedAttributes() {
          const template = source.querySelector('template');
          const slots = template.content.querySelectorAll('slot');
          const slotNames = Array.from(slots, slot => slot.name);
          return slotNames;
        }

        attributeChangedCallback(name, oldValue, newValue) {
          this.ensureTemplate();
          for (const node of this.querySelectorAll(`slot[name="${name}"]`).values()) {
            node.remove();
          }
          this.append(Object.assign(this.ownerDocument.createElement('span'), { textContent: newValue, slot: name }));
        }
      });
    }
  }
});
</script>

<script>
window.customElements.define('custom-element3', class extends HTMLElement {
  connectedCallback() {
    const name = this.getAttribute('name');
    const source = this;
    console.log(this.innerHTML);

    window.customElements.define(name, class extends HTMLElement {
      connectedCallback() {
        const template = source.querySelector('template');
        const fragment = template.content.cloneNode(true);
        this.attachShadow({mode: 'open'}).appendChild(fragment);
      }
    });
  }
});
</script>

<custom-element name="hello-there">
  <template>Hello <slot name="subject">World</slot>.</template>
</custom-element>

<hello-there></hello-there>
<hello-there><span slot="subject">Universe</span></hello-there>
<hello-there subject="Props"></hello-there>

<custom-element name="custom-script">
  <template>
    <script>console.log("Inside template", document.currentScript)</script>
  </template>
</custom-element>

<custom-script></custom-script>
