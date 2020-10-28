# Promise

You can think of a Promise as a value. Once a Promise has been created, you can’t changed the value. Sooner or later its value will be given — as promised. (Or it may fail with an error. More on that later.)

## Promises are eager

Let's compare two code samples.

```js
const promisedValue = new Promise((resolve, reject) => {
  console.log("Creating value");
  resolve(40 + 2);
});
```

How many times will we see _Creating value_ logged?

```js
const promisedValue = new Promise((resolve, reject) => {
  console.log("Creating value");
  resolve(40 + 2);
});

promisedValue.then(console.log);
promisedValue.then(console.log);
promisedValue.then(console.log);
```

Any how many times will we see _Creating value_ logged here?

In both cases, we will see it logged only once, because promises are created eagerly.

Listening to a promise using `.then()` does not affect nor start that promise.

Once a promise has been created, then you may wait to hear its result one time, fifteen times, or not at all, and the original promise will behave the same.

This may seem like a strange limitation, but it simplifies reasoning about promises as they work similar to _values_.

### How values work

If we store a value in a variable, we feel comfortable knowing that the reading of that variable has absolutely no effect on its value.

```js
const value = 40 + 2;

console.log(value);
console.log(value);
console.log(value);
```

42 will be logged three times, but if removed the logs altogether, the value will remain the same. The act of logging had no effect on the source value.

Promises work exactly the same.

We can use this to our advantage, by thinking about promises in the same way we think about values.
