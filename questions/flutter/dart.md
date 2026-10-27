# Dart language

Dart 3 language questions. The verified answers are run by `flutter test` in
[answers/flutter](../../answers/flutter), from
[dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart).

## FLT-001: How does sound null safety work in Dart, and what do `?`, `!`, `??` and `late` do?

**Level:** junior · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

Types are non-nullable by default: a `String` can never hold `null`, and the compiler proves it,
which lets it drop null checks at run time ("sound").

- `String?` is a nullable type. You must check it before use; after `if (name != null)` the
  variable is promoted to `String` (for local variables and private final fields).
- `a?.b` returns `null` instead of calling `b` on `null`; `a ?? b` uses `b` when `a` is `null`;
  `a ??= b` assigns only if `a` is `null`.
- `value!` asserts non-null and throws at run time if it is null. Every `!` is a place a crash can
  happen; prefer a check, a default with `??`, or a better type.
- `late` defers initialisation: the compiler trusts you, and reading the variable before it is set
  throws a `LateInitializationError`. `late final` can be set once. `late` with an initializer
  (`late final total = compute();`) runs the initializer lazily on first read.

```dart
String displayName(String name, String? nickname) => nickname ?? name;

class Session {
  late final String token;   // reading it before login throws
}
```

**Reference:** [Sound null safety](https://dart.dev/null-safety)

## FLT-002: What is the difference between `final` and `const`?

**Level:** junior · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

- `final` means the **variable** is assigned once, at run time. The object it points to can still
  change: `final list = [1]; list.add(2);` is fine.
- `const` means the **value** is a compile-time constant and deeply immutable. A const list throws
  `UnsupportedError` on `add`. Identical const expressions are **canonicalised** into one
  instance, so `identical(const [1, 2], const [1, 2])` is `true`.

```dart
const a = [1, 2, 3];
const b = [1, 2, 3];
identical(a, b);   // true: one shared instance
final c = [1, 2, 3];
c.add(4);          // fine: final fixes the variable, not the list
```

In Flutter this matters because a `const` widget constructor call returns the same instance on
every build, and the framework skips rebuilding a widget whose instance has not changed (see
FLT-014). A class can only have a `const` constructor if all its fields are `final`.

**Reference:** [Variables: Final and const](https://dart.dev/language/variables)

## FLT-003: In what order do synchronous code, microtasks and `Future`s run?

**Level:** mid · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

Each isolate has one thread and an event loop with two queues:

1. The current **synchronous** code runs to completion; nothing interrupts it.
2. Then all **microtasks** run: `scheduleMicrotask`, and callbacks of futures that are already
   completed (`Future.value().then(...)`, code after an `await` of a completed future).
3. Then one item from the **event queue**: timers (`Timer.run`, `Future(() {...})`,
   `Future.delayed`), I/O, user input, frame callbacks. After each event, the microtask queue is
   emptied again.

```dart
Timer.run(() => print('timer'));
Future(() => print('Future()'));
scheduleMicrotask(() => print('microtask'));
Future.value().then((_) => print('then'));
print('sync');
// sync, microtask, then, timer, Future()
```

Two practical consequences: a long synchronous loop blocks frames (the UI freezes) even if it is
inside an `async` function, and an endless chain of microtasks starves the event queue just as
badly. Heavy work belongs in another isolate (FLT-005).

**Reference:** [Concurrency in Dart: Event loop](https://dart.dev/language/concurrency)

## FLT-004: What is the difference between a single-subscription and a broadcast `Stream`?

**Level:** mid · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

- A **single-subscription** stream (the default from `StreamController()`, file reads, HTTP
  bodies) allows one listener. It buffers events until someone listens, so no data is lost, and
  listening a second time throws `StateError`.
- A **broadcast** stream (`StreamController.broadcast()`, `stream.asBroadcastStream()`) allows any
  number of listeners, and each gets the events sent **while** it is listening. Events sent before
  anyone listens are dropped.

```dart
final controller = StreamController<int>.broadcast();
controller.add(1);                         // nobody listening: lost
final sub = controller.stream.listen(print);
controller.add(2);                         // printed
```

Some streams re-run their source for each listener instead: `Stream.fromIterable` is not a
broadcast stream, yet each `listen` iterates the list again. Whichever kind, cancel subscriptions
in `dispose` and close controllers you own; Flutter's `StreamBuilder` subscribes and unsubscribes
for you.

**Reference:** [Asynchronous programming: Streams](https://dart.dev/libraries/async/using-streams)

## FLT-005: When and how do you use isolates in Flutter?

**Level:** mid · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

All Dart code of a Flutter app's UI runs on the main isolate, which must produce a frame every
16 ms at 60 Hz (8 ms at 120 Hz). CPU-heavy work longer than that, such as parsing a large JSON
file, image processing or encryption, causes jank and belongs on another isolate.

Isolates do **not share memory**: each has its own heap, and values are copied when sent (or
moved for `TransferableTypedData`). That removes data races but means you send inputs and get a
result back:

```dart
final total = await Isolate.run(() => sumTo(1000000));
```

`Isolate.run` (and Flutter's `compute`, which uses it) spawns an isolate, runs the function,
returns the result or rethrows its error, and exits. For a long-lived worker that handles many
requests, use `Isolate.spawn` with `SendPort` and `ReceivePort`. Plugins that use platform channels
need `BackgroundIsolateBinaryMessenger.ensureInitialized` before they work in a background
isolate. Async I/O such as an HTTP request does not need an isolate: it does not block the thread.

**References:** [Concurrency in Dart: Isolates](https://dart.dev/language/isolates) · [Concurrency and isolates (Flutter)](https://docs.flutter.dev/perf/isolates)

## FLT-006: What are records and patterns in Dart 3?

**Level:** mid · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

A **record** is an anonymous, immutable group of values with positional and named fields, compared
by value: `(int, String)` or `({double lat, double lng})`. It replaces small classes or lists when
a function returns more than one thing.

**Patterns** destructure and test values in declarations, `switch` and `if-case`:

```dart
(int min, int max) bounds(List<int> values) { ... }
final (min, max) = bounds([4, -2, 9]);      // destructuring

String? cityOf(Object? json) => switch (json) {
  {'address': {'city': final String city}} => city,   // matches the shape and the type
  _ => null,
};
```

The map pattern above replaces several `is` checks and casts when reading JSON: it only matches
when `address` is a map and `city` is a `String`, so `{'city': 35}` yields `null` instead of a type
error. Other patterns include list patterns with rest elements (`[first, ...rest]`), relational
patterns (`>= 0`), logical `||` and `&&`, and guards with `when`.

**References:** [Records](https://dart.dev/language/records) · [Patterns](https://dart.dev/language/patterns)

## FLT-007: What is a `sealed` class, and why is it useful with `switch`?

**Level:** mid · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

A `sealed` class can only be extended or implemented in its own library, so the compiler knows
every direct subtype. A `switch` over it is checked for **exhaustiveness**: forgetting a case is a
compile error, and adding a subtype later flags every switch that needs updating.

```dart
sealed class PaymentResult {}
final class Paid extends PaymentResult { Paid(this.receiptId); final String receiptId; }
final class Declined extends PaymentResult { Declined(this.code); final int code; }
final class Pending extends PaymentResult {}

String describe(PaymentResult result) => switch (result) {
  Paid(:final receiptId) => 'Paid ($receiptId)',
  Declined(code: 402) => 'Card declined',
  Declined(:final code) => 'Declined ($code)',
  Pending() => 'Waiting for the bank',
};
```

This is how Dart models the states of a screen or the result of an operation, like enums with
associated values in Swift or sealed classes in Kotlin. A sealed class is implicitly abstract.
Other class modifiers in Dart 3 (`final`, `base`, `interface`) control whether other libraries may
extend or implement a type.

**Reference:** [Class modifiers](https://dart.dev/language/class-modifiers)

## FLT-008: How do mixins work, and in which order do they run?

**Level:** senior · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

A mixin adds members to a class without inheritance from it: `class A extends B with M1, M2`.
The mixins are applied in order, each creating a new superclass layer, so the class hierarchy is
`A → M2 → M1 → B`. A method calls `super` along that chain, which means **the last mixin listed
runs first**:

```dart
mixin Timestamped on Logger { List<String> describe() => ['Timestamped', ...super.describe()]; }
mixin Tagged on Logger { List<String> describe() => ['Tagged', ...super.describe()]; }

class ConsoleLogger extends Logger with Timestamped, Tagged {}
ConsoleLogger().describe();   // [Tagged, Timestamped, Logger]
```

`on Logger` restricts the mixin to subclasses of `Logger` and allows it to call `super`. Since
Dart 3 a mixin must be declared with `mixin` (or `mixin class`); a plain class can no longer be
used as one. Flutter uses mixins for `TickerProviderStateMixin` and
`AutomaticKeepAliveClientMixin`, where the order matters when two mixins override the same
`State` method.

**Reference:** [Mixins](https://dart.dev/language/mixins)

## FLT-009: What is the difference between an extension method and an extension type?

**Level:** senior · **Verified by:** [dart_language_test.dart](../../answers/flutter/test/dart_language_test.dart)

- An **extension** adds methods to an existing type, statically: `extension Initials on String {
String get initials => ... }` lets you write `'Ada Lovelace'.initials`. The value is still a
  plain `String`; the extension is chosen from the static type, so it does not work through
  `dynamic`.
- An **extension type** (Dart 3.3) is a new static type that wraps a value with **no run-time
  cost**: `extension type UserId(int value)`. The compiler treats `UserId` and `int` as different
  types, so you cannot pass a product ID where a user ID is expected, but at run time it is just
  the `int`.

```dart
extension type const UserId(int value) {
  bool get isValid => value > 0;
}
const id = UserId(42);
final Object? erased = id;
erased is int;   // true: no wrapper object exists
```

Because the wrapper disappears at run time, an extension type is not a security or validation
boundary: a cast or `dynamic` gets the representation back. Without an `implements` clause it is
also not a subtype of `Object`, only of `Object?`, which is why the test stores it in an `Object?`.
JavaScript interop (`dart:js_interop`) uses extension types for this zero-cost reason.

**References:** [Extension methods](https://dart.dev/language/extension-methods) · [Extension types](https://dart.dev/language/extension-types)
