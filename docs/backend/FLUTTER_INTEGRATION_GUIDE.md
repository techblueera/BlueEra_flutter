# Flutter Integration Guide — Video Service

A complete, Flutter-focused guide for integrating with the `be_video_service`
backend: a Node.js/Express video platform that powers **reels (shorts)**,
**long-form video**, an **OTT (series/episodes) catalog**, social interactions
(likes/comments/share), a music library, and admin tooling.

> If you only care about the **reels** experience, the shorter
> [REELS_API_FRONTEND_GUIDE.md](REELS_API_FRONTEND_GUIDE.md) is a focused subset
> of this document. This guide covers the **whole system**.

---

## Table of contents

1. [Conventions & base setup](#1-conventions--base-setup)
2. [Dependencies](#2-dependencies)
3. [Networking layer (Dio + auth interceptor)](#3-networking-layer-dio--auth-interceptor)
4. [Authentication](#4-authentication)
5. [Core data models (Dart)](#5-core-data-models-dart)
6. [The unified feed envelope](#6-the-unified-feed-envelope)
7. [Videos & feeds](#7-videos--feeds)
8. [Uploading a video](#8-uploading-a-video)
9. [Video playback (HLS)](#9-video-playback-hls)
10. [Likes](#10-likes)
11. [Comments](#11-comments)
12. [Share / deep links](#12-share--deep-links)
13. [OTT — series, episodes & personalized feed](#13-ott--series-episodes--personalized-feed)
14. [Songs & favorites](#14-songs--favorites)
15. [Categories & titles](#15-categories--titles)
16. [Admin videos (in-app banners/ads)](#16-admin-videos-in-app-bannersads)
17. [Admin dashboard & moderation](#17-admin-dashboard--moderation)
18. [Health & demo endpoints](#18-health--demo-endpoints)
19. [Error handling](#19-error-handling)
20. [Full endpoint reference](#20-full-endpoint-reference)

---

## 1. Conventions & base setup

- **Base URL:** routes are mounted at the **root** — there is **no `/api`
  prefix**. e.g. `https://<host>/videos/hot/short`.
- **Content type:** JSON for everything except song uploads (multipart) and the
  direct-to-S3 PUT during video upload.
- **IDs** are MongoDB ObjectIds (24-char hex strings).
- **Timestamps** are ISO-8601 strings (UTC).
- **Auth** is a JWT bearer token: `Authorization: Bearer <token>`.
- **Interactive API docs (Swagger):** `GET /api-docs`, raw spec at
  `GET /swagger.json`.

Two common response envelopes you'll see:

```jsonc
// "simple" envelope (most non-feed endpoints)
{ "success": true, "message": "…", "data": { /* or [ ] */ } }

// "feed" envelope (video lists — see §6)
{ "success": true, "data": { "feedType": "...", "videos": [ ... ] },
  "metadata": { ... }, "pagination": { ... } }
```

> ⚠️ Two endpoints deviate from the feed envelope: `GET /videos/hot/:type`
> returns a **flat array** in `data`, and `GET /videos/metadata/:id` returns the
> **raw** video document. Both are called out below.

Define your config once:

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-host.example.com';
  static const Duration timeout = Duration(seconds: 30);
}
```

---

## 2. Dependencies

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0                 # HTTP client
  flutter_secure_storage: ^9.0.0   # store the JWT
  # HLS playback — pick ONE:
  video_player: ^2.8.0       # lightweight, supports HLS (.m3u8) on iOS/Android
  chewie: ^1.7.0             # optional UI controls on top of video_player
  # OR for richer reels UX (quality switch, caching, preloading):
  # better_player_plus: ^1.0.0
  cached_network_image: ^3.3.0     # poster/cover images
  visibility_detector: ^0.4.0      # for autoplay in a vertical reels PageView
```

For **reels** specifically, `better_player_plus` (or `media_kit`) gives you
preloading and per-item controllers, which matters for a smooth vertical feed.
`video_player` is fine to start.

---

## 3. Networking layer (Dio + auth interceptor)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = const FlutterSecureStorage();
  late final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.timeout,
    receiveTimeout: ApiConfig.timeout,
    // Treat only <500 as "resolved" so we can read 4xx bodies ourselves:
    validateStatus: (s) => s != null && s < 500,
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_AuthInterceptor());

  Future<String?> get token => _storage.read(key: 'jwt');
  Future<void> setToken(String t) => _storage.write(key: 'jwt', value: t);
  Future<void> clearToken() => _storage.delete(key: 'jwt');
}

class _AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'jwt');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 401) {
      // token expired / invalid — trigger logout or refresh in your app
    }
    handler.next(response);
  }
}
```

**Auth requirement legend** used throughout:

| Symbol | Meaning |
|---|---|
| 🔓 | No auth needed |
| 🔐 | **Required** — request fails without a valid token |
| 🟡 | **Optional** — works without auth, but personalizes (`isLiked`, `isFollowing`) and may unlock owner-only data when present |
| 👑 | Requires an **Admin** (or SubAdmin) account |

---

## 4. Authentication

This service does **not** issue tokens — login/signup happen in your **auth
service**. This backend only *consumes* the JWT.

How the backend validates it (you don't have to do anything special):
1. It reads `Authorization: Bearer <token>`.
2. If gRPC session validation is enabled, it decodes the token, pulls the
   `sessionId` claim, and validates the session over gRPC.
3. Otherwise (or as a fallback) it verifies the JWT with the shared secret.
4. `req.user` is populated with `{ _id, account_type, role }`. The `account_type`
   (e.g. `"User"`, `"Business"`, `"Admin"`) drives admin gating.

**Just send the same bearer token** you got from the auth service on every
authenticated request.

### Feature-toggle endpoints (ops, not for app users)

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/auth/session-validation/status` | 🔓 | `{ success, isGrpcSessionValidationEnabled }` |
| `PUT` | `/auth/session-validation/toggle` | 🔓 | body `{ enabled: bool }` — toggles gRPC validation |

Your Flutter app normally won't call these.

### Common 401 bodies

```json
{ "success": false, "message": "Not authorized, no token provided." }
```
Variants: `"token has expired."`, `"token invalid or malformed."`

---

## 5. Core data models (Dart)

These mirror the backend Mongoose schemas. Field nullability reflects what the
API actually returns — be defensive (almost everything except IDs can be null).

### Video

Enums:
- `type`: `short` | `long`
- `status`: `creator_draft` | `submitted_for_review` | `processing` |
  `published` | `failed` | `approved_published` | `rejected`
- `visibility`: `public` | `private` | `unlisted`

```dart
class Video {
  final String id;
  final String userId;
  final String? channelId;
  final String? seriesId;
  final int? episodeNumber;
  final String type;          // "short" | "long"
  final String status;
  final String? title;
  final String? subheading;
  final String? description;  // long-form uses this
  final String? caption;      // shorts use this
  final String? coverUrl;     // poster/thumbnail
  final String? videoUrl;     // original source (mp4)
  final int duration;         // seconds
  final TranscodedUrls? transcodedUrls;
  final Thumbnails? thumbnails;
  final String visibility;
  final List<String> tags;
  final List<String> keywords;
  final List<dynamic> categories; // ObjectIds OR populated {_id,name,slug}
  final VideoLocation? location;
  final SongRef? song;
  final bool allowComments;
  final bool isMatureContent;
  final List<dynamic> taggedUsers;
  final VideoStats stats;
  final DateTime? createdAt;

  Video({
    required this.id, required this.userId, required this.type,
    required this.status, required this.duration, required this.visibility,
    required this.tags, required this.keywords, required this.categories,
    required this.allowComments, required this.isMatureContent,
    required this.taggedUsers, required this.stats,
    this.channelId, this.seriesId, this.episodeNumber, this.title,
    this.subheading, this.description, this.caption, this.coverUrl,
    this.videoUrl, this.transcodedUrls, this.thumbnails, this.location,
    this.song, this.createdAt,
  });

  factory Video.fromJson(Map<String, dynamic> j) => Video(
    id: j['_id'] as String,
    userId: j['userId']?.toString() ?? '',
    channelId: j['channelId']?.toString(),
    seriesId: j['seriesId']?.toString(),
    episodeNumber: j['episodeNumber'] as int?,
    type: j['type'] as String? ?? 'short',
    status: j['status'] as String? ?? 'published',
    title: j['title'] as String?,
    subheading: j['subheading'] as String?,
    description: j['description'] as String?,
    caption: j['caption'] as String?,
    coverUrl: j['coverUrl'] as String?,
    videoUrl: j['videoUrl'] as String?,
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    transcodedUrls: j['transcodedUrls'] == null
        ? null : TranscodedUrls.fromJson(j['transcodedUrls']),
    thumbnails: j['thumbnails'] == null
        ? null : Thumbnails.fromJson(j['thumbnails']),
    visibility: j['visibility'] as String? ?? 'public',
    tags: (j['tags'] as List?)?.cast<String>() ?? const [],
    keywords: (j['keywords'] as List?)?.cast<String>() ?? const [],
    categories: (j['categories'] as List?) ?? const [],
    location: j['location'] == null ? null : VideoLocation.fromJson(j['location']),
    song: j['song'] == null ? null : SongRef.fromJson(j['song']),
    allowComments: j['allowComments'] as bool? ?? true,
    isMatureContent: j['isMatureContent'] as bool? ?? false,
    taggedUsers: (j['taggedUsers'] as List?) ?? const [],
    stats: VideoStats.fromJson(j['stats'] ?? const {}),
    createdAt: j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt']),
  );

  /// Best playback URL: HLS master if available, else original mp4.
  String? get playbackUrl => transcodedUrls?.master ?? videoUrl;
  bool get isReady => status == 'published' || status == 'approved_published';
}

class TranscodedUrls {
  final String? master; // index.m3u8 — prefer this
  final String? p360, p432, p540, p720, p720high, p1080, p1200;
  TranscodedUrls({this.master, this.p360, this.p432, this.p540, this.p720,
      this.p720high, this.p1080, this.p1200});
  factory TranscodedUrls.fromJson(Map<String, dynamic> j) => TranscodedUrls(
    master: j['master'], p360: j['360p'], p432: j['432p'], p540: j['540p'],
    p720: j['720p'], p720high: j['720p-high'], p1080: j['1080p'],
    p1200: j['1200p'],
  );
}

class Thumbnails {
  final String? defaultUrl, high, medium, low;
  Thumbnails({this.defaultUrl, this.high, this.medium, this.low});
  factory Thumbnails.fromJson(Map<String, dynamic> j) => Thumbnails(
    defaultUrl: j['default'], high: j['high'], medium: j['medium'], low: j['low'],
  );
}

class VideoStats {
  final int views, likes, shares, comments;
  VideoStats({this.views = 0, this.likes = 0, this.shares = 0, this.comments = 0});
  factory VideoStats.fromJson(Map<String, dynamic> j) => VideoStats(
    views: (j['views'] as num?)?.toInt() ?? 0,
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    shares: (j['shares'] as num?)?.toInt() ?? 0,
    comments: (j['comments'] as num?)?.toInt() ?? 0,
  );
}

class VideoLocation {
  final String? name; final double? lat, lng;
  VideoLocation({this.name, this.lat, this.lng});
  factory VideoLocation.fromJson(Map<String, dynamic> j) => VideoLocation(
    name: j['name'], lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble());
}

class SongRef {
  final String? id, name, artist, coverUrl;
  SongRef({this.id, this.name, this.artist, this.coverUrl});
  factory SongRef.fromJson(Map<String, dynamic> j) => SongRef(
    id: j['id']?.toString(), name: j['name'], artist: j['artist'],
    coverUrl: j['coverUrl']);
  Map<String, dynamic> toJson() =>
    {'id': id, 'name': name, 'artist': artist, 'coverUrl': coverUrl};
}
```

### Author & Channel (present in feed items)

```dart
class Author {
  final String id;
  final String? username, name, profileImage, designation, accountType;
  final bool isVerified;
  Author({required this.id, this.username, this.name, this.profileImage,
      this.designation, this.accountType, this.isVerified = false});
  factory Author.fromJson(Map<String, dynamic> j) => Author(
    id: j['_id'].toString(), username: j['username'], name: j['name'],
    profileImage: j['profile_image'], designation: j['designation'],
    accountType: j['account_type'], isVerified: j['isVerified'] ?? false);
}

class Channel {
  final String id;
  final String? name, username, logoUrl, coverImageUrl;
  final bool isVerified, isFollowing;
  Channel({required this.id, this.name, this.username, this.logoUrl,
      this.coverImageUrl, this.isVerified = false, this.isFollowing = false});
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: j['_id'].toString(), name: j['name'], username: j['username'],
    logoUrl: j['logoUrl'], coverImageUrl: j['coverImageUrl'],
    isVerified: j['isVerified'] ?? false, isFollowing: j['isFollowing'] ?? false);
}

class Interactions {
  final bool isLiked, isBookmarked, isFollowing;
  Interactions({this.isLiked = false, this.isBookmarked = false,
      this.isFollowing = false});
  factory Interactions.fromJson(Map<String, dynamic> j) => Interactions(
    isLiked: j['isLiked'] ?? false, isBookmarked: j['isBookmarked'] ?? false,
    isFollowing: j['isFollowing'] ?? false);
}
```

---

## 6. The unified feed envelope

Most video-list endpoints (`channel`, `users`, `category`, `search`, single
video, share) return this shape. Build your UI against `FeedItem`.

```dart
class FeedItem {
  final String videoId;
  final Video video;
  final Author? author;
  final Channel? channel;
  final Interactions interactions;
  FeedItem({required this.videoId, required this.video, this.author,
      this.channel, required this.interactions});
  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
    videoId: j['videoId']?.toString() ?? j['video']['_id'].toString(),
    video: Video.fromJson(j['video']),
    author: j['author'] == null ? null : Author.fromJson(j['author']),
    channel: j['channel'] == null ? null : Channel.fromJson(j['channel']),
    interactions: Interactions.fromJson(j['interactions'] ?? const {}),
  );
}

class Pagination {
  final int page, limit, totalPages;
  final int totalVideos;
  final bool hasMore;
  Pagination({required this.page, required this.limit, required this.totalPages,
      required this.totalVideos, required this.hasMore});
  factory Pagination.fromJson(Map<String, dynamic> j) => Pagination(
    page: j['page'] ?? 1, limit: j['limit'] ?? 20,
    totalPages: j['totalPages'] ?? 1,
    totalVideos: j['totalVideos'] ?? j['total'] ?? 0,
    hasMore: j['hasMore'] ?? false);
}

class FeedResponse {
  final List<FeedItem> items;
  final Pagination pagination;
  FeedResponse(this.items, this.pagination);

  factory FeedResponse.fromEnvelope(Map<String, dynamic> body) {
    final data = body['data'];
    // `data.videos` is an array for lists, or a single object for `feedType:single`
    final raw = data is Map ? data['videos'] : data;
    final list = raw is List ? raw : (raw == null ? [] : [raw]);
    return FeedResponse(
      list.map((e) => FeedItem.fromJson(e)).toList(),
      Pagination.fromJson(body['pagination'] ?? const {}),
    );
  }
}
```

---

## 7. Videos & feeds

All under `/videos`.

| Method | Path | Auth | Shape | Notes |
|---|---|---|---|---|
| `GET` | `/videos/hot/:type` | 🔓 | **flat array** | trending; `:type` = `short`/`long` |
| `GET` | `/videos/search` | 🟡 | feed | `query` required |
| `GET` | `/videos/category/:categoryId` | 🟡 | feed | not type-filtered server-side |
| `GET` | `/videos/categories` | 🔓 | `data: [ ]` | list categories |
| `GET` | `/videos/metadata/:videoId` | 🟡 | **raw doc** | ⚠️ increments views |
| `GET` | `/videos/:videoId` | 🔐 | feed (`single`) | personalized; no view increment |
| `GET` | `/videos/channel/:channelId` | 🔐 | feed | a creator's videos |
| `GET` | `/videos/users/:userId/videos` | 🔐 | feed | alias of channel |
| `POST` | `/videos/upload` | 🔐 | — | register an uploaded video |
| `PUT` | `/videos/:videoId` | 🔐 | `data: video` | owner only |
| `DELETE` | `/videos/:videoId` | 🔐 | `{success,message}` | owner or admin |
| `GET` | `/videos/upload-status` | 🔐 | cooldown info | 60-min cooldown |
| `POST` | `/videos/batch-prepare` | 🔐 | warms cache | body `{videoIds:[…≤100]}` |
| `GET` | `/videos/health/redis` | 🔓 | health | |

### 7.1 Trending / "For You" — `GET /videos/hot/:type` 🔓

Ranked by `views×0.6 + likes×0.3 + comments×0.1`. **Flat array, not personalized**
(`isLiked` is always false here — hydrate with the batch like-status call §10).

```
GET /videos/hot/short?page=1&limit=10      // limit 1–50, default 10
```
```jsonc
{ "success": true,
  "data": [ { "_id": "...", "type": "short", "caption": "...", ... } ],
  "pagination": { "page":1, "limit":10, "total":233, "totalPages":24 } }
```

```dart
Future<({List<Video> videos, bool hasMore})> getTrending(
    String type, {int page = 1, int limit = 10}) async {
  final r = await ApiClient.instance.dio.get(
    '/videos/hot/$type', queryParameters: {'page': page, 'limit': limit});
  final list = (r.data['data'] as List).map((e) => Video.fromJson(e)).toList();
  final p = r.data['pagination'];
  return (videos: list, hasMore: page < (p['totalPages'] ?? 1));
}
```

### 7.2 A creator's videos — `GET /videos/channel/:id` / `/videos/users/:id/videos` 🔐

```
GET /videos/channel/<id>?typeFilter=short&page=1&limit=20&sortBy=latest&post_via=all
```

| Query | Default | Options |
|---|---|---|
| `limit` | 20 | 1–50 |
| `page` | 1 | |
| `status` | `published` | `draft`/`processing`/`published`/`failed`/`all` — non-published visible only to the **owner** |
| `typeFilter` | — | `short` \| `long` |
| `sortBy` | `latest` | `latest`/`oldest`/`popular`/`trending` |
| `post_via` | `all` | `user` / `channel` / `all` |

Returns the feed envelope. Owners pass `status=all` to see their drafts.

### 7.3 By category — `GET /videos/category/:categoryId` 🟡

```
GET /videos/category/<id>?page=1&limit=20&sortBy=latest
```
Feed envelope. **Not** type-filtered on the server — filter client-side on
`video.type == 'short'` if needed. Get category IDs from `/videos/categories` or
`/categories`.

### 7.4 Search — `GET /videos/search` 🟡

```
GET /videos/search?query=travel&type=short&page=1&limit=20&sortBy=relevance
```

| Query | Notes |
|---|---|
| `query` | **required**, min length 1 |
| `type` | `short`/`long` |
| `category` | category ObjectId |
| `channelId`, `userId` | scope to a creator |
| `minDuration`, `maxDuration` | seconds |
| `startDate`, `endDate` | ISO dates |
| `sortBy` | `relevance`/`uploadDate`/`views`/`likes` |
| `sortOrder` | `asc`/`desc` (default `desc`) |
| `page`, `limit` | 1 / 20 (max 50) |

### 7.5 Single video — `GET /videos/:videoId` 🔐

Feed envelope with `feedType:"single"`; `data.videos` is a **single object**.
A missing video still returns `200` with an empty `videos` — check before
rendering. Use this for a personalized detail view (no view increment).

### 7.6 Raw metadata + view count — `GET /videos/metadata/:videoId` 🟡

Returns the **raw** document: `{ success:true, data:{…video…} }`.

> ⚠️ **Side effect:** each call **increments `stats.views` by 1**. Call it once
> per actual view (e.g. when a reel becomes >50% visible / starts playing). Do
> not poll it to refresh UI. For non-counting reads use `/videos/:videoId`.

### Generic feed fetcher

```dart
Future<FeedResponse> getFeed(String path,
    {Map<String, dynamic>? query}) async {
  final r = await ApiClient.instance.dio.get(path, queryParameters: query);
  if (r.statusCode != 200) throw ApiException.fromResponse(r);
  return FeedResponse.fromEnvelope(r.data);
}

// e.g. creator feed:
final feed = await getFeed('/videos/channel/$channelId',
    query: {'typeFilter': 'short', 'page': 1, 'limit': 20});
```

---

## 8. Uploading a video

Three steps: **(1)** get a pre-signed S3 URL, **(2)** PUT the bytes to S3,
**(3)** register the video so transcoding starts. There's also a chunked variant
for large/long-form files.

### Step 1 — pre-signed URL — `GET /upload/init` 🔓

```
GET /upload/init?fileName=myReel.mp4&fileType=video/mp4
```
```json
{
  "uploadUrl": "https://bucket.s3.amazonaws.com/uploads/...mp4?X-Amz-...",
  "publicUrl": "https://bucket.s3.us-east-1.amazonaws.com/uploads/...mp4",
  "fileKey": "uploads/1719991234567-uuid123.mp4"
}
```
- `uploadUrl` — pre-signed PUT URL, **valid 30 minutes**.
- `publicUrl` — permanent public URL (use as `videoUrl`/`coverUrl`).
- `fileKey` — S3 key (use as `videoKey`).

Do this twice: once for the video, once for the cover image
(`fileType=image/jpeg`).

### Step 2 — PUT the bytes to S3 (no auth header!)

```dart
Future<({String publicUrl, String fileKey})> uploadToS3(
    File file, String fileName, String mime) async {
  final init = await ApiClient.instance.dio.get('/upload/init',
      queryParameters: {'fileName': fileName, 'fileType': mime});
  final uploadUrl = init.data['uploadUrl'];
  final publicUrl = init.data['publicUrl'];
  final fileKey = init.data['fileKey'];

  // Use a bare Dio (no auth interceptor) for the S3 PUT.
  await Dio().put(uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          Headers.contentTypeHeader: mime,       // MUST match fileType
          Headers.contentLengthHeader: await file.length(),
        },
      ),
      onSendProgress: (sent, total) => debugPrint('${sent / total * 100}%'));

  return (publicUrl: publicUrl, fileKey: fileKey);
}
```

### Step 3 — register the video — `POST /videos/upload` 🔐

```jsonc
{
  "title": "My Reel",            // required
  "type": "short",               // required: "short" | "long"
  "videoUrl": "<publicUrl>",     // required
  "videoKey": "<fileKey>",       // required
  "coverUrl": "<cover publicUrl>",
  "caption": "Adventure awaits!",// shorts use caption; long-form uses description
  "description": "...",
  "visibility": "public",        // public | private | unlisted
  "duration": 28,
  "tags": ["travel", "vlog"],
  "keywords": ["mountain"],
  "categories": ["60d5...","60d6..."],   // category ObjectIds
  "song": { "id": "...", "name": "Song", "artist": "Artist", "coverUrl": "..." },
  "allowComments": true,
  "channelId": "...",
  "location": { "name": "Goa", "lat": 15.3, "lng": 74.1 },
  "taggedUsers": ["..."],
  "isMatureContent": false,
  "isBrandPromotion": false,
  "brandPromotionLink": "https://...",   // required if isBrandPromotion
  "acceptBookingsOrEnquiries": false
}
```

Response:
```json
{ "message": "Video Uploaded Successfully", "videoId": "60d5...",
  "videoUrl": "...", "coverUrl": "...", "status": "processing" }
```

Notes:
- The backend verifies the S3 object actually exists; if not you get
  `400 "Uploaded video file is invalid or incomplete. Please re-upload."`.
- Arrays accept real JSON arrays (preferred) or JSON-encoded strings.

```dart
Future<String> registerVideo(Map<String, dynamic> payload) async {
  final r = await ApiClient.instance.dio.post('/videos/upload', data: payload);
  if (r.statusCode != 200 && r.statusCode != 201) throw ApiException.fromResponse(r);
  return r.data['videoId'] as String;
}
```

### Step 4 — poll for transcoding

The video starts `processing`. Poll until `published` (or `failed`). You can use
either the raw metadata endpoint or the owner channel feed with `status=all`.

```dart
Future<String> waitForPublish(String videoId,
    {Duration interval = const Duration(seconds: 5), int maxTries = 60}) async {
  for (var i = 0; i < maxTries; i++) {
    final r = await ApiClient.instance.dio.get('/videos/metadata/$videoId');
    final status = r.data['data']['status'] as String;   // ⚠️ this bumps views
    if (status == 'published' || status == 'failed') return status;
    await Future.delayed(interval);
  }
  return 'processing';
}
```
> Polling `/videos/metadata` inflates views. For an exact view count, prefer
> polling the owner channel feed (`/videos/channel/:id?status=all`) instead.

### Upload cooldown — `GET /videos/upload-status` 🔐

There is a **60-minute per-user upload cooldown**. Gate the upload button on it.

```json
// allowed
{ "canUpload": true, "message": "User can upload a new video" }
// blocked
{ "canUpload": false, "remainingCooldownSeconds": 1800,
  "lastUploadTime": "...", "nextUploadTime": "..." }
```

### Chunked upload (large files) — `POST /upload/chunk` 🔐

`multipart/form-data`, one request per chunk:

| Field | Notes |
|---|---|
| `chunk` | binary part (≤10 MB) |
| `uploadId` | a client-generated session id (stable across all chunks) |
| `chunkIndex` | 0-based |
| `totalChunks` | total count |
| `fileName` | original name |

The first chunk (`chunkIndex 0`) initiates the S3 multipart upload; the last
chunk (`totalChunks-1`) completes it **and triggers transcoding automatically**
(so you don't call `/videos/upload` afterward for this path). Middle chunks
return `{ "message":"Chunk stored", "partETag":"..." }`.

---

## 9. Video playback (HLS)

Prefer `transcodedUrls.master` (HLS `.m3u8`) — the player auto-switches quality
by bandwidth. Fall back to `videoUrl` (mp4) while `status == 'processing'`.

```dart
import 'package:video_player/video_player.dart';

class ReelPlayer extends StatefulWidget {
  final Video video;
  const ReelPlayer({super.key, required this.video});
  @override State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    final url = widget.video.playbackUrl;   // master m3u8 or mp4
    if (url != null) {
      _c = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          _c!..setLooping(true)..play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() { _c?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_c == null || !_c!.value.isInitialized) {
      // show cover as poster while buffering
      return widget.video.coverUrl != null
          ? Image.network(widget.video.coverUrl!, fit: BoxFit.cover)
          : const ColoredBox(color: Colors.black);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _c!.value.size.width, height: _c!.value.size.height,
        child: VideoPlayer(_c!)),
    );
  }
}
```

Reels feed tips:
- Use a vertical `PageView` + `VisibilityDetector` to play only the visible page.
- Preload the next 1–2 controllers for instant transitions (or use
  `better_player_plus`/`media_kit` which handle this better than `video_player`).
- Show `video.coverUrl` as the poster.
- Register a view (call `/videos/metadata/:id` once, or fire
  `POST /ott/interaction {type:"view"}`) when a reel actually starts playing —
  not on scroll-past.

---

## 10. Likes

All under `/likes`. `:id` is the **video** id.

| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| `POST` | `/likes/:id/like` | 🔐 | — | `{success, data:<like>}` (201) |
| `DELETE` | `/likes/:id/like` | 🔐 | — | `{success, data:{message:"Unliked"}}` |
| `GET` | `/likes/:id/like/status` | 🔐 | — | `{success, data:{liked:bool}}` |
| `POST` | `/likes/users/:userId/likes/status` | 🔓 | `{videoIds:[…]}` | map `{videoId: bool}` |
| `GET` | `/likes/:id/likes` | 🔓 | — | paginated likers (full video populated) |
| `GET` | `/likes/users/:userId/likes` | 🔓 | — | videos a user liked (paginated) |

The user is taken from the token — no body needed for like/unlike. Liking
increments `video.stats.likes`; unliking is a soft-delete and decrements it.

```dart
class LikesApi {
  final _dio = ApiClient.instance.dio;
  Future<void> like(String videoId)   => _dio.post('/likes/$videoId/like');
  Future<void> unlike(String videoId) => _dio.delete('/likes/$videoId/like');

  Future<bool> isLiked(String videoId) async {
    final r = await _dio.get('/likes/$videoId/like/status');
    return r.data['data']['liked'] as bool;
  }

  /// Hydrate like-state for a page of trending reels (which aren't personalized).
  Future<Map<String, bool>> batchStatus(String userId, List<String> ids) async {
    final r = await _dio.post('/likes/users/$userId/likes/status',
        data: {'videoIds': ids});
    return Map<String, bool>.from(r.data['data']);
  }
}
```

**Optimistic UI:** flip the heart immediately, call the API, revert on error.

---

## 11. Comments

All under `/comments`.

| Method | Path | Auth | Body | Notes |
|---|---|---|---|---|
| `POST` | `/comments` | 🔐 | `{videoId, content, parentId?}` | `parentId` makes it a reply; returns 201 |
| `GET` | `/comments/video/:videoId` | 🔐 | — | `?page&limit&parentOnly` |
| `PUT` | `/comments/:commentId` | 🔐 | `{content}` | author/admin |
| `DELETE` | `/comments/:commentId` | 🔐 | — | author, video owner, or admin (soft delete) |
| `POST` | `/comments/:commentId/like` | 🔐 | — | toggle like on a comment |
| `POST` | `/comments/:commentId/flag` | 🔐 | `{reason}` | report |
| `GET` | `/comments/flagged` | 👑 | — | moderation queue |

Comment object returned by the API (note the renamed fields):

```dart
class Comment {
  final String id;
  final String message;          // the text (server renames "content" → "message")
  final String timeAgo;          // e.g. "4d"
  final int likesCount;
  final bool isLiked;
  final int repliesCount;
  final Author createdBy;
  final List<Comment> replies;   // nested
  Comment({required this.id, required this.message, required this.timeAgo,
      required this.likesCount, required this.isLiked, required this.repliesCount,
      required this.createdBy, required this.replies});
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
    id: j['_id'].toString(),
    message: j['message'] ?? '',
    timeAgo: j['time_ago'] ?? '',
    likesCount: j['likes_count'] ?? 0,
    isLiked: j['isLiked'] ?? false,
    repliesCount: j['replies_count'] ?? 0,
    createdBy: Author.fromJson(j['created_by'] ?? const {'_id': ''}),
    replies: (j['replies'] as List?)?.map((e) => Comment.fromJson(e)).toList()
        ?? const [],
  );
}
```

```dart
class CommentsApi {
  final _dio = ApiClient.instance.dio;

  Future<Comment> add(String videoId, String content, {String? parentId}) async {
    final r = await _dio.post('/comments',
        data: {'videoId': videoId, 'content': content, 'parentId': parentId});
    return Comment.fromJson(r.data['data']);
  }

  Future<({List<Comment> items, Pagination page})> list(String videoId,
      {int page = 1, int limit = 20, bool parentOnly = false}) async {
    final r = await _dio.get('/comments/video/$videoId', queryParameters: {
      'page': page, 'limit': limit, 'parentOnly': parentOnly});
    final items = (r.data['data'] as List).map((e) => Comment.fromJson(e)).toList();
    return (items: items, page: Pagination.fromJson(r.data['pagination']));
  }

  Future<void> toggleLike(String id) => _dio.post('/comments/$id/like');
  Future<void> flag(String id, String reason) =>
      _dio.post('/comments/$id/flag', data: {'reason': reason});
  Future<void> delete(String id) => _dio.delete('/comments/$id');
}
```

Adding a top-level comment increments `video.stats.comments`; deleting decrements
it.

---

## 12. Share / deep links

Public (no auth) endpoints for share-landing pages — safe to open from a link
before the user logs in.

| Method | Path | Auth | Returns |
|---|---|---|---|
| `GET` | `/share/videos/:videoId` | 🔓 | feed envelope, single video |
| `GET` | `/share/videos` | 🔓 | feed envelope, list (`?limit=10`, max 50) |

`interactions.isLiked/isFollowing` are always `false` here (no user context).
Use this to render a share/preview screen, then deep-link into the real player.

```dart
Future<FeedItem?> getSharedVideo(String id) async {
  final r = await ApiClient.instance.dio.get('/share/videos/$id');
  final items = FeedResponse.fromEnvelope(r.data).items;
  return items.isEmpty ? null : items.first;
}
```

To **count** a share, fire `POST /ott/interaction {videoId, type:"share"}` (auth)
after a successful native share.

---

## 13. OTT — series, episodes & personalized feed

All under `/ott`. This is the long-form catalog: creators group videos into
**series** (seasons of **episodes**), submit them for **admin approval**, and
once approved + released they appear publicly.

### Personalization

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/ott/feed` | 🟡 | personalized if logged in; `?page&limit&category&sortBy=latest\|relevant` |
| `POST` | `/ott/interaction` | 🔐 | body `{videoId, type}` — `view`/`like`/`share`/`skip`/`complete` |

Fire-and-forget interactions as the user watches to improve recommendations:

```dart
Future<void> trackInteraction(String videoId, String type) async {
  // type: view | like | share | skip | complete
  try { await ApiClient.instance.dio.post('/ott/interaction',
      data: {'videoId': videoId, 'type': type}); } catch (_) {/* ignore */}
}
```

### Public catalog (viewer side)

| Method | Path | Auth | Returns |
|---|---|---|---|
| `GET` | `/ott/series` | 🔓 | released series (paginated); each has `videosCount` + `creator` |
| `GET` | `/ott/series/:id` | 🟡 | series detail with episodes (full video objects, `episodeNumber`) |
| `GET` | `/ott/channel/:id/content` | 🔓 | a channel's approved `series` + standalone `videos` |

`GET /ott/series/:id` returns episodes under `videos[]` where each entry is
`{ videoId, episodeNumber, _id: <full video object> }`. Sort by `episodeNumber`
and play `_id.transcodedUrls.master`.

```dart
class Series {
  final String id;
  final String title, description, thumbnail;
  final String status;          // draft | published
  final String approvalStatus;  // pending | approved | rejected
  final bool isReleased;
  final String? rejectionReason;
  final List<Episode> episodes;
  Series({required this.id, required this.title, required this.description,
      required this.thumbnail, required this.status, required this.approvalStatus,
      required this.isReleased, this.rejectionReason, required this.episodes});
  factory Series.fromJson(Map<String, dynamic> j) => Series(
    id: j['_id'].toString(), title: j['title'] ?? '',
    description: j['description'] ?? '', thumbnail: j['thumbnail'] ?? '',
    status: j['status'] ?? 'draft', approvalStatus: j['approvalStatus'] ?? 'pending',
    isReleased: j['isReleased'] ?? false, rejectionReason: j['rejectionReason'],
    episodes: (j['videos'] as List?)?.map((e) => Episode.fromJson(e)).toList()
        ?? const []);
}

class Episode {
  final int episodeNumber;
  final Video video;
  Episode({required this.episodeNumber, required this.video});
  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
    episodeNumber: j['episodeNumber'] ?? 0,
    // `_id` is the populated video object in series detail
    video: Video.fromJson(j['_id'] is Map ? j['_id'] : j));
}
```

### Creator side (manage your own catalog) 🔐

| Method | Path | Auth | Body | Notes |
|---|---|---|---|---|
| `GET` | `/ott/channel/videos` | 🔐 | — | your own videos eligible for series/submission |
| `GET` | `/ott/channel/draft-series` | 🔐 | — | your draft series |
| `GET` | `/ott/channel/:id/rejected-content` | 🔐 | — | your rejected series/videos (own only) |
| `POST` | `/ott/series` | 🔐 | `{title, description, thumbnail}` | creates a **draft** (201) |
| `PUT` | `/ott/series/:id` | 🔐 | `{title?, description?, thumbnail?, videos?}` | edit & **reorder** episodes |
| `DELETE` | `/ott/series/:id` | 🔐 | — | creator or admin; can't delete a released series |
| `POST` | `/ott/series/:id/add-episode` | 🔐 | `{videoId}` | append episode (auto episodeNumber) |
| `DELETE` | `/ott/series/:id/remove-episode` | 🔐 | `{videoId}` | remove & re-index |
| `PUT` | `/ott/series/:id/publish` | 🔐 | — | submit series for admin review |
| `PUT` | `/ott/video/:id/publish` | 🔐 | — | submit a standalone video for review |

Reorder by sending the full ordered `videos` array to `PUT /ott/series/:id`:
```json
{ "videos": [ {"videoId":"A"}, {"videoId":"C"}, {"videoId":"B"} ] }
```
`episodeNumber` is reassigned sequentially server-side.

**Creator lifecycle:** `creator_draft` → (`add to series` / `publish`) →
`submitted_for_review` (videos) or series `status:published`+`approvalStatus:pending`
→ admin approves → videos become `approved_published`, series `isReleased:true`.

### Admin moderation (OTT) 👑

| Method | Path | Body |
|---|---|---|
| `GET` | `/ott/admin/videos/pending` | — |
| `GET` | `/ott/admin/series/pending` | — |
| `PUT` | `/ott/admin/series/:id/approve` | — |
| `PUT` | `/ott/admin/series/:id/reject` | `{reason?}` |
| `PUT` | `/ott/admin/video/:id/approve` | — |
| `PUT` | `/ott/admin/video/:id/reject` | `{reason?}` |
| `GET` | `/ott/admin/rejected-content` | `?page&limit&channelId&userId` |

---

## 14. Songs & favorites

Music library for attaching audio to videos/reels.

### Songs — `/songs`

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/songs` | 🟡 | `?page&limit`; adds `is_favourite` when authed |
| `GET` | `/songs/search` | 🔓 | `?query&page&limit` (query required) |
| `GET` | `/songs/:songId` | 🟡 | adds `is_favourite` when authed |
| `POST` | `/songs` | 🔐 | `multipart/form-data` |
| `PUT` | `/songs/:songId` | 🔐 | uploader or admin; multipart |
| `DELETE` | `/songs/:songId` | 🔐 | uploader or admin |

Song object: `{ _id, name, artist, isGlobal, externalUrl (audio S3 URL),
coverUrl, duration, uploadedBy, is_favourite? }`.

Create (multipart): fields `name` (req), `artist` (req), `songFile` (req, audio
binary), optional `duration`, `isGlobal`, `coverImageFile` (binary) or `coverUrl`.

```dart
class Song {
  final String id;
  final String? name, artist, externalUrl, coverUrl;
  final int? duration;
  final bool isGlobal, isFavourite;
  Song({required this.id, this.name, this.artist, this.externalUrl, this.coverUrl,
      this.duration, this.isGlobal = false, this.isFavourite = false});
  factory Song.fromJson(Map<String, dynamic> j) => Song(
    id: j['_id'].toString(), name: j['name'], artist: j['artist'],
    externalUrl: j['externalUrl'], coverUrl: j['coverUrl'],
    duration: (j['duration'] as num?)?.toInt(),
    isGlobal: j['isGlobal'] ?? false, isFavourite: j['is_favourite'] ?? false);
}

Future<Song> uploadSong(File audio, {required String name, required String artist,
    File? cover, int? duration, bool isGlobal = false}) async {
  final form = FormData.fromMap({
    'name': name, 'artist': artist,
    if (duration != null) 'duration': duration,
    'isGlobal': isGlobal,
    'songFile': await MultipartFile.fromFile(audio.path),
    if (cover != null) 'coverImageFile': await MultipartFile.fromFile(cover.path),
  });
  final r = await ApiClient.instance.dio.post('/songs', data: form);
  return Song.fromJson(r.data['data']);
}
```

### Favorites — `/favorites` 🔐

| Method | Path | Body | Notes |
|---|---|---|---|
| `POST` | `/favorites` | `{songId}` | add (409 if already favorited) |
| `GET` | `/favorites` | — | `?page&limit`; `song` is populated |
| `GET` | `/favorites/search` | — | `?q&page&limit` |
| `GET` | `/favorites/check/:songId` | — | `{success, isFavorite:bool}` |
| `DELETE` | `/favorites/:songId` | — | remove |

---

## 15. Categories & titles

### Categories — `/categories`

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/categories` | 🔓 | public (non-admin) categories |
| `GET` | `/categories/:categoryId` | 🔓 | single |
| `GET` | `/categories/all` | 👑 | all (incl. admin) |
| `GET` | `/categories/admin` | 👑 | admin-only categories |
| `GET` | `/categories/admin/:categoryId` | 👑 | single admin category |
| `POST` | `/categories` | 👑 | `{name, description?, adminCategory?}` |
| `PUT` | `/categories/:categoryId` | 👑 | partial update |
| `DELETE` | `/categories/:categoryId` | 👑 | |

Category object: `{ _id, name, slug, description, adminCategory }`. Use these IDs
for the `categories` array on upload and for `/videos/category/:id`.
There is also `GET /videos/categories` (same data, no auth) if you prefer.

### Titles — `/titles`

Reusable text snippets / dynamic titles.

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/titles` | 🔓 | `?limit&page&sortBy&sortOrder&isActive` |
| `GET` | `/titles/:id` | 🔓 | single |
| `POST` | `/titles` | 🔐 | `{title, description?, isActive?}` |
| `PUT` | `/titles/:id` | 🔐 | partial |
| `DELETE` | `/titles/:id` | 🔐 | |

---

## 16. Admin videos (in-app banners/ads)

`/admin-videos` is a separate collection of **app-managed promo/welcome videos**
(multi-language), placed on specific screens. Reads are public — use them to show
a welcome/ad video for a screen.

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/admin-videos` | 🔓 | `?page&limit&category&screenPlacement&language&type&title` |
| `GET` | `/admin-videos/:id` | 🔓 | single |
| `GET` | `/admin-videos/screen/:screen` | 🔓 | videos for a screen placement |
| `POST` | `/admin-videos` | 🔐 | create |
| `PUT` | `/admin-videos/:id` | 🔐 | update |
| `DELETE` | `/admin-videos/:id` | 🔐 | delete |

Object: `{ _id, title, description, thumbnailUrl, videoUrls:[{language,url}],
screenPlacement, duration, type:"App Video"|"Ads Video" }`.

```dart
Future<List<Map<String, dynamic>>> adminVideosForScreen(String screen) async {
  final r = await ApiClient.instance.dio.get('/admin-videos/screen/$screen');
  return (r.data['data'] as List).cast<Map<String, dynamic>>();
}
```
Pick the `videoUrls` entry whose `language` matches the user's locale.

---

## 17. Admin dashboard & moderation

Only relevant if you build an **admin app**. All require an Admin/SubAdmin
account (👑). Franchise admins are auto-scoped by pincode.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/video-stats` | KPI cards: totals, success %, trends. `?start_date&end_date&filter_type=day\|week\|month\|year&video_type` |
| `GET` | `/admin/video-overview-chart` | 12-month chart. `?year&filter_type=all\|views\|likes\|comments&video_type` |
| `GET` | `/admin/video-details` | paginated reels list. `?limit&offset&start_date&end_date&search_query&category_id&sort_by&sort_order&video_type` |
| `GET` | `/admin/users/:userId/details` | a user's profile + their videos |
| `GET` | `/comments/flagged` | flagged-comment moderation queue |

Plus all the OTT admin endpoints in §13.

---

## 18. Health & demo endpoints

**Health** (`/health`) — 🔓, returns `200` healthy / `503` unhealthy:
`/health`, `/health/database`, `/health/redis`, `/health/kafka`. Useful for a
debug screen, not for app users.

**Demo** (`/demo`) — 🔓 mock data (channels, categories, playlists, videos) for
prototyping UI before real data exists. In-memory; resets on restart. Don't ship
against these.

---

## 19. Error handling

Errors are JSON. Most carry a `message`; the global handler wraps unexpected
errors as `{ "error": { "message": "..." } }`.

| Status | Meaning | Action |
|---|---|---|
| `400` | Bad input (invalid ObjectId, missing field, bad `type`) | show validation msg |
| `401` | Missing/expired/invalid token | force re-auth |
| `403` | Not owner / no access to private video / not admin | hide action |
| `404` | Not found | show empty state |
| `409` | Conflict (duplicate favorite/category/flag) | treat as already-done |
| `500` | Server error | retry / report |

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  factory ApiException.fromResponse(Response r) {
    final d = r.data;
    final msg = d is Map
        ? (d['message'] ?? d['error']?['message'] ?? 'Request failed').toString()
        : 'Request failed';
    return ApiException(r.statusCode ?? 0, msg);
  }
  @override String toString() => 'ApiException($statusCode): $message';
}

// Wrap calls:
Future<T> guard<T>(Future<Response> Function() call, T Function(Response) ok) async {
  try {
    final r = await call();
    if (r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300) {
      return ok(r);
    }
    throw ApiException.fromResponse(r);
  } on DioException catch (e) {
    if (e.response != null) throw ApiException.fromResponse(e.response!);
    throw ApiException(0, e.message ?? 'Network error');
  }
}
```

### Pagination pattern (infinite scroll)

```dart
class FeedPager {
  final String path;
  final Map<String, dynamic> baseQuery;
  int _page = 1;
  bool hasMore = true;
  bool _loading = false;
  FeedPager(this.path, {this.baseQuery = const {}});

  Future<List<FeedItem>> next({int limit = 20}) async {
    if (_loading || !hasMore) return [];
    _loading = true;
    try {
      final res = await getFeed(path,
          query: {...baseQuery, 'page': _page, 'limit': limit});
      hasMore = res.pagination.hasMore;
      _page++;
      return res.items;
    } finally { _loading = false; }
  }
}
```

---

## 20. Full endpoint reference

🔓 none · 🟡 optional · 🔐 required · 👑 admin

### Videos `/videos`
| Method | Path | Auth |
|---|---|---|
| GET | `/videos/hot/:type` | 🔓 |
| GET | `/videos/search` | 🟡 |
| GET | `/videos/category/:categoryId` | 🟡 |
| GET | `/videos/categories` | 🔓 |
| GET | `/videos/metadata/:videoId` (⚠️ +view) | 🟡 |
| GET | `/videos/:videoId` | 🔐 |
| GET | `/videos/channel/:channelId` | 🔐 |
| GET | `/videos/users/:userId/videos` | 🔐 |
| POST | `/videos/upload` | 🔐 |
| PUT | `/videos/:videoId` | 🔐 |
| DELETE | `/videos/:videoId` | 🔐 |
| GET | `/videos/upload-status` | 🔐 |
| POST | `/videos/batch-prepare` | 🔐 |
| GET | `/videos/health/redis` | 🔓 |

### Upload `/upload`
| Method | Path | Auth |
|---|---|---|
| GET | `/upload/init` | 🔓 |
| POST | `/upload/chunk` | 🔐 |

### Likes `/likes`
| Method | Path | Auth |
|---|---|---|
| POST | `/likes/:id/like` | 🔐 |
| DELETE | `/likes/:id/like` | 🔐 |
| GET | `/likes/:id/like/status` | 🔐 |
| POST | `/likes/users/:userId/likes/status` | 🔓 |
| GET | `/likes/:id/likes` | 🔓 |
| GET | `/likes/users/:userId/likes` | 🔓 |

### Comments `/comments`
| Method | Path | Auth |
|---|---|---|
| POST | `/comments` | 🔐 |
| GET | `/comments/video/:videoId` | 🔐 |
| PUT | `/comments/:commentId` | 🔐 |
| DELETE | `/comments/:commentId` | 🔐 |
| POST | `/comments/:commentId/like` | 🔐 |
| POST | `/comments/:commentId/flag` | 🔐 |
| GET | `/comments/flagged` | 👑 |

### Share `/share`
| Method | Path | Auth |
|---|---|---|
| GET | `/share/videos/:videoId` | 🔓 |
| GET | `/share/videos` | 🔓 |

### OTT `/ott`
| Method | Path | Auth |
|---|---|---|
| GET | `/ott/feed` | 🟡 |
| POST | `/ott/interaction` | 🔐 |
| GET | `/ott/channel/videos` | 🔐 |
| GET | `/ott/channel/draft-series` | 🔐 |
| GET | `/ott/channel/:id/content` | 🔓 |
| GET | `/ott/channel/:id/rejected-content` | 🔐 |
| POST | `/ott/series` | 🔐 |
| GET | `/ott/series` | 🔓 |
| GET | `/ott/series/:id` | 🟡 |
| PUT | `/ott/series/:id` | 🔐 |
| DELETE | `/ott/series/:id` | 🔐 |
| POST | `/ott/series/:id/add-episode` | 🔐 |
| DELETE | `/ott/series/:id/remove-episode` | 🔐 |
| PUT | `/ott/series/:id/publish` | 🔐 |
| PUT | `/ott/video/:id/publish` | 🔐 |
| GET | `/ott/admin/videos/pending` | 👑 |
| GET | `/ott/admin/series/pending` | 👑 |
| PUT | `/ott/admin/series/:id/approve` | 👑 |
| PUT | `/ott/admin/series/:id/reject` | 👑 |
| PUT | `/ott/admin/video/:id/approve` | 👑 |
| PUT | `/ott/admin/video/:id/reject` | 👑 |
| GET | `/ott/admin/rejected-content` | 👑 |

### Songs `/songs` · Favorites `/favorites`
| Method | Path | Auth |
|---|---|---|
| GET | `/songs` | 🟡 |
| GET | `/songs/search` | 🔓 |
| GET | `/songs/:songId` | 🟡 |
| POST | `/songs` | 🔐 |
| PUT | `/songs/:songId` | 🔐 |
| DELETE | `/songs/:songId` | 🔐 |
| POST | `/favorites` | 🔐 |
| GET | `/favorites` | 🔐 |
| GET | `/favorites/search` | 🔐 |
| GET | `/favorites/check/:songId` | 🔐 |
| DELETE | `/favorites/:songId` | 🔐 |

### Categories `/categories` · Titles `/titles`
| Method | Path | Auth |
|---|---|---|
| GET | `/categories` | 🔓 |
| GET | `/categories/:categoryId` | 🔓 |
| GET | `/categories/all` | 👑 |
| GET | `/categories/admin` | 👑 |
| GET | `/categories/admin/:categoryId` | 👑 |
| POST | `/categories` | 👑 |
| PUT | `/categories/:categoryId` | 👑 |
| DELETE | `/categories/:categoryId` | 👑 |
| GET | `/titles` | 🔓 |
| GET | `/titles/:id` | 🔓 |
| POST | `/titles` | 🔐 |
| PUT | `/titles/:id` | 🔐 |
| DELETE | `/titles/:id` | 🔐 |

### Admin videos `/admin-videos` · Admin dashboard `/admin`
| Method | Path | Auth |
|---|---|---|
| GET | `/admin-videos` | 🔓 |
| GET | `/admin-videos/:id` | 🔓 |
| GET | `/admin-videos/screen/:screen` | 🔓 |
| POST | `/admin-videos` | 🔐 |
| PUT | `/admin-videos/:id` | 🔐 |
| DELETE | `/admin-videos/:id` | 🔐 |
| GET | `/admin/video-stats` | 👑 |
| GET | `/admin/video-overview-chart` | 👑 |
| GET | `/admin/video-details` | 👑 |
| GET | `/admin/users/:userId/details` | 👑 |

### Auth / health / demo
| Method | Path | Auth |
|---|---|---|
| GET | `/auth/session-validation/status` | 🔓 |
| PUT | `/auth/session-validation/toggle` | 🔓 |
| GET | `/health` · `/health/database` · `/health/redis` · `/health/kafka` | 🔓 |
| GET | `/demo/*` (mock data) | 🔓 |

> Interactive API docs (Swagger): `GET /api-docs`.
