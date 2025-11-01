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
  final String type;
  final int views_count;
  final int comments_count;
  final int likes_count;
  final int repost_count;
  final String createdAt;
  final bool isLiked;

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
    required this.createdAt,
    required this.views_count,
    required this.comments_count,
    required this.type,
    required this.repost_count,
    required this.isLiked,
    required this.likes_count,
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
      views_count: json["views_count"]?? "",
      repost_count: json["repost_count"]?? "",
      type: json["type"]?? "",
      comments_count: json["comments_count"]?? "",
      createdAt: json["created_at"],
      isLiked: json["isLiked"],
      likes_count: json["likes_count"],
    );
  }
}
