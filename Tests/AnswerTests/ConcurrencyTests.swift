import Foundation
import Synchronization
import Testing

// Checks the claims in questions/ios/concurrency.md.

@Suite("Concurrency answers")
struct ConcurrencyTests {
    // MARK: IOS-023

    @Test("IOS-023: a task group returns child results as they finish and waits for all of them")
    func taskGroupsCollectChildResults() async {
        let squares = await withTaskGroup(of: (Int, Int).self) { group in
            for number in 1...5 {
                group.addTask { (number, number * number) }
            }
            var results: [Int: Int] = [:]
            for await (number, square) in group {
                results[number] = square
            }
            return results
        }
        #expect(squares == [1: 1, 2: 4, 3: 9, 4: 16, 5: 25])
    }

    @Test("IOS-023: async let starts children right away and the parent awaits them")
    func asyncLet() async throws {
        async let first = slowValue(1)
        async let second = slowValue(2)
        let total = try await first + second
        #expect(total == 3)
    }

    // MARK: IOS-024

    @Test("IOS-024: cancelling a parent cancels its children, which must check for it")
    func cancellationIsCooperative() async {
        let started = AsyncStream<Void>.makeStream()
        let task = Task {
            await withTaskGroup(of: Bool.self) { group in
                group.addTask {
                    started.continuation.yield()
                    do {
                        try await Task.sleep(for: .seconds(60))
                        return false
                    } catch {
                        return error is CancellationError
                    }
                }
                group.addTask {
                    // A child that never checks keeps running until it returns on its own.
                    while !Task.isCancelled { await Task.yield() }
                    return true
                }
                var all: [Bool] = []
                for await result in group { all.append(result) }
                return all
            }
        }
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        task.cancel()
        let results = await task.value
        #expect(results == [true, true], "Task.sleep threw CancellationError and the loop saw isCancelled")
    }

    // MARK: IOS-025

    actor Counter {
        private(set) var value = 0
        func increment() { value += 1 }
    }

    @Test("IOS-025: an actor runs one call at a time, so concurrent increments are not lost")
    func actorsSerializeAccess() async {
        let counter = Counter()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1_000 {
                group.addTask { await counter.increment() }
            }
        }
        #expect(await counter.value == 1_000)
    }

    // MARK: IOS-026

    /// The bug from the answer: the balance is checked before an await and used after it.
    actor Account {
        private(set) var balance = 100
        let approval: @Sendable () async -> Void

        init(approval: @escaping @Sendable () async -> Void) {
            self.approval = approval
        }

        func withdrawCheckingFirst(_ amount: Int) async -> Bool {
            guard balance >= amount else { return false }
            await approval()  // the actor is free to run other calls here
            balance -= amount
            return true
        }

        func withdrawCheckingAfterAwait(_ amount: Int) async -> Bool {
            await approval()
            guard balance >= amount else { return false }
            balance -= amount
            return true
        }
    }

    @Test("IOS-026: actor state can change across an await (reentrancy)")
    func actorReentrancy() async {
        let gate = Gate()
        let account = Account(approval: { await gate.wait() })

        async let first = account.withdrawCheckingFirst(80)
        async let second = account.withdrawCheckingFirst(80)
        await gate.waitForWaiters(2)  // both calls passed the balance check and are suspended
        await gate.open()
        let bothApproved = await [first, second]
        #expect(bothApproved == [true, true])
        #expect(await account.balance == -60, "both withdrawals saw the old balance")

        let fixedGate = Gate()
        let fixed = Account(approval: { await fixedGate.wait() })
        async let third = fixed.withdrawCheckingAfterAwait(80)
        async let fourth = fixed.withdrawCheckingAfterAwait(80)
        await fixedGate.waitForWaiters(2)
        await fixedGate.open()
        let results = await [third, fourth]
        #expect(results.sorted { !$0 && $1 } == [false, true], "re-checking after the await lets only one through")
        #expect(await fixed.balance == 20)
    }

    // MARK: IOS-030

    @Test("IOS-030: AsyncStream with bufferingNewest drops older values nobody read")
    func asyncStreamBuffering() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(2))
        for value in 1...5 { continuation.yield(value) }
        continuation.finish()
        var received: [Int] = []
        for await value in stream { received.append(value) }
        #expect(received == [4, 5])

        let (unbounded, all) = AsyncStream.makeStream(of: Int.self)
        for value in 1...5 { all.yield(value) }
        all.finish()
        var everything: [Int] = []
        for await value in unbounded { everything.append(value) }
        #expect(everything == [1, 2, 3, 4, 5], "the default policy buffers without limit")
    }

    // MARK: IOS-031

    final class HitCounter: Sendable {
        private let hits = Mutex(0)
        func record() { hits.withLock { $0 += 1 } }
        var count: Int { hits.withLock { $0 } }
    }

    @Test("IOS-031: a Mutex makes a class Sendable and keeps every update")
    func mutexProtectsState() async {
        let counter = HitCounter()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    for _ in 0..<1_000 { counter.record() }
                }
            }
        }
        #expect(counter.count == 8_000)
    }

    // MARK: IOS-032

    /// A callback API like many older SDKs have.
    final class LegacyGeocoder: Sendable {
        func lookUp(_ query: String, completion: @escaping @Sendable (Result<String, any Error>) -> Void) {
            DispatchQueue.global().async {
                completion(query.isEmpty ? .failure(URLError(.badURL)) : .success("Found \(query)"))
            }
        }
    }

    func lookUp(_ query: String, with geocoder: LegacyGeocoder) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.lookUp(query) { result in
                continuation.resume(with: result)
            }
        }
    }

    @Test("IOS-032: a checked continuation turns a callback into async/await")
    func continuations() async throws {
        let geocoder = LegacyGeocoder()
        #expect(try await lookUp("Istanbul", with: geocoder) == "Found Istanbul")
        await #expect(throws: URLError.self) {
            try await lookUp("", with: geocoder)
        }
    }
}

private func slowValue(_ value: Int) async throws -> Int {
    try await Task.sleep(for: .milliseconds(10))
    return value
}

/// Suspends callers until `open()`; lets a test hold tasks at a known point without sleeping.
actor Gate {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var watchers: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var isOpen = false

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
            let ready = watchers.filter { $0.count <= waiters.count }
            watchers.removeAll { $0.count <= waiters.count }
            for watcher in ready { watcher.continuation.resume() }
        }
    }

    func waitForWaiters(_ count: Int) async {
        if waiters.count >= count { return }
        await withCheckedContinuation { watchers.append((count, $0)) }
    }

    func open() {
        isOpen = true
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
    }
}
