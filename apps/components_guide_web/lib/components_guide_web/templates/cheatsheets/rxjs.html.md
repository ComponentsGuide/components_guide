# RxJS Cheatsheet

<!--<script defer src="https://unpkg.com/rxjs@7.0.0/dist/bundles/rxjs.umd.js"></script>
<script defer>
console.log('window', Object.keys(window));
</script>-->

<script type="module">
console.log('go1');
import * as RxJS from "https://cdn.jsdelivr.net/npm/rxjs@7.0.0/dist/esm/index.js";
</script>

<script type="module">
console.log('go2');
/*import * as RxJS from "https://cdn.skypack.dev/rxjs";*/

/* import * as RxJS from "https://unpkg.com/rxjs@7.0.0/dist/esm/index.js?module"; */
/* import * as RxJS from "https://unpkg.com/rxjs@7.0.0?module"; */
/* import * as operators from "https://unpkg.com/rxjs@7.0.0/dist/esm/operators/index.js?module"; */

/* console.log({ operators }); */

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
    if (type === 'javascript') {
      const classNames = classNamesFor(javascriptIndex);
      
      el.classList.add('border-l-4', ...classNames);
      const list = el.appendChild(document.createElement('ol));
      
      const args = [RxJS['of'], operators.map];
      const testFunction = new Function('of2', 'map', `return ${code}`);
      [].concat(testFunction(...args)).forEach(o$ => {
        o$.subscribe({
          next: value => {
            list.appendChild(Object.assign(document.createElement('li'), { textContent: `${value}` }));
          }
        })
      });
      
      javascriptIndex++;
    }
  }
}
</script>

## Hot vs Cold

A **hot observable** models something that is happening that you can tune into.

An example is listening to click events from the user. You can tune into this, and tune out, but your observation has no effect on when click events happen. It’s up to the user!

📻 This is similar to tuning into the radio. A radio receiver can tune into a broadcast show, but the act of tuning in doesn’t affect whether the show starts or not. And if that receiver is turned off, it doesn’t shut down the show. If multiple receivers are tuned in, they receive the same signal.

A **cold observable** is something that is started via the act of subscribing. A HTTP request is made only when a subscriber is added. And if multiple subscribers are added, then multiple HTTP requests are sent.

🥞 This is similar to ordering a plate of fresh pancakes. They are made on-the-fly just for you. If your particular order asks for gluten-free flour or extra topping, then that effects the result.

## Stateful vs Eventful Observables

A stateful observable is something that models a mutable value. When you subscribe, you immediately receive the current value. If the value is changed, then all subscribers receive that value.

If the value is changed, and _then_ someone subscribes they will still receive that value — they won’t miss out.

📰 This is similar to a news subscription that sends you the latest news. And when you start subscribing you’ll receive the current edition.

An eventful obsevable is something that models a stream of messages. When you subscribe, you won’t immediately receive the latest value. If a message is sent, then all subscribers receive that value.

If a message is sent, and _then_ someone subscribes they will miss out on that value.

🚇 This is similar to catching public transport. When you arrive at the platform, you can only catch the next train that passes. The last one won’t reverse and let you on.

## Exceptions vs Error Values

An exception is a failure. Maybe the server is not available. Or a parsing error occured.

Errors in RxJS cause the pipeline to blow up and terminate. Once an exception happens, it’s over.

You can recover from exceptions, which stop the termination from happening and keeps the pipeline alive. It’s up to you to decide _how_ you want to recover. You can do this with the `catchError()` operator.

If you are still interested in the error itself, you can transform it to an event value. Then your observable emits either a success value or a failure value. Because the failures are just value they won’t terminate your pipeline. This is not a built-in feature of RxJS, so you must model this behaviour yourself.

## Useful Operators

### `map()`

<output></output>

```javascript
of2(10).pipe(
  map(n * 2)
);
```

### `filter()`

### `switchMap()`

### `catchError()`

### `scan()`

### `map() + merge()`

### Why to avoid `combineLatest()`

## Anti-pattern: merging in a source observable down stream

