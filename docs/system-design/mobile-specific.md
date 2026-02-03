# Mobile-Specific System Design Interview Questions

Comprehensive guide to designing systems optimized for mobile platforms.

---

## Table of Contents

1. [Mobile Architecture Fundamentals](#mobile-architecture-fundamentals)
2. [Offline-First Design](#offline-first-design)
3. [Network Optimization](#network-optimization)
4. [Battery & Performance](#battery--performance)
5. [Push Notifications](#push-notifications)
6. [Real-Time Features](#real-time-features)
7. [Security Architecture](#security-architecture)
8. [Data Synchronization](#data-synchronization)
9. [Media Handling](#media-handling)
10. [Analytics & Monitoring](#analytics--monitoring)

---

## Mobile Architecture Fundamentals

### Q1: What are the unique constraints when designing for mobile?

**Answer:**

| Constraint | Impact | Design Consideration |
|------------|--------|---------------------|
| Limited Battery | Background work drains battery | Batch operations, minimize wake-ups |
| Unreliable Network | Intermittent connectivity | Offline support, retry logic |
| Limited Memory | App killed when low memory | Efficient data structures, pagination |
| Variable Bandwidth | 3G to WiFi transitions | Adaptive quality, compression |
| Screen Real Estate | Small viewport | Progressive disclosure, prioritization |
| App Store Rules | Review process delays | Feature flags, remote config |
| Device Fragmentation | Multiple screen sizes/OS versions | Responsive design, graceful degradation |

**Architecture principles:**

```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile Client                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │     UI      │  │   Domain    │  │    Data     │        │
│  │   Layer     │  │   Layer     │  │   Layer     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌─────────────────────────────────────────────────┐      │
│  │            Local Storage / Cache                 │      │
│  │   (SQLite, Core Data, Realm, UserDefaults)      │      │
│  └─────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                             │
│  (Authentication, Rate Limiting, Request Routing)           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Backend Services                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │  Auth   │  │  User   │  │ Content │  │  Push   │       │
│  │ Service │  │ Service │  │ Service │  │ Service │       │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

### Q2: Design a mobile app architecture that supports 10M+ DAU

**Answer:**

**Requirements Analysis:**
- 10M DAU = ~7,000 requests/second average
- Peak traffic = 3-5x average
- Global user base
- Real-time features (messaging, feeds)

**Client Architecture:**

```swift
// Clean Architecture layers
app/
├── Presentation/          // UI, ViewModels
│   ├── Features/
│   │   ├── Feed/
│   │   ├── Profile/
│   │   └── Messaging/
│   └── Common/
├── Domain/               // Business logic, Use cases
│   ├── UseCases/
│   ├── Entities/
│   └── Repositories/     // Protocols
├── Data/                 // Implementation
│   ├── Network/
│   ├── Database/
│   ├── Cache/
│   └── Repositories/     // Implementations
└── Infrastructure/       // Utilities, DI
```

**Backend Architecture:**

```
                         ┌─────────────┐
                         │     CDN     │
                         │ (CloudFront)│
                         └──────┬──────┘
                                │
                         ┌──────▼──────┐
                         │   AWS ALB   │
                         └──────┬──────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
    ┌──────▼──────┐     ┌──────▼──────┐     ┌──────▼──────┐
    │ API Gateway │     │ WebSocket   │     │   GraphQL   │
    │  (REST)     │     │   Server    │     │   Server    │
    └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
           │                    │                    │
           └────────────────────┼────────────────────┘
                                │
                         ┌──────▼──────┐
                         │   Service   │
                         │    Mesh     │
                         └──────┬──────┘
                                │
     ┌──────────┬───────────────┼───────────────┬──────────┐
     │          │               │               │          │
┌────▼────┐ ┌───▼───┐    ┌─────▼─────┐   ┌────▼────┐ ┌───▼───┐
│  Auth   │ │ User  │    │   Feed    │   │ Message │ │ Push  │
│ Service │ │Service│    │  Service  │   │ Service │ │Service│
└────┬────┘ └───┬───┘    └─────┬─────┘   └────┬────┘ └───┬───┘
     │          │              │              │          │
     └──────────┴──────────────┼──────────────┴──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       ┌──────▼──────┐  ┌─────▼─────┐  ┌──────▼──────┐
       │  PostgreSQL │  │   Redis   │  │ Elasticsearch│
       │  (Primary)  │  │  Cluster  │  │             │
       └─────────────┘  └───────────┘  └─────────────┘
```

**Scaling strategies:**

1. **Horizontal scaling**: Auto-scaling groups behind load balancer
2. **Database sharding**: Shard by user_id for user data
3. **Caching layers**: Redis for session, CDN for static content
4. **Event-driven**: Kafka for async processing
5. **Regional deployment**: Multi-region for low latency

---

## Offline-First Design

### Q3: Design an offline-first mobile application architecture

**Answer:**

**Core principles:**
1. Local database as source of truth
2. Sync queue for pending changes
3. Conflict resolution strategy
4. Background sync

```swift
// Data flow architecture
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
└──────────────────────────┬──────────────────────────────────┘
                           │ Observes
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Local Database                             │
│              (Source of Truth for UI)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
          ┌────────────────┴────────────────┐
          │                                 │
          ▼                                 ▼
┌─────────────────┐              ┌─────────────────────┐
│   Sync Queue    │              │   Sync Engine       │
│ (Pending Ops)   │◄────────────►│  (Bidirectional)    │
└─────────────────┘              └──────────┬──────────┘
                                            │
                                            ▼
                                 ┌─────────────────────┐
                                 │    Remote Server    │
                                 └─────────────────────┘
```

**Implementation:**

```swift
// Sync operation model
struct SyncOperation: Identifiable, Codable {
    let id: UUID
    let entityType: String
    let entityId: String
    let operationType: OperationType
    let payload: Data
    let createdAt: Date
    var status: SyncStatus
    var retryCount: Int
    
    enum OperationType: String, Codable {
        case create, update, delete
    }
    
    enum SyncStatus: String, Codable {
        case pending, inProgress, completed, failed
    }
}

// Sync manager
actor SyncManager {
    private let localDB: LocalDatabase
    private let api: APIClient
    private let syncQueue: SyncQueue
    
    func performSync() async {
        // 1. Push local changes
        await pushPendingOperations()
        
        // 2. Pull remote changes
        await pullRemoteChanges()
        
        // 3. Resolve conflicts
        await resolveConflicts()
    }
    
    private func pushPendingOperations() async {
        let operations = await syncQueue.getPending()
        
        for operation in operations {
            do {
                try await api.sync(operation)
                await syncQueue.markCompleted(operation.id)
            } catch {
                await syncQueue.incrementRetry(operation.id)
            }
        }
    }
    
    private func pullRemoteChanges() async {
        let lastSyncTimestamp = await localDB.getLastSyncTimestamp()
        
        let changes = try? await api.getChanges(since: lastSyncTimestamp)
        
        for change in changes ?? [] {
            await localDB.apply(change)
        }
    }
}

// Conflict resolution strategies
enum ConflictResolution {
    case serverWins      // Simple, server always wins
    case clientWins      // Client changes take precedence
    case lastWriteWins   // Most recent timestamp wins
    case merge           // Merge changes field by field
    case manual          // User decides
}

struct ConflictResolver {
    func resolve(
        local: Entity,
        remote: Entity,
        strategy: ConflictResolution
    ) -> Entity {
        switch strategy {
        case .serverWins:
            return remote
        case .clientWins:
            return local
        case .lastWriteWins:
            return local.updatedAt > remote.updatedAt ? local : remote
        case .merge:
            return mergeFields(local: local, remote: remote)
        case .manual:
            // Mark for user resolution
            return local.withConflict(remote)
        }
    }
}
```

---

### Q4: How do you handle database migrations in offline-first apps?

**Answer:**

```swift
// Migration system
protocol Migration {
    var version: Int { get }
    func migrate(database: Database) throws
    func rollback(database: Database) throws
}

class MigrationManager {
    private let migrations: [Migration]
    private let database: Database
    
    func migrate(to targetVersion: Int? = nil) throws {
        let currentVersion = database.schemaVersion
        let target = targetVersion ?? migrations.last?.version ?? 0
        
        if currentVersion < target {
            try migrateUp(from: currentVersion, to: target)
        } else if currentVersion > target {
            try migrateDown(from: currentVersion, to: target)
        }
    }
    
    private func migrateUp(from: Int, to: Int) throws {
        let pendingMigrations = migrations.filter {
            $0.version > from && $0.version <= to
        }.sorted { $0.version < $1.version }
        
        for migration in pendingMigrations {
            try database.transaction {
                try migration.migrate(database: database)
                database.schemaVersion = migration.version
            }
        }
    }
}

// Example migration
struct AddUserAvatarMigration: Migration {
    let version = 5
    
    func migrate(database: Database) throws {
        try database.execute("""
            ALTER TABLE users ADD COLUMN avatar_url TEXT;
            CREATE INDEX idx_users_avatar ON users(avatar_url);
        """)
    }
    
    func rollback(database: Database) throws {
        try database.execute("""
            DROP INDEX idx_users_avatar;
            ALTER TABLE users DROP COLUMN avatar_url;
        """)
    }
}

// Data migration with transformation
struct MigrateUserNamesMigration: Migration {
    let version = 6
    
    func migrate(database: Database) throws {
        // Add new columns
        try database.execute("""
            ALTER TABLE users ADD COLUMN first_name TEXT;
            ALTER TABLE users ADD COLUMN last_name TEXT;
        """)
        
        // Transform data
        let users = try database.query("SELECT id, full_name FROM users")
        for user in users {
            let parts = user.fullName.split(separator: " ")
            try database.execute("""
                UPDATE users SET 
                    first_name = ?,
                    last_name = ?
                WHERE id = ?
            """, [parts.first ?? "", parts.dropFirst().joined(separator: " "), user.id])
        }
        
        // Remove old column (SQLite limitation - need to recreate table)
    }
}
```

---

## Network Optimization

### Q5: Design an efficient API strategy for mobile clients

**Answer:**

**API Design Principles:**

```
1. Minimize round trips
2. Reduce payload size
3. Support partial responses
4. Enable efficient caching
5. Handle poor connectivity
```

**GraphQL vs REST decision:**

| Factor | REST | GraphQL |
|--------|------|---------|
| Over-fetching | Common problem | Solved |
| Under-fetching | Multiple requests | Single request |
| Caching | HTTP caching works well | Requires custom caching |
| Learning curve | Lower | Higher |
| File uploads | Native support | Needs workarounds |
| Real-time | Requires WebSocket | Subscriptions built-in |

**Efficient REST API design:**

```swift
// Field selection (sparse fieldsets)
GET /api/users/123?fields=id,name,avatar

// Embedded resources
GET /api/posts?include=author,comments.author

// Pagination
GET /api/feed?cursor=abc123&limit=20

// Compression
Accept-Encoding: gzip, br

// Response
{
    "data": [...],
    "meta": {
        "nextCursor": "xyz789",
        "hasMore": true
    }
}
```

**Request batching:**

```swift
// Batch multiple requests
POST /api/batch
{
    "requests": [
        {"method": "GET", "path": "/users/1"},
        {"method": "GET", "path": "/users/2"},
        {"method": "GET", "path": "/posts/1"}
    ]
}

// Response
{
    "responses": [
        {"status": 200, "body": {...}},
        {"status": 200, "body": {...}},
        {"status": 200, "body": {...}}
    ]
}
```

**Client implementation:**

```swift
class NetworkOptimizer {
    private let requestQueue: [URLRequest] = []
    private var batchTimer: Timer?
    
    func enqueueRequest(_ request: URLRequest) async throws -> Data {
        // Batch requests within a window
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.append((request, continuation))
            scheduleBatch()
        }
    }
    
    private func scheduleBatch() {
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            self?.executeBatch()
        }
    }
    
    private func executeBatch() {
        guard !requestQueue.isEmpty else { return }
        
        let requests = requestQueue
        requestQueue.removeAll()
        
        // Execute batch request
        Task {
            let batchResponse = await performBatchRequest(requests.map(\.0))
            
            for (index, (_, continuation)) in requests.enumerated() {
                continuation.resume(returning: batchResponse.responses[index])
            }
        }
    }
}
```

---

### Q6: How do you implement adaptive quality based on network conditions?

**Answer:**

```swift
// Network quality monitor
class NetworkQualityMonitor {
    private let monitor = NWPathMonitor()
    private var currentQuality: NetworkQuality = .unknown
    
    enum NetworkQuality {
        case unknown
        case poor      // < 150 Kbps
        case moderate  // 150 Kbps - 550 Kbps
        case good      // 550 Kbps - 2 Mbps
        case excellent // > 2 Mbps
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateQuality(for: path)
        }
        monitor.start(queue: .global())
    }
    
    private func updateQuality(for path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            currentQuality = .excellent
        } else if path.usesInterfaceType(.cellular) {
            // Measure actual throughput
            measureThroughput()
        }
    }
    
    private func measureThroughput() {
        // Download small test file and measure speed
        let startTime = CFAbsoluteTimeGetCurrent()
        
        Task {
            let (data, _) = try await URLSession.shared.data(from: testURL)
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let bytesPerSecond = Double(data.count) / elapsed
            
            currentQuality = classifySpeed(bytesPerSecond)
        }
    }
}

// Adaptive image loading
class AdaptiveImageLoader {
    private let networkMonitor: NetworkQualityMonitor
    
    func loadImage(for item: ContentItem) async -> UIImage? {
        let quality = networkMonitor.currentQuality
        let url = selectImageURL(for: item, quality: quality)
        
        return await loadImage(from: url)
    }
    
    private func selectImageURL(
        for item: ContentItem,
        quality: NetworkQuality
    ) -> URL {
        switch quality {
        case .poor:
            return item.thumbnailURL        // 100x100
        case .moderate:
            return item.smallImageURL       // 320x320
        case .good:
            return item.mediumImageURL      // 640x640
        case .excellent, .unknown:
            return item.fullImageURL        // Original
        }
    }
}

// Adaptive video streaming
class AdaptiveVideoPlayer {
    func configureForNetworkQuality(_ quality: NetworkQuality) {
        let preferredBitrate: Double
        let preferredResolution: CGSize
        
        switch quality {
        case .poor:
            preferredBitrate = 400_000      // 400 Kbps
            preferredResolution = CGSize(width: 426, height: 240)
        case .moderate:
            preferredBitrate = 1_000_000    // 1 Mbps
            preferredResolution = CGSize(width: 640, height: 360)
        case .good:
            preferredBitrate = 2_500_000    // 2.5 Mbps
            preferredResolution = CGSize(width: 1280, height: 720)
        case .excellent, .unknown:
            preferredBitrate = 5_000_000    // 5 Mbps
            preferredResolution = CGSize(width: 1920, height: 1080)
        }
        
        player.currentItem?.preferredPeakBitRate = preferredBitrate
        player.currentItem?.preferredMaximumResolution = preferredResolution
    }
}
```

---

## Battery & Performance

### Q7: Design a battery-efficient background task system

**Answer:**

```swift
// Background task categories and strategies
enum BackgroundTaskType {
    case sync           // Data synchronization
    case upload         // File uploads
    case prefetch       // Content prefetching
    case maintenance    // Database cleanup, cache trimming
}

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    func registerTasks() {
        // App refresh - short tasks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.app.refresh",
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Processing - long tasks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.app.processing",
            using: nil
        ) { task in
            self.handleProcessing(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.app.processing")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false // Set true for heavy work
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Schedule next
        
        let operation = SyncOperation()
        
        task.expirationHandler = {
            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        operationQueue.addOperation(operation)
    }
}

// Battery-aware task scheduling
class BatteryAwareScheduler {
    private var batteryLevel: Float {
        UIDevice.current.batteryLevel
    }
    
    private var isCharging: Bool {
        UIDevice.current.batteryState == .charging ||
        UIDevice.current.batteryState == .full
    }
    
    func shouldExecuteTask(_ type: BackgroundTaskType) -> Bool {
        switch type {
        case .sync:
            // Always allow critical sync
            return true
        case .upload:
            // Allow if charging or > 20%
            return isCharging || batteryLevel > 0.2
        case .prefetch:
            // Only if charging or > 50%
            return isCharging || batteryLevel > 0.5
        case .maintenance:
            // Only while charging
            return isCharging
        }
    }
    
    func batchOperationsForEfficiency() {
        // Batch network requests to reduce radio wake-ups
        // Group database writes into transactions
        // Defer non-critical work
    }
}
```

**Location tracking optimization:**

```swift
class EfficientLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var significantChangeMode = false
    
    func configureForUseCase(_ useCase: LocationUseCase) {
        switch useCase {
        case .navigation:
            // High accuracy, continuous updates
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 10
            locationManager.allowsBackgroundLocationUpdates = true
            
        case .geoFencing:
            // Region monitoring (very battery efficient)
            let region = CLCircularRegion(
                center: targetLocation,
                radius: 100,
                identifier: "destination"
            )
            locationManager.startMonitoring(for: region)
            
        case .occasionalUpdates:
            // Significant location changes only
            locationManager.startMonitoringSignificantLocationChanges()
            significantChangeMode = true
            
        case .cityLevel:
            // Low accuracy, infrequent
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.distanceFilter = 1000
        }
    }
}
```

---

### Q8: How do you profile and optimize app launch time?

**Answer:**

```
App Launch Timeline:
┌──────────────────────────────────────────────────────────────┐
│ Process Creation │ dyld Loading │ Runtime Init │ App Init    │
│     (~50ms)      │   (~200ms)   │   (~100ms)   │  (~200ms)   │
└──────────────────────────────────────────────────────────────┘
```

**Optimization strategies:**

```swift
// 1. Reduce dyld loading time
// - Minimize frameworks
// - Use static linking where possible
// - Lazy load optional features

// 2. Defer non-critical initialization
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // CRITICAL: Only essential setup here
        setupAnalytics()  // Need for measuring
        setupCrashReporting()
        
        // DEFER: Non-critical setup
        DispatchQueue.main.async {
            self.deferredSetup()
        }
        
        return true
    }
    
    private func deferredSetup() {
        // After first frame rendered
        setupPushNotifications()
        prefetchData()
        warmCaches()
    }
}

// 3. Optimize initial view hierarchy
struct OptimizedRootView: View {
    @State private var isReady = false
    
    var body: some View {
        Group {
            if isReady {
                MainTabView()  // Full app
            } else {
                LaunchView()   // Lightweight placeholder
            }
        }
        .task {
            await prepareApp()
            isReady = true
        }
    }
}

// 4. Measure with MetricKit
class LaunchMetricsCollector: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            if let launchMetrics = payload.applicationLaunchMetrics {
                // histogrammedTimeToFirstDraw
                // histogrammedResumeTime
                analyzeLaunchMetrics(launchMetrics)
            }
        }
    }
}

// 5. Pre-main optimizations
// In Build Settings:
// - OTHER_LDFLAGS = -Wl,-no_compact_unwind
// - Use DEAD_CODE_STRIPPING = YES
// - Enable Link-Time Optimization
```

**Launch time budget:**

| App Type | Cold Launch Target | Warm Launch Target |
|----------|-------------------|-------------------|
| Simple utility | < 400ms | < 200ms |
| Social app | < 1s | < 400ms |
| Complex app | < 2s | < 500ms |
| Game | < 3s | < 1s |

---

## Push Notifications

### Q9: Design a scalable push notification system

**Answer:**

```
Architecture:
                                    ┌─────────────────┐
                                    │   APNs / FCM    │
                                    └────────▲────────┘
                                             │
┌─────────────┐    ┌─────────────┐    ┌─────┴─────┐
│   Client    │───►│  API Server │───►│   Push    │
│   Action    │    │             │    │  Service  │
└─────────────┘    └─────────────┘    └─────┬─────┘
                                            │
                         ┌──────────────────┼──────────────────┐
                         │                  │                  │
                   ┌─────▼─────┐    ┌──────▼──────┐    ┌─────▼─────┐
                   │   Queue   │    │  Template   │    │  Device   │
                   │ (Kafka)   │    │   Service   │    │  Registry │
                   └───────────┘    └─────────────┘    └───────────┘
```

**Server-side implementation:**

```python
# Push notification service
class PushNotificationService:
    def __init__(self):
        self.apns_client = APNsClient()
        self.fcm_client = FCMClient()
        self.device_registry = DeviceRegistry()
        self.template_service = TemplateService()
    
    async def send_notification(self, notification: Notification):
        # Get target devices
        devices = await self.device_registry.get_devices(
            user_ids=notification.target_users,
            segments=notification.segments
        )
        
        # Render template
        content = await self.template_service.render(
            template_id=notification.template_id,
            variables=notification.variables
        )
        
        # Batch by platform
        ios_devices = [d for d in devices if d.platform == 'ios']
        android_devices = [d for d in devices if d.platform == 'android']
        
        # Send concurrently
        await asyncio.gather(
            self.send_apns_batch(ios_devices, content),
            self.send_fcm_batch(android_devices, content)
        )
    
    async def send_apns_batch(self, devices, content):
        # APNs supports HTTP/2 multiplexing
        # Send up to 1000 concurrent requests
        async with aiohttp.ClientSession() as session:
            tasks = [
                self.send_apns(session, device, content)
                for device in devices
            ]
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Handle failures
            for device, result in zip(devices, results):
                if isinstance(result, Exception):
                    await self.handle_failure(device, result)
```

**Client-side handling:**

```swift
// Rich notification handling
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Handle foreground notification
        let content = notification.request.content
        
        // Update UI if needed
        await updateBadgeCount()
        
        // Decide presentation
        if shouldShowInForeground(content) {
            return [.banner, .sound]
        }
        return []
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        // Track engagement
        await analytics.track("notification_tapped", properties: userInfo)
        
        // Handle action
        switch response.actionIdentifier {
        case "REPLY_ACTION":
            let textResponse = response as? UNTextInputNotificationResponse
            await handleReply(textResponse?.userText)
        case "LIKE_ACTION":
            await handleLike(userInfo)
        default:
            await handleTap(userInfo)
        }
    }
}

// Notification Service Extension for modification
class NotificationServiceExtension: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
        guard let content = bestAttemptContent,
              let imageURLString = content.userInfo["image_url"] as? String,
              let imageURL = URL(string: imageURLString) else {
            contentHandler(request.content)
            return
        }
        
        // Download and attach image
        downloadImage(from: imageURL) { [weak self] attachment in
            if let attachment = attachment {
                content.attachments = [attachment]
            }
            self?.contentHandler?(content)
        }
    }
}
```

---

## Real-Time Features

### Q10: Design a real-time messaging system for mobile

**Answer:**

```
Connection Architecture:
┌─────────────────────────────────────────────────────────────┐
│                      Mobile Client                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Connection Manager                      │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │   │
│  │  │ WebSocket │  │  Fallback │  │   Push    │       │   │
│  │  │  Primary  │  │   HTTP    │  │  Backup   │       │   │
│  │  └───────────┘  └───────────┘  └───────────┘       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    WebSocket Gateway                         │
│  - Connection management                                    │
│  - Authentication                                           │
│  - Message routing                                          │
│  - Presence tracking                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Message Broker                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     Kafka                            │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐         │   │
│  │  │messages- │  │messages- │  │ presence │         │   │
│  │  │  user-A  │  │  user-B  │  │  events  │         │   │
│  │  └──────────┘  └──────────┘  └──────────┘         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Client implementation:**

```swift
actor MessageConnection {
    private var webSocket: URLSessionWebSocketTask?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
    }
    
    private(set) var state: ConnectionState = .disconnected
    
    func connect() async throws {
        state = .connecting
        
        let url = URL(string: "wss://chat.example.com/ws")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        webSocket = URLSession.shared.webSocketTask(with: request)
        webSocket?.resume()
        
        state = .connected
        reconnectAttempts = 0
        
        await receiveMessages()
    }
    
    private func receiveMessages() async {
        guard let webSocket = webSocket else { return }
        
        do {
            while state == .connected {
                let message = try await webSocket.receive()
                await handleMessage(message)
            }
        } catch {
            await handleDisconnection()
        }
    }
    
    private func handleDisconnection() async {
        state = .reconnecting
        
        // Exponential backoff
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30)
        try? await Task.sleep(for: .seconds(delay))
        
        if reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            try? await connect()
        } else {
            state = .disconnected
            // Fall back to push notifications
            await enablePushFallback()
        }
    }
    
    func send(_ message: OutgoingMessage) async throws {
        let data = try JSONEncoder().encode(message)
        try await webSocket?.send(.data(data))
    }
}

// Message synchronization
class MessageSyncManager {
    private let localDB: MessageDatabase
    private let connection: MessageConnection
    
    func syncMessages(for conversationId: String) async {
        // Get local latest
        let localLatest = await localDB.getLatestMessageId(conversationId)
        
        // Fetch missing from server
        let missing = await fetchMissingMessages(
            conversationId: conversationId,
            after: localLatest
        )
        
        // Insert locally
        await localDB.insert(missing)
        
        // Send pending outgoing
        let pending = await localDB.getPendingMessages(conversationId)
        for message in pending {
            try? await connection.send(message)
        }
    }
}
```

---

## Security Architecture

### Q11: Design a secure authentication flow for mobile

**Answer:**

```
OAuth2 + PKCE Flow (Recommended for mobile):
┌─────────┐                              ┌─────────┐
│  Mobile │                              │  Auth   │
│   App   │                              │ Server  │
└────┬────┘                              └────┬────┘
     │                                        │
     │  1. Generate code_verifier (random)    │
     │  2. Create code_challenge = SHA256(verifier)
     │                                        │
     │  3. Authorization Request              │
     │  ──────────────────────────────────────►
     │  (code_challenge, redirect_uri)        │
     │                                        │
     │  4. User authenticates in browser      │
     │  ◄──────────────────────────────────────
     │  (authorization_code via redirect)     │
     │                                        │
     │  5. Token Request                      │
     │  ──────────────────────────────────────►
     │  (authorization_code, code_verifier)   │
     │                                        │
     │  6. Tokens                             │
     │  ◄──────────────────────────────────────
     │  (access_token, refresh_token)         │
     └────────────────────────────────────────┘
```

**Secure token storage:**

```swift
// Keychain wrapper for secure storage
class SecureTokenStorage {
    private let service = "com.app.auth"
    
    func saveToken(_ token: Token) throws {
        let data = try JSONEncoder().encode(token)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStorageError.saveFailed(status)
        }
    }
    
    func getToken() throws -> Token? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(Token.self, from: data)
    }
}

// Token refresh with race condition handling
actor TokenManager {
    private var currentToken: Token?
    private var refreshTask: Task<Token, Error>?
    
    func getValidToken() async throws -> Token {
        if let token = currentToken, !token.isExpired {
            return token
        }
        
        // Prevent multiple simultaneous refreshes
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        let task = Task {
            let newToken = try await refreshToken()
            self.currentToken = newToken
            self.refreshTask = nil
            return newToken
        }
        
        refreshTask = task
        return try await task.value
    }
}
```

**Certificate pinning:**

```swift
// Public key pinning
class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedPublicKeys: [SecKey]
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Verify server certificate chain
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard isValid,
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
              let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Check against pinned keys
        let isPinned = pinnedPublicKeys.contains { pinnedKey in
            let pinnedKeyData = SecKeyCopyExternalRepresentation(pinnedKey, nil)
            let serverKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil)
            return pinnedKeyData == serverKeyData
        }
        
        if isPinned {
            return (.useCredential, URLCredential(trust: serverTrust))
        } else {
            return (.cancelAuthenticationChallenge, nil)
        }
    }
}
```

---

## Data Synchronization

### Q12: Design a conflict-free replicated data type (CRDT) system for collaborative features

**Answer:**

```swift
// Last-Write-Wins Register
struct LWWRegister<T: Codable>: Codable {
    private(set) var value: T
    private(set) var timestamp: TimeInterval
    private(set) var nodeId: String
    
    mutating func set(_ newValue: T, at time: TimeInterval, by node: String) {
        if time > timestamp || (time == timestamp && node > nodeId) {
            value = newValue
            timestamp = time
            nodeId = node
        }
    }
    
    func merge(with other: LWWRegister<T>) -> LWWRegister<T> {
        if other.timestamp > timestamp ||
           (other.timestamp == timestamp && other.nodeId > nodeId) {
            return other
        }
        return self
    }
}

// G-Counter (Grow-only Counter)
struct GCounter: Codable {
    private var counts: [String: Int] = [:]
    
    var value: Int {
        counts.values.reduce(0, +)
    }
    
    mutating func increment(by nodeId: String) {
        counts[nodeId, default: 0] += 1
    }
    
    func merge(with other: GCounter) -> GCounter {
        var merged = GCounter()
        let allNodes = Set(counts.keys).union(other.counts.keys)
        
        for node in allNodes {
            merged.counts[node] = max(
                counts[node] ?? 0,
                other.counts[node] ?? 0
            )
        }
        
        return merged
    }
}

// PN-Counter (Positive-Negative Counter)
struct PNCounter: Codable {
    private var increments = GCounter()
    private var decrements = GCounter()
    
    var value: Int {
        increments.value - decrements.value
    }
    
    mutating func increment(by nodeId: String) {
        increments.increment(by: nodeId)
    }
    
    mutating func decrement(by nodeId: String) {
        decrements.increment(by: nodeId)
    }
    
    func merge(with other: PNCounter) -> PNCounter {
        var merged = PNCounter()
        merged.increments = increments.merge(with: other.increments)
        merged.decrements = decrements.merge(with: other.decrements)
        return merged
    }
}

// LWW-Element-Set (for collaborative editing)
struct LWWElementSet<T: Hashable & Codable>: Codable {
    private var addSet: [T: TimeInterval] = [:]
    private var removeSet: [T: TimeInterval] = [:]
    
    var elements: Set<T> {
        var result = Set<T>()
        for (element, addTime) in addSet {
            let removeTime = removeSet[element] ?? 0
            if addTime > removeTime {
                result.insert(element)
            }
        }
        return result
    }
    
    mutating func add(_ element: T, at timestamp: TimeInterval) {
        if timestamp > (addSet[element] ?? 0) {
            addSet[element] = timestamp
        }
    }
    
    mutating func remove(_ element: T, at timestamp: TimeInterval) {
        if timestamp > (removeSet[element] ?? 0) {
            removeSet[element] = timestamp
        }
    }
    
    func merge(with other: LWWElementSet<T>) -> LWWElementSet<T> {
        var merged = LWWElementSet<T>()
        
        for (element, time) in addSet {
            merged.addSet[element] = max(time, other.addSet[element] ?? 0)
        }
        for (element, time) in other.addSet {
            merged.addSet[element] = max(time, addSet[element] ?? 0)
        }
        
        for (element, time) in removeSet {
            merged.removeSet[element] = max(time, other.removeSet[element] ?? 0)
        }
        for (element, time) in other.removeSet {
            merged.removeSet[element] = max(time, removeSet[element] ?? 0)
        }
        
        return merged
    }
}
```

---

## Media Handling

### Q13: Design an efficient image loading and caching system

**Answer:**

```swift
// Multi-tier cache architecture
┌─────────────────────────────────────────────────────────────┐
│                      Image Request                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Memory Cache (L1)                         │
│              (NSCache, ~50MB, fastest)                      │
└──────────────────────────┬──────────────────────────────────┘
                           │ Miss
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     Disk Cache (L2)                          │
│              (File system, ~500MB, fast)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ Miss
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        Network                               │
│                 (CDN, conditional GET)                      │
└─────────────────────────────────────────────────────────────┘

// Implementation
actor ImageLoader {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let urlSession: URLSession
    private var inProgressTasks: [URL: Task<UIImage, Error>] = [:]
    
    init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        diskCache = DiskCache(maxSize: 500 * 1024 * 1024) // 500MB
        
        let config = URLSessionConfiguration.default
        config.urlCache = nil // We handle caching
        urlSession = URLSession(configuration: config)
    }
    
    func loadImage(from url: URL, size: CGSize? = nil) async throws -> UIImage {
        let cacheKey = cacheKey(for: url, size: size)
        
        // L1: Memory cache
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        
        // L2: Disk cache
        if let diskData = await diskCache.get(cacheKey),
           let image = UIImage(data: diskData) {
            let resized = resize(image, to: size)
            memoryCache.setObject(resized, forKey: cacheKey as NSString)
            return resized
        }
        
        // Coalesce duplicate requests
        if let existingTask = inProgressTasks[url] {
            return try await existingTask.value
        }
        
        // Network fetch
        let task = Task {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                throw ImageLoadError.invalidResponse
            }
            
            // Cache original to disk
            await diskCache.set(data, forKey: url.absoluteString)
            
            // Resize and cache to memory
            let resized = resize(image, to: size)
            memoryCache.setObject(resized, forKey: cacheKey as NSString)
            
            return resized
        }
        
        inProgressTasks[url] = task
        
        defer {
            inProgressTasks.removeValue(forKey: url)
        }
        
        return try await task.value
    }
    
    private func resize(_ image: UIImage, to size: CGSize?) -> UIImage {
        guard let targetSize = size,
              image.size.width > targetSize.width ||
              image.size.height > targetSize.height else {
            return image
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func cacheKey(for url: URL, size: CGSize?) -> String {
        if let size = size {
            return "\(url.absoluteString)_\(Int(size.width))x\(Int(size.height))"
        }
        return url.absoluteString
    }
}

// Disk cache with LRU eviction
actor DiskCache {
    private let directory: URL
    private let maxSize: Int
    private var currentSize: Int = 0
    private var accessLog: [String: Date] = [:]
    
    func set(_ data: Data, forKey key: String) async {
        let fileURL = directory.appendingPathComponent(key.sha256())
        
        try? data.write(to: fileURL)
        accessLog[key] = Date()
        currentSize += data.count
        
        await evictIfNeeded()
    }
    
    func get(_ key: String) async -> Data? {
        let fileURL = directory.appendingPathComponent(key.sha256())
        accessLog[key] = Date()
        return try? Data(contentsOf: fileURL)
    }
    
    private func evictIfNeeded() async {
        guard currentSize > maxSize else { return }
        
        // Sort by last access time
        let sorted = accessLog.sorted { $0.value < $1.value }
        
        for (key, _) in sorted {
            guard currentSize > maxSize * 3 / 4 else { break } // Evict to 75%
            
            let fileURL = directory.appendingPathComponent(key.sha256())
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attrs[.size] as? Int {
                try? FileManager.default.removeItem(at: fileURL)
                currentSize -= size
                accessLog.removeValue(forKey: key)
            }
        }
    }
}
```

---

## Analytics & Monitoring

### Q14: Design a mobile analytics and crash reporting system

**Answer:**

```swift
// Event tracking system
actor AnalyticsEngine {
    private var eventBuffer: [AnalyticsEvent] = []
    private let batchSize = 50
    private let flushInterval: TimeInterval = 30
    private var flushTask: Task<Void, Never>?
    
    struct AnalyticsEvent: Codable {
        let name: String
        let properties: [String: AnyCodable]
        let timestamp: Date
        let sessionId: String
        let userId: String?
        let deviceInfo: DeviceInfo
    }
    
    func track(_ event: String, properties: [String: Any] = [:]) {
        let analyticsEvent = AnalyticsEvent(
            name: event,
            properties: properties.mapValues { AnyCodable($0) },
            timestamp: Date(),
            sessionId: SessionManager.shared.sessionId,
            userId: UserManager.shared.userId,
            deviceInfo: DeviceInfo.current
        )
        
        eventBuffer.append(analyticsEvent)
        
        if eventBuffer.count >= batchSize {
            Task { await flush() }
        }
        
        scheduleFlush()
    }
    
    private func scheduleFlush() {
        flushTask?.cancel()
        flushTask = Task {
            try? await Task.sleep(for: .seconds(flushInterval))
            await flush()
        }
    }
    
    func flush() async {
        guard !eventBuffer.isEmpty else { return }
        
        let eventsToSend = eventBuffer
        eventBuffer.removeAll()
        
        do {
            try await sendEvents(eventsToSend)
        } catch {
            // Re-queue failed events
            eventBuffer.insert(contentsOf: eventsToSend, at: 0)
            // Persist to disk for retry
            await persistFailedEvents(eventsToSend)
        }
    }
}

// Performance monitoring
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var traces: [String: TraceData] = [:]
    
    struct TraceData {
        let name: String
        let startTime: CFAbsoluteTime
        var checkpoints: [(String, CFAbsoluteTime)] = []
        var attributes: [String: String] = []
    }
    
    func startTrace(_ name: String) -> String {
        let traceId = UUID().uuidString
        traces[traceId] = TraceData(name: name, startTime: CFAbsoluteTimeGetCurrent())
        return traceId
    }
    
    func addCheckpoint(_ checkpoint: String, to traceId: String) {
        traces[traceId]?.checkpoints.append((checkpoint, CFAbsoluteTimeGetCurrent()))
    }
    
    func endTrace(_ traceId: String) {
        guard var trace = traces.removeValue(forKey: traceId) else { return }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - trace.startTime
        
        // Report to analytics
        var properties: [String: Any] = [
            "trace_name": trace.name,
            "duration_ms": duration * 1000
        ]
        
        // Add checkpoint durations
        var lastTime = trace.startTime
        for (name, time) in trace.checkpoints {
            properties["checkpoint_\(name)_ms"] = (time - lastTime) * 1000
            lastTime = time
        }
        
        Analytics.track("performance_trace", properties: properties)
    }
    
    // Auto-instrument network requests
    func instrumentURLSession() {
        URLProtocol.registerClass(MonitoringURLProtocol.self)
    }
}

// Crash reporting
class CrashReporter {
    static let shared = CrashReporter()
    
    func configure() {
        // Set up exception handler
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.handleException(exception)
        }
        
        // Set up signal handlers
        signal(SIGABRT) { _ in CrashReporter.shared.handleSignal(SIGABRT) }
        signal(SIGILL) { _ in CrashReporter.shared.handleSignal(SIGILL) }
        signal(SIGSEGV) { _ in CrashReporter.shared.handleSignal(SIGSEGV) }
        signal(SIGFPE) { _ in CrashReporter.shared.handleSignal(SIGFPE) }
        signal(SIGBUS) { _ in CrashReporter.shared.handleSignal(SIGBUS) }
    }
    
    private func handleException(_ exception: NSException) {
        let crashReport = CrashReport(
            type: .exception,
            name: exception.name.rawValue,
            reason: exception.reason ?? "Unknown",
            stackTrace: exception.callStackSymbols,
            threadInfo: captureThreadInfo()
        )
        
        persistCrashReport(crashReport)
    }
    
    func checkPendingCrashReports() async {
        let pendingReports = loadPersistedCrashReports()
        
        for report in pendingReports {
            do {
                try await uploadCrashReport(report)
                deleteCrashReport(report.id)
            } catch {
                // Will retry next launch
            }
        }
    }
}
```

---

## Summary

| Topic | Key Design Principles |
|-------|----------------------|
| Architecture | Clean layers, offline-first, modular features |
| Networking | Batch requests, adaptive quality, compression |
| Caching | Multi-tier, LRU eviction, size limits |
| Security | PKCE auth, keychain storage, certificate pinning |
| Performance | Background task batching, lazy loading |
| Real-time | WebSocket with fallback, message queuing |
| Sync | CRDTs for conflicts, event sourcing |
| Analytics | Batched upload, crash persistence |

---

*Last updated: 2024*
