# Video Prefetch — Frontend Integration Guide

How to use the `prefetch` field on feed items to get **instant video start** and
**Instagram-style offline playback** (already-fetched reels keep playing when the
network drops).

> **TL;DR** — The backend now tells you *what to download ahead of time* via a
> `prefetch` object on every feed item. Your job is to download the upcoming
> items **before** the user scrolls to them and play from the local cache.

---

## 1. Where it comes from

The `prefetch` object is attached to **every item** in all playback feeds:

| Endpoint | Feed |
|----------|------|
| `GET /hot/:type` | Hot / trending reels |
| `GET /channel/:channelId` | Channel feed |
| `GET /users/:userId/videos` | User's videos |
| `GET /category/:categoryId` | Category feed |
| `GET /search` | Search results |

No new endpoint, no new request params — it's an **additive field** on the feed
items you already consume. If you ignore it, nothing breaks.

---

## 2. The shape

```jsonc
{
  "videoId": "60d5f9b8b60e4661d8f0a1b2",
  "position": 3,
  "video": { /* ...full video object as before... */ },
  "author": { /* ... */ },
  "channel": { /* ... */ },

  "prefetch": {
    "hlsUrl":         "https://cdn.example.com/videos/abc/master.m3u8",  // adaptive stream (nullable)
    "lowVariantUrl":  "https://cdn.example.com/videos/abc/360p.m3u8",    // lightest ladder (nullable)
    "progressiveUrl": "https://cdn.example.com/videos/abc/video.mp4",    // MP4 fallback (nullable)
    "poster":         "https://cdn.example.com/videos/abc/thumb_low.jpg",// show instantly (nullable)
    "duration":       42,                                                // seconds
    "type":           "hls"                                             // "hls" | "mp4"
  }
}
```

### Field meaning

| Field | Use it for |
|-------|-----------|
| `hlsUrl` | **Primary playback + prefetch URL.** Adaptive HLS master. The player starts almost instantly and caches TS segments to disk as they download. Use this when `type == "hls"`. |
| `lowVariantUrl` | The **lightest** bitrate ladder. Prefetch *this* (not the master) when you want the cheapest possible ahead-of-time download on mobile data. |
| `progressiveUrl` | Original MP4. **Fallback only** — use when `hlsUrl` is `null` (transcoding not finished) or the player can't do HLS. |
| `poster` | Thumbnail to render on the video surface immediately while bytes are still downloading. Eliminates the black/blank frame. |
| `duration` | Decide how much to prefetch, show a progress bar, budget cache size. |
| `type` | `"hls"` → use `hlsUrl`/`lowVariantUrl`. `"mp4"` → use `progressiveUrl`. |

> **Any field can be `null`** (e.g. a freshly uploaded video still transcoding).
> Always null-check and fall back down the chain:
> `hlsUrl → lowVariantUrl → progressiveUrl`.

---

## 3. Recommended strategy

### Prefetch window
While the user watches item **N**, prefetch items **N+1** and **N+2** (tune to
2–3 ahead). Don't prefetch the whole feed — it wastes the user's data and your
cache budget.

```
[ N-1 played ]  [ N playing ]  [ N+1 prefetching ]  [ N+2 prefetching ]  [ N+3 idle ]
```

### What to download per upcoming item
- **HLS (`type == "hls"`):** hand `hlsUrl` to a **caching player** (see §4). To
  cap data usage, prefetch only the **first few seconds** — enough for an instant
  start — rather than the whole video. Pin the low ladder with `lowVariantUrl`
  when the user is on cellular.
- **MP4 (`type == "mp4"`):** download `progressiveUrl` to a file in your cache
  directory; play from that file.

### Trigger prefetch of the *next page* early
Each feed response includes `pagination.hasMore`. Request the next page when the
user is ~3 items from the end so the prefetch pipeline never runs dry.

### Respect the network
- On **Wi‑Fi**: prefetch normally (2–3 ahead).
- On **cellular / data-saver**: prefetch 1 ahead and prefer `lowVariantUrl`.
- On **no network**: play whatever is already cached; show a graceful "offline"
  state when you reach an un-cached item.

### Cache eviction
Keep an LRU cache (e.g. 300–500 MB or last ~20 reels). Evict oldest first. Use
`duration` to estimate sizes if you cap by total size.

---

## 4. Flutter reference (video_player + a caching HTTP layer)

The key is a **caching proxy/data-source** so playback reads from disk on repeat
and works offline. Common options: `flutter_cache_manager` (progressive files) or
an HLS-capable caching player (e.g. `better_player` with cache enabled, or a
platform ExoPlayer/AVPlayer cache).

### 4a. Prefetch the lightest bytes for upcoming items

```dart
final cacheManager = DefaultCacheManager();

Future<void> prefetchUpcoming(List<FeedItem> items, int currentIndex) async {
  for (var i = currentIndex + 1; i <= currentIndex + 2 && i < items.length; i++) {
    final p = items[i].prefetch;
    if (p == null) continue;

    // Pick the cheapest playable URL.
    final url = p.type == 'hls'
        ? (p.lowVariantUrl ?? p.hlsUrl ?? p.progressiveUrl)
        : (p.progressiveUrl ?? p.hlsUrl);
    if (url == null) continue;

    // Warm the poster too, so the first frame is instant.
    if (p.poster != null) {
      unawaited(cacheManager.downloadFile(p.poster!));
    }

    // For MP4 this caches the whole file. For HLS, prefer a caching player
    // that fetches only the first segments (see 4b) instead of the full file.
    unawaited(cacheManager.downloadFile(url));
  }
}
```

### 4b. Play from cache (offline-capable)

```dart
Future<VideoPlayerController> buildController(Prefetch p) async {
  if (p.type == 'hls' && p.hlsUrl != null) {
    // Use a player configured with an on-disk HLS cache (ExoPlayer/AVPlayer).
    // On replay or offline, it serves cached segments automatically.
    return VideoPlayerController.networkUrl(Uri.parse(p.hlsUrl!));
  }

  // MP4 path: if we already cached the file, play the local copy (works offline).
  final url = p.progressiveUrl;
  final fileInfo = url != null
      ? await DefaultCacheManager().getFileFromCache(url)
      : null;

  if (fileInfo != null) {
    return VideoPlayerController.file(fileInfo.file); // offline
  }
  return VideoPlayerController.networkUrl(Uri.parse(url!)); // online fallback
}
```

> **Offline reality check:** a video plays offline **only if it was prefetched
> while online**. Once the user scrolls to an item that was never downloaded,
> playback stops — that's expected (Instagram behaves the same). Show a poster +
> "You're offline" placeholder for un-cached items.

---

## 5. Android / iOS native notes

- **Android (ExoPlayer):** use `CacheDataSource` with a `SimpleCache`
  (`LeastRecentlyUsedCacheEvictor`) wrapping the HLS media source. Prefetch with
  a `CacheWriter`/`DownloadService` limited to the first N seconds.
- **iOS (AVPlayer):** use `AVAssetDownloadTask` / `AVAssetDownloadURLSession` to
  persist HLS for offline; for lightweight prefetch, preroll with a short
  `preferredForwardBufferDuration`.

---

## 6. Edge cases & rules

1. **Always null-check** every `prefetch` field — treat `prefetch` itself as
   possibly `null` for very new items.
2. **Fallback order:** `hlsUrl → lowVariantUrl → progressiveUrl`. If all are
   `null`, skip prefetch for that item and just show the poster.
3. **Don't prefetch what's already cached** — check the cache before downloading.
4. **Cancel prefetch** for items the user scrolled past without watching, to save
   data.
5. **`progressiveUrl` is the original upload** — larger and not adaptive. Prefer
   HLS whenever `hlsUrl` is present.

---

## 7. What the backend does *not* do

- The backend does **not** store or stream video bytes through the API — media is
  served from the CDN (S3/CloudFront). Prefetch/caching happens entirely on the
  device.
- Long-lived CDN cache headers on the immutable `.ts`/`.m3u8` files are an infra
  concern (S3/CloudFront), handled separately from this guide.

---

## 8. Quick checklist for the frontend

- [ ] Read `prefetch` from each feed item.
- [ ] Prefetch items N+1..N+2 using the cheapest available URL + poster.
- [ ] Use a caching player/data-source so playback reads from disk.
- [ ] Request the next page when ~3 items from the end (`pagination.hasMore`).
- [ ] Throttle prefetch on cellular / data-saver.
- [ ] LRU-evict the on-disk cache.
- [ ] Show poster + offline placeholder for un-cached items.
