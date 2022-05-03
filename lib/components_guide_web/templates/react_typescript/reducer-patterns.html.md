# React Reducer Patterns

## One-Way Flag

```js
const [isEnabled, enable] = useReducer(() => true, false);
```

[Source](https://twitter.com/markdalgleish/status/1521304112738217984)

## Toggle Flag

```js
const [on, toggle] = useReducer(flag => !flag, false)
```

[Source](https://twitter.com/FernandoTheRojo/status/1521305729558274048)

## Menu

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

tap("file") // "file"
tap(null) // null
tap("file") // "file"
tap("file") // null
tap("file") // "file"
tap("edit") // "edit"
tap("view") // "view"
tap("edit") // "edit"
tap("edit") // null
tap(null) // null
```

You can of course condense it to a ternary if you want:

```ts
// You can of course shorten it into a ternary if you really want:
const [openMenu, tap] = useReducer(
  (current: Menu, action: Menu) => (action === current) ? null : action,
  null
);
```
