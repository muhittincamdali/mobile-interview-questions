<p align="center">
  <img src="Assets/banner.png" alt="Mobile Interview Questions" width="800"/>
</p>

<h1 align="center">Mobile Interview Questions</h1>

<p align="center">
  <strong>🎯 18 Mobile developer interview questions & answers for iOS, Flutter & React Native</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/muhittincamdali/mobile-interview-questions?style=flat-square" alt="Stars"/>
  <img src="https://img.shields.io/github/forks/muhittincamdali/mobile-interview-questions?style=flat-square" alt="Forks"/>
  <img src="https://img.shields.io/badge/questions-18-blue?style=flat-square" alt="Questions"/>
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square" alt="PRs Welcome"/>
</p>

<p align="center">
  <a href="#ios">iOS</a> •
  <a href="#swift">Swift</a> •
  <a href="#flutter">Flutter</a> •
  <a href="#react-native">React Native</a> •
  <a href="#system-design">System Design</a>
</p>

---

## 📋 Table of Contents

- [iOS & Swift](#ios--swift)
  - [Swift Fundamentals](#swift-fundamentals)
  - [Memory Management](#memory-management)
  - [Concurrency](#concurrency)
  - [SwiftUI](#swiftui)
  - [UIKit](#uikit)
  - [Networking](#networking)
  - [Core Data](#core-data)
  - [Testing](#testing)
- [Flutter & Dart](#flutter--dart)
- [React Native](#react-native)
- [System Design](#system-design)
- [Behavioral](#behavioral)
- [Coding Challenges](#coding-challenges)
- [Contributing](#contributing)
- [License](#license)
- [Star History](#-star-history)

---

## iOS & Swift

### Swift Fundamentals

<details>
<summary><b>What is the difference between `let` and `var`?</b></summary>

- `let` declares a constant (immutable)
- `var` declares a variable (mutable)

```swift
let constant = "Cannot change"
var variable = "Can change"
variable = "Changed!"
```

**Follow-up:** Can you modify properties of a `let` class instance?
- Yes, because `let` means the reference is constant, not the object itself.
</details>

<details>
<summary><b>What is the difference between `struct` and `class`?</b></summary>

| Feature | Struct | Class |
|---------|--------|-------|
| Type | Value | Reference |
| Inheritance | ❌ | ✅ |
| Default init | ✅ memberwise | ❌ |
| ARC | ❌ | ✅ |
| Mutating | Need `mutating` | Not needed |

**When to use struct:**
- Data containers
- Immutability preferred
- No inheritance needed
- Thread safety important

**When to use class:**
- Identity matters
- Inheritance needed
- Reference semantics needed
</details>

<details>
<summary><b>Explain optionals and unwrapping methods</b></summary>

```swift
var name: String? = "John"

// 1. Force unwrap (dangerous)
let unwrapped = name!

// 2. Optional binding
if let safeName = name {
    print(safeName)
}

// 3. Guard
guard let safeName = name else { return }

// 4. Nil coalescing
let result = name ?? "Default"

// 5. Optional chaining
let length = name?.count
```
</details>

<details>
<summary><b>What are property wrappers?</b></summary>

Property wrappers add custom behavior to properties:

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    var wrappedValue: Value {
        didSet { wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound) }
    }
    let range: ClosedRange<Value>
}

struct Player {
    @Clamped(range: 0...100) var health: Int = 100
}
```

Common wrappers: `@State`, `@Published`, `@AppStorage`
</details>

<details>
<summary><b>Explain protocol-oriented programming</b></summary>

```swift
protocol Drawable {
    func draw()
}

extension Drawable {
    func draw() { print("Default drawing") }
}

struct Circle: Drawable {
    func draw() { print("Drawing circle") }
}

// Protocol composition
typealias Displayable = Drawable & CustomStringConvertible
```

**Benefits:**
- Composition over inheritance
- Value type support
- Default implementations
- Multiple conformance
</details>

### Memory Management

<details>
<summary><b>Explain ARC (Automatic Reference Counting)</b></summary>

ARC automatically manages memory by tracking reference counts:

```swift
class Person {
    let name: String
    init(name: String) { self.name = name }
    deinit { print("\(name) deinitialized") }
}

var person1: Person? = Person(name: "John") // RC = 1
var person2 = person1 // RC = 2
person1 = nil // RC = 1
person2 = nil // RC = 0 -> deinit called
```
</details>

<details>
<summary><b>What are strong, weak, and unowned references?</b></summary>

```swift
class Parent {
    var child: Child?
}

class Child {
    weak var parent: Parent? // Prevents retain cycle
    unowned let owner: Parent // Non-optional, assumes always valid
}
```

| Type | Reference Count | Optional | Use Case |
|------|-----------------|----------|----------|
| strong | +1 | N/A | Default |
| weak | 0 | Yes | Delegates, parent refs |
| unowned | 0 | No | Known valid lifetime |
</details>

<details>
<summary><b>How do you avoid retain cycles in closures?</b></summary>

```swift
class ViewModel {
    var data: String = ""
    
    func load() {
        // ❌ Retain cycle
        networkCall { self.data = $0 }
        
        // ✅ Weak self
        networkCall { [weak self] result in
            self?.data = result
        }
        
        // ✅ Unowned (if guaranteed valid)
        networkCall { [unowned self] result in
            self.data = result
        }
    }
}
```
</details>

### Concurrency

<details>
<summary><b>Explain async/await in Swift</b></summary>

```swift
// Async function
func fetchUser() async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Calling async function
Task {
    do {
        let user = try await fetchUser()
        // Use user
    } catch {
        // Handle error
    }
}
```
</details>

<details>
<summary><b>What is an actor?</b></summary>

Actors provide data isolation for safe concurrent access:

```swift
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
}

// Usage (must await)
let account = BankAccount()
await account.deposit(100)
```
</details>

<details>
<summary><b>Explain @MainActor</b></summary>

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var data: [Item] = []
    
    func load() async {
        // This runs on main thread automatically
        data = await fetchData()
    }
}

// Or for specific code
await MainActor.run {
    self.updateUI()
}
```
</details>

### SwiftUI

<details>
<summary><b>What is the difference between @State, @Binding, @StateObject, @ObservedObject?</b></summary>

| Wrapper | Ownership | Type | Use |
|---------|-----------|------|-----|
| @State | View owns | Value | Simple local state |
| @Binding | Reference | Value | Pass state down |
| @StateObject | View creates | Reference | Create ObservableObject |
| @ObservedObject | External | Reference | Injected ObservableObject |

```swift
struct ParentView: View {
    @State private var count = 0  // Owns the state
    @StateObject var viewModel = ViewModel()  // Creates and owns
    
    var body: some View {
        ChildView(count: $count)  // Passes binding
    }
}

struct ChildView: View {
    @Binding var count: Int  // References parent's state
    @ObservedObject var vm: ViewModel  // Doesn't own
}
```
</details>

### Networking

<details>
<summary><b>How do you make network requests in iOS?</b></summary>

```swift
// Modern async/await approach
func fetchUsers() async throws -> [User] {
    let url = URL(string: "https://api.example.com/users")!
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NetworkError.invalidResponse
    }
    
    return try JSONDecoder().decode([User].self, from: data)
}
```
</details>

---

## Flutter & Dart

<details>
<summary><b>What is the difference between StatelessWidget and StatefulWidget?</b></summary>

```dart
// Immutable - rebuild with new data
class Greeting extends StatelessWidget {
  final String name;
  const Greeting({required this.name});
  
  @override
  Widget build(BuildContext context) => Text('Hello $name');
}

// Mutable - internal state
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;
  
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('Count: $count'),
    );
  }
}
```
</details>

<details>
<summary><b>Explain Flutter's widget lifecycle</b></summary>

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();  // Called once
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();  // After initState, on dependency change
  }
  
  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);  // Parent rebuilds
  }
  
  @override
  void dispose() {
    super.dispose();  // Cleanup
  }
}
```
</details>

---

## System Design

<details>
<summary><b>Design a social media feed (like Instagram)</b></summary>

### Requirements
- Infinite scrolling feed
- Image/video posts
- Likes, comments
- Real-time updates

### Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Feed API  │───►│  CDN/Cache  │───►│   Client    │
└─────────────┘    └─────────────┘    └─────────────┘
       │
       ▼
┌─────────────┐    ┌─────────────┐
│  Database   │───►│  Search/ML  │
└─────────────┘    └─────────────┘
```

### Key Decisions
- Pagination: Cursor-based (not offset)
- Caching: In-memory + disk
- Images: Progressive loading, CDN
- Real-time: WebSocket for updates
</details>

---

## Coding Challenges

<details>
<summary><b>Reverse a linked list</b></summary>

```swift
func reverseList(_ head: ListNode?) -> ListNode? {
    var prev: ListNode? = nil
    var current = head
    
    while current != nil {
        let next = current?.next
        current?.next = prev
        prev = current
        current = next
    }
    
    return prev
}
```
</details>

<details>
<summary><b>Check if a string is a palindrome</b></summary>

```swift
func isPalindrome(_ s: String) -> Bool {
    let chars = s.lowercased().filter { $0.isLetter || $0.isNumber }
    return chars == String(chars.reversed())
}
```
</details>

---

## Study Plan

### Week 1-2: Fundamentals
- [ ] Swift/Dart basics
- [ ] Memory management
- [ ] Data structures

### Week 3-4: Platform
- [ ] UIKit/SwiftUI or Flutter widgets
- [ ] Networking
- [ ] Persistence

### Week 5-6: Advanced
- [ ] Architecture patterns
- [ ] System design
- [ ] Performance

### Week 7-8: Practice
- [ ] LeetCode (2/day)
- [ ] Mock interviews
- [ ] Project review

---

## Contributing

Add questions via PR! See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License

---

<p align="center">
  <sub>Good luck with your interviews! 🍀</sub>
</p>

---

## 📈 Star History

<a href="https://star-history.com/#muhittincamdali/mobile-interview-questions&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/mobile-interview-questions&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/mobile-interview-questions&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muhittincamdali/mobile-interview-questions&type=Date" />
 </picture>
</a>
