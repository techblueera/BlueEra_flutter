class AddFavouriteSongModel {
  final bool success;
  final String message;
  final FavouriteSongData data;

  AddFavouriteSongModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AddFavouriteSongModel.fromJson(Map<String, dynamic> json) {
    return AddFavouriteSongModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: FavouriteSongData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data.toJson(),
  };
}

class FavouriteSongData {
  final String id;
  final String user;
  final String song;
  final DateTime createdAt;
  final DateTime updatedAt;

  FavouriteSongData({
    required this.id,
    required this.user,
    required this.song,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavouriteSongData.fromJson(Map<String, dynamic> json) {
    return FavouriteSongData(
      id: json['_id'] ?? '',
      user: json['user'] ?? '',
      song: json['song'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user': user,
    'song': song,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
