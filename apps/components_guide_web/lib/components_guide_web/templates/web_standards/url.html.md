# Anatomy of a URL

## Change the parts of a URL

<live-render>
ComponentsGuideWeb.WebStandards.Live.URL
</live-render>

----

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

## Elixir’s `URI`

```elixir
url = URI.parse("https://www.example.org/")

```
