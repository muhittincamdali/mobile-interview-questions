import Foundation

/// Writes text to a file handle in blocks of 64 KiB, so `interview` prints a long listing while it
/// is made instead of holding all of it in memory first.
public struct FileStream: TextOutputStream {
    static let blockSize = 1 << 16

    private let handle: FileHandle
    private var buffer = Data()

    public init(_ handle: FileHandle) {
        self.handle = handle
    }

    public mutating func write(_ string: String) {
        buffer.append(contentsOf: string.utf8)
        if buffer.count >= Self.blockSize { flush() }
    }

    /// Writes what is still buffered; call it before the process exits.
    public mutating func flush() {
        guard !buffer.isEmpty else { return }
        handle.write(buffer)
        buffer.removeAll(keepingCapacity: true)
    }
}
