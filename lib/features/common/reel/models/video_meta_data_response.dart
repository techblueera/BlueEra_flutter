// video_meta_data_response.dart
class VideoMetaDataResponse {
  final bool? success;
  final VideoMetaData? data;

  const VideoMetaDataResponse({this.success, this.data});

  factory VideoMetaDataResponse.fromJson(Map<String, dynamic> json) =>
      VideoMetaDataResponse(
        success: json['success'] as bool,
        data: json['data'] == null
            ? null
            : VideoMetaData.fromJson(json['data'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data?.toJson(),
  };
}

class VideoMetaData {
  final TranscodedUrls transcodedUrls;
  final Location? location;
  final String id;
  final String userId;
  final String? channelId;
  final String type;
  final String status;
  final String title;
  final String caption;
  final String coverUrl;
  final String videoUrl;
  final int duration;
  final String? visibility;
  final List<String> keywords;
  final List<String> categories;
  final bool isCollaboration;
  final bool allowComments;
  final List<TaggedUser> taggedUsers;
  final List<dynamic> taggedChannelProducts;
  final bool isMatureContent;
  final String? relatedVideoLink;
  final bool isBrandPromotion;
  final String? brandPromotionLink;
  final bool acceptBookingsOrEnquiries;
  final bool isFlagged;
  final List<dynamic> reports;
  final Song? song;
  final String createdAt;
  final String updatedAt;
  final int v;

  const VideoMetaData({
    required this.transcodedUrls,
    this.location,
    required this.id,
    required this.userId,
    this.channelId,
    required this.type,
    required this.status,
    required this.title,
    required this.caption,
    required this.coverUrl,
    required this.videoUrl,
    required this.duration,
    this.visibility,
    required this.keywords,
    required this.categories,
    required this.isCollaboration,
    required this.allowComments,
    required this.taggedUsers,
    required this.taggedChannelProducts,
    required this.isMatureContent,
    this.relatedVideoLink,
    required this.isBrandPromotion,
    this.brandPromotionLink,
    required this.acceptBookingsOrEnquiries,
    required this.isFlagged,
    required this.reports,
    required this.song,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory VideoMetaData.fromJson(Map<String, dynamic> json) => VideoMetaData(
    transcodedUrls:
    TranscodedUrls.fromJson(json['transcodedUrls'] as Map<String, dynamic>),
    location: json['location'] == null
        ? null
        : Location.fromJson(json['location'] as Map<String, dynamic>),
    id: json['_id'] as String,
    userId: json['userId'] as String,
    channelId: json['channelId'] as String?,
    type: json['type'] as String,
    status: json['status'] as String,
    title: json['title'] as String,
    caption: json['caption'] as String,
    coverUrl: json['coverUrl'] as String,
    videoUrl: json['videoUrl'] as String,
    duration: json['duration'] as int,
    visibility: json['visibility'] as String?,
    keywords: List<String>.from(json['keywords'] as List<dynamic>? ?? []),
    categories: List<String>.from(json['categories'] as List<dynamic>? ?? []),
    isCollaboration: json['isCollaboration'] as bool,
    allowComments: json['allowComments'] as bool,
    taggedUsers: (json['taggedUsers'] as List<dynamic>? ?? [])
        .map((e) => TaggedUser.fromJson(e as Map<String, dynamic>))
        .toList(),
    taggedChannelProducts:
    List<dynamic>.from(json['taggedChannelProducts'] as List? ?? []),
    isMatureContent: json['isMatureContent'] as bool,
    relatedVideoLink: json['relatedVideoLink'] as String?,
    isBrandPromotion: json['isBrandPromotion'] as bool,
    brandPromotionLink: json['brandPromotionLink'] as String?,
    acceptBookingsOrEnquiries: json['acceptBookingsOrEnquiries'] as bool,
    isFlagged: json['isFlagged'] as bool,
    reports: List<dynamic>.from(json['reports'] as List? ?? []),
    song: json['song'] == null
        ? null
        : Song.fromJson(json['song'] as Map<String, dynamic>),
    createdAt: json['createdAt'] as String,
    updatedAt: json['updatedAt'] as String,
    v: json['__v'] as int,
  );

  Map<String, dynamic> toJson() => {
    'transcodedUrls': transcodedUrls.toJson(),
    'location': location?.toJson(),
    '_id': id,
    'userId': userId,
    'channelId': channelId,
    'type': type,
    'status': status,
    'title': title,
    'caption': caption,
    'coverUrl': coverUrl,
    'videoUrl': videoUrl,
    'duration': duration,
    'visibility': visibility,
    'keywords': keywords,
    'categories': categories,
    'isCollaboration': isCollaboration,
    'allowComments': allowComments,
    'taggedUsers': taggedUsers.map((e) => e.toJson()).toList(),
    'taggedChannelProducts': taggedChannelProducts,
    'isMatureContent': isMatureContent,
    'relatedVideoLink': relatedVideoLink,
    'isBrandPromotion': isBrandPromotion,
    'brandPromotionLink': brandPromotionLink,
    'acceptBookingsOrEnquiries': acceptBookingsOrEnquiries,
    'isFlagged': isFlagged,
    'reports': reports,
    'song': song?.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class TranscodedUrls {
  final String s360p;
  final String s720p;
  final String s1080p;

  const TranscodedUrls({
    required this.s360p,
    required this.s720p,
    required this.s1080p,
  });

  factory TranscodedUrls.fromJson(Map<String, dynamic> json) => TranscodedUrls(
    s360p: json['360p'] as String,
    s720p: json['720p'] as String,
    s1080p: json['1080p'] as String,
  );

  Map<String, dynamic> toJson() => {
    '360p': s360p,
    '720p': s720p,
    '1080p': s1080p,
  };
}

class Location {
  final String name;
  final double lat;
  final double lng;

  const Location({
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    name: json['name'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': lat,
    'lng': lng,
  };
}

class TaggedUser {
  final String id;
  final String name;

  const TaggedUser({required this.id, required this.name});

  factory TaggedUser.fromJson(Map<String, dynamic> json) => TaggedUser(
    id: json['id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Song {
  final String? id;
  final String? name;
  final String? artist;
  final String? coverUrl;

  Song({this.id,  this.name, this.artist, this.coverUrl});

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'] as String,
    name: json['name'] as String,
    artist: json['artist'] as String,
    coverUrl: json['coverUrl'] as String
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'coverUrl': coverUrl,
  };
}
