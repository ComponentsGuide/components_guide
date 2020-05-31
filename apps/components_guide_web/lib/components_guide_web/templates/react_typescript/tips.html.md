## Use the `function` keyword for top level functions

Compare these two ways of declaring a function component in JavaScript:

```tsx
const Button = ({
  title,
  onClick
}) => {

}
```

```tsx
function Button({
  title,
  onClick
}) {

}
```

There’s not much difference, but I prefer the latter as:
- The `function` keyword clearly says *I am a function* whereas the `=>` whispers.
- Using function adds a [`name` property](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/name), which is both useful for debugging and is also used in presenting in [React Developer Tools](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en). Arrow functions need an additional [babel plugin]((https://babeljs.io/docs/en/babel-plugin-transform-function-name) to make this happen.
- We don’t need to decide between implicit and explicit returns — we always need to write `return` which makes refactoring quicker as we can quickly add new statements.
- Just because arrow functions are newer doesn’t mean we have to use them all the time.

In TypeScript I think the argument for using the `function` keyword becomes even stronger:

```tsx
function Button({ title, onClick }: ButtonProps): JSX.Element {

}
```

```tsx
import React, { FunctionComponent } from 'react';

const Button: FunctionComponent<ButtonProps> = ({
  title,
  onClick
}) => {

}
```

The top version using `function` has these benefits:
- It’s less typing.
- It’s really clear that it’s a function.
- We don’t have to import a type from the **react** package.
- The stuff I care about is front and centre: the component name, the name of the props.
- Adding the `JSX.Element` return type ensures I remember to `return` a React element, as not returning something will be a compile time error.

## Structural vs nominal types

Most statically typed languages use the concept of nominal types.

If I create two structs in a language like C or Go:

```go
type Point2D struct {
  x float32
  y float32
}

type Point3D struct {
  x float32
  y float32
  z float32
}
```

I can’t cast value of one to the other:

```go
pointA := Point3D{x: 2.0, y: 3.0, z: 1.0}
pointB := Point2D(point)
// Compile error: cannot convert point (type Point3D) to type Point2D
```

In TypeScript, the equivalent is perfectly valid:

```ts
interface Point2D {
  x: float;
  y: float;
}

interface Point3D {
  x: float;
  y: float;
  z: float;
}

const pointA: Point3D = { x: 2.0, y: 3.0, z: 1.0 };
const pointB: Point2D = pointA;
```

This is because the properties of `Point2D` and `Point3D` overlap, or more specifically the type of `Point2D` is a subset of `Point3D`.

This works because TypeScript is concerned with the shape of a type, not the name. What a type *has* not what it *is*. Types are essentially explicit declarations of duck typing.

We can use this to our advantage, and declare types in multiple places (say the model and the view), and the TypeScript compiler will check for us that the values we use are all in agreement with those types.

## Interfaces vs type aliases

There’s some differences between types and interfaces in TypeScript. As this chart shows though, they offer very similar capabilities:
![](https://i.stack.imgur.com/6Tjyp.png)

I prefer to default interfaces for declaring shapes for inputs and outputs. They work with declaring shapes of objects, classes, and even functions.

If I am combining types, then I generally will switch to using the `type` keyword and it’s ability to intersect `&` and union `|` types together. Or if I simply want an alias to an existing type, I will write: `type BlockID = string`.

## Declaring React prop types with TypeScript

Use an interface named after the component with a `Props` suffix. Remember to export it too as your tests probably want it.

```tsx
export interface ButtonProps {
  title: string;
  onClick: () => void;
}
export function Button({ title, onClick }: ButtonProps): JSX.Element {
 // ...
}
```

## Prefer functions to classes

Classes need more ceremony. The need to be instantiated, they can have properties changed over time, and they offer a range of approaches for achieving the same thing.

Functions are called with some input and return some output, and usually have just one way to achieve something. This leads to simpler code and more consistency between developers. They encourage the principle of single responsibility.

Functions are also easier to test — given input X, the expected output is Y.

Examples of things that could be a function:

- **Format** a date into a string
- **Produce** modified state for a given action (a la Redux)
- **Parse** a string into a value
- **Make** a URL for some given state
- **Query** an element with a DOM tree
- **Focus** on an element matching a selector

You can see the single responsibility being enforced here — there’s a single verb and one or two nouns.

Functions should ideally be deterministic and referentially transparent. Woah — what are these words? In English:

- _Deterministic:_ always produce the same result given the same input.
- _Referentially transparent:_ if you can replace the usage of a function with a hard-coded value it produces the same behaviour.

To understand, it might be worth asking what if our functions didn’t have these properties:

- If we couldn’t *determine* all the inputs that affected how a function worked, it would be hard to understand and debug. Think of global variables, or transient state.
- If we couldn’t just paste in a hard coded value instead of calling a function, it would make caching and mocking difficult.

## What is a React component?

With these concepts down, it’s worth asking what is a React component?

**A React component is a deterministic and referentially transparent function that takes in props as input, and produce changes to the DOM as output.**

The general life-cycle of the React engine is:

1. Render: call components that return elements.
2. Render: resolve any nested components by calling them (go to 1).
3. Gather all the leaf HTML elements that all the components produced.
4. Find the differences since the last render, and build a list of DOM changes to be made.
5. Actually commit the changes to the DOM.
6. Call `useLayoutEffect` hooks.
7. Allow the browser to paint and show the user the changes.
8. Call `useEffect` hooks.

There are a few things to note here. The DOM isn’t actually changed until step 5! Our components are merely instructions to the React engine.

The contract that React provides to developers is:
- Pass me a component that maps data to HTML/components, and I will keep the DOM updated for you.
- I will register event handlers and call your `onClick`, `onChange` etc functions.
- I will decide when to call your component functions.
- I can call them as much or as little as I like! I could even call them multiple times in one render.
- I will call your side effect callbacks (e.g. `useEffect`, `useLayoutEffect`) when I like.
- You can let me manage localised state (e.g. `useState`, `useReducer`) on your behalf.
- However, when you ask to change state, I will decide when to actually re-render. Or even if to actually change the state.

Therefore our jobs as developers is to produce well designed components that map to the HTML we want. We have no control over when renders happen, and we shouldn’t try to micro manage the React engine. Doing so can actually give the React engine more work to do, and also defeats the whole purpose of breaking our apps into easy-to-read components.

## What is a React element?

A React element is an description of what DOM element we would like created for us.

They look like this using JSX:

```tsx
const someButton = (
  <button
    type="submit"
    onClick={() => {}}
  >
    Place Order
  </button>
);
```

This is equivalent to writing:

```tsx
const someButton = React.createElement(
  'button',
  {
    type: 'submit',
    onClick: () => {}
  },
  'Place Order'
);
```

It’s not a DOM element — it’s a React element. A button DOM element has behaviour and state and overhead that is not needed to describe what button we would like.

A button DOM element is expensive to create. Every time our component is rendered, we don’t want to create a whole new button from scratch.

So React elements are light-weight. They aren’t much more than vanilla JavaScript objects. They are cheap to create, and so that’s what our component use to describe with.

React will then read that description and manage the creation of the actual DOM elements for us — and update them if they have already been created.

## What is a React hook?

A React hook lets component authors perform more advanced things outside the pure props to HTML contract of components. You can use them directly, or wrap them into higher level patterns.

- `useState` — store data that the component relies on for rendering.
- `useReducer` — more flexible version of `useState`.
- `useEffect` — perform side effect like fetching data or storing in local storage.
- `useLayoutEffect` — perform change to the DOM like focus.
- `useRef` — store data that the component relies on for effects or event handlers.
- `useContext` — use state provided by a higher up component.
- `useMemo` — perform expensive calculations that would be the same across multiple renders.

## Prefer composition

Composition has the following benefits:

- It’s easy to understand what single responsibility each piece has.
- It’s easy to read and understand how each piece fits together.
- It’s easy to pull apart and debug.
- It’s easy to reuse.
- It’s easy to break up into smaller pieces that can also compose.
- It’s easy to mock out a piece that is composed.

We can compose functions. We can compose function components. We can compose hooks.

## Components must have consistent identity

React uses the identity of a function component to know whether the implementation is the same. If the function identity changes from render to render, then React will entirely destroy then recreate the produced DOM elements.

Consider these two components.

This one uses a nested component, which it asks React to render (`<Body />`):

```tsx
interface CardProps {
  title: string;
  children: React.ReactNode;
}
function Card({ title, children }: CardProps): JSX.Element {
  function Body() {
    return <div>{children}</div>;
  }

  return <article>
    <h2>{title}</h2>
    <Body />
  </article>
}
```

This one uses a nested function, which we call:

```tsx
interface CardProps {
  title: string;
  children: React.ReactNode;
}
function Card({ title, children }: CardProps): JSX.Element {
  function renderBody() {
    return <div>{children}</div>;
  }

  return <article>
    <h2>{title}</h2>
    {renderBody()}
  </article>;
}
```

The first with the nested component will destroy the `<div>` every render, because from React’s point of view, it is being managed by a totally different component each time, and so to be safe it must be reset and cleaned up.

The second with the nested function is referentially transparent — it makes no different to React whether how the `<div>` React element got there. All it sees is an `<h2>` and `<div>` inside an `<article>`.

The second behaves no differently to:

```tsx
interface CardProps {
  title: string;
  children: React.ReactNode;
}
function Card({ title, children }: CardProps): JSX.Element {
  return <article>
    <h2>{title}</h2>
    <div>{children}</div>
  </article>;
}
```

For this reason, I would recommend that components are functions that are declared at the top level of a file. A function declared nested inside another will be different each time that outer function is called — so either call these functions yourself or extract them out.

## Once elements & props are given to React, they mustn’t be mutated

When you return an element tree from a component, it might be used immediately or it might be scheduled for use later.

If you kept a reference to an element you returned and mutated it later, React might see an inconsistent view, causing the result to be unpredictable or for it to crash.

React relies on immutability. It avoids creating defensive copies of elements and props, as that would just be overhead.

## Test behavior and markup over implementation detail

## Test roles
