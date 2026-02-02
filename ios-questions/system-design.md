# iOS System Design Interview Questions - Deep Dive

A comprehensive guide to mobile system design questions asked at top tech companies.

---

## Framework for Mobile System Design

Before diving into specific questions, here's a framework to approach any mobile system design interview:

1. **Clarify Requirements** — Functional + Non-functional
2. **High-Level Architecture** — Client components + API layer
3. **Data Model** — Core entities and relationships
4. **API Design** — Endpoints, request/response shapes
5. **Client Architecture** — Modules, layers, patterns
6. **Deep Dives** — Offline support, caching, sync, performance
7. **Trade-offs** — Justify your decisions

---

## Q: Design a Photo Sharing App (Instagram-like)

**Difficulty:** 🔴 Senior

### Requirements

- Feed with photos from followed users
- Post photos with filters and captions
- Like, comment, save posts
- User profiles with grid view
- Stories (ephemeral 24h content)
- Push notifications

### High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                   App Layer                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│
│  │  Feed    │ │  Camera  │ │   Profile        ││
│  │  Module  │ │  Module  │ │   Module         ││
│  └────┬─────┘ └────┬─────┘ └────┬─────────────┘│
│       │             │            │               │
│  ┌────▼─────────────▼────────────▼──────────────┐│
│  │         Service / Domain Layer               ││
│  │  PostService  UserService  MediaService      ││
│  └────┬─────────────┬────────────┬──────────────┘│
│       │             │            │               │
│  ┌────▼─────────────▼────────────▼──────────────┐│
│  │         Data / Infrastructure Layer          ││
│  │  APIClient  Cache  ImagePipeline  Database   ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### Data Model

```swift
struct Post: Codable, Identifiable {
    let id: String
    let authorId: String
    let imageURLs: [URL]
    let caption: String
    let likeCount: Int
    let commentCount: Int
    let createdAt: Date
    var isLiked: Bool
    var isSaved: Bool
}

struct FeedItem: Codable {
    let post: Post
    let author: UserSummary
}

struct UserSummary: Codable {
    let id: String
    let username: String
    let avatarURL: URL?
}
```

### Feed API

```swift
// Cursor-based pagination
protocol FeedAPI {
    func getFeed(cursor: String?, limit: Int) async throws -> FeedResponse
}

struct FeedResponse: Codable {
    let items: [FeedItem]
    let nextCursor: String?
    let hasMore: Bool
}
```

### Image Loading Pipeline

```swift
final class ImagePipeline {
    static let shared = ImagePipeline()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let downloader: ImageDownloader

    func load(_ url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString

        // 1. Memory cache
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        // 2. Disk cache
        if let diskData = try? diskCache.read(for: key as String),
           let image = UIImage(data: diskData) {
            memoryCache.setObject(image, forKey: key)
            return image
        }

        // 3. Network
        let data = try await downloader.download(url)
        guard let image = UIImage(data: data) else {
            throw ImageError.decodingFailed
        }

        // Cache
        memoryCache.setObject(image, forKey: key)
        try? diskCache.write(data, for: key as String)

        return image
    }
}
```

### Key Design Decisions

**Feed Pagination:** Cursor-based over offset-based to handle insertions without skipping/duplicating items.

**Image Caching:** Three-tier (memory → disk → network). Use progressive JPEG for perceived performance. Downsample images to display size to reduce memory.

**Offline Support:** Cache last N feed items in Core Data. Show stale-while-revalidate pattern.

**Prefetching:** Use `UICollectionViewDataSourcePrefetching` to load images before cells become visible.

```swift
extension FeedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = feedItems[indexPath.item].post.imageURLs.first
            if let url = imageURL {
                Task { try? await ImagePipeline.shared.load(url) }
            }
        }
    }
}
```

---

## Q: Design a Chat Application (WhatsApp-like)

**Difficulty:** 🔴 Senior

### Requirements

- 1:1 and group messaging
- Real-time message delivery
- Read receipts and typing indicators
- Media messages (photos, videos, documents)
- Message persistence and offline support
- End-to-end encryption

### Architecture

```
┌──────────────────────────────────────────────┐
│              Presentation Layer               │
│  ConversationList → ChatView → MediaViewer   │
├──────────────────────────────────────────────┤
│              Domain Layer                     │
│  MessageService  ConversationService         │
│  EncryptionService  SyncService              │
├──────────────────────────────────────────────┤
│              Data Layer                       │
│  WebSocket   REST API   SQLite/CoreData      │
│  FileManager  Keychain  MediaUploader        │
└──────────────────────────────────────────────┘
```

### Real-Time Communication

```swift
final class ChatSocket {
    private var webSocket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    func connect(token: String) {
        var request = URLRequest(url: URL(string: "wss://api.example.com/ws")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        receiveMessage()
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(.string(let text)):
                self?.handleIncoming(text)
            case .failure(let error):
                self?.handleDisconnect(error)
            default:
                break
            }
            self?.receiveMessage()  // Continue listening
        }
    }

    func send(_ message: OutgoingMessage) async throws {
        let data = try JSONEncoder().encode(message)
        try await webSocket?.send(.data(data))
    }
}
```

### Message Storage

```swift
// Core Data entity
@objc(MessageEntity)
class MessageEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var conversationId: String
    @NSManaged var senderId: String
    @NSManaged var content: String
    @NSManaged var timestamp: Date
    @NSManaged var status: Int16  // sent, delivered, read
    @NSManaged var mediaURL: String?
    @NSManaged var localMediaPath: String?
}

// Sync strategy: last-synced timestamp per conversation
final class MessageSyncService {
    func sync(conversationId: String) async throws {
        let lastSync = getLastSyncTimestamp(for: conversationId)
        let newMessages = try await api.getMessages(
            conversationId: conversationId,
            since: lastSync
        )
        try persistMessages(newMessages)
        updateSyncTimestamp(for: conversationId)
    }
}
```

### Offline-First Strategy

1. **Outbox Pattern:** Messages are saved locally first with status `.pending`, then sent via WebSocket/API. On success, status updates to `.sent`.
2. **Sync on reconnect:** Fetch missed messages using last-seen message ID.
3. **Conflict resolution:** Server timestamp wins; messages are ordered by server timestamp.

### Key Trade-offs

- **WebSocket vs SSE vs Polling:** WebSocket for bidirectional real-time. SSE as fallback. Long polling as last resort.
- **SQLite vs Core Data:** Core Data for convenience and NSFetchedResultsController. SQLite (GRDB/FMDB) for performance-critical apps.
- **E2E Encryption:** Signal Protocol (Double Ratchet). Keys stored in Keychain. Performance cost on message send/receive.

---

## Q: Design a Ride-Sharing App (Uber-like)

**Difficulty:** 🔴 Senior

### Requirements

- Real-time map with driver locations
- Ride request and matching
- Live trip tracking
- ETA calculation
- Payment processing
- Rating system

### Map and Location Architecture

```swift
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let updateSubject = PassthroughSubject<CLLocation, Never>()

    var locationUpdates: AnyPublisher<CLLocation, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func startTracking() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        locations.forEach { updateSubject.send($0) }
    }
}

// Driver location updates via WebSocket
struct DriverLocation: Codable {
    let driverId: String
    let latitude: Double
    let longitude: Double
    let heading: Double
    let timestamp: Date
}
```

### Map Rendering Optimization

```swift
final class DriverAnnotationManager {
    private var driverAnnotations: [String: MKPointAnnotation] = [:]

    func updateDriverLocations(_ locations: [DriverLocation], on mapView: MKMapView) {
        var updatedIds = Set<String>()

        for location in locations {
            updatedIds.insert(location.driverId)

            if let existing = driverAnnotations[location.driverId] {
                // Animate existing marker
                UIView.animate(withDuration: 0.3) {
                    existing.coordinate = CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
            } else {
                // Add new marker
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                driverAnnotations[location.driverId] = annotation
                mapView.addAnnotation(annotation)
            }
        }

        // Remove stale markers
        let staleIds = Set(driverAnnotations.keys).subtracting(updatedIds)
        for id in staleIds {
            if let annotation = driverAnnotations.removeValue(forKey: id) {
                mapView.removeAnnotation(annotation)
            }
        }
    }
}
```

### Ride Request Flow

```
User taps "Request Ride"
     │
     ▼
Client sends POST /rides with pickup/dropoff
     │
     ▼
Server matches driver (ETA-based + proximity)
     │
     ▼
Driver receives push notification + in-app alert
     │
     ▼
Driver accepts → Server notifies rider via WebSocket
     │
     ▼
Both see real-time location updates
     │
     ▼
Driver arrives → Trip starts
     │
     ▼
Trip ends → Payment processed → Rating screen
```

### Key Considerations

- **Battery optimization:** Reduce location accuracy when app is in background. Use significant location changes for idle state.
- **Map tile caching:** Cache map tiles for frequently visited areas.
- **Geohashing:** Use geohash for efficient nearby driver queries.
- **Smooth animations:** Interpolate between location updates for smooth marker movement.

---

## Q: Design an Offline-First Note-Taking App

**Difficulty:** 🔴 Senior

### Core Challenge

Full offline support with multi-device sync and conflict resolution.

### Sync Architecture

```swift
// CRDT-based text editing for conflict-free merging
struct TextOperation: Codable {
    let id: String
    let position: Int
    let type: OperationType
    let character: Character?
    let timestamp: Date
    let deviceId: String

    enum OperationType: String, Codable {
        case insert
        case delete
    }
}

// Operational Transform approach
final class SyncEngine {
    private let localDB: NoteDatabase
    private let remoteAPI: SyncAPI
    private var pendingOps: [TextOperation] = []

    func pushPendingChanges() async throws {
        let ops = try localDB.getPendingOperations()
        guard !ops.isEmpty else { return }

        let response = try await remoteAPI.sync(operations: ops)

        // Apply remote operations that happened concurrently
        for remoteOp in response.remoteOperations {
            try localDB.apply(remoteOp)
        }

        try localDB.markSynced(ops.map(\.id))
    }

    func resolveConflict(local: Note, remote: Note) -> Note {
        // Last-write-wins for metadata
        // CRDT merge for content
        if local.contentVersion == remote.contentVersion {
            return local
        }
        return local.modifiedAt > remote.modifiedAt ? local : remote
    }
}
```

### Key Decisions

- **Conflict Resolution:** CRDTs for text content, last-write-wins for metadata.
- **Storage:** SQLite with WAL mode for concurrent reads during sync.
- **Sync Protocol:** Operational transforms for real-time collaboration, batch sync for background updates.

---

## Q: Design a Video Streaming App (YouTube-like)

**Difficulty:** 🔴 Senior

### Video Playback Architecture

```swift
final class VideoPlayerManager {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let cache = VideoCache()

    func play(url: URL, in view: UIView) {
        // Check for cached segments
        if let localURL = cache.localURL(for: url) {
            setupPlayer(with: localURL, in: view)
            return
        }

        // Use AVAssetResourceLoaderDelegate for custom caching
        let asset = AVURLAsset(url: url)
        asset.resourceLoader.setDelegate(
            ResourceLoaderDelegate(cache: cache),
            queue: .global(qos: .userInitiated)
        )

        let item = AVPlayerItem(asset: asset)
        setupPlayer(with: item, in: view)
    }

    private func setupPlayer(with url: URL, in view: UIView) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        setupPlayer(with: item, in: view)
    }

    private func setupPlayer(with item: AVPlayerItem, in view: UIView) {
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer!)
        player?.play()
    }
}
```

### Adaptive Bitrate Streaming

Use HLS (HTTP Live Streaming) with multiple quality variants. AVPlayer handles adaptive bitrate natively:

```swift
// HLS playlist with multiple variants
// The system automatically selects based on network conditions
let hlsURL = URL(string: "https://cdn.example.com/video/master.m3u8")!
let player = AVPlayer(url: hlsURL)

// Monitor quality changes
player.currentItem?.observe(\.tracks) { item, _ in
    let videoBitrate = item.accessLog()?.events.last?.indicatedBitrate
    print("Current bitrate: \(videoBitrate ?? 0)")
}
```

### Feed Performance

- **Cell recycling:** Reuse player instances across cells
- **Autoplay logic:** Only autoplay the most visible cell (>50% visible)
- **Preloading:** Prefetch first 2 seconds of next 2 videos
- **Memory management:** Pause and release players for off-screen cells

---

## General Tips for Mobile System Design Interviews

1. **Always start with requirements clarification** — Don't assume. Ask about scale, offline needs, real-time requirements.

2. **Think mobile-first** — Battery, network variability, memory constraints, app lifecycle.

3. **Draw diagrams** — Show client architecture layers, data flow, state management.

4. **Discuss trade-offs** — There's no perfect solution. Show you understand the costs of your choices.

5. **Cover edge cases** — Poor connectivity, backgrounding, force quit, OS memory pressure.

6. **Know your numbers** — Typical image sizes, API response times, memory limits, storage constraints.

7. **Security matters** — Certificate pinning, token storage (Keychain), data encryption at rest.

8. **Testing strategy** — How would you test this? Mock network layer, snapshot tests for UI, integration tests for sync logic.
