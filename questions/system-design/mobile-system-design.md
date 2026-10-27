# Mobile system design

Design questions that are specific to apps: unreliable networks, offline use, old app versions in
the field, battery and storage. Answers name the trade-offs and cite platform documentation or
standards.

## SD-001: How do you structure a mobile system design interview?

**Level:** mid

Spend the first minutes on scope, then go from the user-facing flow down to the details:

1. **Requirements**: the core user flows (three at most), the platforms, and non-functional needs:
   offline support, latency, data size, privacy, number of users. Ask; do not assume.
2. **High-level client architecture**: UI layer, state holders (view models), a domain or
   repository layer, local storage, networking, and background work. Draw the data flow in one
   direction: the UI observes local state, user actions go through the repository, the network
   updates storage.
3. **API and data model**: the endpoints or messages the client needs, pagination, how changes
   reach the client (polling, push, a socket), and the local schema.
4. **Deep dives** the interviewer cares about: offline sync (SD-002), feeds (SD-003), media
   (SD-004), real time (SD-005), notifications (SD-006), authentication (SD-007).
5. **Operational concerns**: rollout and feature flags (SD-008), compatibility with old versions
   (SD-009), failure handling (SD-010), monitoring of crashes and performance.

Name trade-offs explicitly ("cursor pagination costs a more complex API but survives inserts") and
keep the server side at the level of detail the role needs.

**References:** [Guide to app architecture (Android)](https://developer.android.com/topic/architecture) · [Guide to app architecture (Flutter)](https://docs.flutter.dev/app-architecture/guide)

## SD-002: Design offline-first sync for a notes app.

**Level:** senior

**Local database as the source of truth.** The UI reads and writes only the local store (SwiftData,
Room, SQLite). Every write is applied locally at once and recorded in an **outbox** table with an
operation ID.

**Upload.** A sync worker (WorkManager on Android, a background task or the next foreground launch
on iOS) sends outbox entries in order. Each request carries the operation ID as an idempotency key
so a retry after a timeout cannot apply twice (SD-010). Entries are removed only after the server
confirms.

**Download.** The client asks for changes since its last **sync token** (a server-issued cursor,
not a client clock) and applies them in one transaction. Deletions arrive as tombstones.

**Conflicts.** Decide per field or per record:

- last writer wins, using server-assigned versions, is simple and fine for settings;
- a three-way merge using the common base version suits text fields;
- for collaborative editing, CRDTs merge concurrent edits without a central decision, at the cost
  of complexity and metadata size;
- some conflicts must be shown to the user.

Also cover schema migrations of the local store, sync of large attachments separately from
metadata, and what the UI shows for unsynced changes.

**Reference:** [Build an offline-first app](https://developer.android.com/topic/architecture/data-layer/offline-first)

## SD-003: How do you paginate an infinite feed?

**Level:** mid

**Offset pagination** (`?offset=40&limit=20`) is simple but breaks when items are inserted or
deleted while the user scrolls: items are skipped or shown twice, and deep offsets are slow on the
database.

**Cursor pagination** returns an opaque `next_cursor` that encodes the position (for example the
sort key and ID of the last item). The next page starts strictly after it, so inserts at the top do
not shift the pages, and queries use an index. New items at the top are fetched separately ("3 new
posts") with a cursor for the newest item seen.

Client side:

- Request the next page when the user is a few screens from the end, not at the last row.
- De-duplicate by ID when merging pages, and keep loading, error and end-of-list states per
  direction.
- Cache pages in the local database so the feed opens instantly and works offline; Android's Paging
  library with a `RemoteMediator` implements exactly this pattern.
- Cancel requests for pages that are no longer needed.

**Reference:** [Paging library overview](https://developer.android.com/topic/libraries/architecture/paging/v3-overview)

## SD-004: Design the image loading pipeline of a photo feed.

**Level:** mid

1. **Request the right size.** The server or a CDN provides several sizes or resizes on the fly
   (`?w=600`), and the client asks for the display size times the screen scale.
2. **Memory cache** of decoded images keyed by URL and size, with a byte limit and eviction under
   memory pressure (`NSCache`, an LRU cache on Android). Decoded size is width × height × 4 bytes.
3. **Disk cache** of the encoded files, honouring HTTP cache headers.
4. **Decode off the main thread** and downsample while decoding (ImageIO thumbnails on iOS,
   `inSampleSize` or `ImageDecoder` target size on Android), never decode full resolution for a
   thumbnail.
5. **De-duplicate** concurrent requests for the same URL, **prioritise** visible cells, and
   **cancel** requests for cells that scrolled away; prefetch the next rows.
6. **Placeholders**: a blurhash or dominant colour from the API avoids layout jumps.
7. Prefer modern formats such as HEIC, AVIF or WebP where the platform decodes them.

Existing libraries (Nuke or Kingfisher on iOS, Coil or Glide on Android) implement most of this; in
an interview, explain the pipeline even if you would use one.

**Reference:** [Images and Graphics Best Practices (WWDC18)](https://developer.apple.com/videos/play/wwdc2018/219/)

## SD-005: Design the client side of a chat app.

**Level:** senior

**Transport.** A WebSocket (`URLSessionWebSocketTask`, OkHttp) while the app is in the foreground,
with heartbeats and reconnect with back-off. When the app is in the background or killed, the socket
is gone; new messages arrive as push notifications, and the app syncs when opened.

**Sending.** The client creates the message with a client-generated ID, stores it locally as
"sending", shows it at once, and sends it. The server acknowledges with the server ID and a
timestamp; retries reuse the client ID so the server can de-duplicate. Failed messages stay in the
outbox with a retry option.

**Ordering.** Order by a server-assigned sequence number per conversation, not by device clocks.
After reconnecting, fetch everything after the last sequence number seen, which also fills gaps.

**Receipts and presence.** Delivered and read receipts are small messages keyed by sequence number;
typing indicators are ephemeral and never stored.

**Storage.** Messages in a local database, paginated by sequence number; attachments uploaded
separately, with the message referencing the uploaded file. Mention end-to-end encryption as a
design choice (it moves search and multi-device sync to the client) if the interviewer asks for
privacy.

**References:** [URLSessionWebSocketTask](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask) · [RFC 6455: The WebSocket Protocol](https://www.rfc-editor.org/rfc/rfc6455)

## SD-006: How do push notifications work end to end?

**Level:** mid

1. The app asks the user for permission (iOS always; Android 13 and later for
   `POST_NOTIFICATIONS`).
2. The OS gives the app a **device token**: from APNs on iOS, from Firebase Cloud Messaging on
   Android (FCM can also deliver to iOS through APNs). The app sends the token to your server with
   the user ID. Tokens change: send it on every launch and when the platform reports a new one.
3. Your server sends a message to APNs or FCM with the token; the platform service delivers it.
4. The OS shows **alert** notifications even if the app is not running. **Silent/background**
   pushes (`content-available` on iOS, data messages on Android) wake the app briefly, are throttled
   by the system and are not guaranteed, so never rely on them for critical delivery.

Design points: keep payloads small and fetch details on open; use a Notification Service Extension
on iOS to download images or decrypt content; group notifications with thread IDs or channels;
remove tokens the services report as invalid; and route a tap to the right screen with a deep link
in the payload.

**References:** [User Notifications](https://developer.apple.com/documentation/usernotifications) · [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

## SD-007: How should a native app sign users in with OAuth?

**Level:** senior

Follow OAuth 2.0 for Native Apps (RFC 8252):

- Use the **authorization code flow with PKCE**. The app generates a random `code_verifier`, sends
  its SHA-256 hash as `code_challenge`, and later proves possession by sending the verifier with the
  code. An intercepted code is useless without it.
- Open the sign-in page in the **system browser** (`ASWebAuthenticationSession` on iOS, Custom
  Tabs on Android), not an embedded web view, so the app never sees the password and the user's
  existing session can be reused.
- Receive the redirect with a claimed `https` link (universal link or app link) where possible.
- Never ship a client secret in the app; anything in the binary can be extracted.

Tokens: keep a short-lived access token and a refresh token in the Keychain or Keystore-backed
storage (IOS-051, RN-021). Refresh **once** when several requests get a 401 at the same time (one
in-flight refresh task that the others await), rotate refresh tokens on the server, and sign out
cleanly when refresh fails.

**References:** [RFC 8252: OAuth 2.0 for Native Apps](https://www.rfc-editor.org/rfc/rfc8252) · [RFC 7636: Proof Key for Code Exchange](https://www.rfc-editor.org/rfc/rfc7636)

## SD-008: How do you roll out a risky feature to millions of users?

**Level:** mid

Separate **shipping code** from **turning it on**:

- Ship the feature behind a **remote feature flag**, off by default, with the old path still
  working. The app fetches flag values at launch, caches them, and uses safe defaults when the
  fetch fails.
- Turn it on for internal users, then a small percentage, then more, watching crash-free rate,
  error rates and the feature's own metrics at each step. A **kill switch** turns it off without a
  release.
- Use the stores' staged rollouts for the binary too: phased release on the App Store (seven days,
  can be paused) and staged rollouts on Google Play (a percentage you choose, can be halted).

Add a **minimum supported version** check for the rare case where old versions must stop working
(a broken payment flow, a security fix): the app asks the server and shows a blocking update
screen; on Android the Play in-app updates API can run an immediate update. Remove flags once a
feature is fully rolled out, or they become permanent complexity.

**References:** [Release a version update in phases (App Store Connect)](https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases) · [In-app updates (Android)](https://developer.android.com/guide/playcore/in-app-updates)

## SD-009: How do you change an API when old app versions stay installed for years?

**Level:** senior

Unlike a website, you cannot update every client at once: users skip updates, and some devices
cannot install new versions. So the API must stay compatible with every version you still
support.

- Make **additive** changes: new optional fields and new endpoints. Clients must ignore unknown
  fields and unknown enum values (decode unknown cases into an `.unknown` case instead of failing).
- Never change the meaning or type of an existing field; add a new one and keep the old one
  populated until the versions that read it are retired.
- Version breaking changes (`/v2/`, or a version header) and keep the old version running.
- Send the app version and platform with every request, so the server can adapt responses and you
  can see which versions are still active before retiring anything.
- Drive server-controlled UI (which sections a home screen shows) with a schema that old clients
  can safely skip.
- Enforce a minimum version (SD-008) only as the last step.

**Reference:** [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)

## SD-010: How should a mobile client retry failed requests?

**Level:** senior

Retry only what is safe and likely to succeed:

- Retry **transient** failures: timeouts, connection loss, `429` and `503` (honour `Retry-After`).
  Do not retry `4xx` errors such as `400` or `403`, which will fail again.
- Retry only **idempotent** operations, or make them idempotent: the client sends an
  `Idempotency-Key` with a POST that creates a payment or a message, and the server returns the
  first result for repeated keys.
- Use **exponential back-off with jitter** (wait a random time up to `base × 2^attempt`, capped),
  so thousands of clients that failed together do not retry together and overload the recovering
  server.
- Limit attempts and total time, and give up immediately when the user leaves the screen
  (cancellation).
- Wait for connectivity instead of failing at once: `URLSessionConfiguration.waitsForConnectivity`
  on iOS, WorkManager network constraints on Android.

The same logic applies to reconnecting sockets. Show the user what happened when retries are
exhausted, and keep the unsent data so it can be sent later.

**References:** [Retry strategy (Google Cloud)](https://cloud.google.com/storage/docs/retry-strategy) · [The Idempotency-Key HTTP Header Field (IETF draft)](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)
