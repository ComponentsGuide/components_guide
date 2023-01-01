# Events Design System

You will learn:

- What different events there are.
- The right element for each event.
- The correct HTML for functionality and accessibility.

## Link

```html
<a href="/about">About me</a>
```

- Anti-pattern: adding a navigation event handler to another element like `<button onClick={() => router.goTo(…)}>`

## Click

```html
<button>Add to favorites</button>
```

- Anti-pattern: adding a click handler to an inert element like `<div>`.
- Anti-pattern: adding a click handler to a link like `<a href="#" onClick={…}>`.

## Input

```html
<input type="text" />
```

```html
<textarea></textarea>
```

## Choose

```html
<label for="color-scheme-select">Choose a color scheme</label>
<select id="color-scheme-select">
  <option value="dark">Dark</option>
  <option value="light">Light</option>
  <option value="system">System</option>
</select>
```

```html
<fieldset>
  <legend>Choose a color scheme</legend>
  <label for="radio-dark"><input type="radio" id="radio-dark" value="dark" /> Dark</label>
  <label for="radio-light"><input type="radio" id="radio-light" value="light" /> Light</label>
  <label for="radio-system"><input type="radio" id="radio-system" value="system" /> System</label>
</fieldset>
```

## Search

```html
<input type="searchbox" />
```

## Autocomplete
