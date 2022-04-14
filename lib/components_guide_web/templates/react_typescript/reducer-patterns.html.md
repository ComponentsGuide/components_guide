# React `useReducer` patterns

## Multiple controls where only one can be open at a time

```ts
type FilterValue = null | "first" | "second" | "third"; // null means closed

const [openFilter, dispatchOpen] = useReducer(
  (current: FilterValue, action: FilterValue) => {
    if (action === current) {
      return null;
    }

    return action;
  },
  null
);

dispatchOpen("first") // "first"
dispatchOpen(null) // null
dispatchOpen("first") // "first"
dispatchOpen("first") // null
dispatchOpen("first") // "first"
dispatchOpen("second") // "second"
dispatchOpen("third") // "third"
dispatchOpen("second") // "second"
dispatchOpen("second") // null
dispatchOpen(null) // null
```
