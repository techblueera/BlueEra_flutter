class VideoResponse {
  final bool? success;
  final String? message;
  final VideoFeedData? data;
  final String? timestamp;
  final String? version;
  final Pagination? pagination;

  VideoResponse({
    this.success,
    this.message,
    this.data,
    this.timestamp,
    this.version,
    this.pagination,
  });

  factory VideoResponse.fromJson(Map<String, dynamic> json) {
    return VideoResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? VideoFeedData.fromJson(json['data']) : null,
      timestamp: json['timestamp'],
      version: json['version'],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  /// Parser for the `GET /videos/hot/:type` (trending) response, whose shape
  /// differs from the unified feed: `data` is a **flat array of raw Video
  /// objects** (no author/channel/interactions resolution, `isLiked` always
  /// false) and `pagination` carries `page/limit/total/totalPages` with **no**
  /// `hasMore` flag. We wrap each raw video into a [ShortFeedItem] so the rest
  /// of the shorts pipeline (which expects `data.videos`) is unchanged, and we
  /// derive `hasMore` from `page < totalPages`.
  factory VideoResponse.fromHotJson(Map<String, dynamic> json) {
    // The hot/trending endpoint returns a FLAT video object per item, with
    // `author` and `isLiked` as SIBLING fields (no `channel`, no nested
    // `video`/`interactions` wrapper). Parse them here too — otherwise the
    // player has no avatar / name / @handle / like-state to show.
    final items = (json['data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) {
              final author = e['author'] is Map<String, dynamic>
                  ? Author.fromJson(e['author'] as Map<String, dynamic>)
                  : null;
              return ShortFeedItem(
                videoId: e['_id'] as String?,
                video: VideoData.fromJson(e),
                author: author,
                // Follow state ships on the author here, not in an
                // `interactions` block. Mirror it so consumers can read it
                // from the same place as the unified feed.
                interactions: Interactions(
                  isLiked: e['isLiked'] as bool? ?? false,
                  isFollowing: author?.isFollowing ?? false,
                ),
              );
            })
            .toList() ??
        <ShortFeedItem>[];

    Pagination? pagination;
    final p = json['pagination'];
    if (p is Map<String, dynamic>) {
      final page = (p['page'] as num?)?.toInt();
      final totalPages = (p['totalPages'] as num?)?.toInt();
      // The random-order hot feed now returns `hasMore` (and a shuffle `seed`)
      // directly. Honour the explicit flag when present; otherwise fall back to
      // deriving it from page/totalPages for older responses.
      final serverHasMore = p['hasMore'] as bool?;
      pagination = Pagination(
        page: page,
        limit: (p['limit'] as num?)?.toInt(),
        totalVideos: ((p['total'] ?? p['totalVideos']) as num?)?.toInt(),
        totalPages: totalPages,
        hasMore: serverHasMore ??
            ((page != null && totalPages != null) ? page < totalPages : false),
        seed: p['seed']?.toString(),
      );
    }

    return VideoResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: VideoFeedData(feedType: 'hot', videos: items),
      pagination: pagination,
    );
  }

  VideoResponse copyWith({
    bool? success,
    String? message,
    VideoFeedData? data,
    String? timestamp,
    String? version,
    Pagination? pagination,
  }) {
    return VideoResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      version: version ?? this.version,
      pagination: pagination ?? this.pagination,
    );
  }
}

class VideoFeedData {
  final bool? success;
  final String? feedType;
  final List<ShortFeedItem>? videos;
  final Metadata? metadata;

  VideoFeedData({
    this.success,
    this.feedType,
    this.videos,
    this.metadata,
  });

  factory VideoFeedData.fromJson(Map<String, dynamic> json) {
    return VideoFeedData(
      success: json['success'],
      feedType: json['feedType'],
      videos: (json['videos'] as List?)
          ?.map((e) => ShortFeedItem.fromJson(e))
          .toList(),
      metadata:
          json['metadata'] != null ? Metadata.fromJson(json['metadata']) : null,
    );
  }

  VideoFeedData copyWith({
    bool? success,
    String? feedType,
    List<ShortFeedItem>? videos,
    Metadata? metadata,
  }) {
    return VideoFeedData(
      success: success ?? this.success,
      feedType: feedType ?? this.feedType,
      videos: videos ?? this.videos,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ShortFeedItem {
  final String? videoId;
  final int? position;
  final dynamic score;
  final String? reason;
  final VideoData? video;
  final Author? author;
  final Channel? channel;
  final Interactions? interactions;
  final VideoItemMetadata? metadata;

  final int? commentsCount;
  final int? likesCount;
  final int? repostCount;
  final int? viewsCount;
  final int? sharesCount;

  ShortFeedItem({
    this.commentsCount,
    this.likesCount,
    this.repostCount,
    this.viewsCount,
    this.sharesCount,
    this.videoId,
    this.position,
    this.score,
    this.reason,
    this.video,
    this.author,
    this.channel,
    this.interactions,
    this.metadata,
  });

  factory ShortFeedItem.fromJson(Map<String, dynamic> json) {
    return ShortFeedItem(
      videoId: json['videoId'],
      position: json['position'],
      score: json['score'],
      reason: json['reason'],
      video: json['video'] != null ? VideoData.fromJson(json['video']) : null,
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      channel:
          json['channel'] != null ? Channel.fromJson(json['channel']) : null,
      interactions: json['interactions'] != null
          ? Interactions.fromJson(json['interactions'])
          : null,
      metadata: json['metadata'] != null
          ? VideoItemMetadata.fromJson(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'position': position,
        'score': score,
        'reason': reason,
        'video': video?.toJson(),
        'author': author?.toJson(),
        'channel': channel?.toJson(),
        'interactions': interactions?.toJson(),
        'metadata': metadata?.toJson(),
      };

  ShortFeedItem copyWith({
    String? videoId,
    int? position,
    dynamic score,
    String? reason,
    VideoData? video,
    Author? author,
    Channel? channel,
    Interactions? interactions,
    VideoItemMetadata? metadata,
    int? commentsCount,
    int? likesCount,
    int? repostCount,
    int? viewsCount,
    int? sharesCount,
  }) {
    return ShortFeedItem(
      videoId: videoId ?? this.videoId,
      position: position ?? this.position,
      score: score ?? this.score,
      reason: reason ?? this.reason,
      video: video ?? this.video,
      author: author ?? this.author,
      channel: channel ?? this.channel,
      interactions: interactions ?? this.interactions,
      metadata: metadata ?? this.metadata,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}

class VideoData {
  final String? id;
  final String? userId;
  final String? channelId;
  final String? type;
  final String? status;
  final String? title;
  final String? subheading;
  final String? description;
  final String? caption;
  final String? coverUrl;
  final String? videoUrl;
  final int? duration;
  TranscodedUrls? transcodedUrls;
  final List<String>? tags;
  final List<String>? keywords;
  final List<Categories>? categories;
  final Location? location;
  final Song? song;
  final bool? isCollaboration;
  final bool? allowComments;
  final bool? allowGifting;
  final List<TaggedUser>? taggedUsers;
  final bool? isMatureContent;
  final String? relatedVideoLink;
  final bool? acceptBookingsOrEnquiries;
  final bool? isBrandPromotion;
  final String? brandPromotionLink;
  final Stats? stats;
  final String? createdAt;
  final String? updatedAt;
  final num? media_height;
  final num? media_width;

  VideoData({
    this.id,
    this.userId,
    this.channelId,
    this.type,
    this.status,
    this.title,
    this.subheading,
    this.description,
    this.caption,
    this.coverUrl,
    this.videoUrl,
    this.duration,
    this.transcodedUrls,
    this.tags,
    this.keywords,
    this.categories,
    this.location,
    this.song,
    this.isCollaboration,
    this.allowComments,
    this.allowGifting,
    this.taggedUsers,
    this.isMatureContent,
    this.relatedVideoLink,
    this.acceptBookingsOrEnquiries,
    this.isBrandPromotion,
    this.brandPromotionLink,
    this.stats,
    this.createdAt,
    this.updatedAt,
    this.media_width,
    this.media_height,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['_id'],
      userId: json['userId'],
      channelId: json['channelId'],
      type: json['type'],
      status: json['status'],
      title: json['title'],
      subheading: json['subheading'],
      description: json['description'],
      caption: json['caption'],
      coverUrl: json['coverUrl'],
      videoUrl: json['videoUrl'],
      duration: (json['duration'] as num?)?.toInt(),
      transcodedUrls: json['transcodedUrls'] != null
          ? TranscodedUrls.fromJson(json['transcodedUrls'])
          : null,
      tags: (json['tags'] as List?)?.cast<String>(),
      keywords: (json['keywords'] as List?)?.cast<String>(),
      categories: (json['categories'] as List?)
          ?.map((e) => e is Map<String, dynamic>
              ? Categories.fromJson(e)
              : Categories(id: e?.toString()))
          .toList(),
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      song: json['song'] != null ? Song.fromJson(json['song']) : null,
      isCollaboration: json['isCollaboration'],
      allowComments: json['allowComments'],
      allowGifting: json['allowGifting'],
      taggedUsers: (json['taggedUsers'] as List?)
          ?.map((e) => e is Map<String, dynamic>
              ? TaggedUser.fromJson(e)
              : TaggedUser(id: e?.toString()))
          .toList(),
      isMatureContent: json['isMatureContent'],
      relatedVideoLink: json['relatedVideoLink'],
      acceptBookingsOrEnquiries: json['acceptBookingsOrEnquiries'],
      isBrandPromotion: json['isBrandPromotion'],
      brandPromotionLink: json['brandPromotionLink'],
      stats: json['stats'] != null ? Stats.fromJson(json['stats']) : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      media_height: json['media_height'],
      media_width: json['media_width'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'channelId': channelId,
        'type': type,
        'status': status,
        'title': title,
        'subheading': subheading,
        'description': description,
        'caption': caption,
        'coverUrl': coverUrl,
        'videoUrl': videoUrl,
        'duration': duration,
        'transcodedUrls': transcodedUrls?.toJson(),
        'tags': tags,
        'keywords': keywords,
        'categories': categories?.map((c) => c.toJson()).toList(),
        'location': location?.toJson(),
        'song': song?.toJson(),
        'isCollaboration': isCollaboration,
        'allowComments': allowComments,
        'allowGifting': allowGifting,
        'taggedUsers': taggedUsers?.map((c) => c.toJson()).toList(),
        'isMatureContent': isMatureContent,
        'relatedVideoLink': relatedVideoLink,
        'acceptBookingsOrEnquiries': acceptBookingsOrEnquiries,
        'isBrandPromotion': isBrandPromotion,
        'brandPromotionLink': brandPromotionLink,
        'stats': stats?.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
    'media_width': media_width,
    'media_height': media_height,
      };

  VideoData copyWith({
    String? id,
    String? userId,
    String? channelId,
    String? type,
    String? status,
    String? title,
    String? subheading,
    String? description,
    String? caption,
    String? coverUrl,
    String? videoUrl,
    int? duration,
    TranscodedUrls? transcodedUrls,
    List<String>? tags,
    List<String>? keywords,
    List<Categories>? categories,
    Location? location,
    Song? song,
    bool? isCollaboration,
    bool? allowComments,
    bool? allowGifting,
    List<TaggedUser>? taggedUsers,
    bool? isMatureContent,
    String? relatedVideoLink,
    bool? acceptBookingsOrEnquiries,
    bool? isBrandPromotion,
    String? brandPromotionLink,
    Stats? stats,
    String? createdAt,
    String? updatedAt,
     num? media_height,
     num? media_width,
  }) {
    return VideoData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      subheading: subheading ?? this.subheading,
      description: description ?? this.description,
      caption: caption ?? this.caption,
      coverUrl: coverUrl ?? this.coverUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      transcodedUrls: transcodedUrls ?? this.transcodedUrls,
      tags: tags ?? this.tags,
      keywords: keywords ?? this.keywords,
      categories: categories ?? this.categories,
      location: location ?? this.location,
      song: song ?? this.song,
      isCollaboration: isCollaboration ?? this.isCollaboration,
      allowComments: allowComments ?? this.allowComments,
      allowGifting: allowGifting ?? this.allowGifting,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      isMatureContent: isMatureContent ?? this.isMatureContent,
      relatedVideoLink: relatedVideoLink ?? this.relatedVideoLink,
      acceptBookingsOrEnquiries:
          acceptBookingsOrEnquiries ?? this.acceptBookingsOrEnquiries,
      isBrandPromotion: isBrandPromotion ?? this.isBrandPromotion,
      brandPromotionLink: brandPromotionLink ?? this.brandPromotionLink,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      media_height: media_height ?? this.media_height,
      media_width: media_width ?? this.media_width,
    );
  }
}

class TranscodedUrls {
  final String? master;
  final String? p360;
  final String? p432;
  final String? p540;
  final String? p720;
  final String? p720High;
  final String? p1080;
  final String? p1200;

  const TranscodedUrls({
    this.master,
    this.p360,
    this.p432,
    this.p540,
    this.p720,
    this.p720High,
    this.p1080,
    this.p1200,
  });

  factory TranscodedUrls.fromJson(Map<String, dynamic> json) {
    return TranscodedUrls(
      master: json['master'],
      p360: json['360p'],
      p432: json['432p'],
      p540: json['540p'],
      p720: json['720p'],
      p720High: json['720p-high'],
      p1080: json['1080p'],
      p1200: json['1200p'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'master': master,
      '360p': p360,
      '432p': p432,
      '540p': p540,
      '720p': p720,
      '720p-high': p720High,
      '1080p': p1080,
      '1200p': p1200,
    };
  }

  TranscodedUrls copyWith({
    String? master,
    String? p360,
    String? p432,
    String? p540,
    String? p720,
    String? p720High,
    String? p1080,
    String? p1200,
  }) {
    return TranscodedUrls(
      master: master ?? this.master,
      p360: p360 ?? this.p360,
      p432: p432 ?? this.p432,
      p540: p540 ?? this.p540,
      p720: p720 ?? this.p720,
      p720High: p720High ?? this.p720High,
      p1080: p1080 ?? this.p1080,
      p1200: p1200 ?? this.p1200,
    );
  }
}

class Categories {
  final String? id;
  final String? name;
  final String? slug;
  final String? description;

  const Categories({
    this.id,
    this.name,
    this.slug,
    this.description,
  });

  /* ---------- fromJson ---------- */
  factory Categories.fromJson(Map<String, dynamic> json) => Categories(
        id: json['_id'] as String?,
        name: json['name'] as String?,
        slug: json['slug'] as String?,
        description: json['description'] as String?,
      );

  /* ---------- toJson ---------- */
  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        'description': description,
      };

  /* ---------- copyWith ---------- */
  Categories copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
  }) =>
      Categories(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        description: description ?? this.description,
      );
}

class TaggedUser {
  final String? id;
  final String? username;
  final String? accountType;
  final String? profileImage;
  final String? name;
  final String? designation;
  final bool? isVerified;
  final int? followersCount;

  TaggedUser({
    this.id,
    this.username,
    this.accountType,
    this.profileImage,
    this.name,
    this.designation,
    this.isVerified,
    this.followersCount,
  });

  factory TaggedUser.fromJson(Map<String, dynamic> json) {
    return TaggedUser(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      accountType: json['account_type'] ?? '',
      profileImage: json['profile_image'] ?? '',
      name: json['name'] ?? '',
      designation: json['designation'] ?? '',
      isVerified: json['isVerified'] ?? false,
      followersCount: json['followersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'account_type': accountType,
      'profile_image': profileImage,
      'name': name,
      'designation': designation,
      'isVerified': isVerified,
      'followersCount': followersCount,
    };
  }

  TaggedUser copyWith({
    String? id,
    String? username,
    String? accountType,
    String? profileImage,
    String? name,
    String? designation,
    bool? isVerified,
    int? followersCount,
  }) {
    return TaggedUser(
      id: id ?? this.id,
      username: username ?? this.username,
      accountType: accountType ?? this.accountType,
      profileImage: profileImage ?? this.profileImage,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}

class Location {
  final String? name;
  final double? lat;
  final double? lng;

  const Location({
    this.name,
    this.lat,
    this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
    };
  }

  Location copyWith({
    String? name,
    double? lat,
    double? lng,
  }) {
    return Location(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class Song {
  final String? id;
  final String? name;
  final String? artist;
  final String? coverUrl;

  Song({this.id, this.name, this.artist, this.coverUrl});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      coverUrl: json['coverUrl'],
    );
  }

  Song copyWith({
    String? id,
    String? name,
    String? artist,
    String? coverUrl,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'coverUrl': coverUrl,
    };
  }
}

class Stats {
  int? views;
  int? likes;
  int? shares;
  int? comments;
  int? repost_count;

  Stats({
    this.views,
    this.likes,
    this.shares,
    this.comments,
    this.repost_count,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      views: (json['views'] as num?)?.toInt(),
      likes: (json['likes'] as num?)?.toInt(),
      shares: (json['shares'] as num?)?.toInt(),
      comments: (json['comments'] as num?)?.toInt(),
      repost_count: (json['repost_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'likes': likes,
      'shares': shares,
      'comments': comments,
      'repost_count': repost_count,
    };
  }

  Stats copyWith({
    int? views,
    int? likes,
    int? shares,
    int? comments,
    int? repost_count,
  }) {
    return Stats(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      comments: comments ?? this.comments,
      repost_count: repost_count ?? this.repost_count,
    );
  }
}

/// author.dart
class Author {
  final String? id; // Common id for both business and personal accounts
  final String? accountType;
  final String? username;
  final String? profileImage; // Common profile image
  final String? name; // Common name
  final String? designation; // Common designation
  final bool? isVerified;
  final int? followersCount;
  final bool? isFollowing;
  // Routing taxonomy used by [VisitProfileResolver] to open the right visit
  // screen for a tapped author:
  //  - [typeOfBusiness]     → BusinessType (Food / Grocery / Automotive / …)
  //  - [categoryOfBusiness] → business sub-category slug (e.g. AUTO_PARTS)
  //  - [profileType]        → individual profile type (SELF_EMPLOYED /
  //                            PROFESSIONAL / GIG_WORKER / SOCIAL_PROFILE)
  final String? businessType;
  final String? categoryOfBusiness;
  final String? profileType;

  const Author({
    this.id,
    this.accountType,
    this.username,
    this.profileImage,
    required this.name,
    this.designation,
    this.isVerified,
    this.followersCount,
    this.isFollowing,
    this.businessType,
    this.categoryOfBusiness,
    this.profileType,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['_id'] as String?,
        accountType: json['account_type'] as String?,
        username: json['username'] as String?,
        profileImage: json['profile_image'] as String?,
        name: json['name'] as String? ?? '',
        designation: json['designation'] as String?,
        isVerified: json['isVerified'] as bool?,
        followersCount: json['followersCount'] as int?,
        isFollowing: json['isFollowing'] as bool?,
        // Defensive key fallbacks — backends vary between camelCase and
        // snake_case for these fields.
        businessType:
            (json['businessType'] ?? json['businessType']) as String?,
        categoryOfBusiness: (json['categoryOfBusiness'] ??
            json['category_of_business']) as String?,
        profileType:
            (json['profileType'] ?? json['profile_type']) as String?,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'account_type': accountType,
        'username': username,
        'profile_image': profileImage,
        'name': name,
        'designation': designation,
        'isVerified': isVerified,
        'followersCount': followersCount,
        'isFollowing': isFollowing,
      };

  Author copyWith({
    String? id,
    String? accountType,
    String? username,
    String? profileImage,
    String? name,
    String? designation,
    bool? isVerified,
    int? followersCount,
    bool? isFollowing,
    String? businessType,
    String? categoryOfBusiness,
    String? profileType,
  }) {
    return Author(
      id: id ?? this.id,
      accountType: accountType ?? this.accountType,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
      businessType: businessType ?? this.businessType,
      categoryOfBusiness: categoryOfBusiness ?? this.categoryOfBusiness,
      profileType: profileType ?? this.profileType,
    );
  }
}

class Channel {
  final List<String>? websites;
  final String? id;
  final String? name;
  final String? username;
  final String? bio;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? category;
  final String? gstCode;
  final bool? isVerified;
  final String? claimedBy;
  final String? createdAt;
  final String? updatedAt;
  final bool? isFollowing;

  Channel({
    this.websites,
    this.id,
    this.name,
    this.username,
    this.bio,
    this.logoUrl,
    this.coverImageUrl,
    this.category,
    this.gstCode,
    this.isVerified,
    this.claimedBy,
    this.createdAt,
    this.updatedAt,
    this.isFollowing,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      websites: (json['websites'] as List?)?.cast<String>(),
      id: json['_id'],
      name: json['name'],
      username: json['username'],
      bio: json['bio'],
      logoUrl: json['logoUrl'],
      coverImageUrl: json['coverImageUrl'],
      category: json['category'],
      gstCode: json['gstCode'],
      isVerified: json['isVerified'],
      claimedBy: json['claimedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isFollowing: json['isFollowing'],
    );
  }

  Map<String, dynamic> toJson() => {
        'websites': websites,
        '_id': id,
        'name': name,
        'username': username,
        'bio': bio,
        'logoUrl': logoUrl,
        'coverImageUrl': coverImageUrl,
        'category': category,
        'gstCode': gstCode,
        'isVerified': isVerified,
        'claimedBy': claimedBy,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isFollowing': isFollowing,
      };

  Channel copyWith({
    List<String>? websites,
    String? id,
    String? name,
    String? username,
    String? bio,
    String? logoUrl,
    String? coverImageUrl,
    String? category,
    String? gstCode,
    bool? isVerified,
    String? claimedBy,
    String? createdAt,
    String? updatedAt,
    bool? isFollowing,
  }) {
    return Channel(
      websites: websites ?? this.websites,
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      gstCode: gstCode ?? this.gstCode,
      isVerified: isVerified ?? this.isVerified,
      claimedBy: claimedBy ?? this.claimedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class Interactions {
  bool? isLiked;
  final bool? isBookmarked;
  final bool? isFollowing;

  Interactions({
    this.isLiked,
    this.isBookmarked,
    this.isFollowing,
  });

  factory Interactions.fromJson(Map<String, dynamic> json) {
    return Interactions(
      isLiked: json['isLiked'],
      isBookmarked: json['isBookmarked'],
      isFollowing: json['isFollowing'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'isFollowing': isFollowing,
    };
  }

  Interactions copyWith({
    bool? isLiked,
    bool? isBookmarked,
    bool? isFollowing,
  }) {
    return Interactions(
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class VideoItemMetadata {
  final String? addedAt;
  final String? source;
  final bool? watchedBefore;

  VideoItemMetadata({
    this.addedAt,
    this.source,
    this.watchedBefore,
  });

  factory VideoItemMetadata.fromJson(Map<String, dynamic> json) {
    return VideoItemMetadata(
      addedAt: json['addedAt'],
      source: json['source'],
      watchedBefore: json['watchedBefore'],
    );
  }

  VideoItemMetadata copyWith({
    String? addedAt,
    String? source,
    bool? watchedBefore,
  }) {
    return VideoItemMetadata(
      addedAt: addedAt ?? this.addedAt,
      source: source ?? this.source,
      watchedBefore: watchedBefore ?? this.watchedBefore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addedAt': addedAt,
      'source': source,
      'watchedBefore': watchedBefore,
    };
  }
}

class Metadata {
  final int? totalVideos;
  final String? algorithm;
  final String? lastUpdated;
  final String? version;
  final Composition? composition;
  final int? page;
  final int? limit;

  Metadata({
    this.totalVideos,
    this.algorithm,
    this.lastUpdated,
    this.version,
    this.composition,
    this.page,
    this.limit,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      totalVideos: json['totalVideos'],
      algorithm: json['algorithm'],
      lastUpdated: json['lastUpdated'],
      version: json['version'],
      composition: json['composition'] != null
          ? Composition.fromJson(json['composition'])
          : null,
      page: json['page'],
      limit: json['limit'],
    );
  }

  Metadata copyWith({
    int? totalVideos,
    String? algorithm,
    String? lastUpdated,
    String? version,
    Composition? composition,
    int? page,
    int? limit,
  }) {
    return Metadata(
      totalVideos: totalVideos ?? this.totalVideos,
      algorithm: algorithm ?? this.algorithm,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      composition: composition ?? this.composition,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class Composition {
  final int? trending;
  final int? personalized;

  Composition({this.trending, this.personalized});

  factory Composition.fromJson(Map<String, dynamic> json) {
    return Composition(
      trending: json['trending'],
      personalized: json['personalized'],
    );
  }

  Composition copyWith({
    int? trending,
    int? personalized,
  }) {
    return Composition(
      trending: trending ?? this.trending,
      personalized: personalized ?? this.personalized,
    );
  }
}

class Pagination {
  final int? page;
  final int? limit;
  final int? totalVideos;
  final int? totalPages;
  final bool? hasMore;

  /// Shuffle seed for the random-order hot feed (`/videos/hot/:type`). The
  /// server mints one on page 1 and the client replays it on later pages so a
  /// session paginates a stable random order with zero repeats. String.
  final String? seed;

  Pagination({
    this.page,
    this.limit,
    this.totalVideos,
    this.totalPages,
    this.hasMore,
    this.seed,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      totalVideos: (json['totalVideos'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      hasMore: json['hasMore'],
      seed: json['seed']?.toString(),
    );
  }

  Pagination copyWith({
    int? page,
    int? limit,
    int? totalVideos,
    int? totalPages,
    bool? hasMore,
    String? seed,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalVideos: totalVideos ?? this.totalVideos,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      seed: seed ?? this.seed,
    );
  }
}
