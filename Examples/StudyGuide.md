# 📚 Study Guide Examples

> Complete study plans and example interview preparation paths.

---

## 🎯 6-Week Interview Preparation Plan

### Week 1: Platform Fundamentals

**Daily Schedule (2-3 hours)**

| Day | Topic | Questions | Practice |
|-----|-------|-----------|----------|
| Mon | Swift/Kotlin basics | 10 | Write code |
| Tue | Types & collections | 10 | Implement custom types |
| Wed | Optionals/Nullability | 8 | Handle edge cases |
| Thu | Closures/Lambdas | 8 | Write higher-order functions |
| Fri | Protocols/Interfaces | 10 | Design abstractions |
| Sat | Review | 20 | Mock quiz |
| Sun | Rest | - | Light reading |

**End of Week Goals:**
- [ ] Complete 50+ fundamental questions
- [ ] Write 10 custom implementations
- [ ] No syntax lookup needed

---

### Week 2: UI Frameworks

**Daily Schedule (2-3 hours)**

| Day | iOS | Android | Practice |
|-----|-----|---------|----------|
| Mon | SwiftUI basics | Compose basics | Build simple UI |
| Tue | State management | State hoisting | Stateful counter |
| Wed | Navigation | Navigation | Multi-screen app |
| Thu | Lists & grids | LazyColumn | Scrollable list |
| Fri | Modifiers/Styling | Modifiers | Themed component |
| Sat | UIKit/XML review | View system | Compare approaches |
| Sun | Mini project | Mini project | Complete small app |

**End of Week Goals:**
- [ ] Build 3 small UIs from scratch
- [ ] Understand declarative vs imperative
- [ ] Navigate between screens confidently

---

### Week 3: Architecture & Concurrency

**Daily Schedule (3 hours)**

| Day | Topic | Deep Dive |
|-----|-------|-----------|
| Mon | MVVM pattern | Implement from scratch |
| Tue | Clean Architecture | Layer separation |
| Wed | Dependency Injection | Container pattern |
| Thu | async/await basics | Simple async operations |
| Fri | Advanced concurrency | Actors, race conditions |
| Sat | Architecture review | Refactor previous projects |
| Sun | Practice questions | Mock technical interview |

**Sample Architecture Implementation:**

```swift
// MVVM Example
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
}

@MainActor
final class UserViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let service: UserServiceProtocol
    
    init(service: UserServiceProtocol) {
        self.service = service
    }
    
    func loadUser(id: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                user = try await service.fetchUser(id: id)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}
```

---

### Week 4: Coding Challenges

**Daily Schedule (3-4 hours)**

| Day | Topic | Problems | Difficulty |
|-----|-------|----------|------------|
| Mon | Arrays | 5 | Easy-Medium |
| Tue | Strings | 5 | Easy-Medium |
| Wed | Linked Lists | 4 | Medium |
| Thu | Trees | 4 | Medium |
| Fri | Graphs | 3 | Medium-Hard |
| Sat | Dynamic Programming | 3 | Medium-Hard |
| Sun | Review weak areas | 5 | Mixed |

**Problem Solving Template:**

```swift
/// Problem: Two Sum
/// Time: O(n), Space: O(n)
func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
    // 1. Understand the problem
    // Find two numbers that add up to target
    
    // 2. Plan the solution
    // Use hash map for O(1) lookup
    
    // 3. Implement
    var seen: [Int: Int] = [:]
    
    for (index, num) in nums.enumerated() {
        let complement = target - num
        if let complementIndex = seen[complement] {
            return [complementIndex, index]
        }
        seen[num] = index
    }
    
    return []
    
    // 4. Test with examples
    // [2,7,11,15], target=9 → [0,1]
    
    // 5. Analyze complexity
    // Time: O(n) - single pass
    // Space: O(n) - hash map storage
}
```

---

### Week 5: System Design

**Daily Schedule (2-3 hours)**

| Day | Topic | Design Exercise |
|-----|-------|-----------------|
| Mon | Mobile architecture patterns | News feed app |
| Tue | Networking layer | Retry & caching |
| Wed | Offline-first design | Sync strategy |
| Thu | Image loading system | Cache hierarchy |
| Fri | Real-time features | Chat system |
| Sat | Push notifications | Delivery system |
| Sun | Full design practice | Instagram clone |

**System Design Template:**

```
1. Requirements Clarification (5 min)
   - Functional requirements
   - Non-functional requirements
   - Scale estimation

2. High-Level Design (10 min)
   - Component diagram
   - Data flow
   - API contracts

3. Detailed Design (15 min)
   - Deep dive into components
   - Database schema
   - Caching strategy

4. Bottlenecks & Trade-offs (5 min)
   - Identify limitations
   - Discuss alternatives
   - Scaling strategies
```

---

### Week 6: Behavioral & Mock Interviews

**Daily Schedule (2-3 hours)**

| Day | Focus | Activity |
|-----|-------|----------|
| Mon | STAR method | Write 10 stories |
| Tue | Leadership scenarios | Practice responses |
| Wed | Mock technical | Friend/peer interview |
| Thu | Mock behavioral | Record yourself |
| Fri | Mock system design | Whiteboard practice |
| Sat | Full mock interview | 4-hour simulation |
| Sun | Rest & review | Light preparation |

**STAR Story Template:**

```markdown
## Situation
[Set the context - where, when, what was happening]

## Task
[Your specific responsibility or challenge]

## Action
[What YOU did - specific steps, decisions]
- Action 1
- Action 2
- Action 3

## Result
[Quantifiable outcome - metrics, impact]
- Metric 1: X% improvement
- Metric 2: Y hours saved
- Metric 3: Z increase in [thing]

## Learnings
[What you took away from this experience]
```

---

## 📋 Quick Reference Cards

### iOS Quick Reference

```
┌──────────────────────────────────────────────────────┐
│                iOS QUICK REFERENCE                    │
├──────────────────────────────────────────────────────┤
│                                                       │
│ VALUE vs REFERENCE TYPES                             │
│ struct = value type (stack)                          │
│ class = reference type (heap)                        │
│                                                       │
│ MEMORY MANAGEMENT                                    │
│ ARC = Automatic Reference Counting                   │
│ strong (default), weak, unowned                      │
│                                                       │
│ CONCURRENCY                                          │
│ async/await = structured concurrency                 │
│ actor = data race protection                         │
│ Task = unit of async work                            │
│                                                       │
│ COMMON PROTOCOLS                                     │
│ Codable = JSON encoding/decoding                     │
│ Equatable = == comparison                            │
│ Hashable = hash-based collections                    │
│ Identifiable = unique identity                       │
│                                                       │
│ SWIFTUI STATE                                        │
│ @State = local view state                            │
│ @Binding = two-way connection                        │
│ @StateObject = owned observable                      │
│ @ObservedObject = external observable                │
│ @EnvironmentObject = injected dependency             │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### Android Quick Reference

```
┌──────────────────────────────────────────────────────┐
│              ANDROID QUICK REFERENCE                  │
├──────────────────────────────────────────────────────┤
│                                                       │
│ KOTLIN FEATURES                                      │
│ data class = auto equals/hash/toString               │
│ sealed class = restricted hierarchy                  │
│ object = singleton                                   │
│                                                       │
│ NULL SAFETY                                          │
│ ? = nullable                                         │
│ ?. = safe call                                       │
│ ?: = elvis operator                                  │
│ !! = force unwrap (avoid!)                           │
│                                                       │
│ COROUTINES                                           │
│ suspend = suspending function                        │
│ launch = fire and forget                             │
│ async = returns Deferred                             │
│ withContext = switch dispatcher                      │
│                                                       │
│ FLOW                                                 │
│ Flow = cold stream                                   │
│ StateFlow = state holder                             │
│ SharedFlow = event stream                            │
│                                                       │
│ COMPOSE STATE                                        │
│ remember = survive recomposition                     │
│ mutableStateOf = observable state                    │
│ derivedStateOf = computed state                      │
│ rememberSaveable = survive config change             │
│                                                       │
│ LIFECYCLE                                            │
│ onCreate → onStart → onResume                        │
│ onPause → onStop → onDestroy                         │
│                                                       │
└──────────────────────────────────────────────────────┘
```

---

## 🎤 Common Interview Questions Cheat Sheet

### Technical Questions

| Question | Key Points |
|----------|------------|
| Struct vs Class | Value/reference, stack/heap, copy semantics |
| Memory leaks | Retain cycles, weak/unowned, closure captures |
| async/await vs GCD | Structured concurrency, cancellation, actors |
| MVVM vs MVC | Separation of concerns, testability, binding |
| SwiftUI vs UIKit | Declarative/imperative, state management, diffing |

### Behavioral Questions

| Question | Framework |
|----------|-----------|
| Tell me about yourself | Present → Past → Future (2 min) |
| Biggest challenge | STAR method + learnings |
| Why this company | Research + specific reasons |
| Conflict resolution | Situation → Approach → Outcome |
| 5-year plan | Growth + realistic goals |

---

## ✅ Interview Day Checklist

### Before the Interview

- [ ] Get good sleep (7-8 hours)
- [ ] Review company research
- [ ] Prepare 5 STAR stories
- [ ] Test audio/video setup
- [ ] Have water nearby
- [ ] Review your resume
- [ ] Prepare questions to ask

### During the Interview

- [ ] Take a breath before answering
- [ ] Ask clarifying questions
- [ ] Think out loud
- [ ] Admit what you don't know
- [ ] Show enthusiasm
- [ ] Take notes

### Questions to Ask

1. "What does success look like in the first 90 days?"
2. "How does the team handle technical decisions?"
3. "What's the biggest challenge the team is facing?"
4. "How do you support professional development?"
5. "What's the code review process like?"

---

<p align="center">
  <b>Good luck with your interviews! 🚀</b>
</p>
