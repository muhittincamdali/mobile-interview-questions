# SwiftUI Deep Dive Interview Questions

Comprehensive SwiftUI interview preparation covering architecture, state management, performance, and advanced techniques.

---

## Table of Contents

1. [SwiftUI Fundamentals](#swiftui-fundamentals)
2. [State Management](#state-management)
3. [View Lifecycle & Identity](#view-lifecycle--identity)
4. [Layout System](#layout-system)
5. [Navigation](#navigation)
6. [Animations & Transitions](#animations--transitions)
7. [Performance Optimization](#performance-optimization)
8. [Custom Views & Modifiers](#custom-views--modifiers)
9. [Data Flow Patterns](#data-flow-patterns)
10. [Testing SwiftUI](#testing-swiftui)

---

## SwiftUI Fundamentals

### Q1: How does SwiftUI's declarative syntax differ from UIKit's imperative approach?

**Answer:**

```swift
// UIKit - Imperative (HOW to do it)
class ImperativeViewController: UIViewController {
    let label = UILabel()
    let button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = "Count: 0"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        button.setTitle("Increment", for: .normal)
        button.addTarget(self, action: #selector(increment), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    var count = 0
    
    @objc func increment() {
        count += 1
        label.text = "Count: \(count)"  // Manual UI update
    }
}

// SwiftUI - Declarative (WHAT you want)
struct DeclarativeView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1  // UI updates automatically
            }
        }
    }
}
```

**Key differences:**
- SwiftUI: Describe desired state, framework handles updates
- UIKit: Manually manage view hierarchy and updates
- SwiftUI views are value types (structs), UIKit views are reference types (classes)
- SwiftUI uses diffing algorithm to minimize UI updates

---

### Q2: Explain the View protocol and body property

**Answer:**

```swift
// View protocol definition
public protocol View {
    associatedtype Body: View
    
    @ViewBuilder var body: Self.Body { get }
}

// The body is computed every time state changes
struct ContentView: View {
    @State private var showDetail = false
    
    // body is a computed property, not stored
    var body: some View {
        VStack {
            Button("Toggle") {
                showDetail.toggle()
            }
            
            if showDetail {
                DetailView()
            }
        }
    }
}

// Opaque return type (some View)
// - Hides concrete type from caller
// - Compiler knows exact type
// - Enables performance optimizations

// View composition
struct ComposedView: View {
    var body: some View {
        VStack {
            HeaderView()
            ContentSection()
            FooterView()
        }
    }
}

// Never type for leaf views
extension Text: View {
    // Body is Never - it's a primitive view
    typealias Body = Never
}
```

---

### Q3: What is @ViewBuilder and how does it work?

**Answer:**

```swift
// @ViewBuilder is a result builder for composing views
@resultBuilder
struct ViewBuilder {
    // Build multiple views into TupleView
    static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)>
        where C0: View, C1: View
    
    // Support for conditionals
    static func buildIf<Content>(_ content: Content?) -> Content?
        where Content: View
    
    // Support for if-else
    static func buildEither<TrueContent, FalseContent>(
        first: TrueContent
    ) -> _ConditionalContent<TrueContent, FalseContent>
}

// Custom view with @ViewBuilder parameter
struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// Usage
Card {
    Text("Title")
    Text("Subtitle")
    if showImage {
        Image(systemName: "star")
    }
}

// Custom container with multiple slots
struct TwoColumnLayout<Left: View, Right: View>: View {
    let left: Left
    let right: Right
    
    init(
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.left = left()
        self.right = right()
    }
    
    var body: some View {
        HStack {
            left
            Spacer()
            right
        }
    }
}
```

---

## State Management

### Q4: Explain the differences between @State, @Binding, @StateObject, @ObservedObject, and @EnvironmentObject

**Answer:**

```swift
// @State - Local value type state, owned by the view
struct CounterView: View {
    @State private var count = 0  // Source of truth
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
            
            // Pass binding to child
            ChildView(count: $count)
        }
    }
}

// @Binding - Two-way connection to state owned elsewhere
struct ChildView: View {
    @Binding var count: Int  // Reference to parent's state
    
    var body: some View {
        Button("Reset") { count = 0 }  // Modifies parent's state
    }
}

// @StateObject - Reference type state, owned by the view (created once)
class UserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
}

struct ProfileView: View {
    @StateObject private var viewModel = UserViewModel()  // Created once
    
    var body: some View {
        VStack {
            TextField("Name", text: $viewModel.name)
            ChildProfile(viewModel: viewModel)
        }
    }
}

// @ObservedObject - Reference type state, NOT owned (passed in)
struct ChildProfile: View {
    @ObservedObject var viewModel: UserViewModel  // Passed from parent
    
    var body: some View {
        TextField("Email", text: $viewModel.email)
    }
}

// @EnvironmentObject - Shared state from ancestor
@main
struct MyApp: App {
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)  // Inject into environment
        }
    }
}

struct DeepNestedView: View {
    @EnvironmentObject var settings: AppSettings  // Access from anywhere
    
    var body: some View {
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}
```

---

### Q5: When should you use @StateObject vs @ObservedObject?

**Answer:**

```swift
// WRONG: Using @ObservedObject for owned state
struct BadExample: View {
    // This creates a new instance every time parent redraws!
    @ObservedObject var viewModel = MyViewModel()  // BUG!
    
    var body: some View {
        Text(viewModel.data)
    }
}

// CORRECT: Use @StateObject for owned state
struct GoodExample: View {
    @StateObject private var viewModel = MyViewModel()  // Created once
    
    var body: some View {
        Text(viewModel.data)
    }
}

// CORRECT: Use @ObservedObject when passed from parent
struct ParentView: View {
    @StateObject private var viewModel = MyViewModel()  // Owner
    
    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel  // Not owner, just observing
    
    var body: some View {
        Text(viewModel.data)
    }
}

// Rule of thumb:
// - @StateObject: You CREATE and OWN the object
// - @ObservedObject: Someone PASSES you the object

// Lifecycle demonstration
class LifecycleViewModel: ObservableObject {
    init() { print("ViewModel created") }
    deinit { print("ViewModel destroyed") }
}

struct ParentWithToggle: View {
    @State private var showChild = true
    
    var body: some View {
        VStack {
            Toggle("Show", isOn: $showChild)
            if showChild {
                // With @StateObject: Created once
                // With @ObservedObject: Created every toggle
                StateObjectChild()
            }
        }
    }
}

struct StateObjectChild: View {
    @StateObject private var vm = LifecycleViewModel()
    var body: some View { Text("Child") }
}
```

---

### Q6: Explain @Published and how ObservableObject works

**Answer:**

```swift
// ObservableObject with @Published
class ShoppingCart: ObservableObject {
    // @Published auto-generates publisher
    @Published var items: [Item] = []
    @Published var discount: Double = 0
    
    // Computed property (no @Published needed)
    var total: Double {
        items.reduce(0) { $0 + $1.price } * (1 - discount)
    }
    
    // Manual publishing for custom logic
    var couponCode: String = "" {
        willSet {
            objectWillChange.send()  // Manual notification
        }
        didSet {
            applyDiscount(for: couponCode)
        }
    }
    
    func addItem(_ item: Item) {
        items.append(item)  // @Published auto-notifies
    }
}

// Under the hood, @Published creates:
class ManualPublished: ObservableObject {
    private var _value: Int = 0
    
    var value: Int {
        get { _value }
        set {
            objectWillChange.send()  // Notify before change
            _value = newValue
        }
    }
}

// Combining multiple ObservableObjects
class AppState: ObservableObject {
    @Published var user: User?
    @Published var cart: ShoppingCart
    @Published var settings: Settings
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        cart = ShoppingCart()
        settings = Settings()
        
        // Forward child changes to parent
        cart.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
}
```

---

### Q7: What is @Environment and how do you create custom environment values?

**Answer:**

```swift
// Built-in environment values
struct EnvironmentDemo: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack {
            Text(colorScheme == .dark ? "Dark" : "Light")
            
            Button("Dismiss") { dismiss() }
            
            Button("Open URL") {
                openURL(URL(string: "https://apple.com")!)
            }
        }
    }
}

// Custom environment value
struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Convenience modifier
extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
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

ContentView()
    .theme(.dark)

// Environment vs EnvironmentObject
// Environment: Simple values, built-in support
// EnvironmentObject: Complex objects, observable
```

---

### Q8: How does @AppStorage and @SceneStorage work?

**Answer:**

```swift
// @AppStorage - UserDefaults wrapper
struct SettingsView: View {
    @AppStorage("username") var username = "Guest"
    @AppStorage("notifications_enabled") var notificationsEnabled = true
    @AppStorage("selected_theme") var selectedTheme = Theme.system
    
    var body: some View {
        Form {
            TextField("Username", text: $username)
            Toggle("Notifications", isOn: $notificationsEnabled)
            Picker("Theme", selection: $selectedTheme) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
        }
    }
}

// Custom type with RawRepresentable
enum Theme: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
}

// @SceneStorage - Per-scene state restoration
struct DocumentView: View {
    @SceneStorage("selected_tab") var selectedTab = 0
    @SceneStorage("scroll_position") var scrollPosition: Double = 0
    @SceneStorage("draft_text") var draftText = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EditorTab(text: $draftText)
                .tag(0)
            PreviewTab(text: draftText)
                .tag(1)
        }
    }
}

// Differences:
// @AppStorage: 
// - Persists across app launches
// - Shared across all scenes
// - Uses UserDefaults
//
// @SceneStorage:
// - Per-scene state
// - Restored on scene recreation
// - Lost when scene is destroyed
```

---

## View Lifecycle & Identity

### Q9: Explain view identity and how SwiftUI tracks views

**Answer:**

```swift
// Structural Identity - position in view hierarchy
struct StructuralIdentity: View {
    @State private var showFirst = true
    
    var body: some View {
        if showFirst {
            Text("First")  // Structural identity: if-true branch
        } else {
            Text("Second")  // Different identity: if-false branch
        }
        // State is NOT preserved when switching
    }
}

// Explicit Identity - using .id() modifier
struct ExplicitIdentity: View {
    @State private var items = ["A", "B", "C"]
    
    var body: some View {
        ForEach(items, id: \.self) { item in
            ItemView(item: item)
                .id(item)  // Explicit identity
        }
    }
}

// Stable identity preserves state
struct StableIdentityDemo: View {
    @State private var data = [
        Item(id: "1", name: "First"),
        Item(id: "2", name: "Second")
    ]
    
    var body: some View {
        ForEach(data) { item in  // Uses Item.id for identity
            ItemRow(item: item)  // State preserved when reordering
        }
    }
}

// Identity affects animations
struct AnimationIdentity: View {
    @State private var flag = true
    
    var body: some View {
        VStack {
            // Same identity - animates changes
            Rectangle()
                .fill(flag ? Color.red : Color.blue)
                .frame(width: flag ? 100 : 200)
            
            // Different identity - no animation, view replaced
            if flag {
                Circle().fill(.red)
            } else {
                Circle().fill(.blue)
            }
        }
        .animation(.default, value: flag)
    }
}
```

---

### Q10: What is the difference between onAppear and task modifier?

**Answer:**

```swift
// onAppear - called when view appears
struct OnAppearExample: View {
    @State private var data: [Item] = []
    
    var body: some View {
        List(data) { item in
            Text(item.name)
        }
        .onAppear {
            // Synchronous code or fire-and-forget async
            loadData()
        }
        .onDisappear {
            // Cleanup
        }
    }
    
    func loadData() {
        Task {
            data = try await fetchData()
        }
    }
}

// task modifier - tied to view lifecycle, auto-cancellation
struct TaskExample: View {
    @State private var data: [Item] = []
    
    var body: some View {
        List(data) { item in
            Text(item.name)
        }
        .task {
            // Automatically cancelled when view disappears
            do {
                data = try await fetchData()
            } catch {
                // Handle error (including cancellation)
            }
        }
        .task(id: searchQuery) {
            // Re-runs when id changes
            // Previous task cancelled automatically
            data = try await search(query: searchQuery)
        }
    }
}

// Comparing approaches
struct ComparisonView: View {
    @State private var userId: String
    
    var body: some View {
        VStack {
            // onAppear: Manual lifecycle management
            Text("User")
                .onAppear { loadUser() }
                .onChange(of: userId) { _ in loadUser() }
            
            // task: Automatic lifecycle management
            Text("User")
                .task(id: userId) {
                    await loadUser(id: userId)
                }
        }
    }
}

// task priorities
.task(priority: .background) {
    await heavyWork()
}
```

---

### Q11: How do you handle view updates and prevent unnecessary redraws?

**Answer:**

```swift
// Problem: Unnecessary redraws
struct ParentView: View {
    @State private var count = 0
    @State private var name = "John"
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
            
            // This redraws every time count changes!
            ExpensiveChildView(name: name)
        }
    }
}

// Solution 1: EquatableView
struct ExpensiveChildView: View, Equatable {
    let name: String
    
    var body: some View {
        // Expensive computation
        Text("Hello, \(name)")
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }
}

// Usage with .equatable()
ExpensiveChildView(name: name).equatable()

// Solution 2: Extract into separate views
struct OptimizedParent: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            CounterSection(count: $count)  // Isolated updates
            StaticSection()  // Never redraws
        }
    }
}

// Solution 3: Use @ObservedObject selectively
class ViewModel: ObservableObject {
    @Published var frequentlyChanging = 0
    @Published var rarelyChanging = "Static"
}

struct SelectiveObservation: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            // Only this part needs frequent updates
            FrequentUpdateView(value: viewModel.frequentlyChanging)
            
            // This should not redraw
            RareUpdateView(value: viewModel.rarelyChanging)
        }
    }
}

// Solution 4: Use let for static data
struct OptimizedRow: View {
    let item: Item  // Immutable, no observation overhead
    
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Text(item.price, format: .currency(code: "USD"))
        }
    }
}
```

---

## Layout System

### Q12: Explain SwiftUI's layout algorithm

**Answer:**

```swift
// Three-phase layout:
// 1. Parent proposes size to child
// 2. Child determines its own size
// 3. Parent positions child

// Demonstrating with custom layout
struct CustomLayoutDemo: View {
    var body: some View {
        HStack {  // Proposes divided space to children
            Text("Hello")  // Reports its ideal size
                .background(Color.red)
            
            Text("World")
                .frame(width: 100)  // Fixed size
                .background(Color.blue)
            
            Spacer()  // Flexible, takes remaining space
        }
        .frame(width: 300)  // Container size
    }
}

// Layout priorities
struct LayoutPriority: View {
    var body: some View {
        HStack {
            Text("Low priority, will truncate...")
                .layoutPriority(0)  // Default
            
            Text("High priority")
                .layoutPriority(1)  // Gets space first
        }
        .frame(width: 200)
    }
}

// Fixed vs flexible frames
struct FrameTypes: View {
    var body: some View {
        VStack {
            // Fixed size
            Text("Fixed")
                .frame(width: 100, height: 50)
            
            // Flexible with constraints
            Text("Flexible")
                .frame(minWidth: 50, maxWidth: 200)
            
            // Fill available space
            Text("Fill")
                .frame(maxWidth: .infinity)
            
            // Ideal size
            Text("Ideal")
                .frame(idealWidth: 150)
        }
    }
}

// GeometryReader for reading sizes
struct GeometryDemo: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Width: \(geometry.size.width)")
                Text("Height: \(geometry.size.height)")
                
                Rectangle()
                    .frame(width: geometry.size.width * 0.5)
            }
        }
    }
}
```

---

### Q13: How do you create custom layouts in SwiftUI?

**Answer:**

```swift
// Custom Layout protocol (iOS 16+)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = arrangeSubviews(
            proposal: proposal,
            subviews: subviews
        )
        return result.size
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let arrangement = arrangeSubviews(
            proposal: proposal,
            subviews: subviews
        )
        
        for (index, position) in arrangement.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                proposal: ProposedViewSize(
                    subviews[index].sizeThatFits(.unspecified)
                )
            )
        }
    }
    
    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// Usage
struct TagCloud: View {
    let tags = ["Swift", "SwiftUI", "iOS", "macOS", "Xcode"]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
        }
    }
}
```

---

### Q14: Explain alignment guides and how to use them

**Answer:**

```swift
// Built-in alignments
struct AlignmentDemo: View {
    var body: some View {
        HStack(alignment: .top) {
            Text("Top")
                .font(.largeTitle)
            Text("aligned")
                .font(.caption)
        }
        
        HStack(alignment: .firstTextBaseline) {
            Text("Baseline")
                .font(.largeTitle)
            Text("aligned")
                .font(.caption)
        }
    }
}

// Custom alignment guide
extension VerticalAlignment {
    struct CustomAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    
    static let custom = VerticalAlignment(CustomAlignment.self)
}

struct CustomAlignmentDemo: View {
    var body: some View {
        HStack(alignment: .custom) {
            VStack {
                Text("Header")
                Text("Align Here")
                    .alignmentGuide(.custom) { d in d[.bottom] }
                Text("Footer")
            }
            
            Rectangle()
                .frame(width: 2, height: 100)
                .alignmentGuide(.custom) { d in d[VerticalAlignment.center] }
            
            Text("Matched")
                .alignmentGuide(.custom) { d in d[.top] }
        }
    }
}

// Alignment guide for offset
struct OffsetAlignment: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Leading")
            
            Text("Indented")
                .alignmentGuide(.leading) { d in d[.leading] - 20 }
            
            Text("More Indented")
                .alignmentGuide(.leading) { d in d[.leading] - 40 }
        }
    }
}
```

---

## Navigation

### Q15: Explain the new NavigationStack and NavigationPath

**Answer:**

```swift
// NavigationStack with value-based navigation (iOS 16+)
struct ModernNavigation: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink("Go to User", value: User(id: "1", name: "John"))
                NavigationLink("Go to Settings", value: Route.settings)
            }
            .navigationDestination(for: User.self) { user in
                UserDetailView(user: user)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                case .profile:
                    ProfileView()
                }
            }
        }
    }
}

// Programmatic navigation
struct ProgrammaticNav: View {
    @State private var path: [Route] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Button("Go Deep") {
                    path = [.settings, .profile]  // Push multiple
                }
                
                Button("Pop to Root") {
                    path.removeAll()
                }
            }
            .navigationDestination(for: Route.self) { route in
                RouteView(route: route, path: $path)
            }
        }
    }
}

// NavigationPath for heterogeneous types
struct HeterogeneousNav: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Button("Push User") {
                    path.append(User(id: "1", name: "John"))
                }
                
                Button("Push Number") {
                    path.append(42)
                }
            }
            .navigationDestination(for: User.self) { user in
                Text("User: \(user.name)")
            }
            .navigationDestination(for: Int.self) { number in
                Text("Number: \(number)")
            }
        }
    }
}

// Persisting navigation state
class NavigationStore: ObservableObject {
    @Published var path = NavigationPath()
    
    private let savePath = URL.documentsDirectory.appending(path: "navigation.json")
    
    init() {
        if let data = try? Data(contentsOf: savePath),
           let decoded = try? JSONDecoder().decode(
               NavigationPath.CodableRepresentation.self,
               from: data
           ) {
            path = NavigationPath(decoded)
        }
    }
    
    func save() {
        guard let representation = path.codable else { return }
        let data = try? JSONEncoder().encode(representation)
        try? data?.write(to: savePath)
    }
}
```

---

### Q16: How do you implement deep linking with NavigationStack?

**Answer:**

```swift
// Deep link handling
enum DeepLink: Hashable {
    case user(id: String)
    case product(id: String)
    case settings(section: String?)
}

class DeepLinkHandler: ObservableObject {
    @Published var path = NavigationPath()
    
    func handle(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }
        
        path.removeAll()  // Reset to root
        
        switch host {
        case "user":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                path.append(DeepLink.user(id: id))
            }
            
        case "product":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                path.append(DeepLink.product(id: id))
            }
            
        case "settings":
            let section = components.queryItems?.first(where: { $0.name == "section" })?.value
            path.append(DeepLink.settings(section: section))
            
        default:
            break
        }
    }
}

struct DeepLinkApp: View {
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    
    var body: some View {
        NavigationStack(path: $deepLinkHandler.path) {
            HomeView()
                .navigationDestination(for: DeepLink.self) { link in
                    switch link {
                    case .user(let id):
                        UserView(userId: id)
                    case .product(let id):
                        ProductView(productId: id)
                    case .settings(let section):
                        SettingsView(section: section)
                    }
                }
        }
        .onOpenURL { url in
            deepLinkHandler.handle(url: url)
        }
    }
}
```

---

## Animations & Transitions

### Q17: Explain implicit vs explicit animations

**Answer:**

```swift
// Implicit animation - animation modifier
struct ImplicitAnimation: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
            .animation(.spring(), value: scale)  // Animates when scale changes
            .onTapGesture {
                scale = scale == 1.0 ? 1.5 : 1.0
            }
    }
}

// Explicit animation - withAnimation
struct ExplicitAnimation: View {
    @State private var offset: CGFloat = 0
    @State private var color = Color.red
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .offset(x: offset)
            
            Button("Animate") {
                withAnimation(.easeInOut(duration: 0.5)) {
                    offset = offset == 0 ? 100 : 0
                }
                
                // This won't animate
                color = color == .red ? .blue : .red
            }
            
            Button("Animate Both") {
                withAnimation {
                    offset = offset == 0 ? 100 : 0
                    color = color == .red ? .blue : .red
                }
            }
        }
    }
}

// Animation timing curves
struct AnimationCurves: View {
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            AnimatedRect(animate: animate, animation: .linear)
            AnimatedRect(animate: animate, animation: .easeIn)
            AnimatedRect(animate: animate, animation: .easeOut)
            AnimatedRect(animate: animate, animation: .easeInOut)
            AnimatedRect(animate: animate, animation: .spring())
            AnimatedRect(animate: animate, animation: .interactiveSpring())
        }
        .onTapGesture {
            withAnimation { animate.toggle() }
        }
    }
}

struct AnimatedRect: View {
    let animate: Bool
    let animation: Animation
    
    var body: some View {
        Rectangle()
            .fill(.blue)
            .frame(width: 50, height: 50)
            .offset(x: animate ? 100 : 0)
            .animation(animation, value: animate)
    }
}
```

---

### Q18: How do you create custom transitions?

**Answer:**

```swift
// Built-in transitions
struct TransitionDemo: View {
    @State private var show = false
    
    var body: some View {
        VStack {
            Button("Toggle") { withAnimation { show.toggle() } }
            
            if show {
                // Single transition
                Text("Slide")
                    .transition(.slide)
                
                // Combined transitions
                Text("Scale + Fade")
                    .transition(.scale.combined(with: .opacity))
                
                // Asymmetric transition
                Text("Asymmetric")
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
    }
}

// Custom transition using modifier
struct RotateModifier: ViewModifier {
    let amount: Double
    let anchor: UnitPoint
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(amount), anchor: anchor)
            .clipped()
    }
}

extension AnyTransition {
    static var rotate: AnyTransition {
        .modifier(
            active: RotateModifier(amount: 90, anchor: .topLeading),
            identity: RotateModifier(amount: 0, anchor: .topLeading)
        )
    }
    
    static func rotate(amount: Double) -> AnyTransition {
        .modifier(
            active: RotateModifier(amount: amount, anchor: .center),
            identity: RotateModifier(amount: 0, anchor: .center)
        )
    }
}

// Advanced custom transition
extension AnyTransition {
    static var iris: AnyTransition {
        .modifier(
            active: IrisModifier(pct: 0),
            identity: IrisModifier(pct: 1)
        )
    }
}

struct IrisModifier: ViewModifier {
    let pct: CGFloat
    
    func body(content: Content) -> some View {
        content
            .clipShape(IrisShape(pct: pct))
    }
}

struct IrisShape: Shape {
    var pct: CGFloat
    
    var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = max(rect.width, rect.height) * pct
        path.addEllipse(in: CGRect(
            x: rect.midX - radius,
            y: rect.midY - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path
    }
}
```

---

### Q19: How do you implement hero animations with matchedGeometryEffect?

**Answer:**

```swift
// Basic matchedGeometryEffect
struct HeroAnimation: View {
    @Namespace private var namespace
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if isExpanded {
                ExpandedView(namespace: namespace)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isExpanded = false
                        }
                    }
            } else {
                CollapsedView(namespace: namespace)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isExpanded = true
                        }
                    }
            }
        }
    }
}

struct CollapsedView: View {
    let namespace: Namespace.ID
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue)
                .matchedGeometryEffect(id: "shape", in: namespace)
                .frame(width: 50, height: 50)
            
            Text("Title")
                .matchedGeometryEffect(id: "title", in: namespace)
            
            Spacer()
        }
        .padding()
    }
}

struct ExpandedView: View {
    let namespace: Namespace.ID
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue)
                .matchedGeometryEffect(id: "shape", in: namespace)
                .frame(height: 200)
            
            Text("Title")
                .font(.largeTitle)
                .matchedGeometryEffect(id: "title", in: namespace)
            
            Text("Details go here...")
            
            Spacer()
        }
        .padding()
    }
}

// Grid to detail animation
struct PhotoGrid: View {
    @Namespace private var namespace
    @State private var selectedPhoto: Photo?
    
    let photos: [Photo]
    
    var body: some View {
        ZStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(photos) { photo in
                    if selectedPhoto?.id != photo.id {
                        PhotoThumbnail(photo: photo, namespace: namespace)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedPhoto = photo
                                }
                            }
                    } else {
                        Color.clear.frame(width: 100, height: 100)
                    }
                }
            }
            
            if let photo = selectedPhoto {
                PhotoDetail(photo: photo, namespace: namespace)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedPhoto = nil
                        }
                    }
            }
        }
    }
}
```

---

## Performance Optimization

### Q20: How do you optimize list performance in SwiftUI?

**Answer:**

```swift
// Lazy loading with LazyVStack
struct OptimizedList: View {
    let items: [Item]
    
    var body: some View {
        ScrollView {
            LazyVStack {  // Only renders visible items
                ForEach(items) { item in
                    ItemRow(item: item)
                }
            }
        }
    }
}

// List with proper identity
struct EfficientList: View {
    @State private var items: [Item] = []
    
    var body: some View {
        List {
            ForEach(items) { item in  // Uses Identifiable
                ItemRow(item: item)
            }
        }
        .listStyle(.plain)
    }
}

// Avoiding expensive operations in body
struct OptimizedItemRow: View {
    let item: Item
    
    // Precompute expensive values
    private let formattedDate: String
    private let formattedPrice: String
    
    init(item: Item) {
        self.item = item
        self.formattedDate = Self.dateFormatter.string(from: item.date)
        self.formattedPrice = Self.priceFormatter.string(from: NSNumber(value: item.price)) ?? ""
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            VStack(alignment: .trailing) {
                Text(formattedPrice)
                Text(formattedDate)
            }
        }
    }
}

// Pagination
struct PaginatedList: View {
    @StateObject private var viewModel = PaginatedViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                ItemRow(item: item)
                    .onAppear {
                        if item == viewModel.items.last {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    }
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

---

### Q21: How do you debug SwiftUI performance issues?

**Answer:**

```swift
// 1. Track view body evaluations
struct DebuggableView: View {
    let item: Item
    
    var body: some View {
        let _ = print("Body evaluated for \(item.id)")  // Debug print
        
        Text(item.name)
    }
}

// 2. Use Self._printChanges() (iOS 15+)
struct DebugChangesView: View {
    @State private var count = 0
    @State private var name = ""
    
    var body: some View {
        let _ = Self._printChanges()  // Prints what caused redraw
        
        VStack {
            Text("Count: \(count)")
            TextField("Name", text: $name)
        }
    }
}

// 3. Instruments Time Profiler
// Profile > Time Profiler > Look for body evaluations

// 4. Isolate expensive views
struct ExpensiveView: View {
    let data: [Item]
    
    var body: some View {
        // Expensive computation
        let processed = data.map { expensiveTransform($0) }
        
        ForEach(processed, id: \.id) { item in
            Text(item.name)
        }
    }
}

// Better: Move computation out of body
struct OptimizedExpensiveView: View {
    let processedData: [ProcessedItem]
    
    init(data: [Item]) {
        self.processedData = data.map { expensiveTransform($0) }
    }
    
    var body: some View {
        ForEach(processedData, id: \.id) { item in
            Text(item.name)
        }
    }
}

// 5. Measure with benchmarks
func measureViewCreation() {
    let start = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<1000 {
        _ = ContentView().body
    }
    
    let end = CFAbsoluteTimeGetCurrent()
    print("Time: \(end - start) seconds")
}
```

---

## Custom Views & Modifiers

### Q22: How do you create custom view modifiers?

**Answer:**

```swift
// Basic custom modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// Modifier with parameters
struct BorderedModifier: ViewModifier {
    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
}

extension View {
    func bordered(
        color: Color = .gray,
        width: CGFloat = 1,
        cornerRadius: CGFloat = 8
    ) -> some View {
        modifier(BorderedModifier(
            color: color,
            width: width,
            cornerRadius: cornerRadius
        ))
    }
}

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
            .onChange(of: trigger) { _ in
                shake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shake = false
                }
            }
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
        view.background(Color.yellow)
    }
```

---

### Q23: How do you create custom shapes and paths?

**Answer:**

```swift
// Custom shape
struct Polygon: Shape {
    let sides: Int
    
    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path() }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angle = .pi * 2 / Double(sides)
        
        var path = Path()
        
        for i in 0..<sides {
            let x = center.x + radius * cos(angle * Double(i) - .pi / 2)
            let y = center.y + radius * sin(angle * Double(i) - .pi / 2)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// Animatable shape
struct AnimatablePolygon: Shape {
    var sides: Double  // Use Double for animation
    
    var animatableData: Double {
        get { sides }
        set { sides = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        // Same as above but using sides as Double
        let intSides = Int(sides)
        guard intSides >= 3 else { return Path() }
        
        // ... path calculation
        return Path()
    }
}

// Usage with animation
struct AnimatedShape: View {
    @State private var sides: Double = 3
    
    var body: some View {
        AnimatablePolygon(sides: sides)
            .fill(.blue)
            .frame(width: 200, height: 200)
            .onTapGesture {
                withAnimation(.spring()) {
                    sides = sides < 12 ? sides + 1 : 3
                }
            }
    }
}

// Complex path
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: height))
        
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            control1: CGPoint(x: width / 2, y: height * 3 / 4),
            control2: CGPoint(x: 0, y: height / 2)
        )
        
        path.addArc(
            center: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        path.addArc(
            center: CGPoint(x: width * 3 / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height / 2),
            control2: CGPoint(x: width / 2, y: height * 3 / 4)
        )
        
        return path
    }
}
```

---

## Data Flow Patterns

### Q24: How do you implement MVVM in SwiftUI?

**Answer:**

```swift
// Model
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
}

// ViewModel
@MainActor
class UserViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            users = try await userService.fetchUsers()
        } catch {
            self.error = error
        }
    }
    
    func addUser(name: String, email: String) async {
        do {
            let newUser = try await userService.createUser(name: name, email: email)
            users.append(newUser)
        } catch {
            self.error = error
        }
    }
    
    func deleteUser(_ user: User) async {
        do {
            try await userService.deleteUser(id: user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            self.error = error
        }
    }
}

// View
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(viewModel.users) { user in
                            UserRow(user: user)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let user = viewModel.users[index]
                                Task {
                                    await viewModel.deleteUser(user)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Users")
            .toolbar {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddUserSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
            .task {
                await viewModel.loadUsers()
            }
        }
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
```

---

### Q25: How do you implement dependency injection in SwiftUI?

**Answer:**

```swift
// Protocol-based dependencies
protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
    func createUser(name: String, email: String) async throws -> User
}

// Real implementation
class UserService: UserServiceProtocol {
    func fetchUsers() async throws -> [User] {
        // Network call
        return []
    }
    
    func createUser(name: String, email: String) async throws -> User {
        // Network call
        return User(id: UUID().uuidString, name: name, email: email)
    }
}

// Mock for testing
class MockUserService: UserServiceProtocol {
    var users: [User] = []
    var shouldFail = false
    
    func fetchUsers() async throws -> [User] {
        if shouldFail { throw MockError.failed }
        return users
    }
    
    func createUser(name: String, email: String) async throws -> User {
        let user = User(id: UUID().uuidString, name: name, email: email)
        users.append(user)
        return user
    }
}

// Dependency container
class DependencyContainer: ObservableObject {
    let userService: UserServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    
    init(
        userService: UserServiceProtocol = UserService(),
        analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    ) {
        self.userService = userService
        self.analyticsService = analyticsService
    }
    
    static let live = DependencyContainer()
    static let mock = DependencyContainer(
        userService: MockUserService(),
        analyticsService: MockAnalyticsService()
    )
}

// Environment-based injection
struct DependencyKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.live
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyKey.self] }
        set { self[DependencyKey.self] = newValue }
    }
}

// Usage in views
struct ContentView: View {
    @Environment(\.dependencies) var dependencies
    
    var body: some View {
        UserListView(service: dependencies.userService)
    }
}

// Preview with mock dependencies
#Preview {
    ContentView()
        .environment(\.dependencies, .mock)
}
```

---

## Testing SwiftUI

### Q26: How do you unit test SwiftUI ViewModels?

**Answer:**

```swift
// ViewModel to test
@MainActor
class CounterViewModel: ObservableObject {
    @Published private(set) var count = 0
    @Published private(set) var history: [Int] = []
    
    func increment() {
        count += 1
        history.append(count)
    }
    
    func decrement() {
        count -= 1
        history.append(count)
    }
    
    func reset() {
        count = 0
        history.removeAll()
    }
}

// Tests
@MainActor
class CounterViewModelTests: XCTestCase {
    var viewModel: CounterViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = CounterViewModel()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertTrue(viewModel.history.isEmpty)
    }
    
    func testIncrement() {
        viewModel.increment()
        
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertEqual(viewModel.history, [1])
    }
    
    func testDecrement() {
        viewModel.decrement()
        
        XCTAssertEqual(viewModel.count, -1)
        XCTAssertEqual(viewModel.history, [-1])
    }
    
    func testReset() {
        viewModel.increment()
        viewModel.increment()
        viewModel.reset()
        
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertTrue(viewModel.history.isEmpty)
    }
}

// Testing async operations
@MainActor
class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    var mockService: MockUserService!
    
    override func setUp() {
        super.setUp()
        mockService = MockUserService()
        viewModel = UserViewModel(userService: mockService)
    }
    
    func testLoadUsers() async {
        let expectedUsers = [
            User(id: "1", name: "John", email: "john@example.com")
        ]
        mockService.users = expectedUsers
        
        await viewModel.loadUsers()
        
        XCTAssertEqual(viewModel.users, expectedUsers)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadUsersFailure() async {
        mockService.shouldFail = true
        
        await viewModel.loadUsers()
        
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertNotNil(viewModel.error)
    }
}
```

---

### Q27: How do you write UI tests for SwiftUI apps?

**Answer:**

```swift
// App with accessibility identifiers
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .accessibilityIdentifier("emailTextField")
            
            SecureField("Password", text: $password)
                .accessibilityIdentifier("passwordTextField")
            
            Button("Login") {
                login()
            }
            .accessibilityIdentifier("loginButton")
            .disabled(email.isEmpty || password.isEmpty)
            
            if isLoading {
                ProgressView()
                    .accessibilityIdentifier("loadingIndicator")
            }
        }
    }
    
    func login() { }
}

// UI Tests
class LoginUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testLoginButtonDisabledWithEmptyFields() {
        let loginButton = app.buttons["loginButton"]
        
        XCTAssertFalse(loginButton.isEnabled)
    }
    
    func testLoginButtonEnabledWithValidInput() {
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        XCTAssertTrue(loginButton.isEnabled)
    }
    
    func testSuccessfulLogin() {
        // Enter credentials
        app.textFields["emailTextField"].tap()
        app.textFields["emailTextField"].typeText("test@example.com")
        
        app.secureTextFields["passwordTextField"].tap()
        app.secureTextFields["passwordTextField"].typeText("password123")
        
        // Tap login
        app.buttons["loginButton"].tap()
        
        // Verify navigation to home
        XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
    }
}

// Snapshot testing with ViewInspector
import ViewInspector

extension LoginView: Inspectable { }

class LoginViewTests: XCTestCase {
    func testInitialState() throws {
        let view = LoginView()
        
        let email = try view.inspect().textField(0).input()
        let password = try view.inspect().secureField(0).input()
        
        XCTAssertEqual(email, "")
        XCTAssertEqual(password, "")
    }
}
```

---

## Summary

Key SwiftUI concepts for interviews:

| Topic | Key Points |
|-------|-----------|
| Fundamentals | Declarative syntax, View protocol, @ViewBuilder |
| State Management | @State, @Binding, @StateObject, @ObservedObject |
| Lifecycle | View identity, onAppear vs task, update optimization |
| Layout | Layout algorithm, custom layouts, alignment guides |
| Navigation | NavigationStack, NavigationPath, deep linking |
| Animation | Implicit/explicit, transitions, matchedGeometryEffect |
| Performance | Lazy loading, view isolation, debugging |
| Testing | ViewModel testing, UI testing, ViewInspector |

Master these concepts and practice building real apps to prepare for SwiftUI interviews.

---

*Last updated: 2024*
