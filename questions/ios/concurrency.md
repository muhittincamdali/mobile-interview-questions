# Swift concurrency

async/await, tasks, actors and data-race safety in the Swift 6 language mode. The verified
answers run in [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift).

## IOS-022: What does async/await give you over completion handlers?

**Level:** junior

- **Straight-line code**: steps that depend on each other are written one after another, with
  `try` and `catch`, instead of nested callbacks.
- **Every path finishes**: the compiler makes an `async` function return or throw on every path,
  while a completion handler can be forgotten or called twice.
- **Cancellation and priority** flow from the parent task to everything it awaits.
- **Data-race checking**: the compiler knows which actor each piece of code runs on and rejects
  unsafe sharing in the Swift 6 language mode.

`await` marks a **suspension point**: the function may pause there, the thread is given back to
run other work, and the function may resume on a different thread. A suspension point is not a
lock and not a thread switch you can rely on; what runs where is decided by actor isolation
(see IOS-028).

```swift
func loadProfile() async throws -> Profile {
    let user = try await api.user()
    let avatar = try await images.load(user.avatarURL)
    return Profile(user: user, avatar: avatar)
}
```

**Reference:** [Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

## IOS-023: What is structured concurrency? Compare `async let`, task groups, `Task {}` and `Task.detached`.

**Level:** mid · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

In **structured** concurrency, child tasks are tied to a scope: the parent cannot return before
its children finish, cancelling the parent cancels the children, and errors propagate up.

| Tool                                      | Structured | Use it for                                                                                                      |
| ----------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------- |
| `async let`                               | yes        | A fixed number of parallel calls: `async let a = f(); async let b = g()`                                        |
| `withTaskGroup` / `withThrowingTaskGroup` | yes        | A dynamic number of children; results arrive in completion order                                                |
| `Task { }`                                | no         | Starting async work from synchronous code (a button action). Inherits the actor, priority and task-local values |
| `Task.detached { }`                       | no         | Work that must not inherit the current actor or task-locals. Rarely needed                                      |

```swift
let squares = await withTaskGroup(of: (Int, Int).self) { group in
    for number in 1...5 { group.addTask { (number, number * number) } }
    var results: [Int: Int] = [:]
    for await (number, square) in group { results[number] = square }
    return results
}
```

Unstructured tasks are not cancelled when the code that created them goes away; keep the `Task`
handle and call `cancel()` (SwiftUI's `.task` modifier does this for you). An `async let` that is
never awaited is cancelled and awaited implicitly when its scope ends.

**References:** [Concurrency: Tasks and Task Groups](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) · [TaskGroup](https://developer.apple.com/documentation/swift/taskgroup)

## IOS-024: How does task cancellation work?

**Level:** mid · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

Cancellation is **cooperative**. `task.cancel()` only sets a flag on the task and its children;
nothing is stopped by force. Code reacts by:

- calling `try Task.checkCancellation()`, which throws `CancellationError`, or reading
  `Task.isCancelled` and returning early;
- awaiting APIs that check for you: `Task.sleep` throws `CancellationError`, and `URLSession`'s
  async methods cancel the request and throw `URLError(.cancelled)`;
- wrapping callback-based work in `withTaskCancellationHandler(operation:onCancel:)` to cancel
  the underlying operation.

The test cancels a parent while one child sleeps and another loops: the sleeping child gets
`CancellationError`, and the loop only stops because it checks `Task.isCancelled`. A loop that never
checks would keep running and keep the parent waiting.

```swift
for item in items {
    try Task.checkCancellation()
    await process(item)
}
```

After cancellation, clean up and return quickly; returning partial results is fine if the API
documents it.

**Reference:** [Task](https://developer.apple.com/documentation/swift/task)

## IOS-025: What is an actor, and how does it prevent data races?

**Level:** mid · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

An actor is a reference type that protects its mutable state by running one piece of its code at
a time. Code outside the actor must `await` to call its methods or read its properties, and the
compiler rejects synchronous access from outside:

```swift
actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}

let counter = Counter()
await withTaskGroup(of: Void.self) { group in
    for _ in 0..<1_000 { group.addTask { await counter.increment() } }
}
await counter.value   // 1_000, every time
```

Inside the actor, access is synchronous. Values passed in or out must be `Sendable`, so a
non-thread-safe class cannot leak out and be changed from two places. Mark a member
`nonisolated` when it does not touch mutable state (for example a `let` that is `Sendable`, or a
computed `description`) so callers do not need `await`.

Actors do not make a sequence of calls atomic; see reentrancy in IOS-026.

**References:** [Concurrency: Actors](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) · [SE-0306: Actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md)

## IOS-026: What is actor reentrancy, and what bug does it cause?

**Level:** senior · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

While an actor method is suspended at an `await`, the actor is free to run other calls. State you
checked before the `await` may have changed by the time you resume:

```swift
actor Account {
    var balance = 100
    func withdraw(_ amount: Int) async -> Bool {
        guard balance >= amount else { return false }
        await approval()          // another withdraw can run here
        balance -= amount         // both calls subtract: balance is -60
        return true
    }
}
```

The test holds two `withdraw(80)` calls at the `await` and releases them together: both pass the
check and the balance ends at −60.

Swift chose reentrancy to avoid deadlocks and to keep actors responsive. The fixes:

- re-check the state **after** the `await` (the test's fixed version lets only one withdrawal
  through),
- do all reads and writes of one decision synchronously, with no `await` in between,
- for work that must happen once, such as a token refresh, store the in-flight `Task` in the
  actor and let later callers await that task instead of starting another.

**Reference:** [SE-0306: Actors (Actor reentrancy)](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md)

## IOS-027: What is `Sendable`, and what changes in the Swift 6 language mode?

**Level:** mid

`Sendable` marks a type whose values can be shared between concurrent code without data races:
value types whose stored properties are all `Sendable`, actors, immutable `final` classes with
`Sendable` `let` properties, and classes that protect their state internally (for example with a
`Mutex`). Closures that cross isolation boundaries must be `@Sendable` or `sending`.

The Swift 6 **language mode** turns the data-race checks from warnings into errors: passing a
non-`Sendable` value from one actor to another, or capturing mutable state in a concurrently
running closure, does not compile. The checks are smarter than "everything must be Sendable":
region-based isolation (SE-0414) lets you pass a non-`Sendable` value that is never used again
by the sender, and `sending` (SE-0430) states that in an API.

Ways to fix an error, from best to worst: make the type a value type or immutable; isolate it to
an actor (often `@MainActor`); protect its state with a `Mutex`; and only as a last resort mark it
`@unchecked Sendable` with a comment explaining why it is safe.

Migrating can be done module by module: Swift 6 compilers still build the Swift 5 language mode,
and `swiftLanguageModes` in `Package.swift` selects it per package.

**References:** [Sendable](https://developer.apple.com/documentation/swift/sendable) · [Migrating to Swift 6](https://www.swift.org/migration/documentation/migrationguide/)

## IOS-028: What is `@MainActor`, and what does default main-actor isolation change?

**Level:** mid

`@MainActor` is a global actor whose executor is the main thread. Marking a type, function or
closure `@MainActor` makes the compiler guarantee it runs there; calling it from elsewhere needs
`await`. UIKit and SwiftUI types such as `UIViewController` and `View` are main-actor isolated.

```swift
@MainActor
final class ProfileViewModel {
    var name = ""
    func load() async {
        let profile = await api.profile()   // runs off the main actor if api is nonisolated or an actor
        name = profile.name                 // back on the main actor
    }
}
```

Since Swift 6.2 a module can make `@MainActor` the **default isolation** for every declaration
that does not say otherwise (SE-0466): `.defaultIsolation(MainActor.self)` in a package's
`swiftSettings`, or the _Default Actor Isolation_ build setting, which new Xcode app projects set
to `MainActor`. App code then needs no annotations, and only the code that should run elsewhere is
marked `nonisolated` or `@concurrent`. This mode suits app targets; libraries usually keep
`nonisolated` as the default.

`DispatchQueue.main.async` still works but gives no compile-time checking; inside async code prefer
`await MainActor.run { }` or a `@MainActor` function.

**References:** [MainActor](https://developer.apple.com/documentation/swift/mainactor) · [SE-0466: Control default actor isolation inference](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md)

## IOS-029: Where does a `nonisolated async` function run, and what do `nonisolated(nonsending)` and `@concurrent` mean?

**Level:** senior

Up to Swift 6.1, a `nonisolated async` function always ran on the global concurrent executor,
away from the caller's actor. So calling a helper from `@MainActor` code moved the work off the
main actor, and any non-`Sendable` argument had to cross an isolation boundary, which caused many
Swift 6 errors.

SE-0461 (Swift 6.2) splits the two behaviours:

- `nonisolated(nonsending)` runs the async function **on the caller's actor**. Arguments stay in
  the caller's isolation, so non-`Sendable` values can be passed. With the upcoming feature
  `NonisolatedNonsendingByDefault` (part of Xcode's _Approachable Concurrency_ setting) this is
  what plain `nonisolated async` means.
- `@concurrent` always runs the function on the concurrent executor: use it for CPU-heavy work
  such as decoding a large file or resizing images, which should not run on the main actor.

```swift
nonisolated(nonsending) func validate(_ form: Form) async -> Bool { ... }  // stays on the caller
@concurrent func decodeCatalog(_ data: Data) async throws -> Catalog { ... } // leaves the caller
```

Synchronous `nonisolated` functions are unchanged: they always run where they are called.

**Reference:** [SE-0461: Run nonisolated async functions on the caller's actor by default](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md)

## IOS-030: What is an `AsyncStream`, and what does its buffering policy control?

**Level:** mid · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

`AsyncStream` adapts a callback or delegate API into an `AsyncSequence` that callers read with
`for await`. `AsyncStream.makeStream(of:bufferingPolicy:)` returns the stream and its
continuation; the producer calls `yield(_:)` and `finish()`.

Values yielded before the consumer reads them are buffered according to the policy:

- `.unbounded` (the default) keeps everything, so a fast producer and a slow consumer use
  unbounded memory.
- `.bufferingNewest(n)` keeps the latest `n`: good for state such as location or progress, where
  only the current value matters.
- `.bufferingOldest(n)` keeps the first `n` and drops later values.

```swift
let (stream, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(2))
for value in 1...5 { continuation.yield(value) }
continuation.finish()
// for await reads 4, 5
```

Set `continuation.onTermination` to stop the underlying observer when the consumer stops
iterating or its task is cancelled. An `AsyncStream` supports one consumer; for several, keep one
continuation per consumer or use an `@Observable` model.

**References:** [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream) · [SE-0388: Convenience Async[Throwing]Stream.makeStream methods](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0388-async-stream-factory.md)

## IOS-031: When would you use a `Mutex` instead of an actor?

**Level:** senior · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

`Mutex` (in the `Synchronization` module, iOS 18 and macOS 15) protects a value with a lock.
Access is **synchronous**: no `await`, no suspension, and no reentrancy, because nothing else
can run while the lock is held.

```swift
import Synchronization

final class HitCounter: Sendable {
    private let hits = Mutex(0)
    func record() { hits.withLock { $0 += 1 } }
    var count: Int { hits.withLock { $0 } }
}
```

A class with only `let` properties of `Sendable` types, here a `Mutex`, is `Sendable` without
`@unchecked`.

Choose a **Mutex** for small critical sections that must be callable from synchronous code (a
cache lookup, a counter, a registry) or from a `nonisolated` API that should not force callers to
`await`. Choose an **actor** when the protected work itself awaits, or when you want the compiler
to keep every access inside one isolation domain. Never `await` or call unknown code while
holding a lock, and keep `withLock` bodies short. For a single integer or flag, `Atomic` from the
same module avoids the lock.

**References:** [Mutex](https://developer.apple.com/documentation/synchronization/mutex) · [SE-0433: Synchronous Mutual Exclusion Lock](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0433-mutex.md)

## IOS-032: How do you call a completion-handler API from async code?

**Level:** mid · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)

Wrap it in a continuation:

```swift
func lookUp(_ query: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        geocoder.lookUp(query) { result in
            continuation.resume(with: result)
        }
    }
}
```

The rule is that a continuation must be resumed **exactly once**. Resuming twice is a crash with
the checked variant; never resuming leaves the caller suspended forever, and the checked variant
logs a warning when the continuation is released without being resumed. Use
`withUnsafeContinuation` only after measuring, because it drops those checks.

Things to handle in the wrapper: callbacks that may be called more than once (use an
`AsyncStream` instead), APIs that never call back on some error path, and cancellation, which a
continuation does not see unless you add `withTaskCancellationHandler`. Many Apple APIs already
have async versions generated from their Objective-C completion handlers, so check before writing
one.

**Reference:** [withCheckedThrowingContinuation(isolation:function:_:)](<https://developer.apple.com/documentation/swift/withcheckedthrowingcontinuation(isolation:function:_:)>)
