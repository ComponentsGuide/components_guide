# Semantic Content

<table class="text-left table-fixed">
  <caption class="text-3xl pb-4 text-left">Content roles cheatsheet</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML element</th>
    </tr>
  </thead>
  <tbody class="text-white bg-purple-900 border border-purple-700">
    <%= table_rows([
      ["**link**", "`<a href=…>`"],
      ["_none!_", "`<a>`"],
      ["**heading**", "`<h1>`, `<h2>`, `<h3>`, etc"],
      ["**list**", "`<ul>`, `<ol>`"],
      ["**listitem**", "`<li>`"],
      ["**term**", "`<dt>`"],
      ["**definition**", "`<dd>`"],
      ["**img**", "`<img alt=\"Some description\">`"],
      ["_none!_", "`<img alt=\"\">`"],
      ["**figure**", "`<figure>`"],
      ["**separator**", "`<hr>`, `<li role=separator>`"],
      ["_none!_", "`<p>`"],
      ["_none!_", "`<div>`"],
      ["_none!_", "`<span>`"],
      ["**group**", "`<details>`"],
      ["**button**", "`<summary>`"],
    ]) %>
  </tbody>
</table>

## Search engines and other crawlers

A crawler service that visits your website on behalf of a search engine like Google or social network like Instagram expects semantic content.

Semantic HTML elements allow meaning and structure to be determined.

More coming soon…

## Headings

## Lists

## Term & Definition

## Images

## Figure

## Details & Summary

## Separator
