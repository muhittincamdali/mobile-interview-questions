# UIKit and the app life cycle

Scenes, view controllers, mixing UIKit with SwiftUI, background work and links into the app.

## IOS-043: What is the scene-based life cycle, and why does it matter for apps built with the iOS 27 SDK?

**Level:** mid

Since iOS 13 an app's UI lives in **scenes** (`UIWindowScene`), each with its own window and its
own life cycle: `sceneWillEnterForeground`, `sceneDidBecomeActive`, `sceneWillResignActive`,
`sceneDidEnterBackground`, delivered to a `UISceneDelegate`. The `UIApplicationDelegate` keeps the
process-level events: launch, push notification registration, and creating scene
configurations. On iPad, Mac and visionOS one app can show several scenes at once, so
"the app is in the background" and "this window is in the background" are different states.

Apple's technote TN3187 announced that apps built with the SDK released after iOS 26, which is
the iOS 27 SDK, must adopt the scene life cycle; an app without a scene configuration does not
launch. Migrating an older app means:

1. Add `UIApplicationSceneManifest` to the Info.plist (or return a `UISceneConfiguration` from
   `application(_:configurationForConnecting:options:)`).
2. Move window setup from `application(_:didFinishLaunchingWithOptions:)` to
   `scene(_:willConnectTo:options:)`, and foreground/background handling to the scene delegate.
3. Read URLs, user activities and shortcut items from `connectionOptions` at launch and from the
   scene delegate's callbacks afterwards, instead of the app delegate.
4. Replace `UIApplication.shared.windows` and `keyWindow` with the window of the relevant scene.

A SwiftUI app that uses the `App` protocol already runs on scenes.

**References:** [TN3187: Migrating to the UIKit scene-based life cycle](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle) · [Managing your app's life cycle](https://developer.apple.com/documentation/uikit/managing-your-app-s-life-cycle)

## IOS-044: Describe the `UIViewController` life cycle.

**Level:** junior

1. `init` (from code or a storyboard) — no view yet.
2. `loadView` — creates `view`; override only to supply a custom root view, without calling super.
3. `viewDidLoad` — once per controller: one-time setup, constraints, subscriptions.
4. `viewWillAppear(_:)` — each time before the view is shown: refresh data that may have changed.
5. `viewIsAppearing(_:)` (iOS 17, back-deployed to iOS 13) — the view is in the hierarchy with
   its trait collection and an accurate size; the right place for work that depends on geometry
   or traits.
6. `viewWillLayoutSubviews` / `viewDidLayoutSubviews` — can run many times; keep them cheap.
7. `viewDidAppear(_:)` — on screen: start animations, analytics "screen viewed" events.
8. `viewWillDisappear(_:)` / `viewDidDisappear(_:)` — stop work that only matters on screen.
9. `deinit` — when the last reference goes; if it never runs after you leave a screen, something
   keeps the controller alive (see IOS-018).

`viewDidUnload` has been gone since iOS 6; views are no longer unloaded under memory pressure.
Trait changes are observed with `registerForTraitChanges(_:handler:)` (iOS 17) instead of
`traitCollectionDidChange(_:)`.

**References:** [UIViewController](https://developer.apple.com/documentation/uikit/uiviewcontroller) · [viewIsAppearing(_:)](<https://developer.apple.com/documentation/uikit/uiviewcontroller/viewisappearing(_:)>)

## IOS-045: How do you use SwiftUI inside UIKit, and UIKit inside SwiftUI?

**Level:** mid

**SwiftUI in UIKit**: wrap the view in a `UIHostingController` and add it as a child view
controller, so it gets the life-cycle and trait events:

```swift
let host = UIHostingController(rootView: SettingsView(model: model))
addChild(host)
view.addSubview(host.view)
host.view.translatesAutoresizingMaskIntoConstraints = false
// pin constraints ...
host.didMove(toParent: self)
```

Set `sizingOptions = .intrinsicContentSize` when Auto Layout should size it from its content. For
table and collection view cells, `UIHostingConfiguration` (iOS 16) puts SwiftUI in a cell without
a hosting controller per cell.

**UIKit in SwiftUI**: implement `UIViewRepresentable` (or `UIViewControllerRepresentable`):

- `makeUIView(context:)` creates the view once,
- `updateUIView(_:context:)` copies SwiftUI state into it on every update,
- `makeCoordinator()` returns an object that acts as the delegate or target and sends changes
  back through `@Binding`s,
- `sizeThatFits(_:uiView:context:)` (iOS 16) reports a size.

A frequent bug is doing setup in `updateUIView`, which runs many times, or writing to a binding
synchronously inside it, which triggers another update.

**References:** [UIHostingController](https://developer.apple.com/documentation/swiftui/uihostingcontroller) · [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)

## IOS-046: What are content hugging and compression resistance priorities?

**Level:** mid

Views with an **intrinsic content size** (labels, buttons, image views) tell Auto Layout how big
they would like to be. Two priorities decide what happens when the constraints give more or less
space than that:

- **Content hugging**: resistance to growing **larger** than the intrinsic size. The view with the
  higher hugging priority stays at its natural size; the other one stretches.
- **Compression resistance**: resistance to shrinking **smaller** than the intrinsic size. When
  space runs out, the view with the lower priority is truncated first.

Example: a title label and a date label side by side. Give the date label higher hugging (250 → 251) so the title takes the extra space, and higher compression resistance (750 → 751) so the
title truncates instead of the date.

```swift
dateLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
dateLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
```

Ambiguous layouts, where two views have the same priorities, show up in the view debugger and as
"Unable to simultaneously satisfy constraints" logs. SwiftUI's equivalents are
`.layoutPriority(_:)` and `.fixedSize()`.

**Reference:** [Auto Layout Guide: Views with Intrinsic Content Size](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html)

## IOS-047: How do you run work in the background on iOS?

**Level:** senior

iOS suspends apps shortly after they leave the foreground, so background work must use an API
that the system schedules:

| Need                                                                                                    | API                                                                                            |
| ------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Finish a short task the user started (save, upload a small file)                                        | `beginBackgroundTask(withName:expirationHandler:)`: a few seconds to finish, then end the task |
| Refresh content periodically                                                                            | `BGAppRefreshTask` via `BGTaskScheduler`; the system decides when, based on usage              |
| Long maintenance work (database cleanup, model training)                                                | `BGProcessingTask`, can require power and network                                              |
| Continue a user-started job with visible progress (export, upload) after the app goes to the background | `BGContinuedProcessingTask` (iOS 26), shown with system progress UI                            |
| Large downloads and uploads                                                                             | A background `URLSession` configuration; transfers continue even if the app is terminated      |
| Server-triggered updates                                                                                | Background push notifications (`content-available`), which are throttled                       |

Background task identifiers must be listed under `BGTaskSchedulerPermittedIdentifiers` in the
Info.plist and registered before launch finishes. Every handler must set an expiration handler
and call `setTaskCompleted(success:)`. Nothing guarantees exact timing, so design for "eventually",
and test with the debugger command `e -l objc -- (void)[[BGTaskScheduler sharedScheduler]
_simulateLaunchForTaskWithIdentifier:@"id"]`.

**References:** [Choosing Background Strategies for Your App](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app) · [BGContinuedProcessingTask](https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask)

## IOS-048: What is the difference between universal links and custom URL schemes?

**Level:** mid

- A **custom URL scheme** (`myapp://item/42`) is declared in the Info.plist. Any app can claim the
  same scheme, there is no fallback when the app is not installed, and Safari asks the user before
  opening it. Fine for callbacks between your own apps, not for links you publish.
- A **universal link** is a normal `https://example.com/item/42` URL. The domain proves ownership
  by serving an `apple-app-site-association` file at `/.well-known/`, and the app lists
  `applinks:example.com` in its Associated Domains entitlement. If the app is installed the link
  opens it; otherwise the website opens. Nobody else can claim your domain.

Handling: in a scene-based app, links arrive in `scene(_:willConnectTo:options:)` at launch and
`scene(_:continue:)` afterwards; in SwiftUI, `.onOpenURL` and `.onContinueUserActivity`.

Common pitfalls: the association file must be served over HTTPS without redirects; Apple's CDN
caches it, so changes take time to reach devices (the `?mode=developer` option on the entitlement
bypasses the CDN during development); and links typed in Safari's address bar or opened from the
same domain open the website, not the app.

**References:** [Supporting universal links in your app](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app) · [Defining a custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
