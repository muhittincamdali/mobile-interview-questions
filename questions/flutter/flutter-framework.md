# Flutter framework

Widgets, state, rendering, platform integration and testing. The verified answers are widget
tests in [widgets_test.dart](../../answers/flutter/test/widgets_test.dart).

## FLT-010: What are the widget, element and render object trees?

**Level:** mid

- **Widgets** are immutable descriptions of part of the UI, created again on every build. They are
  cheap.
- **Elements** are the long-lived instances that hold a widget's place in the tree. When a parent
  rebuilds, each element compares the new widget with the old one: if the runtime type and key
  match (`Widget.canUpdate`), the element is kept and updated; otherwise it is replaced. `State`
  objects belong to elements, which is why they survive rebuilds. `BuildContext` _is_ the element.
- **Render objects** do layout, painting and hit testing. Only some widgets have one (those that
  extend `RenderObjectWidget`, such as `Padding` or `Text`'s `RichText`); `StatelessWidget` and
  `StatefulWidget` just compose others.

Rebuilding is therefore not repainting: a `build` creates new widgets, the elements diff them, and
only changed render objects lay out or paint again. This is why keys (FLT-012) and `const`
(FLT-014) affect performance and correctness.

**Reference:** [Flutter architectural overview](https://docs.flutter.dev/resources/architectural-overview)

## FLT-011: Describe the life cycle of a `State` object.

**Level:** junior · **Verified by:** [widgets_test.dart](../../answers/flutter/test/widgets_test.dart)

1. `createState()` — the framework creates the `State` when the `StatefulWidget` is inserted.
2. `initState()` — once: create controllers, start subscriptions. `context` exists, but do not
   read inherited widgets here.
3. `didChangeDependencies()` — right after `initState`, and again whenever an inherited widget it
   depends on changes. The place to read `Theme.of(context)` or `MediaQuery` for setup.
4. `build()` — any number of times. It must be fast and free of side effects.
5. `didUpdateWidget(oldWidget)` — the parent rebuilt with a new configuration for the same
   element. Compare `widget` and `oldWidget` to restart animations or resubscribe.
6. `deactivate()` — removed from the tree, possibly to be reinserted elsewhere with a
   `GlobalKey`.
7. `dispose()` — once, permanently: dispose controllers and cancel subscriptions and timers.
   After this `mounted` is `false`.

The test records exactly this order: `initState`, `didChangeDependencies`, `build` on insertion;
`didUpdateWidget` and `build` when the parent passes a new label; `dispose` on removal.

**Reference:** [State class](https://api.flutter.dev/flutter/widgets/State-class.html)

## FLT-012: When do you need a `Key`, and which kind?

**Level:** mid · **Verified by:** [widgets_test.dart](../../answers/flutter/test/widgets_test.dart)

Without keys, Flutter matches old and new children by **position and type**. That is fine until
stateful children of the same type are reordered, inserted or removed: the `State` stays in its
slot while the data moves, so a row shows another item's state (an expanded panel, a text field's
content, a checkbox).

The test swaps two counters: without keys the tapped count stays in the first slot and now shows
next to the other name; with `ValueKey(name)` it moves with its item.

| Key                 | Use it for                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `ValueKey(id)`      | Items with a stable unique value, the usual choice in lists                                                                             |
| `ObjectKey(object)` | When identity of the object itself is the key                                                                                           |
| `UniqueKey()`       | Forcing a fresh element on every build (resets state on purpose)                                                                        |
| `GlobalKey`         | Reaching a `State` from outside (`formKey.currentState!.validate()`) or moving a subtree without losing state. Expensive; use sparingly |

Keys belong on the widget that is directly in the list being reordered, and must be unique among
siblings. Using the list index as a key is the same as no key.

**Reference:** [Key class](https://api.flutter.dev/flutter/foundation/Key-class.html)

## FLT-013: What is `BuildContext`, and how does an `InheritedWidget` update its dependents?

**Level:** mid · **Verified by:** [widgets_test.dart](../../answers/flutter/test/widgets_test.dart)

A `BuildContext` is the element of the widget being built: its position in the tree. Lookups such
as `Theme.of(context)` walk up from that position, so they find ancestors of _this_ widget, not of
the one that created it. (That is why `Scaffold.of(context)` fails when called with the context of
the widget that builds the `Scaffold`.)

`context.dependOnInheritedWidgetOfExactType<Brand>()` finds the nearest `Brand` in O(1) and
**registers a dependency**. When a new `Brand` replaces the old one and `updateShouldNotify`
returns `true`, only the registered dependents rebuild, not the whole subtree. The test keeps the
subtree's widget instances unchanged and replaces only the `Brand`: the reader rebuilds, its
sibling does not.

`getInheritedWidgetOfExactType` reads without depending, for one-time reads in callbacks.
`Theme`, `MediaQuery` and `Navigator`, and packages such as Provider, are built on this mechanism.
`MediaQuery.sizeOf(context)` depends only on the size, so a widget is not rebuilt when, for
example, the keyboard inset changes.

**References:** [InheritedWidget class](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html) · [BuildContext class](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)

## FLT-014: Why does `const` make a widget cheaper to rebuild?

**Level:** mid · **Verified by:** [widgets_test.dart](../../answers/flutter/test/widgets_test.dart)

When a parent rebuilds, each child element checks whether the new child widget is the **same
instance** as the old one. If it is, the element skips updating that subtree entirely. A `const`
constructor call is canonicalised at compile time (FLT-002), so `const StaticLabel()` is the same
instance on every build and its `build` is never called again; a non-const child gets a new
instance and is rebuilt.

The test taps a parent twice: the const child was built once, the non-const child three times.

Related techniques with the same effect: extract parts of a large `build` into separate widget
classes so they can be `const` or rebuild on their own; pass a prebuilt `child` into builders such
as `AnimatedBuilder` and `ValueListenableBuilder`; and keep `setState` as low in the tree as
possible. The `prefer_const_constructors` lint finds missing `const`.

**Reference:** [Performance best practices: Control build() cost](https://docs.flutter.dev/perf/best-practices)

## FLT-015: Why is calling `setState` after an `await` risky?

**Level:** junior · **Verified by:** [widgets_test.dart](../../answers/flutter/test/widgets_test.dart)

While the `await` is pending, the user can leave the screen, and the `State` is disposed. Calling
`setState` on a disposed `State` throws a `FlutterError` ("setState() called after dispose()").
Check `mounted` after every `await` before touching state or `context`:

```dart
Future<void> load() async {
  final items = await repository.fetch();
  if (!mounted) return;
  setState(() => this.items = items);
}
```

In code that only has a `BuildContext` (for example a callback that shows a `SnackBar`), use
`context.mounted`; the `use_build_context_synchronously` lint warns when a context is used after an
`await` without the check. Better still, cancel the work: keep the `StreamSubscription` or a
cancellation flag and stop it in `dispose`.

**Reference:** [State.mounted](https://api.flutter.dev/flutter/widgets/State/mounted.html)

## FLT-016: How do you choose a state management approach?

**Level:** mid

Start from the scope of the state:

- **Local, short-lived UI state** (a toggle, the current tab, an animation): `setState` or a
  `ValueNotifier` with `ValueListenableBuilder`.
- **State shared by a subtree**: lift it up and pass it down, or provide it with an
  `InheritedWidget` / `InheritedNotifier`, usually through a package.
- **App state with async loading, caching and dependencies**: a package. The Flutter docs list
  several; the common ones are Provider (thin layer over `InheritedWidget`, recommended in the
  official app architecture guide), Riverpod (compile-safe providers that do not depend on the
  widget tree, with built-in async states), and Bloc (events in, states out, strict separation).

What interviewers want to hear is the trade-off rather than a favourite: how the approach handles
async loading and errors, how it is tested without widgets, how it limits rebuilds, and how much
ceremony it adds for a team. Keep business logic out of widgets whichever you choose, so it can be
unit tested.

**References:** [State management](https://docs.flutter.dev/data-and-backend/state-mgmt) · [Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)

## FLT-017: What is the difference between hot reload, hot restart and a full restart?

**Level:** junior

- **Hot reload** injects changed code into the running Dart VM and rebuilds the widget tree.
  **State is kept.** It does not rerun `main()` or `initState()`, so changes to those, to global
  or static initializers, or to enums and generic type changes may not appear or may require a
  restart.
- **Hot restart** reloads the code and restarts the Dart app from `main()`. State is lost, but the
  native app keeps running, so it is still fast.
- **Full restart** (stop and run) rebuilds the native app. Needed after changing native code,
  plugins, `pubspec.yaml` dependencies with native parts, or platform configuration files.

Hot reload works in debug mode because Dart runs JIT-compiled there; release builds are AOT
compiled to machine code and do not support it. On the web, hot reload is supported in recent
Flutter versions for the development compiler.

**Reference:** [Hot reload](https://docs.flutter.dev/tools/hot-reload)

## FLT-018: How does Flutter call platform code: platform channels, Pigeon and FFI?

**Level:** mid

- **Platform channels** (`MethodChannel`, `EventChannel`, `BasicMessageChannel`) send
  asynchronous messages between Dart and Kotlin/Swift. Values are serialised with the standard
  message codec, method names are strings, and mistakes show up at run time.
- **Pigeon** generates the channel code on both sides from a Dart interface definition, so the
  messages are typed and checked by the compiler. Prefer it over hand-written channels.
- **FFI** (`dart:ffi`) calls C functions directly and synchronously, with no message
  serialisation. Use it for C, C++ or Rust libraries and performance-sensitive calls; the
  `ffigen` tool generates bindings for C and Objective-C headers, and `jnigen` for Java and
  Kotlin APIs.

Channel handlers on the platform side run on the platform's main thread by default, so long work
there must move to a background thread. Most needs are already covered by an existing plugin; check
pub.dev first.

**References:** [Writing custom platform-specific code](https://docs.flutter.dev/platform-integration/platform-channels) · [C interop using dart:ffi](https://dart.dev/interop/c-interop)

## FLT-019: How does Flutter render a frame, and what is Impeller?

**Level:** senior

Flutter draws every pixel itself instead of using platform widgets. For each frame, triggered by
the display's vsync:

1. **Animate**: tickers and animation controllers advance.
2. **Build**: dirty elements rebuild their widgets.
3. **Layout**: constraints go down, sizes come up, in one pass over dirty render objects.
4. **Paint**: render objects record drawing commands into layers.
5. **Composite and rasterise**: the layer tree goes to the raster thread, where the engine turns
   it into GPU commands.

Steps 1–4 run on the UI thread in Dart; rasterising runs on a separate raster thread. A frame is
late if either takes too long, and DevTools shows which one.

**Impeller** is Flutter's rendering engine that replaced Skia on iOS and is the default on modern
Android devices. It compiles its shaders ahead of time, which removes the first-run "shader
compilation jank" that Skia had, and it targets Metal and Vulkan directly. Check the Impeller page
for the current per-platform defaults and fallbacks.

**References:** [Flutter architectural overview: Rendering and layout](https://docs.flutter.dev/resources/architectural-overview) · [Impeller rendering engine](https://docs.flutter.dev/perf/impeller)

## FLT-020: A list screen drops frames. What do you check?

**Level:** mid

1. **Profile mode on a device**: `flutter run --profile`. Debug mode is much slower and not
   representative. Open DevTools' Performance view to see whether the UI or the raster thread is
   slow.
2. **Lazy lists**: `ListView.builder` (or `.separated`) builds only visible rows; a `Column` in a
   `SingleChildScrollView` builds all of them. Give rows a fixed `itemExtent` or a
   `prototypeItem` when you can, so scrolling does not need to measure every row.
3. **Build cost**: no parsing, sorting or formatting in `build`; `const` widgets; smaller
   widgets that rebuild on their own (FLT-014).
4. **Images**: decode at display size with `cacheWidth`/`cacheHeight` (or `ResizeImage`); a
   full-resolution photo in a thumbnail costs memory and raster time.
5. **Expensive effects**: `Opacity`, `ClipRRect` with anti-aliasing, `ShaderMask` and
   `BackdropFilter` can call `saveLayer`, which is costly. Prefer `FadeTransition` or a colour
   with alpha, and check the "saveLayer" overlay in DevTools.
6. **Repaint isolation**: wrap a frequently animating part in a `RepaintBoundary` so it does not
   repaint the rest of the list.

**References:** [Performance best practices](https://docs.flutter.dev/perf/best-practices) · [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance)

## FLT-021: What kinds of tests does Flutter support, and what does each cover?

**Level:** junior

| Test                             | Runs                                   | Covers                                              | Speed                        |
| -------------------------------- | -------------------------------------- | --------------------------------------------------- | ---------------------------- |
| Unit (`test`)                    | Dart VM                                | A function, a class, business logic                 | milliseconds                 |
| Widget (`testWidgets`)           | Dart VM with a test binding, no device | One widget or screen: build, tap, scroll, find text | fast                         |
| Integration (`integration_test`) | A device, emulator or browser          | The whole app with real plugins and navigation      | slow                         |
| Golden (`matchesGoldenFile`)     | Widget test environment                | Pixel output compared with a reference image        | fast, but platform-sensitive |

Widget tests are the sweet spot: in `testWidgets`, `tester.pumpWidget` builds a widget,
`tester.tap(find.text('Save'))` sends input, and `tester.pump()` advances a frame, all without a
device. The answers in this repository are verified that way, including a test that a const child
is not rebuilt. Fake time with `tester.pump(duration)` instead of real delays, and inject
dependencies (FLT-016) so tests do not hit the network.

**Reference:** [Testing Flutter apps](https://docs.flutter.dev/testing/overview)

## FLT-022: What are debug, profile and release modes?

**Level:** mid

| Mode    | Compilation                                        | Use it for                                         |
| ------- | -------------------------------------------------- | -------------------------------------------------- |
| Debug   | JIT, assertions on, service extensions, hot reload | Development; slow and large on purpose             |
| Profile | AOT like release, with tracing kept                | Measuring performance in DevTools on a real device |
| Release | AOT, assertions removed, tree shaken               | The store build                                    |

Release builds compile Dart ahead of time to machine code, tree-shake unused code and icons, and
can obfuscate symbols (`--obfuscate --split-debug-info=<dir>`; keep the symbol files to read crash
stack traces). `assert` statements and `kDebugMode` branches do not run in release, so never put
required logic inside an `assert`.

To reduce app size, build app bundles for Android (`flutter build appbundle`) so each device
downloads only its architecture, and check what takes space with `--analyze-size`.

**References:** [Flutter's build modes](https://docs.flutter.dev/testing/build-modes) · [Measuring your app's size](https://docs.flutter.dev/perf/app-size)
