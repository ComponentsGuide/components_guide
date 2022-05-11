# Simplify React Effects with Logical Clocks

## Problems

Hooks offer a more flexible and powerful suite of tools than we had a few years ago in React with class components’ lifecycle methods.

Each hook tries to follow the unix philosophy: have small tools that solve one particular task well. For example, `useState()` solves many needs for a mutable variable that belongs to a component.

However, while React has certainly made the *what* easier with the declarative model of building a view, getting the *when* right proves to be a lot harder. Hooks like `useEffect()` can appear simple but are difficult to compose together and to visualise. By using logical clocks, we can get back towards the declarative model that we all love in React.

## What is a logical clock?

A logical clock is a monotonically increasing number. Or in other words, an incremented integer: `i++`.

We can implement once as a React hook using `useReducer()`:

```ts
function useTicker() {
  return useReducer(t => t + 1, 0);
}
```

We can wire it up to a button like so:

```ts
const [count, advance] = useTicker();

return <>
  <p>You have clicked {count} times</p>
  <button onClick={advance}>Click me!</button>
</>;
```

## Debouncing

```ts
export function useDebouncedTicker(duration: number): readonly [number, EffectCallback] {
  const [count, advance] = useTicker();

  const callback = useMemo(() => {
    let timeout: null | ReturnType<typeof setTimeout> = null;
    function clear() {
      if (timeout) {
        clearTimeout(timeout);
        timeout = null;
      }
    }
    return () => {
      clear()
      timeout = setTimeout(advance, duration);
      return clear;
    };
  }, [duration, advance]);

  return [count, callback];
}
```

```ts
export function useDebouncedEffect(effect: EffectCallback, duration: number, deps: DependencyList): void {
  const [count, receive] = useDebouncedTicker(duration);
  useEffect(receive, deps); // When our deps change, notify our debouncer.
  useEffect(effect, [count]); // When our debouncer finishes, run our effect.
}

export function useDebouncedMemo<T>(factory: () => T, duration: number, deps: DependencyList): T {
  const [tick, scheduleAdvance] = useDebouncedTicker(duration);
  useEffect(scheduleAdvance, deps); // When our deps change, notify our debouncer.
  return useMemo(factory, [tick]); // When our debouncer finishes, invalidate our memo.
}
```
