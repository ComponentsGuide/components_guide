# Accessible Forms with Tests

<table>
  <caption class="text-left text-2xl font-bold pt-4 pb-8">Form roles cheatsheet</caption>
  <thead>
    <tr>
      <th style="width: 12em">Role name</th>
      <th>HTML snippet</th>
    </tr>
  </thead>
  <tbody>
    <%= table_rows([
      ["**form**", "`<form>`"],
      ["**search**", "`<form role=search>`"],
      ["**group**", "`<fieldset>`"],
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
      ["**progressbar**", "`<progress>`"],
      ["**status**", "`<output>`"],
    ]) %>
  </tbody>
</table>

_Note: The code examples here use [Testing Library](https://testing-library.com/), which works with React, Vue, Preact, Angular, Puppeteer, and more._

----

## Form

```html
<form aria-labelledby=sign-up-heading>
  <h1 id=sign-up-heading>Sign Up</h1>
  …
</form>
```

```js
screen.getByRole('form', { name: 'Sign up' });
```

----

## Button

```html
<button>Save</button>
```

```js
screen.getByRole('button', { name: 'Save' });
```

### Disabled

```html
<button disabled>Save</button>
```

```js
expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled();
```

----

## Textbox

```html
<label>Name <input type=text></label>
```

```js
screen.getByRole('textbox', { name: 'Name' });
```

### Multilined

```html
<label>Bio <textarea></textarea></label>
```

```js
screen.getByRole('textbox', { name: 'Bio' });
```

### Specific types

```html
<label>Email <input type=email></label>
<label>Website <input type=url></label>
<label>Phone <input type=tel></label>
```

```js
const emailTextbox = screen.getByRole('textbox', { name: 'Email' });
const websiteTextbox = screen.getByRole('textbox', { name: 'Website' });
const phoneTextbox = screen.getByRole('textbox', { name: 'Phone' });
```

### Expect value to match

```html
<label>Bio <textarea>Some bio</textarea></label>
```

```js
expect(
  screen.getByRole('textbox', { name: 'Bio' })
).toHaveValue("Some bio");
```

----

## Searchbox

```html
<label>Search <input type=search></label>
```

```js
screen.getByRole('searchbox', { name: 'Search' });
```

----

## Checkbox

```html
<label><input type=checkbox> Receive email alerts</label>
```

```js
screen.getByRole('checkbox', { name: 'Receive email alerts' });
```

### Expect to be checked

```html
<label><input type=checkbox checked> Receive email alerts</label>
```

```js
expect(
  screen.getByRole('checkbox', { name: 'Receive email alerts' })
).toBeChecked();
```

----

## Radio & Radiogroup

```html
<fieldset role=radiogroup>
  <legend>Favorite color</legend>
  <label><input type=radio name=fave-color value=green> Green</label>
  <label><input type=radio name=fave-color value=red checked> Red</label>
  <label><input type=radio name=fave-color value=yellow> Yellow</label>
  <label><input type=radio name=fave-color value=blue> Blue</label>
</fieldset>
```

```js
screen.getByRole('radiogroup', { name: 'Favorite color' });
```

```js
expect(screen.getByRole('radio', { name: 'Red' })).toBeChecked();
```

```js
expect(
  screen.getByRole('radiogroup', { name: 'Favorite color' })
).toHaveFormValues({ 'fave-color': 'red' });
```
