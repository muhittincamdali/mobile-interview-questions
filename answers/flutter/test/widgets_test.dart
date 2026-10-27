import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Checks the Flutter answers in questions/flutter/flutter-framework.md.

void main() {
  testWidgets(
    'FLT-011: State runs initState, didChangeDependencies, build, didUpdateWidget and dispose',
    (tester) async {
      final events = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LifecycleProbe(label: 'a', events: events),
        ),
      );
      expect(events, ['initState', 'didChangeDependencies', 'build a']);

      events.clear();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LifecycleProbe(label: 'b', events: events),
        ),
      );
      expect(events, [
        'didUpdateWidget a -> b',
        'build b',
      ], reason: 'a new configuration keeps the same State');

      events.clear();
      await tester.pumpWidget(const SizedBox());
      expect(events, ['dispose']);
    },
  );

  testWidgets(
    'FLT-012: without keys, state follows the position; with keys it follows the item',
    (tester) async {
      Widget list(List<String> names, {required bool keyed}) => Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            for (final name in names)
              Counter(key: keyed ? ValueKey(name) : null, name: name),
          ],
        ),
      );

      for (final keyed in [false, true]) {
        await tester.pumpWidget(list(['first', 'second'], keyed: keyed));
        await tester.tap(find.text('first: 0'));
        await tester.pump();
        expect(find.text('first: 1'), findsOneWidget);

        // Swap the two items.
        await tester.pumpWidget(list(['second', 'first'], keyed: keyed));
        if (keyed) {
          expect(
            find.text('first: 1'),
            findsOneWidget,
            reason: 'the count moved with its item',
          );
          expect(find.text('second: 0'), findsOneWidget);
        } else {
          expect(
            find.text('second: 1'),
            findsOneWidget,
            reason: 'the count stayed in the first slot',
          );
          expect(find.text('first: 0'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'FLT-013: only widgets that depend on an InheritedWidget rebuild when it changes',
    (tester) async {
      final builds = <String, int>{};

      Widget app(Color color) => Directionality(
        textDirection: TextDirection.ltr,
        child: Brand(
          color: color,
          child: Column(
            children: [
              BuildCounter(name: 'reader', builds: builds, readsBrand: true),
              BuildCounter(name: 'other', builds: builds, readsBrand: false),
            ],
          ),
        ),
      );

      // The children are created once and passed as the same instances below, as when a
      // parent's state changes but its child subtree is cached.
      await tester.pumpWidget(app(Colors.blue));
      expect(builds, {'reader': 1, 'other': 1});

      final tree = tester.widget<Brand>(find.byType(Brand)).child;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Brand(color: Colors.indigo, child: tree),
        ),
      );
      expect(builds, {'reader': 2, 'other': 1});
    },
  );

  testWidgets(
    'FLT-014: a const child is not rebuilt when its parent rebuilds',
    (tester) async {
      StaticLabel.builds = 0;
      DynamicLabel.builds = 0;
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ParentWithCounter(),
        ),
      );
      expect((StaticLabel.builds, DynamicLabel.builds), (1, 1));

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(
        (StaticLabel.builds, DynamicLabel.builds),
        (1, 3),
        reason: 'the const instance is identical, so Flutter skips it',
      );
    },
  );

  testWidgets(
    'FLT-015: setState after dispose throws; checking mounted avoids it',
    (tester) async {
      final key = GlobalKey<LoaderState>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Loader(key: key),
        ),
      );
      final state = key.currentState!;
      await tester.pumpWidget(const SizedBox());

      expect(state.mounted, isFalse);
      expect(() => state.finishUnsafely(), throwsFlutterError);
      state.finishSafely(); // no exception
      expect(state.loaded, isFalse);
    },
  );
}

class LifecycleProbe extends StatefulWidget {
  const LifecycleProbe({super.key, required this.label, required this.events});
  final String label;
  final List<String> events;

  @override
  State<LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.events.add('initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.events.add('didChangeDependencies');
  }

  @override
  void didUpdateWidget(LifecycleProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.events.add('didUpdateWidget ${oldWidget.label} -> ${widget.label}');
  }

  @override
  void dispose() {
    widget.events.add('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.events.add('build ${widget.label}');
    return Text(widget.label);
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key, required this.name});
  final String name;

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => count++),
    child: Text('${widget.name}: $count'),
  );
}

class Brand extends InheritedWidget {
  const Brand({super.key, required this.color, required super.child});
  final Color color;

  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Brand>()!.color;

  @override
  bool updateShouldNotify(Brand oldWidget) => color != oldWidget.color;
}

class BuildCounter extends StatelessWidget {
  const BuildCounter({
    super.key,
    required this.name,
    required this.builds,
    required this.readsBrand,
  });
  final String name;
  final Map<String, int> builds;
  final bool readsBrand;

  @override
  Widget build(BuildContext context) {
    builds[name] = (builds[name] ?? 0) + 1;
    if (readsBrand) Brand.of(context);
    return const SizedBox();
  }
}

class StaticLabel extends StatelessWidget {
  const StaticLabel({super.key});
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return const Text('Static');
  }
}

class DynamicLabel extends StatelessWidget {
  // Deliberately not const, to show the difference.
  // ignore: prefer_const_constructors_in_immutables
  DynamicLabel({super.key, required this.value});
  final int value;
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return Text('$value');
  }
}

class ParentWithCounter extends StatefulWidget {
  const ParentWithCounter({super.key});

  @override
  State<ParentWithCounter> createState() => _ParentWithCounterState();
}

class _ParentWithCounterState extends State<ParentWithCounter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => taps++),
    child: Column(
      children: [
        const StaticLabel(),
        DynamicLabel(value: taps),
      ],
    ),
  );
}

class Loader extends StatefulWidget {
  const Loader({super.key});

  @override
  State<Loader> createState() => LoaderState();
}

class LoaderState extends State<Loader> {
  bool loaded = false;

  /// What code after an `await` does when it forgets the check.
  void finishUnsafely() => setState(() => loaded = true);

  /// The fix from the answer.
  void finishSafely() {
    if (!mounted) return;
    setState(() => loaded = true);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
