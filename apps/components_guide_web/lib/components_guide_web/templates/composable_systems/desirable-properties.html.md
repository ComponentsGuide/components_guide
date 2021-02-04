# Desirable Properties

<h2>Values</h2>

<h3 id=deterministic>Deterministic</h3>

- A given input always produces the same output
- Easily Cacheable
- Verifiable by multiple actors
- *e.g. Converting to lowercase or uppercase*
- *e.g. Concatenating strings*
- *e.g. SHA256 hash digest (RFC 6234)*
- *e.g. Base64 encoding/decoding (RFC 4648)*
- *e.g. Gzip decoding (RFC 1952)*

```console
# Converting to lowercase
> echo "AbC" | tr "[:upper:]" "[:lower:]"
abc

# SHA256 hash digest
> echo "abc" | shasum -a 256
edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb  -

# Base64 encoding
> echo "abc" | base64
YWJjCg==

# Base64 decoding
> echo "YWJjCg==" | base64 -d
abc

# Gzip decompressing
> echo "H4sIADFoHGAAA0tMSuYCAE6BiEcEAAAA" | base64 --decode | gzip --decompress
abc
```

<h3 id=unique>Unique</h3>

- Unique within a context or globally unique?
- Won’t clash with existing values
- *e.g. UUID (RFC 4122)*
- *e.g. SHA256 hash digest (RFC 6234)*
- Could still be guessable: *e.g. Auto increment SQL primary key*

```console
# UUID
> uuidgen
5F36D0E2-F524-46B8-870B-9AA70128F8AF
```

<h3 id=random>Random</h3>

- Not [Guessable](#guessable)
- Should never clash with existing values
- *e.g. UUID v4*
- *e.g. Cryptographically Random source*

<h3 id=guessable>Guessable</h3>

- Not Secure
- Not [Random](#random)
- *e.g. Auto increment SQL primary key*

----

<h2>Acts</h2>

<h3 id=immutable>Immutable</h3>

- Benefits caching
- Benefits syncing
- *e.g. Twitter tweets are not editable*
- *e.g. a Git commit*
- *e.g. a YouTube video cannot be edited*

<h3 id=stateless>Stateless</h3>

- Is [Deterministic](#deterministic)
- *e.g. Restful HTTP GET request*

<h3 id=idempotent>Idempotent</h3>

- *e.g. At-least-once event delivery*
- Could use Random identifier in request to record which commands have already been completed

<h3 id=versioned>Versioned</h3>

- Won't break previous usages
- *e.g. [Stripe’s API Versioning](https://stripe.com/blog/api-versioning)*
