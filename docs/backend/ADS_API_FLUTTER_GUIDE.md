# Promo ads API — Flutter integration guide

**Service:** `be_other_service`
**Endpoint:** `GET https://be.beapp.in/api/other-service/ads`
**Auth:** none — no token, no headers
**Audience:** Flutter app team

One request returns every promo image the app can show, grouped by the slot it
fits, plus the notification copy in English and Hindi.

This replaces hardcoded image assets. Same artwork, served from the backend, so
a campaign can be swapped, paused or reordered **without an app release**.

---

## The one idea you need

> **A placement is a pixel size. Everything returned under a placement fits that
> slot exactly.**

The artwork is drawn per size, not scaled from one master. So you never pick an
image and hope it fits — you ask for the slot you are filling, and every
creative you get back is that slot's exact dimensions.

```
placements["home_hero"]  →  900x506, always
placements["banner_strip"] → 320x50, always
```

That is the whole mental model. No aspect-ratio guessing, no cropping.

---

## The 13 placements

| Key | Size | Ratio | Where it goes |
|---|---|---|---|
| `banner_strip` | 320×50 | 6.40 | thin sticky bar above the bottom nav |
| `inline_rect` | 300×250 | 1.20 | rectangle between feed items |
| `promo_wide` | 400×200 | 2.00 | small wide promo, half-width card |
| `promo_card` | 500×300 | 1.67 | standard card in a vertical list |
| `tile` | 708×474 | 1.49 | grid tile, e.g. two-column category grid |
| `home_hero` | 900×506 | 1.78 | full-width hero / carousel slide |
| `wide_strip` | 1200×470 | 2.55 | full-width strip between home sections |
| `video_thumb` | 1280×720 | 1.78 | 16:9 video-style card |
| `square_post` | 1080×1080 | 1.00 | square social-style post |
| `interstitial_portrait` | 360×640 | 0.56 | full-screen portrait |
| `interstitial_landscape` | 800×480 | 1.67 | full-screen landscape |
| `icon_large` | 512×512 | 1.00 | large icon / promo avatar |
| `icon_small` | 200×200 | 1.00 | small thumbnail in a dense list |

**121 creatives live today**, 7 per placement (21 for `home_hero`, 23 for
`icon_small`).

---

## The response

```http
GET /api/other-service/ads
```

```json
{
  "success": true,
  "version": "121-1788265566405",
  "generatedAt": "2026-09-01T12:26:06.405Z",
  "totalCreatives": 121,

  "placements": {
    "home_hero": {
      "width": 900,
      "height": 506,
      "aspectRatio": 1.7787,
      "description": "Full-width hero or carousel slide on the home screen.",
      "creatives": [
        {
          "id": "6a96c4536a7d77f8116c1230",
          "url": "https://blu-other-bck.s3.ap-south-1.amazonaws.com/ads/creatives/home_hero/1.png",
          "width": 900,
          "height": 506,
          "format": "png",
          "bytes": 53671,
          "campaign": "generic",
          "campaignLabel": "General",
          "targetUrl": null
        }
      ]
    },
    "banner_strip": { "...": "..." }
  },

  "notifications": [
    {
      "id": 1,
      "en": { "title": "Play & Win Coins Daily.",
              "body": "Come play Cricket contests running for 50,000 Coins daily." },
      "hi": { "title": "रोज़ खेलें और कॉइन्स जीतें",
              "body": "हर रोज 50,000 कॉइन के लिए चल रहे क्रिकेट कॉन्टेस्ट खेलें" }
    }
  ]
}
```

### Fields that matter

| Field | Use it for |
|---|---|
| `placements[key].width/height/aspectRatio` | **reserve layout space before the image loads** — otherwise the feed jumps as each one arrives |
| `creatives[].url` | the image. Load it directly, it is public |
| `creatives[].targetUrl` | where a tap goes. **`null` = decorative — render with no tap target**, do not invent a destination |
| `creatives[].campaign` | show one campaign consistently across screens instead of a different quiz in every slot |
| `version` | cache key — unchanged means nothing changed, skip the refetch |

---

## Minimal integration

**1 — model**

```dart
class AdCreative {
  final String id, url, format, campaign, campaignLabel;
  final int width, height;
  final String? targetUrl;
  const AdCreative({ required this.id, required this.url, required this.format,
    required this.campaign, required this.campaignLabel,
    required this.width, required this.height, this.targetUrl });

  factory AdCreative.fromJson(Map j) => AdCreative(
    id: j['id'], url: j['url'], format: j['format'],
    campaign: j['campaign'] ?? 'generic',
    campaignLabel: j['campaignLabel'] ?? 'General',
    width: j['width'], height: j['height'],
    targetUrl: j['targetUrl'],
  );
}

class AdPlacement {
  final int width, height;
  final double aspectRatio;
  final List<AdCreative> creatives;
  const AdPlacement({ required this.width, required this.height,
    required this.aspectRatio, required this.creatives });

  factory AdPlacement.fromJson(Map j) => AdPlacement(
    width: j['width'], height: j['height'],
    aspectRatio: (j['aspectRatio'] as num).toDouble(),
    creatives: (j['creatives'] as List).map((c) => AdCreative.fromJson(c)).toList(),
  );
}
```

**2 — fetch once, keep it**

```dart
class AdsService {
  static Map<String, AdPlacement> _placements = {};
  static List<dynamic> notifications = [];

  static Future<void> load() async {
    try {
      final r = await ApiBaseHelper().getHTTP('other-service/ads');
      if (!r.isSuccess) return;                 // keep whatever we had
      final body = r.response?.data;
      _placements = (body['placements'] as Map).map(
        (k, v) => MapEntry(k as String, AdPlacement.fromJson(v)));
      notifications = body['notifications'] ?? [];
    } catch (_) {
      // Ads are decorative. Never let this break a screen.
    }
  }

  static AdPlacement? of(String key) => _placements[key];

  /// One creative for a slot. Rotates so the same image is not always first.
  static AdCreative? pick(String key, {int? index}) {
    final p = _placements[key];
    if (p == null || p.creatives.isEmpty) return null;
    final i = index ?? Random().nextInt(p.creatives.length);
    return p.creatives[i % p.creatives.length];
  }
}
```

Call `AdsService.load()` once at startup (splash or first home build). It needs
no token, so it can run before login.

**3 — render**

```dart
Widget adSlot(String placementKey) {
  final p = AdsService.of(placementKey);
  final c = AdsService.pick(placementKey);
  if (p == null || c == null) return const SizedBox.shrink();   // ← no ads, no gap

  return AspectRatio(
    aspectRatio: p.aspectRatio,        // space reserved BEFORE the image loads
    child: GestureDetector(
      onTap: c.targetUrl == null ? null : () => launchUrl(Uri.parse(c.targetUrl!)),
      child: CachedNetworkImage(
        imageUrl: c.url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey.shade200),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      ),
    ),
  );
}
```

Usage:

```dart
adSlot('home_hero')       // carousel slide
adSlot('banner_strip')    // above bottom nav
adSlot('inline_rect')     // between feed items
```

---

## Filters

Fetch everything once and filter client-side for normal use. These exist for
when you genuinely want less:

| Query | Effect |
|---|---|
| `?placement=home_hero` | only that slot |
| `?campaign=cricket_quiz` | only that campaign, across every slot |
| `?limit=3` | at most 3 creatives per placement |

```
GET /api/other-service/ads?placement=home_hero&limit=5
```

**Campaigns:** `cricket_quiz`, `ipl_quiz`, `gk_quiz`, `history_quiz`,
`tech_quiz`, `tech_skills`, `play_quizzes`, `generic`.

To run one campaign everywhere for a week, fetch with `?campaign=ipl_quiz` and
every slot fills from that campaign.

---

## Notifications

24 entries, each carrying **both** languages, so picking by `id` cannot pair an
English title with a Hindi body:

```dart
final n = AdsService.notifications[i];
final lang = isHindi ? 'hi' : 'en';
final title = n[lang]['title'];
final body  = n[lang]['body'];
```

These are copy only — the API does not send pushes. Use them with whatever
notification scheduler you already have.

---

## Rules

- **`targetUrl: null` means no tap target.** Most creatives are decorative
  today. Do not wire a tap to nothing, and do not substitute a guessed URL.
- **Reserve space with `aspectRatio` before loading.** Every slot's size is in
  the response for exactly this reason; without it the feed jumps.
- **A missing placement is not an error.** `SizedBox.shrink()`. A slot with no
  creative should collapse, never leave a grey box.
- **Never block a screen on this call.** It is decorative — if it fails, render
  the screen without ads. The endpoint returns `200` with an empty `placements`
  even on a server fault, precisely so you do not need an error branch.
- **Cache on `version`.** It changes only when creatives change. Refetching on
  every home build wastes bandwidth for a payload that changes weekly.
- **Do not send a token.** The endpoint ignores it. It is public so the splash
  can prefetch before login.

---

## Testing

```bash
curl -s "https://be.beapp.in/api/other-service/ads" | jq '.totalCreatives, (.placements|keys)'
curl -s "https://be.beapp.in/api/other-service/ads?placement=home_hero&limit=2" | jq
```

Verified live at the time of writing: **121 creatives across 13 placements**,
all image URLs returning `200` with the right `content-type`, and 24
notification pairs.

---

## What is NOT in this API

- **No tracking.** No impression or click reporting. If ad performance needs
  measuring, that is a separate endpoint and a deliberate decision — say so and
  it can be added.
- **No targeting.** Everyone gets the same bundle. No per-user, per-city or
  per-language selection of creatives.
- **No scheduling in use yet.** The model supports `startsAt` / `endsAt` and an
  `isActive` switch, but every creative is currently always-on.

None of this blocks the integration; it is listed so nobody assumes a capability
that is not there.
