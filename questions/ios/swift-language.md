# Swift language

Questions on the language itself. Answers follow the Swift 6 language mode; the code in the
verified answers is compiled and run by [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift).

## IOS-001: What is the difference between a struct and a class?

**Level:** junior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

A struct is a **value type**: assigning it or passing it to a function gives the receiver its own
copy, so a change in one place never shows up in another. A class is a **reference type**: every
variable points at the same instance, and `===` tells whether two references are the same object.

Other differences that come up in interviews:

- Classes support inheritance, `deinit` and identity; structs do not.
- Struct methods that change properties must be `mutating`, and a `let` struct cannot be changed
  at all. A `let` class reference can still have its `var` properties changed.
- Structs get a memberwise initializer for free.
- Classes are managed by ARC (reference counting); a struct that only holds values needs none.

Apple's guidance is to start with a struct and use a class when you need identity, inheritance,
or shared mutable state (for example a cache or a view model observed by several views).

```swift
var a = Point(x: 0)      // struct
var b = a
b.x = 10                 // a.x is still 0

let c = Counter()        // class
let d = c
d.count = 10             // c.count is 10 as well
```

**References:** [Structures and Classes](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures/) · [Choosing Between Structures and Classes](https://developer.apple.com/documentation/swift/choosing-between-structures-and-classes)

## IOS-002: What is copy-on-write, and how do you add it to your own type?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

Copy-on-write (CoW) lets a value type share one heap buffer between copies and copy it only when
one of them is about to change. `Array`, `Dictionary`, `Set` and `String` work this way, so
passing a large array to a function is cheap until somebody mutates it.

To give a custom struct the same behaviour, keep the data in a private class and check
`isKnownUniquelyReferenced(_:)` before every write:

```swift
struct Notes {
    private final class Storage {
        var items: [String]
        init(_ items: [String]) { self.items = items }
    }
    private var storage = Storage([])

    var items: [String] { storage.items }

    mutating func append(_ item: String) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(storage.items)   // someone else shares it: copy first
        }
        storage.items.append(item)
    }
}
```

The test checks the three cases: a copy shares the buffer, the first write to a shared buffer
copies it, and a uniquely referenced buffer is changed in place. CoW is not automatic for your own
structs: a struct that holds a class reference without this check shares mutations between copies.

**References:** [isKnownUniquelyReferenced(_:)](<https://developer.apple.com/documentation/swift/isknownuniquelyreferenced(_:)-98zpp>) · [Array](https://developer.apple.com/documentation/swift/array)

## IOS-003: How do enums with associated values work, and why must a switch be exhaustive?

**Level:** junior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

Each case of an enum can carry its own payload, which makes enums a good fit for state that has
different data in each phase:

```swift
enum PaymentState {
    case idle
    case processing(progress: Double)
    case failed(code: Int, message: String)
}

switch state {
case .idle: "idle"
case .processing(let progress) where progress >= 1: "finishing"
case .processing(let progress): "processing \(Int(progress * 100))%"
case .failed(let code, _) where code == 401: "sign in again"
case .failed(_, let message): message
}
```

`switch` must cover every case, so adding a case is a compile error everywhere it is not handled
yet. That is the reason to avoid `default:` for your own enums. For enums from Apple SDKs that
can gain cases in a later OS (non-frozen enums), write `@unknown default:`; it still compiles but
warns when a known case is missing. `indirect` allows recursive cases such as a tree node.

**Reference:** [Enumerations](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/)

## IOS-004: A method is implemented in a protocol extension and in a conforming type. Which one runs?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

It depends on whether the method is a **requirement** of the protocol.

- If it is declared in the protocol, calls are dispatched through the protocol's witness table,
  so the conforming type's version runs even through an `any Greeter` value.
- If it exists **only in the extension**, it is dispatched statically: the compiler picks the
  implementation from the static type of the expression.

```swift
protocol Greeter { func greet() -> String }      // requirement
extension Greeter {
    func greet() -> String { "default greet" }
    func wave() -> String { "default wave" }      // not a requirement
}
struct Robot: Greeter {
    func greet() -> String { "Robot greet" }
    func wave() -> String { "Robot wave" }
}

let robot: any Greeter = Robot()
robot.greet()   // "Robot greet"
robot.wave()    // "default wave"
```

The fix is to add `wave()` to the protocol if conforming types are meant to customise it.

**Reference:** [Protocols: Providing Default Implementations](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/)

## IOS-005: What is the difference between `some` and `any`?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

- `some Shape` is an **opaque type**: there is exactly one concrete type, chosen by the
  implementation and hidden from the caller. The compiler knows it, so calls are statically
  dispatched and can be specialised. `func makeShape() -> some Shape` must return the same type
  on every path; `some View` in SwiftUI works this way.
- `any Shape` is an **existential**: a box that can hold any conforming type and can change type
  at run time. It costs a box (values over three words go on the heap) and dynamic dispatch, and
  some protocol features are limited through it.

```swift
let shapes: [any Shape] = [Square(side: 2), Circle(radius: 1)]   // mixed types: needs any
func totalArea(of shapes: [some Shape]) -> Double { ... }         // one type per call: generic
```

`some` in a parameter position is shorthand for a generic parameter. A good rule is to write
`some` by default and use `any` when you really store different types together. Since Swift 6,
an existential must be spelled with `any`.

**References:** [Opaque and Boxed Protocol Types](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/opaquetypes/) · [SE-0335: Introduce existential any](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0335-existential-any.md)

## IOS-006: What are associated types and primary associated types?

**Level:** senior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

An associated type is a placeholder inside a protocol that each conforming type fills in, such as
`Element` in `Collection`. It lets one protocol describe containers of any element type without
generics on the protocol itself.

A **primary associated type** (SE-0346) is listed in angle brackets after the protocol name,
`protocol Collection<Element>`, so you can constrain it with lightweight syntax:

```swift
func sum(of values: some Collection<Int>) -> Int { values.reduce(0, +) }

sum(of: [1, 2, 3])      // Array<Int>
sum(of: Set([4, 5]))    // Set<Int>
sum(of: 1...4)          // ClosedRange<Int>

let boxes: [any Collection<Int>] = [[1, 2], 3...5]   // constrained existentials (SE-0353)
```

Before this you had to write `func sum<C: Collection>(of values: C) -> Int where C.Element == Int`.
`where` clauses are still needed for constraints that are not primary associated types, such as
`C.Index == Int`.

**References:** [Generics: Associated Types](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/generics/) · [SE-0346: Lightweight same-type requirements for primary associated types](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md)

## IOS-007: What are typed throws, and when should you use them?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

Since Swift 6.0 a function can declare the one error type it throws (SE-0413):

```swift
enum ParseError: Error { case empty, notANumber(String) }

func parsePort(_ text: String) throws(ParseError) -> Int { ... }

do {
    _ = try parsePort("http")
} catch {
    // error is ParseError here, not any Error: no cast needed, and the switch is exhaustive
}
```

`throws` alone means `throws(any Error)`, and a non-throwing function is `throws(Never)`.

Use typed throws when the set of errors is closed and part of the contract: inside a module, for
parsing and validation, or in generic code that should pass its closure's error through
unchanged (`rethrows` cannot express that). Keep untyped `throws` for most public APIs: a typed
error is a promise that adding a new failure, such as a network error, is a breaking change.

**Reference:** [SE-0413: Typed throws](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0413-typed-throws.md)

## IOS-008: What is a noncopyable type (`~Copyable`), and what problem does it solve?

**Level:** senior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

`struct FileToken: ~Copyable` is a value type that cannot be copied, so there is always exactly
one owner. The compiler enforces it: passing the value either **borrows** it (read-only, the
default for parameters) or **consumes** it, after which the old variable cannot be used.

That models unique resources, such as a file descriptor, a lock or a one-time payment token,
without a class and reference counting:

```swift
struct FileToken: ~Copyable {
    let descriptor: Int32

    consuming func close() {
        // ... close(descriptor)
        discard self        // ownership ends here; deinit does not run
    }

    deinit { /* close the descriptor if close() was never called */ }
}
```

Unlike other structs, a noncopyable struct can have a `deinit`. `discard self` ends the value
without running it; today it requires that the type's stored properties are trivially destroyed
(plain values, no class references). The standard library uses noncopyable types for `Mutex`
and `Atomic`, and `Optional` and `Result` accept noncopyable payloads since Swift 6.0.

**References:** [SE-0390: Noncopyable structs and enums](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md) · [SE-0427: Noncopyable generics](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0427-noncopyable-generics.md)

## IOS-009: How does a property wrapper work, and what is its projected value?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

A property wrapper is a type marked `@propertyWrapper` with a `wrappedValue`. Writing
`@Clamped(0...100) var volume = 50` makes the compiler store a `Clamped` instance and route reads
and writes of `volume` through its `wrappedValue`, so the clamping logic is written once.

```swift
@propertyWrapper
struct Clamped {
    private var value: Int
    let range: ClosedRange<Int>
    init(wrappedValue: Int, _ range: ClosedRange<Int>) { ... }
    var wrappedValue: Int {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
    var projectedValue: ClosedRange<Int> { range }
}

settings.volume = 150   // stored as 100
settings.$volume        // the projected value: 0...100
```

`$name` reads the `projectedValue`; SwiftUI uses it to hand out a `Binding` from `@State` and
`@Binding`. Wrappers cannot be used on computed properties, and a wrapper that holds mutable
state in a class is shared between copies of the enclosing struct, which can surprise.

**Reference:** [Properties: Property Wrappers](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/)

## IOS-010: What is a result builder?

**Level:** senior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

A result builder is a type marked `@resultBuilder` whose static methods tell the compiler how to
combine the statements of a closure into one value. SwiftUI's `@ViewBuilder` is the best-known
one; the same mechanism builds regex components and HTML or attributed-string DSLs.

The compiler rewrites the closure into calls to the builder:

- `buildBlock(_:)` combines the statements,
- `buildExpression(_:)` converts each expression,
- `buildOptional(_:)` handles `if` without `else`,
- `buildEither(first:)` and `buildEither(second:)` handle `if`/`else` and `switch`,
- `buildArray(_:)` handles `for` loops.

```swift
let lines = makeLines {
    "Header"
    for index in 1...2 { "Item \(index)" }
    if showFooter { "Footer" }
}
// ["Header", "Item 1", "Item 2"] when showFooter is false
```

A statement the builder has no method for, such as `for` without `buildArray`, is a compile error,
which is why some loops need `ForEach` in SwiftUI.

**Reference:** [Advanced Operators: Result Builders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/)

## IOS-011: Why can't you index a Swift `String` with an `Int`?

**Level:** junior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

A `String` is a collection of `Character`s, and a `Character` is an extended grapheme cluster:
what a reader sees as one character can be several Unicode scalars and a variable number of
bytes. Finding the n-th character therefore means walking from the start, which is O(n), so
Swift does not hide that cost behind an integer subscript. You move with `String.Index`:

```swift
let word = "Swift"
let third = word[word.index(word.startIndex, offsetBy: 2)]   // "i"

let flag = "🇹🇷"
flag.count                 // 1 character
flag.unicodeScalars.count  // 2 scalars (regional indicators)
flag.utf16.count           // 4 (what NSString.length reports)
flag.utf8.count            // 8 bytes
```

Strings compare by canonical equivalence, so `"café"` written with `é` and with `e` plus a
combining accent are equal and have the same `count`, but different UTF-8 lengths. When an API
needs an offset (for example `NSRange` for UIKit text), convert with `NSRange(_:in:)` instead of
mixing `count` and `utf16.count`.

**Reference:** [Strings and Characters](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/stringsandcharacters/)

## IOS-012: How do you convert a `Double` to an `Int` without crashing?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

`Int(someDouble)` truncates toward zero, and it **traps** (crashes) when the value is NaN,
infinite or outside `Int`'s range. Values that come from JSON, sensors, sliders or arithmetic
like `0 / 0` can be any of these. Use the failable initialisers:

```swift
Int(exactly: 42.0)          // 42
Int(exactly: 3.5)           // nil: not a whole number
Int(exactly: Double.nan)    // nil, where Int(Double.nan) traps
Int(exactly: huge)          // nil for huge = 1e300, where Int(huge) traps

Int(3.9)                    // 3: truncates
Int(exactly: value.rounded())       // round first if that is what you mean
```

With a literal such as `Int(1e300)` the compiler reports the overflow at build time; the trap
happens with values only known at run time. Integer arithmetic also traps on overflow in Swift. When overflow is expected, choose the
behaviour: `&+` wraps, `addingReportingOverflow(_:)` reports it, `Int8(clamping: 300)` gives 127,
and `Int8(exactly: 300)` gives `nil`. A typical review comment is a progress value turned into a
percentage with `Int(progress * 100)` where `progress` came from `bytesSent / totalBytes` and
`totalBytes` can be zero.

**Reference:** [Int.init(exactly:)](<https://developer.apple.com/documentation/swift/int/init(exactly:)-77kq8>)

## IOS-013: What is the difference between a `lazy var` and a lazy sequence?

**Level:** junior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

- A `lazy var` property runs its initializer the first time it is read, once, and stores the
  result. It is useful for expensive objects that may never be needed and for initializers that
  use `self`. It must be a `var`, and it is not thread-safe: two threads reading it for the first
  time at once can both run the initializer.
- `.lazy` on a sequence returns a view whose `map`, `filter` and so on run per element when the
  element is requested, instead of building a new array at every step:

```swift
var calls = 0
let doubled = (1...1_000).lazy.map { value -> Int in calls += 1; return value * 2 }
doubled.first(where: { $0 > 10 })   // 12, and calls == 6
```

The lazy chain runs the closure again every time you iterate it, so call `Array(_:)` on it when
you need the results more than once.

**References:** [Properties: Lazy Stored Properties](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/) · [LazySequence](https://developer.apple.com/documentation/swift/lazysequence)

## IOS-014: How do you decode JSON whose keys differ from your property names, or where a field may be missing?

**Level:** junior · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

Declare a `CodingKeys` enum to map names, and write `init(from:)` only for the fields that need
special handling:

```swift
struct User: Codable {
    var id: Int
    var displayName: String
    var isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case isAdmin = "is_admin"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
    }
}
```

For APIs that use snake_case everywhere, `decoder.keyDecodingStrategy = .convertFromSnakeCase` is
shorter than `CodingKeys`. A property declared optional decodes a missing key as `nil`, but a
non-optional property with a default value is still required by the synthesized decoder, which
is why `decodeIfPresent` is needed for defaults. A wrong type (`"id": "3"`) throws
`DecodingError.typeMismatch`; log the error's `codingPath` to see which field failed.

**Reference:** [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)

## IOS-015: What do `private`, `fileprivate`, `internal`, `package`, `public` and `open` mean?

**Level:** junior

From the narrowest to the widest:

| Level                | Visible in                                                                     |
| -------------------- | ------------------------------------------------------------------------------ |
| `private`            | The enclosing declaration and its extensions in the same file                  |
| `fileprivate`        | The whole source file                                                          |
| `internal` (default) | The whole module                                                               |
| `package`            | Every module in the same Swift package (Swift 5.9, SE-0386)                    |
| `public`             | Other modules, which can use but not subclass or override                      |
| `open`               | Other modules, which can also subclass and override (classes and members only) |

Interview follow-ups: `internal` is the default, so a framework only exposes what is marked
`public`; `package` replaces many `@_spi` and "make it public but don't use it" workarounds in
multi-module apps; `@testable import` lets tests see `internal` symbols; `private(set)` makes the
setter narrower than the getter.

**References:** [Access Control](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/) · [SE-0386: New access modifier: package](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0386-package-access-modifier.md)
