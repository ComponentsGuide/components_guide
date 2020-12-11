# Landmarks

When you visit a new city, one thing you expect to see are landmarks. Statues, botanical gardens, theaters, skyscrapers, markets. These landmarks help us navigate around unfamiliar areas by being reference points we can see on the horizon or on a map.

As makers of the web, we can also provide landmarks to people. These aren’t arbitrary — there are eight landmarks that are part of the HTML standard:

- Navigation
- Main
- Banner
- Search
- Form
- Content info
- Region
- Complementary

Some of these seem obvious, but some are odd — what on earth does “contentinfo” mean? Let’s walk through what they are, why they are important to provide, and finally how we can really easily use them.

## Navigation

Nearly all websites have a primary navigation. It’s often presented as a row of links at the top of the page, or under a hamburger menu.

![Stripe’s navigation bar at the top of its homepage][stripe-nav]

Stripe’s navigation provides links to the primary pages people want to visit. It’s clear, and follows common practices of showing only a handful of links, and placing the link to sign in up on the far right.

Most visual users would identify this as the primary navigation of the site, and so you should denote it as such in your HTML markup. Here’s what you might write for Stripe’s navigation:

[stripe-nav]: https://icing.space/wp-content/uploads/2020/03/DraggedImage.77e7cbde60df4e08a4eac02d9ce73454-2048x134.png
