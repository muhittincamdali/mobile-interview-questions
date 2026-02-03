<div align="center">

```
╔═════════════════════════════════════════════════════════════════════════════════╗
║  __  __       _     _ _        ___       _                 _                    ║
║ |  \/  | ___ | |__ (_) | ___  |_ _|_ __ | |_ ___ _ ____   _(_) _____      __    ║
║ | |\/| |/ _ \| '_ \| | |/ _ \  | || '_ \| __/ _ \ '__\ \ / / |/ _ \ \ /\ / /    ║
║ | |  | | (_) | |_) | | |  __/  | || | | | ||  __/ |   \ V /| |  __/\ V  V /     ║
║ |_|  |_|\___/|_.__/|_|_|\___| |___|_| |_|\__\___|_|    \_/ |_|\___| \_/\_/      ║
║                                                                                  ║
║   ___                  _   _                                                    ║
║  / _ \ _   _  ___  ___| |_(_) ___  _ __  ___                                    ║
║ | | | | | | |/ _ \/ __| __| |/ _ \| '_ \/ __|                                   ║
║ | |_| | |_| |  __/\__ \ |_| | (_) | | | \__ \                                   ║
║  \__\_\\__,_|\___||___/\__|_|\___/|_| |_|___/                                   ║
║                                                                                  ║
╚═════════════════════════════════════════════════════════════════════════════════╝
```

# Mobile Interview Questions

**A comprehensive collection of iOS and Android interview questions with answers**

[![Interview](https://img.shields.io/badge/Interview-Prep-red?style=flat-square)](https://github.com/muhittincamdali/mobile-interview-questions)
[![iOS](https://img.shields.io/badge/iOS-Questions-orange?style=flat-square&logo=apple)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-Questions-green?style=flat-square&logo=android)](https://developer.android.com)
![GitHub stars](https://img.shields.io/github/stars/muhittincamdali/mobile-interview-questions?style=flat-square&color=yellow)
![GitHub forks](https://img.shields.io/github/forks/muhittincamdali/mobile-interview-questions?style=flat-square)
![GitHub last commit](https://img.shields.io/github/last-commit/muhittincamdali/mobile-interview-questions?style=flat-square&color=blue)
![GitHub contributors](https://img.shields.io/github/contributors/muhittincamdali/mobile-interview-questions?style=flat-square&color=green)
[![License](https://img.shields.io/github/license/muhittincamdali/mobile-interview-questions?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

[iOS Questions](#-ios-questions) •
[Android Questions](#-android-questions) •
[System Design](#-system-design) •
[Behavioral](#-behavioral-questions)

</div>

---

## 📖 Overview

Prepare for your next mobile developer interview with this comprehensive question bank. Covers iOS, Android, system design, and behavioral questions from junior to senior levels.

## 📑 Table of Contents

- [Overview](#-overview)
- [How to Use](#-how-to-use)
- [iOS Questions](#-ios-questions)
- [Android Questions](#-android-questions)
- [System Design](#-system-design)
- [Behavioral Questions](#-behavioral-questions)
- [Contributing](#-contributing)

## 🎯 How to Use

| Level | Icon | Description |
|-------|------|-------------|
| Junior | 🟢 | Entry-level (0-2 years) |
| Mid | 🟡 | Intermediate (2-5 years) |
| Senior | 🔴 | Advanced (5+ years) |

## 🍎 iOS Questions

### Swift Fundamentals

#### 🟢 What is the difference between `let` and `var`?

**Answer**: `let` declares a constant (immutable), `var` declares a variable (mutable). Use `let` by default for safety.

```swift
let name = "John"  // Cannot be changed
var age = 25       // Can be changed
```

---

#### 🟢 What are optionals in Swift?

**Answer**: Optionals represent a value that may or may not exist. They're declared with `?` and must be unwrapped to access the value.

```swift
var name: String? = nil
name = "John"

// Safe unwrapping
if let unwrapped = name {
    print(unwrapped)
}
```

---

#### 🟡 Explain ARC (Automatic Reference Counting)

**Answer**: ARC automatically manages memory by tracking references to class instances. It deallocates instances when the reference count reaches zero.

**Key concepts**:
- Strong references (default)
- Weak references (`weak`)
- Unowned references (`unowned`)

---

#### 🟡 What are closures and how do they capture values?

**Answer**: Closures are self-contained blocks of functionality. They capture and store references to variables from their surrounding context.

```swift
func makeCounter() -> () -> Int {
    var count = 0
    return {
        count += 1
        return count
    }
}
```

---

#### 🔴 Explain Swift Concurrency (async/await)

**Answer**: Swift Concurrency provides structured concurrency with:
- `async` functions that can suspend
- `await` to call async functions
- `Task` for concurrent execution
- `Actor` for thread-safe state

```swift
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

---

### Architecture & Design

#### 🟡 Compare MVC, MVP, and MVVM

| Pattern | View-Model Communication | Testing | Complexity |
|---------|-------------------------|---------|------------|
| MVC | Direct | Hard | Low |
| MVP | Through Presenter | Medium | Medium |
| MVVM | Data Binding | Easy | Medium |

---

#### 🔴 What is Clean Architecture?

**Answer**: Clean Architecture separates concerns into layers:
- **Entities**: Business models
- **Use Cases**: Business logic
- **Interface Adapters**: ViewModels, Presenters
- **Frameworks**: UI, DB, Network

Dependencies point inward; inner layers don't know about outer layers.

---

## 🤖 Android Questions

### Kotlin Fundamentals

#### 🟢 What are data classes in Kotlin?

**Answer**: Data classes automatically generate `equals()`, `hashCode()`, `toString()`, and `copy()` methods.

```kotlin
data class User(val name: String, val age: Int)
```

---

#### 🟡 Explain coroutines and their scopes

**Answer**: Coroutines are lightweight threads for async programming.

**Scopes**:
- `GlobalScope`: Application lifetime
- `viewModelScope`: ViewModel lifetime
- `lifecycleScope`: Lifecycle-aware

```kotlin
viewModelScope.launch {
    val data = repository.fetchData()
    _state.value = data
}
```

---

#### 🔴 How does Jetpack Compose handle state?

**Answer**: Compose uses unidirectional data flow:
- State flows down (props)
- Events flow up (callbacks)
- `remember` for local state
- `MutableState` for reactive updates

```kotlin
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }
    Button(onClick = { count++ }) {
        Text("Count: $count")
    }
}
```

---

## 🏗️ System Design

#### 🔴 Design a social media feed

**Key considerations**:
- Infinite scrolling with pagination
- Image caching strategy
- Offline support
- Pull-to-refresh
- Optimistic updates

---

#### 🔴 Design an offline-first app

**Architecture**:
```
Remote API → Repository → Local DB → ViewModel → UI
                ↑___________↓ (Sync)
```

---

## 💬 Behavioral Questions

#### Tell me about a challenging bug you solved

**Framework (STAR)**:
- **Situation**: Context
- **Task**: Your responsibility
- **Action**: What you did
- **Result**: Outcome

---

#### How do you stay updated with mobile development?

**Good answers include**:
- WWDC/Google I/O sessions
- Official documentation
- Tech blogs and newsletters
- Side projects
- Community involvement

## 🤝 Contributing

Have questions to add? See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 👤 Author

**Muhittin Camdali**
- GitHub: [@muhittincamdali](https://github.com/muhittincamdali)

---

<div align="center">

### ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=muhittincamdali/mobile-interview-questions&type=Date)](https://star-history.com/#muhittincamdali/mobile-interview-questions&Date)

**Good luck with your interviews! ⭐ Star if this helped!**

</div>
