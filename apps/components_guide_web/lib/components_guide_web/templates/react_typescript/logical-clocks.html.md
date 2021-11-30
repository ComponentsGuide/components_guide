# Simplify React Effects with Logical Clocks

## Problems

Hooks offer a more flexible and powerful suite of tools than we had a few years ago in React with class components’ lifecycle methods.

Each hook tries to follow the unix philosophy: have small tools that solve one particular task well. For example, `useState()` solves many needs for a mutable variable that belongs to a component.

However, while React has certainly made the *what* easier with the declarative model of building a view, getting the *when* right proves to be a lot harder. Hooks like `useEffect()` can appear simple but are difficult to compose together and to visualise. By using logical clocks, we can get back towards the declarative model that we all love in React.

## What is a logical clock?

```ts
function useTick() {
  return useReducer(n => n + 1, 0);
}
```

## Debouncing

```ts
export function useDebouncer(duration: number): readonly [number, EffectCallback] {
  const [count, tick] = useTick();
  const effect = useCallback(() => {
    const timeout = setTimeout(tick, duration);
    return () => clearTimeout(timeout);
  }, [duration, tick]);

  return [count, effect];
}
```

```ts
export function useDebouncedEffect(effect: EffectCallback, duration: number, deps: DependencyList): void {
  const [count, didChange] = useDebouncer(duration);
  useEffect(didChange, deps); // When our deps change, notify our debouncer.
  useEffect(effect, [count]); // When our debouncer finishes, run our effect.
}
```
