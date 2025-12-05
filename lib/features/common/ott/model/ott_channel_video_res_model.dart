import 'dart:convert';
OttChannelVideoResModel ottChannelVideoResModelFromJson(String str) => OttChannelVideoResModel.fromJson(json.decode(str));
String ottChannelVideoResModelToJson(OttChannelVideoResModel data) => json.encode(data.toJson());
class OttChannelVideoResModel {
  OttChannelVideoResModel({
      this.creator, 
      this.videos,
      this.currentPage,});

  OttChannelVideoResModel.fromJson(dynamic json) {
    creator = json['creator'] != null ? Creator.fromJson(json['creator']) : null;
    videos = json['videos'] != null ? VideosData.fromJson(json['videos']) : null;
    currentPage = json['currentPage'];
  }
  Creator? creator;
  VideosData? videos;
  int? currentPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (creator != null) {
      map['creator'] = creator?.toJson();
    }

    if (videos != null) {
      map['videos'] = videos?.toJson();
    }
    map['currentPage'] = currentPage;
    return map;
  }

}

VideosData videosFromJson(String str) => VideosData.fromJson(json.decode(str));
String videosToJson(VideosData data) => json.encode(data.toJson());
class VideosData {
  VideosData({
      this.items, 
      this.totalItems, 
      this.totalPages,});

  VideosData.fromJson(dynamic json) {
    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items?.add(VideoItems.fromJson(v));
      });
    }
    totalItems = json['totalItems'];
    totalPages = json['totalPages'];
  }
  List<VideoItems>? items;
  int? totalItems;
  int? totalPages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (items != null) {
      map['items'] = items?.map((v) => v.toJson()).toList();
    }
    map['totalItems'] = totalItems;
    map['totalPages'] = totalPages;
    return map;
  }

}

VideoItems itemsFromJson(String str) => VideoItems.fromJson(json.decode(str));
String itemsToJson(VideoItems data) => json.encode(data.toJson());
class VideoItems {
  VideoItems({
      this.id, 
      this.userId, 
      this.channelId, 
      this.type, 
      this.status, 
      this.title, 
      this.description, 
      this.coverUrl, 
      this.videoUrl, 
      this.duration, 
      this.visibility, 
      this.tags, 
      this.isCollaboration,
      this.allowComments, 
      this.allowGifting, 
      this.isMatureContent,
      this.relatedVideoLink, 
      this.acceptBookingsOrEnquiries, 
      this.isFlagged, 
      this.stats, 
      this.createdAt,
      this.updatedAt, 
      this.v, 
      this.transcodedUrls,});

  VideoItems.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    channelId = json['channelId'];
    type = json['type'];
    status = json['status'];
    title = json['title'];
    description = json['description'];
    coverUrl = json['coverUrl'];
    videoUrl = json['videoUrl'];
    duration = json['duration'];
    visibility = json['visibility'];
    tags = json['tags'] != null ? json['tags'].cast<String>() : [];
    isCollaboration = json['isCollaboration'];
    allowComments = json['allowComments'];
    allowGifting = json['allowGifting'];
    isMatureContent = json['isMatureContent'];
    relatedVideoLink = json['relatedVideoLink'];
    acceptBookingsOrEnquiries = json['acceptBookingsOrEnquiries'];
    isFlagged = json['isFlagged'];
    stats = json['stats'] != null ? Stats.fromJson(json['stats']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    transcodedUrls = json['transcodedUrls'] != null ? TranscodedUrls.fromJson(json['transcodedUrls']) : null;
  }
  String? id;
  String? userId;
  String? channelId;
  String? type;
  String? status;
  String? title;
  String? description;
  String? coverUrl;
  String? videoUrl;
  int? duration;
  String? visibility;
  List<String>? tags;
  bool? isCollaboration;
  bool? allowComments;
  bool? allowGifting;
  bool? isMatureContent;
  String? relatedVideoLink;
  bool? acceptBookingsOrEnquiries;
  bool? isFlagged;
  Stats? stats;
  String? createdAt;
  String? updatedAt;
  int? v;
  TranscodedUrls? transcodedUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['channelId'] = channelId;
    map['type'] = type;
    map['status'] = status;
    map['title'] = title;
    map['description'] = description;
    map['coverUrl'] = coverUrl;
    map['videoUrl'] = videoUrl;
    map['duration'] = duration;
    map['visibility'] = visibility;
    map['tags'] = tags;

    map['isCollaboration'] = isCollaboration;
    map['allowComments'] = allowComments;
    map['allowGifting'] = allowGifting;

    map['isMatureContent'] = isMatureContent;
    map['relatedVideoLink'] = relatedVideoLink;
    map['acceptBookingsOrEnquiries'] = acceptBookingsOrEnquiries;
    map['isFlagged'] = isFlagged;
    if (stats != null) {
      map['stats'] = stats?.toJson();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (transcodedUrls != null) {
      map['transcodedUrls'] = transcodedUrls?.toJson();
    }
    return map;
  }

}

TranscodedUrls transcodedUrlsFromJson(String str) => TranscodedUrls.fromJson(json.decode(str));
String transcodedUrlsToJson(TranscodedUrls data) => json.encode(data.toJson());
class TranscodedUrls {
  TranscodedUrls({
      this.master, 
      this.p360,
      this.p432,
      this.p540,
      this.p720,
      this.phigh720,
      this.p1080,
      this.p1200,});

  TranscodedUrls.fromJson(dynamic json) {
    master = json['master'];
    p360 = json['360p'];
    p432 = json['432p'];
    p540 = json['540p'];
    p720 = json['720p'];
    phigh720 = json['720p-high'];
    p1080 = json['1080p'];
    p1200 = json['1200p'];
  }
  String? master;
  String? p360;
  String? p432;
  String? p540;
  String? p720;
  String? phigh720;
  String? p1080;
  String? p1200;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['master'] = master;
    map['360p'] = p360;
    map['432p'] = p432;
    map['540p'] = p540;
    map['720p'] = p720;
    map['720p-high'] = phigh720;
    map['1080p'] = p1080;
    map['1200p'] = p1200;
    return map;
  }

}

Stats statsFromJson(String str) => Stats.fromJson(json.decode(str));
String statsToJson(Stats data) => json.encode(data.toJson());
class Stats {
  Stats({
      this.views, 
      this.likes, 
      this.shares, 
      this.comments,});

  Stats.fromJson(dynamic json) {
    views = json['views'];
    likes = json['likes'];
    shares = json['shares'];
    comments = json['comments'];
  }
  int? views;
  int? likes;
  int? shares;
  int? comments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['views'] = views;
    map['likes'] = likes;
    map['shares'] = shares;
    map['comments'] = comments;
    return map;
  }

}



Creator creatorFromJson(String str) => Creator.fromJson(json.decode(str));
String creatorToJson(Creator data) => json.encode(data.toJson());
class Creator {
  Creator({
      this.id, 
      this.username, 
      this.accountType, 
      this.profileImage, 
      this.name, 
      this.designation, 
      this.isVerified, 
      this.followersCount, 
      this.natureOfBusiness, 
      this.subCategoryOfBusiness, 
      this.categoryOfBusiness,});

  Creator.fromJson(dynamic json) {
    id = json['_id'];
    username = json['username'];
    accountType = json['account_type'];
    profileImage = json['profile_image'];
    name = json['name'];
    designation = json['designation'];
    isVerified = json['isVerified'];
    followersCount = json['followersCount'];
    natureOfBusiness = json['natureOfBusiness'];
    subCategoryOfBusiness = json['subCategoryOfBusiness'];
    categoryOfBusiness = json['categoryOfBusiness'];
  }
  String? id;
  String? username;
  String? accountType;
  String? profileImage;
  String? name;
  String? designation;
  bool? isVerified;
  int? followersCount;
  dynamic natureOfBusiness;
  dynamic subCategoryOfBusiness;
  dynamic categoryOfBusiness;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['username'] = username;
    map['account_type'] = accountType;
    map['profile_image'] = profileImage;
    map['name'] = name;
    map['designation'] = designation;
    map['isVerified'] = isVerified;
    map['followersCount'] = followersCount;
    map['natureOfBusiness'] = natureOfBusiness;
    map['subCategoryOfBusiness'] = subCategoryOfBusiness;
    map['categoryOfBusiness'] = categoryOfBusiness;
    return map;
  }

}