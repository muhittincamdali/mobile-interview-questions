# 📚 API Reference - Mobile Interview Questions

> Complete API reference for the question structure, categories, and metadata formats used throughout this repository.

---

## 📋 Table of Contents

- [Question Schema](#question-schema)
- [Category Structure](#category-structure)
- [Difficulty Levels](#difficulty-levels)
- [Platform Tags](#platform-tags)
- [Answer Formats](#answer-formats)
- [Code Examples](#code-examples)
- [Metadata](#metadata)

---

## Question Schema

### Basic Structure

```yaml
question:
  id: string                    # Unique identifier (e.g., "ios-swift-001")
  title: string                 # Question title
  category: string              # Category ID
  platform: string[]            # Target platforms
  difficulty: "easy" | "medium" | "hard"
  tags: string[]                # Topic tags
  content:
    question: string            # The question text
    answer: string              # Detailed answer
    codeExamples: CodeExample[] # Code snippets
    keyPoints: string[]         # Key takeaways
    followUp: string[]          # Follow-up questions
    references: string[]        # External links
  metadata:
    author: string              # Contributor
    createdAt: date             # Creation date
    updatedAt: date             # Last update
    version: string             # Question version
```

### Example

```json
{
  "id": "ios-swift-001",
  "title": "Struct vs Class in Swift",
  "category": "swift-language",
  "platform": ["ios", "macos"],
  "difficulty": "easy",
  "tags": ["swift", "types", "memory", "fundamentals"],
  "content": {
    "question": "What is the difference between struct and class in Swift?",
    "answer": "Structs are value types...",
    "codeExamples": [...],
    "keyPoints": [
      "Structs are value types, classes are reference types",
      "Structs are stored on stack, classes on heap"
    ],
    "followUp": [
      "When would you choose struct over class?",
      "How does copy-on-write work?"
    ]
  }
}
```

---

## Category Structure

### iOS Categories

| ID | Name | Description |
|----|------|-------------|
| `swift-language` | Swift Language | Core Swift concepts |
| `uikit` | UIKit | Traditional UI framework |
| `swiftui` | SwiftUI | Declarative UI framework |
| `concurrency` | Concurrency | async/await, actors, GCD |
| `memory` | Memory Management | ARC, retain cycles |
| `networking` | Networking | URLSession, REST APIs |
| `architecture` | Architecture | MVVM, VIPER, Clean |
| `testing` | Testing | XCTest, UI Testing |

### Android Categories

| ID | Name | Description |
|----|------|-------------|
| `kotlin` | Kotlin Fundamentals | Kotlin language features |
| `compose` | Jetpack Compose | Modern UI toolkit |
| `lifecycle` | Android Lifecycle | Activity, Fragment lifecycle |
| `coroutines` | Coroutines & Flow | Async programming |
| `architecture` | Architecture Components | ViewModel, Room, etc. |
| `di` | Dependency Injection | Hilt, Dagger |

### Flutter Categories

| ID | Name | Description |
|----|------|-------------|
| `dart` | Dart Language | Dart fundamentals |
| `widgets` | Widget Lifecycle | StatelessWidget, StatefulWidget |
| `state` | State Management | Provider, Riverpod, Bloc |
| `navigation` | Navigation | Router, Navigator 2.0 |
| `performance` | Performance | Optimization techniques |

### React Native Categories

| ID | Name | Description |
|----|------|-------------|
| `react` | React Fundamentals | Hooks, context, components |
| `native` | Native Modules | Bridging, Turbo Modules |
| `navigation` | Navigation | React Navigation |
| `performance` | Performance | Optimization, profiling |

---

## Difficulty Levels

### Definitions

| Level | Emoji | Expected Knowledge | Interview Stage |
|-------|-------|-------------------|-----------------|
| Easy | 🟢 | Junior developer | Phone screen |
| Medium | 🟡 | Mid-level developer | Technical round |
| Hard | 🔴 | Senior developer | Senior/Staff round |

### Criteria

```typescript
interface DifficultyLevel {
  level: 'easy' | 'medium' | 'hard';
  experienceYears: number;
  concepts: string[];
  expectedTime: number; // minutes
}

const difficultyLevels: Record<string, DifficultyLevel> = {
  easy: {
    level: 'easy',
    experienceYears: 0-2,
    concepts: ['syntax', 'basic APIs', 'common patterns'],
    expectedTime: 5
  },
  medium: {
    level: 'medium',
    experienceYears: 2-5,
    concepts: ['architecture', 'performance', 'edge cases'],
    expectedTime: 10
  },
  hard: {
    level: 'hard',
    experienceYears: 5+,
    concepts: ['system design', 'optimization', 'tradeoffs'],
    expectedTime: 15
  }
};
```

---

## Platform Tags

### Primary Platforms

```typescript
type Platform = 
  | 'ios'           // iOS native (Swift/ObjC)
  | 'android'       // Android native (Kotlin/Java)
  | 'flutter'       // Flutter (Dart)
  | 'react-native'  // React Native (TypeScript/JavaScript)
  | 'cross-platform'; // Applicable to multiple platforms
```

### Version Targeting

```yaml
platform:
  ios:
    minVersion: "15.0"
    swiftVersion: "5.9"
    xcode: "15.0"
  android:
    minSdk: 26
    targetSdk: 34
    kotlin: "1.9"
  flutter:
    version: "3.16"
    dart: "3.2"
  reactNative:
    version: "0.73"
    node: "18"
```

---

## Answer Formats

### Text Answer

```markdown
## Answer

[Main explanation paragraph]

### Key Concepts

1. **Concept 1**: Description
2. **Concept 2**: Description
3. **Concept 3**: Description

### When to Use

- Use Case 1
- Use Case 2

### Common Mistakes

- Mistake 1
- Mistake 2
```

### Comparison Table

```markdown
| Feature | Option A | Option B |
|---------|----------|----------|
| Performance | ✅ Fast | ⚠️ Moderate |
| Memory | ⚠️ High | ✅ Low |
| Complexity | 🔴 Complex | 🟢 Simple |
```

### Step-by-Step

```markdown
1. **Step 1**: Description
   ```swift
   // Code for step 1
   ```

2. **Step 2**: Description
   ```swift
   // Code for step 2
   ```

3. **Step 3**: Description
   ```swift
   // Code for step 3
   ```
```

---

## Code Examples

### Code Block Schema

```typescript
interface CodeExample {
  language: string;
  title?: string;
  code: string;
  highlights?: number[];  // Line numbers to highlight
  annotations?: Annotation[];
}

interface Annotation {
  line: number;
  text: string;
}
```

### Swift Example

```swift
/// Demonstrates actor isolation and data race prevention
actor Counter {
    private var count = 0
    
    /// Increments the counter safely
    func increment() {
        count += 1
    }
    
    /// Returns current count
    func getCount() -> Int {
        return count
    }
}
```

### Kotlin Example

```kotlin
/**
 * ViewModel with StateFlow for reactive UI updates
 */
class UserViewModel(
    private val repository: UserRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()
    
    fun loadUser(id: String) {
        viewModelScope.launch {
            _uiState.value = try {
                UiState.Success(repository.getUser(id))
            } catch (e: Exception) {
                UiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
```

### Dart Example

```dart
/// Riverpod provider with async state
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(userId);
});

class UserScreen extends ConsumerWidget {
  final String userId;
  
  const UserScreen({super.key, required this.userId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    
    return userAsync.when(
      data: (user) => UserDetails(user: user),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

### TypeScript Example

```typescript
/**
 * Custom hook for optimistic updates
 */
function useOptimisticUpdate<T>(
  initialValue: T,
  updateFn: (value: T) => Promise<T>
) {
  const [value, setValue] = useState<T>(initialValue);
  const [isUpdating, setIsUpdating] = useState(false);
  
  const update = useCallback(async (newValue: T) => {
    const previousValue = value;
    setValue(newValue); // Optimistic update
    setIsUpdating(true);
    
    try {
      const result = await updateFn(newValue);
      setValue(result);
    } catch (error) {
      setValue(previousValue); // Rollback
      throw error;
    } finally {
      setIsUpdating(false);
    }
  }, [value, updateFn]);
  
  return { value, update, isUpdating };
}
```

---

## Metadata

### File Metadata

```yaml
---
title: "Swift Interview Questions"
description: "Comprehensive Swift language questions for iOS interviews"
category: "ios"
subcategory: "swift-language"
questionCount: 50
difficulty:
  easy: 15
  medium: 25
  hard: 10
lastUpdated: "2024-01-15"
maintainers:
  - "contributor1"
  - "contributor2"
tags:
  - swift
  - ios
  - interview
  - fundamentals
---
```

### Question Metadata

```yaml
---
id: ios-swift-001
version: 1.2.0
createdAt: 2024-01-01
updatedAt: 2024-01-15
author: contributor1
reviewedBy: reviewer1
company: ["apple", "meta", "google"]  # Companies known to ask this
frequency: high  # How often this appears in interviews
---
```

### Validation Rules

```typescript
interface ValidationRules {
  question: {
    minLength: 10;
    maxLength: 500;
  };
  answer: {
    minLength: 100;
    maxLength: 10000;
  };
  codeExample: {
    required: true;
    minCount: 1;
    maxLines: 100;
  };
  keyPoints: {
    minCount: 2;
    maxCount: 10;
  };
}
```

---

## Usage Examples

### Fetching Questions by Category

```typescript
async function getQuestionsByCategory(
  category: string,
  options?: {
    difficulty?: Difficulty;
    platform?: Platform;
    limit?: number;
  }
): Promise<Question[]> {
  const questions = await loadQuestions();
  
  return questions
    .filter(q => q.category === category)
    .filter(q => !options?.difficulty || q.difficulty === options.difficulty)
    .filter(q => !options?.platform || q.platform.includes(options.platform))
    .slice(0, options?.limit || 100);
}
```

### Random Question Selection

```typescript
function getRandomQuestions(count: number, config: {
  platforms: Platform[];
  difficulties: Difficulty[];
  excludeIds?: string[];
}): Question[] {
  const pool = allQuestions
    .filter(q => q.platform.some(p => config.platforms.includes(p)))
    .filter(q => config.difficulties.includes(q.difficulty))
    .filter(q => !config.excludeIds?.includes(q.id));
  
  return shuffleArray(pool).slice(0, count);
}
```

### Progress Tracking

```typescript
interface UserProgress {
  userId: string;
  answeredQuestions: {
    questionId: string;
    answeredAt: Date;
    correct: boolean;
    notes?: string;
  }[];
  statistics: {
    total: number;
    byPlatform: Record<Platform, number>;
    byDifficulty: Record<Difficulty, number>;
  };
}
```

---

## Contributing New Questions

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines on:

- Question format requirements
- Code style guidelines
- Review process
- Quality standards

---

<p align="center">
  <b>Happy Studying! 📚</b>
</p>
