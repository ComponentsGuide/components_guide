# Accessible names

Accessible elements don’t just have a role. They can have a ‘name’ too, which helps the user tell elements with the same role apart.

These names are provided by HTML in a number of ways:

- `<label>` relationship
- `aria-labelledby` attribute
- `aria-label` attribute
- The displayed value
- The text content for the [following roles](https://www.w3.org/TR/wai-aria/#namefromcontent):
    - button
    - cell
    - checkbox
    - columnheader
    - gridcell
    - heading
    - link
    - menuitem
    - menuitemcheckbox
    - menuitemradio
    - option
    - radio
    - row
    - rowgroup
    - rowheader
    - switch
    - tab
    - tooltip
    - tree
    - treeitem


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
