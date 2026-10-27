import Testing

// Checks the claims in questions/ios/memory.md.

@Suite("Memory answers")
struct MemoryTests {
    final class Owner {
        var pet: Pet?
    }

    final class Pet {
        weak var weakOwner: Owner?
        unowned let unownedOwner: Owner

        init(owner: Owner) {
            unownedOwner = owner
            weakOwner = owner
        }
    }

    @Test("IOS-017: a weak reference becomes nil when the object is freed")
    func weakReferencesBecomeNil() {
        var owner: Owner? = Owner()
        let observer = WeakReference(owner)
        let pet = Pet(owner: owner!)
        owner?.pet = pet
        #expect(pet.weakOwner != nil)

        owner = nil
        #expect(observer.object == nil, "neither weak nor unowned references keep the owner alive")
        #expect(pet.weakOwner == nil)
        // Reading pet.unownedOwner now would trap: unowned is for references that never outlive
        // the object.
    }

    final class Downloader {
        static let deinitCount = DeinitCounter()
        var onFinish: (() -> Void)?
        var finished = false

        func startCapturingStrongly() {
            onFinish = { self.finished = true }
        }

        func startCapturingWeakly() {
            onFinish = { [weak self] in self?.finished = true }
        }

        deinit { Self.deinitCount.increment() }
    }

    @Test("IOS-018: a closure stored on self that captures self strongly leaks; [weak self] does not")
    func closureRetainCycles() {
        let counter = Downloader.deinitCount
        let start = counter.value

        var strong: Downloader? = Downloader()
        strong?.startCapturingStrongly()
        let leaked = WeakReference(strong)
        strong = nil
        #expect(leaked.object != nil, "self -> closure -> self keeps the object alive")
        #expect(counter.value == start)
        leaked.object?.onFinish = nil  // breaking the cycle by hand frees it
        #expect(leaked.object == nil)
        #expect(counter.value == start + 1)

        var weakly: Downloader? = Downloader()
        weakly?.startCapturingWeakly()
        let freed = WeakReference(weakly)
        weakly = nil
        #expect(freed.object == nil)
        #expect(counter.value == start + 2)
    }

    @Test("IOS-019: a capture list copies the value when the closure is created")
    func captureListsCopyValues() {
        var count = 1
        let byReference = { count }
        let byValue = { [count] in count }
        count = 2
        #expect(byReference() == 2, "a plain capture sees later changes")
        #expect(byValue() == 1, "[count] captured the value at creation")
    }
}

/// Watches an object without keeping it alive.
struct WeakReference<Object: AnyObject> {
    weak var object: Object?

    init(_ object: Object?) {
        self.object = object
    }
}

/// A counter that is safe to read from any test.
final class DeinitCounter: @unchecked Sendable {
    // Only touched by the serial memory tests above; the class exists so a static can hold it.
    private(set) var value = 0
    func increment() { value += 1 }
}
