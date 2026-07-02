/// A referral-page testimonial from `GET /earn-service/testimonial`.
///
/// Each testimonial has a [title] + [description] and carries media as EITHER
/// a list of [images] OR a single [video] (or neither → text-only).
class ReferralTestimonial {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String? video;
  final DateTime? createdAt;

  const ReferralTestimonial({
    this.id = '',
    this.title = '',
    this.description = '',
    this.images = const [],
    this.video,
    this.createdAt,
  });

  bool get hasVideo => (video ?? '').trim().isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  bool get hasMedia => hasVideo || hasImages;

  /// Poster used behind the play button for video testimonials (if any image
  /// was also supplied).
  String? get poster => images.isNotEmpty ? images.first : null;

  factory ReferralTestimonial.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List?) ?? const [];
    final v = json['video']?.toString();
    return ReferralTestimonial(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: rawImages
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      video: (v == null || v.isEmpty) ? null : v,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
