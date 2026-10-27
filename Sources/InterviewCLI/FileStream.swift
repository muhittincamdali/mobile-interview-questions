import Foundation

/// Writes text to a file handle in blocks of 64 KiB, so `interview` prints a long listing while it
/// is made instead of holding all of it in memory first.
public struct FileStream: TextOutputStream {
    static let blockSize = 1 << 16
    static let newline = UInt8(ascii: "\n")

    private let handle: FileHandle
    private let writesEachLine: Bool
    private var buffer = Data()

    /// - Parameter writesEachLine: Writes the buffer whenever a line ends instead of once 64 KiB
    ///   are collected. Standard error uses it: a message held back until exit could appear after
    ///   output that was printed later.
    public init(_ handle: FileHandle, writesEachLine: Bool = false) {
        self.handle = handle
        self.writesEachLine = writesEachLine
    }

    public mutating func write(_ string: String) {
        buffer.append(contentsOf: string.utf8)
        if buffer.count >= Self.blockSize || (writesEachLine && string.utf8.contains(Self.newline)) {
            flush()
        }
    }

    /// Writes what is still buffered; call it before the process exits.
    public mutating func flush() {
        guard !buffer.isEmpty else { return }
        handle.write(buffer)
        buffer.removeAll(keepingCapacity: true)
    }
}
