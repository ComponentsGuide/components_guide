# Reduce form boilerplate with React reducers

## Thinking of validation as a linear process

We can think of validation as mapping from events to errors.

We have two events: `blur` and `submit`.

When a field is blurred, we validate whether its value is valid or not.

When a whole form is submitted, we validate **all** of its fields at once.

It would be great to write the same code to validate either a single field (when it is blurred) or a whole bunch of fields (when their form is submitted).

If we were to sketch out the steps:

1. Get the field(s) matching this event.
2. Get the values from the fields.
3. Validate each value.
4. Store a key-value map for each error, with the key identifying the field, and the value holding the error message.

So how do we do each of these steps?

## Get the fields matching this event

Each event that happens from a user interacting with some UI control has that control as part of the event. These can be accessed via the `.target` property on the event.

For a `blur` event on an `<input>`, the `.target` property will refer to the input’s DOM element. This is an instance of [`HTMLInputElement`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement), which includes convenient properties like reading the current `.value`.

For a `submit` event on a `<form>`, the `.target` property will refer to the form’s DOM element. This is an instance of [`HTMLFormElement`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement).

Here’s an example form written in React demonstrating reading from the event:

```tsx
<form
  onSubmit={(event) => {
    event.preventDefault();
    const form = event.target;
    console.log(form instanceof HTMLFormElement); // true
  }}
>
  <label for="f">First name</label>
  <input
    id="f"
    onBlur={(event) => {
      const input = event.target;
      console.log(input instanceof HTMLInputElement); // true
    }}
  />
</form>
```

## Get the values from the fields

So we’ve successfully been able to get a DOM element corresponding to the event. Why is this so powerful? Because we can read the current state of the form without having to store that state in React.

That is, instead of adding an `onChange` handler to the form’s inputs and using that to update some React state, we can use these two events `blur` and `submit` as synchronization points to read from the DOM that the user is actively interacting with. Instead of listening to and controlling everything about the form, we let the browser do some of the work.

Here are the two events we care about and the validation work we do for each.

- `blur` event -> HTMLInputElement -> input value -> validate that single value.
- `submit` event -> HTMLFormElement -> all input values -> validate every value.

How we get all input values from a form? There’s a number of approaches, including using the [`.elements` property](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/elements) to get a list of child DOM elements. My favorite approach is to use [`FormData`](https://developer.mozilla.org/en-US/docs/Web/API/FormData) which has been added to browsers.

If you have a HTMLFormElement, you can quickly read every single value from the form by creating a new `FormData` passing the form:

```tsx
const values = new FormData(form);
values.get("firstField"); // "Some string"
values.get("secondField"); // "Another string value"

// For the given form:
<form>
  <label for="f1">First</label>
  <input id="f1" name="firstField" value="Some string" />

  <label for="f2">Second</label>
  <input id="f2" name="secondField" value="Another string value" />
</form>;
```

Note the keys like `firstField` are provided by setting the `name` attribute of each `<input>`.

If we wanted to create an empty `FormData` and add values to it, we can also do that:

```ts
const values = FormData();
values.get("firstField"); // null
values.set("firstField", "The value for this field");
values.get("firstField"); // "The value for this field"
```

Let’s see that with our React form:

```tsx
function validate(values) {
  // TODO
}

<form
  onSubmit={(event) => {
    event.preventDefault();
    const form = event.target;
    const values = new FormData(form);
    validate(values);
  }}
>
  <label for="f1">First name</label>
  <input
    id="f1"
    name="firstName"
    onBlur={(event) => {
      const input = event.target;
      const values = new FormData();
      values.set("firstName", input.value);
      validate(values);
    }}
  />
</form>;
```

You can see for both events we get the associated DOM element and their relevant values and turn it into a `FormData`. I like this pattern of turning two different types of input into a consistent output, as now the code that follows can think about things in just one way, instead of requiring two branches say with an `if` statement.

Now, you might think “there’s only one field here, so I’m going to have to duplicate the `onBlur` handler for every field”.

Say if we added _last name_ and _email_ fields, our code now looks like this:

```tsx
function validate(values) {
  // TODO
}

<form
  onSubmit={(event) => {
    event.preventDefault();
    const form = event.target;
    const values = new FormData(form);
    validate(values);
  }}
>
  <label for="f1">First name</label>
  <input
    id="f1"
    name="firstName"
    onBlur={(event) => {
      const input = event.target;
      const values = new FormData();
      values.set("firstName", input.value);
      validate(values);
    }}
  />

  <label for="f2">Last name</label>
  <input
    id="f2"
    name="lastName"
    onBlur={(event) => {
      const input = event.target;
      const values = new FormData();
      values.set("lastName", input.value);
      validate(values);
    }}
  />

  <label for="f3">Email</label>
  <input
    id="f3"
    name="email"
    type="email"
    onBlur={(event) => {
      const input = event.target;
      const values = new FormData();
      values.set("email", input.value);
      validate(values);
    }}
  />
</form>;
```

Ugghh that’s a lot of repetition. Wouldn’t it be great it we could just have one `onBlur` handler? Turns out we can:

```tsx
function validate(values) {
  // TODO
}

<form
  onBlur={(event) => {
    const input = event.target;
    const values = new FormData();
    values.set(input.name, input.value);
    validate(values);
  }}
  onSubmit={(event) => {
    event.preventDefault();
    const form = event.target;
    const values = new FormData(form);
    validate(values);
  }}
>
  <label for="f1">First name</label>
  <input id="f1" name="firstName" />

  <label for="f2">Last name</label>
  <input id="f2" name="lastName" />

  <label for="f3">Email</label>
  <input id="f3" name="email" type="email" />
</form>;
```

This is a feature of JavaScript, not React. Events like `blur` bubble up, so if they aren’t handled by an event listener on the input element itself, then they bubble to its parent and then its parent, right up to the `<body>`.

Since we want to handle all `blur` events within the form in the same way, it makes sense to add the `blur` event handler to the form itself.

Plus we can use the same `name` attribute that `new FormData(form)` uses to identify the field’s value in our `onBlur` handler.

## Validate each value

So given we have a `FormData` object for both the `blur` and `submit` events, how can we validate each value?

We’ll be validating that the fields were filled in. If the user didn’t type anything in, or only entered whitespace, we’ll flag it as an error. Otherwise, we’ll say the field is valid.

We’ll store our errors in a `Map`, which is similar to `FormData` with `.get()` and `.set()` methods, but we can use to store any key-value pairs.

```ts
function validate(values: FormData) {
  const errors = new Map<string, string>();
  for (let [name, value] of values) {
    // Ignore whitespace: "   " is still counted as invalid.
    value = value.trim();

    if (value === "") {
      errors.set(name, `Field ${name} must be filled in.`);
    }
  }
  return errors;
}
```

We can iterate over the `values` since `FormData` is iterable, like an array.

So we have our errors. Let’s store them in state so we can render them using React.

## Store a key-value map for each error

Let’s wrap what we have so far into an actual component, and store the errors using the `useState` hook.

We also display the error message alongside its form field. We use the `aria-describedby` attribute so that assistive technology like screen readers know which input has which error message. (The more specific `aria-errormessage` attribute is unfortunately [not well supported](https://a11ysupport.io/tech/aria/aria-errormessage_attribute) and so it’s [recommended to use `aria-describedby` instead](https://www.davidmacd.com/blog/test-aria-describedby-errormessage-aria-live.html).)

```tsx
function validate(values: FormData) {
  const errors = new Map<string, string>();
  for (let [name, value] of values) {
    // Ignore whitespace: "   " is still counted as invalid.
    value = value.trim();

    if (value === "") {
      errors.set(name, `Field ${name} must be filled in.`);
    }
  }
  return errors;
}

function ProfileForm() {
  const [errors, setErrors] = useState(new Map<string, string>());

  return (
    <form
      onBlur={(event) => {
        const input = event.target;
        const values = new FormData();
        values.set(input.name, input.value);
        setErrors(validate(values));
      }}
      onSubmit={(event) => {
        event.preventDefault();
        const form = event.target;
        const values = new FormData(form);
        setErrors(validate(values));
      }}
    >
      <label for="f1">First name</label>
      <input
        id="f1"
        name="firstName"
        aria-describedby="f1error"
        aria-invalid={errors.has("firstName")}
      />
      <span id="f1error">{errors.get("firstName")}</span>

      <label for="f2">Last name</label>
      <input
        id="f2"
        name="lastName"
        aria-describedby="f2error"
        aria-invalid={errors.has("lastName")}
      />
      <span id="f2error">{errors.get("lastName")}</span>

      <label for="f3">Email</label>
      <input
        id="f3"
        name="email"
        type="email"
        aria-describedby="f3error"
        aria-invalid={errors.has("email")}
      />
      <span id="f3error">{errors.get("email")}</span>
    </form>
  );
}
```

There’s a bug here though. When we `blur` on a specific field, because we create the `errors` map from scratch, we lose the errors for the other fields.

So we want to reuse the errors that were stored in state previously, being careful to remove the error if the field is now valid.

```tsx
function validate(values: FormData, previousErrors: Map<string, string>) {
  // Create a new Map, copying the previous errors across.
  const errors = new Map<string, string>(previousErrors);

  for (let [name, value] of values) {
    // Remove the error if there was one before.
    errors.delete(name);

    // Ignore whitespace: "   " is still counted as invalid.
    value = value.trim();

    if (value === "") {
      errors.set(name, `Field ${name} must be filled in.`);
    }
  }
  return errors;
}

function ProfileForm() {
  const [errors, setErrors] = useState(new Map<string, string>());

  return (
    <form
      onBlur={(event) => {
        const input = event.target;
        const values = new FormData();
        values.set(input.name, input.value);
        setErrors((previousErrors) => validate(values, previousErrors));
      }}
      onSubmit={(event) => {
        event.preventDefault();
        const form = event.target;
        const values = new FormData(form);
        setErrors((previousErrors) => validate(values, previousErrors));
      }}
    >
      <label for="f1">First name</label>
      <input
        id="f1"
        name="firstName"
        aria-describedby="f1error"
        aria-invalid={errors.has("firstName")}
      />
      <span id="f1error">{errors.get("firstName")}</span>

      <label for="f2">Last name</label>
      <input
        id="f2"
        name="lastName"
        aria-describedby="f2error"
        aria-invalid={errors.has("lastName")}
      />
      <span id="f2error">{errors.get("lastName")}</span>

      <label for="f3">Email</label>
      <input
        id="f3"
        name="email"
        type="email"
        aria-describedby="f3error"
        aria-invalid={errors.has("email")}
      />
      <span id="f3error">{errors.get("email")}</span>
    </form>
  );
}
```

Each form field’s HTML is getting lengthy, so I’m going to extract it out into its own `Field` component. This also lets us use the `useId` hook to generate unique DOM IDs instead of having to come up with our own.

```tsx
function Field({
  name,
  label,
  error,
  type = "text",
}: {
  name: string;
  label: string;
  error?: string;
  type?: string;
}) {
  const id = useId();
  const idError = `${id}-error`;

  return (
    <>
      <label for={id}>{label}</label>
      <input
        id={id}
        name={name}
        type={type}
        aria-describedby={idError}
        aria-invalid={typeof error === "string"}
      />
      <span id={idError}>{error}</span>
    </>
  );
}

function validate(values: FormData, previousErrors: Map<string, string>) {
  …
}

function ProfileForm() {
  const [errors, setErrors] = useState(new Map<string, string>());

  return (
    <form
      onBlur={(event) => {
        const input = event.target;
        const values = new FormData();
        values.set(input.name, input.value);
        setErrors((previousErrors) => validate(values, previousErrors));
      }}
      onSubmit={(event) => {
        event.preventDefault();
        const form = event.target;
        const values = new FormData(form);
        setErrors((previousErrors) => validate(values, previousErrors));
      }}
    >
      <Field
        name="firstName"
        label="First name"
        error={errors.get("firstName")}
      />
      <Field
        name="lastName"
        label="Last name"
        error={errors.get("lastName")}
      />
      <Field
        name="email"
        label="Email"
        type="email"
        error={errors.get("email")}
      />
    </form>
  );
}
```

I’m pretty happy with that, and so if that seems clear enough, stick to using the `useState` approach.

However, there’s also a pattern I’m seeing that makes a good fit for a reducer. And that is the way we are passing a callback to the `setErrors` state change callback. We are effectively applying a new event to some state. Let’s see how a reducer is natural for this sort of use case.

## Closing the loop with a reducer

Let’s summarize what we are doing:

1. We listen to both `blur` and `submit` events.
2. We extract a suitable DOM element from the event.
3. We read the relevant form values for that DOM element.
4. We validate each of those form values, creating an error for those that are invalid (or removing errors when valid).
5. We store the errors in state, merging with the previously stored errors.

This is a loop, starting with events and ending in state. That is the perfect fit for a reducer:

```tsx
function reducer(state: { errors: Map<string, string> }, event: Event) {
  …
}
```

Reducers are a very React-y concept, because if you squint, it’s a similar shape to a component:

```tsx
function SomeComponent({
  state,
  event,
}: {
  state: { errors: Map<string, string> };
  event: Event;
}) {
  …
}
```

A React component takes in data and turns it into a view. A React reducer takes in data and an event, and turns it into data.

When the data (props) to a component changes, React re-renders it, running your function again from top-to-bottom.

When a new event is dispatched to a reducer, React re-evaluates it, running your function again from top-to-bottom.

User interactions become data via reducers, data become user interfaces via components.

My reducer becomes concerned with “how do I use this event to change the current state?”

Let’s see how this work with our form validation. We’ll keep the `Field` component and `validate` function from before, but we’ll remove the individual event handlers for `onBlur` and `onSubmit`. Instead, all events will be dispatched to our reducer.

```tsx
function Field(…) {
  …
}

function validate(values: FormData, previousErrors: Map<string, string>) {
  …
}

function reducer(state: { errors: Map<string, string> }, event: Event) {
 // TODO
}

function ProfileForm() {
  const [{ errors }, dispatch] = useReducer(reducer, { errors: new Map<string, string>() });

  return (
    <form
      onBlur={dispatch}
      onSubmit={dispatch}
    >
      <Field
        name="firstName"
        label="First name"
        error={errors.get("firstName")}
      />
      <Field
        name="lastName"
        label="Last name"
        error={errors.get("lastName")}
      />
      <Field
        name="email"
        label="Email"
        type="email"
        error={errors.get("email")}
      />
    </form>
  );
}
```

Since our reducer will receive `submit` events, we’ll make sure we prevent the default browser submission behavior:

```tsx
function reducer(state: { errors: Map<string, string> }, event: Event) {
  if (event.type === "submit") {
    event.preventDefault();
  }

  return state;
}
```

We’ll again read the DOM element from the event and create a `FormData` with the relevant form values.

```tsx
function valuesForEvent(event: Event) {
  // If we have a form, return all the values from the form.
  if (event.target instanceof HTMLFormElement) {
    return new FormData(event.target);
  }

  const formData = new FormData();
  // If we have just a single input, then add its value.
  if (event.target instanceof HTMLInputElement) {
    formData.set(event.target.name, event.target.value);
  }
  return formData;
}

function reducer(state: { errors: Map<string, string> }, event: Event) {
  if (event.type === "submit") {
    event.preventDefault();
  }

  const values = valuesForEvent(event);

  return state;
}
```

We’ll then call our `validate` function with the values to be validated, and also pass along the previous errors:

```tsx
function valuesForEvent(event: Event) {
  …
}

function reducer(state: { errors: Map<string, string> }, event: Event) {
  if (event.type === "submit") {
    event.preventDefault();
  }

  const values = valuesForEvent(event);
  const errors = validate(values, state.errors)

  return { errors };
}
```

## Final code

The result looks like this:

```tsx
function Field({
  name,
  label,
  error,
  type = "text",
}: {
  name: string;
  label: string;
  error?: string;
  type?: string;
}) {
  const id = useId();
  const idError = `${id}-error`;

  return (
    <>
      <label for={id}>{label}</label>
      <input
        id={id}
        name={name}
        type={type}
        aria-describedby={idError}
        aria-invalid={typeof error === "string"}
      />
      <span id={idError}>{error}</span>
    </>
  );
}

function valuesForEvent(event: Event) {
  // If we have a form, return all the values from the form.
  if (event.target instanceof HTMLFormElement) {
    return new FormData(event.target);
  }

  const formData = new FormData();
  // If we have just a single input, then add its value.
  if (event.target instanceof HTMLInputElement) {
    formData.set(event.target.name, event.target.value);
  }
  return formData;
}

function validate(values: FormData, previousErrors: Map<string, string>) {
  // Create a new Map, copying the previous errors across.
  const errors = new Map<string, string>(previousErrors);

  for (let [name, value] of values) {
    // Remove the error if there was one before.
    errors.delete(name);

    // Ignore whitespace: "   " is still counted as invalid.
    value = value.trim();

    if (value === "") {
      errors.set(name, `Field ${name} must be filled in.`);
    }
  }
  return errors;
}

function reducer(state: { errors: Map<string, string> }, event: Event) {
  if (event.type === "submit") {
    event.preventDefault();
  }

  const values = valuesForEvent(event);
  const errors = validate(values, state.errors)

  return { errors };
}

function ProfileForm() {
  const [{ errors }, dispatch] = useReducer(reducer, { errors: new Map<string, string>() });

  return (
    <form
      onBlur={dispatch}
      onSubmit={dispatch}
    >
      <Field
        name="firstName"
        label="First name"
        error={errors.get("firstName")}
      />
      <Field
        name="lastName"
        label="Last name"
        error={errors.get("lastName")}
      />
      <Field
        name="email"
        label="Email"
        type="email"
        error={errors.get("email")}
      />
      <button type="submit">Save</button>
    </form>
  );
}
```

<code-example-react component-name="ProfileForm" class="block mt-8">
  <h2 id="interactive-preview">Interactive preview</h2>
  <style>
    code-example-react form {
      max-width: 20em;
      margin: auto;
      display: flex;
      flex-direction: column;
    }
    code-example-react input {
      font-size: 1em;
      color: black;
    }
    code-example-react button {
      max-width: max-content;
      margin-top: 1rem;
      padding: 0.5rem 2rem;
      color: white;
      background-color: var(--colors-blue-500) !important;
      border-radius: 999px;
    }
    code-example-react [id$="-error"] {
      font-style: italic;
      color: var(--colors-red-500);
    }
  </style>
  <div id="code-example-react-1"></div>
</code-example-react>

<script src="https://cdn.jsdelivr.net/npm/react@18.2.0/umd/react.profiling.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/react-dom@18.2.0/umd/react-dom.profiling.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/react-dom@18.2.0/umd/react-dom-server.browser.production.min.js"></script>

<script type="module">
import * as esbuild from "https://cdn.jsdelivr.net/npm/esbuild-wasm@0.14.1/esm/browser.min.js";
const esbuildPromise = Promise.resolve(esbuild.initialize({
  wasmURL: 'https://cdn.jsdelivr.net/npm/esbuild-wasm@0.14.1/esbuild.wasm',
}).then(() => esbuild));

window.customElements.define('code-example-react', class extends HTMLElement {
  connectedCallback() {
    // this.attachShadow({mode: 'open'});
    // this.id = "code-example-react-1";
    this.doWork().catch(console.error);
  }

  async doWork() {
    const componentName = this.getAttribute('component-name');
    const esbuild = await esbuildPromise;
    const source = this.previousElementSibling.innerText;

    const suffix = `
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);

    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  render() {
    if (this.state.error) {
      return <div class="flex h-full justify-center items-center text-white bg-red-700"><div>Error: {this.state.error.message}</div></div>;
    }

    return <>{this.props.children}</>;
  }
}

export function Example(rootEl = document) {
  console.log("rootEl", rootEl);
  const clientAppEl = rootEl.querySelector('#code-example-react-1');

  const wrapped = <React.Profiler id="App" onRender={(id, phase, actualDuration, baseDuration, startTime, commitTime, interactions) => {
    clientAppEl.dispatchEvent(new CustomEvent('DID_RENDER', { detail: { id, phase, actualDuration, baseDuration, startTime, commitTime, interactions } }));
  }}>
    <ErrorBoundary>
      <${componentName} />
    </ErrorBoundary>
  </React.Profiler>;

  clientAppEl.dispatchEvent(new CustomEvent('RESET'));
  ReactDOM.render(wrapped, clientAppEl);
  clientAppEl.addEventListener('RESET', () => {
    ReactDOM.unmountComponentAtNode(clientAppEl);
  }, { once: true });

  try {
    return ReactDOMServer.renderToString(wrapped);
  } catch (error) {
    return \`<!-- Uncaught error: \${error.message} -->\n<div class="flex h-full justify-center items-center text-white bg-red-700"><div>Error: \${error.message}</div></div>\`;
  }
}
`;

    const { outputFiles } = await esbuild.build({
      bundle: true,
      minify: true,
      stdin: {
        //contents: `${prefix}\n${body ?? ""}\n${suffix}`,
        contents: `${source ?? ""}\n${suffix}`,
        //contents: body ?? "",
        loader: 'tsx',
        sourcefile: 'main.tsx',
      },
      write: false,
      format: 'iife',
      globalName: 'exports',
      plugins: []
    });

    const code = new TextDecoder().decode(outputFiles[0].contents);

    const hookNames = Object.keys(window.React).filter(name => name.startsWith('use'));
    const preamble = hookNames.map(hookName => `const ${hookName} = window.React.${hookName}`).join(';');
    const executor = new Function('rootEl', `${preamble}; ${code}; return exports.Example(rootEl);`);
    const result = executor(this);
  }
});
</script>
