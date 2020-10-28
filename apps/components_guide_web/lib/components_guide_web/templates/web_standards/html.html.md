# Anatomy of a web page’s HTML

_Here we break down a common HTML page and explain what each part does._

## All web pages have two languages

The first, <abbr title="Hyper Text Markup Language">HTML</abbr>, is for computers. It has been around since the early 90s and continues to be updated today. This language is understood by Safari, Firefox, Chrome, Google.com, DuckDuckGo.com, and many more digital services.

The second is for people, for example: `en` for english, `fr` for français, `zh_CN` for 官话.

So all web pages must state these two languages:

```html
<!doctype html> <!-- This is a modern HTML page -->
<html lang=en> <!-- Written in english -->
```

## Make it work well in browsers, on social media, and on phones.

```html
<!-- OK let’s write some metadata… -->
<head>

<!-- Let’s ensure emoji and all languages work. -->
<meta charset=utf-8>

<!-- The text shown in the browser tab. -->
<title>…</title>

<!-- Let’s look great on social media with a title… -->
<meta property=og:title content=…>

<!-- …and ideally an image too. -->
<meta property=og:image content=…>

<!-- Let’s look great on phones, and allow people to zoom in. -->
<meta name=viewport content="width=device-width, initial-scale=1.0">

<!-- Let’s look great everywhere with CSS styles -->
<link rel=stylesheet href=…>
```

## Let’s write content that anyone can read

```html
<body>

<!-- Allow people to navigate to other pages -->
<nav aria-label="Primary">
  <!-- Allow assistive technology to see each link as its own item -->
  <ul>
    <li><a href="/">Home</a>
    <li><a href="/contact">Contact</a>
    <li><a href="/bio">Bio</a>
    <li><a href="/news">News</a>
  </ul>
</nav>

<!-- Allow assistive technology to find the main content -->
<!-- (A la skip intro on Netflix) -->
<main>
  <!-- The headline of this page -->
  <h1>Example web page</h1>
  
  <p>Some more content</p>
</main>
```

For more on HTML content, read about landmarks.

