# Jetpack Compose Interview Questions

Comprehensive guide to Jetpack Compose concepts, state management, performance, and best practices for Android developers.

---

## Table of Contents

1. [Compose Fundamentals](#compose-fundamentals)
2. [State Management](#state-management)
3. [Lifecycle & Side Effects](#lifecycle--side-effects)
4. [Layouts & Modifiers](#layouts--modifiers)
5. [Navigation](#navigation)
6. [Theming & Styling](#theming--styling)
7. [Performance Optimization](#performance-optimization)
8. [Testing Compose](#testing-compose)
9. [Interoperability](#interoperability)

---

## Compose Fundamentals

### Q1: What is Jetpack Compose and how does it differ from the View system?

**Answer:**

```kotlin
// Traditional View system (XML + Activity/Fragment)
// activity_main.xml
/*
<LinearLayout>
    <TextView android:id="@+id/textView" />
    <Button android:id="@+id/button" />
</LinearLayout>
*/

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        val textView = findViewById<TextView>(R.id.textView)
        val button = findViewById<Button>(R.id.button)
        
        var count = 0
        button.setOnClickListener {
            count++
            textView.text = "Count: $count"  // Manual UI update
        }
    }
}

// Jetpack Compose (Declarative)
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }
    
    Column {
        Text("Count: $count")
        Button(onClick = { count++ }) {
            Text("Increment")
        }
    }
    // UI automatically updates when count changes
}
```

**Key differences:**
- Compose: Declarative UI, Kotlin-only, no XML
- View system: Imperative, XML layouts, manual state management
- Compose: Functions describe UI, recomposition on state change
- View system: Objects represent UI elements, manual invalidation

---

### Q2: Explain @Composable annotation and composable functions

**Answer:**

```kotlin
// @Composable marks a function that can emit UI
@Composable
fun Greeting(name: String) {
    Text(text = "Hello, $name!")
}

// Composable functions can call other composables
@Composable
fun UserProfile(user: User) {
    Column {
        Avatar(url = user.avatarUrl)
        Text(user.name)
        Text(user.email)
    }
}

// Rules for composable functions:
// 1. Can only be called from other composable functions
// 2. Must be fast and side-effect free (pure for UI)
// 3. Can be called multiple times (recomposition)
// 4. Order of calls matters for positional memoization

// Wrong - calling composable from non-composable
fun regularFunction() {
    // Greeting("World") // Compile error!
}

// Composable with return value
@Composable
fun currentUser(): User {
    val context = LocalContext.current
    return remember { loadUser(context) }
}

// Composable lambda
@Composable
fun Card(content: @Composable () -> Unit) {
    Surface(
        elevation = 4.dp,
        shape = RoundedCornerShape(8.dp)
    ) {
        content()
    }
}
```

---

### Q3: What is recomposition and how does Compose optimize it?

**Answer:**

```kotlin
// Recomposition: Re-executing composables when state changes
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }
    
    // This entire function re-executes when count changes
    Column {
        Text("Count: $count")  // Recomposes
        Button(onClick = { count++ }) {
            Text("Increment")  // May skip if unchanged
        }
        StaticText()  // Can skip - no state dependency
    }
}

@Composable
fun StaticText() {
    Text("I never change")  // Skipped during recomposition
}

// Compose optimizations:
// 1. Skip unchanged composables
// 2. Positional memoization
// 3. Smart recomposition (only affected parts)

// Demonstrating skipping
@Composable
fun Parent() {
    var count by remember { mutableStateOf(0) }
    
    Column {
        Text("Parent count: $count")
        Button(onClick = { count++ }) { Text("Increment") }
        
        // Child is skipped if name hasn't changed
        Child(name = "John")
    }
}

@Composable
fun Child(name: String) {
    println("Child recomposed")  // Only prints once
    Text("Hello, $name")
}

// Forcing recomposition with key
@Composable
fun AnimatedItem(item: Item) {
    key(item.id) {  // New key = new composition
        AnimatedVisibility(visible = true) {
            ItemContent(item)
        }
    }
}
```

---

### Q4: Explain the Compose phases: Composition, Layout, and Drawing

**Answer:**

```kotlin
// Phase 1: Composition - What to show
@Composable
fun MyScreen() {
    // Composables executed, UI tree built
    Column {
        Text("Title")
        Button(onClick = {}) { Text("Click") }
    }
}

// Phase 2: Layout - Where to place
@Composable
fun LayoutExample() {
    // Measure and place children
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text("Centered")
    }
}

// Phase 3: Drawing - How to render
@Composable
fun DrawingExample() {
    Canvas(modifier = Modifier.size(100.dp)) {
        drawCircle(
            color = Color.Red,
            radius = size.minDimension / 2
        )
    }
}

// Optimizing each phase
@Composable
fun OptimizedComponent() {
    // Defer state reads to appropriate phase
    var offset by remember { mutableStateOf(0f) }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            // Reading in layout phase, not composition
            .offset { IntOffset(offset.toInt(), 0) }
    ) {
        Text("Moves without recomposition")
    }
}

// graphicsLayer for drawing-only changes
@Composable
fun AnimatedScale() {
    var scale by remember { mutableStateOf(1f) }
    
    Box(
        modifier = Modifier
            .graphicsLayer {
                // Only drawing phase, no recomposition/layout
                scaleX = scale
                scaleY = scale
            }
    )
}
```

---

## State Management

### Q5: Explain remember, mutableStateOf, and rememberSaveable

**Answer:**

```kotlin
// remember - survives recomposition
@Composable
fun RememberExample() {
    // Survives recomposition, lost on configuration change
    var count by remember { mutableStateOf(0) }
    
    Button(onClick = { count++ }) {
        Text("Count: $count")
    }
}

// rememberSaveable - survives configuration changes
@Composable
fun RememberSaveableExample() {
    // Survives rotation, process death
    var count by rememberSaveable { mutableStateOf(0) }
    
    Button(onClick = { count++ }) {
        Text("Count: $count")
    }
}

// Custom saver for complex types
@Parcelize
data class User(val id: String, val name: String) : Parcelable

@Composable
fun UserScreen() {
    var user by rememberSaveable { mutableStateOf(User("1", "John")) }
}

// Manual saver
data class City(val name: String, val country: String)

val CitySaver = run {
    val nameKey = "name"
    val countryKey = "country"
    mapSaver(
        save = { mapOf(nameKey to it.name, countryKey to it.country) },
        restore = { City(it[nameKey] as String, it[countryKey] as String) }
    )
}

@Composable
fun CityScreen() {
    var city by rememberSaveable(stateSaver = CitySaver) {
        mutableStateOf(City("Istanbul", "Turkey"))
    }
}

// remember with keys
@Composable
fun KeyedRemember(userId: String) {
    // Recalculated when userId changes
    val user = remember(userId) {
        loadUser(userId)
    }
}
```

---

### Q6: What is state hoisting and why is it important?

**Answer:**

```kotlin
// Before hoisting - internal state
@Composable
fun InternalStateTextField() {
    var text by remember { mutableStateOf("") }
    
    TextField(
        value = text,
        onValueChange = { text = it }
    )
    // Problem: Parent can't access or control text
}

// After hoisting - state lifted to parent
@Composable
fun HoistedTextField(
    value: String,
    onValueChange: (String) -> Unit
) {
    TextField(
        value = value,
        onValueChange = onValueChange
    )
}

// Parent controls the state
@Composable
fun SearchScreen() {
    var searchQuery by remember { mutableStateOf("") }
    
    Column {
        HoistedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it }
        )
        
        // Can use searchQuery for filtering
        SearchResults(query = searchQuery)
    }
}

// Benefits of state hoisting:
// 1. Single source of truth
// 2. Encapsulation - only parent can modify
// 3. Shareable - multiple components can use same state
// 4. Testable - stateless components are easier to test

// Pattern: State + Event
@Composable
fun Counter(
    count: Int,
    onIncrement: () -> Unit,
    onDecrement: () -> Unit
) {
    Row {
        Button(onClick = onDecrement) { Text("-") }
        Text("$count")
        Button(onClick = onIncrement) { Text("+") }
    }
}

@Composable
fun CounterScreen() {
    var count by remember { mutableStateOf(0) }
    
    Counter(
        count = count,
        onIncrement = { count++ },
        onDecrement = { count-- }
    )
}
```

---

### Q7: Explain ViewModel integration with Compose

**Answer:**

```kotlin
// ViewModel with compose state
class UserViewModel : ViewModel() {
    private val _users = MutableStateFlow<List<User>>(emptyList())
    val users: StateFlow<List<User>> = _users.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    fun loadUsers() {
        viewModelScope.launch {
            _isLoading.value = true
            _users.value = repository.getUsers()
            _isLoading.value = false
        }
    }
}

// Collecting state in Compose
@Composable
fun UserScreen(
    viewModel: UserViewModel = viewModel()
) {
    val users by viewModel.users.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    if (isLoading) {
        CircularProgressIndicator()
    } else {
        LazyColumn {
            items(users) { user ->
                UserItem(user)
            }
        }
    }
}

// Using StateFlow with initial value
@Composable
fun UserScreenWithInitial(
    viewModel: UserViewModel = viewModel()
) {
    val users by viewModel.users.collectAsState(initial = emptyList())
}

// UI State pattern
data class UserUiState(
    val users: List<User> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

class UserViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(UserUiState())
    val uiState: StateFlow<UserUiState> = _uiState.asStateFlow()
    
    fun loadUsers() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val users = repository.getUsers()
                _uiState.update { it.copy(users = users, isLoading = false) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message, isLoading = false) }
            }
        }
    }
}

@Composable
fun UserScreenWithUiState(
    viewModel: UserViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    when {
        uiState.isLoading -> LoadingScreen()
        uiState.error != null -> ErrorScreen(uiState.error!!)
        else -> UserList(uiState.users)
    }
}
```

---

### Q8: What is derivedStateOf and when should you use it?

**Answer:**

```kotlin
// Problem: Expensive computation on every recomposition
@Composable
fun BadExample(items: List<Item>) {
    val filteredItems = items.filter { it.isActive }  // Runs every recomposition
    
    LazyColumn {
        items(filteredItems) { item ->
            ItemRow(item)
        }
    }
}

// Solution: derivedStateOf for computed state
@Composable
fun GoodExample(items: List<Item>) {
    val filteredItems by remember(items) {
        derivedStateOf { items.filter { it.isActive } }
    }
    
    // Only recalculated when items changes AND filter result differs
    LazyColumn {
        items(filteredItems) { item ->
            ItemRow(item)
        }
    }
}

// Common use case: Scroll state dependent UI
@Composable
fun ScrollDependentUI() {
    val listState = rememberLazyListState()
    
    // Derived state prevents unnecessary recompositions
    val showButton by remember {
        derivedStateOf {
            listState.firstVisibleItemIndex > 5
        }
    }
    
    Box {
        LazyColumn(state = listState) {
            items(100) { Text("Item $it") }
        }
        
        if (showButton) {
            FloatingActionButton(
                onClick = { /* scroll to top */ }
            ) {
                Icon(Icons.Default.ArrowUpward, null)
            }
        }
    }
}

// Combining multiple states
@Composable
fun SearchScreen() {
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("All") }
    val items = remember { loadItems() }
    
    val filteredItems by remember(items) {
        derivedStateOf {
            items.filter { item ->
                item.name.contains(query, ignoreCase = true) &&
                (category == "All" || item.category == category)
            }
        }
    }
}
```

---

## Lifecycle & Side Effects

### Q9: Explain LaunchedEffect and its use cases

**Answer:**

```kotlin
// LaunchedEffect - run suspend functions in composition
@Composable
fun LaunchedEffectExample(userId: String) {
    var user by remember { mutableStateOf<User?>(null) }
    
    // Runs when userId changes
    LaunchedEffect(userId) {
        user = fetchUser(userId)
    }
    
    user?.let { UserProfile(it) }
}

// One-time effect
@Composable
fun OneTimeEffect() {
    LaunchedEffect(Unit) {  // Unit = runs once
        analytics.logScreenView("Home")
    }
}

// Cancellation on key change
@Composable
fun SearchWithDebounce(query: String) {
    var results by remember { mutable