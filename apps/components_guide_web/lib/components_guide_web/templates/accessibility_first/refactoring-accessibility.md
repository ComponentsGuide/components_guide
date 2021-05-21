# Refactoring Accessibility

## Headings

- When to use `<h1>`?
- Examples from news websites of their hierarchy

Here’s an example from The Economist:

```html
<header>
  <h1>
    <span>
      Silent sigh
    </span>
    <br>
    <span itemprop="headline">
      South Korea is pushing America for new talks with the North
    </span>
  </h1>
  <p itemprop="description">
    The 70-year stalemate between the two Koreas is unlikely to break without fresh diplomacy
  </p>
</header>
```

## Navigation

- Before: `class="current"`
- After: `aria-current="page"`

## Tooltip

- Before: interactive tooltip that appears only after clicking a very small target
- After: description hint text that is always shown, with `aria-describedby`
