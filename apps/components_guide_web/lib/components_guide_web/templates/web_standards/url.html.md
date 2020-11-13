# URL

## Anatomy of a URL

<live-render>
ComponentsGuideWeb.WebStandards.Live.URL
</live-render>

## Relative URLs

## JavaScript’s `URL`

```js
const url = new URL('https://example.org/songs?first=20&sortBy=releaseDate');
url.protocol; // 'https:' 
url.hostname; // 'example.org' 
url.origin; // 'https://example.org' 
url.pathname; // '/songs' 
```

```js
const root = new URL('/');
```

```js
// In a browser
const current = new URL(window.location.href);
```

```js
// With a fetch Request
const current = new URL(request.url);
```

## Swift’s `URL`

```swift
let root = URL(string: "/")

```
