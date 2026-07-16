/// A backend-generated share/marketing poster for a profile (business or
/// individual). Returned as a `marketing_card` sibling on the profile response:
///
/// ```jsonc
/// "marketing_card": {
///   "url": "https://…/marketing-cards/<id>.png",
///   "generated_at": "2026-07-16T12:31:26.043Z",
///   "source_hash": "ed3d27…",
///   "status": "ready"
/// }
/// ```
///
/// The app renders [url] directly (the poster is composed server-side now)
/// instead of building the banner artwork on the client — but only when
/// [readyUrl] is non-null (status `ready` + a real URL); otherwise the caller
/// falls back to the client-composed banner.
class MarketingCard {
  final String url;
  final String status;
  final String? generatedAt;
  final String? sourceHash;

  const MarketingCard({
    required this.url,
    required this.status,
    this.generatedAt,
    this.sourceHash,
  });

  factory MarketingCard.fromJson(Map<String, dynamic> json) => MarketingCard(
        url: json['url']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        generatedAt: json['generated_at']?.toString(),
        sourceHash: json['source_hash']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'status': status,
        'generated_at': generatedAt,
        'source_hash': sourceHash,
      };

  /// The poster URL to display, or null when it isn't ready to show (still
  /// generating, failed, or no URL). Only `status == "ready"` with a real URL
  /// is safe to render.
  String? get readyUrl =>
      (status.toLowerCase() == 'ready' && url.trim().isNotEmpty)
          ? url.trim()
          : null;

  /// Parse helper tolerant of the raw value being a `Map` (or null/other).
  static MarketingCard? fromRaw(dynamic raw) => raw is Map
      ? MarketingCard.fromJson(Map<String, dynamic>.from(raw))
      : null;
}
