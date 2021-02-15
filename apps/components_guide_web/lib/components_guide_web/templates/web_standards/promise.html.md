# Thinking about Promises

## Promises act as values

You can think of a Promise as an eventual value. It either succeeds with a particular success value, or it possibly fails with an error value.

<div class="my-4 flex text-center text-3xl text-black bg-white rounded shadow-lg">
  <div class="flex-grow p-4 bg-green-300 border border-green-400">
    <div class="space-y-2">
      <div>Resolve with</div>
      <div class="px-4 text-white bg-black border-4 border-green-100 border-dashed rounded-full">
        Value
      </div>
    </div>
  </div>
  <div class="flex-grow p-4 bg-red-300 border border-red-400">
    <div class="space-y-2">
      <div>Reject with</div>
      <div class="px-4 text-white bg-black border-4 border-red-100 border-dashed rounded-full">
        Error
      </div>
    </div>
  </div>
</div>

It either *resolves* to a success value:

<div class="my-4 flex text-center text-3xl text-black shadow-lg">
  <div class="flex-grow p-4 bg-green-300 border border-green-400">
    <div class="space-y-2"><div>✅ Resolved with</div> <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">42</div></div>
  </div>
  <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
</div>

```javascript
// Succeed with the value 42
Promise.resolve(42);

// Longer version of above
new Promise((resolve, reject) => {
  resolve(42);
});
```

Or it *rejects* with an error value:

<div class="my-4 flex text-center text-3xl text-black">
  <div class="flex-grow p-4 bg-green-300 border border-green-400 opacity-25"></div>
  <div class="flex-grow p-4 bg-red-300 border-red-400">
    <div class="space-y-2">
      <div>❌ Rejected with</div>
      <div class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</div>
    </div>
  </div>
</div>

```javascript
// Fail with the error *out of stock*
Promise.reject(new Error("out of stock"));

// Longer version of above
new Promise((resolve, reject) => {
  reject(new Error("out of stock"));
});

// Alternate version of above
new Promise((resolve, reject) => {
  throw new Error("out of stock");
});
```

Once a Promise has receive its value, you can’t changed that value. If it was told it failed, it can’t be changed to succeed instead. And if it succeeded, it can’t later fail.

```javascript
new Promise((resolve, reject) => {
  // Once a promise has been resolved or rejected
  resolve(42);
  // it can’t then be resolved again
  resolve(42); // Invalid!
  // or be rejected later
  reject(new Error("out of stock")); // Invalid!
});
```

## Chaining Promises

A Promise can create a _new_ Promise by calling `.then()` on it.

<div class="my-4 flex flex-col text-center text-3xl text-black shadow-lg">
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400">
      <div class="space-y-2">
        <div>✅ Resolved with</div>
        <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">42</div>
      </div>
    </div>
    <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
  </div>
  <div class="p-4 text-white bg-black">
    <div>⬇ .then</div>
    <div>Multiply value by 2</div>
  </div>
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400">
      <div class="space-y-2">
        <div>✅ Resolved with</div>
        <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">84</div>
      </div>
    </div>
    <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
  </div>
</div>

```javascript
Promise.resolve(42)
  .then(value => {
    return value * 2;
  });
  
// Longer version of above
Promise.resolve(42)
  .then(value => {
    return Promise.resolve(value * 2);
  });
```

The callback to `.then()` can fail, either by throwing an error, or returning a rejected Promise:

<div class="my-4 flex flex-col text-center text-3xl text-black shadow-lg">
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400">
      <div class="space-y-2">
        <div>✅ Resolved with</div>
        <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">42</div>
      </div>
    </div>
    <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
  </div>
  <div class="p-4 text-white bg-black">
    <div>⬇ .then</div>
    <div>Throw <span class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</span></div>
  </div>
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400 opacity-25"></div>
    <div class="flex-grow p-4 bg-red-300 border-red-400">
      <div class="space-y-2">
        <div>❌ Rejected with</div>
        <div class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</div>
      </div>
    </div>
  </div>
</div>

```javascript
Promise.resolve(42)
  .then(value => {
    throw new Error("out of stock");
  });
  
// Longer version of above
Promise.resolve(42)
  .then(value => {
    return Promise.reject(new Error("out of stock"));
  });

// Alternative version of above
// Note the Promises can be created up-front.
const outOfStockError = Promise.reject(new Error("out of stock"));
Promise.resolve(42)
  .then(value => {
    return outOfStockError;
  });
```

If a Promise fails, any derived Promises will also fail.

<div class="my-4 text-center text-3xl text-black shadow-lg">
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400">
      <div class="space-y-2">
        <div>✅ Resolved with</div>
        <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">42</div>
      </div>
    </div>
    <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
  </div>
  <div class="p-4 text-white bg-black">
    <div>⬇ .then</div>
    <div>Throw <span class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</span></div>
  </div>
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400 opacity-25"></div>
    <div class="flex-grow p-4 bg-red-300 border-red-400">
      <div class="space-y-2">
        <div>❌ Rejected with</div>
        <div class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</div>
      </div>
    </div>
  </div>
  <div class="text-white bg-black">⬇ .then</div>
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400 opacity-25"></div>
    <div class="flex-grow p-4 bg-red-300 border-red-400">
      <div class="space-y-2">
        <div>❌ Rejected with</div>
        <div class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</div>
      </div>
    </div>
  </div>
</div>

```javascript
Promise.resolve(42)
  .then(value => {
    throw new Error("out of stock");
  })
  .then(value => {
    // This will never get called as the previous promise was rejected
  });
```

A Promise chain can be recovered by calling `.catch()` and returning another value or Promise.

<div class="my-4 text-center text-3xl text-black shadow-lg">
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400">
      <div class="space-y-2">
        <div>✅ Resolved with</div>
        <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">42</div>
      </div>
    </div>
    <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
  </div>
  <div class="p-4 text-white bg-black">
    <div>⬇ .then</div>
    <div>Throw <span class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</span></div>
  </div>
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400 opacity-25"></div>
    <div class="flex-grow p-4 bg-red-300 border-red-400">
      <div class="space-y-2">
        <div>❌ Rejected with</div>
        <div class="px-4 text-white bg-red-700 border-4 border-red-900 rounded-full">Error: out of stock</div>
      </div>
    </div>
  </div>
  <div class="p-4 text-white bg-black">
    <div>⬇ .catch</div>
    <div>Return <span class="px-4 text-white bg-gray-700 border-4 border-gray-900 rounded-full">3</span></div>
  </div>
  <div class="flex flex-row">
    <div class="flex-grow p-4 bg-green-300 border border-green-400">
      <div class="space-y-2">
        <div>✅ Resolved with</div>
        <div class="px-4 text-white bg-green-700 border-4 border-green-900 rounded-full">3</div>
      </div>
    </div>
    <div class="flex-grow p-4 bg-red-300 border-red-400 opacity-25"></div>
  </div>
</div>

```javascript
export const a = Promise.resolve(42)
  .then(value => {
    throw new Error("out of stock");
  })
  .catch(error => {
    return 3;
  });

// Same as above
export const b = Promise.resolve(42)
  .then(value => {
    throw new Error("out of stock");
  })
  .catch(error => {
    return Promise.resolve(3);
  });

// Same as above
const fallbackPromise = Promise.resolve(3);
export const c = Promise.resolve(42)
  .then(value => {
    throw new Error("out of stock");
  })
  .catch(error => {
    return fallbackPromise;
  });

// Same as above
const promiseThatWillFail = Promise.resolve(42).then(value => {
  throw new Error("out of stock");
});
export const d = promiseThatWillFail.catch(error => {
  return fallbackPromise;
});
```

----

## Promises are eager

Let's compare two code samples. How many times will we see _Creating value_ logged?

```js
const promisedValue = new Promise((resolve, reject) => {
  // Will this be logged once or not at all?
  console.log("Creating value");
  resolve(40 + 2);
});
```

```js
const promisedValue = new Promise((resolve, reject) => {
  // Will this logged three times or once?
  console.log("Creating value");
  resolve(40 + 2);
});

promisedValue.then(console.log);
promisedValue.then(console.log);
promisedValue.then(console.log);
```

In both cases, we will see it logged only once. This is because promises are run once and created eagerly.

Listening to a promise using `.then()` neither affects nor starts that promise. It has no side-effect on the source promise.

Once a promise has been created, then you may wait to hear its result one time, fifteen times, or not at all, and the original promise will behave the same.

This may seem like a strange limitation, but it simplifies reasoning about promises as they work similar to _values_.

### How values work

If we store a value in a variable, we can feel comfortable knowing that the reading of that variable has absolutely no effect on its underlying value.

```js
const value = 40 + 2;

console.log(value);
console.log(value);
console.log(value);
```

The value of `42` will be logged three times, but if the logs were removed altogether, the variable’s value won’t be affected and will remain the same. The act of logging had no effect on the source value.

Promises work exactly the same.

We can use this to our advantage, by thinking about promises in the same way we think about values.

### Reusing

If data is loaded from an API, we might use `fetch()`.

```javascript
const promisedResponse = fetch('https://swapi.dev/api/people/1/');
```

We can chain the response to decode the JSON body of the response.

```javascript
const promisedData = fetch('https://swapi.dev/api/people/1/')
  .then(response => response.json());
```

What happens if we want to use this data again?

```javascript
const promisedData = fetch('https://swapi.dev/api/people/1/')
  .then(response => {
    // How many times will we see this logged?
    console.log('decoding data');
    return response.json();
  });

promisedData.then(data => {
  // Use data
});

promisedData.then(data => {
  // Use data again
});
```

Here we will see *‘decoding data’* logged once. The `fetch()` call returns a Promise, which is chained using `.then()` where we decode the underlying JSON body by calling `.json()` on the response.

We can continue to think of these as eventual values. Once these values have been cast, they cannot change (technically we could mutate anything as JavaScript gives us free reign but we shouldn’t).

The response from `fetch()` is one eventual value. The decoded JSON is another eventual value, and actually has two Promises, one created by the `.json()` method, and another wrapping that which was created by `.then()`.

```javascript
const promisedResponse = fetch('https://swapi.dev/api/people/1/');
const promisedData = promisedResponse.then(response => {
  const promisedDataInner = response.json();
  return promisedDataInner;
});
```

### Failure recovery

```javascript
const fallbackData = {
  name: "Jane Doe",
  height: "168",
  mass: "67",
};

fetch('https://swapi.dev/api/people/1/')
  .then(res => res.data())
  .catch(() => fallbackData);
```

### Async Await

The same applies if the code is rewritten to use `async await`. The underlying objects are still Promises.

The difference is that `async` requires a function, which means the code is run from scratch each time.

Here’s our API call written as a function using Promises:

```javascript
const apiURL = new URL('https://swapi.dev/api/');

function fetchPerson(id) {
  return fetch(new URL(`people/${id}/`, apiURL))
    .then(response => {
      // How many times will we see this logged?
      console.log('decoding data');
      return response.json();
    });
}

function main() {
  fetchPerson('1'); // *Creates* promise
  fetchPerson('1'); // *Creates* another promise
  // We will see 'decoding data' logged twice,
  // as our function is run from scratch twice.
}

main();
```

And here’s that code rewritten to use `async await`.

```javascript
const apiURL = new URL('https://swapi.dev/api/');

async function fetchPerson(id) {
  const response = await fetch(new URL(`people/${id}/`, apiURL));
  // How many times will we see this logged?
  console.log('decoding data');
  // Note: if we return a Promise, then there’s no need to await
  return response.json();
}

async function main() {
  await fetchPerson('1'); // *Creates* promise
  await fetchPerson('1'); // *Creates* another promise
  // We will see 'decoding data' logged twice,
  // as our function is run from scratch twice.
}

main();
```

However, if we use the result from our `fetchPerson()` function (which we be a Promise), and `await` that twice (or more) then since we are running the function only once we will see the *‘decoding data’* message logged only once too.

```javascript
async function main() {
  const promise = fetchPerson('1');  // *Creates* promise

  await promise;
  await promise;
  // We will see 'decoding data' logged only once,
  // as our function is run only once.
}

main();
```

This is conceptually similar to calling `.then()` on the promise twice.

```javascript
function main() {
  const promise = fetchPerson('1');

  promise.then(data => {
    // Do nothing
  });
  promise.then(data => {
    // Do nothing
  });

  // We will see 'decoding data' logged only once,
  // as our function is run only once.
}

main();
```

As we learned earlier, listening to a promise using `.then()` neither affects nor starts that promise — it has no side-effect on that promise. And `await` behaves the same — it also has no side-effect on the source promise. It simply waits for its eventual value.
