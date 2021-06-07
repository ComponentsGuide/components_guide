# Refactoring Accessibility

<script type="module">
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
      
      const screen = DOMTesting.within(div);
      const testFunction = new Function('screen', `return ${code}`);
      [].concat(testFunction(screen)).forEach(el => el.classList.add('border-4', ...classNames));
      
      javascriptIndex++;
    }
  }
}
</script>

## Headings

- When to use `<h1>`?
- Examples from news websites of their hierarchy

Here’s an example from The Economist:

```html
<header>
  <h1>
    <span>
      Silent sigh
    </span>
    <br>
    <span itemprop="headline">
      South Korea is pushing America for new talks with the North
    </span>
  </h1>
  <p itemprop="description">
    The 70-year stalemate between the two Koreas is unlikely to break without fresh diplomacy
  </p>
</header>
```

<output></output>

```javascript
screen.getByRole('heading');
```

## Navigation

- Before: `class="current"`
- After: `aria-current="page"`

## Tooltip

- Before: interactive tooltip that appears only after clicking a very small target
- After: description hint text that is always shown, with `aria-describedby`
