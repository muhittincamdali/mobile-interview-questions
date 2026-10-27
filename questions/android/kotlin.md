# Kotlin and coroutines

Kotlin language, coroutines and Flow. The Kotlin snippets here are not compiled by this
repository's CI; each answer links to the Kotlin or Android documentation it follows.

## AND-001: How does Kotlin's null safety work, and when do you use `lateinit` or `lazy`?

**Level:** junior

Types are non-null by default; `String?` can hold `null` and must be checked before use. The
compiler smart-casts after a check (`if (name != null) name.length`).

- `a?.b` — safe call, `null` if `a` is null. `a?.let { … }` runs a block only for non-null values.
- `a ?: b` — the Elvis operator, `b` when `a` is null; often `?: return` or `?: error("…")`.
- `a!!` — throws `NullPointerException` if `a` is null. Treat each one as a crash waiting to
  happen.
- `lateinit var` — a non-null `var` initialised later (dependency injection, `onCreate`); reading
  it first throws `UninitializedPropertyAccessException`. Not allowed for primitive types.
- `val x by lazy { … }` — computed on first access and cached; thread-safe by default
  (`LazyThreadSafetyMode.SYNCHRONIZED`).

Values coming from Java APIs have **platform types** (`String!`) whose nullability the compiler
does not know; annotate the Java code or treat them as nullable.

**Reference:** [Null safety](https://kotlinlang.org/docs/null-safety.html)

## AND-002: What are data classes and sealed interfaces used for?

**Level:** junior

A `data class` generates `equals`, `hashCode`, `toString`, `copy` and `componentN` from the
properties in its primary constructor. It is the usual type for UI state and models, and
`state.copy(isLoading = false)` creates an updated immutable copy.

A `sealed interface` (or `sealed class`) has a closed set of subtypes known at compile time, so a
`when` over it is exhaustive without an `else`, and adding a case flags every `when` that misses
it:

```kotlin
sealed interface UiState {
    data object Loading : UiState
    data class Success(val items: List<Item>) : UiState
    data class Error(val message: String) : UiState
}

when (state) {
    UiState.Loading -> ShowSpinner()
    is UiState.Success -> ShowList(state.items)   // smart cast
    is UiState.Error -> ShowError(state.message)
}
```

`data object` gives an object a readable `toString`. Only constructor properties take part in
`equals`; properties declared in the body do not.

**References:** [Data classes](https://kotlinlang.org/docs/data-classes.html) · [Sealed classes and interfaces](https://kotlinlang.org/docs/sealed-classes.html)

## AND-003: What is structured concurrency in Kotlin coroutines?

**Level:** mid

Every coroutine is launched in a `CoroutineScope`, and the scope's `Job` is the parent of the
coroutines it starts. That gives three guarantees:

1. A parent completes only when all its children have completed.
2. Cancelling the scope cancels all its children, for example `viewModelScope` when the ViewModel
   is cleared, or `lifecycleScope` when the lifecycle is destroyed.
3. A failing child cancels its parent and siblings (unless the scope uses a `SupervisorJob`).

```kotlin
viewModelScope.launch {
    val profile = async { repository.profile() }
    val feed = async { repository.feed() }
    _state.value = UiState.Success(profile.await(), feed.await())
}
```

Dispatchers choose the threads: `Dispatchers.Main` for UI, `Dispatchers.IO` for blocking I/O,
`Dispatchers.Default` for CPU work. Suspending functions should be **main-safe**: they switch with
`withContext(Dispatchers.IO)` internally, so callers can call them from the main thread.
`GlobalScope` breaks structured concurrency and should be avoided.

**References:** [Coroutines basics](https://kotlinlang.org/docs/coroutines-basics.html) · [Kotlin coroutines on Android](https://developer.android.com/kotlin/coroutines)

## AND-004: How do exceptions behave in `launch` and `async`?

**Level:** senior

- In `launch`, an uncaught exception propagates to the parent immediately, cancels the parent and
  its other children, and finally reaches the scope's `CoroutineExceptionHandler` (or crashes the
  app).
- In `async`, the exception is stored in the `Deferred` and rethrown by `await()`; but as a child
  of a regular `Job`, it still cancels the parent at the moment it fails, even before anyone calls
  `await`. Wrapping only `await()` in `try` does not prevent that.
- Under a `SupervisorJob` (or inside `supervisorScope`), a failing child does not cancel its
  siblings or the parent. `viewModelScope` uses a `SupervisorJob`, so one failed `launch` does not
  stop the others.

Rules of thumb: catch exceptions inside the coroutine where you can handle them; use
`supervisorScope` when independent tasks should fail independently; never catch
`CancellationException` without rethrowing it, because that breaks cancellation (a bare
`catch (e: Exception)` around a suspend call does exactly that). `runCatching` has the same trap.

**Reference:** [Coroutine exceptions handling](https://kotlinlang.org/docs/exception-handling.html)

## AND-005: What is the difference between `Flow`, `StateFlow` and `SharedFlow`?

**Level:** mid

- A plain `Flow` is **cold**: the code in `flow { }` runs again for each collector, starting when
  it collects. Good for a database query or a request.
- `StateFlow` is **hot** and always has a value. Collectors get the current value first and then
  updates; equal consecutive values are skipped (`distinctUntilChanged`). It is the standard
  holder for UI state in a ViewModel.
- `SharedFlow` is **hot** and has no current value by default. It broadcasts emissions to all
  current collectors and can be configured with `replay` and a buffer. Use it for events, though
  one-off UI events are often better modelled as state that the UI consumes.

```kotlin
val uiState: StateFlow<UiState> = repository.items()
    .map { UiState.Success(it) }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState.Loading)
```

`WhileSubscribed(5_000)` keeps the upstream running for five seconds after the last collector
leaves, so a configuration change does not restart the query.

**References:** [Kotlin flows on Android](https://developer.android.com/kotlin/flow) · [StateFlow and SharedFlow](https://developer.android.com/kotlin/flow/stateflow-and-sharedflow)

## AND-006: How do you collect a Flow safely in the UI?

**Level:** mid

Collect only while the UI is visible, otherwise the app keeps working, and may update views,
while it is in the background.

In **Compose**, use `collectAsStateWithLifecycle()` from `lifecycle-runtime-compose`; it collects
while the lifecycle is at least `STARTED`:

```kotlin
val state by viewModel.uiState.collectAsStateWithLifecycle()
```

In **Views**, use `repeatOnLifecycle`, which starts collecting at `STARTED` and cancels at `STOP`,
and restarts when the screen returns:

```kotlin
viewLifecycleOwner.lifecycleScope.launch {
    viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.uiState.collect { render(it) }
    }
}
```

`lifecycleScope.launch { flow.collect { } }` alone keeps collecting until the lifecycle is
destroyed, and the deprecated `launchWhenStarted` only suspends the collector, leaving the upstream
running. In Fragments use `viewLifecycleOwner`, not the Fragment itself, because the view is
destroyed before the Fragment.

**Reference:** [Use Kotlin coroutines with lifecycle-aware components](https://developer.android.com/topic/libraries/architecture/coroutines)
