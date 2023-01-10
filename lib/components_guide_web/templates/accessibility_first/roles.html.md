# Available Roles

<table>
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Landmarks</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="">
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
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Content</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="">
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
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Forms</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="">
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
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Tables</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="">
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
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Tabs</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="">
    <%= table_rows([
      ["**tablist**", "`<ul role=tablist>`"],
      ["**tab**", "`<button role=tab>`"],
      ["**tabpanel**", "`<section role=tabpanel>`"],
    ]) %>
  </tbody>
  <tfoot class="text-purple-300">
    <tr>
      <td colspan=2>You <em>should</em> manage focus with JavaScript.</td>
    </tr>
  </tfoot>
</table>

<table class="text-left table-fixed">
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Menus</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="">
    <%= table_rows([
      ["**menu**", "`<ul role=menu>`"],
      ["**menuitem**", "`<button role=menuitem>`"],
      ["**menuitemcheckbox**", "`<button role=menuitemcheckbox>`"],
      ["**menuitemradio**", "`<button role=menuitemradio>`"],
      ["**menubar**", "`<nav role=menubar>`"],
    ]) %>
  </tbody>
  <tfoot class="text-purple-300">
    <tr>
      <td colspan=2>You <em>should</em> manage focus with JavaScript.</td>
    </tr>
  </tfoot>
</table>
