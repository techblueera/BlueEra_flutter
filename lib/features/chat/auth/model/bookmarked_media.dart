/// A locally-bookmarked chat image/video. Persisted as JSON via
/// SharedPreferenceUtils and grouped by conversation on the Bookmarks screen.
class BookmarkedMedia {
  final String url;
  final String? name;
  final String conversationId;
  final String? personName;
  final String? personImage;
  final String? messageId;
  final String? caption;
  final int savedAt;

  BookmarkedMedia({
    required this.url,
    this.name,
    required this.conversationId,
    this.personName,
    this.personImage,
    this.messageId,
    this.caption,
    required this.savedAt,
  });

  bool get isVideo {
    final l = url.toLowerCase();
    return l.endsWith('.mp4') ||
        l.endsWith('.mov') ||
        l.endsWith('.avi') ||
        l.endsWith('.webm') ||
        l.endsWith('.mkv');
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'conversationId': conversationId,
        'personName': personName,
        'personImage': personImage,
        'messageId': messageId,
        'caption': caption,
        'savedAt': savedAt,
      };

  factory BookmarkedMedia.fromJson(Map<String, dynamic> json) => BookmarkedMedia(
        url: json['url']?.toString() ?? '',
        name: json['name']?.toString(),
        conversationId: json['conversationId']?.toString() ?? '',
        personName: json['personName']?.toString(),
        personImage: json['personImage']?.toString(),
        messageId: json['messageId']?.toString(),
        caption: json['caption']?.toString(),
        savedAt: (json['savedAt'] is int)
            ? json['savedAt'] as int
            : int.tryParse('${json['savedAt']}') ?? 0,
      );
}
