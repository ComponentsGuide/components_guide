# Promise

You can think of a Promise as a value. Once a Promise has been created, you can’t changed the value. Sooner or later its value will be given — as promised. (Or it may fail with an error. More on that later.)

## Promises are eager

Let's compare two code samples. How many times will we see _Creating value_ logged?

```js
const promisedValue = new Promise((resolve, reject) => {
  console.log("Creating value"); // Will this be logged once or not at all?
  resolve(40 + 2);
});
```

```js
const promisedValue = new Promise((resolve, reject) => {
  console.log("Creating value"); // Will this logged three times or once?
  resolve(40 + 2);
});

promisedValue.then(console.log);
promisedValue.then(console.log);
promisedValue.then(console.log);
```

In both cases, we will see it logged only once. This is because promises are run once are created eagerly.

Listening to a promise using `.then()` does not affect nor start that promise. It has no side-effects on the source promise.

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
const promisedData = fetch('https://swapi.dev/api/people/1/').then(response => response.json());
```

What happens if we want to use this data again?

```javascript
const promisedData = fetch('https://swapi.dev/api/people/1/')
  .then(response => {
    console.log('decoding data'); // How many times will we see this logged?
    return response.json();
  });

promisedData.then(data => {
  // Use data
});

promisedData.then(data => {
  // Use data again
});
```

Here will see `decoding data` logged once. The `fetch()` call returns a Promise, which is chained using `.then()` to unwrap the underlying JSON body by calling `.json()` on the response.

We can continue to think of these as eventual values. Once these values have been cast, they cannot change (technically we could mutate anything as JavaScript gives us free reign but we shouldn’t).

The response from `fetch()` is one eventual value. The decode JSON is another eventual value, and actually has two Promises, one created by the `.json()` method, and another wrapping that created by `.then()`.

```javascript
const promisedResponse = fetch('https://swapi.dev/api/people/1/');
const promisedData = promisedResponse.then(response => {
  const promisedDataInner = response.json();
  return promisedDataInner;
});
```

If it seems confusing that there’s actually two Promises for the one JSON value, consider if we delayed

```javascript
function callIn(timeout) {
  return {
    then: (callback) => setTimeout(callback, timeout)
  };
}

Promise.resolve(callIn(500));

const promisedResponse = fetch('https://swapi.dev/api/people/1/');
const promisedData = promisedResponse.then(response => {
  return {
    then: (callback, reject) => {
      console.log('reject', reject);
      setTimeout(() => {
        callback(response.json());
      }, 1000);
    }
  }
});
```

### Async Await

The same applies if the code is rewritten to use `async await`. The underlying objects are still Promises.

### Failure

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

### Caching

```javascript
function sideEffect(send, transform) {
  return (value) => ({
    then(resolve) {
      const transformed = transform(value);
      resolve(transformed);
      send(transformed);
    }
  })
}

function cacheStorer(cache, key, transform) {
  return sideEffect(value => cache.set(key, transform(value)));
}

function localStorageStorer(key) {
  return sideEffect(value => window.localStorage.setItem(key, value));
}

const cachedValues = new WeakMap();
function useCacheKey(cache, key) {
  return [cache.get.bind(cache, key), cache.set(cache, key)];
}

function fetchCached(url) {
  const [read, write] = useCacheKey(cachedValues, url);

  const promise = read(url);
  if (promise) {
    return promise;
  } else {
    return fetch(url).then(
      sideEffect(write, Promise.resolve),
      sideEffect(write, Promise.reject)
    );
  }
}
function fetchCached(url) {
  return Promise.resolve(cachedValues.get(url) || fetch(url).then(cacheStorer(cachedValues, url)));
}
```

### Chaining
