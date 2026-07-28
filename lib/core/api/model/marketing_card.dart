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
/// The app renders [url] directly — the poster is composed server-side and is
/// the ONLY artwork the share card shows. There is no client-composed
/// fallback: when [readyUrl] is null the card simply renders without a poster.
///
/// Note there is **no video here** — the referral promo clip is a top-level
/// `referal_video` on the profile response, not part of this object.
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

  /// The poster URL to display, or null when the payload carries none.
  ///
  /// The URL is the ONLY thing gated on — [status] is not. It used to also
  /// require `status == "ready"`, which meant a profile that came back with a
  /// real, servable poster URL but any other status string (or none at all)
  /// rendered no poster. Since the card has no client-composed fallback any
  /// more, that gate showed nothing at all rather than the poster the backend
  /// had already generated.
  String? get readyUrl => url.trim().isNotEmpty ? url.trim() : null;

  /// Parse helper tolerant of the raw value being a `Map` (or null/other).
  static MarketingCard? fromRaw(dynamic raw) => raw is Map
      ? MarketingCard.fromJson(Map<String, dynamic>.from(raw))
      : null;
}
