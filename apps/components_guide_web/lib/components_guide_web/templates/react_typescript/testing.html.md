## Behavior and markup > implementation details



## Roles > Tag Names

You can find a list of roles here [in the spec](https://www.w3.org/TR/wai-aria/#widget_roles).

![list-of-roles.png](list-of-roles.png)

## Roles > Test IDs

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
