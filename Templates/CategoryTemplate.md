# 📂 Category Template

> Use this template when creating a new question category file.

---

## Template Structure

```markdown
# [Category Icon] [Category Name]

> Brief description of what this category covers and why it's important for interviews.

[![Questions](https://img.shields.io/badge/Questions-XX-blue)]()
[![Last Updated](https://img.shields.io/badge/Updated-YYYY--MM--DD-green)]()

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Topic 1](#topic-1)
- [Topic 2](#topic-2)
- [Topic 3](#topic-3)
- [Practice Exercises](#-practice-exercises)
- [Resources](#-resources)

---

## 🎯 Overview

[2-3 paragraph overview of the category]

### What Interviewers Look For

- [ ] Understanding 1
- [ ] Understanding 2
- [ ] Understanding 3

### Key Concepts

| Concept | Description | Difficulty |
|---------|-------------|------------|
| Concept 1 | Brief description | 🟢 Easy |
| Concept 2 | Brief description | 🟡 Medium |
| Concept 3 | Brief description | 🔴 Hard |

---

## Topic 1

### Q1: [Question Title]

**Difficulty:** 🟢 Easy

**Answer:**

[Answer text]

```language
// Code example
```

**Key Points:**
- Point 1
- Point 2

---

### Q2: [Question Title]

**Difficulty:** 🟡 Medium

**Answer:**

[Answer text]

```language
// Code example
```

**Key Points:**
- Point 1
- Point 2

---

## Topic 2

[Continue with more questions...]

---

## 📝 Practice Exercises

### Exercise 1: [Exercise Name]

**Task:** [Description of what to build/implement]

**Requirements:**
- Requirement 1
- Requirement 2
- Requirement 3

**Hints:**
<details>
<summary>Hint 1</summary>
[Hint content]
</details>

<details>
<summary>Solution</summary>

```language
// Solution code
```

</details>

---

## 📚 Resources

### Official Documentation

- [Doc 1](url)
- [Doc 2](url)

### Recommended Reading

- [Article 1](url)
- [Article 2](url)

### Videos

- [Video 1](url)
- [Video 2](url)

---

## ✅ Mastery Checklist

Before moving to the next category, ensure you can:

- [ ] Explain concept 1 clearly
- [ ] Implement concept 2 from scratch
- [ ] Debug common issues with concept 3
- [ ] Answer follow-up questions about trade-offs

---

<p align="center">
  <b>Happy Studying! 📖</b>
</p>
```

---

## Example: Swift Concurrency Category

```markdown
# ⚡ Swift Concurrency

> Master modern Swift concurrency with async/await, actors, and structured concurrency - essential for any iOS interview.

[![Questions](https://img.shields.io/badge/Questions-30-blue)]()
[![Last Updated](https://img.shields.io/badge/Updated-2024--01--15-green)]()

---

## 📋 Table of Contents

- [Overview](#-overview)
- [async/await Basics](#asyncawait-basics)
- [Task and TaskGroup](#task-and-taskgroup)
- [Actors](#actors)
- [Continuations](#continuations)
- [Practice Exercises](#-practice-exercises)
- [Resources](#-resources)

---

## 🎯 Overview

Swift Concurrency, introduced in Swift 5.5, provides a modern, safe way to write concurrent code. It replaces many uses of Grand Central Dispatch with a more ergonomic and safer API.

### What Interviewers Look For

- [ ] Understanding of async/await mechanics
- [ ] Knowledge of actor isolation
- [ ] Ability to prevent data races
- [ ] Understanding of structured concurrency
- [ ] Migration strategies from GCD

### Key Concepts

| Concept | Description | Difficulty |
|---------|-------------|------------|
| async/await | Basic asynchronous functions | 🟢 Easy |
| Task | Unit of asynchronous work | 🟢 Easy |
| TaskGroup | Concurrent task execution | 🟡 Medium |
| Actor | Data race protection | 🟡 Medium |
| Sendable | Thread-safe types | 🟡 Medium |
| Continuation | Bridging legacy APIs | 🔴 Hard |
| Actor isolation | Deep isolation rules | 🔴 Hard |

---

## async/await Basics

### Q1: What is async/await and how does it differ from completion handlers?

**Difficulty:** 🟢 Easy

**Answer:**

`async/await` is Swift's native concurrency model that makes asynchronous code look and behave like synchronous code.

| Aspect | Completion Handlers | async/await |
|--------|--------------------| ------------|
| Readability | Nested callbacks | Linear flow |
| Error handling | Multiple paths | try/catch |
| Control flow | Complex | Natural |
| Cancellation | Manual | Cooperative |

```swift
// Completion handler approach (before)
func fetchUser(completion: @escaping (Result<User, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            completion(.success(user))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// async/await approach (after)
func fetchUser() async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}
```

**Key Points:**
- `async` marks a function as asynchronous
- `await` marks a suspension point
- Errors are thrown naturally with `throws`
- Code reads top to bottom

---

### Q2: What happens at an await point?

**Difficulty:** 🟡 Medium

**Answer:**

At an await point, the function may suspend and allow other code to run. The key behaviors are:

1. **Suspension**: The function yields control back to the system
2. **No thread blocking**: The thread is freed to do other work
3. **Resumption**: The function resumes when the async operation completes
4. **Potentially different thread**: May resume on a different thread

```swift
func processData() async {
    print("Before await - Thread: \(Thread.current)")
    
    // ⚠️ This is a suspension point
    let data = await fetchData()
    
    // May be on a different thread!
    print("After await - Thread: \(Thread.current)")
}
```

**Key Points:**
- State may change across await
- Instance properties might have new values
- Always check assumptions after await
- Use actors for thread-safe state

---

## Actors

### Q5: What is an actor and how does it prevent data races?

**Difficulty:** 🟡 Medium

**Answer:**

An actor is a reference type that protects its mutable state by serializing access to it.

```swift
actor BankAccount {
    private var balance: Decimal = 0
    
    func deposit(_ amount: Decimal) {
        balance += amount
    }
    
    func withdraw(_ amount: Decimal) async throws -> Decimal {
        guard balance >= amount else {
            throw BankError.insufficientFunds
        }
        balance -= amount
        return amount
    }
    
    var currentBalance: Decimal {
        balance
    }
}

// Usage
let account = BankAccount()

// Must use await from outside the actor
await account.deposit(100)
let withdrawn = try await account.withdraw(50)
let balance = await account.currentBalance
```

**Key Points:**
- Actor methods are implicitly `async` when called externally
- Only one task can execute actor code at a time
- Internal synchronous methods don't need `await`
- Compile-time data race prevention

---

## 📝 Practice Exercises

### Exercise 1: Convert Callback to async/await

**Task:** Convert this callback-based function to async/await

```swift
func loadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        if let data = data, let image = UIImage(data: data) {
            completion(image)
        } else {
            completion(nil)
        }
    }.resume()
}
```

<details>
<summary>Solution</summary>

```swift
func loadImage(url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }
    return image
}
```

</details>

---

## 📚 Resources

### Official Documentation

- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Updating an App to Use Swift Concurrency](https://developer.apple.com/documentation/swift/updating-an-app-to-use-swift-concurrency)

### WWDC Videos

- [Meet Swift Concurrency](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)

---

## ✅ Mastery Checklist

- [ ] Can convert callback-based code to async/await
- [ ] Understand when and why to use actors
- [ ] Know the difference between Task and TaskGroup
- [ ] Can use continuations to bridge legacy APIs
- [ ] Understand Sendable and why it matters

---

<p align="center">
  <b>Master Concurrency, Master the Interview! 🚀</b>
</p>
```

---

## Checklist for New Category

- [ ] Clear, descriptive title
- [ ] Overview explains importance
- [ ] Table of contents included
- [ ] Questions organized by subtopic
- [ ] Difficulty progression (easy → hard)
- [ ] Code examples for each answer
- [ ] Practice exercises included
- [ ] Resources linked
- [ ] Mastery checklist at end
- [ ] Consistent formatting throughout

---

<p align="center">
  <b>Thank you for expanding our question library! 🙏</b>
</p>
