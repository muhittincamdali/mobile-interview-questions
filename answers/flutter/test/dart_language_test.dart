import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:interview_answers/interview_answers.dart';

// Checks the Dart answers in questions/flutter/dart.md.

void main() {
  test(
    'FLT-001: ?? and ?. handle null, and a late field read too early throws',
    () {
      expect(displayName('Ada Lovelace', null), 'Ada Lovelace');
      expect(displayName('Ada Lovelace', 'Ada'), 'Ada');

      final nicknames = <String, String>{};
      final maybe = nicknames['grace'];
      expect(maybe?.length, isNull);

      final session = Session();
      expect(() => session.token, throwsA(isA<Error>()));
      session.token = 'abc';
      expect(session.token, 'abc');
      expect(
        () => session.token = 'again',
        throwsA(isA<Error>()),
        reason: 'late final can be set once',
      );
    },
  );

  test(
    'FLT-002: const values are canonicalised and deeply immutable, final is not',
    () {
      const a = [1, 2, 3];
      const b = [1, 2, 3];
      expect(
        identical(a, b),
        isTrue,
        reason: 'equal const expressions share one instance',
      );

      final c = [1, 2, 3];
      final d = [1, 2, 3];
      expect(identical(c, d), isFalse);

      c.add(4);
      expect(c, [
        1,
        2,
        3,
        4,
      ], reason: 'final fixes the variable, not the object');
      expect(() => a.add(4), throwsUnsupportedError);
    },
  );

  test('FLT-003: synchronous code, then microtasks, then events', () async {
    final order = <String>[];
    final done = Completer<void>();

    Timer.run(() => order.add('timer (event queue)'));
    unawaited(
      Future<void>(() {
        order.add('Future() (event queue)');
        done.complete();
      }),
    );
    scheduleMicrotask(() => order.add('microtask'));
    unawaited(
      Future<void>.value().then(
        (_) => order.add('then of a completed future (microtask)'),
      ),
    );
    order.add('synchronous');

    await done.future;
    expect(order, [
      'synchronous',
      'microtask',
      'then of a completed future (microtask)',
      'timer (event queue)',
      'Future() (event queue)',
    ]);
  });

  test(
    'FLT-004: a single-subscription stream allows one listener, a broadcast stream many',
    () async {
      final source = StreamController<int>();
      final single = source.stream;
      unawaited(
        source
            .addStream(Stream.fromIterable([1, 2, 3]))
            .then((_) => source.close()),
      );
      final values = await single.toList();
      expect(values, [1, 2, 3]);
      expect(() => single.listen((_) {}), throwsStateError);

      final controller = StreamController<int>.broadcast();
      final first = <int>[];
      final second = <int>[];
      final subscriptions = [
        controller.stream.listen(first.add),
        controller.stream.listen(second.add),
      ];
      controller
        ..add(1)
        ..add(2);
      await controller.close();
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      expect(first, [1, 2]);
      expect(second, [1, 2]);
    },
  );

  test(
    'FLT-004: a broadcast stream drops events sent before anyone listens',
    () async {
      final controller = StreamController<int>.broadcast();
      controller.add(1);
      final received = <int>[];
      final subscription = controller.stream.listen(received.add);
      controller.add(2);
      await controller.close();
      await subscription.cancel();
      expect(received, [2]);
    },
  );

  test(
    'FLT-005: Isolate.run runs a function on another isolate and returns its result',
    () async {
      int sumTo(int n) {
        var total = 0;
        for (var i = 1; i <= n; i++) {
          total += i;
        }
        return total;
      }

      expect(await Isolate.run(() => sumTo(1000000)), 500000500000);

      final counter = [0];
      await Isolate.run(() => counter[0]++);
      expect(
        counter[0],
        0,
        reason: 'the isolate changed its own copy; memory is not shared',
      );

      await expectLater(
        Isolate.run<int>(() => throw StateError('boom')),
        throwsStateError,
      );
    },
  );

  test(
    'FLT-006: records group values and patterns destructure and validate them',
    () {
      final (min, max) = bounds([4, -2, 9, 3]);
      expect((min, max), (-2, 9));
      expect((1, 'a') == (1, 'a'), isTrue, reason: 'records compare by value');

      expect(
        cityOf({
          'address': {'city': 'Izmir'},
        }),
        'Izmir',
      );
      expect(
        cityOf({
          'address': {'city': 35},
        }),
        isNull,
        reason: 'the pattern checks the type',
      );
      expect(cityOf({'name': 'x'}), isNull);
      expect(cityOf(null), isNull);
    },
  );

  test('FLT-007: a switch over a sealed class handles every subtype', () {
    expect(describePayment(const Paid('r-1')), 'Paid (r-1)');
    expect(
      describePayment(const Declined(code: 402, retryable: true)),
      'Card declined, try again',
    );
    expect(describePayment(const Declined(code: 402)), 'Declined (402)');
    expect(describePayment(const Pending()), 'Waiting for the bank');
  });

  test('FLT-008: the last mixin applied runs first', () {
    expect(ConsoleLogger().describe(), ['Tagged', 'Timestamped', 'Logger']);
    expect(OtherOrderLogger().describe(), ['Timestamped', 'Tagged', 'Logger']);
  });

  test('FLT-009: an extension type is the wrapped value at run time', () {
    const id = UserId(42);
    expect(id.isValid, isTrue);
    expect(id.value, 42);
    final Object? erased = id;
    expect(erased is int, isTrue, reason: 'there is no wrapper object');
    expect(erased, 42);

    expect('ada  lovelace '.initials, 'AL');
    expect(''.initials, '');
  });
}
