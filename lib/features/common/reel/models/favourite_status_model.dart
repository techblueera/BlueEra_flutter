class FavoriteStatusModel {
  final bool success;
  final bool isFavorite;

  FavoriteStatusModel({
    required this.success,
    required this.isFavorite,
  });

  factory FavoriteStatusModel.fromJson(Map<String, dynamic> json) {
    return FavoriteStatusModel(
      success: json['success'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'isFavorite': isFavorite,
  };
}
