import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';

class PostResponse {
  final bool success;
  final String? message;
  final List<Post> data;
  final Pagination pagination;

  PostResponse({
    required this.success,
    this.message,
    required this.data,
    required this.pagination,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) {
    return PostResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data:
          (json['data'] as List?)?.map((e) => Post.fromJson(e)).toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  PostResponse copyWith({
    bool? success,
    String? message,
    List<Post>? data,
    Pagination? pagination,
  }) {
    return PostResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      pagination: pagination ?? this.pagination,
    );
  }
}
class Post {
  final String id;
  final String? message;
  final String? location;
  final num? latitude;
  final num? longitude;
  final String? title;
  final String? subTitle;
  final String? type;
  final String? post_via;
  final String? natureOfPost;
  final String? referenceLink;
   int? commentsCount;
   int? likesCount;
  final int? repostCount;
  final int? viewsCount;
  final int? sharesCount;
  final int? totalEngagement;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? quesOptions;
  final List<User>? taggedUsers;
  final List<String>? media;
  final List<String>? media_types;

  // final LocationMetadata? locationMetadata;
  final Poll? poll;
   bool? isLiked;
  final User? user;
  final bool? isPostSavedLocal;
  final Song? song;
  final int? visibilityDuration;
  final String? videoUrl;
  final String? thumbnail;
  final int? duration;
  final Channel? channel;
  final bool? is_reposted;
  final Post? children_post;
  final num? media_height;
  final num? media_width;
  final String? channelName;

  /// Mixed post/reel feed discriminator: "post", "reel", or null (flag-off /
  /// legacy posts-only response). Branch rendering on [isReel].
  final String? itemType;

  /// Reel payload — present only when [isReel] is true; null for posts.
  final FeedReel? reel;

  bool get isReel => itemType == 'reel';

  Post({
    required this.id,
    this.message,
    this.channelName,
    this.is_reposted,
    this.children_post,
    this.location,
    this.latitude,
    this.longitude,
    this.title,
    this.subTitle,
    this.type,
    this.natureOfPost,
    this.referenceLink,
    this.commentsCount,
    this.likesCount,
    this.post_via,
    this.repostCount,
    this.viewsCount,
    this.sharesCount,
    this.totalEngagement,
    this.createdAt,
    this.updatedAt,
    this.quesOptions,
    this.taggedUsers,
    this.media,
    this.media_types,
    // this.locationMetadata,
    this.poll,
    this.isLiked,
    this.user,
    this.isPostSavedLocal,
    this.song,
    this.visibilityDuration,
    this.videoUrl,
    this.thumbnail,
    this.duration,
    this.channel,
    this.media_width,
    this.media_height,
    this.itemType,
    this.reel,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Mixed post/reel feed: a reel item is tagged item_type:"reel" and nests
    // its payload under `reel` (it has no post fields at top level). Wrap it in
    // a marker Post that only carries the reel; the UI branches on [isReel].
    // See docs/backend/REELS_IN_FEED_FRONTEND_GUIDE.md.
    if (json['item_type'] == 'reel') {
      final reelJson = (json['reel'] as Map<String, dynamic>?) ?? const {};
      return Post(
        id: reelJson['id']?.toString() ?? '',
        itemType: 'reel',
        reel: FeedReel.fromJson(reelJson),
      );
    }
    return Post(
      id: json['_id']?? json['id'] ?? ""??"",
      itemType: json['item_type'],
      channelName: json['channelName'],
      is_reposted: json['is_reposted'],
      message: json['message'],
      // location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      title: json['title'],
      post_via: json['post_via'],
      subTitle: json['sub_title'],
      type: json['type'],
      natureOfPost: json['nature_of_post'],
      referenceLink: json['reference_link'],
      // commentsCount: json['comments_count'],
      commentsCount:
          int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      repostCount: int.tryParse(json['repost_count']?.toString() ?? '0') ?? 0,
      viewsCount: int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      sharesCount: int.tryParse(json['shares_count']?.toString() ?? '0') ?? 0,

      totalEngagement: json['totalEngagement'],
      // quesOptions: json['quesOptions'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,

      taggedUsers: (json['tagged_users_details'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      media: (json['media'] as List?)?.map((e) => e.toString()).toList(),
      media_types: (json['media_types'] as List?)?.map((e) => e.toString()).toList(),

      poll: json['poll'] != null ? Poll.fromJson(json['poll']) : null,
      isLiked: json['isLiked'],
        user: json['user'] != null ? User.fromJson(json['user']) : null,
      isPostSavedLocal: json['isPostSavedLocal'],
      song: json['song'] != null ? Song.fromJson(json['song']) : null,
      visibilityDuration: json['visibility_duration'],
      videoUrl: json['video_url']?.toString().trim(),
      thumbnail: json['thumbnail']?.toString().trim(),
      duration: json['duration'],
      media_height: json['media_height'],
      media_width: json['media_width'],
      channel: json['channel'] != null ? Channel.fromJson(json['channel']) : null,
      children_post: json['children_post'] != null ? Post.fromJson(json['children_post']) : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      // '_id': id,
      'channelName': channelName,
      'message': message,
      'is_reposted': is_reposted,
      'location': location,
      'latitude': latitude,
      'post_via': post_via,
      'longitude': longitude,
      'title': title,
      'sub_title': subTitle,
      'type': type,
      'nature_of_post': natureOfPost,
      'reference_link': referenceLink,
      'comments_count': commentsCount,
      'likes_count': likesCount,
      'repost_count': repostCount,
      'views_count': viewsCount,
      'shares_count': sharesCount,
      'totalEngagement': totalEngagement,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'ques_options': quesOptions,
      'tagged_users_details': taggedUsers?.map((e) => e.toJson()).toList(),
      'media': media,
      'media_types': media_types,
      // 'location_metadata': locationMetadata?.toJson(),
      'poll': poll?.toJson(),
      'isLiked': isLiked,
      'user': user?.toJson(),
      'isPostSavedLocal': isPostSavedLocal,
      'song': song?.toJson(),
      'visibility_duration': visibilityDuration,
      'video_url': videoUrl,
      'thumbnail': thumbnail,
      'duration': duration,
      'media_width': media_width,
      'media_height': media_height,
      'channel': channel?.toJson(),
      'children_post': children_post?.toJson(),

    };
  }

  Post copyWith({
    String? id,
    String? message,
    String? channelName,
    String? post_via,
    String? location,
    double? latitude,
    double? longitude,
    String? title,
    String? subTitle,
    String? type,
    String? natureOfPost,
    String? referenceLink,
    int? commentsCount,
    int? likesCount,
    int? repostCount,
    int? viewsCount,
    int? sharesCount,
    int? totalEngagement,
    DateTime? createdAt,
    String? quesOptions,
    List<User>? taggedUsers,
    List<String>? media,
    List<String>? media_types,
    Poll? poll,
    bool? isLiked,
    User? user,
    bool? isPostSavedLocal,
    Song? song,
    int? visibilityDuration,
    String? videoUrl,
    String? thumbnail,
    int? duration,
    Channel? channel,
    Post? children_post,
    bool? is_reposted,
    num? media_height,
    num? media_width,
    String? itemType,
    FeedReel? reel,
  }) {
    return Post(
      id: id ?? this.id,
      message: message ?? this.message,
      channelName: channelName ?? this.channelName,
      post_via: post_via ?? this.post_via,
      is_reposted: is_reposted ?? this.is_reposted,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      type: type ?? this.type,
      natureOfPost: natureOfPost ?? this.natureOfPost,
      referenceLink: referenceLink ?? this.referenceLink,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      repostCount: repostCount ?? this.repostCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      totalEngagement: totalEngagement ?? this.totalEngagement,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quesOptions: quesOptions ?? this.quesOptions,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      media: media ?? this.media,
      media_types: media_types ?? this.media_types,
      poll: poll ?? this.poll,
      isLiked: isLiked ?? this.isLiked,
      user: user ?? this.user,
      isPostSavedLocal: isPostSavedLocal ?? this.isPostSavedLocal,
      song: song ?? this.song,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      channel: channel ?? this.channel,
      children_post: children_post ?? this.children_post,
      visibilityDuration: visibilityDuration ?? this.visibilityDuration,
      media_width: media_width ?? this.media_width,
      media_height: media_height ?? this.media_height,
      itemType: itemType ?? this.itemType,
      reel: reel ?? this.reel,
    );
  }
}

/// A short video injected into the mixed post/reel feed. Carried on a [Post]
/// whose `item_type == "reel"` (see docs/backend/REELS_IN_FEED_FRONTEND_GUIDE.md).
/// Every field can be null/0 — always render with fallbacks.
class FeedReel {
  final String? id;
  final String? userId;
  final String? channelId;
  final String? title;
  final String? caption;
  final String? description;
  final String? coverUrl;
  final String? videoUrl;
  final int? duration;
  final String? type;
  final String? createdAt;
  final dynamic song;
  final Map<String, dynamic>? thumbnails;
  final FeedReelStats stats;

  FeedReel({
    this.id,
    this.userId,
    this.channelId,
    this.title,
    this.caption,
    this.description,
    this.coverUrl,
    this.videoUrl,
    this.duration,
    this.type,
    this.createdAt,
    this.song,
    this.thumbnails,
    FeedReelStats? stats,
  }) : stats = stats ?? const FeedReelStats();

  factory FeedReel.fromJson(Map<String, dynamic> json) {
    return FeedReel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      channelId: json['channel_id']?.toString(),
      title: json['title']?.toString(),
      caption: json['caption']?.toString(),
      description: json['description']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      type: json['type']?.toString(),
      createdAt: _parseReelTimestamp(json['created_at']),
      song: json['song'],
      thumbnails: (json['thumbnails'] as Map?)?.cast<String, dynamic>(),
      stats: FeedReelStats.fromJson(
          (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  /// `created_at` arrives as a gRPC timestamp object `{ seconds, nanos }`
  /// (`seconds` is a numeric string), not an ISO string. Normalise it to an ISO
  /// string so downstream date formatting works; tolerate a legacy ISO string
  /// and null. See REELS_IN_FEED_FRONTEND_GUIDE.md §3.
  static String? _parseReelTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) {
      final seconds = int.tryParse(raw['seconds']?.toString() ?? '');
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
            .toIso8601String();
      }
    }
    return null;
  }

  /// Text to show under the cover: caption first, then title.
  String get displayText {
    final c = caption?.trim() ?? '';
    if (c.isNotEmpty) return c;
    return title?.trim() ?? '';
  }
}

/// Reel engagement counters — always present, default 0.
class FeedReelStats {
  final int views;
  final int likes;
  final int shares;
  final int comments;

  const FeedReelStats({
    this.views = 0,
    this.likes = 0,
    this.shares = 0,
    this.comments = 0,
  });

  factory FeedReelStats.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return FeedReelStats(
      views: parse(json['views']),
      likes: parse(json['likes']),
      shares: parse(json['shares']),
      comments: parse(json['comments']),
    );
  }
}

class User {
  final String? id;
  final String? username;
  final String? profileImage;
  final String? designation;
  final String? accountType;
  final String? name;
  final String? businessName;
  final String? business_id;
  final String? categoryOfBusiness;

  User({
    this.id,
    this.username,
    this.profileImage,
    this.designation,
    this.accountType,
    this.name,
    this.businessName,
    this.business_id,
    this.categoryOfBusiness,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']??json['id'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profile_image'] ?? '',
      designation: json['designation'] ?? '',
      accountType: json['account_type'] ?? '',
      name: json['name'] ?? '',
      businessName: json['business_name'] ?? '',
      business_id: json['business_id'] ?? '',
      categoryOfBusiness: json['categoryOfBusiness'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'profile_image': profileImage,
      'designation': designation,
      'account_type': accountType,
      'name': name,
      'business_name': businessName,
      'business_id': business_id,
      'categoryOfBusiness': categoryOfBusiness,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? profileImage,
    String? designation,
    String? accountType,
    String? name,
    String? businessName,
    String? categoryOfBusiness,
    String? natureOfBusiness,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      designation: designation ?? this.designation,
      accountType: accountType ?? this.accountType,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      categoryOfBusiness: categoryOfBusiness ?? this.categoryOfBusiness,
    );
  }
}

class Poll {
  final String? question;
  final List<PollOption> options;

  Poll({
    this.question,
    required this.options,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      question: json['question'],
      options: (json['options'] as List?)
              ?.map((e) => PollOption.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  Poll copyWith({
    String? question,
    List<PollOption>? options,
  }) {
    return Poll(
      question: question ?? this.question,
      options: options ?? this.options,
    );
  }
}

class PollOption {
  final String text;
  final bool isCorrect;
  List<String>? votes;

  PollOption({
    required this.text,
    required this.isCorrect,
    required this.votes,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      votes: (json['votes'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCorrect': isCorrect,
      'votes': votes,
    };
  }

  PollOption copyWith({
    String? text,
    bool? isCorrect,
    // int? votes,

    List<String>? votes,
  }) {
    return PollOption(
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      votes: votes ?? this.votes,
    );
  }
}

class CategoryDetails {
  final String id;
  final String name;

  CategoryDetails({
    required this.id,
    required this.name,
  });

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name};
  }

  CategoryDetails copyWith({String? id, String? name}) {
    return CategoryDetails(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

class SubCategoryDetails {
  final String id;
  final String name;

  SubCategoryDetails({
    required this.id,
    required this.name,
  });

  factory SubCategoryDetails.fromJson(Map<String, dynamic> json) {
    return SubCategoryDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name};
  }

  SubCategoryDetails copyWith({String? id, String? name}) {
    return SubCategoryDetails(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

class Pagination {
  final int? page;
  final int? limit;
  final String? type;

  Pagination({
    this.page,
    this.limit,
    this.type,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'type': type,
    };
  }

  Pagination copyWith({
    int? page,
    int? limit,
    String? type,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      type: type ?? this.type,
    );
  }
}

class Song {
  final String id;
  final String name;
  final String artist;
  final String coverUrl;
  final String externalUrl;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.coverUrl,
    required this.externalUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      externalUrl: json['externalUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "artist": artist,
      "coverUrl": coverUrl,
      "externalUrl": externalUrl,
    };
  }
}
