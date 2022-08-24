# React Testing Guide

## Use Roles First

Most semantic HTML elements have an implicit role. This role is used by accessibility tools such as screen readers. But as we’ll explain, you can also use it to write easy-to-understand tests.

Because the ARIA specs are more recent than HTML 1.0, it clarifies HTML and provides improved names for a lot of the traditional HTML elements. The names used are more what everyday users would use too, such as `link` rather than `a`.

### Roles are better than Tag Names

Roles are better than tag names, as they generalize towards the user behaviour not the nitty-gritty of HTML specifics.

As an example, `<input type="text">` and `<textarea></textarea>` both have the role **textbox**. A user probably does not care for the difference — it’s just a text field that they can type into.

These roles allow us to think in the language that our users would use:

- The **save** _button_
- The **email** _text field_
- The **primary** _navigation_
- The **notifications** icon _image_
- The _**search** field_
- The **remember me** _checkbox_

### Roles are better than Test IDs

Test IDs are something that allow us to find specific elements on the page. They can seem especially necessary in a component system, since our component structure is not surfaced if we render our component tree to HTML.

The problem is that Test IDs are _only_ used for automated testing — they don’t affect the user’s experience at all.

So something that relies on Test IDs to work might still pass, but still produce an issue for end users! So using them does not give us that much more confidence that what we are implementing actually works.

It would be better if we could test the same experience as our users. If we could take the same path they use when first coming to a page and they begin to understand what’s there.

A screen reader user has this exact experience. They arrive at a page, and are able to hear what sections and elements are available. They are able to jump to a specific section or element and interact with it. And they get feedback telling them exactly what the state of the world is as they interact.

This sounds exactly what we would desire for our automated tests! We want to find elements on the page, interact with them, and get feedback that they are working correctly.

This is what accessibility-first testing allows us to achieve. And as a massive bonus, it lets us create an accessible experience from day one. We can be on a path to creating a fantastic user experience too.

## Component test boilerplate

```tsx
import SignInForm from "./SignInForm";

import React from "react";
import { lazy, freshFn } from "jest-zest";
import { render } from "@testing-library/react";
import user from "@testing-library/user-event";

const onSignIn = freshFn();
const { getByRole } = lazy(() => render(
  <SignInForm onSignIn={onSignIn} />
));

it("renders an email textbox", () => {
  expect(getByRole('textbox', { name: /Email/i })).toBeInTheDocument();
});

describe("when Sign In button is clicked", () => {
  beforeEach(() => {
    user.click(getByRole('button', { name: /Sign In/i }));
  });

  it("calls onSignIn prop", () => {
    expect(onSignIn).toHaveBeenCalled();
  });
})
```

## Available Roles

<table class="text-left table-fixed">
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**link**", "`<a href=…>`"],
      ["_none_", "`<a>`"],
      ["**button**", "`<button>`"],
      ["**button**", "`<input type=button>`"],
      ["**textbox**", "`<textarea>`"],
      ["**textbox**", "`<input type=text>`"],
      ["**radio**", "`<input type=radio>`"],
      ["**heading**", "`<h1>`"],
      ["**heading**", "`<h2>`"],
      ["**heading**", "`<h3>`"],
      ["**document**", "`<body>`"],
    ]) %>
  </tbody>
</table>

<table class="text-left table-fixed">
  <caption class="text-2xl">Landmarks</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**main**", "`<main>`"],
      ["**navigation**", "`<nav>`"],
      ["**banner**", "`<header role=banner>`"],
      ["**contentinfo**", "`<footer role=contentinfo>`"],
      ["**search**", "`<form role=search>`"],
      ["**form**", "`<form>`"],
      ["**complementary**", "`<aside>`"],
      ["**region**", "`<section>`"],
    ]) %>
  </tbody>
</table>

<table class="text-left table-fixed">
  <caption class="text-2xl">Content</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**link**", "`<a href=…>`"],
      ["_none_", "`<a>`"],
      ["**heading**", "`<h1>`, `<h2>`, `<h3>`, etc"],
      ["**list**", "`<ul>`, `<ol>`"],
      ["**listitem**", "`<li>`"],
      ["**term**", "`<dt>`"],
      ["**definition**", "`<dd>`"],
      ["**img**", "`<img alt=\"Some description\">`"],
      ["_none_", "`<img alt=\"\">`"],
      ["**figure**", "`<figure>`"],
      ["**separator**", "`<hr>`, `<li role=separator>`"],
      ["_none_", "`<p>`"],
      ["_none_", "`<div>`"],
      ["_none_", "`<span>`"],
      ["**group**", "`<details>`"],
      ["**button**", "`<summary>`"],
    ]) %>
  </tbody>
</table>

<table class="text-left table-fixed">
  <caption class="text-2xl">Forms</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**form**", "`<form>`"],
      ["**group**", "`<fieldset>`"],
      ["**search**", "`<form role=search>`"],
      ["**button**", "`<button>`"],
      ["**button**", "`<input type=button>`"],
      ["**button**", "`<button type=submit>`, `<input type=submit>`"],
      ["**textbox**", "`<textarea>`"],
      ["**textbox**", "`<input type=text>`"],
      ["**textbox**", "`<input type=email>`"],
      ["**textbox**", "`<input type=tel>`"],
      ["**textbox**", "`<input type=url>`"],
      ["**searchbox**", "`<input type=search>` without `list` attribute"],
      ["**radiogroup**", "`<fieldset role=radiogroup>`"],
      ["**radio**", "`<input type=radio>`"],
      ["**checkbox**", "`<input type=checkbox>`"],
      ["**combobox**", "`<select>` without `multiple` attribute"],
      ["**listbox**", "`<select>` with `multiple` attribute"],
      ["**option**", "`<option>`"],
      ["**slider**", "`<input type=range>`"],
      ["_none_", "`<input type=password>`"],
      ["progressbar", "`<progress>`"],
      ["status", "`<output>`"],
    ]) %>
  </tbody>
</table>

<table class="text-left table-fixed">
  <caption class="text-2xl">Tables</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**table**", "`<table>`"],
      ["**rowgroup**", "`<tbody>`, `<thead>`, `<tfoot>`"],
      ["**rowheader**", "`<th>`"],
      ["**columnheader**", "`<th>`"],
      ["**row**", "`<tr>`"],
      ["**cell**", "`<td>`"],
    ]) %>
  </tbody>
</table>

<table class="text-left table-fixed">
  <caption class="text-2xl">Tabs</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**tablist**", "`<ul role=tablist>`"],
      ["**tab**", "`<button role=tab>`"],
      ["**tabpanel**", "`<section role=tabpanel>`"],
    ]) %>
  </tbody>
  <tfoot class="text-purple-100 bg-purple-900 border border-purple-700">
    <tr>
      <td colspan=2 class="px-3 py-1"><em>Should</em> manage focus with JavaScript.</td>
    </tr>
  </tfoot>
</table>

<table class="text-left table-fixed">
  <caption class="text-2xl">Menus</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**menu**", "`<ul role=menu>`"],
      ["**menuitem**", "`<button role=menuitem>`"],
      ["**menuitemcheckbox**", "`<button role=menuitemcheckbox>`"],
      ["**menuitemradio**", "`<button role=menuitemradio>`"],
      ["**menubar**", "`<nav role=menubar>`"],
    ]) %>
  </tbody>
  <tfoot class="text-purple-100 bg-purple-900 border border-purple-700">
    <tr>
      <td colspan=2 class="px-3 py-1"><em>Should</em> manage focus with JavaScript.</td>
    </tr>
  </tfoot>
</table>

## Accessible names

Accessible elements don’t just have a role. They can have a ‘name’ too, which helps the user tell elements with the same role apart.

These names are provided by HTML in a number of ways:

- `<label>` relationship
- `aria-labelledby` attribute
- `aria-label` attribute
- The displayed value
- The text content

The algorithm is specified in [W3C’s Accessible Name and Description Computation](https://www.w3.org/TR/accname-1.1/#mapping_additional_nd_te).

### Examples of accessible names

```html
<button>Save</button>
```

```html
<label>Email: <input type=email></label>
```

```html
<label><input type=checkbox> Receive email alerts</label>
```

```html
<fieldset>
  <legend>Alert settings</legend>
  <label><input type=checkbox> Receive push notifications</label>
  <label><input type=checkbox> Receive email alerts</label>
  <label><input type=checkbox> Receive text messages</label>
</fieldset>
```

```html
<article aria-labelledby="faq-heading">
  <h2 id="faq-heading">Frequently Asked Questions</h2>
</article>
```

```html
<nav aria-label="Primary">
  …
</nav>
```

```html
<svg role="img">
  <title>New document</title>
  …
</svg>
```

You could query these elements using Testing Library:

```ts
getByRole('button', { name: 'Save' });
getByRole('textbox', { name: /Email/ });
getByRole('checkbox', { name: /Receive email alerts/i });
getByRole('fieldset', { name: /Alert settings/i });
getByRole('article', { name: /Frequently asked questions/i });
getByRole('navigation', { name: 'Primary' });
getByRole('img', { name: 'New document' });
```

----

## Accessibility-first testing: a standards-based approach

- Build components
- Test components work as expected
- Test-drive components
- Learnable & deterministic

## Test components work as expected

### Roles > Tag Names

<figure>
  <%= collected_image(@conn, view_module(@conn), "list-of-roles") %>
  <figcaption>
  <%= line("A list of roles [from the wai-aria spec](https://www.w3.org/TR/wai-aria/#widget_roles).") %>
  </figcaption>
</figure>

### Roles > Test IDs

- Test IDs are fragile. They are not part of behaviour.
- Easier to write tests first.
- Reduce coupling to a certain implementation.
- Can swap out third-party components.
- Good accessibility from day one.

## Use accessible names

<table>
  <thead>
    <tr>
      <th>Role name</th>
      <th>Responsibility</th>
      <th>HTML example</th>
    </tr>
  </thead>
  <tbody class="border">
    <%= table_rows([
      ["Button", "Perform action here", "`<button>`"],
      ["Checkbox", "Enable something", "`<input type=checkbox>`"],
      ["Textbox", "Type in something", "`<input type=text>` *or* `<textarea>`"],
      ["Radio & Radiogroup", "Choose from a list", "`<input type=radio>`"],
      ["Combobox", "Choose or type from a list", "`<select>` *or* `<div role=combobox> <input>`"],
      ["Slider", "Choose from a range", "`<input type=range aria-valuemin=1 …>`"],
      ["Menu & Menuitem", "Choose action", "`<ul role=menu> <li role=menuitem>…`"],
      ["Dialog", "Focus on this separate content", "`<div role=dialog>`"],
      ["Alert", "Alert to live information, errors", "`<div role=alert>`"],
    ]) %>
  </tbody>
</table>

## Reduce coupling to specific implementations

- Reach UI or React Modal?
- React Select or Downshift?
- Emotion or CSS Modules?
- React or Vue?
- HTML and ARIA are stable, consistent specifications
- Third-party libraries are unstable, discrepant implementations

## Specs

- <https://www.w3.org/TR/wai-aria-practices/>
- <https://www.w3.org/TR/html-aria/>
