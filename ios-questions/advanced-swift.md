# Advanced Swift Interview Questions

A comprehensive collection of advanced Swift interview questions covering memory management, concurrency, generics, protocols, and performance optimization.

---

## Table of Contents

1. [Memory Management](#memory-management)
2. [Concurrency & Async/Await](#concurrency--asyncawait)
3. [Generics & Type System](#generics--type-system)
4. [Protocol-Oriented Programming](#protocol-oriented-programming)
5. [Performance Optimization](#performance-optimization)
6. [Runtime & Reflection](#runtime--reflection)
7. [Advanced Closures](#advanced-closures)
8. [Error Handling Patterns](#error-handling-patterns)

---

## Memory Management

### Q1: Explain the difference between strong, weak, and unowned references. When would you use each?

**Answer:**

```swift
// Strong reference (default) - increases retain count
class Parent {
    var child: Child?
}

// Weak reference - doesn't increase retain count, becomes nil when deallocated
class Child {
    weak var parent: Parent?
}

// Unowned reference - doesn't increase retain count, crashes if accessed after deallocation
class Customer {
    let name: String
    var card: CreditCard?
    
    init(name: String) { self.name = name }
}

class CreditCard {
    let number: Int
    unowned let customer: Customer
    
    init(number: Int, customer: Customer) {
        self.number = number
        self.customer = customer
    }
}
```

**When to use:**
- **Strong**: Default ownership, parent-to-child relationships
- **Weak**: Delegate patterns, optional relationships where either object can be deallocated first
- **Unowned**: Non-optional relationships where referenced object has equal or longer lifetime

---

### Q2: What is a retain cycle and how do you detect and fix it?

**Answer:**

A retain cycle occurs when two or more objects hold strong references to each other, preventing deallocation.

```swift
// Retain cycle example
class ViewController {
    var closure: (() -> Void)?
    
    func setupClosure() {
        // This creates a retain cycle!
        closure = {
            self.doSomething() // self strongly captures ViewController
        }
    }
    
    // Fixed version using capture list
    func setupClosureFixed() {
        closure = { [weak self] in
            self?.doSomething()
        }
    }
    
    func doSomething() { }
}
```

**Detection methods:**
1. Xcode Memory Graph Debugger
2. Instruments Leaks tool
3. Adding deinit print statements during development
4. Static analysis tools

---

### Q3: Explain autorelease pools and when you'd manually use them

**Answer:**

```swift
// Manual autorelease pool usage
func processLargeDataSet() {
    for i in 0..<100000 {
        autoreleasepool {
            let data = loadLargeData(index: i)
            processData(data)
            // Memory released at end of each iteration
        }
    }
}

// Useful scenarios:
// 1. Loops creating many temporary objects
// 2. Background thread operations
// 3. Command-line tools without RunLoop
```

Autorelease pools provide deterministic cleanup of temporary objects, reducing peak memory usage in tight loops.

---

### Q4: What is copy-on-write (COW) and how does Swift implement it for value types?

**Answer:**

```swift
// Copy-on-write demonstration
var array1 = [1, 2, 3, 4, 5]
var array2 = array1 // No actual copy yet, both point to same storage

array2.append(6) // NOW a copy is made

// Implementing custom COW
final class Storage<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

struct COWContainer<T> {
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

### Q5: Explain the memory layout of a Swift class vs struct

**Answer:**

```swift
// Struct - stored inline on stack (typically)
struct Point {
    var x: Double  // 8 bytes
    var y: Double  // 8 bytes
}
// Total: 16 bytes, no overhead

// Class - stored on heap with metadata
class PointClass {
    var x: Double  // 8 bytes
    var y: Double  // 8 bytes
}
// Total: 16 bytes + 8 bytes (isa pointer) + 8 bytes (retain count) = 32 bytes minimum

// Checking memory layout
print(MemoryLayout<Point>.size)       // 16
print(MemoryLayout<Point>.stride)     // 16
print(MemoryLayout<Point>.alignment)  // 8
```

---

## Concurrency & Async/Await

### Q6: Explain actors and how they prevent data races

**Answer:**

```swift
// Actor provides automatic synchronization
actor BankAccount {
    private var balance: Double = 0
    
    func deposit(_ amount: Double) {
        balance += amount
    }
    
    func withdraw(_ amount: Double) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }
    
    // nonisolated allows synchronous access from outside
    nonisolated let accountNumber: String = "12345"
}

// Usage requires await
func performTransaction() async {
    let account = BankAccount()
    await account.deposit(100)
    let success = await account.withdraw(50)
}

// Global actor for shared state
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

@DatabaseActor
class DatabaseManager {
    func query(_ sql: String) -> [Any] { [] }
}
```

---

### Q7: What is structured concurrency and how does TaskGroup work?

**Answer:**

```swift
// Structured concurrency with TaskGroup
func fetchAllUserData(userIds: [String]) async throws -> [UserData] {
    try await withThrowingTaskGroup(of: UserData.self) { group in
        for userId in userIds {
            group.addTask {
                try await fetchUser(id: userId)
            }
        }
        
        var results: [UserData] = []
        for try await userData in group {
            results.append(userData)
        }
        return results
    }
}

// Cancellation propagates automatically
func fetchWithTimeout() async throws -> Data {
    try await withThrowingTaskGroup(of: Data.self) { group in
        group.addTask {
            try await fetchFromServer()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll() // Cancel remaining tasks
        return result
    }
}
```

---

### Q8: Explain Sendable and how to make types thread-safe

**Answer:**

```swift
// Value types are implicitly Sendable
struct UserInfo: Sendable {
    let id: String
    let name: String
}

// Classes need explicit conformance
final class Configuration: Sendable {
    let apiKey: String // Only let properties allowed
    let baseURL: URL
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
}

// Use @unchecked Sendable carefully
class ThreadSafeCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Any] = [:]
    
    func get(_ key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
    
    func set(_ key: String, value: Any) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}
```

---

### Q9: What is MainActor and when should you use it?

**Answer:**

```swift
// MainActor ensures code runs on main thread
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func loadItems() async {
        let fetchedItems = await fetchItemsFromAPI()
        items = fetchedItems // Safe - already on MainActor
    }
}

// Isolate specific methods
class DataService {
    func fetchData() async -> [Data] {
        // Runs on any thread
        return await networkCall()
    }
    
    @MainActor
    func updateUI(with data: [Data]) {
        // Guaranteed main thread
    }
}

// MainActor.run for one-off dispatches
func processInBackground() async {
    let result = await heavyComputation()
    await MainActor.run {
        updateLabel(result)
    }
}
```

---

### Q10: Explain AsyncSequence and AsyncStream

**Answer:**

```swift
// Custom AsyncSequence
struct Counter: AsyncSequence {
    typealias Element = Int
    let limit: Int
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var current = 0
        let limit: Int
        
        mutating func next() async -> Int? {
            guard current < limit else { return nil }
            defer { current += 1 }
            try? await Task.sleep(nanoseconds: 100_000_000)
            return current
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(limit: limit)
    }
}

// Using AsyncStream for bridging
func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let manager = CLLocationManager()
        let delegate = LocationDelegate { location in
            continuation.yield(location)
        }
        manager.delegate = delegate
        manager.startUpdatingLocation()
        
        continuation.onTermination = { _ in
            manager.stopUpdatingLocation()
        }
    }
}
```

---

## Generics & Type System

### Q11: Explain associated types and how they differ from generic parameters

**Answer:**

```swift
// Associated type in protocol
protocol Container {
    associatedtype Item
    var count: Int { get }
    mutating func append(_ item: Item)
    subscript(i: Int) -> Item { get }
}

// Implementation with concrete type
struct IntStack: Container {
    typealias Item = Int  // Can often be inferred
    var items: [Int] = []
    var count: Int { items.count }
    
    mutating func append(_ item: Int) {
        items.append(item)
    }
    
    subscript(i: Int) -> Int {
        items[i]
    }
}

// Generic implementation
struct Stack<Element>: Container {
    var items: [Element] = []
    var count: Int { items.count }
    
    mutating func append(_ item: Element) {
        items.append(item)
    }
    
    subscript(i: Int) -> Element {
        items[i]
    }
}
```

**Key differences:**
- Associated types are determined by the conforming type
- Generic parameters are specified by the caller
- Associated types enable protocol use as a type constraint

---

### Q12: What is type erasure and when would you use it?

**Answer:**

```swift
// Problem: Can't use protocol with associated type as a type
protocol DataFetcher {
    associatedtype DataType
    func fetch() async throws -> DataType
}

// Type erasure solution
struct AnyDataFetcher<T>: DataFetcher {
    private let _fetch: () async throws -> T
    
    init<F: DataFetcher>(_ fetcher: F) where F.DataType == T {
        _fetch = fetcher.fetch
    }
    
    func fetch() async throws -> T {
        try await _fetch()
    }
}

// Usage
class UserFetcher: DataFetcher {
    func fetch() async throws -> User {
        // Fetch user
        return User()
    }
}

let fetcher: AnyDataFetcher<User> = AnyDataFetcher(UserFetcher())

// Modern approach: any keyword (Swift 5.7+)
let modernFetcher: any DataFetcher = UserFetcher()
```

---

### Q13: Explain opaque types (some) vs existential types (any)

**Answer:**

```swift
// Opaque type - specific underlying type (identity preserved)
func makeCollection() -> some Collection<Int> {
    [1, 2, 3, 4, 5]
}

// Existential type - type erased (identity lost)
func makeAnyCollection() -> any Collection<Int> {
    if Bool.random() {
        return [1, 2, 3]
    } else {
        return Set([1, 2, 3])
    }
}

// Key differences
let opaque = makeCollection()
// Compiler knows exact type, can optimize

let existential = makeAnyCollection()
// Type erased, dynamic dispatch, heap allocation

// Use opaque when:
// - Same type always returned
// - Need maximum performance
// - Want to hide implementation details

// Use existential when:
// - Different types may be returned
// - Storing heterogeneous collections
// - Flexibility > performance
```

---

### Q14: How do you constrain generic types with where clauses?

**Answer:**

```swift
// Basic constraint
func findIndex<T: Equatable>(of value: T, in array: [T]) -> Int? {
    array.firstIndex(of: value)
}

// Multiple constraints with where
func processData<T, U>(input: T, transformer: U) -> U.Output 
    where T: Collection, 
          U: Transformer, 
          T.Element == U.Input {
    transformer.transform(input.first!)
}

// Extension with constraints
extension Array where Element: Numeric {
    func sum() -> Element {
        reduce(0, +)
    }
}

// Protocol extension with constraints
extension Collection where Element: Equatable {
    func containsDuplicates() -> Bool {
        for (index, element) in enumerated() {
            if self.dropFirst(index + 1).contains(element) {
                return true
            }
        }
        return false
    }
}

// Associated type constraints
protocol Repository {
    associatedtype Entity: Identifiable where Entity.ID == UUID
    func find(id: UUID) -> Entity?
}
```

---

### Q15: Explain phantom types and their use cases

**Answer:**

```swift
// Phantom type - type parameter not used in stored properties
enum Validated {}
enum Unvalidated {}

struct Email<Status> {
    let rawValue: String
    
    private init(_ value: String) {
        self.rawValue = value
    }
    
    static func create(_ value: String) -> Email<Unvalidated> {
        Email<Unvalidated>(value)
    }
}

extension Email where Status == Unvalidated {
    func validate() -> Email<Validated>? {
        guard rawValue.contains("@") else { return nil }
        return Email<Validated>(rawValue)
    }
}

// Function only accepts validated emails
func sendEmail(to email: Email<Validated>) {
    print("Sending to \(email.rawValue)")
}

// Usage
let unvalidated = Email<Unvalidated>.create("test@example.com")
// sendEmail(to: unvalidated) // Compile error!

if let validated = unvalidated.validate() {
    sendEmail(to: validated) // Works!
}
```

---

## Protocol-Oriented Programming

### Q16: Explain protocol composition and its benefits

**Answer:**

```swift
// Individual protocols
protocol Identifiable {
    var id: String { get }
}

protocol Named {
    var name: String { get }
}

protocol Timestamped {
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

// Protocol composition
typealias Entity = Identifiable & Named & Timestamped

// Function accepting composed type
func display(entity: Identifiable & Named) {
    print("\(entity.id): \(entity.name)")
}

// Implementation
struct User: Entity {
    let id: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
}

// Flexible constraints
func sync<T: Identifiable & Codable>(_ item: T) throws {
    let data = try JSONEncoder().encode(item)
    // Upload with id
}
```

---

### Q17: How do you use protocol witnesses for dependency injection?

**Answer:**

```swift
// Protocol witness / point-free style
struct Environment {
    var fetchUser: (String) async throws -> User
    var saveUser: (User) async throws -> Void
    var analytics: Analytics
    var date: () -> Date
    var uuid: () -> UUID
}

extension Environment {
    static let live = Environment(
        fetchUser: { id in
            // Real network call
            try await APIClient.shared.fetchUser(id: id)
        },
        saveUser: { user in
            try await APIClient.shared.saveUser(user)
        },
        analytics: .live,
        date: Date.init,
        uuid: UUID.init
    )
    
    static let mock = Environment(
        fetchUser: { _ in User.mock },
        saveUser: { _ in },
        analytics: .mock,
        date: { Date(timeIntervalSince1970: 0) },
        uuid: { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
    )
}

// Usage in view model
class UserViewModel {
    let environment: Environment
    
    init(environment: Environment = .live) {
        self.environment = environment
    }
    
    func load(userId: String) async throws -> User {
        try await environment.fetchUser(userId)
    }
}
```

---

### Q18: Explain Self requirement in protocols

**Answer:**

```swift
// Self refers to the conforming type
protocol Copyable {
    func copy() -> Self
}

final class Document: Copyable {
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    func copy() -> Document { // Self = Document
        Document(content: content)
    }
}

// Self in static methods
protocol Factory {
    static func create() -> Self
}

final class Widget: Factory {
    static func create() -> Widget {
        Widget()
    }
}

// Self as parameter type
protocol Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool
}

// Note: Protocols with Self requirements can't be used as types
// let items: [Copyable] = [] // Error!
// Use generics instead:
func duplicate<T: Copyable>(_ item: T) -> T {
    item.copy()
}
```

---

### Q19: How do you implement a protocol with default implementations?

**Answer:**

```swift
// Protocol with default implementation
protocol Loggable {
    var logPrefix: String { get }
    func log(_ message: String)
    func logError(_ error: Error)
}

extension Loggable {
    var logPrefix: String { String(describing: Self.self) }
    
    func log(_ message: String) {
        print("[\(logPrefix)] \(message)")
    }
    
    func logError(_ error: Error) {
        print("[\(logPrefix)] ERROR: \(error.localizedDescription)")
    }
}

// Conforming type gets defaults
class NetworkService: Loggable {
    func fetch() {
        log("Starting fetch...")
    }
}

// Override specific methods
class VerboseService: Loggable {
    var logPrefix: String { "🔵 VerboseService" }
    
    func log(_ message: String) {
        print("[\(logPrefix)] [\(Date())] \(message)")
    }
}
```

---

### Q20: What is protocol-oriented programming vs object-oriented programming?

**Answer:**

```swift
// OOP approach - inheritance hierarchy
class Animal {
    func makeSound() { }
}

class Dog: Animal {
    override func makeSound() { print("Bark") }
}

class Cat: Animal {
    override func makeSound() { print("Meow") }
}

// POP approach - composition over inheritance
protocol SoundMaking {
    func makeSound()
}

protocol Moving {
    func move()
}

struct Dog: SoundMaking, Moving {
    func makeSound() { print("Bark") }
    func move() { print("Run") }
}

struct Car: Moving {
    func move() { print("Drive") }
}

// Benefits of POP:
// 1. Value types can conform (structs, enums)
// 2. Multiple conformance (no diamond problem)
// 3. Default implementations via extensions
// 4. Better testability
// 5. No implicit state sharing

// Mixing both approaches
protocol Drivable {
    var speed: Double { get set }
    func accelerate()
}

extension Drivable {
    mutating func accelerate() {
        speed += 10
    }
}
```

---

## Performance Optimization

### Q21: How do you profile and optimize Swift code performance?

**Answer:**

```swift
// 1. Use Instruments Time Profiler
// 2. Measure with CFAbsoluteTimeGetCurrent
func measure(_ block: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let end = CFAbsoluteTimeGetCurrent()
    print("Execution time: \(end - start) seconds")
}

// 3. Use os_signpost for detailed tracing
import os.signpost

let log = OSLog(subsystem: "com.app", category: "performance")

func loadData() {
    os_signpost(.begin, log: log, name: "Load Data")
    // Work here
    os_signpost(.end, log: log, name: "Load Data")
}

// 4. Compiler optimizations
// -O for release, -Osize for size optimization
// Use @inlinable for cross-module optimization
@inlinable
public func fastOperation(_ x: Int) -> Int {
    x * 2
}

// 5. Avoid unnecessary allocations
// Prefer structs over classes when possible
// Use reserveCapacity for collections
var array: [Int] = []
array.reserveCapacity(1000)
```

---

### Q22: Explain the performance differences between Array, Set, and Dictionary

**Answer:**

```swift
// Array - O(n) search, O(1) append
var array = [1, 2, 3, 4, 5]
array.append(6)           // O(1) amortized
array.contains(3)         // O(n)
array.insert(0, at: 0)    // O(n)

// Set - O(1) average for lookup/insert/delete
var set: Set = [1, 2, 3, 4, 5]
set.insert(6)             // O(1) average
set.contains(3)           // O(1) average
set.remove(3)             // O(1) average

// Dictionary - O(1) average for key operations
var dict = ["a": 1, "b": 2]
dict["c"] = 3             // O(1) average
dict["a"]                 // O(1) average

// Performance comparison
let largeArray = Array(0..<100000)
let largeSet = Set(largeArray)

measure {
    _ = largeArray.contains(99999)  // ~0.003s
}

measure {
    _ = largeSet.contains(99999)    // ~0.00001s
}

// When to use each:
// Array: Ordered data, index access, duplicates allowed
// Set: Unique values, fast lookup, no order needed
// Dictionary: Key-value pairs, fast lookup by key
```

---

### Q23: How do you optimize table view / collection view performance?

**Answer:**

```swift
// 1. Cell reuse
func tableView(_ tableView: UITableView, 
               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
        withIdentifier: "Cell", 
        for: indexPath
    ) as! CustomCell
    
    // 2. Configure quickly, avoid heavy work
    cell.configure(with: items[indexPath.row])
    return cell
}

// 3. Prefetching
extension ViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, 
                   prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = items[indexPath.row]
            imageLoader.prefetch(url: item.imageURL)
        }
    }
}

// 4. Estimated heights
tableView.estimatedRowHeight = 100
tableView.rowHeight = UITableView.automaticDimension

// 5. Async image loading with caching
func loadImage(for cell: CustomCell, url: URL) {
    if let cached = imageCache.object(forKey: url as NSURL) {
        cell.imageView.image = cached
        return
    }
    
    Task {
        let (data, _) = try await URLSession.shared.data(from: url)
        let image = UIImage(data: data)
        imageCache.setObject(image!, forKey: url as NSURL)
        
        await MainActor.run {
            cell.imageView.image = image
        }
    }
}

// 6. Avoid transparency when possible
cell.layer.shouldRasterize = true
cell.layer.rasterizationScale = UIScreen.main.scale
```

---

### Q24: What techniques reduce app launch time?

**Answer:**

```swift
// 1. Defer non-essential initialization
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Only essential setup here
        setupCrashReporting()
        return true
    }
}

// 2. Lazy initialization
class DataManager {
    lazy var database: Database = {
        Database(path: dbPath)
    }()
    
    lazy var heavyResource: HeavyResource = {
        HeavyResource()
    }()
}

// 3. Reduce dynamic library loading
// Use fewer frameworks, merge static libraries

// 4. Optimize +load and +initialize
// Avoid Objective-C +load methods
// Use +initialize only when necessary

// 5. Main thread work
func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
           options connectionOptions: UIScene.ConnectionOptions) {
    // Minimal synchronous work
    
    // Defer heavy work
    DispatchQueue.main.async {
        self.performDeferredSetup()
    }
}

// 6. Pre-main optimization
// - Remove unused code (dead stripping)
// - Reduce Objective-C metadata
// - Use static linking where possible

// Measurement in Instruments > App Launch
// Target: < 400ms for cold launch
```

---

### Q25: How do you reduce memory footprint in Swift?

**Answer:**

```swift
// 1. Use value types appropriately
struct LightweightModel {  // Stack allocated
    let id: Int
    let name: String
}

// 2. Lazy loading for heavy resources
class ViewController: UIViewController {
    lazy var heavyView: UIView = {
        createHeavyView()
    }()
}

// 3. Image optimization
func loadOptimizedImage(named name: String) -> UIImage? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
          let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }
    
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: 200,
        kCGImageSourceCreateThumbnailFromImageAlways: true
    ]
    
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    
    return UIImage(cgImage: thumbnail)
}

// 4. Cache management
let imageCache = NSCache<NSString, UIImage>()
imageCache.countLimit = 100
imageCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

// 5. Memory warnings handling
override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    imageCache.removeAllObjects()
    optionalData = nil
}

// 6. Use autoreleasepool in loops
func processLargeDataset() {
    for item in largeDataset {
        autoreleasepool {
            processItem(item)
        }
    }
}
```

---

## Runtime & Reflection

### Q26: How does Swift's reflection (Mirror) work?

**Answer:**

```swift
// Mirror API for runtime introspection
struct Person {
    let name: String
    let age: Int
    private let ssn: String
}

let person = Person(name: "John", age: 30, ssn: "123-45-6789")
let mirror = Mirror(reflecting: person)

// Iterate over properties
for child in mirror.children {
    print("\(child.label ?? "unknown"): \(child.value)")
}

// Custom debug description using Mirror
extension CustomDebugStringConvertible {
    var debugDescription: String {
        let mirror = Mirror(reflecting: self)
        let properties = mirror.children.map { "\($0.label ?? "?"): \($0.value)" }
        return "\(mirror.subjectType)(\(properties.joined(separator: ", ")))"
    }
}

// Type checking and casting
func describe(_ value: Any) {
    let mirror = Mirror(reflecting: value)
    
    print("Type: \(mirror.subjectType)")
    print("Display style: \(String(describing: mirror.displayStyle))")
    
    if let displayStyle = mirror.displayStyle {
        switch displayStyle {
        case .struct: print("It's a struct")
        case .class: print("It's a class")
        case .enum: print("It's an enum")
        case .optional: print("It's an optional")
        default: break
        }
    }
}
```

---

### Q27: Explain @dynamicMemberLookup and @dynamicCallable

**Answer:**

```swift
// @dynamicMemberLookup - dot syntax for dynamic properties
@dynamicMemberLookup
struct JSON {
    private var data: [String: Any]
    
    subscript(dynamicMember key: String) -> JSON? {
        guard let value = data[key] else { return nil }
        if let dict = value as? [String: Any] {
            return JSON(data: dict)
        }
        return nil
    }
    
    subscript(dynamicMember key: String) -> String? {
        data[key] as? String
    }
    
    subscript(dynamicMember key: String) -> Int? {
        data[key] as? Int
    }
}

let json = JSON(data: ["user": ["name": "John", "age": 30]])
let name: String? = json.user?.name  // "John"

// @dynamicCallable - function call syntax
@dynamicCallable
struct PythonFunction {
    let name: String
    
    func dynamicallyCall(withArguments args: [Any]) -> String {
        "\(name)(\(args.map { String(describing: $0) }.joined(separator: ", ")))"
    }
    
    func dynamicallyCall(withKeywordArguments pairs: KeyValuePairs<String, Any>) -> String {
        let args = pairs.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return "\(name)(\(args))"
    }
}

let print = PythonFunction(name: "print")
print("Hello", "World")  // "print(Hello, World)"
print(message: "Hi", count: 3)  // "print(message=Hi, count=3)"
```

---

### Q28: What is @_silgen_name and when might you use it?

**Answer:**

```swift
// @_silgen_name provides direct symbol binding
// WARNING: This is an unofficial/internal attribute

// Calling C functions without header
@_silgen_name("strlen")
func c_strlen(_ s: UnsafePointer<CChar>) -> Int

let length = c_strlen("Hello")

// Interoperating with assembly/low-level code
@_silgen_name("_swift_stdlib_random")
func _random() -> UInt64

// Use cases:
// 1. Bridging to C without full headers
// 2. Performance-critical code avoiding bridging overhead
// 3. Accessing internal Swift runtime functions

// Better alternatives:
// - Use proper C bridging headers
// - Use @_cdecl for exporting Swift functions
@_cdecl("swift_greeting")
public func greeting() -> UnsafePointer<CChar> {
    ("Hello from Swift" as NSString).utf8String!
}
```

---

## Advanced Closures

### Q29: Explain @escaping vs non-escaping closures

**Answer:**

```swift
// Non-escaping (default) - closure doesn't outlive function
func performOperation(with closure: () -> Void) {
    closure()  // Called before function returns
}

// Escaping - closure may be called after function returns
func fetchData(completion: @escaping (Data) -> Void) {
    DispatchQueue.global().async {
        let data = loadData()
        completion(data)  // Called later, asynchronously
    }
}

// Stored closure must be escaping
class DataManager {
    var completionHandler: ((Data) -> Void)?
    
    func setHandler(_ handler: @escaping (Data) -> Void) {
        completionHandler = handler  // Stored for later
    }
}

// Memory implications
class ViewController {
    var name = "Main"
    
    func setupEscaping() {
        fetchData { [weak self] data in
            // Must capture self weakly to avoid retain cycle
            self?.processData(data)
        }
    }
    
    func setupNonEscaping() {
        performOperation {
            // Safe to use self implicitly
            print(name)
        }
    }
}
```

---

### Q30: What is @autoclosure and when should you use it?

**Answer:**

```swift
// @autoclosure wraps expression in closure automatically
func log(_ message: @autoclosure () -> String, level: Int = 0) {
    guard level >= minimumLogLevel else { return }
    print(message())  // Expression evaluated only if needed
}

// Usage - looks like regular function call
log("User count: \(users.count)")  // Expensive operation deferred

// Implementing short-circuit evaluation
func &&(lhs: Bool, rhs: @autoclosure () -> Bool) -> Bool {
    guard lhs else { return false }
    return rhs()  // Only evaluated if lhs is true
}

// Assert implementation
func assert(_ condition: @autoclosure () -> Bool,
            _ message: @autoclosure () -> String = "",
            file: StaticString = #file,
            line: UInt = #line) {
    #if DEBUG
    if !condition() {
        fatalError(message(), file: file, line: line)
    }
    #endif
}

// Combining with @escaping
func delayedAssert(_ condition: @autoclosure @escaping () -> Bool) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        assert(condition())
    }
}
```

---

### Q31: Explain capture lists in detail

**Answer:**

```swift
// Capture list syntax
class Example {
    var value = 10
    
    func demonstrate() {
        // Capture by value (copy at creation time)
        let closure1 = { [value] in
            print(value)  // Always 10, even if self.value changes
        }
        
        // Capture by reference (weak)
        let closure2 = { [weak self] in
            guard let self = self else { return }
            print(self.value)  // Current value, nil-safe
        }
        
        // Capture by reference (unowned)
        let closure3 = { [unowned self] in
            print(self.value)  // Crashes if self is deallocated
        }
        
        // Multiple captures
        let other = OtherClass()
        let closure4 = { [weak self, weak other, value] in
            self?.process(other, with: value)
        }
        
        // Renaming captures
        let closure5 = { [localValue = self.value, owner = self] in
            print(localValue)
        }
    }
}

// Closure capture behavior
var counter = 0
var closures: [() -> Int] = []

for i in 0..<5 {
    closures.append { i }  // Captures reference, all return 4
}

for i in 0..<5 {
    closures.append { [i] in i }  // Captures value, returns 0,1,2,3,4
}
```

---

## Error Handling Patterns

### Q32: Explain typed throws in Swift

**Answer:**

```swift
// Swift 6.0+ typed throws
enum NetworkError: Error {
    case timeout
    case invalidResponse
    case serverError(code: Int)
}

func fetchData() throws(NetworkError) -> Data {
    guard let response = try? makeRequest() else {
        throw .timeout
    }
    
    guard response.isValid else {
        throw .invalidResponse
    }
    
    return response.data
}

// Caller knows exact error type
do {
    let data = try fetchData()
} catch .timeout {
    // Handle timeout
} catch .invalidResponse {
    // Handle invalid response  
} catch .serverError(let code) {
    // Handle server error
}

// Generic error propagation
func transform<E: Error>(_ operation: () throws(E) -> Data) throws(E) -> String {
    let data = try operation()
    return String(data: data, encoding: .utf8) ?? ""
}
```

---

### Q33: Implement Result type patterns

**Answer:**

```swift
// Result type for explicit error handling
enum APIError: Error {
    case invalidURL
    case networkFailure(Error)
    case decodingError(Error)
    case unauthorized
}

func fetchUser(id: String) async -> Result<User, APIError> {
    guard let url = URL(string: "https://api.example.com/users/\(id)") else {
        return .failure(.invalidURL)
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.networkFailure(URLError(.badServerResponse)))
        }
        
        guard httpResponse.statusCode != 401 else {
            return .failure(.unauthorized)
        }
        
        let user = try JSONDecoder().decode(User.self, from: data)
        return .success(user)
    } catch let error as DecodingError {
        return .failure(.decodingError(error))
    } catch {
        return .failure(.networkFailure(error))
    }
}

// Result transformation
extension Result {
    func mapBoth<NewSuccess, NewFailure>(
        success: (Success) -> NewSuccess,
        failure: (Failure) -> NewFailure
    ) -> Result<NewSuccess, NewFailure> {
        switch self {
        case .success(let value):
            return .success(success(value))
        case .failure(let error):
            return .failure(failure(error))
        }
    }
}

// Usage with async/await
let result = await fetchUser(id: "123")
switch result {
case .success(let user):
    print("User: \(user.name)")
case .failure(let error):
    handleError(error)
}
```

---

### Q34: How do you handle errors in async sequences?

**Answer:**

```swift
// Throwing async sequence
struct ThrowingDataStream: AsyncSequence {
    typealias Element = Data
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var index = 0
        
        mutating func next() async throws -> Data? {
            guard index < 10 else { return nil }
            defer { index += 1 }
            
            if index == 5 {
                throw StreamError.interrupted
            }
            
            return try await fetchChunk(index: index)
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}

// Consuming with error handling
func processStream() async {
    let stream = ThrowingDataStream()
    
    do {
        for try await data in stream {
            process(data)
        }
    } catch {
        handleStreamError(error)
    }
}

// Partial success pattern
func processWithPartialResults() async -> ([Data], Error?) {
    let stream = ThrowingDataStream()
    var results: [Data] = []
    
    do {
        for try await data in stream {
            results.append(data)
        }
        return (results, nil)
    } catch {
        return (results, error)
    }
}
```

---

### Q35: Implement a retry mechanism with exponential backoff

**Answer:**

```swift
// Retry configuration
struct RetryPolicy {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double
    
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 2.0
    )
}

// Retry implementation
func withRetry<T>(
    policy: RetryPolicy = .default,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    var delay = policy.initialDelay
    
    for attempt in 1...policy.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            if attempt < policy.maxAttempts {
                let jitter = Double.random(in: 0...0.3) * delay
                let sleepDuration = min(delay + jitter, policy.maxDelay)
                
                try await Task.sleep(nanoseconds: UInt64(sleepDuration * 1_000_000_000))
                delay = min(delay * policy.multiplier, policy.maxDelay)
            }
        }
    }
    
    throw lastError!
}

// Usage
func fetchWithRetry() async throws -> Data {
    try await withRetry(policy: .default) {
        try await networkRequest()
    }
}

// Conditional retry
func withConditionalRetry<T>(
    shouldRetry: (Error) -> Bool,
    operation: () async throws -> T
) async throws -> T {
    try await withRetry { 
        do {
            return try await operation()
        } catch where shouldRetry(error) {
            throw error
        } catch {
            throw RetryError.nonRetryable(error)
        }
    }
}
```

---

## Additional Advanced Topics

### Q36: Explain property wrappers in depth

**Answer:**

```swift
// Basic property wrapper
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>
    
    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
    
    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

// Usage
struct Settings {
    @Clamped(0...100) var volume: Int = 50
    @Clamped(0.0...1.0) var brightness: Double = 0.5
}

// Property wrapper with projected value
@propertyWrapper
struct Published<Value> {
    private var value: Value
    private let subject = PassthroughSubject<Value, Never>()
    
    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            subject.send(newValue)
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
}

// Accessing projected value with $
class ViewModel {
    @Published var count = 0
}

let vm = ViewModel()
vm.$count.sink { print($0) }  // Subscribe to changes
```

---

### Q37: What are result builders and how do they work?

**Answer:**

```swift
// Custom result builder
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

// Usage
func makeArray<T>(@ArrayBuilder<T> content: () -> [T]) -> [T] {
    content()
}

let numbers = makeArray {
    1
    2
    if true { 3 }
    for i in 4...6 { i }
}
// [1, 2, 3, 4, 5, 6]

// HTML DSL example
@resultBuilder
struct HTMLBuilder {
    static func buildBlock(_ components: String...) -> String {
        components.joined()
    }
}

func html(@HTMLBuilder content: () -> String) -> String {
    "<html>\(content())</html>"
}

func body(@HTMLBuilder content: () -> String) -> String {
    "<body>\(content())</body>"
}
```

---

### Q38: Explain existential types and their performance implications

**Answer:**

```swift
// Existential container (any Protocol)
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    func draw() { print("Circle") }
}

struct Square: Drawable {
    func draw() { print("Square") }
}

// Existential - type erased, heap allocated for large types
var shapes: [any Drawable] = [Circle(), Square()]

// Performance comparison
func useExistential(_ drawable: any Drawable) {
    drawable.draw()  // Dynamic dispatch via witness table
}

func useGeneric<T: Drawable>(_ drawable: T) {
    drawable.draw()  // Static dispatch, potentially inlined
}

// Existential container memory layout
// - 3 words for value buffer (inline if fits, otherwise heap pointer)
// - 1 word for type metadata
// - 1 word for protocol witness table

// When to use existentials:
// - Heterogeneous collections
// - Highly dynamic code
// - When protocol has associated types (with primary associated type)

// Protocol with primary associated type (Swift 5.7+)
protocol Collection<Element> {
    associatedtype Element
}

var intCollections: [any Collection<Int>] = []
```

---

### Q39: How do you implement custom operators in Swift?

**Answer:**

```swift
// Precedence group
precedencegroup ExponentiationPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: right
}

// Custom operator declaration
infix operator **: ExponentiationPrecedence
prefix operator √

// Implementation
func ** (base: Double, exponent: Double) -> Double {
    pow(base, exponent)
}

prefix func √ (value: Double) -> Double {
    sqrt(value)
}

// Usage
let result = 2 ** 3 ** 2  // 512 (right associative: 2^(3^2))
let root = √16  // 4.0

// Generic operator
infix operator ???: NilCoalescingPrecedence

func ???<T> (optional: T?, defaultValue: @autoclosure () throws -> T) rethrows -> T {
    if let value = optional {
        return value
    }
    return try defaultValue()
}

// Combining types with operators
struct Vector2D {
    var x: Double
    var y: Double
    
    static func + (lhs: Vector2D, rhs: Vector2D) -> Vector2D {
        Vector2D(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func * (vector: Vector2D, scalar: Double) -> Vector2D {
        Vector2D(x: vector.x * scalar, y: vector.y * scalar)
    }
    
    static prefix func - (vector: Vector2D) -> Vector2D {
        Vector2D(x: -vector.x, y: -vector.y)
    }
}
```

---

### Q40: What is the Swift calling convention and ABI stability?

**Answer:**

```swift
// ABI (Application Binary Interface) stability
// Since Swift 5.0, the ABI is stable on Apple platforms

// Benefits:
// 1. Swift runtime included in OS
// 2. Smaller app binaries
// 3. Framework compatibility across Swift versions

// Calling convention
// Swift uses its own calling convention, different from C

// @convention attribute
typealias SwiftClosure = () -> Void           // @convention(swift)
typealias CClosure = @convention(c) () -> Void
typealias BlockClosure = @convention(block) () -> Void

// Using C convention for callbacks
func registerCallback(_ callback: @convention(c) (Int32) -> Void) {
    // Can be passed to C functions
}

// Module stability (Library Evolution)
// @frozen - layout can't change
@frozen
public struct Point {
    public var x: Double
    public var y: Double
}

// Non-frozen (default) - layout can change between versions
public struct FlexiblePoint {
    public var x: Double
    public var y: Double
    // Future versions can add/reorder properties
}

// @inlinable for cross-module optimization
@inlinable
public func fastMath(_ x: Int) -> Int {
    x * 2 + 1
}
```

---

## Summary

This guide covers essential advanced Swift topics for senior iOS developer interviews:

| Category | Key Topics |
|----------|-----------|
| Memory Management | ARC, retain cycles, autorelease pools, COW |
| Concurrency | Actors, async/await, TaskGroup, Sendable |
| Generics | Associated types, type erasure, opaque types |
| Protocols | POP, composition, Self requirements |
| Performance | Profiling, collection performance, optimization |
| Runtime | Mirror, dynamic features, ABI |
| Closures | Escaping, autoclosure, capture lists |
| Error Handling | Typed throws, Result, retry patterns |

Practice implementing these patterns in real projects to solidify your understanding.

---

*Last updated: 2024*
