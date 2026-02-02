# JavaScript/TypeScript Fundamentals - Deep Dive

A comprehensive deep dive into JavaScript and TypeScript fundamentals for React Native interviews.

---

## Closures and Scope

### Q: Explain closures in JavaScript with a practical example.

**Difficulty:** 🟢 Junior

A closure is a function that remembers the variables from its outer scope even after the outer function has returned.

```javascript
// Classic closure example
function createCounter(initialValue = 0) {
  let count = initialValue;

  return {
    increment: () => ++count,
    decrement: () => --count,
    getCount: () => count,
    reset: () => { count = initialValue; },
  };
}

const counter = createCounter(10);
counter.increment();
counter.increment();
console.log(counter.getCount()); // 12

// Practical: debounce utility
function debounce(fn, delay) {
  let timeoutId;

  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn.apply(this, args), delay);
  };
}

const debouncedSearch = debounce((query) => {
  console.log(`Searching: ${query}`);
}, 300);
```

---

### Q: What is the difference between `var`, `let`, and `const`?

**Difficulty:** 🟢 Junior

```javascript
// var — function-scoped, hoisted, can be redeclared
function varExample() {
  console.log(x); // undefined (hoisted)
  var x = 10;
  var x = 20;     // OK — redeclaration allowed

  if (true) {
    var y = 30;   // function-scoped, not block-scoped
  }
  console.log(y); // 30
}

// let — block-scoped, not hoisted (TDZ), no redeclaration
function letExample() {
  // console.log(x); // ReferenceError (TDZ)
  let x = 10;
  // let x = 20;     // Error — no redeclaration

  if (true) {
    let y = 30;     // block-scoped
  }
  // console.log(y); // ReferenceError
}

// const — block-scoped, must be initialized, reference immutable
const obj = { name: 'Alice' };
obj.name = 'Bob';    // OK — object is mutable
// obj = {};          // Error — reference is immutable

// Classic interview question: loop with var vs let
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100); // 3, 3, 3
}

for (let j = 0; j < 3; j++) {
  setTimeout(() => console.log(j), 100); // 0, 1, 2
}
```

---

## Prototypes and Classes

### Q: Explain the prototype chain in JavaScript.

**Difficulty:** 🟡 Mid

```javascript
// Every object has a [[Prototype]] (accessible via __proto__ or Object.getPrototypeOf)
const animal = {
  breathe() {
    return `${this.name} is breathing`;
  },
};

const dog = Object.create(animal);
dog.name = 'Rex';
dog.bark = function () {
  return `${this.name} says woof!`;
};

console.log(dog.bark());    // "Rex says woof!" — own method
console.log(dog.breathe()); // "Rex is breathing" — inherited from prototype

// Prototype chain: dog → animal → Object.prototype → null

// ES6 class is syntactic sugar over prototypes
class Animal {
  constructor(name) {
    this.name = name;
  }

  breathe() {
    return `${this.name} is breathing`;
  }
}

class Dog extends Animal {
  bark() {
    return `${this.name} says woof!`;
  }
}

const rex = new Dog('Rex');
console.log(rex instanceof Dog);    // true
console.log(rex instanceof Animal); // true

// Under the hood:
// rex.__proto__ === Dog.prototype
// Dog.prototype.__proto__ === Animal.prototype
```

---

## Promises and Async/Await

### Q: Explain the Promise lifecycle and error handling patterns.

**Difficulty:** 🟡 Mid

```javascript
// Promise states: pending → fulfilled OR rejected
const fetchData = (shouldFail) =>
  new Promise((resolve, reject) => {
    setTimeout(() => {
      shouldFail
        ? reject(new Error('Network error'))
        : resolve({ id: 1, name: 'Alice' });
    }, 1000);
  });

// Chaining
fetchData(false)
  .then((data) => {
    console.log(data);
    return fetchMoreData(data.id);
  })
  .then((moreData) => console.log(moreData))
  .catch((error) => console.error(error))
  .finally(() => console.log('Done'));

// Async/await equivalent
async function loadData() {
  try {
    const data = await fetchData(false);
    const moreData = await fetchMoreData(data.id);
    return moreData;
  } catch (error) {
    console.error(error);
    throw error;
  } finally {
    console.log('Done');
  }
}

// Parallel execution
const [users, posts, comments] = await Promise.all([
  fetchUsers(),
  fetchPosts(),
  fetchComments(),
]);

// Race — first to settle wins
const result = await Promise.race([
  fetchFromPrimary(),
  fetchFromBackup(),
]);

// allSettled — wait for all, regardless of success/failure
const results = await Promise.allSettled([
  fetchUser(1),
  fetchUser(2),  // might fail
  fetchUser(3),
]);

results.forEach((result) => {
  if (result.status === 'fulfilled') {
    console.log(result.value);
  } else {
    console.error(result.reason);
  }
});
```

---

### Q: What is the event loop? Explain microtasks vs macrotasks.

**Difficulty:** 🔴 Senior

```javascript
console.log('1 - sync');

setTimeout(() => console.log('5 - macrotask (setTimeout)'), 0);

Promise.resolve().then(() => console.log('3 - microtask (Promise)'));

queueMicrotask(() => console.log('4 - microtask (queueMicrotask)'));

console.log('2 - sync');

// Output:
// 1 - sync
// 2 - sync
// 3 - microtask (Promise)
// 4 - microtask (queueMicrotask)
// 5 - macrotask (setTimeout)

// Event loop order:
// 1. Execute synchronous code (call stack)
// 2. Drain microtask queue (Promise callbacks, queueMicrotask)
// 3. Execute one macrotask (setTimeout, setInterval, I/O)
// 4. Drain microtask queue again
// 5. Render updates (in browser)
// 6. Repeat from 3

// React Native uses a JS thread with this event loop
// Bridge calls from native are queued as macrotasks
// In new architecture (JSI), calls can be synchronous
```

---

## TypeScript

### Q: Explain TypeScript utility types with practical examples.

**Difficulty:** 🟡 Mid

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: 'admin' | 'user' | 'moderator';
  createdAt: Date;
}

// Partial — all properties optional
type UserUpdate = Partial<User>;
// { id?: string; name?: string; ... }

// Pick — select specific properties
type UserPreview = Pick<User, 'id' | 'name' | 'avatar'>;
// { id: string; name: string; avatar?: string; }

// Omit — exclude specific properties
type CreateUser = Omit<User, 'id' | 'createdAt'>;
// { name: string; email: string; avatar?: string; role: ... }

// Required — all properties required
type CompleteUser = Required<User>;
// { id: string; name: string; email: string; avatar: string; role: ...; createdAt: Date }

// Record — key-value mapping
type UserRoles = Record<string, User['role']>;
// { [key: string]: 'admin' | 'user' | 'moderator' }

// Readonly — all properties readonly
type FrozenUser = Readonly<User>;
// Cannot modify any property

// Extract / Exclude — for union types
type AdminRole = Extract<User['role'], 'admin' | 'moderator'>;
// 'admin' | 'moderator'

type NonAdminRole = Exclude<User['role'], 'admin'>;
// 'user' | 'moderator'

// ReturnType / Parameters
function createUser(name: string, email: string): User {
  return { id: '1', name, email, role: 'user', createdAt: new Date() };
}

type CreateUserReturn = ReturnType<typeof createUser>;  // User
type CreateUserParams = Parameters<typeof createUser>;   // [string, string]
```

---

### Q: Explain TypeScript generics and conditional types.

**Difficulty:** 🔴 Senior

```typescript
// Generic constraints
interface HasId {
  id: string;
}

function findById<T extends HasId>(items: T[], id: string): T | undefined {
  return items.find((item) => item.id === id);
}

// Conditional types
type IsString<T> = T extends string ? true : false;
type A = IsString<string>;  // true
type B = IsString<number>;  // false

// Practical: API response wrapper
type ApiResponse<T> = T extends Array<infer U>
  ? { data: U[]; total: number; page: number }
  : { data: T };

type UserListResponse = ApiResponse<User[]>;
// { data: User[]; total: number; page: number }

type UserResponse = ApiResponse<User>;
// { data: User }

// Mapped types
type Validators<T> = {
  [K in keyof T]: (value: T[K]) => boolean;
};

const userValidators: Validators<Pick<User, 'name' | 'email'>> = {
  name: (value) => value.length > 0,
  email: (value) => value.includes('@'),
};

// Template literal types
type EventName = 'click' | 'focus' | 'blur';
type EventHandler = `on${Capitalize<EventName>}`;
// 'onClick' | 'onFocus' | 'onBlur'

// Discriminated unions (great for React Native state)
type NetworkState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function renderState<T>(state: NetworkState<T>) {
  switch (state.status) {
    case 'idle':
      return null;
    case 'loading':
      return <ActivityIndicator />;
    case 'success':
      return <DataView data={state.data} />;  // TypeScript knows data exists
    case 'error':
      return <ErrorView error={state.error} />;
  }
}
```

---

## Functional Programming Patterns

### Q: Explain common FP patterns used in React Native.

**Difficulty:** 🟡 Mid

```javascript
// Immutable updates (critical for React state)
const state = {
  user: { name: 'Alice', settings: { theme: 'dark' } },
  posts: [{ id: 1, title: 'Hello' }],
};

// Deep immutable update
const newState = {
  ...state,
  user: {
    ...state.user,
    settings: {
      ...state.user.settings,
      theme: 'light',
    },
  },
};

// Array operations (no mutation)
const posts = [
  { id: 1, title: 'First', likes: 5 },
  { id: 2, title: 'Second', likes: 12 },
  { id: 3, title: 'Third', likes: 3 },
];

// Filter + Map + Reduce pipeline
const totalPopularLikes = posts
  .filter((post) => post.likes > 4)
  .map((post) => post.likes)
  .reduce((sum, likes) => sum + likes, 0);
// 17

// Composition
const compose = (...fns) => (x) =>
  fns.reduceRight((acc, fn) => fn(acc), x);

const pipe = (...fns) => (x) =>
  fns.reduce((acc, fn) => fn(acc), x);

const processUser = pipe(
  normalizeEmail,
  validateAge,
  hashPassword,
  saveToDatabase,
);

// Currying
const multiply = (a) => (b) => a * b;
const double = multiply(2);
const triple = multiply(3);

console.log(double(5));  // 10
console.log(triple(5));  // 15

// Memoization
function memoize(fn) {
  const cache = new Map();

  return function (...args) {
    const key = JSON.stringify(args);
    if (cache.has(key)) return cache.get(key);

    const result = fn.apply(this, args);
    cache.set(key, result);
    return result;
  };
}

const expensiveCalc = memoize((n) => {
  console.log('Computing...');
  return n * n;
});

expensiveCalc(5); // Computing... 25
expensiveCalc(5); // 25 (cached)
```

---

## Destructuring and Spread

### Q: Explain advanced destructuring patterns.

**Difficulty:** 🟢 Junior

```javascript
// Nested destructuring with defaults
const {
  user: {
    name = 'Anonymous',
    address: { city = 'Unknown', zip } = {},
  } = {},
  meta: { page = 1 } = {},
} = apiResponse;

// Array destructuring with skip and rest
const [first, , third, ...rest] = [1, 2, 3, 4, 5];
// first=1, third=3, rest=[4,5]

// Swap variables
let a = 1, b = 2;
[a, b] = [b, a];

// Function parameter destructuring (very common in React Native)
function UserCard({
  name,
  email,
  avatar = 'default.png',
  onPress,
}: {
  name: string;
  email: string;
  avatar?: string;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity onPress={onPress}>
      <Image source={{ uri: avatar }} />
      <Text>{name}</Text>
      <Text>{email}</Text>
    </TouchableOpacity>
  );
}

// Dynamic property names
const field = 'email';
const { [field]: emailValue } = { email: 'test@example.com' };
console.log(emailValue); // 'test@example.com'
```

---

## Proxy and Reflect

### Q: What are Proxy and Reflect? Give a practical use case.

**Difficulty:** 🔴 Senior

```javascript
// Proxy intercepts operations on an object
const createReactiveState = (initialState, onChange) => {
  return new Proxy(initialState, {
    set(target, property, value) {
      const oldValue = target[property];
      const result = Reflect.set(target, property, value);

      if (oldValue !== value) {
        onChange(property, oldValue, value);
      }

      return result;
    },

    get(target, property) {
      const value = Reflect.get(target, property);
      // Auto-wrap nested objects
      if (typeof value === 'object' && value !== null) {
        return createReactiveState(value, onChange);
      }
      return value;
    },
  });
};

const state = createReactiveState(
  { count: 0, user: { name: 'Alice' } },
  (prop, oldVal, newVal) => {
    console.log(`${String(prop)}: ${oldVal} → ${newVal}`);
  },
);

state.count = 1;          // "count: 0 → 1"
state.user.name = 'Bob';  // "name: Alice → Bob"

// Validation proxy
const createValidated = (schema) => {
  return new Proxy({}, {
    set(target, prop, value) {
      const validator = schema[prop];
      if (validator && !validator(value)) {
        throw new TypeError(`Invalid value for ${String(prop)}: ${value}`);
      }
      return Reflect.set(target, prop, value);
    },
  });
};

const user = createValidated({
  age: (v) => typeof v === 'number' && v >= 0 && v <= 150,
  email: (v) => typeof v === 'string' && v.includes('@'),
});

user.email = 'test@example.com'; // OK
// user.age = -5;                 // TypeError
```

---

## WeakRef and FinalizationRegistry

### Q: Explain WeakRef and when to use it in React Native.

**Difficulty:** 🔴 Senior

```javascript
// WeakRef holds a reference that doesn't prevent garbage collection
class ImageCache {
  #cache = new Map();
  #registry = new FinalizationRegistry((key) => {
    // Called when the cached image is garbage collected
    console.log(`Image ${key} was garbage collected`);
    this.#cache.delete(key);
  });

  set(key, image) {
    const ref = new WeakRef(image);
    this.#cache.set(key, ref);
    this.#registry.register(image, key);
  }

  get(key) {
    const ref = this.#cache.get(key);
    if (!ref) return undefined;

    const image = ref.deref();
    if (!image) {
      // Object was garbage collected
      this.#cache.delete(key);
      return undefined;
    }

    return image;
  }
}

// Use case in React Native: caching expensive computed results
// that can be recreated if memory pressure causes GC
const cache = new ImageCache();
const bitmap = await createBitmap(uri);
cache.set(uri, bitmap);

// Later...
const cached = cache.get(uri);
if (cached) {
  // Use cached bitmap
} else {
  // Recreate — it was garbage collected
}
```

---

## Generators and Iterators

### Q: What are generators and how are they useful?

**Difficulty:** 🟡 Mid

```javascript
// Generator function — pausable, lazy evaluation
function* range(start, end, step = 1) {
  for (let i = start; i < end; i += step) {
    yield i;
  }
}

for (const n of range(0, 10, 2)) {
  console.log(n); // 0, 2, 4, 6, 8
}

// Infinite sequence
function* fibonacci() {
  let a = 0, b = 1;
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
}

// Take first N from infinite sequence
function take(n, iterable) {
  const result = [];
  for (const value of iterable) {
    result.push(value);
    if (result.length >= n) break;
  }
  return result;
}

console.log(take(8, fibonacci()));
// [0, 1, 1, 2, 3, 5, 8, 13]

// Async generator — great for paginated API calls
async function* fetchAllPages(baseUrl) {
  let page = 1;
  let hasMore = true;

  while (hasMore) {
    const response = await fetch(`${baseUrl}?page=${page}`);
    const data = await response.json();

    yield* data.items;  // yield each item individually

    hasMore = data.hasMore;
    page++;
  }
}

// Consume lazily
for await (const item of fetchAllPages('/api/users')) {
  console.log(item);
  if (someCondition) break;  // Stop fetching early
}
```
