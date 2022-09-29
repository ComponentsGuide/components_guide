---
a = 4 + 3
class = "italic"
---

# Astro

<p class={class}><%= a %>?</p>
<p class={class}><%= class %></p>

```astro
---
title: When WebAssembly is faster
description: The overhead of the network vs the overhead of WebAssembly
layout: ../../layouts/MainLayout.astro
---
```

<script type="module">
import * as shiki from "https://jspm.dev/shiki";

shiki
    .getHighlighter({
      theme: 'nord'
    })
    .then(highlighter => {
      for (const astroCodeEl of document.body.querySelectorAll('code.language-astro')) {
        const html = highlighter.codeToHtml(astroCodeEl.textContent, { lang: 'astro' });
        astroCodeEl.innerHTML = html;
      }
    });
</script>
