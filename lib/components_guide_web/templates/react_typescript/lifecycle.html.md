# React Lifecycle

1. Initial render.
2. Initial DOM is created.
3. Browser performs layout and repainting.
4. External event occurs (e.g. user interaction, promise completes).
5. State changes.
6. Component subtree is rendered.
7. UI differences are applied to DOM.
8. Browser performs layout and repainting.

## Client-only

1. Initial render:
    1. Calls root component (e.g. `App`) to get its returned elements.
    2. Iterates through elements and calls their components, and so on, until we have all leaf elements that represent HTML elements.
    3. Creates DOM elements for each leaf React element, and inserts them on the page.
    4. Runs `useLayoutEffect` callbacks.
    5. Browser performs layout and repainting.
    6. Runs `useEffect` callbacks.
2. A component within the tree changes state:
    1. Schedules update.
    2. Update starts.
    3. Calls the changed component to get its returned elements.
    4. Iterates through elements and calls their components, and so on, until we have all leaf elements that represent HTML elements.
    5. Compares the new leaf elements to the previously committed leaf elements.
    6. Updates/replaces/removes DOM elements for each leaf React element.
    7. Runs `useLayoutEffect` callbacks.
    8. Browser performs layout and repainting.
    9. Runs `useEffect` callbacks.

## Not included (yet?)

- Hydration from server to client rendering
- Suspense
- `useDeferredValue`
- React Server Components
- Server streaming

## Next.js

## Example

```jsx

```
