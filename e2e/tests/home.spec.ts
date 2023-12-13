import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto("/");
});


test('has title', async ({ page }) => {
  await expect(page).toHaveTitle("Guides to React, Accessibility, Modern CSS, TypeScript · Components.Guide");
});

// test('get started link', async ({ page }) => {
//   // Click the get started link.
//   await page.getByRole('link', { name: 'Get started' }).click();

//   // Expects page to have a heading with the name of Installation.
//   await expect(page.getByRole('heading', { name: 'Installation' })).toBeVisible();
// });
