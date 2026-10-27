/// A small, fast generator whose sequence depends only on its seed, so a quiz can be repeated
/// on any machine (SplitMix64, as in Steele, Lea and Flood, "Fast Splittable Pseudorandom
/// Number Generators", OOPSLA 2014).
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}

public enum Quiz {
    /// Picks `count` different questions in a random order that depends only on `seed`.
    ///
    /// A `count` of zero or less gives an empty quiz; a `count` larger than the pool gives the
    /// whole pool, shuffled.
    public static func pick(_ count: Int, from pool: [Question], seed: UInt64) -> [Question] {
        guard count > 0, !pool.isEmpty else { return [] }
        let size = min(count, pool.count)
        var generator = SeededGenerator(seed: seed)
        var picked = pool
        // A partial Fisher–Yates shuffle: only the first `size` slots are settled.
        for slot in 0..<size {
            let other = Int.random(in: slot..<picked.count, using: &generator)
            picked.swapAt(slot, other)
        }
        return Array(picked.prefix(size))
    }
}
