# Data and networking

URLSession, persistence, secrets and transport security. The networking answer is checked in
[NetworkingTests](../../Tests/AnswerTests/NetworkingTests.swift) against a local `URLProtocol`
stub.

## IOS-049: Does `URLSession` throw for a 404 or 500 response? How do you write a request with async/await?

**Level:** junior · **Verified by:** [NetworkingTests](../../Tests/AnswerTests/NetworkingTests.swift)

No. `URLSession` throws a `URLError` only when there is no HTTP response at all: no network,
timeout, TLS failure, cancellation. A 404 or 500 is a successful transfer with a status code, so
check it yourself:

```swift
func data(for request: URLRequest, session: URLSession = .shared) async throws -> Data {
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw HTTPError.notHTTP }
    guard (200..<300).contains(http.statusCode) else { throw HTTPError.status(http.statusCode) }
    return data
}
```

The async methods take part in task cancellation: cancelling the calling task cancels the
request and throws `URLError(.cancelled)`. Other points interviewers look for: decode off the main
actor for large payloads, set `timeoutInterval` deliberately, use one configured `URLSession` per
API rather than creating one per request, and inject the session (or a protocol over it) so tests
can use a `URLProtocol` stub as the tests here do.

**References:** [Fetching website data into memory](https://developer.apple.com/documentation/foundation/fetching-website-data-into-memory) · [URLSession](https://developer.apple.com/documentation/foundation/urlsession)

## IOS-050: How do SwiftData and Core Data compare?

**Level:** mid

SwiftData (iOS 17) is a Swift-first persistence framework built on the same storage technology as
Core Data:

|             | SwiftData                                                                                                     | Core Data                                                         |
| ----------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Model       | `@Model` classes in code                                                                                      | `.xcdatamodeld` file plus `NSManagedObject` subclasses            |
| Queries     | `#Predicate` and `FetchDescriptor`, type-checked                                                              | `NSPredicate` strings, checked at run time                        |
| SwiftUI     | `@Query` and `.modelContainer`                                                                                | `@FetchRequest` and the managed object context in the environment |
| Concurrency | `ModelContext` per actor; `@ModelActor` for background work                                                   | contexts with `perform` blocks                                    |
| Migrations  | `VersionedSchema` and `SchemaMigrationPlan`                                                                   | lightweight and mapping-model migrations                          |
| Maturity    | newer; features added each year (custom stores, `#Unique` and history in iOS 18, model inheritance in iOS 26) | many years in production, more tuning options                     |

Choose SwiftData for new apps with a minimum of iOS 17 or later and simple to moderate models.
Keep Core Data for existing stores, for features SwiftData lacks in your minimum OS, or when you
need fine control over fetching and batching. Both can sync with CloudKit, which requires every
attribute to be optional or have a default and does not support unique constraints.

**References:** [SwiftData](https://developer.apple.com/documentation/swiftdata) · [Core Data](https://developer.apple.com/documentation/coredata)

## IOS-051: Where do you store an access token, and why not in `UserDefaults`?

**Level:** junior

In the **Keychain**. `UserDefaults` is a plain property list in the app's container: it is
included in unencrypted device backups, readable on a jailbroken device and from a Mac backup, and
not meant for secrets.

The Keychain encrypts items with keys protected by the Secure Enclave, and the accessibility class
decides when the item can be read:

- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — only while the device is unlocked, never moved
  to another device through a backup. A good default for tokens.
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — also readable in the background after the
  first unlock since boot, which background refresh needs.
- `kSecAccessControl` with `.biometryCurrentSet` — reading requires Face ID or Touch ID.

Also: keychain items can survive deleting the app, so clear them on first launch after a
reinstall if that matters; share items between your apps with a keychain access group; and never
log tokens or put them in URLs, where they end up in server logs.

**References:** [Keychain services](https://developer.apple.com/documentation/security/keychain-services) · [Restricting keychain item accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility)

## IOS-052: What does App Transport Security enforce, and how do you pin a server's key?

**Level:** senior

App Transport Security (ATS) is on by default: connections made with `URLSession` must use HTTPS
with TLS 1.2 or later, forward secrecy and valid certificates. Exceptions go in the Info.plist
(`NSAppTransportSecurity`), are reviewed by App Review, and should be limited to specific domains
(`NSExceptionDomains`), never `NSAllowsArbitraryLoads` for the whole app.

Pinning goes further: the app accepts only certificates whose public key it knows, so a
compromised or user-installed certificate authority cannot intercept traffic. Since iOS 14 it can
be declared without code under `NSPinnedDomains`: per domain, `NSPinnedLeafIdentities` or
`NSPinnedCAIdentities` with the base64 SHA-256 of the key's SubjectPublicKeyInfo
(`SPKI-SHA256-BASE64`). In code, implement `urlSession(_:didReceive:completionHandler:)` and
compare the server's key.

Pin keys, not certificates, include at least one backup key (a pin on a single key bricks the app's
networking the day that key is rotated), prefer pinning an intermediate CA you control, and plan
how to update pins, since old app versions live for years.

**References:** [Preventing Insecure Network Connections](https://developer.apple.com/documentation/security/preventing-insecure-network-connections) · [Identity Pinning: How to configure server certificates for your app](https://developer.apple.com/news/?id=g9ejcf8y)

## IOS-053: How do you cache network responses and images?

**Level:** mid

Use the layers that exist before building your own:

1. **HTTP caching** with `URLCache`. `URLSession` honours `Cache-Control`, `ETag` and
   `Last-Modified`, revalidating with `If-None-Match` and getting a cheap `304 Not Modified`. Size
   the shared cache (`URLCache(memoryCapacity:diskCapacity:)`) and let the server set the
   policy. `requestCachePolicy = .returnCacheDataElseLoad` is an option for offline reading.
2. **Decoded images in memory**: `NSCache` keyed by URL and target size. It evicts under memory
   pressure and is thread-safe. Store downsampled images; the decoded size is width × height × 4
   bytes no matter how small the file is.
3. **Downsampling** with ImageIO (`CGImageSourceCreateThumbnailAtIndex` with
   `kCGImageSourceThumbnailMaxPixelSize`) decodes straight to the display size without decoding
   the full image first.
4. **Your own data** that must work offline belongs in a database (SwiftData, Core Data, SQLite),
   not a cache: caches may be purged, and files in `Caches/` can be deleted by the system when
   storage is low.

De-duplicate in-flight requests for the same URL (store the `Task` in a dictionary in an actor)
so a list that shows one avatar ten times downloads it once.

**References:** [Accessing cached data](https://developer.apple.com/documentation/foundation/accessing-cached-data) · [NSCache](https://developer.apple.com/documentation/foundation/nscache)
