import Foundation

/// Seconds of processor time the calling thread has used. Time the thread spends waiting for
/// a processor on a busy or shared machine is not counted, which is what made fixed time limits
/// fail on loaded CI runners.
private func threadProcessorSeconds() -> Double {
    var time = timespec()
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &time)
    return Double(time.tv_sec) + Double(time.tv_nsec) / 1e9
}

/// How much more processor time `work` needs when its input is `ratio` times larger: the
/// fastest of `attempts` runs at each size. Linear work gives about `ratio`; work that is
/// quadratic gives about `ratio * ratio`. `work` must run on the calling thread.
func growthFactor(
    ratio: Int = 8,
    attempts: Int = 3,
    smallSize: Int,
    work: (Int) throws -> Void
) throws -> Double {
    func fastest(_ size: Int) throws -> Double {
        var best = Double.infinity
        for _ in 0..<attempts {
            let start = threadProcessorSeconds()
            try work(size)
            best = min(best, threadProcessorSeconds() - start)
        }
        return best
    }
    let small = try fastest(smallSize)
    let large = try fastest(smallSize * ratio)
    return large / max(small, 0.000_1)
}

/// Linear work stays near the size ratio of 8; quadratic work reaches 64.
let maximumLinearGrowth = 24.0
