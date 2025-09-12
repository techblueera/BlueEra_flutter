class SongModel {
  final String id;
  final String name;
  final String artist;
  final String coverUrl;

  SongModel({
    required this.id,
    required this.name,
    required this.artist,
    required this.coverUrl,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "artist": artist,
      "coverUrl": coverUrl,
    };
  }
}
