# Accessibility Testing in Playwright

## Accessibility tree snapshots

I usually don’t like snapshot “tests” because they don’t really test anything. Instead of documenting behaviour you want demonstrated, they take a shortcut and just save a dump of everything to disk. Also they usually capture implementation details (like the HTML tree) that should be allowed to vary as you refactor — adding or removing whitespace or a `<div>` shouldn’t affect a test.

Instead of snapshotting HTML, consider looking at your accessibility tree. Playwright [lets you inspect this](https://playwright.dev/docs/api/class-accessibility) via `page.accessibility.snapshot()`, and you can capture each tree for Chrome, Safari, and Firefox (each browser interprets things slightly differently).

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

Here’s how to install Playwright in a Node.js project and run the tests:

```bash
# Add Playwright as a dev dependency
npm i -D @playwright/test
# install supported browsers
npx playwright install
# Run the tests
npx playwright test
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
    },
    …
  ]
}
```

If you make changes to your site and run the tests again, you’ll see a helpful diff like so:

<collected-figure image="accessibility-tree-snapshot-failure-diff">
  Diff comparing the accessibility tree after making changes to the components.guide home page.
</collected-figure>

Once you have checked the diff of the accessibility tree and are happy with the results, re-run the tests and pass the option to update the snapshots:

```bash
npx playwright test -u

# Or if you prefer the longer form:
# npx playwright test --update-snapshots
```

----

## Asserting landmarks exist with Testing Library

If you’d like to go beyond snapshots, you can write tests that assert that specific [landmarks](/accessibility-first/landmarks) exist.

Here’s a test that checks for landmarks like `main`, `banner`, a `navigation` named “Main menu”, and a `search` form inside the `banner` are all visible on the page. These tests are run against the excellent MDN home page.

```ts
// tests/mdn.spec.ts
import { test, within } from "./helpers";

test.beforeEach(async ({ page }) => {
  await page.goto("https://developer.mozilla.org/en-US/");
});

test.describe("landmarks", () => {
  test("has main nav", async ({ queries: { getByRole } }) => {
    await getByRole('navigation', { name: 'Main menu' });
  });

  test("has main landmark", async ({ queries: { getByRole } }) => {
    await getByRole('main');
  });

  test("has banner landmark", async ({ queries: { getByRole } }) => {
    await getByRole('banner');
  });

  test("has search form inside banner", async ({ queries: { getByRole } }) => {
    const banner = await getByRole('banner');
    await within(banner).getByRole('search');
  });
});
```

And here’s the boilerplate in `helpers.ts` to get Testing Library and Playwright working together:

```ts
// tests/helpers.ts
import { test as baseTest } from "@playwright/test";
import {
  fixtures,
  type TestingLibraryFixtures,
} from "@playwright-testing-library/test/fixture";
export { within } from "@playwright-testing-library/test";

export const test = baseTest.extend<TestingLibraryFixtures>(fixtures);
export const { expect } = test;
```
