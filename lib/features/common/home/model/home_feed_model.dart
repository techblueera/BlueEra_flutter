import 'package:get/get.dart';

import 'package:BlueEra/features/common/feed/models/posts_response.dart';
class HomeFeedResponse {
  final bool success;
  final List<FeedItem> feed;
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
          (json['feed'] as List?)?.map((e) => FeedItem.fromJson(e)).toList() ??
              [],
      metaData: json['meta'] != null ? MetaData.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'feed': feed.map((e) => e.toJson()).toList(),
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

class FeedItem {
  final String id;
  final String type; // post, long_video, short_video
  final String? title;
  final String? description;
  final String? videoUrl;
  final String? thumbnail;
  final int? duration;
  final dynamic channel;
  final Stats? stats;
  final DateTime? createdAt;
  final List<String>? tags;
  final List<String>? categories;
  final dynamic location;
  final Author author;
  final Content? content;
  final String? subTitle;
  final String? natureOfPost;
  final List<User>? taggedUsers;
  final dynamic song;
  final bool? is_post_liked;

  FeedItem({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.videoUrl,
    this.thumbnail,
    this.duration,
    this.channel,
    this.stats,
    this.createdAt,
    this.tags,
    this.categories,
    this.location,
    required this.author,
    this.content,
    this.subTitle,
    this.natureOfPost,
    this.taggedUsers,
    this.song,
    this.is_post_liked,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'],
      description: json['description'],
      videoUrl: json['video_url']?.toString().trim(),
      thumbnail: json['thumbnail']?.toString().trim(),
      duration: json['duration'],
      channel: json['channel'],
      stats: json['stats'] != null ? Stats.fromJson(json['stats']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      categories:
          (json['categories'] as List?)?.map((e) => e.toString()).toList(),
      location: json['location'],
      author: Author.fromJson(json['author'] ?? {}),
      content:
          json['content'] != null ? Content.fromJson(json['content']) : null,
      subTitle: json['sub_title'],
      natureOfPost: json['nature_of_post'],
      song: json['song'],
      is_post_liked: json['is_post_liked'],
      taggedUsers:
      (json['tagged_users'] as List<dynamic>?)?.map((e) => User.fromJson(e as Map<String, dynamic>)).toList(),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail': thumbnail,
      'duration': duration,
      'channel': channel,
      'stats': stats?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'tags': tags,
      'categories': categories,
      'location': location,
      'author': author.toJson(),
      'content': content?.toJson(),
      'sub_title': subTitle,
      'nature_of_post': natureOfPost,
      'song': song,
      'is_post_liked': is_post_liked,
      'tagged_users': taggedUsers?.map((e) => e.toJson()).toList(),

    };
  }
}

class Stats {
  final dynamic views;
  final dynamic likes;
  final dynamic comments;
  final dynamic shares;

  Stats({
    this.views,
    this.likes,
    this.comments,
    this.shares,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      views: json['views'],
      likes: json['likes'],
      comments: json['comments'],
      shares: json['shares'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'likes': likes,
      'comments': comments,
      'shares': shares,
    };
  }
}

class Author {
  final String id;
  final String name;
  final String username;
  final String avatar;
  final bool verified;
  final String accountType;
  final String? designation;
  final String? location;
  final String? businessName;
  final String? businessCategory;

  Author({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.verified,
    required this.accountType,
    this.designation,
    this.location,
    this.businessName,
    this.businessCategory,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar']?.toString().trim() ?? '',
      verified: json['verified_'] ?? false,
      accountType: json['account_type'] ?? '',
      designation: json['designation'],
      location: json['location'],
      businessName: json['business_name'],
      businessCategory: json['business_category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatar': avatar,
      'verified': verified,
      'account_type': accountType,
      'designation': designation,
      'location': location,
      'business_name': businessName,
      'business_category': businessCategory,
    };
  }
}

class Content {
  final String? text;
  final List<String>? images;

  Content({
    this.text,
    this.images,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      text: json['text'],
      images:
          (json['images'] as List?)?.map((e) => e.toString().trim()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'images': images,
    };
  }
}
