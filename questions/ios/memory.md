# Memory management

ARC, reference cycles and finding leaks. The verified answers run in
[MemoryTests](../../Tests/AnswerTests/MemoryTests.swift).

## IOS-016: How does ARC work, and how is it different from garbage collection?

**Level:** junior

Automatic Reference Counting keeps a count of strong references to each class instance. The
compiler inserts the retain and release calls; when the count reaches zero the instance is freed
immediately and its `deinit` runs.

Compared with a tracing garbage collector (the JVM, Dart, JavaScript engines):

- Freeing is **deterministic**: it happens at the last release, not at a collection pause, so
  `deinit` is a reliable place to stop timers or close files.
- There are no collection pauses, but every retain and release is an atomic operation, which has
  a cost in hot code.
- ARC **cannot free cycles**. Two objects that hold each other strongly keep their counts above
  zero forever; a tracing collector would find them unreachable. Breaking cycles with `weak` or
  `unowned` is the developer's job.

ARC applies to class instances and closures. Structs and enums are values; they are only
reference counted indirectly when they contain class references or copy-on-write buffers.

**Reference:** [Automatic Reference Counting](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)

## IOS-017: When do you use `weak` and when `unowned`?

**Level:** mid · **Verified by:** [MemoryTests](../../Tests/AnswerTests/MemoryTests.swift)

Both are references that do not keep the object alive. The difference is what happens after the
object is freed:

- `weak` must be an optional and becomes `nil` automatically. Use it when the other object can go
  away first: delegates, a child pointing at its parent view controller, `[weak self]` in a
  closure that may outlive `self`.
- `unowned` is non-optional and assumes the object is still there. Reading it after the object
  is freed **traps**. Use it only when the referenced object always outlives the reference, for
  example a `CreditCard` that cannot exist without its `Customer`.

```swift
final class Pet {
    weak var weakOwner: Owner?       // nil once the owner is freed
    unowned let unownedOwner: Owner  // must never be read after that
}
```

`unowned(unsafe)` skips the runtime check entirely (like `__unsafe_unretained` in Objective-C);
it is only for measured hot paths. If in doubt, choose `weak`: a `nil` is easier to debug than a
crash.

**Reference:** [Automatic Reference Counting: Resolving Strong Reference Cycles](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)

## IOS-018: How does a closure create a retain cycle, and how do you break it?

**Level:** mid · **Verified by:** [MemoryTests](../../Tests/AnswerTests/MemoryTests.swift)

A closure captures the variables it uses strongly. If an object stores a closure that uses
`self`, the object holds the closure and the closure holds the object, and neither is freed:

```swift
final class Downloader {
    var onFinish: (() -> Void)?
    func start() {
        onFinish = { self.finished = true }               // self → closure → self: leak
        onFinish = { [weak self] in self?.finished = true } // no cycle
    }
}
```

The test shows the strong version staying alive after the last outside reference is gone, and the
`[weak self]` version being freed.

Not every closure that mentions `self` leaks: a closure that is not stored (`map`, `UIView.animate`,
most `Task {}` bodies) is released when it finishes. A long-running `Task` that loops while
capturing `self` does keep it alive until the loop ends, so such loops should capture `self`
weakly or be cancelled in `deinit` or `onDisappear`. Inside a `[weak self]` closure, `guard let
self else { return }` gives a strong reference for the rest of that call only.

**Reference:** [Automatic Reference Counting: Strong Reference Cycles for Closures](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)

## IOS-019: What does a capture list like `[count]` do to a value type?

**Level:** mid · **Verified by:** [MemoryTests](../../Tests/AnswerTests/MemoryTests.swift)

Without a capture list, a closure captures the **variable**, so it sees changes made after the
closure was created. A capture list evaluates the expression **when the closure is created** and
stores that value:

```swift
var count = 1
let byReference = { count }
let byValue = { [count] in count }
count = 2
byReference()   // 2
byValue()       // 1
```

This matters for closures that run later, such as a completion handler that should report the
state at the moment the request started, and it is the same mechanism as `[weak self]`, which
evaluates `self` once and stores a weak reference to it.

**Reference:** [Closures: Capturing Values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/)

## IOS-020: How do you find memory leaks in an iOS app?

**Level:** mid

1. **Memory Graph Debugger** (Debug Memory Graph in Xcode's debug bar): pause the app after
   leaving a screen and look for instances that should be gone. Purple warnings mark detected
   cycles, and the graph shows who holds each object.
2. **Instruments**: the _Leaks_ instrument finds unreachable cycles; _Allocations_ with
   generation marks ("Mark Generation" before and after opening and closing a screen) finds
   objects that are still reachable but should not be, which Leaks does not report.
3. **Tests**: assert that an object is freed, for example by holding it in a `weak` variable,
   dropping the last strong reference and expecting `nil`, as the memory tests in this repository
   do.
4. **Malloc Stack Logging** in the scheme's diagnostics shows where a leaked object was
   allocated.

Common causes: closures stored on `self`, delegates declared strong, timers (`Timer` retains its
target), `NotificationCenter` block observers that capture `self`, and never-ending `Task` loops.

**References:** [Gathering information about memory use](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use) · [Diagnosing memory, thread, and crash issues early](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)

## IOS-021: Is `autoreleasepool` still useful in Swift?

**Level:** senior

Swift objects are not autoreleased, but many Objective-C framework APIs return autoreleased
objects (for example `UIImage(contentsOfFile:)`, `NSString` bridging, some Core Graphics and
Foundation calls). Those objects live until the current autorelease pool drains, which on the main
thread is the end of the run loop iteration.

In a tight loop that processes many such objects, memory therefore climbs until the loop ends.
Wrapping the body in a pool keeps the peak low:

```swift
for url in imageURLs {
    autoreleasepool {
        let image = UIImage(contentsOfFile: url.path)
        thumbnails.append(makeThumbnail(image))
    }
}
```

Measure with the Allocations instrument before adding pools: if the loop's peak memory does not
grow with the number of iterations, the pool does nothing. GCD queues and Swift concurrency
threads manage their own pools per work item.

**Reference:** [autoreleasepool(invoking:)](<https://developer.apple.com/documentation/objectivec/autoreleasepool(invoking:)>)
