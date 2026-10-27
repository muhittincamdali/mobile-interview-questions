import Observation
import Testing

// Checks the claim in questions/ios/swiftui.md that @Observable tracks the properties a view
// reads, which is what limits SwiftUI updates to the views that use a changed property.

@Observable
final class ProfileModel {
    var name = "Ada"
    var unreadCount = 0
}

@Suite("Observation answers")
struct ObservationTests {
    /// Reads `read` inside withObservationTracking, then runs `change` and reports whether the
    /// tracking fired.
    private func fires(reading read: @escaping (ProfileModel) -> Void, change: (ProfileModel) -> Void) -> Bool {
        let model = ProfileModel()
        let fired = Flag()
        withObservationTracking {
            read(model)
        } onChange: {
            fired.set()
        }
        change(model)
        return fired.value
    }

    @Test("IOS-035: only the properties read during tracking trigger a change")
    func observationTracksReadProperties() {
        #expect(fires(reading: { _ = $0.name }, change: { $0.name = "Lin" }))
        #expect(!fires(reading: { _ = $0.name }, change: { $0.unreadCount = 3 }), "unreadCount was not read")
        #expect(fires(reading: { _ = $0.unreadCount }, change: { $0.unreadCount += 1 }))
    }

    @Test("IOS-035: onChange fires once; tracking has to be set up again for the next change")
    func observationFiresOnce() {
        let model = ProfileModel()
        let count = Tally()
        withObservationTracking {
            _ = model.name
        } onChange: {
            count.add()
        }
        model.name = "One"
        model.name = "Two"
        #expect(count.value == 1)
    }
}

/// Mutable boxes for the onChange closures, which must be Sendable.
final class Flag: @unchecked Sendable {
    // onChange runs synchronously inside the setter on this thread.
    private(set) var value = false
    func set() { value = true }
}

final class Tally: @unchecked Sendable {
    private(set) var value = 0
    func add() { value += 1 }
}
