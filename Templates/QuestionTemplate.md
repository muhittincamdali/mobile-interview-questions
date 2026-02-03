# 📝 Question Template

> Use this template when adding new interview questions to the repository.

---

## Template Structure

```markdown
## Q: [Question Title]

**Difficulty:** 🟢 Easy | 🟡 Medium | 🔴 Hard
**Platform:** iOS | Android | Flutter | React Native | Cross-platform
**Category:** [Category name]
**Tags:** `tag1`, `tag2`, `tag3`

### Question

[Full question text - be specific and clear]

### Answer

[Comprehensive answer with explanation]

### Code Example

```[language]
// Well-commented code example
// Include imports if necessary
```

### Key Points

- **Point 1**: Explanation
- **Point 2**: Explanation
- **Point 3**: Explanation

### Common Mistakes

❌ **Mistake 1**: Description
✅ **Correct approach**: Description

❌ **Mistake 2**: Description
✅ **Correct approach**: Description

### Follow-up Questions

1. [Follow-up question 1]
2. [Follow-up question 2]
3. [Follow-up question 3]

### References

- [Official Documentation](url)
- [Related Article](url)

---
```

---

## Example: Swift Question

```markdown
## Q: What is the difference between `weak` and `unowned` references in Swift?

**Difficulty:** 🟡 Medium
**Platform:** iOS, macOS
**Category:** Memory Management
**Tags:** `swift`, `arc`, `memory`, `retain-cycle`

### Question

Explain the difference between `weak` and `unowned` references in Swift. When would you use each one, and what are the potential risks?

### Answer

Both `weak` and `unowned` are used to break retain cycles in Swift's Automatic Reference Counting (ARC) system, but they behave differently:

| Aspect | weak | unowned |
|--------|------|---------|
| Optional | Yes (always optional) | No (non-optional) |
| Nil handling | Becomes nil when deallocated | Crashes if accessed after deallocation |
| Use case | Reference may become nil | Reference will never be nil while in use |
| Performance | Slight overhead (nil checking) | Slightly faster |

### Code Example

```swift
// WEAK - Use when the reference may become nil
class Person {
    let name: String
    var apartment: Apartment?
    
    init(name: String) { self.name = name }
    deinit { print("\(name) is being deinitialized") }
}

class Apartment {
    let unit: String
    weak var tenant: Person?  // Tenant may move out
    
    init(unit: String) { self.unit = unit }
    deinit { print("Apartment \(unit) is being deinitialized") }
}

// UNOWNED - Use when reference will always be valid
class Customer {
    let name: String
    var card: CreditCard?
    
    init(name: String) { self.name = name }
    deinit { print("\(name) is being deinitialized") }
}

class CreditCard {
    let number: UInt64
    unowned let customer: Customer  // Card can't exist without customer
    
    init(number: UInt64, customer: Customer) {
        self.number = number
        self.customer = customer
    }
    deinit { print("Card #\(number) is being deinitialized") }
}
```

### Key Points

- **Use `weak`**: When the referenced object can become nil during the lifetime of the reference holder
- **Use `unowned`**: When you're certain the referenced object will never be nil while the reference holder exists
- **Retain cycles**: Both break retain cycles, but incorrect usage of `unowned` can cause crashes
- **Closures**: Be especially careful with closures capturing `self`

### Common Mistakes

❌ **Mistake 1**: Using `unowned` when the reference can become nil
✅ **Correct approach**: Use `weak` if there's any possibility the reference could become nil

❌ **Mistake 2**: Using `weak` everywhere "to be safe"
✅ **Correct approach**: Use `unowned` when semantically appropriate for better performance and cleaner code

❌ **Mistake 3**: Forgetting to use `[weak self]` in closures
✅ **Correct approach**: Always consider capture semantics in closures

### Follow-up Questions

1. How does ARC differ from garbage collection?
2. What is a retain cycle and how do you detect one?
3. When would you use `unowned(unsafe)`?
4. How do actors affect memory management in Swift?

### References

- [Swift Documentation - ARC](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)
- [WWDC - ARC in Swift](https://developer.apple.com/videos/)

---
```

---

## Example: Android Question

```markdown
## Q: Explain the difference between StateFlow and SharedFlow in Kotlin

**Difficulty:** 🟡 Medium
**Platform:** Android
**Category:** Coroutines & Flow
**Tags:** `kotlin`, `coroutines`, `flow`, `state-management`

### Question

What is the difference between StateFlow and SharedFlow in Kotlin? When would you use each one in an Android application?

### Answer

Both are hot flows that can have multiple collectors, but they serve different purposes:

| Aspect | StateFlow | SharedFlow |
|--------|-----------|------------|
| Initial value | Required | Not required |
| Replay | Always 1 (current value) | Configurable (0 or more) |
| Equality | Conflates equal values | Emits all values |
| Use case | State holder | Event stream |

### Code Example

```kotlin
// StateFlow - For holding UI state
class UserViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(UserUiState())
    val uiState: StateFlow<UserUiState> = _uiState.asStateFlow()
    
    fun updateUser(name: String) {
        _uiState.update { it.copy(userName = name) }
    }
}

// SharedFlow - For one-time events
class EventViewModel : ViewModel() {
    private val _events = MutableSharedFlow<UiEvent>()
    val events: SharedFlow<UiEvent> = _events.asSharedFlow()
    
    fun showToast(message: String) {
        viewModelScope.launch {
            _events.emit(UiEvent.ShowToast(message))
        }
    }
}

// Collecting in UI
@Composable
fun UserScreen(viewModel: UserViewModel) {
    // StateFlow - collectAsState for state
    val uiState by viewModel.uiState.collectAsState()
    
    // SharedFlow - LaunchedEffect for events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is UiEvent.ShowToast -> showToast(event.message)
            }
        }
    }
}
```

### Key Points

- **StateFlow**: Always has a value, conflates duplicates, perfect for UI state
- **SharedFlow**: Flexible configuration, can emit same value twice, perfect for events
- **Replay**: SharedFlow can replay values to new collectors (configurable)
- **Collectors**: Both support multiple collectors

### Common Mistakes

❌ **Mistake 1**: Using StateFlow for one-time events (navigation, toasts)
✅ **Correct approach**: Use SharedFlow or Channel for events

❌ **Mistake 2**: Not using `asStateFlow()` to expose immutable flow
✅ **Correct approach**: Always expose immutable versions from ViewModel

### Follow-up Questions

1. What is the difference between hot and cold flows?
2. How would you handle configuration changes with StateFlow?
3. What is `conflate` and when would you use it?

### References

- [Kotlin StateFlow and SharedFlow](https://kotlinlang.org/docs/flow.html)
- [Android - StateFlow and SharedFlow](https://developer.android.com/kotlin/flow/stateflow-and-sharedflow)

---
```

---

## Checklist Before Submitting

- [ ] Question is clear and specific
- [ ] Answer is comprehensive
- [ ] Code examples compile and work
- [ ] Key points highlight important concepts
- [ ] Common mistakes help avoid pitfalls
- [ ] Follow-up questions encourage deeper learning
- [ ] Difficulty level is appropriate
- [ ] Tags are relevant
- [ ] References to official docs included
- [ ] Formatting follows template

---

<p align="center">
  <b>Thank you for contributing! 🙏</b>
</p>
