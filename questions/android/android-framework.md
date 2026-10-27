# Android framework and Jetpack

Life cycle, ViewModel, Compose, background work, platform behaviour changes and performance. The
Kotlin snippets are not compiled by this repository's CI; each answer links to the Android
documentation it follows.

## AND-007: Describe the Activity life cycle and what happens on a configuration change.

**Level:** junior

`onCreate` → `onStart` (visible) → `onResume` (in the foreground, receiving input) → `onPause` →
`onStop` (no longer visible) → `onDestroy`. Returning to a stopped activity calls `onRestart`,
`onStart` and `onResume`.

A **configuration change** (rotation, dark mode, language, font size, resizing in multi-window or
on a foldable) destroys and recreates the activity by default, so everything stored in its fields
is lost. What survives:

- a `ViewModel`, which lives in the `ViewModelStore` across the recreation,
- state saved in `onSaveInstanceState` or `rememberSaveable`, which also survives **process death**,
- persisted data.

Handling configuration changes yourself with `android:configChanges` avoids the recreation but
makes you responsible for updating every resource-dependent value; it is reasonable for a video
player or a game, not as a general fix. Since Android 16 apps on large screens are resized much
more often (see AND-018), so code that assumes a stable configuration breaks sooner.

**References:** [The activity lifecycle](https://developer.android.com/guide/components/activities/activity-lifecycle) · [Handle configuration changes](https://developer.android.com/guide/topics/resources/runtime-changes)

## AND-008: What does a ViewModel survive, and how do you handle process death?

**Level:** mid

A `ViewModel` survives configuration changes but **not process death**. When the app is in the
background, the system can kill the process to reclaim memory; when the user returns, Android
recreates the back stack, and every ViewModel starts empty.

Keep the small pieces of state needed to restore the screen in `SavedStateHandle`, which is saved
with the instance state:

```kotlin
class SearchViewModel(private val savedState: SavedStateHandle, private val repo: SearchRepository) : ViewModel() {
    val query: StateFlow<String> = savedState.getStateFlow("query", "")
    fun onQueryChange(value: String) { savedState["query"] = value }
}
```

Store IDs and user input there, not large lists (the saved state goes through a Binder transaction
with a limit of about 1 MB shared by the whole process), and reload the data from the repository.
Test it with "Don't keep activities" in the developer options, or by putting the app in the
background and running `adb shell am kill <package>`.

**References:** [ViewModel overview](https://developer.android.com/topic/libraries/architecture/viewmodel) · [Saved State module for ViewModel](https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate)

## AND-009: What is recomposition, and what do `remember`, `rememberSaveable` and state hoisting mean?

**Level:** mid

A composable function describes UI from its inputs. When a `State` it reads changes, Compose
**recomposes**: it calls the function again and updates only what changed. Recomposition can happen
often, in any order and may be skipped, so composables must be free of side effects.

- `remember { }` keeps a value across recompositions of the same call site; it is lost when the
  composable leaves the composition.
- `rememberSaveable { }` also survives configuration changes and process death by saving into the
  instance state (the value must be saveable, or you provide a `Saver`).
- **State hoisting** moves state to the caller: the composable takes `value` and `onValueChange`
  instead of owning the state. That makes it reusable, testable and previewable, and gives one
  source of truth.

```kotlin
@Composable
fun SearchField(query: String, onQueryChange: (String) -> Unit) {
    TextField(value = query, onValueChange = onQueryChange)
}
```

Screen-level state normally lives in a ViewModel and reaches the screen as a `StateFlow`
collected with `collectAsStateWithLifecycle` (AND-006).

**References:** [State and Jetpack Compose](https://developer.android.com/develop/ui/compose/state) · [Where to hoist state](https://developer.android.com/develop/ui/compose/state-hoisting)

## AND-010: What is stability in Compose, and what does strong skipping change?

**Level:** senior

Compose can **skip** recomposing a composable when its parameters are equal to the previous call.
To compare safely it needs to know whether a type is **stable**: its `equals` result will not change
without Compose being notified. Primitives, `String`, function types, and classes with only `val`
properties of stable types are stable; `List<T>` is an interface and treated as unstable, and
classes from modules without the Compose compiler are unstable too.

**Strong skipping mode**, enabled by default since Kotlin 2.0.20 with the Compose compiler Gradle
plugin, relaxes this: composables with unstable parameters can be skipped too, compared by instance
identity (`===`), and lambdas are remembered automatically. Most stability work becomes
unnecessary, but passing a new list instance on every recomposition still prevents skipping.

Tools: the Compose compiler reports (`reportsDestination`) show which classes and composables are
stable or skippable; Layout Inspector shows recomposition counts. Fixes include immutable
collections (`kotlinx.collections.immutable`), `@Immutable` or `@Stable` annotations, and a
stability configuration file for types you do not own.

**Reference:** [Stability in Compose](https://developer.android.com/develop/ui/compose/performance/stability)

## AND-011: Which Compose side-effect APIs do you use, and when?

**Level:** mid

| API                             | Use it for                                                                                                                                     |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `LaunchedEffect(key)`           | Running a suspend function when the composable enters, restarting when `key` changes, cancelled when it leaves                                 |
| `rememberCoroutineScope()`      | Starting coroutines from event callbacks (a button tap scrolling a list)                                                                       |
| `DisposableEffect(key)`         | Registering and unregistering a listener or observer with an `onDispose` cleanup                                                               |
| `SideEffect`                    | Publishing Compose state to non-Compose code after every successful recomposition                                                              |
| `rememberUpdatedState(value)`   | Reading the latest value inside a long-lived effect without restarting it                                                                      |
| `derivedStateOf { }`            | A value computed from other state that changes less often than its inputs, such as "show the scroll-to-top button" from the first visible item |
| `produceState` / `snapshotFlow` | Converting between non-Compose sources and Compose state                                                                                       |

Using `LaunchedEffect(Unit)` for something that depends on a parameter is a common bug: the effect
does not restart when the parameter changes. Pass the parameter as the key.

**Reference:** [Side-effects in Compose](https://developer.android.com/develop/ui/compose/side-effects)

## AND-012: How do you keep a `LazyColumn` fast and correct?

**Level:** mid

- Pass a stable `key` per item (`items(list, key = { it.id })`), so state such as an expanded row or
  scroll position follows the item when the list changes, and animations with `Modifier.animateItem()`
  work.
- Pass `contentType` when rows have different layouts, so compositions are reused only between
  rows of the same kind.
- Avoid heavy work in item composables: format and sort in the ViewModel.
- Do not nest a scrollable list in another scrollable container in the same direction without
  fixed height; use one `LazyColumn` with different item types instead.
- Read scroll state in a `derivedStateOf` or in a lambda modifier, so the whole screen does not
  recompose on every scroll pixel.

Measure in a release build with R8 and a Baseline Profile (AND-019); debug builds of Compose are
much slower and not representative.

**References:** [Lists and grids](https://developer.android.com/develop/ui/compose/lists) · [Follow best practices (Compose performance)](https://developer.android.com/develop/ui/compose/performance/bestpractices)

## AND-013: Why use Hilt, and how does it scope dependencies?

**Level:** mid

Hilt is the dependency injection library recommended for Android, built on Dagger. It generates
the dependency graph at compile time, so a missing binding fails the build rather than crashing at
run time, and it provides containers that match Android classes:

- `@HiltAndroidApp` on the `Application` creates the app-level component.
- `@AndroidEntryPoint` on activities, fragments and services injects their fields.
- `@HiltViewModel` with an `@Inject constructor` lets `hiltViewModel()` create ViewModels with
  their dependencies and a `SavedStateHandle`.
- `@Module` with `@InstallIn(SingletonComponent::class)` provides types you cannot annotate, such
  as a Retrofit instance; `@Binds` maps an interface to an implementation.

Scopes (`@Singleton`, `@ActivityRetainedScoped`, `@ViewModelScoped`) keep one instance per
component lifetime; unscoped bindings create a new instance every time, which is the cheaper
default. Tests replace modules with `@TestInstallIn` or `@BindValue`.

**Reference:** [Dependency injection with Hilt](https://developer.android.com/training/dependency-injection/hilt-android)

## AND-014: When do you use WorkManager, a foreground service or a coroutine?

**Level:** mid

- **A coroutine in `viewModelScope` or `lifecycleScope`**: work that only matters while the user is
  on the screen. It stops when the scope ends.
- **WorkManager**: deferrable work that must eventually run even if the app exits or the device
  restarts: uploads, syncs, log cleanup. It persists requests, supports constraints (network,
  charging), retries with back-off, chains and unique work. `setExpedited` asks for prompt
  execution of short, important jobs.
- **A foreground service**: work the user is aware of and that must keep running now, with a
  visible notification: navigation, music playback, an ongoing call. Since Android 14 every
  foreground service must declare a **type** (`location`, `mediaPlayback`, `dataSync`, …) and the
  matching permission, and starting one from the background is heavily restricted.

For a user-initiated large transfer, WorkManager with a foreground notification, or the
user-initiated data transfer jobs added in Android 14, are designed for the case; a plain
`Service` without a notification is stopped soon after the app leaves the foreground.

**References:** [Guide to background work](https://developer.android.com/develop/background-work/background-tasks) · [Foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types)

## AND-015: How do you build an offline-first screen with Room?

**Level:** mid

Make the local database the **single source of truth**: the UI observes Room, and the network only
updates Room.

```kotlin
@Dao
interface ArticleDao {
    @Query("SELECT * FROM article ORDER BY published DESC")
    fun observeAll(): Flow<List<ArticleEntity>>

    @Upsert
    suspend fun upsertAll(articles: List<ArticleEntity>)
}

class ArticleRepository(private val dao: ArticleDao, private val api: ArticleApi) {
    val articles: Flow<List<Article>> = dao.observeAll().map { rows -> rows.map { it.toModel() } }
    suspend fun refresh() = dao.upsertAll(api.latest().map { it.toEntity() })
}
```

A `Flow` returned by a DAO emits again whenever the table changes, so the screen updates by itself
after `refresh()`. Writes made offline go into the database with a "pending" marker and are sent by
a WorkManager job with a network constraint. Plan **migrations** from the first release
(`autoMigrations` or `Migration` objects, tested with `MigrationTestHelper`); a missing migration
crashes on update or, with `fallbackToDestructiveMigration`, deletes user data.

**References:** [Save data in a local database using Room](https://developer.android.com/training/data-storage/room) · [Build an offline-first app](https://developer.android.com/topic/architecture/data-layer/offline-first)

## AND-016: What changed with edge-to-edge in Android 15, and how do you handle insets?

**Level:** mid

Apps that target Android 15 (API 35) are displayed **edge-to-edge** by default on Android 15
devices: the app draws behind the status bar and the navigation bar, and the old options to opt out
are deprecated. Content that ignores insets ends up under the system bars or the display cutout.

Handle it explicitly:

- Call `enableEdgeToEdge()` in the activity so behaviour is the same on older versions too.
- In Compose, apply insets where content must stay clear: `Modifier.safeDrawingPadding()`,
  `windowInsetsPadding(WindowInsets.systemBars)`, or the `contentWindowInsets` of `Scaffold`;
  Material 3 components such as `TopAppBar` and `NavigationBar` handle their own.
- In Views, use `ViewCompat.setOnApplyWindowInsetsListener` and pad the views that need it.
- Keep backgrounds edge-to-edge and pad only the interactive content, and check the IME insets
  (`WindowInsets.ime`) for screens with text input.

**References:** [Display content edge-to-edge in views](https://developer.android.com/develop/ui/views/layout/edge-to-edge) · [About window insets (Compose)](https://developer.android.com/develop/ui/compose/system/insets)

## AND-017: What is predictive back, and how do you support it?

**Level:** mid

Predictive back shows a preview of where the back gesture leads (the home screen, the previous
activity, or an in-app destination) while the user is still swiping, and lets them cancel. To make
that possible the system must know in advance whether the app will handle back, so the old model of
overriding `onBackPressed()` and deciding at the last moment does not work.

- Register back handling ahead of time with `OnBackPressedDispatcher` and an
  `OnBackPressedCallback` whose `isEnabled` reflects whether you want to intercept (for example,
  only when a form has unsaved changes); in Compose use `BackHandler(enabled = …)` or
  `PredictiveBackHandler` for custom animations.
- Opt in with `android:enableOnBackInvokedCallback="true"` in the manifest. For apps that target
  Android 16 (API 36) the system back animations are on by default and `onBackPressed` is no longer
  called.
- Navigation Compose and Fragments with recent AndroidX versions animate predictive back between
  destinations.

**Reference:** [Add support for the predictive back gesture](https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture)

## AND-018: What changes for apps on large screens when they target Android 16?

**Level:** senior

For apps that target Android 16 (API 36), the system ignores orientation, aspect-ratio and
resizability restrictions on displays whose smallest width is at least 600 dp (sw600dp: tablets,
unfolded foldables, desktop windows): `screenOrientation`, `resizeableActivity="false"`, `minAspectRatio` and
`maxAspectRatio` no longer letterbox or lock the app there. Games are excluded, and there was a
temporary opt-out for apps that need more time.

That means a portrait-only phone layout will be shown in landscape and in resizable windows. What
to do:

- Build adaptive layouts from **window size classes** (`currentWindowAdaptiveInfo()`) rather than
  device type or orientation: list-detail on wide windows, a navigation rail instead of a bottom bar.
- Make sure state survives the more frequent configuration changes (AND-007, AND-008).
- Avoid assumptions such as a fixed camera preview orientation, and test in the resizable emulator
  and on a foldable.

**Reference:** [Behavior changes: Apps targeting Android 16](https://developer.android.com/about/versions/16/behavior-changes-16)

## AND-019: How do R8 and Baseline Profiles improve an Android app?

**Level:** senior

- **R8** shrinks, optimises and obfuscates the code of release builds: it removes unused classes
  and members, inlines and devirtualises calls, and renames symbols. Code reached only by
  reflection (some serialisation libraries, JNI) needs keep rules, otherwise it crashes at run
  time; keep the generated mapping file to read crash stack traces.
- **Baseline Profiles** list the classes and methods used during start-up and key user journeys.
  They ship with the app, and Android Runtime compiles those paths ahead of time at install,
  instead of interpreting and JIT compiling them on first use. The Baseline Profiles overview
  credits them with about 30 % faster code execution from the first launch. Generate them with the
  Macrobenchmark `BaselineProfileRule` and the Baseline Profile Gradle plugin; Compose and other Jetpack libraries
  ship their own.
- **Startup Profiles** additionally tell R8 how to lay out the DEX files so start-up code is
  together.

Measure start-up with Macrobenchmark (`StartupTimingMetric`) on a physical device in release mode;
emulators and debug builds give misleading numbers.

**References:** [Shrink, obfuscate, and optimize your app](https://developer.android.com/build/shrink-code) · [Baseline Profiles overview](https://developer.android.com/topic/performance/baselineprofiles/overview)

## AND-020: What causes an ANR, and how do you find and prevent it?

**Level:** mid

An "Application Not Responding" dialog appears when the main thread cannot respond in time: for
example an input event not handled within 5 seconds, a `BroadcastReceiver` that does not finish,
or a service that does not start in time. Google Play's Android vitals counts ANRs, and a high
rate affects how the app is shown in the store.

Common causes: disk or network I/O on the main thread (including `SharedPreferences.commit()` and
large database queries), lock contention with a background thread, slow `onCreate` work, binder
calls to slow system services, and deadlocks.

Finding them: the ANR traces in Play Console and `ApplicationExitInfo` on the device (Android 11+)
include the main thread's stack; `StrictMode` with `detectDiskReads()` and `detectNetwork()` in debug
builds flags violations as they happen; and Perfetto traces show what the main thread was doing.
Prevention is moving work to coroutines on `Dispatchers.IO` or `Default`, and keeping
`BroadcastReceiver.onReceive` short (use `goAsync` or WorkManager).

**References:** [ANRs](https://developer.android.com/topic/performance/vitals/anr) · [StrictMode](https://developer.android.com/reference/android/os/StrictMode)

## AND-021: How do runtime permissions work, and when do you not need a permission at all?

**Level:** junior

Dangerous permissions (camera, location, microphone, contacts, notifications since Android 13) must
be declared in the manifest **and** requested at run time. In code, register
`ActivityResultContracts.RequestPermission` (or `RequestMultiplePermissions`), show the request when
the user starts the feature that needs it, and handle denial gracefully;
`shouldShowRequestPermissionRationale` tells you when to explain first. After two denials the system
stops showing the dialog, so offer a path to the app settings.

Often no permission is needed:

- The **photo picker** (`PickVisualMedia`) gives access to selected images and videos without
  storage permissions.
- The system **document picker** and `ACTION_CREATE_DOCUMENT` for files.
- An intent to the camera app (`TakePicture`) instead of the camera permission, when you only need
  a photo.
- **Approximate location** is enough for weather or nearby content.

Google Play reviews requests for sensitive permissions such as `READ_MEDIA_IMAGES` and background
location, and rejects apps that do not need them.

**References:** [Request runtime permissions](https://developer.android.com/training/permissions/requesting) · [Photo picker](https://developer.android.com/training/data-storage/shared/photo-picker)

## AND-022: How do you structure a large Android project in Gradle modules?

**Level:** senior

Split by feature and by layer so teams can work independently and Gradle can build in parallel and
reuse cached outputs:

- `:app` — wires the features together, little code of its own.
- `:feature:*` — one module per feature (UI and ViewModels), depending only on core modules, never
  on other features. Navigation between features goes through routes defined in a shared module.
- `:core:*` — data, database, network, design system, testing utilities.

Supporting practices:

- A **version catalog** (`gradle/libs.versions.toml`) keeps dependency versions in one place.
- **Convention plugins** in an included `build-logic` build share the Android, Kotlin and Compose
  configuration instead of copying it into every `build.gradle.kts`.
- Use `implementation` rather than `api` so changes in a module do not recompile its dependents'
  dependents.
- Turn on the configuration cache and the build cache, and check build scans for slow tasks.

The Now in Android sample app follows this structure and is a good reference in an interview.

**References:** [Guide to Android app modularization](https://developer.android.com/topic/modularization) · [Migrate your build to version catalogs](https://developer.android.com/build/migrate-to-catalogs)
