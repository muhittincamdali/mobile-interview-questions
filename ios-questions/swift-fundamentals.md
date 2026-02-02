# Swift Language Fundamentals - Deep Dive

A comprehensive deep dive into Swift language fundamentals commonly asked in iOS interviews.

---

## Value Types vs Reference Types

### Q: What is the difference between a struct and a class in Swift?

**Difficulty:** 🟢 Junior

Structs are value types; classes are reference types. When you assign a struct to a new variable or pass it to a function, a copy is made. Classes share the same reference.

Key differences:

| Feature | Struct | Class |
|---------|--------|-------|
| Type | Value | Reference |
| Inheritance | No | Yes |
| Deinitializer | No | Yes |
| Reference counting | No | Yes |
| Mutability control | `mutating` keyword | Direct mutation |

```swift
struct Point {
    var x: Double
    var y: Double
}

var a = Point(x: 1, y: 2)
var b = a        // copy
b.x = 10
print(a.x)      // 1 — unchanged

class Node {
    var value: Int
    init(value: Int) { self.value = value }
}

let n1 = Node(value: 5)
let n2 = n1      // shared reference
n2.value = 99
print(n1.value)  // 99
```

---

### Q: Explain Copy-on-Write (CoW) in Swift.

**Difficulty:** 🟡 Mid

Swift standard library collections (Array, Dictionary, Set) use copy-on-write optimization. The actual copy is deferred until a mutation occurs, and only if there is more than one reference to the underlying buffer.

```swift
var arr1 = [1, 2, 3]
var arr2 = arr1          // no copy yet, shared buffer

arr2.append(4)           // now the buffer is copied

// You can implement CoW for custom types:
final class Storage<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

struct CowWrapper<T> {
    private var storage: Storage<T>

    init(_ value: T) {
        storage = Storage(value)
    }

    var value: T {
        get { storage.value }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = Storage(newValue)
            } else {
                storage.value = newValue
            }
        }
    }
}
```

---

### Q: What are enums with associated values? Give a practical example.

**Difficulty:** 🟢 Junior

Enums in Swift can carry associated data of any type per case, making them algebraic data types.

```swift
enum NetworkResult {
    case success(data: Data, statusCode: Int)
    case failure(error: Error)
    case loading(progress: Double)
}

func handle(_ result: NetworkResult) {
    switch result {
    case .success(let data, let code):
        print("Got \(data.count) bytes, status \(code)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    case .loading(let progress):
        print("Loading: \(Int(progress * 100))%")
    }
}
```

---

### Q: Explain the difference between `Any`, `AnyObject`, and `AnyHashable`.

**Difficulty:** 🟡 Mid

- `Any` can represent an instance of any type, including functions and value types.
- `AnyObject` can represent an instance of any class type (reference types only).
- `AnyHashable` is a type-erased hashable value, useful as dictionary keys.

```swift
var anyArray: [Any] = [1, "hello", 3.14, { print("closure") }]

var objectArray: [AnyObject] = [NSString("test"), NSNumber(42)]

var hashDict: [AnyHashable: String] = [
    1: "one",
    "key": "value"
]
```

---

### Q: What is a metatype in Swift? Explain `.self` and `.Type`.

**Difficulty:** 🔴 Senior

A metatype is the type of a type. `T.Type` is the metatype of `T`. You get the metatype value using `T.self`.

```swift
struct Dog {
    var name: String
    static func species() -> String { "Canis familiaris" }
}

let dogType: Dog.Type = Dog.self
print(dogType.species())

// Useful for generic factory patterns:
protocol Decodable {
    init(from data: Data) throws
}

func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try T(from: data)
}
```

---

## Optionals

### Q: How does optional chaining differ from forced unwrapping?

**Difficulty:** 🟢 Junior

Optional chaining (`?.`) safely accesses properties/methods on an optional, returning `nil` if any link in the chain is `nil`. Forced unwrapping (`!`) crashes if the value is `nil`.

```swift
struct Address {
    var city: String?
}

struct Person {
    var address: Address?
}

let person: Person? = Person(address: Address(city: "Istanbul"))

// Optional chaining — safe
let city = person?.address?.city   // Optional("Istanbul")

// Forced unwrapping — crashes if nil
let city2 = person!.address!.city! // "Istanbul" or crash
```

---

### Q: What is the `nil` coalescing operator and how does it short-circuit?

**Difficulty:** 🟢 Junior

The `??` operator returns the left-hand value if non-nil, otherwise the right-hand default. It short-circuits — the default expression is only evaluated if needed.

```swift
let name: String? = nil
let display = name ?? "Anonymous"   // "Anonymous"

// Short-circuit demonstration:
func expensiveDefault() -> String {
    print("Computing...")
    return "Fallback"
}

let value: String? = "Exists"
let result = value ?? expensiveDefault()  // "Computing..." never prints
```

---

### Q: Explain `Optional` under the hood. What is it really?

**Difficulty:** 🟡 Mid

`Optional<Wrapped>` is an enum with two cases:

```swift
// Simplified version of Swift's Optional
enum Optional<Wrapped> {
    case none
    case some(Wrapped)
}

// So String? is syntactic sugar for Optional<String>
let greeting: Optional<String> = .some("Hello")

// Pattern matching works:
switch greeting {
case .some(let value):
    print(value)
case .none:
    print("nil")
}

// if-let is syntactic sugar for pattern matching .some
if case .some(let value) = greeting {
    print(value)
}
```

---

## Protocols and Generics

### Q: What is a protocol with associated type (PAT)?

**Difficulty:** 🟡 Mid

A protocol can declare an associated type as a placeholder for a type that conforming types must specify.

```swift
protocol Container {
    associatedtype Element
    var count: Int { get }
    mutating func append(_ item: Element)
    subscript(i: Int) -> Element { get }
}

struct IntStack: Container {
    typealias Element = Int   // can be inferred
    private var items: [Int] = []
    var count: Int { items.count }
    mutating func append(_ item: Int) { items.append(item) }
    subscript(i: Int) -> Int { items[i] }
}
```

---

### Q: What are opaque return types (`some`) and how do they differ from `any`?

**Difficulty:** 🔴 Senior

`some Protocol` (opaque type) hides the concrete type but guarantees it is always the same type. `any Protocol` (existential type) can hold any conforming type at runtime.

```swift
// Opaque — caller doesn't know the concrete type, but it's always the same
func makeCollection() -> some Collection {
    [1, 2, 3]  // always returns Array<Int>
}

// Existential — can hold different conforming types
func randomShape() -> any Shape {
    if Bool.random() {
        return Circle(radius: 5)
    } else {
        return Square(side: 4)
    }
}

// Key difference: opaque types preserve type identity
let c1 = makeCollection()
let c2 = makeCollection()
// c1 and c2 are guaranteed same type — you can compare them if Equatable
```

---

### Q: Explain type erasure in Swift. When would you use it?

**Difficulty:** 🔴 Senior

Type erasure hides a specific generic type behind a wrapper, letting you use protocols with associated types in collections or as property types.

```swift
// The problem: can't use PAT directly
// let publishers: [Publisher] — error!

// Solution: type-erased wrapper
struct AnyPublisher<Output, Failure: Error> {
    private let _receive: (Output) -> Void

    init<P: Publisher>(_ publisher: P)
    where P.Output == Output, P.Failure == Failure {
        _receive = { publisher.send($0) }
    }
}

// Modern Swift (5.7+) alternative: primary associated types
protocol Collection<Element> {
    associatedtype Element
}

// Now you can write:
func process(_ items: any Collection<Int>) { }
```

---

### Q: What are phantom types and when are they useful?

**Difficulty:** 🔴 Senior

Phantom types are generic type parameters that appear in the type signature but are never used in the stored data. They provide compile-time safety.

```swift
enum Validated {}
enum Unvalidated {}

struct Email<State> {
    let rawValue: String
}

func validate(_ email: Email<Unvalidated>) -> Email<Validated>? {
    guard email.rawValue.contains("@") else { return nil }
    return Email<Validated>(rawValue: email.rawValue)
}

func send(to email: Email<Validated>) {
    // Only accepts validated emails — compile-time guarantee
    print("Sending to \(email.rawValue)")
}

let raw = Email<Unvalidated>(rawValue: "test@example.com")
// send(to: raw)  // Compile error!
if let valid = validate(raw) {
    send(to: valid)  // OK
}
```

---

## Closures

### Q: What is a closure capture list and when do you use `[weak self]`?

**Difficulty:** 🟡 Mid

A capture list defines how values are captured in a closure. `[weak self]` prevents retain cycles when a closure is stored by the object that owns it.

```swift
class ViewModel {
    var data: [String] = []
    var onUpdate: (() -> Void)?

    func fetchData() {
        // Without [weak self] — retain cycle!
        // self -> onUpdate -> closure -> self
        networkService.fetch { [weak self] result in
            guard let self else { return }
            self.data = result
            self.onUpdate?()
        }
    }

    deinit {
        print("ViewModel deallocated")
    }
}
```

---

### Q: Explain `@escaping` vs non-escaping closures.

**Difficulty:** 🟡 Mid

A non-escaping closure is guaranteed to be called before the function returns. An `@escaping` closure can outlive the function, typically stored or called asynchronously.

```swift
// Non-escaping (default)
func apply(_ transform: (Int) -> Int, to value: Int) -> Int {
    transform(value)
}

// Escaping — stored for later
class Scheduler {
    private var tasks: [() -> Void] = []

    func schedule(_ task: @escaping () -> Void) {
        tasks.append(task)
    }

    func runAll() {
        tasks.forEach { $0() }
        tasks.removeAll()
    }
}
```

Non-escaping closures don't require `self.` inside classes and can capture values without worrying about reference cycles.

---

### Q: What is the difference between `@autoclosure` and a regular closure?

**Difficulty:** 🟡 Mid

`@autoclosure` automatically wraps an expression into a closure, providing a cleaner call site. The expression is lazily evaluated.

```swift
func log(_ message: @autoclosure () -> String, level: Int) {
    guard level >= 3 else { return }
    print(message())   // Only evaluated if level >= 3
}

// Call site is clean — no braces needed
log("User count: \(users.count)", level: 2)
// users.count is never evaluated because level < 3

// Swift uses this in assert():
// assert(expensive() == true)  // only runs in debug
```

---

## Error Handling

### Q: Compare `throws`, `Result`, and `async throws`.

**Difficulty:** 🟡 Mid

```swift
// 1. throws — synchronous, propagating
func parse(_ json: Data) throws -> Model {
    guard let model = try? JSONDecoder().decode(Model.self, from: json) else {
        throw ParseError.invalidFormat
    }
    return model
}

// 2. Result — callback-based, explicit success/failure
func fetch(completion: @escaping (Result<Data, NetworkError>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error {
            completion(.failure(.requestFailed(error)))
        } else if let data {
            completion(.success(data))
        }
    }.resume()
}

// 3. async throws — modern async, structured
func fetchUser() async throws -> User {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw NetworkError.badStatus
    }
    return try JSONDecoder().decode(User.self, from: data)
}
```

---

### Q: What are typed throws in Swift 6?

**Difficulty:** 🔴 Senior

Swift 6 introduces typed throws, letting you specify the exact error type a function can throw.

```swift
enum ValidationError: Error {
    case tooShort
    case invalidCharacters
}

func validate(password: String) throws(ValidationError) {
    guard password.count >= 8 else {
        throw .tooShort
    }
    guard password.rangeOfCharacter(from: .alphanumerics) != nil else {
        throw .invalidCharacters
    }
}

// Caller knows exact error type — no casting needed
do {
    try validate(password: "abc")
} catch .tooShort {
    print("Password too short")
} catch .invalidCharacters {
    print("Invalid characters")
}
```

---

## Property Wrappers

### Q: Explain property wrappers with a practical example.

**Difficulty:** 🟡 Mid

Property wrappers encapsulate property access patterns into reusable components.

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>

    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    var projectedValue: ClosedRange<Value> { range }

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

struct AudioPlayer {
    @Clamped(0...100) var volume: Int = 50

    func info() {
        print("Volume: \(volume)")
        print("Range: \($volume)")  // projected value: 0...100
    }
}

var player = AudioPlayer()
player.volume = 150
print(player.volume)  // 100 — clamped
```

---

## Key Paths

### Q: What are key paths in Swift and how are they used?

**Difficulty:** 🟡 Mid

Key paths are references to properties that can be passed around as values.

```swift
struct Employee {
    var name: String
    var salary: Double
    var department: String
}

let employees = [
    Employee(name: "Alice", salary: 95000, department: "Engineering"),
    Employee(name: "Bob", salary: 85000, department: "Design"),
    Employee(name: "Carol", salary: 105000, department: "Engineering"),
]

// Using key paths with standard library
let names = employees.map(\.name)
let sorted = employees.sorted(by: \.salary)
let totalSalary = employees.reduce(0) { $0 + $1[keyPath: \.salary] }

// Key paths as function parameters
func extract<T, V>(_ keyPath: KeyPath<T, V>, from items: [T]) -> [V] {
    items.map { $0[keyPath: keyPath] }
}

let departments = extract(\.department, from: employees)
```

---

## Result Builders

### Q: How do result builders work? Write a simple one.

**Difficulty:** 🔴 Senior

Result builders transform a series of statements into a single value using compile-time transformations.

```swift
@resultBuilder
struct ArrayBuilder<Element> {
    static func buildBlock(_ components: Element...) -> [Element] {
        components
    }

    static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }

    static func buildEither(first component: [Element]) -> [Element] {
        component
    }

    static func buildEither(second component: [Element]) -> [Element] {
        component
    }

    static func buildArray(_ components: [[Element]]) -> [Element] {
        components.flatMap { $0 }
    }
}

func buildMenu(@ArrayBuilder<String> content: () -> [String]) -> [String] {
    content()
}

let menu = buildMenu {
    "Home"
    "Profile"
    if isAdmin {
        "Admin Panel"
    }
    for item in extraItems {
        item
    }
}
```

SwiftUI's `@ViewBuilder` is the most well-known result builder in practice.

---

## String Internals

### Q: Why is `String.count` O(n) in Swift?

**Difficulty:** 🔴 Senior

Swift strings are collections of `Character` values (extended grapheme clusters), not fixed-width code units. A single `Character` can span multiple Unicode scalars, so you must walk the string to count characters.

```swift
let emoji = "👨‍👩‍👧‍👦"
print(emoji.count)                    // 1 (one grapheme cluster)
print(emoji.unicodeScalars.count)     // 7
print(emoji.utf8.count)              // 25
print(emoji.utf16.count)             // 11

// This is why String uses opaque indexing:
let str = "Hello 🌍"
let idx = str.index(str.startIndex, offsetBy: 6)
print(str[idx])  // 🌍

// O(n) implications:
// str.count       — O(n)
// str[str.startIndex]  — O(1)
// str.prefix(k)   — O(k)
```

For performance-critical code working with ASCII, consider using `UTF8View` directly.
