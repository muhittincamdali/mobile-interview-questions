import Foundation
import Synchronization
import Testing

// Each test checks a claim made in questions/ios/swift-language.md. The question ID at the start
// of the test name is what the linter looks for.

@Suite("Swift language answers")
struct SwiftLanguageTests {
    // MARK: IOS-001

    struct PointValue { var x = 0 }
    final class PointReference { var x = 0 }

    @Test("IOS-001: assigning a struct copies it, assigning a class instance shares it")
    func valueAndReferenceSemantics() {
        var a = PointValue()
        var b = a
        b.x = 10
        #expect(a.x == 0)
        a.x = 1
        #expect(b.x == 10)

        let c = PointReference()
        let d = c
        d.x = 10
        #expect(c.x == 10)
        #expect(c === d)
    }

    // MARK: IOS-002

    /// A value type with copy-on-write storage, as in the answer.
    struct Notes {
        private final class Storage {
            var items: [String]
            init(_ items: [String]) { self.items = items }
        }

        private var storage = Storage([])

        var items: [String] { storage.items }
        var storageIdentity: ObjectIdentifier { ObjectIdentifier(storage) }

        mutating func append(_ item: String) {
            if !isKnownUniquelyReferenced(&storage) {
                storage = Storage(storage.items)
            }
            storage.items.append(item)
        }
    }

    @Test("IOS-002: copies share storage until one of them is mutated")
    func copyOnWrite() {
        var first = Notes()
        first.append("a")
        var second = first
        #expect(first.storageIdentity == second.storageIdentity, "a copy shares the buffer")

        second.append("b")
        #expect(first.storageIdentity != second.storageIdentity, "the first write copies")
        #expect(first.items == ["a"])
        #expect(second.items == ["a", "b"])

        let before = second.storageIdentity
        second.append("c")
        #expect(second.storageIdentity == before, "a uniquely referenced buffer is mutated in place")
    }

    @Test("IOS-002: Array uses the same copy-on-write strategy")
    func arrayCopyOnWrite() {
        let original = [1, 2, 3]
        var copy = original
        let shared = original.withUnsafeBufferPointer { a in copy.withUnsafeBufferPointer { b in a.baseAddress == b.baseAddress } }
        #expect(shared)
        copy.append(4)
        let stillShared = original.withUnsafeBufferPointer { a in copy.withUnsafeBufferPointer { b in a.baseAddress == b.baseAddress } }
        #expect(!stillShared)
    }

    // MARK: IOS-003

    enum PaymentState: Equatable {
        case idle
        case processing(progress: Double)
        case failed(code: Int, message: String)
    }

    func describe(_ state: PaymentState) -> String {
        switch state {
        case .idle: "idle"
        case .processing(let progress) where progress >= 1: "finishing"
        case .processing(let progress): "processing \(Int(progress * 100))%"
        case .failed(let code, _) where code == 401: "sign in again"
        case .failed(_, let message): message
        }
    }

    @Test("IOS-003: a switch over associated values must be exhaustive and can bind and filter")
    func enumsWithAssociatedValues() {
        #expect(describe(.idle) == "idle")
        #expect(describe(.processing(progress: 0.25)) == "processing 25%")
        #expect(describe(.processing(progress: 1)) == "finishing")
        #expect(describe(.failed(code: 401, message: "x")) == "sign in again")
        #expect(describe(.failed(code: 500, message: "Server error")) == "Server error")
    }

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

    // MARK: IOS-011

    @Test("IOS-011: count counts characters, not bytes or UTF-16 units")
    func unicodeStrings() {
        let flag = "🇹🇷"
        #expect(flag.count == 1)
        #expect(flag.unicodeScalars.count == 2)
        #expect(flag.utf16.count == 4)
        #expect(flag.utf8.count == 8)

        let composed = "caf\u{E9}"
        let decomposed = "cafe\u{301}"
        #expect(composed == decomposed, "canonically equivalent strings are equal")
        #expect(composed.count == decomposed.count)
        #expect(composed.utf8.count != decomposed.utf8.count)

        let word = "Swift"
        let third = word[word.index(word.startIndex, offsetBy: 2)]
        #expect(third == "i")
    }

    // MARK: IOS-012

    @Test("IOS-012: Int(exactly:) returns nil where Int(_:) would trap")
    func safeNumericConversion() throws {
        #expect(Int(exactly: 42.0) == 42)
        #expect(Int(exactly: 3.5) == nil)
        #expect(Int(exactly: Double.nan) == nil)
        #expect(Int(exactly: Double.infinity) == nil)
        let huge = try #require(Double("1e300"), "read at run time, like a value from JSON")
        #expect(Int(exactly: huge) == nil)
        #expect(Int(3.9) == 3, "Int(_:) truncates toward zero")
        #expect(Int((3.5).rounded()) == 4)
        #expect(Int(exactly: (-2.5).rounded(.toNearestOrEven)) == -2)

        let (sum, overflow) = Int.max.addingReportingOverflow(1)
        #expect(overflow)
        #expect(sum == Int.min)
        #expect(Int8(127) &+ 1 == -128, "&+ wraps instead of trapping")
        #expect(Int8(clamping: 300) == 127)
        #expect(Int8(exactly: 300) == nil)
    }

    // MARK: IOS-013

    @Test("IOS-013: a lazy property runs once, a lazy sequence runs per element on demand")
    func laziness() {
        var calls = 0
        let numbers = (1...1_000).lazy.map { value -> Int in
            calls += 1
            return value * 2
        }
        #expect(numbers.first(where: { $0 > 10 }) == 12)
        #expect(calls == 6, "only the elements up to the first match were mapped")

        let report = Report()
        #expect(report.buildCount == 0)
        _ = report.summary
        _ = report.summary
        #expect(report.buildCount == 1)
    }

    // MARK: IOS-014

    struct User: Codable, Equatable {
        var id: Int
        var displayName: String
        var isAdmin: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case isAdmin = "is_admin"
        }

        init(id: Int, displayName: String, isAdmin: Bool) {
            self.id = id
            self.displayName = displayName
            self.isAdmin = isAdmin
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            displayName = try container.decode(String.self, forKey: .displayName)
            // A field older servers do not send gets a default instead of failing the decode.
            isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        }
    }

    @Test("IOS-014: CodingKeys rename fields and decodeIfPresent gives defaults")
    func codable() throws {
        let decoder = JSONDecoder()
        let full = try decoder.decode(User.self, from: Data(#"{"id": 1, "display_name": "Ada", "is_admin": true}"#.utf8))
        #expect(full == User(id: 1, displayName: "Ada", isAdmin: true))

        let old = try decoder.decode(User.self, from: Data(#"{"id": 2, "display_name": "Lin"}"#.utf8))
        #expect(old.isAdmin == false)

        #expect(throws: DecodingError.self) {
            try decoder.decode(User.self, from: Data(#"{"id": "3", "display_name": "x"}"#.utf8))
        }

        let encoded = try JSONEncoder().encode(full)
        let keys = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any]).keys
        #expect(Set(keys) == ["id", "display_name", "is_admin"])
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

final class Report {
    private(set) var buildCount = 0

    lazy var summary: String = {
        buildCount += 1
        return "Summary"
    }()
}
