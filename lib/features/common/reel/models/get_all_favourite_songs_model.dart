import 'package:BlueEra/features/common/reel/models/get_all_songs_model.dart';

class FavouriteSongsResponse {
  final bool success;
  final List<FavouriteSong> data;
  final Pagination? pagination;

  FavouriteSongsResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory FavouriteSongsResponse.fromJson(Map<String, dynamic> json) {
    return FavouriteSongsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>)
          .map((e) => FavouriteSong.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data.map((e) => e.toJson()).toList(),
    'pagination': pagination?.toJson(),
  };
}

class FavouriteSong {
  final String id;
  final String userId;
  final Song song;

  FavouriteSong({
    required this.id,
    required this.userId,
    required this.song,
  });

  factory FavouriteSong.fromJson(Map<String, dynamic> json) {
    final songJson = json['song'];
    songJson['is_favourite'] = true; // Mark it as favorite

    return FavouriteSong(
      id: json['_id'],
      userId: json['user'],
      song: Song.fromJson(songJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'song': song.toJson(),
    };
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }

  Pagination copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
