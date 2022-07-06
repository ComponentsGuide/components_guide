# Accessibility Tree Snapshots

I usually don’t like snapshot “tests” because they don’t really test anything. Instead of documenting behaviour you want demonstrated, they take a shortcut and just save a dump of everything to disk. Also they usually capture implementation details (like the HTML tree) that should be allowed to vary as you refactor — adding or removing whitespace or a `<div>` shouldn’t affect a test.

Instead of snapshotting HTML, consider looking at your accessibility tree. Playwright [lets you inspect this](https://playwright.dev/docs/api/class-accessibility) via `page.accessibility.snapshot()`, and you can capture each tree for Chrome, Safari, and Firefox (each interpret it slightly differently).

Here is an automated test that retrieves this accessibility tree, and then writes it to a `accessibility-tree.json` file to compare with the next test run.

```ts
import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.goto("https://components.guide/");
});

test.describe("accessibility", () => {
  test("accessibility tree", async ({ page }) => {
    const tree = await page.accessibility.snapshot();
    expect(JSON.stringify(tree, null, 2)).toMatchSnapshot("accessibility-tree.json");
  });
});
```

Here’s what the tree looks like:

```json
{
  "role": "WebArea",
  "name": "Guides to React, Accessibility, Modern CSS, TypeScript · Components.Guide",
  "children": [
    {
      "role": "combobox",
      "name": "JUMP TO",
      "haspopup": "menu"
    },
    {
      "role": "link",
      "name": "COMPONENTS ·GUIDE"
    },
    {
      "role": "textbox",
      "name": "Search…"
    },
    {
      "role": "heading",
      "name": "Want to learn how to improve the UX & DX of your components?",
      "level": 1
    },
    {
      "role": "text",
      "name": "Get better at accessibility, testing, naming, performance, and using built-in browser features — all for free."
    }
  ]
}
```
