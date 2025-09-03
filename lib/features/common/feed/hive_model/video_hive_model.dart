import 'package:hive/hive.dart';

part 'video_hive_model.g.dart';

@HiveType(typeId: 5)
class VideoFeedItemHive extends HiveObject {
  @HiveField(0) final String? videoId;
  @HiveField(1) final int? position;
  @HiveField(2) final String? score; // store as String for Hive
  @HiveField(3) final String? reason;
  @HiveField(4) final VideoDataHive? video;
  @HiveField(5) final AuthorHive? author;
  @HiveField(6) final ChannelHive? channel;

  VideoFeedItemHive({
    this.videoId,
    this.position,
    this.score,
    this.reason,
    this.video,
    this.author,
    this.channel
  });

  /* ---------- from JSON ---------- */
  factory VideoFeedItemHive.fromJson(Map<String, dynamic> json) =>
      VideoFeedItemHive(
        videoId: json['videoId'] as String?,
        position: json['position'] as int?,
        score: json['score']?.toString(),
        reason: json['reason'] as String?,
        video: json['video'] != null
            ? VideoDataHive.fromJson(json['video'] as Map<String, dynamic>)
            : null,
        author: json['author'] != null
            ? AuthorHive.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        channel: json['channel'] != null
            ? ChannelHive.fromJson(json['channel'] as Map<String, dynamic>)
            : null,
      );

  /* ---------- to JSON ---------- */
  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'position': position,
    'score': score,
    'reason': reason,
    'video': video?.toJson(),
    'author': author?.toJson(),
    'channel': channel?.toJson(),
  };
}

@HiveType(typeId: 6)
class VideoDataHive {
  @HiveField(0)  String?  id;
  @HiveField(1)  String?  userId;
  @HiveField(2)  String?  channelId;
  @HiveField(3)  String?  type;
  @HiveField(4)  String?  status;
  @HiveField(5)  String?  title;
  @HiveField(6)  String?  subheading;
  @HiveField(7)  String?  description;
  @HiveField(8)  String?  caption;
  @HiveField(9)  String?  coverUrl;
  @HiveField(10) String?  videoUrl;
  @HiveField(11) int?     duration;
  @HiveField(12) Map<String, String>? transcodedUrls;
  @HiveField(13) List<String>? tags;
  @HiveField(14) List<String>? keywords;
  @HiveField(15) List<CategoryHive>? categories;
  @HiveField(16) LocationHive? location;
  @HiveField(17) SongHive? song;
  @HiveField(18) bool? isCollaboration;
  @HiveField(19) bool? allowComments;
  @HiveField(20) bool? allowGifting;
  @HiveField(21) List<TaggedUserHive>? taggedUser;
  @HiveField(22) bool? isMatureContent;
  @HiveField(23) String? relatedVideoLink;
  @HiveField(24) bool? acceptBookingsOrEnquiries;
  @HiveField(25) bool? isBrandPromotion;
  @HiveField(26) String? brandPromotionLink;
  @HiveField(27) StatsHive? stats;
  @HiveField(28) String? createdAt;
  @HiveField(29) String? updatedAt;

  VideoDataHive({
    this.id, this.userId, this.channelId, this.type, this.status,
    this.title, this.subheading, this.description, this.caption,
    this.coverUrl, this.videoUrl, this.duration, this.transcodedUrls,
    this.tags, this.keywords, this.categories, this.song, this.location,
    this.isCollaboration, this.allowComments, this.allowGifting, this.taggedUser,
    this.isMatureContent, this.relatedVideoLink, this.acceptBookingsOrEnquiries,
    this.isBrandPromotion, this.brandPromotionLink, this.stats, this.createdAt, this.updatedAt,
  });

  /* ---------- fromJson ---------- */
  factory VideoDataHive.fromJson(Map<String, dynamic> json) => VideoDataHive(
    id: json['_id'] as String?,
    userId: json['userId'] as String?,
    channelId: json['channelId'] as String?,
    type: json['type'] as String?,
    status: json['status'] as String?,
    title: json['title'] as String?,
    subheading: json['subheading'] as String?,
    description: json['description'] as String?,
    caption: json['caption'] as String?,
    coverUrl: json['coverUrl'] as String?,
    videoUrl: json['videoUrl'] as String?,
    duration: json['duration'] as int?,
    transcodedUrls: (json['transcodedUrls'] as Map?)?.cast<String, String>(),
    tags: (json['tags'] as List?)?.cast<String>(),
    keywords: (json['keywords'] as List?)?.cast<String>(),
    categories: json['categories'] != null
        ? (json['categories'] as List)
        .map((e) => CategoryHive.fromJson(e as Map<String, dynamic>))
        .toList()
        : null,
    location: json['location'] != null
        ? LocationHive.fromJson(json['location'] as Map<String, dynamic>)
        : null,
    song: json['song'] != null
        ? SongHive.fromJson(json['song'] as Map<String, dynamic>)
        : null,
    isCollaboration: json['isCollaboration'] as bool?,
    allowComments: json['allowComments'] as bool?,
    taggedUser: json['taggedUser'] != null
        ? (json['taggedUser'] as List)
        .map((e) => TaggedUserHive.fromJson(e as Map<String, dynamic>))
        .toList()
        : null,
    allowGifting: json['allowGifting'] as bool?,
    isMatureContent: json['isMatureContent'] as bool?,
    relatedVideoLink: json['relatedVideoLink'] as String?,
    acceptBookingsOrEnquiries: json['acceptBookingsOrEnquiries'] as bool?,
    isBrandPromotion: json['isBrandPromotion'] as bool?,
    brandPromotionLink: json['brandPromotionLink'] as String?,
    stats: json['stats'] != null
        ? StatsHive.fromJson(json['stats'] as Map<String, dynamic>)
        : null,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );

  /* ---------- toJson ---------- */
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
    'transcodedUrls': transcodedUrls,
    'tags': tags,
    'keywords': keywords,
    'categories': categories,
    'location': location?.toJson(),
    'song': song?.toJson(),
    'isCollaboration': isCollaboration,
    'allowComments': allowComments,
    'allowGifting': allowGifting,
    'taggedUser': taggedUser,
    'isMatureContent': isMatureContent,
    'relatedVideoLink': relatedVideoLink,
    'acceptBookingsOrEnquiries': acceptBookingsOrEnquiries,
    'isBrandPromotion': isBrandPromotion,
    'brandPromotionLink': brandPromotionLink,
    'stats': stats?.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}


@HiveType(typeId: 7)
class AuthorHive {
  @HiveField(0) String? id;
  @HiveField(1) String? accountType;
  @HiveField(2) String? username;
  @HiveField(3) String? profileImage;
  @HiveField(4) String? name;
  @HiveField(5) String? designation;
  @HiveField(6) bool?   isVerified;
  @HiveField(7) int?    followersCount;

  AuthorHive({
    this.id,
    this.accountType,
    this.username,
    this.profileImage,
    required this.name,
    this.designation,
    this.isVerified,
    this.followersCount,
  });

  /* ---------- fromJson ---------- */
  factory AuthorHive.fromJson(Map<String, dynamic> json) => AuthorHive(
    id: json['_id'] as String?,
    accountType: json['account_type'] as String?,
    username: json['username'] as String?,
    profileImage: json['profile_image'] as String?,
    name: json['name'] as String,
    designation: json['designation'] as String?,
    isVerified: json['isVerified'] as bool?,
    followersCount: json['followersCount'] as int?,
  );

  /* ---------- toJson ---------- */
  Map<String, dynamic> toJson() => {
    '_id': id,
    'account_type': accountType,
    'username': username,
    'profile_image': profileImage,
    'name': name,
    'designation': designation,
    'isVerified': isVerified,
    'followersCount': followersCount,
  };
}

@HiveType(typeId: 8)
class ChannelHive {
  @HiveField(0)  List<String>? websites;
  @HiveField(1)  String?  id;
  @HiveField(2)  String?  name;
  @HiveField(3)  String?  username;
  @HiveField(4)  String?  bio;
  @HiveField(5)  String?  logoUrl;
  @HiveField(6)  String?  coverImageUrl;
  @HiveField(7)  String?  category;
  @HiveField(8)  String?  gstCode;
  @HiveField(9)  bool?    isVerified;
  @HiveField(10) String?  claimedBy;
  @HiveField(11) String?  createdAt;
  @HiveField(12) String?  updatedAt;
  @HiveField(13) bool?    isFollowing;

  ChannelHive({
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

  /* ---------- fromJson ---------- */
  factory ChannelHive.fromJson(Map<String, dynamic> json) => ChannelHive(
    websites: (json['websites'] as List?)?.cast<String>(),
    id: json['_id'] as String?,
    name: json['name'] as String?,
    username: json['username'] as String?,
    bio: json['bio'] as String?,
    logoUrl: json['logoUrl'] as String?,
    coverImageUrl: json['coverImageUrl'] as String?,
    category: json['category'] as String?,
    gstCode: json['gstCode'] as String?,
    isVerified: json['isVerified'] as bool?,
    claimedBy: json['claimedBy'] as String?,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    isFollowing: json['isFollowing'] as bool?,
  );

  /* ---------- toJson ---------- */
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
}

@HiveType(typeId: 9)
class CategoryHive {
  @HiveField(0) String? id;
  @HiveField(1) String? name;
  @HiveField(2) String? slug;
  @HiveField(3) String? description;

  CategoryHive({this.id, this.name, this.slug, this.description});

  /* ---------- fromJson ---------- */
  factory CategoryHive.fromJson(Map<String, dynamic> json) => CategoryHive(
    id: json['id'] as String?,
    name: json['name'] as String?,
    slug: json['slug'] as String?,
    description: json['description'] as String?,
  );

  /* ---------- toJson ---------- */
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description
  };
}

@HiveType(typeId: 10)
class TaggedUserHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String accountType;

  @HiveField(3)
  String profileImage;

  @HiveField(4)
  String name;

  @HiveField(5)
  String designation;

  @HiveField(6)
  bool isVerified;

  @HiveField(7)
  int followersCount;

  TaggedUserHive({
    required this.id,
    required this.username,
    required this.accountType,
    required this.profileImage,
    required this.name,
    required this.designation,
    required this.isVerified,
    required this.followersCount,
  });

  /// ✅ From JSON factory
  factory TaggedUserHive.fromJson(Map<String, dynamic> json) {
    return TaggedUserHive(
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

  /// ✅ To JSON method
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
}

@HiveType(typeId: 11)
class LocationHive {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  double? lat;

  @HiveField(3)
  double? lng;

  LocationHive({
    this.id,
    this.name,
    this.lat,
    this.lng,
  });

  /* ---------- fromJson ---------- */
  factory LocationHive.fromJson(Map<String, dynamic> json) => LocationHive(
    id: json['id'] as String?,
    name: json['name'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );

  /* ---------- toJson ---------- */
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
  };
}

@HiveType(typeId: 12)
class SongHive {
  @HiveField(0) String? id;
  @HiveField(1) String? name;
  @HiveField(2) String? artist;
  @HiveField(3) String? coverUrl;

  SongHive({this.id, this.name, this.artist, this.coverUrl});

  /* ---------- fromJson ---------- */
  factory SongHive.fromJson(Map<String, dynamic> json) => SongHive(
    id: json['id'] as String?,
    name: json['name'] as String?,
    artist: json['artist'] as String?,
    coverUrl: json['coverUrl'] as String?,
  );

  /* ---------- toJson ---------- */
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'coverUrl': coverUrl,
  };
}

@HiveType(typeId: 13)
class StatsHive {
  @HiveField(0) int? views;
  @HiveField(1) int? likes;
  @HiveField(2) int? shares;
  @HiveField(3) int? comments;

  StatsHive({this.views, this.likes, this.shares, this.comments});

  /* ---------- fromJson ---------- */
  factory StatsHive.fromJson(Map<String, dynamic> json) => StatsHive(
    views: json['views'] as int?,
    likes: json['likes'] as int?,
    shares: json['shares'] as int?,
    comments: json['comments'] as int?,
  );

  /* ---------- toJson ---------- */
  Map<String, dynamic> toJson() => {
    'views': views,
    'likes': likes,
    'shares': shares,
    'comments': comments,
  };
}