# Semantic Content

<style>
article figure {
  display: flex;
  flex-direction: column;
  text-align: center;
  align-items: center;
}
</style>

<script type=module>
import * as DOMTesting from "https://cdn.skypack.dev/@testing-library/dom";
window.DOMTesting = DOMTesting;

function* surroundingSourceElements(el) {
  let prev = el;
  while (prev = prev.previousElementSibling) {
    if (prev.matches('h1, h2, h3, h4')) break;
    if (prev.matches('pre.language-html')) yield { type: 'html', code: prev.textContent };
    if (prev.matches('pre.language-javascript')) yield { type: 'javascript', code: prev.textContent };
  }
  
  let next = el;
  while (next = next.nextElementSibling) {
    if (next.matches('h1, h2, h3, h4')) break;
    if (next.matches('pre.language-html')) yield { type: 'html', code: next.textContent };
    if (next.matches('pre.language-javascript')) yield { type: 'javascript', code: next.textContent };
  }
}

const outputEls = document.querySelectorAll('article output');
console.log(outputEls);

for (const outputEl of outputEls.values()) {
  const div = outputEl.appendChild(document.createElement('div'));
  div.classList.add('p-4');
    
  console.log('outputEl', outputEl);
  const sources = surroundingSourceElements(outputEl);
  for (const source of sources) {
    const { type, code } = source;
    
    console.log('source', source);
    
    if (type === 'html') {
      div.innerHTML = code;
    }
    
    if (type === 'javascript') {
      const screen = DOMTesting.within(div);
      const testFunction = new Function('screen', `return ${code}`);
      testFunction(screen).style.border = '2px solid red';
    }
  }
}
//const htmlSourceElements = document.querySelector('article pre.language-html');
</script>

<table class="text-left table-fixed">
  <caption class="text-3xl pb-4 text-left">Content roles cheatsheet</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**link**", "`<a href=…>`"],
      ["_none!_", "`<a>`"],
      ["**heading**", "`<h1>`, `<h2>`, `<h3>`, etc"],
      ["**list**", "`<ul>`, `<ol>`"],
      ["**listitem**", "`<li>`"],
      ["**term**", "`<dt>`"],
      ["**definition**", "`<dd>`"],
      ["**img**", "`<img alt=\"Some description\">`"],
      ["_none!_", "`<img alt=\"\">`"],
      ["**figure**", "`<figure>`"],
      ["**separator**", "`<hr>`, `<li role=separator>`"],
      ["_none!_", "`<p>`"],
      ["_none!_", "`<div>`"],
      ["_none!_", "`<span>`"],
      ["**group**", "`<details>`"],
      ["**button**", "`<summary>`"],
    ]) %>
  </tbody>
</table>

## Search engines and other crawlers

A crawler service that visits your website on behalf of a search engine like Google or social network like Instagram expects semantic content.

Semantic HTML elements allow meaning and structure to be determined.

The better these crawlers can understand, and the more meaning they can infer, the higher they will rank you.

A web page that is just made of `<div>` and `<span>` elements means that the only content they have to use is the text. Which is a lossy and messy process. Better to provide precise and rich elements instead.

## Headings

```html
<h1>One Thousand and One Nights</h1>
```

<output></output>

```javascript
screen.getByRole('heading');
```

## Lists

```html
<ul>
  <li>First
  <li>Second
  <li>Third
</ul>
```

<output></output>

```javascript
screen.getByRole('list');
```

## Term & Definition

```html
<dl>
  <dt>Name</dt>
  <dd>The Lion King</dd>
  
  <dt>Year Released</dt>
  <dd>1994</dd>
  
  <dt>Runtime</dt>
  <dd>88 min</dd>
</dl>
```

<output></output>

## Images

```html
<img
  alt="The HTML 5 logo"
  src="https://unpkg.com/super-tiny-icons@0.4.0/images/svg/html5.svg"
  width=200
>
```

<output></output>

```javascript
screen.getByRole('img', { name: /logo/ });
```

## Figure

```html
<figure>
  <img
    src="https://unpkg.com/super-tiny-icons@0.4.0/images/svg/html5.svg"
    width=200
  >
  <figcaption>The HTML 5 logo</figcaption>
</figure>
```

<output></output>

```javascript
screen.getByRole('figure');
```

## Details & Summary

## Separator

<script type=module>
  import * as DOM from "https://cdn.skypack.dev/@testing-library/dom";
  console.log("DOM", Object.keys(DOM), DOM.screen);
</script>
