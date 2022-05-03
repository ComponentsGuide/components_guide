# React Reducer Patterns

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
