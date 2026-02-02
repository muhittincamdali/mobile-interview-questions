# Dart Language Fundamentals - Deep Dive

A comprehensive deep dive into Dart language fundamentals for Flutter developer interviews.

---

## Type System

### Q: Explain Dart's sound null safety. What are the key concepts?

**Difficulty:** 🟢 Junior

Dart's null safety ensures that variables cannot be null unless explicitly declared as nullable. This catches null errors at compile time.

```dart
// Non-nullable — cannot be null
String name = 'Alice';
// name = null;  // Compile error!

// Nullable — can be null
String? nickname;
nickname = null;  // OK

// Null-aware operators
String display = nickname ?? 'No nickname';     // null coalescing
int? length = nickname?.length;                  // null-aware access
String forced = nickname!;                       // force unwrap (throws if null)

// Late initialization
late final String apiKey;
void configure() {
  apiKey = Environment.getApiKey();  // Must be set before first read
}

// Null-aware cascade
object
  ?..method1()
  ..method2();
```

---

### Q: What is the difference between `final`, `const`, and `late` in Dart?

**Difficulty:** 🟢 Junior

```dart
// final — set once at runtime, cannot be reassigned
final DateTime now = DateTime.now();
// now = DateTime.now();  // Error

// const — compile-time constant, deeply immutable
const double pi = 3.14159;
const list = [1, 2, 3];    // The list itself is immutable
// list.add(4);             // Runtime error

// late — lazy initialization, set before first use
class UserProfile {
  late final String bio;  // Set later, read-only after first assignment

  late final int _expensiveValue = _computeExpensive();

  int _computeExpensive() {
    print('Computing...');  // Only runs when _expensiveValue is first accessed
    return 42;
  }
}

// const vs final in collections
final mutableList = [1, 2, 3];
mutableList.add(4);         // OK — list is mutable, reference is final

const immutableList = [1, 2, 3];
// immutableList.add(4);   // Error — list is deeply immutable
```

---

### Q: Explain Dart's type system. What are `dynamic`, `Object`, and `var`?

**Difficulty:** 🟡 Mid

```dart
// Object — base of all Dart types (except Null)
// Everything is an Object, but you can only call Object methods
Object obj = 'hello';
// obj.length;  // Error — Object has no 'length'
print(obj.toString());  // OK

// dynamic — opt out of static type checking
dynamic d = 'hello';
print(d.length);       // OK at compile time, checked at runtime
d = 42;
// print(d.length);    // Runtime error — int has no 'length'

// var — inferred type, statically typed after inference
var message = 'hello';  // Inferred as String
// message = 42;        // Error — String expected

// Object? vs dynamic
Object? nullable;      // Can be null, but type-safe
dynamic anything;       // No type checking at all

// Type testing
void process(Object value) {
  if (value is String) {
    // Smart cast — value is now treated as String
    print(value.length);
  } else if (value is int) {
    print(value.isEven);
  }
}
```

---

### Q: What are extension methods in Dart?

**Difficulty:** 🟡 Mid

Extension methods add functionality to existing types without modifying them or creating subclasses.

```dart
extension StringValidation on String {
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$').hasMatch(this);
  }

  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension DateFormatting on DateTime {
  String get timeAgo {
    final difference = DateTime.now().difference(this);
    if (difference.inDays > 365) return '${difference.inDays ~/ 365}y ago';
    if (difference.inDays > 30) return '${difference.inDays ~/ 30}mo ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }
}

// Usage
print('test@example.com'.isValidEmail);  // true
print('Hello World'.truncate(5));         // Hello...
print(DateTime(2026, 1, 1).timeAgo);     // 14d ago
```

---

### Q: Explain Dart's mixin system.

**Difficulty:** 🟡 Mid

Mixins provide a way to reuse code across multiple class hierarchies without multiple inheritance.

```dart
mixin Loggable {
  void log(String message) {
    print('[${runtimeType}] $message');
  }
}

mixin Cacheable {
  final Map<String, dynamic> _cache = {};

  T cached<T>(String key, T Function() compute) {
    return _cache.putIfAbsent(key, compute) as T;
  }

  void clearCache() => _cache.clear();
}

// 'on' clause restricts which classes can use the mixin
mixin Persistable on Model {
  Future<void> save() async {
    final json = toJson();
    await database.insert(tableName, json);
  }
}

abstract class Model {
  Map<String, dynamic> toJson();
  String get tableName;
}

class UserModel extends Model with Loggable, Cacheable, Persistable {
  final String name;
  final String email;

  UserModel({required this.name, required this.email});

  @override
  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  @override
  String get tableName => 'users';
}
```

---

## Async Programming

### Q: Explain `Future`, `async/await`, and `Completer` in Dart.

**Difficulty:** 🟡 Mid

```dart
// Future — represents a value available in the future
Future<String> fetchUsername() async {
  final response = await http.get(Uri.parse('https://api.example.com/user'));
  return jsonDecode(response.body)['name'];
}

// Completer — manually complete a Future
Future<String> waitForCallback() {
  final completer = Completer<String>();

  someNativePlugin.doWork(
    onSuccess: (result) => completer.complete(result),
    onError: (error) => completer.completeError(error),
  );

  return completer.future;
}

// Future combinators
Future<void> loadDashboard() async {
  // Run in parallel
  final results = await Future.wait([
    fetchUser(),
    fetchPosts(),
    fetchNotifications(),
  ]);

  // First to complete wins
  final fastest = await Future.any([
    fetchFromServer1(),
    fetchFromServer2(),
  ]);

  // With timeout
  try {
    final data = await fetchData().timeout(Duration(seconds: 5));
  } on TimeoutException {
    print('Request timed out');
  }
}
```

---

### Q: What are Streams in Dart? Explain single-subscription vs broadcast.

**Difficulty:** 🟡 Mid

```dart
// Single-subscription — one listener only (default)
Stream<int> countStream(int max) async* {
  for (int i = 0; i < max; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

// Broadcast — multiple listeners allowed
final controller = StreamController<String>.broadcast();
controller.stream.listen((data) => print('Listener 1: $data'));
controller.stream.listen((data) => print('Listener 2: $data'));
controller.add('Hello');  // Both listeners receive it

// Stream transformations
final subscription = countStream(100)
    .where((n) => n.isEven)
    .map((n) => 'Number: $n')
    .take(5)
    .listen(
      (data) => print(data),
      onDone: () => print('Complete'),
      onError: (e) => print('Error: $e'),
    );

// Cancel subscription
await subscription.cancel();

// StreamTransformer for custom logic
final debouncer = StreamTransformer<String, String>.fromHandlers(
  handleData: (data, sink) {
    Timer(Duration(milliseconds: 300), () => sink.add(data));
  },
);
```

---

### Q: What are Isolates in Dart? How do they differ from threads?

**Difficulty:** 🔴 Senior

Isolates are independent workers with their own memory heap. They don't share memory — communication happens via message passing.

```dart
// Simple compute for one-off heavy work
final result = await Isolate.run(() {
  // This runs in a separate isolate
  return heavyComputation(data);
});

// Long-lived isolate with bidirectional communication
Future<void> startWorker() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_workerEntryPoint, receivePort.sendPort);

  final sendPort = await receivePort.first as SendPort;

  // Send work to the isolate
  final responsePort = ReceivePort();
  sendPort.send(['process', largeData, responsePort.sendPort]);

  final result = await responsePort.first;
  print('Result: $result');
}

void _workerEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    final command = message[0] as String;
    final data = message[1];
    final replyPort = message[2] as SendPort;

    switch (command) {
      case 'process':
        final result = _processData(data);
        replyPort.send(result);
    }
  });
}

// Flutter's compute() helper
final parsed = await compute(parseJson, jsonString);

List<Item> parseJson(String json) {
  final decoded = jsonDecode(json) as List;
  return decoded.map((e) => Item.fromJson(e)).toList();
}
```

Key differences from threads:
- No shared memory (no data races possible)
- Communication only via SendPort/ReceivePort
- Each isolate has its own event loop
- Heavier than threads but safer

---

## Collections and Patterns

### Q: Explain Dart 3 patterns and records.

**Difficulty:** 🟡 Mid

```dart
// Records — lightweight tuples
(String, int) getNameAndAge() => ('Alice', 30);

// Named fields
({String name, int age}) getUser() => (name: 'Bob', age: 25);

// Destructuring
final (name, age) = getNameAndAge();
final (:name, :age) = getUser();  // shorthand for named

// Pattern matching in switch
String describe(Object value) => switch (value) {
  int n when n < 0 => 'negative',
  int n when n == 0 => 'zero',
  int n => 'positive: $n',
  String s when s.isEmpty => 'empty string',
  String s => 'string: $s',
  [int first, ...var rest] => 'list starting with $first',
  {'key': var v} => 'map with key: $v',
  _ => 'unknown',
};

// Sealed classes with exhaustive matching
sealed class Shape {}
class Circle extends Shape { final double radius; Circle(this.radius); }
class Square extends Shape { final double side; Square(this.side); }
class Triangle extends Shape { final double base, height; Triangle(this.base, this.height); }

double area(Shape shape) => switch (shape) {
  Circle(:var radius) => 3.14159 * radius * radius,
  Square(:var side) => side * side,
  Triangle(:var base, :var height) => 0.5 * base * height,
};
// No default needed — compiler knows all cases are covered
```

---

### Q: What are generics in Dart? Explain bounded and covariant generics.

**Difficulty:** 🟡 Mid

```dart
// Basic generics
class Stack<T> {
  final List<T> _items = [];

  void push(T item) => _items.add(item);
  T pop() => _items.removeLast();
  T get peek => _items.last;
  bool get isEmpty => _items.isEmpty;
}

// Bounded generics
class SortedList<T extends Comparable<T>> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
    _items.sort();
  }
}

// Covariant — relaxes type checking for parameters
class Animal {
  final String name;
  Animal(this.name);
}

class Dog extends Animal {
  Dog(super.name);
}

class Shelter<T extends Animal> {
  void adopt(covariant T animal) {
    print('Adopted ${animal.name}');
  }
}

// Generic functions
T firstWhere<T>(List<T> items, bool Function(T) predicate) {
  for (final item in items) {
    if (predicate(item)) return item;
  }
  throw StateError('No matching element');
}

// Generic typedef
typedef JsonMap = Map<String, dynamic>;
typedef Mapper<T> = T Function(JsonMap);
```

---

## Memory and Performance

### Q: How does Dart's garbage collector work?

**Difficulty:** 🔴 Senior

Dart uses a generational garbage collector optimized for UI workloads:

**Young Generation (Nursery):**
- New objects are allocated here
- Semi-space collector (copying GC)
- Very fast — typically < 1ms
- Most short-lived objects (widgets, build results) are collected here

**Old Generation:**
- Objects surviving multiple young GC cycles are promoted here
- Mark-sweep-compact collector
- Runs less frequently
- Can cause longer pauses if fragmented

```dart
// Best practices for GC-friendly Flutter code:

// 1. Avoid unnecessary object creation in build()
class MyWidget extends StatelessWidget {
  // BAD — new TextStyle every build
  // @override
  // Widget build(context) => Text('Hi', style: TextStyle(fontSize: 16));

  // GOOD — const or static
  static const _style = TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) => Text('Hi', style: _style);
}

// 2. Use const constructors
const widget = Padding(
  padding: EdgeInsets.all(8.0),  // const
  child: Text('Hello'),          // const
);

// 3. Reuse objects in animations
class MyPainter extends CustomPainter {
  final Paint _paint = Paint()..color = Colors.blue;  // Reused

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### Q: Explain Dart's event loop and microtask queue.

**Difficulty:** 🔴 Senior

```dart
// Dart has two queues:
// 1. Microtask queue (higher priority)
// 2. Event queue (timers, I/O, UI events)

void main() {
  print('1 - main start');

  Future(() => print('5 - event queue'));

  scheduleMicrotask(() => print('3 - microtask 1'));

  Future.microtask(() => print('4 - microtask 2'));

  Future.delayed(Duration.zero, () => print('6 - delayed'));

  print('2 - main end');
}

// Output:
// 1 - main start
// 2 - main end
// 3 - microtask 1
// 4 - microtask 2
// 5 - event queue
// 6 - delayed

// Event loop order:
// 1. Run all synchronous code
// 2. Drain microtask queue (all of them)
// 3. Pick one event from event queue
// 4. Drain microtask queue again
// 5. Repeat 3-4

// Practical implication for Flutter:
// setState() schedules a rebuild as a microtask
// Timer callbacks are events
// Future.then() callbacks are microtasks
```

---

## Callable Classes and Operators

### Q: How do callable classes and operator overloading work?

**Difficulty:** 🟡 Mid

```dart
// Callable class — implement call()
class Validator {
  final String pattern;
  final String errorMessage;

  Validator(this.pattern, this.errorMessage);

  String? call(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (!RegExp(pattern).hasMatch(value)) return errorMessage;
    return null;
  }
}

final validateEmail = Validator(
  r'^[\w.]+@[\w]+\.[\w]+$',
  'Invalid email format',
);

// Use like a function
print(validateEmail('test@example.com'));  // null (valid)
print(validateEmail('invalid'));            // 'Invalid email format'

// Operator overloading
class Vector2 {
  final double x, y;
  const Vector2(this.x, this.y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  double operator [](int index) => index == 0 ? x : y;

  @override
  bool operator ==(Object other) =>
      other is Vector2 && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

final a = Vector2(1, 2);
final b = Vector2(3, 4);
print(a + b);      // Vector2(4, 6)
print(a * 2.0);    // Vector2(2, 4)
```
