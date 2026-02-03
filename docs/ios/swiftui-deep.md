# SwiftUI Deep Dive Interview Questions

Comprehensive guide to advanced SwiftUI concepts for senior iOS interviews.

---

## Table of Contents

1. [View Lifecycle & Identity](#view-lifecycle--identity)
2. [State Management](#state-management)
3. [Custom Layout System](#custom-layout-system)
4. [Performance Optimization](#performance-optimization)
5. [Advanced Modifiers](#advanced-modifiers)
6. [Navigation & Routing](#navigation--routing)
7. [Animations & Transitions](#animations--transitions)
8. [Interoperability](#interoperability)
9. [Testing SwiftUI](#testing-swiftui)
10. [Architecture Patterns](#architecture-patterns)

---

## View Lifecycle & Identity

### Q1: How does SwiftUI determine view identity?

**Answer:**

SwiftUI uses two types of identity:

**1. Structural Identity** (default)
- Based on position in view hierarchy
- Changes when conditional logic changes structure

```swift
struct ContentView: View {
    @State private var showHeader: Bool = true
    
    var body: some View {
        VStack {
            if showHeader {
                HeaderView()  // Position 0 when visible
            }
            ContentSection()  // Position 0 or 1 depending on showHeader
        }
    }
}
// Problem: ContentSection's identity changes when showHeader toggles
```

**2. Explicit Identity** (using id modifier or ForEach)
```swift
struct BetterContentView: View {
    @State private var showHeader: Bool = true
    
    var body: some View {
        VStack {
            if showHeader {
                HeaderView()
                    .id("header")
            }
            ContentSection()
                .id("content")  // Identity preserved
        }
    }
}

// ForEach provides identity via Identifiable
struct ItemList: View {
    let items: [Item]
    
    var body: some View {
        ForEach(items) { item in  // Uses item.id for identity
            ItemRow(item: item)
        }
    }
}
```

**Identity affects:**
- State preservation
- Animation behavior
- View recycling

---

### Q2: Explain the SwiftUI view lifecycle

**Answer:**

```swift
struct LifecycleView: View {
    @State private var counter = 0
    
    init() {
        // Called when view struct is created
        // May be called multiple times!
        print("1. init() - View struct created")
    }
    
    var body: some View {
        VStack {
            Text("Count: \(counter)")
                .onAppear {
                    // View appeared on screen
                    print("3. onAppear - View visible")
                }
                .onDisappear {
                    // View removed from screen
                    print("4. onDisappear - View hidden")
                }
                .task {
                    // Async work tied to view lifetime
                    print("5. task - Async started")
                    // Automatically cancelled on disappear
                }
                .onChange(of: counter) { oldValue, newValue in
                    // State changed
                    print("6. onChange - \(oldValue) -> \(newValue)")
                }
        }
        // body is called for every render
        // print("2. body computed") // Don't do this in production!
    }
}
```

**Lifecycle events order:**
```
1. init() - View struct instantiated
2. body computed - Generate render tree
3. onAppear - View added to hierarchy
4. task - Async work starts
5. onChange - When observed values change
6. onDisappear - View removed
```

**Important distinctions:**
```swift
// onAppear vs task
.onAppear {
    // Runs on main thread
    // Called each time view appears
}
.task {
    // Supports async/await
    // Automatically cancelled on disappear
    // Restarted if id changes
}

// task with id
.task(id: userId) {
    // Cancelled and restarted when userId changes
    await loadUser(userId)
}
```

---

### Q3: What is @ViewBuilder and how does it work?

**Answer:**

`@ViewBuilder` is a result builder that constructs views from closures.

```swift
// Basic usage
@ViewBuilder
func makeContent(showExtra: Bool) -> some View {
    Text("Always visible")
    
    if showExtra {
        Text("Sometimes visible")
    }
}

// How it transforms code
// Input:
VStack {
    Text("A")
    Text("B")
}

// Becomes:
VStack {
    ViewBuilder.buildBlock(Text("A"), Text("B"))
}
// Returns: TupleView<(Text, Text)>

// Conditional handling
@ViewBuilder
func conditionalContent(condition: Bool) -> some View {
    if condition {
        Text("True")
    } else {
        Image(systemName: "xmark")
    }
}
// Returns: _ConditionalContent<Text, Image>
```

**Custom containers with @ViewBuilder:**
```swift
struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Usage
Card(title: "Profile") {
    Text("Name: John")
    Text("Email: john@example.com")
    Button("Edit") { }
}
```

---

## State Management

### Q4: Compare @State, @Binding, @StateObject, @ObservedObject, @EnvironmentObject

**Answer:**

| Property Wrapper | Ownership | Source | Use Case |
|-----------------|-----------|--------|----------|
| `@State` | Owns | Local | Simple view-local state |
| `@Binding` | References | Parent | Two-way connection to parent's state |
| `@StateObject` | Owns | Local | Reference type lifecycle management |
| `@ObservedObject` | References | External | Passed-in observable object |
| `@EnvironmentObject` | References | Environment | Dependency injection |

```swift
// @State - View owns the data
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        Button("Count: \(count)") {
            count += 1
        }
    }
}

// @Binding - Two-way reference to parent's state
struct ChildView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("Setting", isOn: $isOn)
    }
}

struct ParentView: View {
    @State private var isEnabled = false
    
    var body: some View {
        ChildView(isOn: $isEnabled)  // Pass binding
    }
}

// @StateObject - Own an ObservableObject
class UserViewModel: ObservableObject {
    @Published var name = ""
}

struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        TextField("Name", text: $viewModel.name)
    }
}

// @ObservedObject - Reference external ObservableObject
struct ProfileView: View {
    @ObservedObject var viewModel: UserViewModel  // Created elsewhere
    
    var body: some View {
        Text(viewModel.name)
    }
}

// @EnvironmentObject - Dependency injection
struct DeepChildView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        Text(settings.theme)
    }
}

// Provide in ancestor
ContentView()
    .environmentObject(AppSettings())
```

---

### Q5: How does @Observable (iOS 17+) change state management?

**Answer:**

`@Observable` macro simplifies observable objects:

```swift
// Old way (pre-iOS 17)
class OldUserModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var age = 0
    
    // Must mark every property
}

// New way (iOS 17+)
@Observable
class UserModel {
    var name = ""
    var email = ""
    var age = 0
    
    // All stored properties automatically observed
}
```

**Key differences:**

```swift
// Old: Need @ObservedObject or @StateObject
struct OldView: View {
    @ObservedObject var user: OldUserModel
    
    var body: some View {
        Text(user.name)  // Entire view updates when ANY property changes
    }
}

// New: Just use in body
struct NewView: View {
    var user: UserModel  // No wrapper needed for observation
    
    var body: some View {
        Text(user.name)  // Only updates when 'name' changes!
    }
}

// Ownership with @State
struct OwningView: View {
    @State private var user = UserModel()
    
    var body: some View {
        TextField("Name", text: $user.name)
    }
}
```

**Granular observation:**
```swift
@Observable
class DetailedModel {
    var frequentlyChanging = 0
    var rarelyChanging = ""
}

struct OptimizedView: View {
    var model: DetailedModel
    
    var body: some View {
        VStack {
            // Only this Text re-renders when rarelyChanging updates
            Text(model.rarelyChanging)
            
            // Only this updates when frequentlyChanging changes
            FrequentUpdateView(value: model.frequentlyChanging)
        }
    }
}
```

---

### Q6: Explain @Environment and custom environment values

**Answer:**

```swift
// Built-in environment values
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var textSize
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Theme: \(colorScheme == .dark ? "Dark" : "Light")")
            Button("Close") { dismiss() }
        }
    }
}

// Custom environment values
struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .standard
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Usage
struct ThemedView: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        Text("Hello")
            .foregroundColor(theme.primaryColor)
    }
}

// Set in hierarchy
ContentView()
    .environment(\.theme, .custom)
```

**iOS 17+ Observable in Environment:**
```swift
@Observable
class AppState {
    var isLoggedIn = false
    var user: User?
}

struct AppView: View {
    @State private var appState = AppState()
    
    var body: some View {
        ContentView()
            .environment(appState)  // Inject observable
    }
}

struct ContentView: View {
    @Environment(AppState.self) var appState
    
    var body: some View {
        if appState.isLoggedIn {
            HomeView()
        } else {
            LoginView()
        }
    }
}
```

---

## Custom Layout System

### Q7: How does the SwiftUI layout system work?

**Answer:**

SwiftUI uses a three-phase layout:

**1. Parent proposes size to child**
**2. Child determines its own size**
**3. Parent positions child**

```swift
struct LayoutDemoView: View {
    var body: some View {
        HStack {
            // 1. HStack proposes available width to each child
            Text("Hello")  // 2. Text sizes to fit content
            Spacer()       // 2. Spacer takes remaining space
            Text("World")  // 2. Text sizes to fit content
        }
        // 3. HStack positions children left-to-right
        .frame(width: 300, height: 50)
    }
}
```

**Layout priority:**
```swift
HStack {
    Text("Short")
    Text("This is a much longer piece of text")
        .layoutPriority(1)  // Gets space first
    Text("Medium text")
}
```

**Frame behavior:**
```swift
Text("Hello")
    .frame(width: 100)           // Exactly 100pt
    .frame(minWidth: 50)         // At least 50pt
    .frame(maxWidth: .infinity)  // Expand to fill
    .frame(idealWidth: 200)      // Preferred size

// Alignment in frame
Text("Hello")
    .frame(width: 200, height: 100, alignment: .topLeading)
```

---

### Q8: How do you create a custom Layout?

**Answer:**

```swift
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let result = arrange(
            proposal: proposal,
            subviews: subviews
        )
        return result.size
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let arrangement = arrange(
            proposal: proposal,
            subviews: subviews
        )
        
        for (index, position) in arrangement.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                proposal: .unspecified
            )
        }
    }
    
    private func arrange(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (
            size: CGSize(width: maxX, height: currentY + lineHeight),
            positions: positions
        )
    }
}

// Usage
struct TagCloud: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(16)
            }
        }
    }
}
```

---

### Q9: Explain GeometryReader and its proper usage

**Answer:**

```swift
// GeometryReader provides size and position information
struct GeometryExample: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Width: \(geometry.size.width)")
                Text("Height: \(geometry.size.height)")
                
                // Safe area insets
                Text("Top inset: \(geometry.safeAreaInsets.top)")
                
                // Frame in different coordinate spaces
                Text("Global Y: \(geometry.frame(in: .global).minY)")
            }
        }
    }
}

// Problem: GeometryReader takes all available space
struct BadUsage: View {
    var body: some View {
        VStack {
            GeometryReader { geo in
                Text("Takes all space!")
            }
            Text("Pushed down")
        }
    }
}

// Solution 1: Background modifier
struct GoodUsage1: View {
    @State private var size: CGSize = .zero
    
    var body: some View {
        Text("Hello")
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        size = geo.size
                    }
                }
            )
    }
}

// Solution 2: Preference key
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct GoodUsage2: View {
    @State private var childSize: CGSize = .zero
    
    var body: some View {
        VStack {
            ChildView()
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: SizePreferenceKey.self,
                            value: geo.size
                        )
                    }
                )
        }
        .onPreferenceChange(SizePreferenceKey.self) { size in
            childSize = size
        }
    }
}
```

---

## Performance Optimization

### Q10: How do you prevent unnecessary view updates?

**Answer:**

```swift
// Problem: Entire list re-renders
struct BadListView: View {
    @State private var items: [Item] = []
    @State private var selectedId: String?
    
    var body: some View {
        List(items) { item in
            // All rows re-render when selectedId changes
            ItemRow(item: item, isSelected: item.id == selectedId)
        }
    }
}

// Solution 1: Equatable conformance
struct ItemRow: View, Equatable {
    let item: Item
    let isSelected: Bool
    
    static func == (lhs: ItemRow, rhs: ItemRow) -> Bool {
        lhs.item.id == rhs.item.id && lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        Text(item.name)
            .background(isSelected ? Color.blue : Color.clear)
    }
}

struct BetterListView: View {
    @State private var items: [Item] = []
    @State private var selectedId: String?
    
    var body: some View {
        List(items) { item in
            EquatableView(content: ItemRow(
                item: item,
                isSelected: item.id == selectedId
            ))
        }
    }
}

// Solution 2: Extract to separate view
struct SelectionIndicator: View {
    let itemId: String
    @Binding var selectedId: String?
    
    var body: some View {
        // Only this view updates
        Circle()
            .fill(itemId == selectedId ? Color.blue : Color.gray)
    }
}

// Solution 3: Use id wisely
struct OptimizedList: View {
    @State private var items: [Item] = []
    
    var body: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)
            }
            .id(items.map(\.id))  // Only refresh when items change
        }
    }
}
```

**Debugging view updates:**
```swift
extension View {
    func debugPrint(_ values: Any...) -> some View {
        #if DEBUG
        print(values)
        #endif
        return self
    }
}

struct DebuggableView: View {
    let value: Int
    
    var body: some View {
        let _ = Self._printChanges()  // Built-in debugging
        Text("\(value)")
    }
}
```

---

### Q11: How do you handle large lists efficiently?

**Answer:**

```swift
// LazyVStack vs VStack
struct LazyListExample: View {
    let items: [Item]  // 10,000 items
    
    var body: some View {
        ScrollView {
            // Bad: Creates all views immediately
            // VStack {
            //     ForEach(items) { item in
            //         ItemRow(item: item)
            //     }
            // }
            
            // Good: Creates views on-demand
            LazyVStack {
                ForEach(items) { item in
                    ItemRow(item: item)
                }
            }
        }
    }
}

// Efficient data loading
struct PaginatedList: View {
    @State private var items: [Item] = []
    @State private var isLoading = false
    @State private var page = 0
    
    var body: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)
                    .onAppear {
                        loadMoreIfNeeded(item: item)
                    }
            }
            
            if isLoading {
                ProgressView()
            }
        }
    }
    
    private func loadMoreIfNeeded(item: Item) {
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMore()
        }
    }
    
    private func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        page += 1
        
        Task {
            let newItems = await fetchItems(page: page)
            items.append(contentsOf: newItems)
            isLoading = false
        }
    }
}

// Pre-rendering with drawingGroup
struct ComplexGraphView: View {
    var body: some View {
        Canvas { context, size in
            // Complex drawing
        }
        .drawingGroup()  // Rasterize to Metal texture
    }
}
```

---

### Q12: Explain task modifiers and async data loading

**Answer:**

```swift
struct AsyncDataView: View {
    let itemId: String
    @State private var item: Item?
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let item {
                ItemDetailView(item: item)
            } else if let error {
                ErrorView(error: error)
            } else {
                ProgressView()
            }
        }
        .task {
            await loadItem()
        }
        .task(id: itemId) {
            // Restarts when itemId changes
            await loadItem()
        }
        .refreshable {
            await loadItem()
        }
    }
    
    private func loadItem() async {
        do {
            item = try await api.fetchItem(id: itemId)
        } catch {
            self.error = error
        }
    }
}

// Cancellation handling
struct CancellableView: View {
    @State private var results: [SearchResult] = []
    @State private var searchText = ""
    
    var body: some View {
        List(results) { result in
            ResultRow(result: result)
        }
        .searchable(text: $searchText)
        .task(id: searchText) {
            // Previous task automatically cancelled
            guard !searchText.isEmpty else {
                results = []
                return
            }
            
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))
            
            // Check if still valid
            guard !Task.isCancelled else { return }
            
            results = await search(query: searchText)
        }
    }
}

// Multiple concurrent tasks
struct DashboardView: View {
    @State private var user: User?
    @State private var posts: [Post] = []
    @State private var notifications: [Notification] = []
    
    var body: some View {
        DashboardContent(user: user, posts: posts, notifications: notifications)
            .task {
                async let userData = fetchUser()
                async let postsData = fetchPosts()
                async let notificationsData = fetchNotifications()
                
                // All fetch concurrently
                user = try? await userData
                posts = (try? await postsData) ?? []
                notifications = (try? await notificationsData) ?? []
            }
    }
}
```

---

## Advanced Modifiers

### Q13: How do you create custom view modifiers?

**Answer:**

```swift
// Basic view modifier
struct CardModifier: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: 4)
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius
        ))
    }
}

// Usage
Text("Hello")
    .cardStyle()

// Modifier with state
struct ShakeModifier: ViewModifier {
    @State private var shake = false
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -10 : 0)
            .animation(
                .default.repeatCount(3, autoreverses: true),
                value: shake
            )
            .onChange(of: trigger) {
                shake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shake = false
                }
            }
    }
}

// Modifier reading environment
struct ThemedTextModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let style: TextStyle
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(colorScheme == .dark ? style.darkColor : style.lightColor)
    }
}

// Conditional modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Usage
Text("Hello")
    .if(isHighlighted) { view in
        view.foregroundColor(.yellow)
    }
```

---

### Q14: Explain preference keys and their uses

**Answer:**

```swift
// Preference: Child-to-parent communication
struct AnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { $1 }
    }
}

// Usage: Highlight selected item with overlay
struct SelectableList: View {
    let items: [String]
    @State private var selected: String?
    
    var body: some View {
        ZStack {
            VStack {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .padding()
                        .anchorPreference(
                            key: AnchorPreferenceKey.self,
                            value: .bounds
                        ) { anchor in
                            [item: anchor]
                        }
                        .onTapGesture {
                            withAnimation {
                                selected = item
                            }
                        }
                }
            }
            .overlayPreferenceValue(AnchorPreferenceKey.self) { anchors in
                GeometryReader { geo in
                    if let selected, let anchor = anchors[selected] {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(
                                width: geo[anchor].width,
                                height: geo[anchor].height
                            )
                            .offset(
                                x: geo[anchor].minX,
                                y: geo[anchor].minY
                            )
                    }
                }
            }
        }
    }
}

// Navigation title preference (simplified)
struct NavigationTitleKey: PreferenceKey {
    static var defaultValue: String = ""
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

extension View {
    func customNavigationTitle(_ title: String) -> some View {
        preference(key: NavigationTitleKey.self, value: title)
    }
}
```

---

## Navigation & Routing

### Q15: Compare NavigationStack vs NavigationSplitView

**Answer:**

```swift
// NavigationStack - Single column navigation
struct StackNavigation: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetail(item: item)
            }
            .navigationDestination(for: Category.self) { category in
                CategoryDetail(category: category)
            }
        }
    }
    
    // Programmatic navigation
    func navigateTo(_ item: Item) {
        path.append(item)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

// NavigationSplitView - Multi-column (iPad/Mac)
struct SplitNavigation: View {
    @State private var selectedCategory: Category?
    @State private var selectedItem: Item?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(categories, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.name, systemImage: category.icon)
                }
            }
            .navigationTitle("Categories")
        } content: {
            // Content column
            if let category = selectedCategory {
                List(category.items, selection: $selectedItem) { item in
                    NavigationLink(value: item) {
                        ItemRow(item: item)
                    }
                }
                .navigationTitle(category.name)
            } else {
                ContentUnavailableView(
                    "Select a Category",
                    systemImage: "folder"
                )
            }
        } detail: {
            // Detail column
            if let item = selectedItem {
                ItemDetail(item: item)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "doc"
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

---

### Q16: How do you implement deep linking with NavigationStack?

**Answer:**

```swift
// Route enum for type-safe navigation
enum Route: Hashable, Codable {
    case home
    case category(id: String)
    case item(id: String)
    case profile(userId: String)
    case settings
}

// Router with URL handling
@Observable
class Router {
    var path = NavigationPath()
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func handleURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "myapp" else {
            return false
        }
        
        let pathComponents = components.path.split(separator: "/")
        
        switch pathComponents.first {
        case "item":
            if let id = pathComponents.dropFirst().first {
                path.append(Route.item(id: String(id)))
                return true
            }
        case "profile":
            if let userId = pathComponents.dropFirst().first {
                path.append(Route.profile(userId: String(userId)))
                return true
            }
        case "settings":
            path.append(Route.settings)
            return true
        default:
            break
        }
        
        return false
    }
}

// Main app with deep linking
struct ContentView: View {
    @State private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .category(let id):
                        CategoryView(categoryId: id)
                    case .item(let id):
                        ItemDetailView(itemId: id)
                    case .profile(let userId):
                        ProfileView(userId: userId)
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environment(router)
        .onOpenURL { url in
            _ = router.handleURL(url)
        }
    }
}

// Save/restore navigation state
extension Router {
    func saveState() -> Data? {
        try? JSONEncoder().encode(path.codable)
    }
    
    func restoreState(_ data: Data) {
        if let decoded = try? JSONDecoder().decode(
            NavigationPath.CodableRepresentation.self,
            from: data
        ) {
            path = NavigationPath(decoded)
        }
    }
}
```

---

## Animations & Transitions

### Q17: Explain SwiftUI's animation system

**Answer:**

```swift
// Implicit animations
struct ImplicitAnimation: View {
    @State private var scale = 1.0
    
    var body: some View {
        Circle()
            .scaleEffect(scale)
            .animation(.spring(duration: 0.5), value: scale)  // Animates scale changes
            .onTapGesture {
                scale = scale == 1.0 ? 1.5 : 1.0
            }
    }
}

// Explicit animations
struct ExplicitAnimation: View {
    @State private var rotation = 0.0
    
    var body: some View {
        Rectangle()
            .rotationEffect(.degrees(rotation))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 1.0)) {
                    rotation += 360
                }
            }
    }
}

// Animation phases (iOS 17+)
struct PhaseAnimator: View {
    @State private var trigger = false
    
    var body: some View {
        Text("Hello")
            .phaseAnimator([false, true], trigger: trigger) { content, phase in
                content
                    .scaleEffect(phase ? 1.5 : 1.0)
                    .opacity(phase ? 1.0 : 0.5)
            } animation: { phase in
                phase ? .bouncy : .easeOut(duration: 0.3)
            }
            .onTapGesture { trigger.toggle() }
    }
}

// Keyframe animations (iOS 17+)
struct KeyframeExample: View {
    @State private var trigger = false
    
    var body: some View {
        Text("Bounce")
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: trigger
            ) { content, value in
                content
                    .scaleEffect(value.scale)
                    .offset(y: value.verticalOffset)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.0, duration: 0.1)
                    SpringKeyframe(1.5, duration: 0.2)
                    SpringKeyframe(1.0, duration: 0.3)
                }
                KeyframeTrack(\.verticalOffset) {
                    LinearKeyframe(0, duration: 0.1)
                    SpringKeyframe(-50, duration: 0.2)
                    SpringKeyframe(0, duration: 0.3)
                }
            }
    }
}

struct AnimationValues {
    var scale = 1.0
    var verticalOffset = 0.0
}
```

---

### Q18: How do you create custom transitions?

**Answer:**

```swift
// Basic transition
struct TransitionDemo: View {
    @State private var showDetail = false
    
    var body: some View {
        VStack {
            if showDetail {
                DetailView()
                    .transition(.slide)
                    // .transition(.opacity)
                    // .transition(.scale)
                    // .transition(.move(edge: .bottom))
            }
            
            Button("Toggle") {
                withAnimation {
                    showDetail.toggle()
                }
            }
        }
    }
}

// Asymmetric transition
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .slide
))

// Custom transition
struct RotateTransition: Transition {
    let angle: Angle
    
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotationEffect(phase.isIdentity ? .zero : angle)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension AnyTransition {
    static var rotate: AnyTransition {
        .modifier(
            active: RotateModifier(angle: .degrees(90), opacity: 0),
            identity: RotateModifier(angle: .zero, opacity: 1)
        )
    }
}

struct RotateModifier: ViewModifier {
    let angle: Angle
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(angle)
            .opacity(opacity)
    }
}

// Matched geometry effect
struct MatchedGeometryExample: View {
    @Namespace private var animation
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if isExpanded {
                ExpandedCard()
                    .matchedGeometryEffect(id: "card", in: animation)
            } else {
                CompactCard()
                    .matchedGeometryEffect(id: "card", in: animation)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}
```

---

## Interoperability

### Q19: How do you wrap UIKit views in SwiftUI?

**Answer:**

```swift
// Basic UIViewRepresentable
struct ActivityIndicator: UIViewRepresentable {
    let isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

// With coordinator for delegates
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Sizing UIKit views
struct SizedTextField: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextField,
        context: Context
    ) -> CGSize? {
        // Custom sizing logic
        return uiView.intrinsicContentSize
    }
}
```

---

### Q20: How do you use SwiftUI views in UIKit?

**Answer:**

```swift
// Using UIHostingController
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swiftUIView = ContentView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}

// UIHostingConfiguration for cells (iOS 16+)
class ModernTableViewController: UITableViewController {
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "Cell",
            for: indexPath
        )
        
        cell.contentConfiguration = UIHostingConfiguration {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("SwiftUI in UIKit cell!")
            }
        }
        
        return cell
    }
}

// Passing data between UIKit and SwiftUI
class DataManager: ObservableObject {
    @Published var items: [String] = []
}

class HybridViewController: UIViewController {
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swiftUIView = ItemListView()
            .environmentObject(dataManager)
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        // ... add to hierarchy
        
        // UIKit can update the data
        dataManager.items.append("New Item")
    }
}
```

---

## Testing SwiftUI

### Q21: How do you test SwiftUI views?

**Answer:**

```swift
// Unit testing view models
@Observable
class CounterViewModel {
    var count = 0
    
    func increment() {
        count += 1
    }
    
    func decrement() {
        count = max(0, count - 1)
    }
}

class CounterViewModelTests: XCTestCase {
    func testIncrement() {
        let vm = CounterViewModel()
        vm.increment()
        XCTAssertEqual(vm.count, 1)
    }
    
    func testDecrementNotBelowZero() {
        let vm = CounterViewModel()
        vm.decrement()
        XCTAssertEqual(vm.count, 0)
    }
}

// Snapshot testing
import SnapshotTesting

class ViewSnapshotTests: XCTestCase {
    func testProfileView() {
        let view = ProfileView(
            user: User.mock
        )
        
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13))
        )
    }
    
    func testDarkMode() {
        let view = ProfileView(user: User.mock)
            .preferredColorScheme(.dark)
        
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13))
        )
    }
}

// UI Testing
class SwiftUIUITests: XCTestCase {
    func testCounterIncrement() {
        let app = XCUIApplication()
        app.launch()
        
        let countText = app.staticTexts["CountLabel"]
        XCTAssertEqual(countText.label, "0")
        
        app.buttons["IncrementButton"].tap()
        XCTAssertEqual(countText.label, "1")
    }
}

// Preview testing
#Preview {
    CounterView()
}

#Preview("Dark Mode") {
    CounterView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    CounterView()
        .dynamicTypeSize(.xxxLarge)
}
```

---

## Architecture Patterns

### Q22: What architecture patterns work best with SwiftUI?

**Answer:**

**1. MVVM (Most common)**
```swift
// Model
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
}

// ViewModel
@Observable
class UserViewModel {
    var user: User?
    var isLoading = false
    var error: Error?
    
    private let repository: UserRepository
    
    init(repository: UserRepository = .shared) {
        self.repository = repository
    }
    
    func loadUser(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            user = try await repository.fetchUser(id: id)
        } catch {
            self.error = error
        }
    }
}

// View
struct UserProfileView: View {
    @State private var viewModel = UserViewModel()
    let userId: String
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                UserContent(user: user)
            } else if viewModel.error != nil {
                ErrorView()
            }
        }
        .task {
            await viewModel.loadUser(id: userId)
        }
    }
}
```

**2. Redux-like (TCA pattern)**
```swift
// State
struct AppState: Equatable {
    var counter = 0
    var todos: [Todo] = []
}

// Actions
enum AppAction {
    case increment
    case decrement
    case addTodo(String)
    case removeTodo(IndexSet)
}

// Reducer
func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .increment:
        state.counter += 1
    case .decrement:
        state.counter -= 1
    case .addTodo(let title):
        state.todos.append(Todo(title: title))
    case .removeTodo(let indexSet):
        state.todos.remove(atOffsets: indexSet)
    }
}

// Store
@Observable
class Store {
    private(set) var state: AppState
    
    init(initialState: AppState = AppState()) {
        self.state = initialState
    }
    
    func send(_ action: AppAction) {
        appReducer(state: &state, action: action)
    }
}

// View
struct CounterView: View {
    @Environment(Store.self) var store
    
    var body: some View {
        VStack {
            Text("\(store.state.counter)")
            HStack {
                Button("-") { store.send(.decrement) }
                Button("+") { store.send(.increment) }
            }
        }
    }
}
```

**3. Clean Architecture**
```swift
// Domain Layer
protocol UserRepository {
    func fetchUser(id: String) async throws -> User
}

// Use Case
struct FetchUserUseCase {
    let repository: UserRepository
    
    func execute(id: String) async throws -> User {
        try await repository.fetchUser(id: id)
    }
}

// Data Layer
class UserRepositoryImpl: UserRepository {
    private let api: APIClient
    private let cache: UserCache
    
    func fetchUser(id: String) async throws -> User {
        if let cached = cache.get(id) {
            return cached
        }
        let user = try await api.fetchUser(id: id)
        cache.set(user)
        return user
    }
}

// Presentation Layer
@Observable
class UserPresenter {
    var user: User?
    
    private let fetchUserUseCase: FetchUserUseCase
    
    init(fetchUserUseCase: FetchUserUseCase) {
        self.fetchUserUseCase = fetchUserUseCase
    }
    
    func loadUser(id: String) async {
        user = try? await fetchUserUseCase.execute(id: id)
    }
}
```

---

### Q23: How do you handle dependency injection in SwiftUI?

**Answer:**

```swift
// Environment-based DI
protocol APIClientProtocol {
    func fetch<T: Decodable>(from url: URL) async throws -> T
}

struct APIClientKey: EnvironmentKey {
    static let defaultValue: APIClientProtocol = APIClient()
}

extension EnvironmentValues {
    var apiClient: APIClientProtocol {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

// Usage
struct DataView: View {
    @Environment(\.apiClient) var api
    
    var body: some View {
        // Use api
    }
}

// For testing
struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        DataView()
            .environment(\.apiClient, MockAPIClient())
    }
}

// Container-based DI
@Observable
class DependencyContainer {
    let apiClient: APIClientProtocol
    let userRepository: UserRepository
    let analyticsService: AnalyticsService
    
    init(
        apiClient: APIClientProtocol = APIClient(),
        userRepository: UserRepository? = nil,
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.apiClient = apiClient
        self.userRepository = userRepository ?? UserRepositoryImpl(api: apiClient)
        self.analyticsService = analyticsService
    }
    
    static let live = DependencyContainer()
    static let preview = DependencyContainer(
        apiClient: MockAPIClient(),
        analyticsService: MockAnalyticsService()
    )
}

// App entry
@main
struct MyApp: App {
    let container = DependencyContainer.live
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
        }
    }
}
```

---

## Summary

| Topic | Key Points |
|-------|------------|
| Identity | Structural vs explicit, affects state & animation |
| State | @State, @Binding, @Observable, @Environment |
| Layout | Propose-size model, GeometryReader, custom Layout |
| Performance | Equatable views, lazy loading, debugging |
| Navigation | NavigationStack, deep linking, state restoration |
| Animation | Implicit/explicit, transitions, keyframes |
| Interop | UIViewRepresentable, UIHostingController |
| Testing | ViewModel tests, snapshots, UI tests |
| Architecture | MVVM, TCA, Clean Architecture |

---

*Last updated: 2024*
