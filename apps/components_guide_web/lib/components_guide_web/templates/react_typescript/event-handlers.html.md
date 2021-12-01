# React Event Handlers

## The Problem

We have a link that is associated with a campaign, and when someone clicks the link we want to record that the campaign received some interest.

Here’s how we might write that:

```tsx
type AuthStatus = 'SignedIn' | 'SignedOut';

function trackCampaignClick(campaign: string, authStatus: AuthStatus) {
  // Probably make some sort of HTTP request…
}

function TwitterLink({ campaign }: { campaign: string }) {
  const authStatus = useAuthStatus(); // Reads from context.

  return <a
    href="https://twitter.com/royalicing"
    onClick={() => {
      // When a click happens, we record two things:
      // the current campaign, and whether the user is signed in or not.
      trackCampaignClick(campaign, authStatus);
    }}
  >
    Follow me on Twitter
  </a>;
}
```

However, even for our simple link, there’s an issue. What happens if either the campaign or auth status changes?

We receive `campaign` as a prop — this could change at any time as it is our parent providing it, and we don’t where this value comes from and how often it changes. (This example of a campaign is admittedly unlikely to change often)

And `useAuthStatus()` is also out of control. We don’t know when the user signs in or out.

So in order for our `trackCampaignClick(campaign, authStatus)` call to be accurate, we need to keep these values up to date. There’s no much point in recording metrics if they use stale data!

## Solution 1: Create a new Event handler when its deps change

```js
function TwitterLink({ campaign }: { campaign: string }) {
  const authStatus = useAuthStatus(); // Reads from context.

  const onClick = useCallback(() => {
    // When a click happens, we record two things:
    // the current campaign, and whether the user is signed in or not.
    trackCampaignClick(campaign, authStatus);
  }, [campaign, authStatus]);

  return <a href="https://twitter.com/royalicing" onClick={onClick}>
    Follow me on Twitter
  </a>;
}
```

## Solution 2: Store changing state in a ref

## Solution 3: Put State in the DOM and read it from the Event handler

## Solution 4: Don’t store the state in React

## Solution 5: Put a unique key in the DOM and read state from a shared store

----

An example implementation of `trackCampaignClick()`:

```js
function trackCampaignClick(campaign) {
  navigator.sendBeacon('/analytics', new URLSearchParams({ campaign }));
}
```
