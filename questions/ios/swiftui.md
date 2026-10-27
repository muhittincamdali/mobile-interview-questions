# SwiftUI

State, identity, navigation and performance. The Observation answer is checked in
[ObservationTests](../../Tests/AnswerTests/ObservationTests.swift).

## IOS-033: How does SwiftUI decide which views to update, and what is view identity?

**Level:** mid

A SwiftUI `View` is a cheap description; SwiftUI keeps the real state (the storage behind
`@State`, the underlying platform views, animations) in its own graph, keyed by **identity**.
When a dependency of a view changes, SwiftUI calls that view's `body` again, compares the new
description with the old one, and updates only what differs.

There are two kinds of identity:

- **Structural**: the position in the view tree. The two branches of an `if`/`else` are
  different views, so switching branches destroys one and creates the other, including their
  `@State` and transitions.
- **Explicit**: an ID from `ForEach(items, id: \.id)`, `Identifiable`, or `.id(_:)`. Changing
  `.id(value)` gives the view a new identity and resets its state, which is a useful way to
  restart a view on purpose.

Practical consequences: prefer modifiers with conditional values (`.opacity(isHidden ? 0 : 1)`)
over `if` branches when the view should keep its state; use stable IDs in lists (never array
indices for data that can be inserted or deleted); and avoid `AnyView`, which hides the structure
SwiftUI uses for diffing.

**Reference:** [Demystify SwiftUI (WWDC21)](https://developer.apple.com/videos/play/wwdc2021/10022/)

## IOS-034: When do you use `@State`, `@Binding`, `@Bindable` and `@Environment`?

**Level:** junior

| Wrapper        | Owns the data | Use it for                                                                                                                                       |
| -------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `@State`       | yes           | Values owned by this view (`private`), and an `@Observable` model the view creates                                                               |
| `@Binding`     | no            | Read and write access to a value owned by a parent: `Toggle(isOn: $isOn)`                                                                        |
| `@Bindable`    | no            | Getting bindings (`$model.name`) to properties of an `@Observable` object passed in                                                              |
| `@Environment` | no            | Values shared down the tree: system values such as `\.dismiss` or `\.colorScheme`, or an `@Observable` model injected with `.environment(model)` |

```swift
@Observable final class Settings { var username = "" }

struct ProfileEditor: View {
    @Bindable var settings: Settings          // passed in by a parent that owns it in @State
    var body: some View {
        TextField("Name", text: $settings.username)
    }
}
```

A plain `let` or `var` property is enough for read-only data, and also for an `@Observable`
object you only read: SwiftUI tracks the properties `body` reads either way. `@StateObject`,
`@ObservedObject` and `@EnvironmentObject` are the older wrappers for `ObservableObject`; they are
still supported but new code on iOS 17 and later uses Observation.

**Reference:** [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)

## IOS-035: Why is `@Observable` better than `ObservableObject` for performance?

**Level:** mid · **Verified by:** [ObservationTests](../../Tests/AnswerTests/ObservationTests.swift)

With `ObservableObject`, any `@Published` property change sends `objectWillChange`, and every view
that observes the object re-evaluates its `body`, even views that never read the changed
property.

The `@Observable` macro (Observation framework, iOS 17) tracks **which properties are read**.
While SwiftUI evaluates a `body`, it records the properties that body accessed, and later only
changes to those properties invalidate the view. A badge that shows `unreadCount` is not
re-rendered when `name` changes.

The test uses the same mechanism SwiftUI uses, `withObservationTracking(_:onChange:)`:

```swift
withObservationTracking {
    _ = model.name          // only name is tracked
} onChange: {
    print("name changed")   // fires for model.name = "Lin", not for model.unreadCount = 3
}
```

`onChange` fires once, before the change is applied; SwiftUI re-establishes tracking on every
`body` evaluation. Other benefits: no `@Published` boilerplate, tracking works through nested
observable objects and arrays of them, and an observable object can be stored in a plain `@State`.
Use `@ObservationIgnored` for properties that should not trigger updates, such as caches.

**References:** [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro) · [withObservationTracking(_:onChange:)](<https://developer.apple.com/documentation/observation/withobservationtracking(_:onchange:)>)

## IOS-036: A view creates its model with `@State private var model = FeedModel()`. What should you watch out for?

**Level:** senior

`@State` makes SwiftUI keep the **first** instance for the lifetime of the view's identity, so
the model is not replaced when the parent re-renders. That is the recommended way for a view to
own an `@Observable` model.

But the initial-value expression is part of the view's initializer, and a view struct is
initialized every time its parent's `body` runs. So `FeedModel()` can run many times; SwiftUI
discards all instances but the first. Consequences:

- Keep the model's `init` cheap. Do not start network requests, timers or observers there; start
  them in `.task { await model.load() }`, which runs once per appearance and is cancelled when the
  view goes away.
- Side effects in `init` (analytics, logging) will repeat and mislead.
- If the model needs a value from the parent, pass the value to the view and create the model in
  the view's `init` with `_model = State(initialValue: FeedModel(id: id))`, or in `.task(id:)`;
  remember that a later change of `id` does not recreate a model stored in `@State`.

`@StateObject` avoided the repeated construction by taking an autoclosure, which is one of the
few behaviours that differ when migrating.

**References:** [State](https://developer.apple.com/documentation/swiftui/state) · [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

## IOS-037: What is the difference between `.task` and `.onAppear`?

**Level:** mid

- `.onAppear` runs a synchronous closure when the view appears. Starting async work there needs
  `Task { }`, and that task keeps running after the view disappears unless you store and cancel it.
- `.task { }` runs an async closure when the view appears and **cancels it automatically** when
  the view disappears. It runs on the main actor, like the view.
- `.task(id: value) { }` also cancels and restarts the work whenever `value` changes, which is a
  clean way to reload on a changing search query or selection.

```swift
.task(id: query) {
    try? await Task.sleep(for: .milliseconds(300))   // debounce: cancelled if query changes again
    guard !Task.isCancelled else { return }
    await model.search(query)
}
```

The work is cancelled, not stopped: the code inside must react to cancellation (see IOS-024).
`.onDisappear` is the place for synchronous cleanup; `.task` cleanup can go after the `await` that
throws `CancellationError`.

**Reference:** [task(id:priority:_:)](<https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:)>)

## IOS-038: How do you build programmatic navigation and deep links with `NavigationStack`?

**Level:** mid

Use value-based navigation: push **data**, and map data types to destinations once.

```swift
enum Route: Hashable { case article(Article.ID), settings }

struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(open: { path.append(.article($0)) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .article(let id): ArticleView(id: id)
                    case .settings: SettingsView()
                    }
                }
        }
        .onOpenURL { url in path = Route.path(for: url) }   // deep link: replace the stack
    }
}
```

The path is plain state, so popping to the root is `path.removeAll()`, a deep link builds the
whole stack at once, and the path can be saved with `Codable` (use `NavigationPath` when the
stack mixes several types; it has a `codable` representation). Avoid putting
`navigationDestination` inside lazy containers like `List` rows, where it may not be registered
yet when the value is pushed. `NavigationSplitView` is the multi-column equivalent for iPad and
Mac.

**Reference:** [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)

## IOS-039: A long `List` or `ScrollView` stutters. What do you check?

**Level:** mid

1. **Laziness**: `List`, `LazyVStack` and `LazyVGrid` create rows on demand; a `VStack` inside a
   `ScrollView` creates every row up front.
2. **Stable identity**: rows need stable, unique IDs. IDs that change on every update (a new
   `UUID()` in a computed property, or indices for mutable data) force SwiftUI to rebuild rows.
3. **Cheap `body`**: no formatting, sorting, filtering or image decoding inside `body`. Precompute
   in the model and keep formatters static.
4. **Images**: decode and downsample off the main actor (`AsyncImage` loads but does not resize);
   a 12-megapixel photo in a 60-point thumbnail costs about 48 MB once decoded.
5. **Narrow dependencies**: pass rows the values they show, not the whole store, so a change to
   one item does not re-render every row. With `@Observable` this mostly happens on its own.
6. **Measure**: the SwiftUI instrument in Instruments shows long `body` updates and what caused
   them; _Hangs_ and _Time Profiler_ show main-thread work.

**References:** [Creating performant scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks) · [Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance)

## IOS-040: How do you pass data from a child view up to its parent?

**Level:** senior

Pick by what the data is:

- **A value the parent owns**: give the child a `@Binding`. The most common case.
- **An event**: pass a closure, `let onSelect: (Item) -> Void`. Keeps the child reusable and
  testable.
- **Layout information**, such as a child's size, that the parent needs to arrange things: a
  `PreferenceKey`. The child sets `.preference(key:value:)`, values from all children are combined
  with `reduce`, and the parent reads them with `.onPreferenceChange`. Navigation titles and
  toolbar items travel up the same way.
- **Sizes for a custom arrangement**: often the `Layout` protocol (iOS 16) is the better tool,
  because it measures children and places them in one pass without a second update.

```swift
struct WidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
```

A preference that changes state which changes the preference again causes an update loop;
SwiftUI warns about it at run time ("Bound preference ... tried to update multiple times per
frame").

**References:** [PreferenceKey](https://developer.apple.com/documentation/swiftui/preferencekey) · [Layout](https://developer.apple.com/documentation/swiftui/layout)

## IOS-041: How do you make a SwiftUI view accessible?

**Level:** junior

Standard controls are accessible by default; custom views need help:

- **Labels**: `.accessibilityLabel("Delete")` for icon-only buttons; `Image(decorative:)` or
  `.accessibilityHidden(true)` for images that are only decoration.
- **Grouping**: `.accessibilityElement(children: .combine)` so VoiceOver reads a row as one
  element instead of five.
- **Values and actions**: `.accessibilityValue` for sliders and progress, `.accessibilityAction`
  for gestures such as swipe-to-delete that have no visible button.
- **Traits**: `.accessibilityAddTraits(.isHeader)` makes rotor navigation by headings work.
- **Dynamic Type**: use text styles (`.font(.body)`), avoid fixed frames around text, and switch
  to a vertical layout for accessibility sizes with `ViewThatFits` or `dynamicTypeSize`.
- **Contrast and motion**: respect `accessibilityReduceMotion` and test with Increase Contrast.

Check with the Accessibility Inspector and the Xcode accessibility audit, and test with
VoiceOver on a device. XCTest's `performAccessibilityAudit()` can run the audit in UI tests.

**Reference:** [Accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)

## IOS-042: How do you share a dependency such as an API client through the SwiftUI environment?

**Level:** mid

Define an environment value with the `@Entry` macro and inject it at the root:

```swift
extension EnvironmentValues {
    @Entry var apiClient: any APIClient = LiveAPIClient()
}

ContentView()
    .environment(\.apiClient, MockAPIClient())   // previews and UI tests

struct FeedView: View {
    @Environment(\.apiClient) private var apiClient
}
```

For an `@Observable` model, `.environment(model)` and `@Environment(Model.self)` work without a
key. The environment is good for app-wide services and for swapping implementations in previews.
Two cautions: a missing `@Environment(Model.self)` object crashes at run time (the optional form
`@Environment(Model.self) private var model: Model?` does not), and the environment hides
dependencies, so view models that need the client are often easier to test with plain initializer
injection.

**References:** [Entry()](<https://developer.apple.com/documentation/swiftui/entry()>) · [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues)
