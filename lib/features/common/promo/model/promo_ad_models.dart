/// Models for `GET other-service/ads` — the server-served promo artwork that
/// replaced the bundled `assets/qureka/*` images.
///
/// See docs/backend/ADS_API_FLUTTER_GUIDE.md. The shape is:
///
/// ```
/// { version, placements: { <key>: { width, height, aspectRatio, creatives[] } },
///   notifications: [ { id, en: {title, body}, hi: {title, body} } ] }
/// ```
library;

/// One image inside a placement.
class AdCreative {
  const AdCreative({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    this.format = 'png',
    this.campaign = 'generic',
    this.campaignLabel = 'General',
    this.targetUrl,
  });

  final String id;
  final String url;
  final int width;
  final int height;
  final String format;
  final String campaign;
  final String campaignLabel;

  /// Where a tap goes, or null for a decorative creative. Most creatives are
  /// null today — see [PromoAdsService] for how the promo destination is
  /// resolved rather than guessed.
  final String? targetUrl;

  /// Tolerant of missing/renamed fields: a malformed creative must not take the
  /// whole bundle down, so everything falls back rather than throwing. A
  /// creative with no [url] is dropped by [AdPlacement.fromJson].
  factory AdCreative.fromJson(Map<String, dynamic> j) {
    return AdCreative(
      id: (j['id'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      width: _int(j['width']),
      height: _int(j['height']),
      format: (j['format'] ?? 'png').toString(),
      campaign: (j['campaign'] ?? 'generic').toString(),
      campaignLabel: (j['campaignLabel'] ?? 'General').toString(),
      targetUrl: (j['targetUrl'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['targetUrl'] as String).trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'width': width,
        'height': height,
        'format': format,
        'campaign': campaign,
        'campaignLabel': campaignLabel,
        'targetUrl': targetUrl,
      };
}

/// One slot — a pixel size and every creative drawn for it.
class AdPlacement {
  const AdPlacement({
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.creatives,
  });

  final int width;
  final int height;

  /// Reserve layout space with this BEFORE the image loads, so a list doesn't
  /// jump as creatives arrive.
  final double aspectRatio;

  final List<AdCreative> creatives;

  factory AdPlacement.fromJson(Map<String, dynamic> j) {
    final width = _int(j['width']);
    final height = _int(j['height']);
    final raw = (j['creatives'] as List?) ?? const [];
    final creatives = raw
        .whereType<Map>()
        .map((c) => AdCreative.fromJson(Map<String, dynamic>.from(c)))
        .where((c) => c.url.isNotEmpty)
        .toList();
    return AdPlacement(
      width: width,
      height: height,
      // Derived from the size when the server omits it (or sends a zero), so a
      // slot can still reserve the right box.
      aspectRatio: _double(j['aspectRatio']) > 0
          ? _double(j['aspectRatio'])
          : (height > 0 ? width / height : 1),
      creatives: creatives,
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'aspectRatio': aspectRatio,
        'creatives': creatives.map((c) => c.toJson()).toList(),
      };

  bool get isEmpty => creatives.isEmpty;
}

/// The placement keys the app fills. The API serves 13; these are the ones with
/// a call site — add a constant here when a screen starts using another slot,
/// so the string exists in exactly one place.
class AdPlacements {
  const AdPlacements._();

  /// 900x506 (16:9) — the full-width promo card in Discover and the feed.
  static const String homeHero = 'home_hero';

  /// 320x50 — the slim strip under the "Me" tabs.
  static const String bannerStrip = 'banner_strip';
}

/// One bilingual notification copy pair. The API sends both languages in the
/// same entry, so picking by id can never pair an English title with a Hindi
/// body.
class AdNotificationCopy {
  const AdNotificationCopy({
    required this.id,
    required this.enTitle,
    required this.enBody,
    required this.hiTitle,
    required this.hiBody,
  });

  final int id;
  final String enTitle;
  final String enBody;
  final String hiTitle;
  final String hiBody;

  factory AdNotificationCopy.fromJson(Map<String, dynamic> j) {
    final en = Map<String, dynamic>.from((j['en'] as Map?) ?? const {});
    final hi = Map<String, dynamic>.from((j['hi'] as Map?) ?? const {});
    return AdNotificationCopy(
      id: _int(j['id']),
      enTitle: (en['title'] ?? '').toString(),
      enBody: (en['body'] ?? '').toString(),
      hiTitle: (hi['title'] ?? '').toString(),
      hiBody: (hi['body'] ?? '').toString(),
    );
  }

  /// Title/body in the caller's language, falling back to English when a Hindi
  /// entry is blank.
  String title({required bool hindi}) =>
      hindi && hiTitle.isNotEmpty ? hiTitle : enTitle;

  String body({required bool hindi}) =>
      hindi && hiBody.isNotEmpty ? hiBody : enBody;
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
