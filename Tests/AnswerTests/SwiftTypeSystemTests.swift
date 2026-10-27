import Synchronization
import Testing

// Each test checks a claim made in questions/ios/swift-language.md about protocols, generics,
// errors, ownership and the type-level language features. The question ID at the start of the
// test name is what the linter looks for.

@Suite("Swift type system answers")
struct SwiftTypeSystemTests {
    // MARK: IOS-004

    @Test("IOS-004: a method only declared in an extension is dispatched statically")
    func protocolExtensionDispatch() {
        let concrete = Robot()
        let existential: any Greeter = Robot()
        #expect(concrete.greet() == "Robot greet")
        #expect(existential.greet() == "Robot greet", "a requirement is dispatched through the witness table")
        #expect(concrete.wave() == "Robot wave")
        #expect(existential.wave() == "default wave", "an extension-only method uses the static type")
    }

    // MARK: IOS-005

    @Test("IOS-005: some keeps one hidden concrete type, any boxes different types")
    func opaqueAndExistentialTypes() {
        let shapes: [any Shape] = [Square(side: 2), Circle(radius: 1)]
        #expect(shapes.map { $0.area }.reduce(0, +) > 4)

        let made = makeShape()
        #expect(type(of: made) == Square.self, "the caller cannot name it, but the type is fixed")
        #expect(totalArea(of: [Square(side: 1), Square(side: 3)]) == 10)
    }

    // MARK: IOS-006

    @Test("IOS-006: a primary associated type constrains some and any")
    func primaryAssociatedTypes() {
        #expect(sum(of: [1, 2, 3]) == 6)
        #expect(sum(of: Set([4, 5])) == 9)
        #expect(sum(of: 1...4) == 10)
        let collections: [any Collection<Int>] = [[1, 2], 3...5]
        #expect(collections.map { $0.count } == [2, 3])
    }

    // MARK: IOS-007

    enum ParseError: Error, Equatable {
        case empty
        case notANumber(String)
    }

    func parsePort(_ text: String) throws(ParseError) -> Int {
        guard !text.isEmpty else { throw .empty }
        guard let port = Int(text), (1...65_535).contains(port) else { throw .notANumber(text) }
        return port
    }

    @Test("IOS-007: typed throws gives the catch block the concrete error type")
    func typedThrows() {
        do {
            _ = try parsePort("http")
            Issue.record("expected an error")
        } catch {
            // `error` is ParseError here, not `any Error`, so no cast is needed.
            #expect(error == .notANumber("http"))
        }
        #expect(throws: ParseError.empty) { try parsePort("") }
        #expect((try? parsePort("8080")) == 8080)
    }

    // MARK: IOS-008

    @Test("IOS-008: a noncopyable value is consumed once and discard skips deinit")
    func noncopyableTypes() {
        do {
            let token = FileToken(descriptor: 3)
            token.close()
            // Using `token` here would not compile: close() consumed it.
        }
        #expect(fileTokenEvents.withLock { $0 } == ["close 3"], "close() consumed the token, so deinit did not run")

        do {
            _ = FileToken(descriptor: 4)
        }
        #expect(fileTokenEvents.withLock { $0 } == ["close 3", "deinit 4"], "a token that is never closed is cleaned up by deinit")
    }

    // MARK: IOS-009

    @Test("IOS-009: a property wrapper stores the logic and exposes a projected value")
    func propertyWrappers() {
        var settings = Settings()
        settings.volume = 150
        #expect(settings.volume == 100)
        settings.volume = -3
        #expect(settings.volume == 0)
        #expect(settings.$volume == 0...100, "$volume is the projected value")
    }

    // MARK: IOS-010

    @Test("IOS-010: a result builder turns statements, if and for into one value")
    func resultBuilders() {
        let showFooter = false
        let lines = makeLines {
            "Header"
            for index in 1...2 { "Item \(index)" }
            if showFooter { "Footer" }
        }
        #expect(lines == ["Header", "Item 1", "Item 2"])
    }
}

// MARK: - Types used by the tests

protocol Greeter {
    func greet() -> String
}

extension Greeter {
    func greet() -> String { "default greet" }
    func wave() -> String { "default wave" }
}

struct Robot: Greeter {
    func greet() -> String { "Robot greet" }
    func wave() -> String { "Robot wave" }
}

protocol Shape {
    var area: Double { get }
}

struct Square: Shape {
    var side: Double
    var area: Double { side * side }
}

struct Circle: Shape {
    var radius: Double
    var area: Double { Double.pi * radius * radius }
}

func makeShape() -> some Shape { Square(side: 1) }

func totalArea(of shapes: [some Shape]) -> Double {
    shapes.map(\.area).reduce(0, +)
}

func sum(of values: some Collection<Int>) -> Int {
    values.reduce(0, +)
}

/// What FileToken did, for the IOS-008 test. A Mutex keeps the global safe under Swift 6.
let fileTokenEvents = Mutex<[String]>([])

struct FileToken: ~Copyable {
    // `discard self` needs trivially destroyed stored properties, so the token holds only an Int32.
    let descriptor: Int32

    consuming func close() {
        fileTokenEvents.withLock { $0.append("close \(descriptor)") }
        discard self
    }

    deinit {
        fileTokenEvents.withLock { $0.append("deinit \(descriptor)") }
    }
}

@propertyWrapper
struct Clamped {
    private var value: Int
    let range: ClosedRange<Int>

    init(wrappedValue: Int, _ range: ClosedRange<Int>) {
        self.range = range
        value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Int {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    var projectedValue: ClosedRange<Int> { range }
}

struct Settings {
    @Clamped(0...100) var volume = 50
}

@resultBuilder
enum LinesBuilder {
    static func buildExpression(_ line: String) -> [String] { [line] }
    static func buildBlock(_ parts: [String]...) -> [String] { parts.flatMap { $0 } }
    static func buildOptional(_ part: [String]?) -> [String] { part ?? [] }
    static func buildEither(first: [String]) -> [String] { first }
    static func buildEither(second: [String]) -> [String] { second }
    static func buildArray(_ parts: [[String]]) -> [String] { parts.flatMap { $0 } }
}

func makeLines(@LinesBuilder _ content: () -> [String]) -> [String] {
    content()
}
