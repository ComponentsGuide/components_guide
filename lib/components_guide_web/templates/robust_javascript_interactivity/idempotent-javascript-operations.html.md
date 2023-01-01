# Idempotent JavaScript Operations

// Could call this ‘Robust UI State’
// Could move this to concurrent_safe_models

Here I’m going to use the example of an online video service like Netflix, where we can do things like add a show to a list, start playing a show, perform a search.

## Adding and removing a show from a user’s list

Apps like Netflix allow you to add a show to a list to watch later. If you’re like me, you rarely get around to actually watching them.

To implement this, we could use an array that holds all the show IDs like so:

```js
const watchLater = [];

function add(showID) {
  watchLater.push(showID);
  console.log(watchLater);
}

add(123);
// [123]
```

However, there’s an issue when we add the same item twice:

```js
add(123);
add(123);
// The same show ID appears twice :(
// [123, 123]
```

We could fix this by adding logic to detect whether the item is already in the array, and skip adding it if so:

```js
function add(showID) {
  if (watchLater.includes(showID)) {
    return;
  }

  watchLater.push(showID);
  console.log(watchLater);
}
```

But wouldn’t it be great if we had a simpler solution? It’s annoying to have to think of these edge cases and code around them.

If we change our data structure to one that enforces uniqueness from the beginning, then our double entry problem is solved.

In JavaScript, a `Set` is a data structure that is ordered just like an array, but it enforces uniqueness:

```js
const watchLater = new Set();

function add(showID) {
  watchLater.add(showID);
  console.log(watchLater);
}

add(123);
add(123);
// Appears only once :)
// Set { 123 }
```

We can extend this for also removing an item from the list:

```js
const watchLater = new Set();

function add(showID) {
  watchLater.add(showID);
  console.log(watchLater);
}

function remove(showID) {
  watchLater.delete(showID);
  console.log(watchLater);
}

add(123);
add(123);
// Appears once, is idempotent :)
// Set { 123 }
remove(123);
remove(123);
// Removed without erroring the second time, also idempotent :)
// Set {}
```

As a bonus, we can add change tracking which would allow us to detect whether the data has actually changed, and and if not, then avoid say a re-render.

```js
const watchLater = new Set();
let watchLaterChangeCount = 0;

function add(showID) {
  const before = watchLater.size;
  watchLater.add(showID);

  if (watchLater.size > before) {
    watchLaterChangeCount++;  
  }
  // OR
  // watchLaterChangeCount += watchLater.size - before;
}

function remove(showID) {
  const before = watchLater.size;
  watchLater.delete(showID);

  if (before > watchLater.size) {
    watchLaterChangeCount++;  
  }
  // OR
  // watchLaterChangeCount += before - watchLater.size;
}

// watchLaterChangeCount: 0
add(123);
// watchLaterChangeCount: 1
add(123);
// watchLaterChangeCount: 1
remove(123);
// watchLaterChangeCount: 2
remove(123);
// watchLaterChangeCount: 2
```

If you prefer classes, we could write this as:

```js
const IDS_KEY = Symbol('ids'); // Our private data.
class MyList {
  constructor() {
    this[IDS_KEY] = new Set();
    this.changeCount = 0;
  }

  toArray() {
    return Array.from(this[IDS_KEY]);
  }

  add(showID) {
    const before = this[IDS_KEY].size;
    this[IDS_KEY].add(showID);

    if (this[IDS_KEY].size > before) {
      this.changeCount++;
    }
  }

  remove(showID) {
    const before = this[IDS_KEY].size;
    this[IDS_KEY].delete(showID);

    if (this[IDS_KEY].size < before) {
      this.changeCount++;
    }
  }
}


const myList = new MyList();
// myList.changeCount: 0
myList.add(123);
// myList.changeCount: 1
myList.add(123);
// myList.changeCount: 1
myList.remove(123);
// myList.changeCount: 2
myList.remove(123);
// myList.changeCount: 2
```

----

## Searching

Before:

```js
let searchResults = null;
let searchError = null;

async function performSearch(searchQuery) {
  const params = new URLSearchParams({ q: searchQuery });
  try {
    searchResults = await fetch(`/search?${params}`).then(res => res.json());
    searchError = null;
  }
  catch (error) {
    searchError = error;
    searchResults = null;
  }
}

performSearch('stranger things');
performSearch('stranger things');
// Two requests are made! :(
performSearch('russian doll');
// Response to earlier request might come after latest request’s response :(
```

After:

```js
let currentSearchQuery = null;
let searchQueryChangeCount = 0;
let searchResultsChangeCount = 0;
let searchResults = null;
let searchError = null;

function performSearch(searchQuery) {
  if (currentSearchQuery === searchQuery) {
    return;
  }

  currentSearchQuery = searchQuery;
  searchQueryChangeCount++;
  const params = new URLSearchParams({ q: searchQuery });

  const expectedChangeCount = searchQueryChangeCount;
  fetch(`/search?${params}`)
    .then(res => res.json())
    .then(results => {
      if (expectedChangeCount !== searchQueryChangeCount) {
        // Ignore this response as it was from earlier.
        return;
      }

      // Success!
      searchResults = results;
      searchError = null;
      searchResultsChangeCount++;
    })
    .catch(error => {
      if (expectedChangeCount !== searchQueryChangeCount) {
        // Ignore this error response as it was from earlier.
        return;
      }

      searchError = error;
      searchResults = null;
      searchResultsChangeCount++;
    });
}

performSearch('stranger things');
performSearch('stranger things');
// Only one request is made! :)
performSearch('russian doll');
// Responses from earlier requests are ignored :)
```

Even better with `AbortSignal`:

```js
let aborter = new AbortController();
let currentSearchQuery = null;
let searchResultsChangeCount = 0;
let searchResults = null;
let searchError = null;

function performSearch(searchQuery) {
  if (currentSearchQuery === searchQuery) {
    return;
  }

  currentSearchQuery = searchQuery;
  // Cancel any previous requests.
  aborter.abort();
  aborter = new AbortController();

  const params = new URLSearchParams({ q: searchQuery });

  fetch(`/search?${params}`, { signal: aborter.signal })
    .then(res => res.json())
    .then(results => {
      // Success!
      searchResults = results;
      searchError = null;
      searchResultsChangeCount++;
    })
    .catch(error => {
      if (error instanceof DOMError && error.name === 'AbortError') {
        // Ignore as this request has been cancelled.
        return;
      }

      // Failure!
      searchError = error;
      searchResults = null;
      searchResultsChangeCount++;
    });
}

performSearch('stranger things');
performSearch('stranger things');
// Only one request is made! :)
performSearch('russian doll');
// Earlier requests are cancelled :)
```

----

```js
const CLOCK = Symbol('clock');
const ABORTER = Symbol('aborter');
class Ticker {
  constructor() {
    this[CLOCK] = 0;
    this[ABORTER] = new AbortController();
  }

  next() {
    this[CLOCK]++;

    this[ABORTER].abort();
    this[ABORTER] = new AbortController();
  }

  get signal() {
    this[ABORTER].signal;
  }
}

const VALUE = Symbol('value');
class ValueTicker extends Ticker {
  constructor(initialValue) {
    super();
    this[VALUE] = initialValue;
  }

  next(nextValue) {
    if (this[VALUE] === nextValue) {
      return false;
    }

    super();
    this[VALUE] = nextValue;
    return true;
  }
}
```

```js
const ticker = new ValueTicker('');
let searchResults = null;
let searchError = null;
let searchResultsChangeCount = 0;

function performSearch(searchQuery) {
  if (!ticker.next(searchQuery)) {
    return;
  }

  const params = new URLSearchParams({ q: searchQuery });

  fetch(`/search?${params}`, { signal: ticker.signal })
    .then(res => res.json())
    .then(results => {
      // Success!
      searchResults = results;
      searchError = null;
      searchResultsChangeCount++;
    })
    .catch(error => {
      if (error instanceof DOMError && error.name === 'AbortError') {
        // Ignore as this request has been cancelled.
        return;
      }

      // Failure!
      searchError = error;
      searchResults = null;
      searchResultsChangeCount++;
    });
}

performSearch('stranger things');
performSearch('stranger things');
// Only one request is made! :)
performSearch('russian doll');
// Earlier requests are cancelled :)
```

----

Draft: coming soon perhaps?

## Switching profiles

```js
let currentProfileID = null;
let currentProfileChangeCount = 0;

function changeProfile(profileID) {
  if (currentProfileID === profileID) {
    return;
  }

  currentProfileID = profileID;
  currentProfileChangeCount++;
}

// currentProfileID: null
// currentProfileChangeCount: 0
changeProfile(123);
// currentProfileID: 123
// currentProfileChangeCount: 1
changeProfile(123);
// currentProfileID: 123
// currentProfileChangeCount: 1
```
