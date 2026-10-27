import Foundation
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
final class Report {
    private(set) var buildCount = 0

    lazy var summary: String = {
        buildCount += 1
        return "Summary"
    }()
}
