# Desirable Properties

<h2 id=deterministic>Deterministic operations</h2>

- A given input will always produce the same output
- Easily cacheable
- Verifiable by multiple actors
- Integers
  - *e.g. Multiply two integers*
  - *e.g. Adding two integers*
  - *e.g. Finding the maximum of two integers*
- Strings
  - *e.g. Converting strings to lowercase or uppercase*
  - *e.g. Concatenating strings*
  - *e.g. Substring of another string*
- List
  - *e.g. Sorting a list of items*
  - *e.g. Removing duplicates from a list of items*
- Binary data
  - *e.g. SHA256 hash digest (RFC 6234)*
  - *e.g. Base64 decoding (RFC 4648)*
  - *e.g. Gzip decoding (RFC 1952)*

```bash
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

----

<h2 id=unique>Unique values</h2>

- Will never clash with existing values.
- Choice: Unique within a context or globally unique?
- Warning: just because a value is unique does not mean that it is unpredictable.
- *e.g. Auto-incrementing SQL primary key*
  - Con: might be predictable as it is _deterministic_.
- *e.g. UUID (RFC 4122)*
- *e.g. A `id` attribute used for linking a `<label>` to its `<input>`*
- *e.g. A key for a React element within an array*
  - It only has to be unique within the array.
- *e.g. SHA256 hash digest (RFC 6234)*

```bash
# UUID
> uuidgen
5F36D0E2-F524-46B8-870B-9AA70128F8AF

# Cryptographically random source
> openssl rand -base64 20
lrtijvqi3Dz4YrHZMQpcdfqTkJ4=

# Auto-incrementing SQL primary key
> sqlite3
sqlite> create table items (id integer primary key);
sqlite> insert into items values (?);
sqlite> insert into items values (?);
sqlite> insert into items values (?);
sqlite> select id from items;
1
2
3
sqlite>
```

----

<h2 id=immutable>Immutable values</h2>

- Can never be modified.
- Changes to a data structure work on a copy, preserving the original.
- Can help with caching: *given I have an resource’s ID, the contents will always be the same.*
    - *e.g. Tweets on Twitter cannot be edited, only deleted.*
    - *e.g. Uploaded videos on YouTube cannot be edited, only deleted.*
- Can help with syncing: *retrieve only the values I do not yet have.*
    - *e.g. Committed files in Git become immutable objects stored in `.git/objects/`. When you `git fetch` new objects are downloaded from your remote.*

----

<h2 id=idempotent>Idempotent operations</h2>

- The same result is produced if run once, twice, or a thousand times
- *e.g. Adding an item to a set*
- *e.g. Removing an item from a set*
- *e.g. Sorting a list of items repeatedly*
- *e.g. HTTP `PUT` request*
- *e.g. Consumers of an at-least-once event delivery system*
- *e.g. [Stripe charges](https://stripe.com/docs/api/idempotent_requests)*
- **Tip:** To get idempotent behavior, you could generate a [random](#random) identifier for each request, and have the receiver record which requests have been processed, and then skip whenever one is repeated.
- See also: [Distributed Systems Shibboleths](https://jolynch.github.io/posts/distsys_shibboleths/)

----

<h2 id=versioned>Versioned interfaces</h2>

- Will allow a previously valid request to still work.
- No breaking changes without the user opting into them.
- This often relies on a **unique** version number.
- *e.g. [Semantic Versioning](https://semver.org)*
- *e.g. [Stripe’s API Versioning](https://stripe.com/blog/api-versioning)*
