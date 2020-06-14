## Link

```html
<a href="/about">About</a>
```

```ts
const aboutLink = screen.getByRole('link', { name: 'About' });
```

### Current link

```html
<a href="/about" aria-current=page>About</a>
```

```ts
expect(aboutLink).toHaveAttribute('aria-current', 'page');
```

## Navigation

```ts
const primaryNav = screen.getByRole('navigation', { name: 'Primary' });
const navLinks = getAllByRole(primaryNav, 'link');
```

```html
<nav aria-label=Primary>
  <ul>
    <li><a href="/" aria-current=page>Home</a>
    <li><a href="/pricing">Pricing</a>
    <li><a href="/news">News</a>
  </ul>
</nav>
```
