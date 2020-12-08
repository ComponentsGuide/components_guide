# URL

## Anatomy of a URL

<live-render>
ComponentsGuideWeb.WebStandards.Live.URL
</live-render>

## JavaScript’s `URL`

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
let url = URL(string: "https://www.example.org/")

```

## Elixir’s `URI`

```elixir
url = URI.parse("https://www.example.org/")

```

## Go’s `net/url`

```go
u, err := url.Parse("https://www.example.org/")
```
