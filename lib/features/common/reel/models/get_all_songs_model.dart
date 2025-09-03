class GetAllSongsModel {
  final bool success;
  final int count;
  final List<Song> data;

  GetAllSongsModel({
    required this.success,
    required this.count,
    required this.data,
  });

  factory GetAllSongsModel.fromJson(Map<String, dynamic> json) {
    return GetAllSongsModel(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Song.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }

  GetAllSongsModel copyWith({
    bool? success,
    int? count,
    List<Song>? data,
  }) {
    return GetAllSongsModel(
      success: success ?? this.success,
      count: count ?? this.count,
      data: data ?? this.data,
    );
  }
}

class Song {
  final String id;
  final String name;
  final String artist;
  final bool isGlobal;
  final String externalUrl;
  final String coverUrl;
  final String? duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavourite;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.isGlobal,
    required this.externalUrl,
    required this.coverUrl,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavourite,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      isGlobal: json['isGlobal'] ?? false,
      externalUrl: json['externalUrl'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      duration: json['duration'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isFavourite: json['is_favourite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'artist': artist,
      'isGlobal': isGlobal,
      'externalUrl': externalUrl,
      'coverUrl': coverUrl,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'is_favourite': isFavourite,
    };
  }

  Song copyWith({
    String? id,
    String? name,
    String? artist,
    bool? isGlobal,
    String? externalUrl,
    String? coverUrl,
    String? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavourite,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      isGlobal: isGlobal ?? this.isGlobal,
      externalUrl: externalUrl ?? this.externalUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}
