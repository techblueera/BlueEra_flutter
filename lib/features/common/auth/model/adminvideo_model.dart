class AdminVideoResponse {
  final bool? success;
  final List<AdminVideo>? data;
  final Pagination? pagination;

  AdminVideoResponse({
    this.success,
    this.data,
    this.pagination,
  });

  factory AdminVideoResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdminVideoResponse();

    return AdminVideoResponse(
      success: json['success'] as bool?,
      data: (json['data'] as List?)
          ?.map((e) => AdminVideo.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}
class AdminVideo {
  final String? id;
  final String? userId;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final List<VideoUrl>? videoUrls;
  final String? categories;
  final String? screenPlacement;
  final int? duration;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminVideo({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.videoUrls,
    this.categories,
    this.screenPlacement,
    this.duration,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminVideo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdminVideo();

    return AdminVideo(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrls: (json['videoUrls'] as List?)
          ?.map((e) => VideoUrl.fromJson(e))
          .toList(),
      categories: json['categories'] as String?,
      screenPlacement: json['screenPlacement'] as String?,
      duration: json['duration'] as int?,
      type: json['type'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrls': videoUrls?.map((e) => e.toJson()).toList(),
      'categories': categories,
      'screenPlacement': screenPlacement,
      'duration': duration,
      'type': type,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
class VideoUrl {
  final String? language;
  final String? url;

  VideoUrl({
    this.language,
    this.url,
  });

  factory VideoUrl.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VideoUrl();

    return VideoUrl(
      language: json['language'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'url': url,
    };
  }
}
class Pagination {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;
  final bool? hasNext;
  final bool? hasPrev;

  Pagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
    this.hasNext,
    this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Pagination();

    return Pagination(
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      total: json['total'] as int?,
      totalPages: json['totalPages'] as int?,
      hasNext: json['hasNext'] as bool?,
      hasPrev: json['hasPrev'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }
}