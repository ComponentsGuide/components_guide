# Semantic Content

<style>
article output {
  --link-decoration: underline;
}

article figure {
  display: flex;
  flex-direction: column;
  text-align: center;
  align-items: center;
}

article dt {
  font-weight: bold;
}
article dd {
  margin-left: 1em;
}

article summary {
  cursor: pointer;
}
</style>

<script type=module>
import * as DOMTesting from "https://cdn.skypack.dev/@testing-library/dom";

function* surroundingSourceElements(el) {
  let prev = el;
  while (prev = prev.previousElementSibling) {
    if (prev.matches('h1, h2, h3, h4')) break;
    if (prev.matches('pre.language-html')) yield { type: 'html', code: prev.textContent, el: prev };
    if (prev.matches('pre.language-javascript')) yield { type: 'javascript', code: prev.textContent, el: prev };
  }
  
  let next = el;
  while (next = next.nextElementSibling) {
    if (next.matches('h1, h2, h3, h4')) break;
    if (next.matches('pre.language-html')) yield { type: 'html', code: next.textContent, el: next };
    if (next.matches('pre.language-javascript')) yield { type: 'javascript', code: next.textContent, el: next };
  }
}

const outputEls = document.querySelectorAll('article output');

function colorFor(index) {
  return ['orange-500', 'purple-500', 'green-500'][index];
}

for (const outputEl of outputEls.values()) {
  const div = outputEl.appendChild(document.createElement('div'));
  div.classList.add('p-4');
    
  let javascriptIndex = 0;
  const sources = surroundingSourceElements(outputEl);
  for (const source of sources) {
    const { type, code, el } = source;
    
    console.log('source', source);
    
    if (type === 'html') {
      div.innerHTML = code;
    }
    
    if (type === 'javascript') {
      const color = colorFor(javascriptIndex);
      
      el.classList.add('border-l-4', `border-${color}`);
      
      const screen = DOMTesting.within(div);
      const testFunction = new Function('screen', `return ${code}`);
      testFunction(screen).classList.add('border-2', `border-${color}`);
      
      javascriptIndex++;
    }
  }
}
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

A web page that is just made of `<div>` and `<span>` elements means that the only content they have to use is the text. Which is a subjective and messy process. Better to provide precise, meaningful elements instead.

## Headings

```html
<h1>One Thousand and One Nights</h1>
```

<output></output>

```javascript
screen.getByRole('heading');
```

## Links

```html
<p><a href="https://en.wikipedia.org/wiki/One_Thousand_and_One_Nights">One Thousand and One Nights</a> is a collection of Middle Eastern folk tales compiled in Arabic during the <a href="https://en.wikipedia.org/wiki/Islamic_Golden_Age">Islamic Golden Age</a>.
```

<output></output>

```javascript
screen.getByRole('link', { name: 'One Thousand and One Nights' });
```

```javascript
screen.getByRole('link', { name: /islamic golden age/i });
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

```html
<details>
  <summary>Expand me…</summary>
  <p>To see more content</p>
</details>
```

<output></output>

```javascript
screen.getByRole('group');
```

## Separator
