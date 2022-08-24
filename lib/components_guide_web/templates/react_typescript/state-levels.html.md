# React State

## Derive local variable

## useState

## useReducer

## useSyncExternalStore

```ts
function useIsOffline(): boolean {
  const isOnline = useSyncExternalStore(
    (callback: () => void) => {
      window.addEventListener("offline", callback);

      return () => {
        window.removeEventListener("offline", callback);
      };
    },
    () => navigator.onLine,
    () => true
  );
  return !isOnline;
}
```

## Root prop

## createContext
