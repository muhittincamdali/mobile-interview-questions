# Mobile System Design Interview Questions

A comprehensive guide to system design questions specifically tailored for mobile engineering interviews. Covers architecture, scalability, offline-first design, and real-world mobile challenges.

---

## Table of Contents

- [Architecture Fundamentals](#architecture-fundamentals)
- [Networking & API Design](#networking--api-design)
- [Data Persistence](#data-persistence)
- [Offline-First Architecture](#offline-first-architecture)
- [Real-Time Systems](#real-time-systems)
- [Media Handling](#media-handling)
- [Performance & Scalability](#performance--scalability)
- [Security Design](#security-design)
- [Case Studies](#case-studies)

---

## Architecture Fundamentals

### Q: Design a scalable mobile app architecture. What patterns would you use?

**Difficulty:** 🔴 Senior

A scalable mobile architecture needs clear separation of concerns, testability, and flexibility for future changes.

**Recommended Layers:**

```
┌─────────────────────────────────────────┐
│            Presentation Layer           │
│    (Views, ViewModels, Coordinators)    │
├─────────────────────────────────────────┤
│             Domain Layer                │
│      (Use Cases, Business Logic)        │
├─────────────────────────────────────────┤
│              Data Layer                 │
│  (Repositories, DataSources, Mappers)   │
├─────────────────────────────────────────┤
│           Infrastructure Layer          │
│   (Network, Database, Cache, Analytics) │
└─────────────────────────────────────────┘
```

**Key Principles:**

| Principle | Benefit |
|-----------|---------|
| Dependency Injection | Testability, loose coupling |
| Unidirectional Data Flow | Predictable state |
| Single Responsibility | Maintainable modules |
| Interface Segregation | Flexible implementations |

```swift
// Clean Architecture Example
protocol UserRepository {
    func fetchUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
}

class GetUserProfileUseCase {
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService
    
    init(userRepository: UserRepository, analyticsService: AnalyticsService) {
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }
    
    func execute(userId: String) async throws -> UserProfile {
        analyticsService.track(.profileViewed(userId))
        let user = try await userRepository.fetchUser(id: userId)
        return UserProfile(from: user)
    }
}
```

---

### Q: Explain the differences between MVC, MVVM, and MVI. When would you choose each?

**Difficulty:** 🟡 Mid

| Pattern | Data Flow | State Management | Best For |
|---------|-----------|------------------|----------|
| MVC | Bidirectional | Distributed | Simple apps, rapid prototyping |
| MVVM | Bidirectional with bindings | ViewModel-centric | Medium complexity, reactive apps |
| MVI | Unidirectional | Single state | Complex UIs, predictable state |

**MVC (Model-View-Controller):**
```swift
class UserViewController: UIViewController {
    var user: User? {
        didSet { updateUI() }
    }
    
    private func updateUI() {
        nameLabel.text = user?.name
        emailLabel.text = user?.email
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard var user = user else { return }
        user.name = nameTextField.text ?? ""
        userService.save(user)
    }
}
```

**MVVM (Model-View-ViewModel):**
```swift
class UserViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    
    private let userService: UserService
    
    func loadUser(id: String) {
        isLoading = true
        userService.fetchUser(id: id) { [weak self] result in
            self?.isLoading = false
            if case .success(let user) = result {
                self?.name = user.name
                self?.email = user.email
            }
        }
    }
}
```

**MVI (Model-View-Intent):**
```swift
enum UserIntent {
    case loadUser(id: String)
    case updateName(String)
    case save
}

struct UserState {
    var user: User?
    var isLoading: Bool
    var error: String?
}

class UserStore {
    @Published private(set) var state = UserState(user: nil, isLoading: false, error: nil)
    
    func dispatch(_ intent: UserIntent) {
        switch intent {
        case .loadUser(let id):
            state.isLoading = true
            // fetch and update state
        case .updateName(let name):
            state.user?.name = name
        case .save:
            // save logic
        }
    }
}
```

---

### Q: How would you implement a modular architecture in a large mobile app?

**Difficulty:** 🔴 Senior

Modular architecture splits the app into independent feature modules with clear boundaries.

**Module Structure:**
```
App/
├── Core/
│   ├── Networking/
│   ├── Storage/
│   ├── Analytics/
│   └── DesignSystem/
├── Features/
│   ├── Authentication/
│   ├── Home/
│   ├── Profile/
│   ├── Settings/
│   └── Chat/
└── App/ (composition root)
```

**Module Dependencies:**
```
┌──────────────┐     ┌──────────────┐
│   Feature A  │     │   Feature B  │
└──────┬───────┘     └──────┬───────┘
       │                    │
       ▼                    ▼
┌──────────────────────────────────┐
│           Core Module            │
└──────────────────────────────────┘
```

**Key considerations:**

1. **Interface Modules** - Define protocols for cross-module communication
2. **Dependency Injection** - Use a DI container for module assembly
3. **Navigation** - Coordinator pattern for decoupled navigation
4. **Shared Resources** - Design system and common utilities in Core

```swift
// Feature Interface
public protocol AuthenticationInterface {
    func isAuthenticated() -> Bool
    func presentLogin(from: UIViewController, completion: @escaping (Bool) -> Void)
}

// Feature Implementation (in separate module)
public class AuthenticationModule: AuthenticationInterface {
    public func isAuthenticated() -> Bool {
        return tokenStorage.hasValidToken()
    }
    
    public func presentLogin(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let loginVC = LoginViewController()
        loginVC.onComplete = completion
        viewController.present(loginVC, animated: true)
    }
}
```

---

## Networking & API Design

### Q: Design a robust networking layer for a mobile app. What components would you include?

**Difficulty:** 🔴 Senior

A production-ready networking layer needs multiple components working together.

**Architecture:**
```
┌───────────────────────────────────────────┐
│              API Client                    │
├───────────────────────────────────────────┤
│  Request Builder │ Response Parser        │
├───────────────────────────────────────────┤
│  Auth Interceptor │ Retry Handler         │
├───────────────────────────────────────────┤
│  Cache Layer │ Connectivity Monitor       │
├───────────────────────────────────────────┤
│           URLSession / HTTP Client        │
└───────────────────────────────────────────┘
```

```swift
protocol APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: Encodable?
    let queryItems: [URLQueryItem]
    let cachePolicy: CachePolicy
    let retryPolicy: RetryPolicy
}

class NetworkClient: APIClient {
    private let session: URLSession
    private let authInterceptor: AuthInterceptor
    private let retryHandler: RetryHandler
    private let cache: ResponseCache
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Check cache first
        if let cached: T = cache.get(for: endpoint) {
            return cached
        }
        
        var request = try buildRequest(from: endpoint)
        request = authInterceptor.intercept(request)
        
        let (data, response) = try await retryHandler.execute {
            try await session.data(for: request)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        try validate(httpResponse)
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        cache.store(decoded, for: endpoint)
        
        return decoded
    }
}
```

---

### Q: How would you handle authentication token refresh in a mobile app?

**Difficulty:** 🟡 Mid

Token refresh needs to handle concurrent requests and prevent race conditions.

```swift
actor TokenManager {
    private var accessToken: String?
    private var refreshToken: String?
    private var refreshTask: Task<String, Error>?
    
    func getValidToken() async throws -> String {
        // Return existing valid token
        if let token = accessToken, !isExpired(token) {
            return token
        }
        
        // If refresh already in progress, wait for it
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        // Start new refresh
        let task = Task { () -> String in
            defer { refreshTask = nil }
            return try await performRefresh()
        }
        
        refreshTask = task
        return try await task.value
    }
    
    private func performRefresh() async throws -> String {
        guard let refresh = refreshToken else {
            throw AuthError.noRefreshToken
        }
        
        let response = try await authService.refreshToken(refresh)
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        
        return response.accessToken
    }
}

class AuthInterceptor {
    private let tokenManager: TokenManager
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var mutableRequest = request
        let token = try await tokenManager.getValidToken()
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }
}
```

---

### Q: Design a request queue for handling API calls when the app is offline.

**Difficulty:** 🔴 Senior

An offline queue stores requests and syncs them when connectivity returns.

```swift
struct QueuedRequest: Codable {
    let id: UUID
    let endpoint: String
    let method: String
    let body: Data?
    let headers: [String: String]
    let createdAt: Date
    let priority: Int
    let maxRetries: Int
    var retryCount: Int
}

actor OfflineRequestQueue {
    private var queue: [QueuedRequest] = []
    private let storage: QueueStorage
    private let networkMonitor: NetworkMonitor
    
    init(storage: QueueStorage, networkMonitor: NetworkMonitor) {
        self.storage = storage
        self.networkMonitor = networkMonitor
        Task { await loadPersistedQueue() }
        observeConnectivity()
    }
    
    func enqueue(_ request: QueuedRequest) async {
        queue.append(request)
        queue.sort { $0.priority > $1.priority }
        await storage.save(queue)
    }
    
    func processQueue() async {
        guard networkMonitor.isConnected else { return }
        
        while let request = queue.first {
            do {
                try await executeRequest(request)
                queue.removeFirst()
                await storage.save(queue)
            } catch {
                if request.retryCount >= request.maxRetries {
                    queue.removeFirst()
                    await handleFailedRequest(request, error: error)
                } else {
                    queue[0].retryCount += 1
                    try? await Task.sleep(nanoseconds: exponentialBackoff(request.retryCount))
                }
            }
        }
    }
    
    private func observeConnectivity() {
        networkMonitor.onConnected = { [weak self] in
            Task { await self?.processQueue() }
        }
    }
}
```

---

## Data Persistence

### Q: Compare different local storage options for mobile apps. When would you use each?

**Difficulty:** 🟡 Mid

| Storage Type | Use Case | Pros | Cons |
|--------------|----------|------|------|
| UserDefaults | Small preferences | Simple, fast | Limited types, no queries |
| Keychain | Sensitive data | Secure, persists reinstall | Complex API, slow |
| File System | Documents, media | Flexible, large files | Manual serialization |
| Core Data | Complex object graphs | Powerful, relationships | Steep learning curve |
| SQLite | Structured queries | Fast, portable | SQL knowledge required |
| Realm | Real-time sync | Easy, reactive | Vendor lock-in |

**Decision Tree:**
```
Is it sensitive (tokens, passwords)?
  └─ Yes → Keychain
  └─ No → Continue

Is it a small preference/setting?
  └─ Yes → UserDefaults
  └─ No → Continue

Is it a large file (image, video)?
  └─ Yes → File System
  └─ No → Continue

Do you need complex queries/relationships?
  └─ Yes → Core Data or SQLite
  └─ No → File System with Codable
```

---

### Q: How would you design a caching strategy for a social media app?

**Difficulty:** 🔴 Senior

A social media app needs multi-level caching with different TTLs per content type.

```swift
enum CachePolicy {
    case networkOnly
    case cacheFirst(maxAge: TimeInterval)
    case cacheAndNetwork
    case staleWhileRevalidate(maxAge: TimeInterval)
}

struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let etag: String?
    
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

class MultiLevelCache {
    private let memoryCache = NSCache<NSString, AnyObject>()
    private let diskCache: DiskCache
    
    func get<T: Codable>(key: String, maxAge: TimeInterval) async -> CacheResult<T> {
        // Level 1: Memory
        if let entry = memoryCache.object(forKey: key as NSString) as? CacheEntry<T> {
            if entry.age < maxAge {
                return .hit(entry.data)
            }
            return .stale(entry.data, entry.etag)
        }
        
        // Level 2: Disk
        if let entry: CacheEntry<T> = await diskCache.read(key: key) {
            memoryCache.setObject(entry as AnyObject, forKey: key as NSString)
            if entry.age < maxAge {
                return .hit(entry.data)
            }
            return .stale(entry.data, entry.etag)
        }
        
        return .miss
    }
    
    func set<T: Codable>(_ value: T, key: String, etag: String?) async {
        let entry = CacheEntry(data: value, timestamp: Date(), etag: etag)
        memoryCache.setObject(entry as AnyObject, forKey: key as NSString)
        await diskCache.write(entry, key: key)
    }
}

// Cache TTL by content type
extension CachePolicy {
    static var userProfile: CachePolicy { .cacheFirst(maxAge: 300) }         // 5 min
    static var feedPost: CachePolicy { .staleWhileRevalidate(maxAge: 60) }   // 1 min
    static var staticContent: CachePolicy { .cacheFirst(maxAge: 86400) }     // 24 hours
    static var notifications: CachePolicy { .networkOnly }
}
```

---

## Offline-First Architecture

### Q: Design an offline-first mobile application. What are the key considerations?

**Difficulty:** 🔴 Senior

Offline-first means the app works fully offline and syncs when connected.

**Core Principles:**

1. **Local First** - All data operations hit local DB first
2. **Background Sync** - Sync happens transparently
3. **Conflict Resolution** - Handle concurrent changes
4. **Optimistic Updates** - UI updates immediately

```swift
// Sync Status Tracking
enum SyncStatus {
    case synced
    case pending
    case failed(Error)
    case conflict
}

struct SyncableEntity {
    let localId: UUID
    var serverId: String?
    var data: Data
    var localVersion: Int
    var serverVersion: Int?
    var syncStatus: SyncStatus
    var modifiedAt: Date
}

protocol OfflineRepository {
    associatedtype Entity
    
    // Local operations (always available)
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(_ entity: Entity) async throws
    func fetch(id: String) async throws -> Entity?
    func fetchAll() async throws -> [Entity]
    
    // Sync operations
    func sync() async throws
    func resolveConflict(_ local: Entity, _ remote: Entity) async throws -> Entity
}

class OfflineFirstRepository<T: Syncable>: OfflineRepository {
    private let localStore: LocalStore<T>
    private let remoteAPI: RemoteAPI<T>
    private let syncEngine: SyncEngine
    
    func create(_ entity: T) async throws -> T {
        // Save locally first
        var localEntity = entity
        localEntity.syncStatus = .pending
        try await localStore.save(localEntity)
        
        // Trigger background sync
        syncEngine.schedulSync()
        
        return localEntity
    }
    
    func sync() async throws {
        let pendingChanges = try await localStore.fetchPending()
        
        for change in pendingChanges {
            do {
                let remote = try await remoteAPI.push(change)
                var updated = change
                updated.serverId = remote.id
                updated.serverVersion = remote.version
                updated.syncStatus = .synced
                try await localStore.save(updated)
            } catch let error as ConflictError {
                try await handleConflict(local: change, remote: error.serverVersion)
            }
        }
        
        // Pull remote changes
        let remoteChanges = try await remoteAPI.fetchChanges(since: lastSyncTimestamp)
        try await mergeRemoteChanges(remoteChanges)
    }
}
```

---

### Q: How do you handle data conflicts in an offline-first app?

**Difficulty:** 🔴 Senior

Conflict resolution strategies depend on the data type and business rules.

**Common Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| Last Write Wins | Latest timestamp wins | Simple, low-value data |
| First Write Wins | Original change preserved | Reservations, bookings |
| Server Wins | Server always authoritative | Admin-controlled data |
| Client Wins | Client always wins | Draft/local documents |
| Manual Resolution | User decides | Critical data, documents |
| Merge | Combine changes | Collaborative editing |

```swift
enum ConflictResolution {
    case lastWriteWins
    case serverWins
    case clientWins
    case manual
    case merge((local: Entity, remote: Entity) -> Entity)
}

class ConflictResolver<T: Mergeable> {
    func resolve(local: T, remote: T, strategy: ConflictResolution) -> T {
        switch strategy {
        case .lastWriteWins:
            return local.modifiedAt > remote.modifiedAt ? local : remote
            
        case .serverWins:
            return remote
            
        case .clientWins:
            return local
            
        case .manual:
            // Store both versions, let user decide
            return T.conflicted(local: local, remote: remote)
            
        case .merge(let merger):
            return merger(local, remote)
        }
    }
}

// Field-level merge for complex objects
struct Document: Mergeable {
    var title: String
    var content: String
    var tags: [String]
    var modifiedAt: Date
    
    static func merge(local: Document, remote: Document) -> Document {
        // Merge strategy: take latest for each field
        return Document(
            title: local.modifiedAt > remote.modifiedAt ? local.title : remote.title,
            content: mergeText(local.content, remote.content),
            tags: Array(Set(local.tags + remote.tags)),  // Union of tags
            modifiedAt: max(local.modifiedAt, remote.modifiedAt)
        )
    }
}
```

---

## Real-Time Systems

### Q: Design a real-time chat system for a mobile app.

**Difficulty:** 🔴 Senior

Real-time chat requires persistent connections, message queuing, and sync.

**Architecture:**
```
┌─────────┐     WebSocket      ┌─────────────┐
│  App    │◄──────────────────►│   Gateway   │
└────┬────┘                    └──────┬──────┘
     │                                │
     │ Local DB                       │ Message Queue
     ▼                                ▼
┌─────────┐                    ┌─────────────┐
│ SQLite  │                    │   Redis     │
└─────────┘                    └──────┬──────┘
                                      │
                                      ▼
                               ┌─────────────┐
                               │   MongoDB   │
                               └─────────────┘
```

```swift
class ChatManager {
    private let socketClient: WebSocketClient
    private let messageStore: MessageStore
    private let syncManager: SyncManager
    
    @Published var connectionState: ConnectionState = .disconnected
    
    func connect(userId: String, token: String) {
        socketClient.connect(
            url: "wss://chat.example.com/ws",
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        socketClient.onConnected = { [weak self] in
            self?.connectionState = .connected
            self?.syncPendingMessages()
        }
        
        socketClient.onMessage = { [weak self] data in
            self?.handleIncomingMessage(data)
        }
        
        socketClient.onDisconnected = { [weak self] in
            self?.connectionState = .disconnected
            self?.scheduleReconnect()
        }
    }
    
    func sendMessage(_ message: Message) async {
        // Save locally first (optimistic)
        var localMessage = message
        localMessage.status = .sending
        await messageStore.save(localMessage)
        
        if connectionState == .connected {
            do {
                try await socketClient.send(message.toJSON())
                localMessage.status = .sent
            } catch {
                localMessage.status = .failed
            }
        } else {
            localMessage.status = .pending
        }
        
        await messageStore.save(localMessage)
    }
    
    private func handleIncomingMessage(_ data: Data) {
        guard let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) else { return }
        
        switch envelope.type {
        case .message:
            let message = envelope.payload as! Message
            Task { await messageStore.save(message) }
            sendDeliveryReceipt(for: message)
            
        case .receipt:
            let receipt = envelope.payload as! DeliveryReceipt
            Task { await messageStore.updateStatus(receipt.messageId, status: receipt.status) }
            
        case .typing:
            NotificationCenter.default.post(name: .userTyping, object: envelope.payload)
        }
    }
}
```

---

### Q: How would you implement presence (online/offline status) in a mobile app?

**Difficulty:** 🟡 Mid

Presence systems track user online status with heartbeats and timeouts.

```swift
class PresenceManager {
    private let socketClient: WebSocketClient
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30
    
    @Published var onlineUsers: Set<String> = []
    
    func startPresence(userId: String) {
        // Send initial presence
        sendPresence(status: .online)
        
        // Start heartbeat
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
        
        // Listen for presence updates
        socketClient.subscribe(channel: "presence") { [weak self] data in
            self?.handlePresenceUpdate(data)
        }
        
        // Handle app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func sendPresence(status: PresenceStatus) {
        let presence = Presence(
            userId: currentUserId,
            status: status,
            lastSeen: Date()
        )
        socketClient.send(presence.toJSON())
    }
    
    @objc private func appDidEnterBackground() {
        sendPresence(status: .away)
        heartbeatTimer?.invalidate()
    }
}

// Server-side presence tracking
struct PresenceService {
    private let redis: Redis
    private let presenceTimeout: TimeInterval = 60
    
    func setOnline(userId: String) async {
        await redis.setex("presence:\(userId)", seconds: Int(presenceTimeout), value: "online")
        await redis.publish("presence", message: "\(userId):online")
    }
    
    func heartbeat(userId: String) async {
        await redis.expire("presence:\(userId)", seconds: Int(presenceTimeout))
    }
    
    func isOnline(userId: String) async -> Bool {
        return await redis.exists("presence:\(userId)")
    }
}
```

---

## Media Handling

### Q: Design an image loading and caching system for a social media feed.

**Difficulty:** 🔴 Senior

Efficient image loading requires multiple cache levels, prefetching, and memory management.

```swift
class ImageLoader {
    static let shared = ImageLoader()
    
    private let memoryCache = NSCache<NSURL, UIImage>()
    private let diskCache: DiskCache
    private let downloadQueue = OperationQueue()
    private var runningTasks: [URL: Task<UIImage, Error>] = [:]
    
    init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        downloadQueue.maxConcurrentOperationCount = 6
    }
    
    func loadImage(url: URL, size: CGSize? = nil) async throws -> UIImage {
        let cacheKey = cacheKey(url: url, size: size)
        
        // Level 1: Memory cache
        if let cached = memoryCache.object(forKey: cacheKey as NSURL) {
            return cached
        }
        
        // Level 2: Disk cache
        if let diskImage = await diskCache.image(for: cacheKey) {
            let processed = size != nil ? diskImage.resized(to: size!) : diskImage
            memoryCache.setObject(processed, forKey: cacheKey as NSURL, cost: processed.memoryCost)
            return processed
        }
        
        // Dedupe concurrent requests for same URL
        if let existingTask = runningTasks[url] {
            return try await existingTask.value
        }
        
        let task = Task { () -> UIImage in
            defer { runningTasks[url] = nil }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                throw ImageError.decodingFailed
            }
            
            // Save original to disk
            await diskCache.save(image, for: url.absoluteString)
            
            // Process for requested size
            let processed = size != nil ? image.resized(to: size!) : image
            memoryCache.setObject(processed, forKey: cacheKey as NSURL, cost: processed.memoryCost)
            
            return processed
        }
        
        runningTasks[url] = task
        return try await task.value
    }
    
    func prefetch(urls: [URL]) {
        for url in urls {
            Task(priority: .low) {
                _ = try? await loadImage(url: url)
            }
        }
    }
    
    func cancelPrefetch(urls: [URL]) {
        for url in urls {
            runningTasks[url]?.cancel()
            runningTasks[url] = nil
        }
    }
}

// UICollectionView integration
class FeedViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { posts[$0.item].imageURL }
        ImageLoader.shared.prefetch(urls: urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { posts[$0.item].imageURL }
        ImageLoader.shared.cancelPrefetch(urls: urls)
    }
}
```

---

### Q: How would you design a video upload system with resume capability?

**Difficulty:** 🔴 Senior

Resumable uploads use chunked transfer and server-side chunk tracking.

```swift
struct UploadSession {
    let id: UUID
    let fileURL: URL
    let fileSize: Int64
    let chunkSize: Int = 1024 * 1024  // 1MB chunks
    var uploadedChunks: Set<Int>
    var status: UploadStatus
    
    var progress: Double {
        Double(uploadedChunks.count * chunkSize) / Double(fileSize)
    }
    
    var totalChunks: Int {
        Int(ceil(Double(fileSize) / Double(chunkSize)))
    }
}

class ResumableUploader {
    private var activeSessions: [UUID: UploadSession] = [:]
    private let storage: UploadSessionStorage
    
    func upload(fileURL: URL) async throws -> String {
        let session = try await createOrResumeSession(for: fileURL)
        
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }
        
        for chunkIndex in 0..<session.totalChunks {
            // Skip already uploaded chunks
            if session.uploadedChunks.contains(chunkIndex) {
                continue
            }
            
            let offset = UInt64(chunkIndex * session.chunkSize)
            try fileHandle.seek(toOffset: offset)
            
            let chunkData = fileHandle.readData(ofLength: session.chunkSize)
            
            try await uploadChunk(
                sessionId: session.id,
                chunkIndex: chunkIndex,
                data: chunkData,
                isLast: chunkIndex == session.totalChunks - 1
            )
            
            activeSessions[session.id]?.uploadedChunks.insert(chunkIndex)
            await storage.save(activeSessions[session.id]!)
            
            NotificationCenter.default.post(
                name: .uploadProgress,
                object: nil,
                userInfo: ["sessionId": session.id, "progress": session.progress]
            )
        }
        
        let result = try await finalizeUpload(sessionId: session.id)
        await storage.delete(session.id)
        
        return result.videoId
    }
    
    private func uploadChunk(sessionId: UUID, chunkIndex: Int, data: Data, isLast: Bool) async throws {
        var request = URLRequest(url: URL(string: "https://api.example.com/upload/\(sessionId)/chunk")!)
        request.httpMethod = "PUT"
        request.setValue("\(chunkIndex)", forHTTPHeaderField: "X-Chunk-Index")
        request.setValue(isLast ? "true" : "false", forHTTPHeaderField: "X-Last-Chunk")
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UploadError.chunkFailed(chunkIndex)
        }
    }
}
```

---

## Performance & Scalability

### Q: How would you optimize a mobile app for low-end devices?

**Difficulty:** 🟡 Mid

Optimization strategies for resource-constrained devices:

| Area | Strategy | Implementation |
|------|----------|----------------|
| Memory | Aggressive caching limits | Lower NSCache limits |
| Images | More aggressive downsampling | Smaller thumbnail sizes |
| Animations | Reduce complexity | Disable parallax, shadows |
| Network | Batch requests | Combine API calls |
| Storage | Limit cache size | Smaller disk cache quota |

```swift
class DeviceProfile {
    static let shared = DeviceProfile()
    
    enum Tier {
        case low, mid, high
    }
    
    var tier: Tier {
        let memory = ProcessInfo.processInfo.physicalMemory
        let processors = ProcessInfo.processInfo.processorCount
        
        if memory < 2 * 1024 * 1024 * 1024 || processors < 4 {
            return .low
        } else if memory < 4 * 1024 * 1024 * 1024 || processors < 6 {
            return .mid
        }
        return .high
    }
    
    var imageCacheLimit: Int {
        switch tier {
        case .low: return 50 * 1024 * 1024   // 50MB
        case .mid: return 100 * 1024 * 1024  // 100MB
        case .high: return 200 * 1024 * 1024 // 200MB
        }
    }
    
    var maxImageSize: CGSize {
        switch tier {
        case .low: return CGSize(width: 200, height: 200)
        case .mid: return CGSize(width: 400, height: 400)
        case .high: return CGSize(width: 800, height: 800)
        }
    }
    
    var animationsEnabled: Bool {
        tier != .low
    }
    
    var prefetchDistance: Int {
        switch tier {
        case .low: return 2
        case .mid: return 5
        case .high: return 10
        }
    }
}

// Usage
func configureForDevice() {
    let profile = DeviceProfile.shared
    
    ImageLoader.shared.cacheLimit = profile.imageCacheLimit
    UIView.setAnimationsEnabled(profile.animationsEnabled)
    collectionView.prefetchDataSource = profile.tier == .low ? nil : self
}
```

---

### Q: Design a pagination system for an infinite scroll feed.

**Difficulty:** 🟡 Mid

Efficient pagination needs cursor-based loading and proper state management.

```swift
enum PaginationState {
    case idle
    case loading
    case loaded(hasMore: Bool)
    case error(Error)
}

class PaginatedDataSource<T: Identifiable> {
    @Published private(set) var items: [T] = []
    @Published private(set) var state: PaginationState = .idle
    
    private var cursor: String?
    private let pageSize: Int = 20
    private let fetchHandler: (String?, Int) async throws -> (items: [T], nextCursor: String?)
    
    init(fetchHandler: @escaping (String?, Int) async throws -> (items: [T], nextCursor: String?)) {
        self.fetchHandler = fetchHandler
    }
    
    func loadInitial() async {
        guard case .idle = state else { return }
        
        state = .loading
        cursor = nil
        
        do {
            let result = try await fetchHandler(nil, pageSize)
            items = result.items
            cursor = result.nextCursor
            state = .loaded(hasMore: result.nextCursor != nil)
        } catch {
            state = .error(error)
        }
    }
    
    func loadMore() async {
        guard case .loaded(hasMore: true) = state else { return }
        
        state = .loading
        
        do {
            let result = try await fetchHandler(cursor, pageSize)
            items.append(contentsOf: result.items)
            cursor = result.nextCursor
            state = .loaded(hasMore: result.nextCursor != nil)
        } catch {
            state = .error(error)
        }
    }
    
    func refresh() async {
        state = .idle
        await loadInitial()
    }
}

// UICollectionView integration
class FeedViewController: UICollectionViewController {
    private let dataSource = PaginatedDataSource<Post> { cursor, limit in
        return try await PostAPI.fetchFeed(cursor: cursor, limit: limit)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Trigger load more when near the end
        if indexPath.item >= dataSource.items.count - 5 {
            Task { await dataSource.loadMore() }
        }
    }
}
```

---

## Security Design

### Q: How would you securely store sensitive data in a mobile app?

**Difficulty:** 🟡 Mid

Sensitive data requires proper encryption and secure storage.

```swift
class SecureStorage {
    private let keychain = KeychainWrapper()
    
    // Store sensitive tokens
    func storeToken(_ token: String, for key: String) throws {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // Retrieve with biometric protection
    func retrieveWithBiometrics(_ key: String) async throws -> String {
        let context = LAContext()
        context.localizedReason = "Authenticate to access secure data"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }
        
        return String(data: data, encoding: .utf8)!
    }
}

// Encrypted local database
class EncryptedDatabase {
    private let encryptionKey: SymmetricKey
    
    init() throws {
        // Derive key from device-specific secret stored in Keychain
        let secret = try SecureStorage().retrieveSecret("db_key")
        encryptionKey = SymmetricKey(data: SHA256.hash(data: secret))
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
}
```

---

### Q: Design certificate pinning for a mobile app. How do you handle certificate rotation?

**Difficulty:** 🔴 Senior

Certificate pinning prevents MITM attacks but needs rotation handling.

```swift
class CertificatePinner: NSObject, URLSessionDelegate {
    private var pinnedCertificates: [String: [Data]] = [:]
    private let backupPins: [String: [Data]]  // For rotation
    
    init(configuration: PinningConfiguration) {
        for (host, pins) in configuration.pins {
            pinnedCertificates[host] = pins.compactMap { Self.loadCertificate($0) }
        }
        backupPins = configuration.backupPins.mapValues { pins in
            pins.compactMap { Self.loadCertificate($0) }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get server certificate
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertData = SecCertificateCopyData(serverCertificate) as Data
        
        // Check against pinned certificates
        let allPins = (pinnedCertificates[host] ?? []) + (backupPins[host] ?? [])
        
        if allPins.contains(serverCertData) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Report pinning failure for monitoring
            reportPinningFailure(host: host, certificate: serverCertData)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// Remote pinning configuration for rotation
struct PinningConfiguration: Codable {
    let pins: [String: [String]]          // host -> certificate hashes
    let backupPins: [String: [String]]    // for rotation
    let expirationDate: Date
    let minimumAppVersion: String
}

class DynamicPinningManager {
    private var configuration: PinningConfiguration
    
    func updatePinsIfNeeded() async {
        // Fetch new pins from a trusted source (with separate pinning)
        let newConfig = try? await fetchPinningConfiguration()
        
        if let config = newConfig, config.expirationDate > Date() {
            configuration = config
            persistConfiguration(config)
        }
    }
}
```

---

## Case Studies

### Q: Design a ride-sharing app like Uber. What are the key mobile components?

**Difficulty:** 🔴 Senior

**Core Features:**
- Real-time location tracking
- Driver-rider matching
- Live map updates
- Payment processing
- Push notifications

**Architecture:**
```
┌─────────────────────────────────────────────┐
│                Rider App                     │
├─────────────────────────────────────────────┤
│  Map View  │  Booking  │  Payment  │ History│
└─────────┬───────────────────────────────────┘
          │ WebSocket + REST
          ▼
┌─────────────────────────────────────────────┐
│              API Gateway                     │
├─────────────────────────────────────────────┤
│  Auth  │  Matching  │  Pricing  │  Tracking │
└─────────────────────────────────────────────┘
```

**Key Mobile Components:**

```swift
// Real-time location updates
class LocationManager {
    private let locationManager = CLLocationManager()
    private let socketClient: WebSocketClient
    private var updateTimer: Timer?
    
    func startTracking(rideId: String) {
        locationManager.startUpdatingLocation()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let location = self?.locationManager.location else { return }
            
            let update = LocationUpdate(
                rideId: rideId,
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                heading: location.course,
                speed: location.speed,
                timestamp: Date()
            )
            
            self?.socketClient.send(update.toJSON())
        }
    }
}

// ETA calculation
class ETACalculator {
    func calculateETA(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        let response = try? await directions.calculate()
        
        return response?.routes.first?.expectedTravelTime ?? 0
    }
}
```

---

### Q: Design a social media feed like Instagram. Focus on the mobile architecture.

**Difficulty:** 🔴 Senior

**Key Challenges:**
- Infinite scroll performance
- Image/video loading optimization
- Real-time updates
- Offline support

```swift
// Feed architecture
class FeedViewModel {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    
    private let feedRepository: FeedRepository
    private let prefetcher: MediaPrefetcher
    private var cursor: String?
    
    func loadFeed() async {
        isLoading = true
        
        // Load from cache first
        if let cached = await feedRepository.getCachedFeed() {
            posts = cached
            isLoading = false
        }
        
        // Fetch fresh data
        do {
            let result = try await feedRepository.fetchFeed(cursor: nil)
            posts = result.posts
            cursor = result.nextCursor
            prefetcher.prefetch(posts: Array(posts.prefix(10)))
        } catch {
            // Keep showing cached data
        }
        
        isLoading = false
    }
}

// Optimized cell rendering
class PostCell: UICollectionViewCell {
    private var imageTask: Task<Void, Never>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageView.image = nil
    }
    
    func configure(with post: Post) {
        usernameLabel.text = post.username
        captionLabel.text = post.caption
        
        imageTask = Task {
            let image = try? await ImageLoader.shared.loadImage(
                url: post.imageURL,
                size: CGSize(width: bounds.width, height: bounds.width)
            )
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.imageView.image = image
            }
        }
    }
}
```

---

## Quick Reference

### System Design Interview Framework

1. **Clarify Requirements** (2-3 min)
   - Functional requirements
   - Non-functional requirements (scale, latency)
   - Platform constraints

2. **High-Level Design** (5-7 min)
   - Architecture diagram
   - Major components
   - Data flow

3. **Deep Dive** (10-15 min)
   - Core algorithms
   - Data models
   - API design

4. **Tradeoffs & Optimizations** (5 min)
   - Performance considerations
   - Scaling strategies
   - Edge cases

### Common Mobile System Design Topics

| Topic | Key Considerations |
|-------|-------------------|
| Feed/Timeline | Pagination, caching, prefetching |
| Chat | WebSocket, offline queue, sync |
| Media Upload | Chunked upload, resume, compression |
| Maps/Location | Battery, accuracy, background updates |
| Payments | Security, tokenization, error handling |
| Notifications | Push vs pull, batching, priority |
| Search | Autocomplete, debounce, caching |
| Auth | Token refresh, biometrics, session management |

---

*Last updated: February 2025*
