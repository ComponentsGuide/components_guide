## Deciding whether to control a form element

If you’ve used React for a while, or have read the [React docs](https://reactjs.org/docs/uncontrolled-components.html), you’ve probably come across controller vs uncontrolled components. Here’s a summary of each’s benefits:

- A controlled form element lets you have **full control** over its value.
- An uncontrolled form element can let you handle events with **less code**.

Instead of thinking about controlled vs uncontrolled components, it can be helpful to think about implicit vs explicit state:

- A form element with **explicit state** has its state managed externally.
- A form element with **implicit state** manages its own state.

## Controlled form elements, or explicit state

- State is explicit and owned by us.
- We store the state for each field using `useState` or `useReducer`.
- We must set the current `value` of the input when rendering.
- We must listen to when the user changes using `onChange` on each input, and update our state.
- We can then read our local state when say the form is submitted.

Here’s an example of a Sign In form with email and password inputs using controlled state:

```tsx
import React, { useState } from "react";
import authService from "../services/auth";

function SignInForm() {
  const [email, updateEmail] = useState("");
  const [password, updatePassword] = useState("");

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault(); // Prevent performing normal submission
        // Could validate here.
        authService.signIn({ email, password });
      }}
    >
      <label>
        Email
        <input
          type="email"
          value={email}
          onChange={(event) => {
            updateEmail(event.target.value);
          }}
        />
      </label>
      <label>
        Password
        <input
          type="password"
          value={password}
          onChange={(event) => {
            updatePassword(event.target.value);
          }}
        />
      </label>
      <button type="submit">Sign In</button>
    </form>
  );
}
```

## Uncontrolled form elements, or implicit state

- State is implicit, tucked away inside the form control element and managed by React for us.
- We can set an initial value using `defaultValue`.
- We don’t _have_ to listen to any change events.
- We can then read using the DOM when the form is submitted.

Here’s an example of a Sign In form with email and password inputs using uncontrolled state, and reading the inputted values using [`FormData`](https://developer.mozilla.org/en-US/docs/Web/API/FormData):

```tsx
import React from "react";
import authService from "../services/auth";

function SignInForm() {
  return (
    <form
      onSubmit={(event) => {
        event.preventDefault(); // Prevent performing normal submission
        const form = event.target;
        const data = new FormData(form);
        const email = data.get('email');
        const password = data.get('password');

        // We could validate at this point if we wanted.

        authService.signIn({ email, password });
      }}
    >
      <label>
        Email
        <input type="email" name="email" />
      </label>
      <label>
        Password
        <input type="password" name="password" />
      </label>
      <button type="submit">Sign In</button>
    </form>
  );
}
```
