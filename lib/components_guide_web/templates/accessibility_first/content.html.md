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

<script type="module">
const DOMTestingPromise = window.IMPORT.DOMTesting();

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

function classNamesFor(index) {
  return ['border-yellow-500', 'border-green-500 border-dotted', 'border-purple-500 border-double'][index].split(' ');
}

for (const outputEl of outputEls.values()) {
  const div = outputEl.appendChild(document.createElement('div'));
  div.classList.add('p-4');
    
  let javascriptIndex = 0;
  const sources = surroundingSourceElements(outputEl);
  for (const source of sources) {
    const { type, code, el } = source;
    
    if (type === 'html') {
      div.innerHTML = code;
    }
    
    if (type === 'javascript') {
      const classNames = classNamesFor(javascriptIndex);
      
      el.classList.add('border-l-4', ...classNames);
      
      DOMTestingPromise.then(DOMTesting => {
        const screen = DOMTesting.within(div);
        const testFunction = new Function('screen', `return ${code}`);
        [].concat(testFunction(screen)).forEach(el => el.classList.add('border-4', ...classNames));
      });
      
      javascriptIndex++;
    }
  }
}
</script>

## Search engines and other crawlers

A crawler service that visits your website on behalf of a search engine like Google or social network like Instagram expects semantic content.

Semantic HTML elements allow meaning and structure to be determined.

The better these crawlers can understand, and the more meaning they can infer, the higher they will rank you.

A web page that is just made of `<div>` and `<span>` elements means that the only content they have to use is the text. Which is a subjective and messy process. Better to provide precise, meaningful elements instead.

<h2 id=headings>Headings</h2>

```html
<h1>One Thousand and One Nights</h1>
```

<output></output>

```javascript
screen.getByRole('heading');
```

<h2 id=links>Links</h2>

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

<h2 id=lists>Lists</h2>

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

<h2 id=terms>Terms & Definitions</h2>

```html
<dl>
  <dt id=movie-1-name>Name</dt>
  <dd aria-labelledby=movie-1-name>The Lion King</dd>
  
  <dt id=movie-1-year>Year Released</dt>
  <dd aria-labelledby=movie-1-year>1994</dd>
  
  <dt id=movie-1-runtime>Runtime</dt>
  <dd aria-labelledby=movie-1-runtime>88 min</dd>
</dl>
```

<output></output>

```javascript
screen.getByRole('definition', { name: 'Name' });
```

```javascript
screen.getByRole('definition', { name: 'Year Released' });
```

```javascript
screen.getByRole('definition', { name: 'Runtime' });
```

<h2 id=images>Images</h2>

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

<h2 id=figures>Figures</h2>

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

<h2 id=details>Details & Summary</h2>

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

<h2 id=separator>Separator</h2>

```html
Before
<hr>
After
```

<output></output>

```javascript
screen.getByRole('separator');
```

<hr>

<table class="text-left table-fixed">
  <caption id=cheatsheet class="text-3xl pb-4 text-left">Content roles cheatsheet</caption>
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
