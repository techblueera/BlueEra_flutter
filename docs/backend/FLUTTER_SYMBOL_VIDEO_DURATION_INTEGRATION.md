# Flutter Integration: Symbol Video Duration (`media_duration`)

## Overview

Video symbols currently display **0:00** instead of their real length.

The cause is simple: **the symbols backend never stored a duration.** It only stores the S3 URL you send in `content`. Nothing in the backend reads the video bytes — there is no `ffprobe`/`ffmpeg` anywhere in the stack — so the server has no way to know how long a clip is.

The backend now accepts a `media_duration` field on symbol creation. **The app is the only component that knows the duration, so this bug is not fixed until the app starts sending it.** A backend deploy alone changes nothing.

---

## The Contract

| Field | Type | Unit | Required | Applies to |
|-------|------|------|----------|------------|
| `media_duration` | number | **seconds** | Strongly recommended | `type: 'video'` only |

Rules:

- **Seconds, not milliseconds.** `27.5` means 27½ seconds. This matches the video-service's existing `duration` field so both services agree.
- Fractional values are fine and preferred (`27.5`, not `27`).
- Range is clamped to `0`–`28800` server-side. Out-of-range, negative, `null`, and non-numeric values all collapse to `0`.
- **Omitting it stores `0`, which renders as 0:00 — the exact bug we are fixing.**
- Ignored for `photo` / `text` / `embeddedUrl` symbols (always stored as `0`).
- ⚠️ **Not to be confused with `duration_days`**, which is the pre-existing field controlling how long the symbol stays *visible* (1–7 days). Unrelated. Different unit, different meaning.

---

## Request

```
POST /symbols
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "type": "video",
  "content": "https://my-bucket.s3.ap-south-1.amazonaws.com/uploads/1758209730553-71cde5e0.mp4",
  "media_duration": 27.5,
  "caption": "Sunset drive",
  "duration_days": 1,
  "visibility": "public"
}
```

## Response

`media_duration` is echoed on create and included on **every** symbol read path — the feed, single-symbol detail, and user-symbol lists — with no extra query params needed.

```json
{
  "_id": "60d0fe4f5311236168a109ca",
  "user_id": "60d0fe4f5311236168a109cb",
  "type": "video",
  "content": "https://my-bucket.s3.ap-south-1.amazonaws.com/uploads/1758209730553-71cde5e0.mp4",
  "media_duration": 27.5,
  "caption": "Sunset drive",
  "expires_at": "2026-07-17T10:30:00.000Z",
  "visibility": "public",
  "likes_count": 0,
  "comments_count": 0,
  "seen_count": 0,
  "created_at": "2026-07-16T10:30:00.000Z"
}
```

---

## Reading the Duration in Flutter

Read it from the **local file** before uploading. Don't try to read it back off the S3 URL — that's a needless network round-trip and it's exactly the read that's unreliable today.

### Option A — `video_player` (preferred if already a dependency)

```dart
import 'dart:io';
import 'package:video_player/video_player.dart';

/// Returns playback length in SECONDS, or null if it can't be determined.
Future<double?> readVideoDurationSeconds(File file) async {
  final controller = VideoPlayerController.file(file);
  try {
    await controller.initialize();
    final d = controller.value.duration;
    if (d == Duration.zero) return null;
    // inMilliseconds / 1000 — NOT `d.inSeconds`, which truncates 27.9s to 27.
    return d.inMilliseconds / 1000.0;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose(); // must dispose or the controller leaks
  }
}
```

### Option B — `video_compress` (if you already compress before upload)

```dart
import 'package:video_compress/video_compress.dart';

Future<double?> readVideoDurationSeconds(String path) async {
  final info = await VideoCompress.getMediaInfo(path);
  final ms = info.duration;              // milliseconds, as a double
  if (ms == null || ms <= 0) return null;
  return ms / 1000.0;
}
```

> If you compress or transcode before uploading, read the duration from the **final file you actually upload**, not the original. Compression can alter length slightly.

### Sending it

```dart
Future<Symbol> createVideoSymbol({
  required File videoFile,
  required String s3Url,
  String? caption,
  int durationDays = 1,
}) async {
  final seconds = await readVideoDurationSeconds(videoFile);

  final body = <String, dynamic>{
    'type': 'video',
    'content': s3Url,
    'caption': caption,
    'duration_days': durationDays,      // visibility window — unrelated
    if (seconds != null) 'media_duration': seconds,
  };

  final res = await dio.post('/symbols', data: body);
  return Symbol.fromJson(res.data);
}
```

### Rendering it

```dart
String formatDuration(num seconds) {
  final total = seconds.round();
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
```

Model parsing — note `media_duration` may arrive as `int` or `double`, so parse defensively:

```dart
class Symbol {
  final double mediaDuration; // seconds; 0 for non-video or legacy symbols

  factory Symbol.fromJson(Map<String, dynamic> json) => Symbol(
    mediaDuration: (json['media_duration'] as num?)?.toDouble() ?? 0,
    // ...
  );

  bool get hasKnownDuration => mediaDuration > 0;
}
```

**Render the label from `media_duration`, not from the player's metadata callback.** The field is available the instant the feed loads, before any video is buffered — so the duration badge can paint immediately instead of popping in late.

---

## Two Things That Will Still Break 0:00 (Please Fix These Too)

Storing the duration fixes the **label**. It does not fix the **player**. The seek bar, scrubbing, and progress indicator all depend on the player parsing the media itself. Both of the following will keep those broken even with a correct `media_duration`:

### 1. Content-Type on the S3 upload

The presigned URL is **signed with `ContentType`** — if the header on your `PUT` doesn't match the `fileType` you requested at presign time, the upload is rejected by S3 outright.

Worse, if you declare a lazy `application/octet-stream`, S3 will serve the object with that type and players cannot read metadata from it.

```dart
// at presign time
final res = await dio.get('/upload/init', queryParameters: {
  'fileName': 'clip.mp4',
  'fileType': 'video/mp4',        // ← real MIME type
});

// on the PUT — header MUST match the fileType above exactly
await dio.put(
  res.data['uploadUrl'],
  data: fileStream,
  options: Options(headers: {'Content-Type': 'video/mp4'}),  // ← must match
);
```

### 2. Faststart (moov atom placement)

**Nothing in the backend remuxes your file.** Whatever you upload is served back byte-for-byte.

If the MP4's `moov` atom sits at the end of the file, a player must download the *entire* video before it knows the duration — which is a classic cause of a 0:00 readout and a dead scrub bar on slow connections. Export with faststart (moov at the front) so metadata is in the first few KB.

If you use `video_compress`, its output is generally already faststart-ordered. If you're writing the file yourself, verify it.

---

## ❓ Open Question — Please Confirm

**Which presign endpoint are symbol videos currently uploading through?**

The symbols service does **not** expose one. It only has a delete helper, and that helper is scoped to the symbols bucket (`AWS_S3_BUCKET_NAME_POST_SERVICE`).

If the app is reusing the **video service's** `GET /upload/init`, those files land in a *different* bucket (`AWS_S3_BUCKET_NAME_VIDEO_SERVICE`). In that case every symbol deletion silently does nothing and the media orphans in S3 forever. We need to know which endpoint you're calling to decide whether symbols needs its own presign route.

---

## Rollout & Backward Compatibility

The change is **purely additive** — the backend is already safe to deploy:

- Old app versions that don't send `media_duration` behave exactly as they do today (field stores `0`). Nothing breaks, no forced app update.
- No data migration is needed. Symbols expire within 7 days maximum (TTL), so the backlog of `0`-duration symbols clears itself automatically once the app ships.
- Bad input can't fail a request — every unusable value clamps to `0` rather than erroring.

**Planned follow-up:** once the app version sending `media_duration` has adequate adoption, we intend to make it **required for `type: 'video'` (HTTP 400 if missing)**. Silently defaulting to `0` is what let this bug go unnoticed in the first place. Please flag if that creates a problem for your release timeline.

---

## Testing Checklist

- [ ] Post a video symbol → response contains a non-zero `media_duration`
- [ ] Duration badge in the feed matches the actual clip length
- [ ] A long clip (> 1 min) formats correctly (e.g. `1:23`, not `83`)
- [ ] A sub-second/short clip doesn't display as `0:00`
- [ ] `media_duration` survives a reload — check the feed response, not just the create response
- [ ] Photo/text symbols still post fine (field absent or `0`)
- [ ] Uploaded object's `Content-Type` in S3 is `video/mp4` (verify in the S3 console or via `curl -I <url>`)
- [ ] Video seeks/scrubs correctly, not just displays the right label

---

## Questions

Backend contact: symbols service. Related: `FLUTTER_SYMBOL_LIKES_VIEWS_IMPLEMENTATION.md`.
