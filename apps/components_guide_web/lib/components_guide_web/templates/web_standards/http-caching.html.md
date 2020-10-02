# HTTP Caching

## Resource that does not want to be cached

```http
GET /about HTTP/1.1
HOST: example.org
```

```http
HTTP/1.1 200 OK
Cache-Control: max-age=0, private, must-revalidate
Date: Fri, 02 Oct 2020 09:28:50 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 4321
```

## Resource that wants to be cached

```http
GET /assets/logo.png HTTP/1.1
Host: example.org
```

```http
HTTP/1.1 200 OK
ETag: "ABC"
Last-Modified: Wed, 21 Oct 2015 07:28:00 GMT 
Cache-Control: public, max-age=31536000
Date: Fri, 02 Oct 2020 09:28:50 GMT
Content-Type: image/png
Content-Length: 2348
Vary: Accept-Encoding

… data …
```

### When server has same etag

```http
GET /assets/logo.png HTTP/1.1
Host: example.org
If-None-Match: "ABC"
```

```http
HTTP/1.1 304 Not Modified
ETag: "ABC"
Date: Fri, 02 Oct 2020 09:28:50 GMT
Content-Type: image/png
Content-Length: 2348
Cache-Control: public, max-age=31536000
Last-Modified: Wed, 21 Oct 2015 07:28:00 GMT 
Vary: Accept-Encoding

```

### When server has not been modified since

```http
GET /assets/logo.png HTTP/1.1
Host: example.org
If-Modified-Since: Wed, 21 Oct 2015 07:28:00 GMT 
```

```http
HTTP/1.1 304 Not Modified
Date: Fri, 02 Oct 2020 09:28:50 GMT
Content-Type: image/png
Content-Length: 2348
Cache-Control: public, max-age=31536000
ETag: "ABC"
Last-Modified: Wed, 21 Oct 2015 07:28:00 GMT 
Vary: Accept-Encoding

```

### When server does not have that etag

```http
GET /assets/logo.png HTTP/1.1
Host: example.org
If-None-Match: "ABC"
```

```http
HTTP/1.1 200 OK
ETag: "XYZ"
Date: Fri, 02 Oct 2020 09:28:50 GMT
Content-Type: image/png
Content-Length: 2348
Cache-Control: public, max-age=31536000
Last-Modified: Wed, 21 Oct 2015 07:28:00 GMT 
Vary: Accept-Encoding

```

### When server has been modified since

```http
GET /assets/logo.png HTTP/1.1
Host: example.org
If-Modified-Since: Wed, 21 Oct 2015 07:28:00 GMT 
```

```http
HTTP/1.1 200 OK
ETag: "XYZ"
Date: Fri, 02 Oct 2020 09:28:50 GMT
Content-Type: image/png
Content-Length: 2348
Cache-Control: public, max-age=31536000
Last-Modified: Thu, 22 Oct 2015 07:28:00 GMT 
Vary: Accept-Encoding

```

## See more

- [MDN: HTTP caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
- [MDN: If-None-Match](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match)
- [MDN: 412 Precondition Failed](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/412)
