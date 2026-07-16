import 'package:BlueEra/features/common/feed/models/posts_response.dart';
class HomeFeedResponse {
  final bool success;
  final List<Post> feed;
  final MetaData? metaData;

  HomeFeedResponse({
    required this.success,
    required this.feed,
    required this.metaData,
  });

  factory HomeFeedResponse.fromJson(Map<String, dynamic> json) {
    return HomeFeedResponse(
      success: json['success'] ?? false,
      feed:
          (json['data'] as List?)?.map((e) => Post.fromJson(e)).toList() ??
              [],
      metaData: json['meta'] != null ? MetaData.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': feed.map((e) => e.toJson()).toList(),
      'meta': metaData?.toJson(),
    };
  }
}

/// `meta` from the `/feed` envelope. See
/// docs/backend/FRONTEND_FEED_INTEGRATION.md §2 and §5.
class MetaData {
  /// Opaque pagination cursor — echo back verbatim as `cursor` on the next
  /// page. Never parse or construct it client-side (guide §5).
  final String next_cursor;

  /// Whether another page exists. This — not the returned item count — is what
  /// terminates infinite scroll (guide §5.4): the backend interleaves several
  /// sources, so a page can be short of `limit` and still have more behind it.
  ///
  /// Null when the server omitted the field entirely, which lets the caller
  /// distinguish "no more pages" from "this server doesn't report has_more" and
  /// fall back to the old count heuristic rather than silently stop paginating.
  final bool? has_more;

  MetaData({required this.next_cursor, this.has_more});

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      next_cursor: json['next_cursor'] ?? "",
      has_more: json['has_more'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'next_cursor': next_cursor,
      'has_more': has_more,
    };
  }
}
