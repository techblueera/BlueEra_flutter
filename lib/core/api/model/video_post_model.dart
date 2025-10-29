class VideoPost {
  final String id;
  final String title;
  final String subTitle;
  final String videoUrl;
  final String thumbnail;
  final String aspectRatio;
  final String authorName;
  final String authorUsername;
  final String avatar;
  final String designation;
  final String business_category;
  final String account_type;

  VideoPost({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.videoUrl,
    required this.thumbnail,
    required this.aspectRatio,
    required this.authorName,
    required this.authorUsername,
    required this.avatar,
    required this.designation,
    required this.business_category,
    required this.account_type,
  });

  factory VideoPost.fromJson(Map<String, dynamic> json) {
    return VideoPost(
      id: json["id"],
      title: json["title"] ?? "",
      subTitle: json["sub_title"] ?? "",
      videoUrl: json["media"].isNotEmpty ? json["media"][0] : "",
      thumbnail: json["thumbnail"] ?? "",
      aspectRatio: json["media_aspect_ratio"] ?? "SQUARE",
      authorName: json["author"]?["name"] ?? "",
      authorUsername: json["author"]?["username"] ?? "",
      avatar: json["author"]?["avatar"] ?? "",
      designation: json["author"]?["designation"] ?? "",
      business_category: json["author"]?["business_category"] ?? "",
      account_type: json["author"]?["account_type"] ?? "",
    );
  }
}
