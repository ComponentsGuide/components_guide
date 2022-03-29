## Deciding whether to control a form element

- A controlled element lets you have **full control** over its value.
- An uncontrolled element can let you handle events with less code.

## Controlled form elements

- We store the state for each field using `useState`.
- We must set the current `value` of the input when rendering.
- We must listen to when the user changes using `onChange` on each input, and update our state.
- We can then read our state when the form is submitted.

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

## Uncontrolled form elements

- We have no state — the input itself holds the state.
- We could set an initial value using `defaultValue`.
- We don’t have to listen to any change events.
- We can then read from the form using the DOM when it is submitted.

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
        // Could validate here.
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
