## Behavior and markup > implementation details

## Accessibility-first testing: a standard-based approach

- Build components
- Test components work as expected
- Test-drive components
- Learnable & deterministic

## Build components

Most semantic HTML elements have a role.

<table class="text-left table-fixed">
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="border text-white bg-teal-900">
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
  <tbody class="border text-white bg-teal-900">
    <%= table_rows([
      ["**main**", "`<main>`"],
      ["**navigation**", "`<nav>`"],
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
  <tbody class="border text-white bg-teal-900">
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
      ["**separator**", "`<hr>`"],
      ["**figure**", "`<figure>`"],
      ["_none_", "`<p>`"],
      ["_none_", "`<div>`"],
      ["_none_", "`<span>`"],
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
  <tbody class="border text-white bg-teal-900">
    <%= table_rows([
      ["**form**", "`<form>`"],
      ["**button**", "`<button>`"],
      ["**button**", "`<input type=button>`"],
      ["**textbox**", "`<textarea>`"],
      ["**textbox**", "`<input type=text>`"],
      ["**textbox**", "`<input type=email>`"],
      ["**textbox**", "`<input type=tel>`"],
      ["**textbox**", "`<input type=url>`"],
      ["**searchbox**", "`<input type=search>` with no `list` attribute"],
      ["**radio**", "`<input type=radio>`"],
      ["**checkbox**", "`<input type=checkbox>`"],
      ["**combobox**", "`<select>`"],
      ["**listbox**", "`<select>` with `multiple` attribute"],
      ["**option**", "`<option>`"],
      ["**slider**", "`<input type=range>`"],
      ["_none_", "`<input type=password>`"],
      ["progressbar", "`<progress>`"],
      ["group", "`<fieldset>`"],
      ["status", "`<output>`"],
      ["_none_", "`<legend>`"],
    ]) %>
  </tbody>
</table>

<table class="text-left">
  <caption class="text-2xl">Tables</caption>
  <thead>
    <tr>
      <th>Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="border text-white bg-teal-900">
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

## Test components work as expected

### Roles > Tag Names

<figure>
  <%= collected_image(@conn, "list-of-roles") %>
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

<table style="width: 100%; text-align: left;">
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
