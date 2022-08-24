## Thinking of validation as a linear process

We can think of validation as mapping from events to errors.

We have two events: `blur` and `submit`.

When a field is blurred, we validate whether its value is valid or not.

When a whole form is submitted, we validate all of its fields at once.

It would be great to write the same code to validate either a single field (when it is blurred) or a whole bunch of fields (when their form is submitted).

If we were to sketch this using TypeScript:

```ts
function validate(event: Event): Map<string, string> {
  // Get the field(s) matching this event.
  // Get the values from the fields.
  // Validate each value.
  // Return a key-value map for each error, with the key identifying the field, and the value holding the error message.
}
```

So how do we do each of these steps?

## Get the field(s) matching this event

Each event that happens from a user interacting with some UI control has that control as part of the event. These can be accessed via the `.current` property on the event.

For a `blur` event on an `<input>`, the `.current` property will refer to the input’s DOM element. This is an instance of [`HTMLInputElement`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement), which includes convenient properties like reading the current `.value`.

For a `submit` event on a `<form>`, the `.current` property will refer to the form’s DOM element. This is an instance of [`HTMLFormElement`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement).

Here’s an example form written in React demonstrating reading from the event:

```tsx
<form onSubmit={(event) => {
  const form = event.target;
  console.log(form instanceof HTMLFormElement); // true
}}>
  <label for="f">First name</label>
  <input id="f" onBlur={(event) => {
    const input = event.target;
    console.log(input instanceof HTMLInputElement); // true
  }} />
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
</form>
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

<form onSubmit={(event) => {
  const form = event.target;
  const values = new FormData(form);
  validate(values);
}}>
  <label for="f1">First name</label>
  <input id="f1" name="firstName" onBlur={(event) => {
    const input = event.target;
    const values = new FormData();
    values.set("firstName", input.value);
    validate(values);
  }} />
</form>
```

You can see for both events we get the associated DOM element and their relevant values and turn it into a `FormData`. I like this pattern of turning two different types of input into a consistent output, as now the code that follows can think about things in just one way, instead of requiring two branches say with an `if` statement.

Now, you might think “there’s only one field here, so I’m going to have to duplicate the `onBlur` handler for every field”.

Say if we added _last name_ and _email_ fields, our code now looks like this:

```tsx
function validate(values) {
  // TODO
}

<form onSubmit={(event) => {
  const form = event.target;
  const values = new FormData(form);
  validate(values);
}}>
  <label for="f1">First name</label>
  <input id="f1" name="firstName" onBlur={(event) => {
    const input = event.target;
    const values = new FormData();
    values.set("firstName", input.value);
    validate(values);
  }} />

  <label for="f2">Last name</label>
  <input id="f2" name="lastName" onBlur={(event) => {
    const input = event.target;
    const values = new FormData();
    values.set("lastName", input.value);
    validate(values);
  }} />

  <label for="f3">Email</label>
  <input id="f3" name="email" type="email" onBlur={(event) => {
    const input = event.target;
    const values = new FormData();
    values.set("email", input.value);
    validate(values);
  }} />
</form>
```

Ugghh that’s a lot of repetition. Wouldn’† it be great it we could just have one `onBlur` handler? Turns out we can:

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
</form>
```

This is a feature of JavaScript, not React. Events like `blur` bubble up, so if they aren’t handled by an event listener on the input element itself, then they bubble to its parent and then its parent, right up to the `<body>`.

Since we want to handle all `blur` events within the form in the same way, it makes sense to add the `blur` event handler to the form itself.

Plus we can use the same `name` attribute that `new FormData(form)` uses to identify the field’s value in our `onBlur` handler.

## Validate each value

So given we have a `FormData` object, how can we validate each value?

For now, we’ll just validate that the fields were filled in. If the user didn’t type anything in, or only entered whitespace, we’ll flag it as an error. Otherwise, we’ll say the field is valid and therefore has no error.

We’ll store our errors in a `Map`, which is similar to `FormData` with `.get()` and `.set()` methods, but we can use to store any key-value pairs.

```ts
const errors = new Map();
for (const [name, value] of formDataFromEvent(event)) {
  errors.delete(name);

  // TODO: add more advanced validation here
  if (value.trim() === "") {
    errors.set(name, "Required");
  }
}
```

## Return a key-value map for each error

## Making it repeatable with a reducer

```tsx
function formDataFromEvent(event: Event) {
  if (event.target instanceof HTMLFormElement) {
    return new FormData(event.target);
  }

  const formData = new FormData();
  if (event.target instanceof HTMLInputElement) {
    formData.set(event.target.name, event.target.value);
  }
  return formData;
}

function reducer(state, event) {
  if (event.type === "submit") {
    event.preventDefault();
  }

  const errors = new Map(state.errors);
  for (const [name, value] of formDataFromEvent(event)) {
    errors.delete(name);

    // TODO: add more advanced validation here
    if (value.trim() === "") {
      errors.set(name, "Required");
    }
  }

  return { ...state, errors };
}

function Field({ name, label, error, type = "text" }) {
  const id = useId();
  return (
    <div class="flex items-center gap-2">
      <label for={id}>{label}</label>
      <input id={id} name={name} type={type} />
      <span class="italic">{error}</span>
    </div>
  );
}

export default function App() {
  const [state, dispatch] = useReducer(reducer, { errors: new Map<string, string>() });

  return (
    <form onBlur={dispatch} onSubmit={dispatch} class="flex flex-col items-start gap-4">
      <p class="italic">Fields will individually validate on blur, or every field will validate on submit.</p>
      <fieldset class="flex flex-col gap-2">
        <Field
          name="firstName"
          label="First name"
          error={state.errors.get("firstName")}
        />
        <Field
          name="lastName"
          label="Last name"
          error={state.errors.get("lastName")}
        />
        <Field
          name="email"
          label="Email"
          type="email"
          error={state.errors.get("email")}
        />
      </fieldset>
      <button class="px-3 py-1 bg-blue-300 rounded">Save</button>
    </form>
  );
}
```
