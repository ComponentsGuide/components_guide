# React Reducer Patterns

## One-Way Flag

```js
const [isEnabled, enable] = useReducer(() => true, false);

isEnabled; // false
enable();
isEnabled; // true
enable();
isEnabled; // true
```

[Source](https://twitter.com/markdalgleish/status/1521304112738217984)

## Toggle Flag

```js
const [on, toggle] = useReducer(flag => !flag, false);

on; // false
toggle();
on; // true
toggle();
on; // false
toggle();
on; // true
```

[Source](https://twitter.com/FernandoTheRojo/status/1521305729558274048)

## Menu or Exclusive Value

```ts
type Menu = null | "file" | "edit" | "view"; // null means closed

const [openMenu, tap] = useReducer(
  (current: Menu, action: Menu) => {
    if (action === current) {
      return null; // Close if matches
    }

    return action; // Use passed value
  },
  null
);

tap("file");
openMenu; // "file"
tap(null);
openMenu; // null
tap("file");
openMenu; // "file"
tap("file");
openMenu; // null
tap("file");
openMenu; // "file"
tap("edit");
openMenu; // "edit"
tap("view");
openMenu; // "view"
tap("edit");
openMenu; // "edit"
tap("edit");
openMenu; // null
tap(null);
openMenu; // null
```

You can of course condense it to a ternary if you want:

```ts
// You can of course shorten it into a ternary if you really want:
const [openMenu, tap] = useReducer(
  (current: Menu, action: Menu) => (action === current) ? null : action,
  null
);
```

## Jitter Generator

Inspired by [AWS: Exponential Backoff And Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)

```js
const baseMs = 5;
const capMs = 2000;
const [{attempt, delayMs}, dispatch] = useReducer((state, random) => {
  return {
    attempt: state.attempt + 1,
    delayMs: random * Math.min(capMs, baseMs * Math.pow(2, attempt))
  };
}, { attempt: 0, delay: baseMs });
const nextAttempt = useCallback(() => dispatch(Math.random()), [dispatch]);
```

## Logical Clock

```js
const [t, tick] = useReducer(n => n + 1, 0);

t; // 0
tick();
t; // 1
tick();
t; // 2
tick();
t; // 3
```

----

## Lamport Timestamp

```js
const [{ t, toSend }, dispatch] = useReducer((state, command) => {
  if (command.type === "send") {
    const t = state.t + 1;
    return {
      t,
      toSend: {
        t,
        message: command.message
      }
    };
  } else if (command.type === "receive") {
    const t = Math.max(state.t, command.t) + 1;
    return {
      t,
      toSend: null
    };
  } else {
    return {
      t: state.t,
      toSend: null
    };
  }
}, { t: 0, toSend: null });
useEffect(() => {
  if (toSend !== null) {
    send(toSend.message, toSend.t); // Second argument can be used for idempotency
  }
}, [toSend]);

t; // 0
toSend; // null
dispatch({ type: "send", message: "hello" });
t; // 1
toSend; // { t: 1, message: "hello" }
dispatch({ type: "receive", t: 3, message: "howdy" });
t; // 4
toSend; // null
```
