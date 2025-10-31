import 'dart:convert';
ChannelFeedModel channelFeedModelFromJson(String str) => ChannelFeedModel.fromJson(json.decode(str));
String channelFeedModelToJson(ChannelFeedModel data) => json.encode(data.toJson());
class ChannelFeedModel {
  ChannelFeedModel({
      this.success, 
      this.message, 
      this.data, 
      this.pagination,});

  ChannelFeedModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(ChannelFeedData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  String? message;
  List<ChannelFeedData>? data;
  Pagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }

}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());
class Pagination {
  Pagination({
      this.page, 
      this.limit, 
      this.total, 
      this.totalPages,});

  Pagination.fromJson(dynamic json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    totalPages = json['totalPages'];
  }
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['page'] = page;
    map['limit'] = limit;
    map['total'] = total;
    map['totalPages'] = totalPages;
    return map;
  }

}

// ChannelFeedData
ChannelFeedData dataFromJson(String str) => ChannelFeedData.fromJson(json.decode(str));
String dataToJson(ChannelFeedData data) => json.encode(data.toJson());
class ChannelFeedData {
  ChannelFeedData({
    this.ownership,
    this.id,
    this.name,
    this.username,
    this.bio,
    this.logoUrl,
    this.websites,

    this.createdAt,
    this.updatedAt,
    this.v,
    this.latestPost,});

  ChannelFeedData.fromJson(dynamic json) {
    ownership = json['ownership'] != null ? Ownership.fromJson(json['ownership']) : null;
    id = json['_id'];
    name = json['name'];
    username = json['username'];
    bio = json['bio'];
    logoUrl = json['logoUrl'];

    websites = json['websites'] != null ? json['websites'].cast<String>() : [];

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    posts = json["stats"]['posts'];
    followers = json["stats"]['followers'];
    v = json['__v'];
    latestPost = json['latestPost'] != null ? LatestPost.fromJson(json['latestPost']) : null;
  }
  Ownership? ownership;
  String? id;
  String? name;
  String? username;
  String? bio;
  String? logoUrl;
  List<String>? websites;
  String? createdAt;
  String? updatedAt;
  int? followers;
  int? posts;
  int? v;
  LatestPost? latestPost;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (ownership != null) {
      map['ownership'] = ownership?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    map['username'] = username;
    map['bio'] = bio;
    map['logoUrl'] = logoUrl;

    map['websites'] = websites;

    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['posts'] = posts;
    map['followers'] = followers;
    map['__v'] = v;
    if (latestPost != null) {
      map['latestPost'] = latestPost?.toJson();
    }
    return map;
  }

}

Ownership ownershipFromJson(String str) => Ownership.fromJson(json.decode(str));
String ownershipToJson(Ownership data) => json.encode(data.toJson());
class Ownership {
  Ownership({
      this.claimedBy, 
      this.claimedAt,});

  Ownership.fromJson(dynamic json) {
    claimedBy = json['claimedBy'];
    claimedAt = json['claimedAt'];
  }
  String? claimedBy;
  String? claimedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['claimedBy'] = claimedBy;
    map['claimedAt'] = claimedAt;
    return map;
  }

}

LatestPost latestPostFromJson(String str) => LatestPost.fromJson(json.decode(str));
String latestPostToJson(LatestPost data) => json.encode(data.toJson());
class LatestPost {
  LatestPost({
    this.media,
    this.mediaTypes,
    this.id,
    this.type,
    this.visibilityDuration,
    this.song,
    this.message,
    this.title,
    this.subTitle,
    this.natureOfPost,
    this.location,
    this.latitude,
    this.longitude,
    this.locationMetadata,
    this.mediaAspectRatio,
    this.postVia,
    this.referenceLink,
    this.authorId,
    this.createdBy,
    this.updatedBy,
    this.poll,
    this.commentsCount,
    this.likesCount,
    this.repostCount,
    this.viewsCount,
    this.sharesCount,
    this.isReposted,
    this.childrenPost,
    this.thumbnail,
    this.duration,});

  LatestPost.fromJson(dynamic json) {

    media = json['media'] != null ? json['media'].cast<String>() : [];
    mediaTypes = json['media_types'] != null ? json['media_types'].cast<String>() : [];
    id = json['id'];
    type = json['type'];
    visibilityDuration = json['visibility_duration'];
    song = json['song'];
    message = json['message'];
    title = json['title'];
    subTitle = json['sub_title'];
    natureOfPost = json['nature_of_post'];
    location = json['location'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    locationMetadata = json['location_metadata'];
    mediaAspectRatio = json['media_aspect_ratio'];
    postVia = json['post_via'];
    referenceLink = json['reference_link'];
    authorId = json['author_id'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    poll = json['poll'];
    commentsCount = json['comments_count'];
    likesCount = json['likes_count'];
    repostCount = json['repost_count'];
    viewsCount = json['views_count'];
    sharesCount = json['shares_count'];
    isReposted = json['is_reposted'];
    childrenPost = json['children_post'];
    thumbnail = json['thumbnail'];
    duration = json['duration'];
  }
  List<String>? media;
  List<String>? mediaTypes;
  String? id;
  String? type;
  int? visibilityDuration;
  dynamic song;
  String? message;
  String? title;
  String? subTitle;
  String? natureOfPost;
  String? location;
  double? latitude;
  double? longitude;
  dynamic locationMetadata;
  String? mediaAspectRatio;
  String? postVia;
  String? referenceLink;
  String? authorId;
  String? createdBy;
  String? updatedBy;
  dynamic poll;
  int? commentsCount;
  int? likesCount;
  int? repostCount;
  int? viewsCount;
  int? sharesCount;
  bool? isReposted;
  dynamic childrenPost;
  String? thumbnail;
  int? duration;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map['media'] = media;
    map['media_types'] = mediaTypes;
    map['id'] = id;
    map['type'] = type;
    map['visibility_duration'] = visibilityDuration;
    map['song'] = song;
    map['message'] = message;
    map['title'] = title;
    map['sub_title'] = subTitle;
    map['nature_of_post'] = natureOfPost;
    map['location'] = location;
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['location_metadata'] = locationMetadata;
    map['media_aspect_ratio'] = mediaAspectRatio;
    map['post_via'] = postVia;
    map['reference_link'] = referenceLink;
    map['author_id'] = authorId;
    map['created_by'] = createdBy;
    map['updated_by'] = updatedBy;
    map['poll'] = poll;
    map['comments_count'] = commentsCount;
    map['likes_count'] = likesCount;
    map['repost_count'] = repostCount;
    map['views_count'] = viewsCount;
    map['shares_count'] = sharesCount;
    map['is_reposted'] = isReposted;
    map['children_post'] = childrenPost;
    map['thumbnail'] = thumbnail;
    map['duration'] = duration;
    return map;
  }

}
