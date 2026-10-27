/// Code from the answers in `questions/flutter`, compiled by `flutter analyze` and run by the
/// tests in `test/`. Each test name starts with the ID of the question it checks.
library;

// FLT-006 and FLT-007 ------------------------------------------------------------------------

/// The result of a payment, as a closed set of cases.
sealed class PaymentResult {
  const PaymentResult();
}

final class Paid extends PaymentResult {
  const Paid(this.receiptId);
  final String receiptId;
}

final class Declined extends PaymentResult {
  const Declined({required this.code, this.retryable = false});
  final int code;
  final bool retryable;
}

final class Pending extends PaymentResult {
  const Pending();
}

/// A switch expression over a sealed type: adding a subclass is a compile error here until it
/// is handled, which is the point of the answer.
String describePayment(PaymentResult result) => switch (result) {
  Paid(:final receiptId) => 'Paid ($receiptId)',
  Declined(code: 402, retryable: true) => 'Card declined, try again',
  Declined(:final code) => 'Declined ($code)',
  Pending() => 'Waiting for the bank',
};

/// Returns two values as a record instead of a class or a list.
(int min, int max) bounds(List<int> values) {
  var low = values.first;
  var high = values.first;
  for (final value in values.skip(1)) {
    if (value < low) low = value;
    if (value > high) high = value;
  }
  return (low, high);
}

/// Destructures JSON with a map pattern and validates types in one step.
String? cityOf(Object? json) => switch (json) {
  {'address': {'city': final String city}} => city,
  _ => null,
};

// FLT-008 --------------------------------------------------------------------------------------

/// Each mixin adds its part and calls `super`, so the order of `with` decides the output.
abstract class Logger {
  List<String> describe() => ['Logger'];
}

mixin Timestamped on Logger {
  @override
  List<String> describe() => ['Timestamped', ...super.describe()];
}

mixin Tagged on Logger {
  @override
  List<String> describe() => ['Tagged', ...super.describe()];
}

class ConsoleLogger extends Logger with Timestamped, Tagged {}

class OtherOrderLogger extends Logger with Tagged, Timestamped {}

// FLT-009 --------------------------------------------------------------------------------------

/// A zero-cost wrapper: at run time a UserId is an int.
extension type const UserId(int value) {
  bool get isValid => value > 0;
}

/// An extension method adds behaviour to an existing type without wrapping it.
extension Initials on String {
  String get initials => trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase())
      .join();
}

// FLT-001 --------------------------------------------------------------------------------------

/// Reads a nickname that may be missing.
String displayName(String name, String? nickname) => nickname ?? name;

/// A `late` field that is used before it is set throws at run time.
class Session {
  late final String token;
}
