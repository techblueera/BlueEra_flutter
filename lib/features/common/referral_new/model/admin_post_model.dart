/// Response envelope for `GET /earn-service/admin-posts`.
///
/// The same endpoint drives the testimonials, overview, tutorial and
/// user-post sections on the new BDM/referral dashboard — filtered via
/// the `?type=` query param.
class AdminPostsResponse {
  final List<AdminPost> adminPosts;
  final int currentPage;
  final int totalPages;
  final int totalAdminPosts;

  AdminPostsResponse({
    required this.adminPosts,
    required this.currentPage,
    required this.totalPages,
    required this.totalAdminPosts,
  });

  factory AdminPostsResponse.fromJson(Map<String, dynamic> json) {
    return AdminPostsResponse(
      adminPosts: (json['adminPosts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminPost.fromJson)
              .toList() ??
          const [],
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalAdminPosts: (json['totalAdminPosts'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPost {
  final String id;
  final String type;
  final String title;
  final String description;
  final String link;
  final List<String> images;
  final String? video;
  final String? createdAt;
  final String? updatedAt;
  final AdminPostCreator? creator;
  final AdminPostMetadata? metadata;

  AdminPost({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.link,
    required this.images,
    this.video,
    this.createdAt,
    this.updatedAt,
    this.creator,
    this.metadata,
  });

  factory AdminPost.fromJson(Map<String, dynamic> json) {
    return AdminPost(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      images: (json['images'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      video: (json['video'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['video'] as String,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      creator: json['creatorDetails'] is Map<String, dynamic>
          ? AdminPostCreator.fromJson(json['creatorDetails'])
          : null,
      metadata: json['metaData'] is Map<String, dynamic>
          ? AdminPostMetadata.fromJson(json['metaData'])
          : null,
    );
  }

  // ── Hero / display helpers ────────────────────────────────────────
  //
  // User-pasted social posts (`type=post`) carry their preview info on
  // `metadata`; admin-created posts (tutorial/overview/testimonial)
  // ship a native S3 `video` URL plus an optional `images` list. These
  // getters paper over that split so the card never has to branch.

  bool get hasVideo => (video?.isNotEmpty ?? false);

  /// True when the post points at a social platform we can't stream
  /// in-app (Instagram / YouTube / Twitter). The card switches the
  /// play badge to "open externally" in that case.
  bool get isExternalMedia => !hasVideo && (metadata?.webpageUrl?.isNotEmpty ?? false);

  /// Best title to render — falls back to the post's own `title` (which
  /// for user posts is just the platform name) only when metadata
  /// hasn't been resolved yet.
  String get displayTitle {
    final m = metadata?.title;
    if (m != null && m.trim().isNotEmpty) return m;
    return title;
  }

  /// Best description — metadata first, then the bare `description`.
  String get displayDescription {
    final m = metadata?.description;
    if (m != null && m.trim().isNotEmpty) return m;
    return description;
  }

  /// Best external link — `metadata.webpageUrl` is the canonical
  /// platform URL once the backend has scraped it; otherwise we fall
  /// back to whatever the user pasted.
  String get externalLink {
    final m = metadata?.webpageUrl;
    if (m != null && m.isNotEmpty) return m;
    return link;
  }

  /// Best non-video thumbnail to show inside the carousel. Prefers
  /// metadata's preview over post images.
  String? get previewThumbnail {
    final m = metadata?.thumbnail;
    if (m != null && m.isNotEmpty) return m;
    if (images.isNotEmpty) return images.first;
    return null;
  }
}

/// Subset of the `metaData` blob returned by `/earn-service/admin-posts`
/// for user-pasted social posts. The full payload from the scraper is
/// much richer (tags, dimensions, raw uploader URL, …); we only model
/// the fields the card actually renders to keep the model lean.
class AdminPostMetadata {
  final String? provider;
  final String? platformId;
  final String? title;
  final String? description;
  final String? thumbnail;
  final num? duration;
  final String? durationString;
  final String? uploader;
  final num? viewCount;
  final num? likeCount;
  final num? commentCount;
  final String? uploadDate;
  final String? webpageUrl;
  final String? extractor;
  final bool isLive;

  AdminPostMetadata({
    this.provider,
    this.platformId,
    this.title,
    this.description,
    this.thumbnail,
    this.duration,
    this.durationString,
    this.uploader,
    this.viewCount,
    this.likeCount,
    this.commentCount,
    this.uploadDate,
    this.webpageUrl,
    this.extractor,
    this.isLive = false,
  });

  factory AdminPostMetadata.fromJson(Map<String, dynamic> json) {
    return AdminPostMetadata(
      provider: json['provider']?.toString(),
      platformId: json['id']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration'] is num ? json['duration'] as num : null,
      durationString: json['durationString']?.toString(),
      uploader: json['uploader']?.toString(),
      viewCount: json['viewCount'] is num ? json['viewCount'] as num : null,
      likeCount: json['likeCount'] is num ? json['likeCount'] as num : null,
      commentCount:
          json['commentCount'] is num ? json['commentCount'] as num : null,
      uploadDate: json['uploadDate']?.toString(),
      webpageUrl: json['webpageUrl']?.toString(),
      extractor: json['extractor']?.toString(),
      isLive: json['isLive'] == true,
    );
  }
}

class AdminPostCreator {
  final String id;
  final String name;
  final String profileImage;
  final String designation;
  final String currentOrganisation;

  AdminPostCreator({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.designation,
    required this.currentOrganisation,
  });

  factory AdminPostCreator.fromJson(Map<String, dynamic> json) {
    return AdminPostCreator(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      currentOrganisation: json['current_organisation']?.toString() ?? '',
    );
  }
}
