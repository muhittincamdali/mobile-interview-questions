# Testing and tooling

Swift Testing, testable design, profiling and app launch.

## IOS-054: What is Swift Testing, and how is it different from XCTest?

**Level:** junior

Swift Testing is the test framework that ships with Xcode 16 and Swift 6 toolchains:

|                     | Swift Testing                                                    | XCTest                                            |
| ------------------- | ---------------------------------------------------------------- | ------------------------------------------------- |
| Declaring a test    | `@Test func` anywhere, optionally in a `@Suite` type             | methods named `test…` in an `XCTestCase` subclass |
| Assertions          | `#expect(a == b)` shows both values; `#require` stops the test   | `XCTAssertEqual`, `XCTUnwrap`, many variants      |
| Parameterized tests | `@Test(arguments: [...])`, each argument reported separately     | loops inside one test                             |
| Parallelism         | in parallel by default, also within one process                  | serial by default per class                       |
| Traits              | `.tags`, `.disabled`, `.timeLimit`, `.bug`, `.serialized`        | naming conventions and schemes                    |
| Setup               | `init` and `deinit` of the suite type, a fresh instance per test | `setUp` and `tearDown`                            |

Both can live in the same target, so migration can be gradual. UI tests (`XCUIApplication`) and
performance tests (`measure`) still use XCTest. Because tests run in parallel, shared mutable state
between tests is a bug; use instance properties or mark a suite `.serialized`.

The tests that check the Swift answers in this repository use Swift Testing, with
parameterized tests for the edge cases of the command-line parser.

**Reference:** [Swift Testing](https://developer.apple.com/documentation/testing)

## IOS-055: How do you test asynchronous code without `sleep`?

**Level:** mid

Sleeping makes tests slow and still flaky on a busy CI machine. Instead:

- **Await the result directly**: an `async` test can `await` an async function. Most async code
  needs nothing more.
- **Callbacks and events**: Swift Testing's `confirmation(expectedCount:)` checks that an event
  happens the expected number of times inside the closure; XCTest uses `expectation` and
  `fulfillment(of:timeout:)`.
- **Time**: inject a `Clock` (`any Clock<Duration>`) so production uses `ContinuousClock` and the
  test uses a clock it advances by hand; inject a debounce interval instead of hard-coding 300 ms.
- **Ordering**: hold tasks at a known point with a small gate built on continuations, as the actor
  reentrancy test in this repository does, rather than hoping a sleep is long enough.
- **Main actor work**: mark the test `@MainActor` when it touches main-actor types.

```swift
@Test func notifiesOnce() async {
    await confirmation(expectedCount: 1) { confirmed in
        let model = UploadModel(onFinish: { confirmed() })
        await model.upload()
    }
}
```

**Reference:** [Testing asynchronous code](https://developer.apple.com/documentation/testing/testing-asynchronous-code)

## IOS-056: How do you make a view model testable?

**Level:** mid

Give it its dependencies instead of letting it create them:

```swift
protocol ArticleLoading: Sendable {
    func articles() async throws -> [Article]
}

@MainActor @Observable
final class FeedModel {
    private(set) var state: State = .idle
    private let loader: any ArticleLoading
    init(loader: any ArticleLoading) { self.loader = loader }

    func load() async {
        state = .loading
        do { state = .loaded(try await loader.articles()) }
        catch { state = .failed }
    }
}
```

The test passes a stub that returns fixed articles or throws, calls `load()`, and checks `state`.
The same approach works for the clock, `UserDefaults` (an instance with a test suite name), the
current date and UUID generation.

Guidelines: inject through the initializer; keep protocols small and owned by the code that uses
them; avoid singletons inside logic (`URLSession.shared` as a default argument is fine); keep
SwiftUI views thin so the logic worth testing lives in plain types; and prefer stubs and fakes to
mocks that assert call sequences, which break on harmless refactors.

**Reference:** [Swift Testing: Defining test functions](https://developer.apple.com/documentation/testing/definingtests)

## IOS-057: Which Instruments do you use for which performance problem?

**Level:** mid

| Symptom                        | Instrument                                                                   |
| ------------------------------ | ---------------------------------------------------------------------------- |
| UI freezes, slow taps          | _Hangs_ and _Time Profiler_: find work on the main thread                    |
| Janky scrolling and animations | _Animation Hitches_, and the _SwiftUI_ instrument for long view body updates |
| Memory grows over time         | _Allocations_ with generations, _Leaks_ (see IOS-020)                        |
| Slow launch                    | the _App Launch_ template                                                    |
| Battery drain                  | _Energy Log_ on device, _Network_, _Location_                                |
| Slow Swift concurrency code    | _Swift Concurrency_: tasks, actors and time spent waiting for an actor       |

Profile a **Release** build on a **real device**: the simulator uses the Mac's CPU and memory, and
Debug builds are unoptimised. In the field, MetricKit (`MXMetricManager`) delivers daily metrics and
diagnostics such as hang call stacks and crash reports, and Xcode's Organizer shows the same data
aggregated across users.

**References:** [Improving your app's performance](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance) · [MetricKit](https://developer.apple.com/documentation/metrickit)

## IOS-058: How do you reduce app launch time?

**Level:** senior

Measure first: the _App Launch_ instrument, `XCTApplicationLaunchMetric` in a performance test,
and launch times in the Xcode Organizer. Users see the time until the first frame, and the system
terminates apps that take too long to launch.

Before `main`:

- Fewer dynamic frameworks: each one is loaded and bound at launch. Link libraries statically, or
  use mergeable libraries (Xcode 15), which link dynamically in Debug and are merged into the app
  in Release.
- Avoid work in `+load` methods and static initializers that run at load time.

After `main`:

- Do only what the first screen needs in `application(_:didFinishLaunchingWithOptions:)` and
  `scene(_:willConnectTo:options:)`; start SDKs, analytics and migrations later or in the
  background.
- Do not block the main thread on disk or network; show cached content first.
- Keep the first screen's view hierarchy simple and avoid synchronous image decoding there.

Measure warm and cold launches separately; a launch after a reboot or an app update is the
slowest case.

**Reference:** [Reducing your app's launch time](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time)
