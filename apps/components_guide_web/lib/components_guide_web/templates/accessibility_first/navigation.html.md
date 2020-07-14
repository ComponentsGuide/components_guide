# Accessible Navigation

## Link vs Button

Links are the ‘secret ingredient’ of the web. They take web pages from being standalone documents to being part of a living, collaborative medium.

As a web author, it’s easy to mix up links and buttons, especially when everything is styled to look like a rounded capsule. However, there are clear rules you can follow for when to use links and when to use buttons.

Here’s what users like to do with links:

- They can open a link in a new tab.
- They can share that link with someone else so they can arrive at the same place.
- They can bookmark that link for later.

Let’s see how the specs describe links:

> [WAI-ARIA](https://www.w3.org/TR/wai-aria-1.1/#link) — An interactive reference to an internal or external resource that, when activated, causes the user agent to navigate to that resource.

So how are buttons different?

Clicking a button usually produces a change of some sort. For example, a Checkout action should be a button and not a link, because that action changes the state of the shopping cart. It makes little sense to be able to look at the shopping cart before it was checked out.

In contrast to a link:

- The user shouldn’t be able to open Checkout in a new tab.
- The user can’t share Checkout with someone else.
- The user can’t bookmark Checkout for later.

> [WAI-ARIA Practices](https://www.w3.org/TR/wai-aria-practices/#button) — A button is a widget that enables users to trigger an action or event, such as submitting a form, opening a dialog, canceling an action, or performing a delete operation.

Let’s look the example of an online store, and categorize things into links or buttons:

- The Product Name _links_ to the page dedicated to this product.
- The Add to Wishlist _button_ performs the add to wishlist action.
- The Checkout _button_ changes the state of the shopping cart.
- The Product Image _link_ opens the product photo gallery.
- The More Details _button_ expands to show the full specifications of the product.

----

In short, buttons **perform actions** and links **navigate somewhere**. Links have URLs that can be shared or copied, and buttons cannot be shared.

Every element of a UI mockup should be very clear which model they use. How these elements work is part of the design.

----

## Link

```html
<a href="/about">About</a>
```

```ts
const aboutLink = screen.getByRole('link', { name: 'About' });
```

### When the link is the current page

```html
<a href="/about" aria-current=page>About</a>
```

```ts
const aboutLink = screen.getByRole('link', { name: 'About' });
expect(aboutLink).toHaveAttribute('aria-current', 'page');
```

----

## Navigation

```html
<nav aria-label=Primary>
  <ul>
    <li><a href="/" aria-current=page>Home</a>
    <li><a href="/pricing">Pricing</a>
    <li><a href="/news">News</a>
  </ul>
</nav>
```

```ts
const primaryNav = screen.getByRole('navigation', { name: 'Primary' });
const navLinks = getAllByRole(primaryNav, 'link');

expect(navLinks).toHaveLength(3);
```
