import 'package:get/get.dart';

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

class MetaData {
  final String next_cursor;

  MetaData({required this.next_cursor});

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      next_cursor: json['next_cursor'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'next_cursor': next_cursor,
    };
  }
}
