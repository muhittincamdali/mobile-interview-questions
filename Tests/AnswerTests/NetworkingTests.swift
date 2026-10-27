import Foundation
#if canImport(FoundationNetworking)
// On Linux, URLSession and URLRequest live in a separate module.
import FoundationNetworking
#endif
import Testing

// Checks the claims in questions/ios/data-and-networking.md with a URLProtocol stub, so no
// request leaves the machine.

/// Answers every request with the status code in the URL's last path component.
final class StubProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let status = Int(url.lastPathComponent),
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"status": \#(status)}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

#if canImport(Darwin)
let usesAppleFoundation = true
#else
let usesAppleFoundation = false
#endif

enum HTTPError: Error, Equatable {
    case notHTTP
    case status(Int)
}

/// The helper from the answer: URLSession does not treat 4xx or 5xx as errors.
func data(for request: URLRequest, session: URLSession) async throws -> Data {
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw HTTPError.notHTTP }
    guard (200..<300).contains(http.statusCode) else { throw HTTPError.status(http.statusCode) }
    return data
}

@Suite("Networking answers")
struct NetworkingTests {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: configuration)
    }()

    @Test("IOS-049: URLSession returns a 404 as a normal response, not as an error")
    func statusCodesAreNotErrors() async throws {
        let request = URLRequest(url: URL(string: "https://api.test/items/404")!)
        let (body, response) = try await session.data(for: request)
        #expect((response as? HTTPURLResponse)?.statusCode == 404)
        #expect(String(decoding: body, as: UTF8.self) == #"{"status": 404}"#)
    }

    @Test("IOS-049: the helper turns non-2xx responses into errors")
    func validatingStatusCodes() async throws {
        let ok = try await data(for: URLRequest(url: URL(string: "https://api.test/items/200")!), session: session)
        #expect(!ok.isEmpty)
        await #expect(throws: HTTPError.status(503)) {
            try await data(for: URLRequest(url: URL(string: "https://api.test/items/503")!), session: session)
        }
    }

    @Test("IOS-049: cancelling the task before the request throws CancellationError")
    func cancellingARequest() async {
        let task = Task {
            try await Task.sleep(for: .seconds(60))
            return try await session.data(from: URL(string: "https://api.test/items/200")!)
        }
        task.cancel()
        let result = await task.result
        #expect(throws: CancellationError.self) { try result.get() }
    }

    /// The answer describes Apple's URLSession. swift-corelibs-foundation, the Foundation used on
    /// Linux, starts the request even when the task is already cancelled, so this check runs only
    /// where the answer applies.
    @Test(
        "IOS-049: a request started in a cancelled task fails with URLError.cancelled",
        .enabled(if: usesAppleFoundation, "Linux Foundation does not cancel a request from a cancelled task")
    )
    func requestInACancelledTask() async {
        let cancelledBeforeRequest = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await session.data(from: URL(string: "https://api.test/items/200")!)
        }
        let error = await #expect(throws: URLError.self) { try await cancelledBeforeRequest.value }
        #expect(error?.code == .cancelled)
    }
}
