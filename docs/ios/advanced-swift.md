# Advanced Swift Interview Questions

Deep dive into Swift's advanced features commonly asked in senior iOS interviews.

---

## Table of Contents

1. [Memory Management](#memory-management)
2. [Generics & Type System](#generics--type-system)
3. [Protocol-Oriented Programming](#protocol-oriented-programming)
4. [Concurrency Deep Dive](#concurrency-deep-dive)
5. [Performance Optimization](#performance-optimization)
6. [Metaprogramming](#metaprogramming)
7. [Swift Internals](#swift-internals)

---

## Memory Management

### Q1: Explain Swift's ARC in detail. How does it differ from garbage collection?

**Answer:**

ARC (Automatic Reference Counting) is a compile-time memory management system. Unlike garbage collection, ARC:

1. **Deterministic deallocation** - Objects are deallocated immediately when reference count hits zero
2. **No runtime overhead** - Reference counting instructions inserted at compile time
3. **No pause times** - No "stop the world" garbage collection pauses
4. **Predictable performance** - Memory freed as soon as possible

```swift
class Node {
    var value: Int
    var next: Node?
    
    init(value: Int) {
        self.value = value
        print("Node \(value) initialized")
    }
    
    deinit {
        print("Node \(value) deinitialized")
    }
}

func createLinkedList() {
    let node1 = Node(value: 1)  // refcount = 1
    let node2 = Node(value: 2)  // refcount = 1
    node1.next = node2          // node2 refcount = 2
    // Function ends: node1 refcount -> 0, deallocated
    // node2 refcount -> 1 (from node1.next) -> 0, deallocated
}
```

**Retain cycle example and solution:**

```swift
class Person {
    let name: String
    var apartment: Apartment?
    
    init(name: String) { self.name = name }
    deinit { print("\(name) is being deinitialized") }
}

class Apartment {
    let unit: String
    weak var tenant: Person?  // weak breaks the cycle
    
    init(unit: String) { self.unit = unit }
    deinit { print("Apartment \(unit) is being deinitialized") }
}
```

---

### Q2: What's the difference between weak, unowned, and unowned(unsafe)?

**Answer:**

| Modifier | Optional | Zeroing | Use Case |
|----------|----------|---------|----------|
| `weak` | Yes | Yes | Reference might become nil |
| `unowned` | No | Crashes if nil | Lifetime >= referencing object |
| `unowned(unsafe)` | No | Undefined behavior | Performance critical, guaranteed lifetime |

```swift
class Customer {
    let name: String
    var card: CreditCard?
    
    init(name: String) { self.name = name }
}

class CreditCard {
    let number: UInt64
    unowned let customer: Customer  // Card can't exist without customer
    
    init(number: UInt64, customer: Customer) {
        self.number = number
        self.customer = customer
    }
}

// Usage
let john = Customer(name: "John")
john.card = CreditCard(number: 1234_5678_9012_3456, customer: john)
// No retain cycle: Customer -> strong -> CreditCard -> unowned -> Customer
```

**When to use unowned(unsafe):**

```swift
// Only when you're 100% certain about lifetime and need performance
class FastCache {
    unowned(unsafe) var delegate: CacheDelegate
    
    init(delegate: CacheDelegate) {
        self.delegate = delegate
    }
}
```

---

### Q3: Explain closure capture lists and memory implications

**Answer:**

Closures capture values from surrounding context. Without capture lists, strong references are created by default.

```swift
class DataLoader {
    var onComplete: (() -> Void)?
    var data: [String] = []
    
    func loadData() {
        // MEMORY LEAK: self strongly captured
        onComplete = {
            print(self.data.count)
        }
        
        // SOLUTION 1: weak self
        onComplete = { [weak self] in
            guard let self = self else { return }
            print(self.data.count)
        }
        
        // SOLUTION 2: unowned self (if closure lifetime <= self)
        onComplete = { [unowned self] in
            print(self.data.count)
        }
    }
}
```

**Capture list semantics:**

```swift
var x = 10
var y = 20

let closure = { [x, y] in  // Captures VALUE at creation time
    print(x, y)  // Prints: 10, 20
}

x = 100
y = 200
closure()  // Still prints: 10, 20

let closureRef = { [x, y] () -> Void in
    // x and y are immutable here
}
```

**Capturing reference types:**

```swift
class Counter {
    var count = 0
}

let counter = Counter()
let increment = { [counter] in  // Captures reference, not value
    counter.count += 1
}

increment()
print(counter.count)  // 1
```

---

### Q4: How does Swift handle copy-on-write (CoW)?

**Answer:**

Copy-on-write is an optimization for value types that delays copying until mutation occurs.

```swift
var array1 = [1, 2, 3, 4, 5]
var array2 = array1  // No copy yet, both point to same buffer

// Check if they share storage
print(array1.withUnsafeBufferPointer { $0.baseAddress! })
print(array2.withUnsafeBufferPointer { $0.baseAddress! })
// Same address!

array2.append(6)  // NOW copy happens
// Different addresses after mutation
```

**Implementing CoW for custom types:**

```swift
final class DataBuffer {
    var storage: [Int]
    
    init(_ storage: [Int]) {
        self.storage = storage
    }
    
    func copy() -> DataBuffer {
        return DataBuffer(storage)
    }
}

struct OptimizedData {
    private var buffer: DataBuffer
    
    init(_ data: [Int]) {
        buffer = DataBuffer(data)
    }
    
    var data: [Int] {
        get { buffer.storage }
        set {
            if !isKnownUniquelyReferenced(&buffer) {
                buffer = buffer.copy()
            }
            buffer.storage = newValue
        }
    }
    
    mutating func append(_ value: Int) {
        if !isKnownUniquelyReferenced(&buffer) {
            buffer = buffer.copy()
        }
        buffer.storage.append(value)
    }
}
```

---

## Generics & Type System

### Q5: Explain associated types vs generic type parameters

**Answer:**

```swift
// Generic Type Parameter - caller specifies type
protocol GenericContainer<T> {
    func add(_ item: T)
    func get() -> T?
}

// Associated Type - implementer specifies type
protocol AssociatedContainer {
    associatedtype Item
    func add(_ item: Item)
    func get() -> Item?
}

// Associated type with constraints
protocol ComparableContainer {
    associatedtype Item: Comparable
    var items: [Item] { get }
    func sorted() -> [Item]
}

struct NumberContainer: ComparableContainer {
    typealias Item = Int  // Explicit
    var items: [Int] = []
    
    func sorted() -> [Int] {
        items.sorted()
    }
}

struct StringContainer: ComparableContainer {
    var items: [String] = []  // Item inferred as String
    
    func sorted() -> [String] {
        items.sorted()
    }
}
```

**Type erasure for protocols with associated types:**

```swift
protocol DataFetcher {
    associatedtype DataType
    func fetch() async -> DataType
}

// Can't use: var fetcher: DataFetcher (protocol has associated type)

// Type erasure solution
struct AnyDataFetcher<T>: DataFetcher {
    private let _fetch: () async -> T
    
    init<F: DataFetcher>(_ fetcher: F) where F.DataType == T {
        _fetch = fetcher.fetch
    }
    
    func fetch() async -> T {
        await _fetch()
    }
}

// Or use Swift 5.7+ any keyword
var fetcher: any DataFetcher
```

---

### Q6: What are opaque types and how do they differ from protocols?

**Answer:**

Opaque types (`some Protocol`) hide the concrete type while preserving type identity.

```swift
// Protocol return type - loses type information
func makeCollection() -> any Collection<Int> {
    return [1, 2, 3]
}

// Opaque type - preserves type identity
func makeOpaqueCollection() -> some Collection<Int> {
    return [1, 2, 3]
}

// Difference in usage
let c1 = makeCollection()
let c2 = makeCollection()
// c1 == c2  // Error: can't compare 'any Collection'

let o1 = makeOpaqueCollection()
let o2 = makeOpaqueCollection()
// o1 == o2  // Works if underlying type is Equatable
```

**SwiftUI example:**

```swift
struct ContentView: View {
    // 'some View' allows compiler to know exact type
    // while hiding it from external code
    var body: some View {
        VStack {
            Text("Hello")
            Text("World")
        }
    }
    // Actual type: VStack<TupleView<(Text, Text)>>
}
```

**Primary associated types (Swift 5.7+):**

```swift
protocol Repository<Model> {
    associatedtype Model
    func save(_ model: Model)
    func fetch(id: String) -> Model?
}

// Can now use with some/any
func getRepository() -> some Repository<User> {
    UserRepository()
}

var repo: any Repository<User> = UserRepository()
```

---

### Q7: Explain Swift's type inference and its limits

**Answer:**

Swift uses bidirectional type inference with constraints propagation.

```swift
// Simple inference
let x = 42              // Int
let y = 3.14            // Double
let z = "hello"         // String

// Generic inference
let array = [1, 2, 3]   // Array<Int>
let dict = ["a": 1]     // Dictionary<String, Int>

// Closure inference
let numbers = [1, 2, 3]
let doubled = numbers.map { $0 * 2 }  // [Int]

// Complex inference with constraints
func combine<T>(_ a: T, _ b: T) -> [T] { [a, b] }
let result = combine(1, 2)  // [Int]
```

**When inference fails:**

```swift
// Ambiguous literal
let value = 42
// Is it Int, Int8, Int16, Int32, Int64, UInt...?
// Default: Int for integer literals

// Generic context needs help
func process<T: Numeric>(_ value: T) -> T {
    value * 2
}
// process(5)  // Error: which Numeric type?
process(5 as Int)  // OK
process(Int(5))    // OK

// Empty collections
let emptyArray: [Int] = []  // Must specify type
let emptyDict = [String: Int]()  // Or use explicit initializer

// Closures with complex return
let closure = { (x: Int) -> Int in  // Sometimes need explicit types
    if x > 0 { return x }
    return -x
}
```

---

### Q8: What are phantom types and when to use them?

**Answer:**

Phantom types are generic parameters that don't appear in the type's stored properties but add compile-time safety.

```swift
// Without phantom types - easy to mix up
struct UserID {
    let value: String
}

struct OrderID {
    let value: String
}

func fetchUser(id: UserID) { }
func fetchOrder(id: OrderID) { }

// With phantom types - compile-time safety
struct Identifier<T> {
    let value: String
}

enum UserTag {}
enum OrderTag {}
enum ProductTag {}

typealias UserID2 = Identifier<UserTag>
typealias OrderID2 = Identifier<OrderTag>
typealias ProductID = Identifier<ProductTag>

func fetchUser2(id: UserID2) { }
func fetchOrder2(id: OrderID2) { }

let userId = UserID2(value: "user-123")
let orderId = OrderID2(value: "order-456")

fetchUser2(id: userId)   // OK
// fetchUser2(id: orderId)  // Compile error!
```

**State machines with phantom types:**

```swift
enum Locked {}
enum Unlocked {}

struct Door<State> {
    private let name: String
    
    fileprivate init(name: String) {
        self.name = name
    }
}

extension Door where State == Locked {
    func unlock() -> Door<Unlocked> {
        print("Unlocking \(name)")
        return Door<Unlocked>(name: name)
    }
}

extension Door where State == Unlocked {
    func lock() -> Door<Locked> {
        print("Locking \(name)")
        return Door<Locked>(name: name)
    }
    
    func open() {
        print("Opening \(name)")
    }
}

func createLockedDoor(name: String) -> Door<Locked> {
    Door<Locked>(name: name)
}

// Usage - can't open locked door!
let door = createLockedDoor(name: "Front")
// door.open()  // Compile error!
let unlockedDoor = door.unlock()
unlockedDoor.open()  // OK
```

---

## Protocol-Oriented Programming

### Q9: How do you design a protocol-oriented architecture?

**Answer:**

```swift
// 1. Start with protocols defining behavior
protocol Identifiable {
    var id: String { get }
}

protocol Timestamped {
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

protocol Persistable: Identifiable {
    static var entityName: String { get }
    func toDictionary() -> [String: Any]
    init?(dictionary: [String: Any])
}

// 2. Provide default implementations via extensions
extension Persistable {
    static var entityName: String {
        String(describing: Self.self)
    }
}

extension Persistable where Self: Codable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return dict
    }
}

// 3. Compose protocols
protocol Model: Persistable, Timestamped, Codable {}

// 4. Implement concrete types
struct User: Model {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
    let updatedAt: Date
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let email = dictionary["email"] as? String
        else { return nil }
        
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = dictionary["createdAt"] as? Date ?? Date()
        self.updatedAt = dictionary["updatedAt"] as? Date ?? Date()
    }
}
```

**Protocol composition for dependency injection:**

```swift
protocol NetworkService {
    func fetch<T: Decodable>(from url: URL) async throws -> T
}

protocol CacheService {
    func get<T: Codable>(key: String) -> T?
    func set<T: Codable>(_ value: T, key: String)
}

protocol AnalyticsService {
    func track(event: String, properties: [String: Any])
}

// Compose dependencies
typealias AppServices = NetworkService & CacheService & AnalyticsService

class UserRepository {
    private let services: AppServices
    
    init(services: AppServices) {
        self.services = services
    }
}
```

---

### Q10: Explain protocol witness tables and existential containers

**Answer:**

Swift uses protocol witness tables (PWT) for dynamic dispatch on protocols.

```swift
protocol Drawable {
    func draw()
    var color: String { get }
}

struct Circle: Drawable {
    func draw() { print("Drawing circle") }
    var color: String { "Red" }
}

struct Square: Drawable {
    func draw() { print("Drawing square") }
    var color: String { "Blue" }
}
```

**Existential container structure (simplified):**

```
+------------------------+
| Value Buffer (24 bytes)|  <- Inline storage for small types
| or Pointer to Heap     |  <- For larger types
+------------------------+
| Value Witness Table    |  <- How to copy, destroy, etc.
+------------------------+
| Protocol Witness Table |  <- Method implementations
+------------------------+
```

**Performance implications:**

```swift
// Existential (dynamic dispatch, heap allocation for large types)
func drawAny(shape: any Drawable) {
    shape.draw()  // Dynamic dispatch via PWT
}

// Generic (static dispatch, specialized at compile time)
func drawGeneric<T: Drawable>(shape: T) {
    shape.draw()  // Static dispatch (usually inlined)
}

// Performance comparison
let shapes: [any Drawable] = [Circle(), Square()]
for shape in shapes {
    drawAny(shape: shape)  // Slower: dynamic dispatch
}

// Faster with generics when type is known
let circle = Circle()
drawGeneric(shape: circle)  // Faster: static dispatch
```

---

## Concurrency Deep Dive

### Q11: Explain actor isolation and data races prevention

**Answer:**

Actors provide compile-time data race safety through isolation.

```swift
actor BankAccount {
    let accountNumber: String
    private(set) var balance: Double
    
    init(accountNumber: String, initialBalance: Double) {
        self.accountNumber = accountNumber
        self.balance = initialBalance
    }
    
    func deposit(_ amount: Double) {
        balance += amount
    }
    
    func withdraw(_ amount: Double) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }
    
    // nonisolated - can be called without await
    nonisolated var description: String {
        "Account: \(accountNumber)"  // OK: accountNumber is let
        // Can't access balance here without await
    }
}

// Usage
let account = BankAccount(accountNumber: "123", initialBalance: 1000)

Task {
    await account.deposit(500)
    let success = await account.withdraw(200)
    let currentBalance = await account.balance
}
```

**Actor reentrancy:**

```swift
actor ImageLoader {
    private var cache: [URL: Data] = [:]
    
    func loadImage(from url: URL) async throws -> Data {
        // Check cache
        if let cached = cache[url] {
            return cached
        }
        
        // SUSPENSION POINT - actor state might change!
        let data = try await URLSession.shared.data(from: url).0
        
        // Another task might have cached this URL during await
        if let cached = cache[url] {
            return cached  // Use cached version
        }
        
        cache[url] = data
        return data
    }
}
```

**Global actors:**

```swift
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

@DatabaseActor
class DatabaseManager {
    func save(_ data: Data) {
        // Always runs on DatabaseActor
    }
}

@DatabaseActor
func performDatabaseOperation() async {
    // Isolated to DatabaseActor
}
```

---

### Q12: What is Sendable and how does it ensure thread safety?

**Answer:**

`Sendable` marks types that can safely cross actor/task boundaries.

```swift
// Automatically Sendable
struct Point: Sendable {
    let x: Double
    let y: Double
}

// Classes need explicit marking and immutability
final class ImmutableConfig: Sendable {
    let apiKey: String
    let baseURL: URL
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
}

// @unchecked Sendable - you guarantee thread safety
final class ThreadSafeCache<Key: Hashable, Value>: @unchecked Sendable {
    private var storage: [Key: Value] = [:]
    private let lock = NSLock()
    
    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
    
    func set(_ key: Key, value: Value) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}
```

**Sendable closures:**

```swift
actor DataProcessor {
    func process(completion: @Sendable () -> Void) {
        // completion must be Sendable to cross actor boundary
    }
    
    func processAsync(handler: @Sendable @escaping () async -> Void) {
        Task {
            await handler()
        }
    }
}

// Non-Sendable types can't cross boundaries
class MutableState {
    var value = 0
}

let state = MutableState()

Task {
    // Error: MutableState is not Sendable
    // state.value += 1
}
```

---

### Q13: Explain structured vs unstructured concurrency

**Answer:**

**Structured Concurrency:**

```swift
// Tasks are scoped to their parent
func fetchUserData() async throws -> UserProfile {
    // Child tasks automatically cancelled if parent is cancelled
    async let avatar = fetchAvatar()
    async let posts = fetchPosts()
    async let friends = fetchFriends()
    
    // All complete or all cancelled together
    return UserProfile(
        avatar: try await avatar,
        posts: try await posts,
        friends: try await friends
    )
}

// TaskGroup for dynamic number of tasks
func fetchAllItems(ids: [String]) async throws -> [Item] {
    try await withThrowingTaskGroup(of: Item.self) { group in
        for id in ids {
            group.addTask {
                try await fetchItem(id: id)
            }
        }
        
        var items: [Item] = []
        for try await item in group {
            items.append(item)
        }
        return items
    }
}
```

**Unstructured Concurrency:**

```swift
class ViewController: UIViewController {
    private var loadTask: Task<Void, Never>?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Unstructured - not tied to any scope
        loadTask = Task {
            await loadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadTask?.cancel()  // Manual cancellation needed
    }
    
    // Detached tasks - no parent context at all
    func startBackgroundWork() {
        Task.detached(priority: .background) {
            // Doesn't inherit actor context
            // Doesn't inherit task-local values
            await self.heavyComputation()
        }
    }
}
```

---

### Q14: How do you handle task cancellation properly?

**Answer:**

```swift
func fetchLargeDataset() async throws -> [DataItem] {
    var items: [DataItem] = []
    
    for page in 1...100 {
        // Check cancellation explicitly
        try Task.checkCancellation()
        
        // Or check and handle gracefully
        if Task.isCancelled {
            return items  // Return partial results
        }
        
        let pageData = try await fetchPage(page)
        items.append(contentsOf: pageData)
    }
    
    return items
}

// Cancellation with cleanup
func downloadFile(url: URL) async throws -> Data {
    let tempFile = createTempFile()
    
    return try await withTaskCancellationHandler {
        // Main work
        let data = try await URLSession.shared.data(from: url).0
        try data.write(to: tempFile)
        return data
    } onCancel: {
        // Cleanup on cancellation
        try? FileManager.default.removeItem(at: tempFile)
    }
}

// Cooperative cancellation in loops
func processItems(_ items: [Item]) async {
    for item in items {
        guard !Task.isCancelled else { break }
        await process(item)
    }
}
```

---

## Performance Optimization

### Q15: What are the performance differences between struct and class?

**Answer:**

```swift
// Struct - Stack allocated (usually), value semantics
struct Point {
    var x: Double
    var y: Double
}

// Class - Heap allocated, reference semantics, ARC overhead
class PointClass {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// Performance comparison
func measureStructPerformance() {
    var points: [Point] = []
    for i in 0..<1_000_000 {
        points.append(Point(x: Double(i), y: Double(i)))
    }
    // Fast: contiguous memory, no heap allocation per element
}

func measureClassPerformance() {
    var points: [PointClass] = []
    for i in 0..<1_000_000 {
        points.append(PointClass(x: Double(i), y: Double(i)))
    }
    // Slower: heap allocation + ARC for each element
}
```

**When structs are NOT on stack:**

```swift
// Struct containing reference type
struct Container {
    var data: NSMutableData  // Reference stored on heap
}

// Struct captured by escaping closure
func captureStruct() -> () -> Void {
    var point = Point(x: 0, y: 0)
    return {
        print(point)  // point moved to heap
    }
}

// Large structs in collections
struct LargeStruct {
    var data: (Int, Int, Int, Int, Int, Int, Int, Int) = (0,0,0,0,0,0,0,0)
}

let array = [LargeStruct()]  // Array buffer on heap
```

---

### Q16: How do you optimize string handling in Swift?

**Answer:**

```swift
// String is a value type with CoW
var str1 = "Hello"
var str2 = str1  // No copy yet
str2 += " World"  // Copy on mutation

// Substring - shares storage with original
let greeting = "Hello, World!"
let hello = greeting.prefix(5)  // Substring, shares memory
let helloString = String(hello)  // Creates independent copy

// Performance tips
func buildString() -> String {
    // Bad: O(n²) due to repeated allocations
    var result = ""
    for i in 0..<1000 {
        result += "item \(i), "
    }
    
    // Good: Reserve capacity
    var result2 = ""
    result2.reserveCapacity(10000)
    for i in 0..<1000 {
        result2 += "item \(i), "
    }
    
    // Best: Use joined
    let items = (0..<1000).map { "item \($0)" }
    return items.joined(separator: ", ")
}

// String comparison optimization
let str = "Hello, World!"

// Slow: Creates new String
if str.lowercased() == "hello, world!" { }

// Fast: Case-insensitive comparison
if str.caseInsensitiveCompare("hello, world!") == .orderedSame { }
if str.localizedCaseInsensitiveCompare("hello, world!") == .orderedSame { }
```

**Unicode and performance:**

```swift
let emoji = "👨‍👩‍👧‍👦"

// Character count (grapheme clusters) - O(n)
print(emoji.count)  // 1

// UTF-8 view - O(1) for count
print(emoji.utf8.count)  // 25

// For ASCII-only operations
extension String {
    var asciiCount: Int? {
        guard self.allSatisfy({ $0.isASCII }) else { return nil }
        return self.utf8.count
    }
}
```

---

### Q17: Explain @inlinable, @inline and their effects

**Answer:**

```swift
// @inline(__always) - Forces inlining
@inline(__always)
func fastSquare(_ x: Int) -> Int {
    x * x
}

// @inline(never) - Prevents inlining (debugging, code size)
@inline(never)
func debugLog(_ message: String) {
    print(message)
}

// @inlinable - Exposes implementation across modules
public struct FastMath {
    @inlinable
    public static func square(_ x: Int) -> Int {
        x * x  // Implementation visible to other modules
    }
}

// @usableFromInline - Internal but available for inlining
public struct OptimizedContainer<T> {
    @usableFromInline
    internal var storage: [T]
    
    public init() {
        storage = []
    }
    
    @inlinable
    public mutating func append(_ element: T) {
        storage.append(element)  // Can access storage
    }
}
```

**When to use:**

```swift
// Use @inlinable for:
// - Simple, performance-critical functions
// - Generic algorithms
// - Property accessors

// DON'T use for:
// - Complex functions (increases binary size)
// - Functions that might change (locks ABI)
// - Security-sensitive code
```

---

## Metaprogramming

### Q18: How do property wrappers work internally?

**Answer:**

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    let range: ClosedRange<Value>
    
    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
    
    var projectedValue: ClosedRange<Value> {
        range
    }
    
    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

struct Player {
    @Clamped(0...100) var health: Int = 100
    @Clamped(0...999) var score: Int = 0
}

var player = Player()
player.health = 150  // Clamped to 100
print(player.health)  // 100
print(player.$health)  // 0...100 (projectedValue)

// What compiler generates:
struct PlayerExpanded {
    private var _health: Clamped<Int> = Clamped(wrappedValue: 100, 0...100)
    
    var health: Int {
        get { _health.wrappedValue }
        set { _health.wrappedValue = newValue }
    }
    
    var $health: ClosedRange<Int> {
        _health.projectedValue
    }
}
```

**Composing property wrappers:**

```swift
@propertyWrapper
struct Logged<Value> {
    private var value: Value
    let name: String
    
    var wrappedValue: Value {
        get { value }
        set {
            print("\(name): \(value) -> \(newValue)")
            value = newValue
        }
    }
    
    init(wrappedValue: Value, name: String) {
        self.value = wrappedValue
        self.name = name
    }
}

struct Settings {
    @Logged(name: "Volume") @Clamped(0...100) var volume: Int = 50
}
// Applied outer to inner: Logged wraps Clamped wraps Int
```

---

### Q19: Explain result builders and their compilation

**Answer:**

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
    
    static func buildExpression(_ expression: Element) -> [Element] {
        [expression]
    }
}

func makeArray<T>(@ArrayBuilder<T> content: () -> [T]) -> [T] {
    content()
}

let numbers = makeArray {
    1
    2
    if Bool.random() {
        3
    }
    for i in 4...6 {
        i
    }
}
```

**SwiftUI ViewBuilder simplified:**

```swift
@resultBuilder
struct SimpleViewBuilder {
    static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }
    
    static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)> {
        TupleView((c0, c1))
    }
    
    static func buildIf<Content: View>(_ content: Content?) -> Content? {
        content
    }
    
    static func buildEither<TrueContent: View, FalseContent: View>(
        first: TrueContent
    ) -> _ConditionalContent<TrueContent, FalseContent> {
        // ...
    }
}
```

---

## Swift Internals

### Q20: How does Swift's method dispatch work?

**Answer:**

Swift has three dispatch mechanisms:

```swift
// 1. Static Dispatch (Direct Call)
struct Calculator {
    func add(_ a: Int, _ b: Int) -> Int {  // Static dispatch
        a + b
    }
}

final class FinalCalculator {
    func add(_ a: Int, _ b: Int) -> Int {  // Static dispatch
        a + b
    }
}

// 2. Table Dispatch (Virtual Table / Witness Table)
class Animal {
    func speak() { }  // Table dispatch (vtable)
}

class Dog: Animal {
    override func speak() { print("Woof") }
}

protocol Speaker {
    func speak()  // Table dispatch (witness table)
}

// 3. Message Dispatch (Objective-C runtime)
class NSObjectSubclass: NSObject {
    @objc dynamic func doSomething() { }  // Message dispatch
}
```

**Performance comparison:**

```
Static Dispatch:    ~0 overhead (inlined often)
Table Dispatch:     ~1-2 ns (pointer lookup)
Message Dispatch:   ~5-20 ns (runtime lookup)
```

**Forcing dispatch type:**

```swift
class BaseClass {
    func method() { }  // Table dispatch
    final func finalMethod() { }  // Static dispatch
}

extension BaseClass {
    func extensionMethod() { }  // Static dispatch (can't override)
}

class SubClass: BaseClass {
    override func method() { }  // Table dispatch
    // Can't override finalMethod or extensionMethod
}

// Protocol extensions
protocol MyProtocol {
    func required()  // Witness table
}

extension MyProtocol {
    func notRequired() { }  // Static dispatch!
}

struct Implementation: MyProtocol {
    func required() { print("Implementation") }
    func notRequired() { print("Also Implementation") }
}

let concrete: Implementation = Implementation()
concrete.notRequired()  // "Also Implementation" (static)

let abstract: MyProtocol = Implementation()
abstract.notRequired()  // "Not Implementation" - extension method! (static)
```

---

### Q21: What happens during Swift compilation?

**Answer:**

```
Source.swift
     │
     ▼
┌─────────────────┐
│ 1. Parsing      │  → AST (Abstract Syntax Tree)
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ 2. Semantic     │  → Type checking, inference
│    Analysis     │  → Name resolution
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ 3. SIL Gen      │  → Swift Intermediate Language
│    (Raw SIL)    │  → High-level optimizations
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ 4. SIL          │  → Guaranteed optimizations
│    Optimization │  → Diagnostic passes
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ 5. IRGen        │  → LLVM IR generation
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ 6. LLVM         │  → Machine code optimization
│    Optimization │  → Code generation
└─────────────────┘
     │
     ▼
  Object File (.o)
```

**SIL example:**

```swift
// Swift code
func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}

// Simplified SIL
sil @add : $@convention(thin) (Int, Int) -> Int {
bb0(%0 : $Int, %1 : $Int):
  %2 = struct_extract %0 : $Int, #Int._value
  %3 = struct_extract %1 : $Int, #Int._value
  %4 = builtin "add_Int64"(%2, %3)
  %5 = struct $Int (%4)
  return %5 : $Int
}
```

---

### Q22: How does Swift handle protocol conformance checking?

**Answer:**

```swift
// Compile-time conformance
protocol Flyable {
    func fly()
}

struct Bird: Flyable {
    func fly() { }  // Compiler verifies this exists
}

// Runtime conformance checking
func checkFlyable(_ object: Any) {
    if let flyable = object as? Flyable {
        flyable.fly()
    }
}

// Conditional conformance
extension Array: Flyable where Element: Flyable {
    func fly() {
        forEach { $0.fly() }
    }
}

// At runtime, Swift checks if Element conforms
let birds: [Bird] = [Bird(), Bird()]
let numbers: [Int] = [1, 2, 3]

birds.fly()   // Works: Bird: Flyable
// numbers.fly()  // Error: Int doesn't conform to Flyable

// Protocol metadata
print(type(of: birds) is Flyable.Type)  // false - metatype check
print(birds is Flyable)  // true - instance check
```

---

## Common Interview Coding Questions

### Q23: Implement a thread-safe singleton

```swift
final class Singleton {
    static let shared = Singleton()  // Thread-safe, lazy
    
    private init() { }
    
    private let lock = NSLock()
    private var _state: [String: Any] = [:]
    
    subscript(key: String) -> Any? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state[key]
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _state[key] = newValue
        }
    }
}

// Modern actor-based approach
actor ModernSingleton {
    static let shared = ModernSingleton()
    
    private var state: [String: Any] = [:]
    
    func get(_ key: String) -> Any? {
        state[key]
    }
    
    func set(_ key: String, value: Any) {
        state[key] = value
    }
}
```

---

### Q24: Implement a generic LRU Cache

```swift
class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    
    class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        guard let node = cache[key] else { return nil }
        moveToFront(node)
        return node.value
    }
    
    func put(_ key: Key, value: Value) {
        if let existing = cache[key] {
            existing.value = value
            moveToFront(existing)
        } else {
            let node = Node(key: key, value: value)
            cache[key] = node
            addToFront(node)
            
            if cache.count > capacity {
                removeLRU()
            }
        }
    }
    
    private func moveToFront(_ node: Node) {
        removeNode(node)
        addToFront(node)
    }
    
    private func addToFront(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }
    
    private func removeNode(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if node === head { head = node.next }
        if node === tail { tail = node.prev }
    }
    
    private func removeLRU() {
        guard let lru = tail else { return }
        cache.removeValue(forKey: lru.key)
        removeNode(lru)
    }
}
```

---

### Q25: Implement async/await compatible debounce

```swift
actor Debouncer {
    private var task: Task<Void, Never>?
    private let duration: Duration
    
    init(duration: Duration) {
        self.duration = duration
    }
    
    func debounce(_ operation: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                await operation()
            } catch {
                // Task was cancelled
            }
        }
    }
}

// Usage
class SearchViewModel {
    private let debouncer = Debouncer(duration: .milliseconds(300))
    
    func searchTextChanged(_ text: String) async {
        await debouncer.debounce { [weak self] in
            await self?.performSearch(text)
        }
    }
    
    private func performSearch(_ query: String) async {
        // API call
    }
}
```

---

## Summary

| Topic | Key Points |
|-------|------------|
| Memory | ARC, weak/unowned, capture lists, CoW |
| Generics | Associated types, opaque types, phantom types |
| Protocols | POP design, witness tables, composition |
| Concurrency | Actors, Sendable, structured tasks |
| Performance | Struct vs class, dispatch types, inlining |
| Metaprogramming | Property wrappers, result builders |
| Internals | Compilation pipeline, SIL, dispatch |

---

*Last updated: 2024*
