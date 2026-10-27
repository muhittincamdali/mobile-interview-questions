# JavaScript for React Native

The JavaScript that React Native interviews test. The verified answers run with `node --test` in
[answers/react-native](../../answers/react-native), from
[javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs). The same rules apply on
Hermes, React Native's JavaScript engine.

## RN-001: In what order do synchronous code, promise callbacks and `setTimeout` run?

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

The current script runs to completion first. Then the engine empties the **microtask queue**
(promise reactions, `queueMicrotask`, the rest of an `async` function after an `await`), and only
then takes the next **task** (macrotask) such as a timer or an event:

```js
setTimeout(() => log("setTimeout"), 0);
Promise.resolve().then(() => log("promise.then"));
queueMicrotask(() => log("queueMicrotask"));
(async () => {
    log("async function body");
    await null;
    log("after await");
})();
log("synchronous");
// async function body, synchronous, promise.then, queueMicrotask, after await, setTimeout
```

The body of an `async` function runs synchronously up to its first `await`. In React Native this
explains why a long synchronous loop freezes touch handling even inside an async function: the JS
thread is busy, and nothing else on it can run until the loop ends.

**References:** [MDN: The event loop](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Event_loop) · [MDN: Using microtasks](https://developer.mozilla.org/en-US/docs/Web/API/HTML_DOM_API/Microtask_guide)

## RN-002: Why does a loop with `var` capture the same value in every closure?

**Level:** junior · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

A closure captures **variables**, not values. `var` is function-scoped, so a `for (var i …)` loop
has one `i` that every callback shares; when they run, the loop has finished and `i` is 3. `let`
and `const` are block-scoped, and a `for (let …)` loop creates a fresh binding for each iteration:

```js
for (var i = 0; i < 3; i++) callbacks.push(() => i); // 3, 3, 3
for (let j = 0; j < 3; j++) callbacks.push(() => j); // 0, 1, 2
```

Also: `let` and `const` are in the "temporal dead zone" until their declaration runs, so reading
them earlier throws instead of giving `undefined`; `const` prevents reassignment but not mutation of
the object. Modern code uses `const` by default, `let` when the variable is reassigned, and never
`var`.

**Reference:** [MDN: Closures](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Closures)

## RN-003: How is `this` determined, and why do arrow functions help in callbacks?

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

For a normal function, `this` depends on **how it is called**: `counter.increment()` sets `this`
to `counter`, but `const { increment } = counter; increment()` calls it without a receiver, so
`this` is `undefined` in strict mode (class bodies and ES modules are always strict) and the call
throws. Passing `this.handlePress` to a component prop has the same problem.

An **arrow function** has no `this` of its own; it uses the `this` of the scope where it was
created. A class field arrow function (`incrementArrow = () => { … }`) is therefore bound to the
instance. `fn.bind(obj)` creates a bound copy; `call` and `apply` set `this` for one call.

Function components and hooks avoid most of this, since they do not use `this` at all, which is one
reason React moved away from class components.

**Reference:** [MDN: this](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/this)

## RN-004: What is the difference between `==`, `===` and `Object.is`?

**Level:** junior · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

- `==` converts types before comparing: `0 == ''` and `null == undefined` are `true`. The rules
  are hard to remember, so most style guides ban it (except, by some, `value == null` to test for
  both `null` and `undefined`).
- `===` compares without conversion, but `NaN === NaN` is `false` and `0 === -0` is `true`.
- `Object.is` is like `===` except that `Object.is(NaN, NaN)` is `true` and `Object.is(0, -0)` is
  `false`.

Objects and arrays compare **by reference** with all three: `{} === {}` is `false`. That matters in
React, which uses `Object.is` to decide whether state changed and whether hook dependencies
changed: a new object or array literal on every render counts as a change every time.

**Reference:** [MDN: Equality comparisons and sameness](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Equality_comparisons_and_sameness)

## RN-005: When should you use `??` instead of `||`?

**Level:** junior · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

`a || b` returns `b` for **every falsy** `a`: `false`, `0`, `''`, `NaN`, `null`, `undefined`.
`a ?? b` (nullish coalescing) returns `b` only when `a` is `null` or `undefined`. For defaults of
values where `0`, `''` or `false` are valid, `||` is a bug:

```js
const settings = { volume: 0, name: "" };
settings.volume || 50; // 50, wrong: the user chose 0
settings.volume ?? 50; // 0
```

Optional chaining `a?.b?.c` stops and returns `undefined` when a link is `null` or `undefined`,
and works for calls (`onPress?.()`) and indexes (`items?.[0]`). In JSX, `{count && <Badge />}`
renders a literal `0` when `count` is 0, which in React Native is an error because text must be
inside `<Text>`; write `{count > 0 && <Badge />}`.

**References:** [MDN: Nullish coalescing operator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Nullish_coalescing) · [MDN: Optional chaining](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining)

## RN-006: Compare `Promise.all`, `allSettled`, `any` and `race`.

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

| Method               | Resolves when                                             | Rejects when                         | Use it for                                                         |
| -------------------- | --------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------ |
| `Promise.all`        | all fulfil, with all values in order                      | the first one rejects                | Requests that are all required (profile and settings)              |
| `Promise.allSettled` | all have settled, with `{ status, value or reason }` each | never                                | Independent work where partial success is fine (sync five folders) |
| `Promise.any`        | the first one fulfils                                     | all reject, with an `AggregateError` | Redundant sources: the first mirror that answers                   |
| `Promise.race`       | the first one settles, either way                         | the first one to settle rejects      | Timeouts, though `AbortSignal.timeout` is clearer (RN-012)         |

None of them cancels the losers: after `Promise.all` rejects, the other requests keep running. To
stop them, pass an `AbortSignal` to each and abort it in the `catch`. The promises start running
when they are created, not when they are passed to these methods.

**Reference:** [MDN: Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)

## RN-007: What happens with `items.forEach(async (item) => await save(item))`?

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

`forEach` ignores the promises its callback returns. All saves start at once, `forEach` returns
immediately, the code after it runs before anything is saved, and a rejection becomes an unhandled
promise rejection that no surrounding `try`/`catch` sees.

Pick what you mean:

```js
for (const item of items) await save(item); // one after another, in order
await Promise.all(items.map((item) => save(item))); // in parallel, wait for all
```

The test shows the `forEach` version returning with nothing saved and the saves finishing out of
order, and the sequential version finishing in order. For large lists, limit concurrency (run
batches of, say, four) instead of starting hundreds of requests at once on a phone connection.

**Reference:** [MDN: Array.prototype.forEach](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach)

## RN-008: Why does `[10, 9, 1, 100].sort()` return `[1, 10, 100, 9]`?

**Level:** junior · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

Without a compare function, `sort` converts elements to strings and compares UTF-16 code units, so
`"100"` comes before `"9"`. Pass a comparator: `numbers.sort((a, b) => a - b)`. For user-visible
strings use `a.localeCompare(b)` or an `Intl.Collator`, which handle accents and locale rules.

`sort` also **mutates** the array in place and returns the same array. Sorting an array held in
React state that way changes state without creating a new reference, so React may not re-render.
`toSorted` (ES2023, like `toReversed` and `toSpliced`) returns a sorted copy and leaves the
original alone:

```js
const sorted = numbers.toSorted((a, b) => a - b);
```

**Reference:** [MDN: Array.prototype.sort](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort)

## RN-009: Why must React state be updated immutably?

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

React decides whether state changed by comparing the old and new values with `Object.is`. If you
mutate an object and set it again, the reference is the same, so React may skip the render, and
memoized children (`React.memo`, `useMemo`) keep showing old data.

Return new objects for what changed and keep the same references for what did not:

```js
case 'toggle':
  return {
    ...state,
    items: state.items.map((item) => (item.id === action.id ? { ...item, done: !item.done } : item)),
  };
```

The test freezes the old state to prove nothing is mutated, checks that untouched items keep their
identity (so memoized rows do not re-render), and that a no-op action returns the same state object,
which lets React bail out. Spreads are shallow; for deeply nested updates, libraries such as Immer
produce the same result from code that looks like mutation.

**Reference:** [React: Updating Objects in State](https://react.dev/learn/updating-objects-in-state)

## RN-010: How do you implement a debounce, and how is it different from throttle?

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

**Debounce** waits until calls have stopped for a period and then runs once with the last
arguments: search-as-you-type, saving a draft. **Throttle** runs at most once per period while
calls continue: scroll position, analytics for a drag.

```js
export function debounce(fn, waitMs) {
    let timer;
    let pending;
    const debounced = (...args) => {
        pending = args;
        clearTimeout(timer);
        timer = setTimeout(() => {
            const call = pending;
            pending = undefined;
            fn(...call);
        }, waitMs);
    };
    debounced.cancel = () => {
        clearTimeout(timer);
        pending = undefined;
    };
    return debounced;
}
```

The full version in [answers.mjs](../../answers/react-native/src/answers.mjs) also has `flush()`
and rejects a wait that is `NaN`, negative or infinite. The test drives it with mocked timers instead
of real waiting. In a component, create the debounced function once (`useMemo` or `useRef`) and
call `cancel()` in the effect cleanup, otherwise it fires after the screen is gone.

**Reference:** [MDN: setTimeout](https://developer.mozilla.org/en-US/docs/Web/API/Window/setTimeout)

## RN-011: What is a stale closure in a React hook, and how do you avoid it?

**Level:** senior

Every render creates new functions that close over that render's props and state. A function kept
from an earlier render, for example in an effect with missing dependencies or a `setInterval`
callback, keeps reading the values of that render:

```js
useEffect(() => {
    const id = setInterval(() => setCount(count + 1), 1000); // count is always the first value
    return () => clearInterval(id);
}, []);
```

Fixes, depending on the case:

- Use the **updater form** when the new state depends on the old: `setCount((c) => c + 1)`.
- List every value the effect reads in its dependency array, as the `react-hooks/exhaustive-deps`
  lint rule asks, and let the effect re-subscribe.
- Keep the latest value in a ref (`latest.current = value`) when a long-lived callback needs it
  without re-subscribing; `useEffectEvent` (React 19.2) is the built-in form of this pattern for
  effects.

**References:** [React: useEffect](https://react.dev/reference/react/useEffect) · [React: Separating Events from Effects](https://react.dev/learn/separating-events-from-effects)

## RN-012: How do you cancel a `fetch` and give it a timeout?

**Level:** mid · **Verified by:** [javascript.test.mjs](../../answers/react-native/test/javascript.test.mjs)

`fetch` takes an `AbortSignal`. Aborting it rejects the promise with an `AbortError` and lets the
platform drop the request. `AbortSignal.timeout(ms)` aborts on its own with a `TimeoutError`, and
`AbortSignal.any([a, b])` combines a caller's signal with a timeout:

```js
export async function fetchJson(url, { timeoutMs = 10_000, signal } = {}) {
    const timeout = AbortSignal.timeout(timeoutMs);
    const combined = signal ? AbortSignal.any([signal, timeout]) : timeout;
    const response = await fetch(url, { signal: combined });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
}
```

`fetch` resolves for 404 and 500 responses, so check `response.ok`. In a component, create an
`AbortController` in the effect and call `abort()` in its cleanup, so a request for a screen that
is gone does not set state later. The test runs this against a local HTTP server, including one
path that never answers. Check that your React Native version's networking supports
`AbortSignal.any` and `AbortSignal.timeout` before relying on them, or create the timeout with
`setTimeout` and `controller.abort()`.

**References:** [MDN: AbortController](https://developer.mozilla.org/en-US/docs/Web/API/AbortController) · [MDN: AbortSignal.timeout()](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/timeout_static)
