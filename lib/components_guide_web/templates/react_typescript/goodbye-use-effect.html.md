# Goodbye `useEffect`

## Media queries

If you `useState` with `useEffect` to subscribe to events you have to [worry about dependency arrays:](https://fireship.io/snippets/use-media-query-hook/)

```tsx

import { useState, useEffect } from "react";

export function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    if (media.matches !== matches) {
      setMatches(media.matches);
    }
    const listener = () => setMatches(media.matches);
    window.addEventListener("resize", listener);
    return () => window.removeEventListener("resize", listener);
  }, [matches, query]);

  return matches;
}
```

Instead try `useSyncExternalStore`. Your breakpoints are very likely constant, so create custom hooks for each one.

```tsx
import { useSyncExternalStore } from "react";

function makeUseMediaQuery(mediaQuery: string, getServerValue: () => boolean): () => boolean {
  return () => useSyncExternalStore(
    onStoreChange => {
      const aborter = new AbortController();
      // https://css-tricks.com/working-with-javascript-media-queries/
      // All browsers support addEventListener instead of addListener today.
      // https://developer.mozilla.org/en-US/docs/Web/API/MediaQueryList/change_event
      window.matchMedia(mediaQuery).addEventListener("change", onStoreChange, { signal: aborter.signal });
      return () => {
        aborter.abort();
      };
    },
    () => window.matchMedia(mediaQuery).matches,
    getServerValue
  );
}

// Default Tailwind breakpoints: https://tailwindcss.com/docs/responsive-design
// Server rendering is mobile-first for SEO so we default to false.
export const useMatchesSm = makeUseMediaQuery("(min-width: 640px)", () => false);
export const useMatchesMd = makeUseMediaQuery("(min-width: 768px)", () => false);
export const useMatchesLg = makeUseMediaQuery("(min-width: 1024px)", () => false);

// Derive “is mobile” from whether sm breakpoint matches.
export function useIsMobile(): boolean {
  return !useMatchesSm();
}
```
