# HTTP Headers

<form role="search" class="text-center" id="search-http-headers">
  <input name="q" type="search" placeholder="Search HTTP Headers…" autofocus class="text-white bg-gray-800 border-gray-700 rounded">
</form>

<script type="module">
  const searchForm = document.getElementById("search-http-headers");
  const listItems = searchForm.parentNode.querySelectorAll('ul li');
  searchForm.addEventListener('input', () => {
    const values = new FormData(searchForm);
    const q = values.get('q').trim().toLowerCase();
    for (const li of Array.from(listItems)) {
      const matches = q === '' ? true : li.textContent.toLowerCase().includes(q);
      li.hidden = !matches;
    }
  });
</script>

## Request

- Host (required)
- User-Agent
- Accept
- Accept-Language
- Accept-Encoding
- Origin
- Referer
- Connection
- Content-Length
- Range
- Cache-Control
  - `max-age`
  - `max-stale`
  - `min-fresh`
  - `no-cache`
  - `no-store`
  - `no-transform`
  - `only-if-cached`
  - `stale-if-error`
- If-Modified-Since
- If-Unmodified-Since
- If-Match
- If-None-Match
- If-Range
- Authorization
- Expect
- Cookie

## Response

- Content-Length
- Content-Type
- Content-Encoding
- Transfer-Encoding
- Location
- Allow
- Link
- Date
- Accept-Ranges
- Content-Range
- Age
- Expires
- Vary
- ETag
- Cache-Control
  - `max-age`
  - `s-maxage`
  - `no-cache`
  - `no-store`
  - `no-transform`
  - `must-revalidate`
  - `proxy-revalidate`
  - `must-understand`
  - `private`
  - `public`
  - `immutable`
  - `stale-while-revalidate`
  - `stale-if-error`
  - https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
  - https://github.com/mdn/browser-compat-data/blob/main/http/headers/cache-control.json
- Set-Cookie
- Access-Control-Allow-Origin
- Upgrade
- Alt-Svc
- Retry-After
- Server-Timing
- Report-To
- Last-Event-ID
