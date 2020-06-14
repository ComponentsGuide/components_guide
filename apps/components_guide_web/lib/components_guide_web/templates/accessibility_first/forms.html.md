## Form

```html
<form aria-labelledby=sign-up-heading>
  <h1 id=sign-up-heading>Sign Up</h1>
  …
</form>
```

```js
getByRole('form', { name: 'Sign up' });
```

## Button

```html
<button>Save</button>
```

```js
getByRole('button', { name: 'Save' });
```

### Disabled

```html
<button disabled>Save</button>
```

```js
expect(getByRole('button', { name: 'Save' })).toBeDisabled();
```

## Textbox

```html
<label>Name <input type=text></label>
```

```js
getByRole('textbox', { name: 'Name' });
```

### Multilined

```html
<label>Bio <textarea></textarea></label>
```

```js
getByRole('textbox', { name: 'Bio' });
```

### Specific types

```html
<label>Email <input type=email></label>
<label>Website <input type=url></label>
<label>Phone <input type=tel></label>
```

```js
const emailTextbox = getByRole('textbox', { name: 'Email' });
const websiteTextbox = getByRole('textbox', { name: 'Website' });
const phoneTextbox = getByRole('textbox', { name: 'Phone' });
```

### Expect value to match

```html
<label>Bio <textarea>Some bio</textarea></label>
```

```js
expect(
  getByRole('textbox', { name: 'Bio' })
).toHaveValue("Some bio");
```

## Searchbox

```html
<label>Search <input type=search></label>
```

```js
getByRole('searchbox', { name: 'Search' });
```

## Checkbox

```html
<label><input type=checkbox> Receive email alerts</label>
```

```js
getByRole('checkbox', { name: 'Receive email alerts' });
```

### Expect to be checked

```html
<label><input type=checkbox checked> Receive email alerts</label>
```

```js
expect(
  getByRole('checkbox', { name: 'Receive email alerts' })
).toBeChecked();
```


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
getByRole('radiogroup', { name: 'Favorite color' });
```

```js
expect(getByRole('radio', { name: 'Red' })).toBeChecked();
```

```js
expect(
  getByRole('radiogroup', { name: 'Favorite color' })
).toHaveFormValues({ 'fave-color': 'red' });
```
