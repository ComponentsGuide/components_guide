# JavaScript Key-Value Collections

- Map
- URLSearchParams
- FormData
- Object
- WeakMap

## Map

- **Pro:** keys can be any JavaScript value, not just strings.
- **Con:** homogeneous TypeScript values.
- 💡 Clone:
```js
const newMap = new Map(otherMap);
```

## URLSearchParams

- Spec: serializes to `application/x-www-form-urlencoded`

## Objects

- Keys can be strings or symbols.
