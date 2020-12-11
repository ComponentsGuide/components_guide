# Why Consider Accessibility First?

A mobile-first approach ensures that a phone experience, which many users now prefer and use regularly, is prioritised and is great. This approach helps combat the natural tendency for the mobile experience to be left behind.

Similarly, an accessibility-first experience ensures that the experience using screen readers and other assistive tech is prioritised and is great.

But the benefit goes further, as developers can use the accessibility affordances to write automated tests. And if what they make is accessible immediately, it provides predictable ways to write the tests upfront. This leads to quicker development and greater reliability.

## Consider your HTML, no matter your framework

HTML is not an after-thought, it’s not a ‘solved problem’, it’s not something you learn once and never have to study again. Especially in the world of web apps, it’s worth surveying the capabilities of today’s HTML and the affordances it can bring to every user.

## Accessibility Checklist for HTML

1. **Links vs Buttons:** use links for navigating and buttons for actions.
1. **Landmarks:** provide familiar touch points that users can jump to.
2. **Semantic Content:** add meaningful structure to your content.
3. **Usable Forms:** ensure form controls are labelled and have the correct roles.
4. **Widgets:** allow everyone to use your controls.
5. **Properties:** hide or mark elements using accessibility attributes.

```ts
getByRole('link', { name: 'About' });

getByRole('button', { name: 'Sign up to newsletter' });
```
