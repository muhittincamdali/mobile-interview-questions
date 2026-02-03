# 📱 Mobile Interview Questions

> **The Ultimate Mobile Developer Interview Preparation Guide** - Comprehensive collection of iOS, Android, Flutter, and React Native interview questions with detailed answers, code examples, and best practices.

[![CI](https://github.com/muhittinpalamutcu/mobile-interview-questions/actions/workflows/ci.yml/badge.svg)](https://github.com/muhittinpalamutcu/mobile-interview-questions/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Flutter%20%7C%20RN-blue.svg)]()
[![Questions](https://img.shields.io/badge/Questions-500%2B-orange.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [iOS Questions](#-ios-questions)
- [Android Questions](#-android-questions)
- [Flutter Questions](#-flutter-questions)
- [React Native Questions](#-react-native-questions)
- [Behavioral Questions](#-behavioral-questions)
- [Coding Challenges](#-coding-challenges)
- [System Design](#-system-design)
- [How to Use](#-how-to-use)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   📱 500+ Interview Questions                                    ║
║   🍎 iOS (Swift/UIKit/SwiftUI)                                  ║
║   🤖 Android (Kotlin/Jetpack Compose)                           ║
║   💙 Flutter (Dart)                                              ║
║   ⚛️  React Native (TypeScript)                                  ║
║                                                                  ║
║   ✅ Detailed Answers with Code Examples                         ║
║   ✅ Real Interview Scenarios                                    ║
║   ✅ FAANG-Level Questions                                       ║
║   ✅ Updated for 2024                                            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

This repository is designed to help mobile developers prepare for technical interviews at top tech companies. Each question includes:

- **Detailed explanation** of the concept
- **Code examples** demonstrating the solution
- **Common pitfalls** to avoid
- **Follow-up questions** interviewers might ask

---

## 🍎 iOS Questions

### Categories

| Category | Questions | Difficulty |
|----------|-----------|------------|
| [Swift Language](ios-questions/swift-language.md) | 50+ | 🟢🟡🔴 |
| [UIKit](ios-questions/uikit.md) | 40+ | 🟢🟡🔴 |
| [SwiftUI](ios-questions/swiftui.md) | 35+ | 🟢🟡🔴 |
| [Concurrency](ios-questions/concurrency.md) | 30+ | 🟡🔴 |
| [Memory Management](ios-questions/memory.md) | 25+ | 🟡🔴 |
| [Networking](ios-questions/networking.md) | 20+ | 🟢🟡 |
| [Architecture](ios-questions/architecture.md) | 25+ | 🟡🔴 |
| [Testing](ios-questions/testing.md) | 20+ | 🟡 |

### Sample Questions

<details>
<summary><b>Q: What is the difference between struct and class in Swift?</b></summary>

**Answer:**

| Feature | Struct | Class |
|---------|--------|-------|
| Type | Value type | Reference type |
| Inheritance | ❌ No | ✅ Yes |
| Deinitializer | ❌ No | ✅ Yes |
| Memory | Stack | Heap |
| Thread Safety | ✅ Safe by default | ⚠️ Needs synchronization |

```swift
// Struct - Value Type
struct Point {
    var x: Int
    var y: Int
}

var point1 = Point(x: 0, y: 0)
var point2 = point1  // Creates a copy
point2.x = 10
print(point1.x)  // 0 (unchanged)

// Class - Reference Type
class Person {
    var name: String
    init(name: String) { self.name = name }
}

let person1 = Person(name: "Alice")
let person2 = person1  // Same reference
person2.name = "Bob"
print(person1.name)  // "Bob" (changed!)
```

**When to use:**
- Use `struct` for simple data, value semantics, thread safety
- Use `class` for inheritance, reference semantics, identity

</details>

<details>
<summary><b>Q: Explain the Swift Actor model and data race safety</b></summary>

**Answer:**

Actors provide data race safety by serializing access to their mutable state.

```swift
actor BankAccount {
    private var balance: Double = 0
    
    func deposit(_ amount: Double) {
        balance += amount
    }
    
    func withdraw(_ amount: Double) async throws -> Double {
        guard balance >= amount else {
            throw BankError.insufficientFunds
        }
        balance -= amount
        return amount
    }
    
    var currentBalance: Double {
        balance
    }
}

// Usage
let account = BankAccount()
await account.deposit(100)
let withdrawn = try await account.withdraw(50)
```

**Key Points:**
- Actor methods are implicitly `async`
- Access from outside requires `await`
- Provides compile-time data race prevention
- Use `nonisolated` for thread-safe properties

</details>

<details>
<summary><b>Q: What are property wrappers and how do they work?</b></summary>

**Answer:**

Property wrappers encapsulate property access patterns:

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>
    
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

// Usage
struct Settings {
    @Clamped(0...100) var volume: Int = 50
    @Clamped(0.0...1.0) var brightness: Double = 0.5
}

var settings = Settings()
settings.volume = 150  // Clamped to 100
print(settings.volume)  // 100
print(settings.$volume)  // 0...100 (projected value)
```

</details>

---

## 🤖 Android Questions

### Categories

| Category | Questions | Difficulty |
|----------|-----------|------------|
| [Kotlin Fundamentals](android-questions/kotlin.md) | 45+ | 🟢🟡🔴 |
| [Jetpack Compose](android-questions/compose.md) | 35+ | 🟢🟡🔴 |
| [Android Lifecycle](android-questions/lifecycle.md) | 30+ | 🟡🔴 |
| [Coroutines & Flow](android-questions/coroutines.md) | 35+ | 🟡🔴 |
| [Architecture Components](android-questions/architecture.md) | 25+ | 🟡🔴 |
| [Dependency Injection](android-questions/di.md) | 20+ | 🟡 |

### Sample Questions

<details>
<summary><b>Q: Explain Kotlin Coroutines and how they differ from threads</b></summary>

**Answer:**

```kotlin
// Coroutines are lightweight concurrent primitives
suspend fun fetchUserData(): User {
    return withContext(Dispatchers.IO) {
        // Network call on IO dispatcher
        api.getUser()
    }
}

// Structured concurrency with CoroutineScope
class UserViewModel : ViewModel() {
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user.asStateFlow()
    
    fun loadUser(id: String) {
        viewModelScope.launch {
            try {
                val user = repository.getUser(id)
                _user.value = user
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
}
```

**Key Differences:**

| Aspect | Threads | Coroutines |
|--------|---------|------------|
| Memory | ~1MB stack | ~1KB |
| Blocking | Blocks thread | Suspends, doesn't block |
| Context Switch | OS-level, expensive | Library-level, cheap |
| Cancellation | Manual | Cooperative, built-in |

</details>

<details>
<summary><b>Q: How does Jetpack Compose handle state and recomposition?</b></summary>

**Answer:**

```kotlin
@Composable
fun Counter() {
    // State that triggers recomposition when changed
    var count by remember { mutableStateOf(0) }
    
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Count: $count",
            style = MaterialTheme.typography.headlineMedium
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = { count-- }) {
                Text("-")
            }
            Button(onClick = { count++ }) {
                Text("+")
            }
        }
    }
}

// State hoisting for better testability
@Composable
fun CounterStateless(
    count: Int,
    onIncrement: () -> Unit,
    onDecrement: () -> Unit
) {
    // UI only, no state management
}
```

**Recomposition Rules:**
- Only recompose when state changes
- Skip unchanged composables
- Use `remember` to survive recomposition
- Use `key` for list stability

</details>

---

## 💙 Flutter Questions

### Categories

| Category | Questions | Difficulty |
|----------|-----------|------------|
| [Dart Language](flutter-questions/dart.md) | 40+ | 🟢🟡🔴 |
| [Widget Lifecycle](flutter-questions/widgets.md) | 35+ | 🟢🟡 |
| [State Management](flutter-questions/state.md) | 30+ | 🟡🔴 |
| [Navigation](flutter-questions/navigation.md) | 20+ | 🟢🟡 |
| [Performance](flutter-questions/performance.md) | 25+ | 🟡🔴 |

### Sample Questions

<details>
<summary><b>Q: Explain the difference between StatelessWidget and StatefulWidget</b></summary>

**Answer:**

```dart
// StatelessWidget - Immutable, no internal state
class Greeting extends StatelessWidget {
  final String name;
  
  const Greeting({super.key, required this.name});
  
  @override
  Widget build(BuildContext context) {
    return Text('Hello, $name!');
  }
}

// StatefulWidget - Mutable state
class Counter extends StatefulWidget {
  const Counter({super.key});
  
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;
  
  void _increment() {
    setState(() {
      _count++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

**Lifecycle Methods:**
- `initState()` - Called once when state is created
- `didChangeDependencies()` - Called when dependencies change
- `build()` - Called every time widget needs to render
- `didUpdateWidget()` - Called when parent rebuilds
- `dispose()` - Called when state is removed

</details>

---

## ⚛️ React Native Questions

### Categories

| Category | Questions | Difficulty |
|----------|-----------|------------|
| [React Fundamentals](react-native-questions/react.md) | 40+ | 🟢🟡 |
| [Native Modules](react-native-questions/native.md) | 25+ | 🟡🔴 |
| [Navigation](react-native-questions/navigation.md) | 20+ | 🟢🟡 |
| [Performance](react-native-questions/performance.md) | 25+ | 🟡🔴 |

### Sample Questions

<details>
<summary><b>Q: How do React hooks work and what are the rules?</b></summary>

**Answer:**

```typescript
// Custom hook for API data
function useApi<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  
  useEffect(() => {
    let cancelled = false;
    
    async function fetchData() {
      try {
        const response = await fetch(url);
        const json = await response.json();
        if (!cancelled) {
          setData(json);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e as Error);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }
    
    fetchData();
    
    return () => {
      cancelled = true;
    };
  }, [url]);
  
  return { data, loading, error };
}

// Usage
function UserProfile({ userId }: { userId: string }) {
  const { data: user, loading, error } = useApi<User>(`/api/users/${userId}`);
  
  if (loading) return <ActivityIndicator />;
  if (error) return <Text>Error: {error.message}</Text>;
  if (!user) return null;
  
  return <Text>{user.name}</Text>;
}
```

**Rules of Hooks:**
1. Only call hooks at the top level
2. Only call hooks from React functions
3. Custom hooks must start with "use"

</details>

---

## 🤝 Behavioral Questions

### Common Interview Questions

| Question | Category | Tips |
|----------|----------|------|
| Tell me about yourself | Introduction | 2-min elevator pitch |
| Why this company? | Motivation | Research the company |
| Describe a challenging project | Experience | Use STAR method |
| How do you handle conflicts? | Teamwork | Show resolution skills |
| Where do you see yourself in 5 years? | Career | Show ambition + realism |

### STAR Method Framework

```
╔══════════════════════════════════════════════════════════════╗
║  S - Situation: Set the context                              ║
║  T - Task: Describe your responsibility                      ║
║  A - Action: Explain what you did                            ║
║  R - Result: Share the outcome (with metrics!)               ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 💻 Coding Challenges

### Data Structures & Algorithms

| Topic | Questions | LeetCode Level |
|-------|-----------|----------------|
| Arrays & Strings | 25+ | Easy-Medium |
| Linked Lists | 15+ | Easy-Medium |
| Trees & Graphs | 20+ | Medium-Hard |
| Dynamic Programming | 15+ | Medium-Hard |
| System Design | 10+ | Hard |

### Mobile-Specific Challenges

```swift
// Challenge: Implement a simple LRU Cache
class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var order: [Key] = []
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        guard let value = cache[key] else { return nil }
        
        // Move to end (most recently used)
        order.removeAll { $0 == key }
        order.append(key)
        
        return value
    }
    
    func put(_ key: Key, _ value: Value) {
        if cache[key] != nil {
            order.removeAll { $0 == key }
        } else if cache.count >= capacity {
            // Remove least recently used
            if let lruKey = order.first {
                cache.removeValue(forKey: lruKey)
                order.removeFirst()
            }
        }
        
        cache[key] = value
        order.append(key)
    }
}
```

---

## 🏗️ System Design

### Mobile Architecture Patterns

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Views  │  │ViewModels│  │Presenters│  │Controllers│       │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       └────────────┴────────────┴────────────┘              │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Use Cases  │  │   Entities  │  │ Repositories │         │
│  │ (Interactors)│  │   (Models)  │  │ (Interfaces) │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Network   │  │   Database  │  │    Cache    │         │
│  │   Service   │  │   Service   │  │   Service   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### Design Interview Topics

- Offline-first architecture
- Real-time messaging system
- Image loading & caching
- Push notification system
- Authentication flow
- Analytics pipeline

---

## 📖 How to Use

### Study Plan

| Week | Focus Area | Hours/Day |
|------|------------|-----------|
| 1 | Platform fundamentals | 2-3 |
| 2 | Architecture & patterns | 2-3 |
| 3 | Concurrency & networking | 2-3 |
| 4 | Coding challenges | 3-4 |
| 5 | System design | 2-3 |
| 6 | Behavioral + mock interviews | 2-3 |

### Tips for Success

1. **Practice coding daily** - Consistency beats intensity
2. **Explain your thought process** - Communication matters
3. **Ask clarifying questions** - Shows thoroughness
4. **Test your code** - Walk through examples
5. **Learn from mistakes** - Review rejected solutions

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-questions`)
3. Add your questions with detailed answers
4. Submit a pull request

### Question Format

```markdown
## Q: [Your Question]

**Difficulty:** 🟢 Easy | 🟡 Medium | 🔴 Hard

**Answer:**

[Detailed explanation]

```[language]
// Code example
```

**Key Points:**
- Point 1
- Point 2

**Follow-up Questions:**
- Follow-up 1
- Follow-up 2
```

---

## 📚 Resources

### Books

| Book | Author | Platform |
|------|--------|----------|
| iOS Programming | Big Nerd Ranch | iOS |
| Kotlin in Action | Dmitry Jemerov | Android |
| Flutter in Action | Eric Windmill | Flutter |
| React Native in Action | Nader Dabit | React Native |

### Online Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Android Developers](https://developer.android.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [React Native Docs](https://reactnative.dev/docs/getting-started)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ Star History

If this repository helped you prepare for interviews, consider giving it a star! ⭐

---

<p align="center">
  <b>Good luck with your interviews! 🚀</b>
</p>

<p align="center">
  Made with ❤️ for the mobile developer community
</p>
