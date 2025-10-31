// import 'dart:convert';
// ChannelFeedModelNew channelFeedModelNewFromJson(String str) => ChannelFeedModelNew.fromJson(json.decode(str));
// String channelFeedModelNewToJson(ChannelFeedModelNew data) => json.encode(data.toJson());
// class ChannelFeedModelNew {
//   ChannelFeedModelNew({
//       this.success,
//       this.message,
//       this.data,
//       this.pagination,});
//
//   ChannelFeedModelNew.fromJson(dynamic json) {
//     success = json['success'];
//     message = json['message'];
//     if (json['data'] != null) {
//       data = [];
//       json['data'].forEach((v) {
//         data?.add(Data.fromJson(v));
//       });
//     }
//     pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
//   }
//   bool? success;
//   String? message;
//   List<Data>? data;
//   Pagination? pagination;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['success'] = success;
//     map['message'] = message;
//     if (data != null) {
//       map['data'] = data?.map((v) => v.toJson()).toList();
//     }
//     if (pagination != null) {
//       map['pagination'] = pagination?.toJson();
//     }
//     return map;
//   }
//
// }
//
// Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
// String paginationToJson(Pagination data) => json.encode(data.toJson());
// class Pagination {
//   Pagination({
//       this.page,
//       this.limit,
//       this.total,
//       this.totalPages,});
//
//   Pagination.fromJson(dynamic json) {
//     page = json['page'];
//     limit = json['limit'];
//     total = json['total'];
//     totalPages = json['totalPages'];
//   }
//   int? page;
//   int? limit;
//   int? total;
//   int? totalPages;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['page'] = page;
//     map['limit'] = limit;
//     map['total'] = total;
//     map['totalPages'] = totalPages;
//     return map;
//   }
//
// }
//
// Data dataFromJson(String str) => Data.fromJson(json.decode(str));
// String dataToJson(Data data) => json.encode(data.toJson());
// class Data {
//   Data({
//       this.verification,
//       this.ownership,
//       this.id,
//       this.name,
//       this.username,
//       this.bio,
//       this.logoUrl,
//       this.socialLinks,
//       this.websites,
//       this.blockedUsers,
//       this.mutedUsers,
//       this.reports,
//       this.followers,
//       this.createdAt,
//       this.updatedAt,
//       this.v,
//       this.latestPost,});
//
//   Data.fromJson(dynamic json) {
//     verification = json['verification'] != null ? Verification.fromJson(json['verification']) : null;
//     ownership = json['ownership'] != null ? Ownership.fromJson(json['ownership']) : null;
//     id = json['_id'];
//     name = json['name'];
//     username = json['username'];
//     bio = json['bio'];
//     logoUrl = json['logoUrl'];
//     if (json['socialLinks'] != null) {
//       socialLinks = [];
//       json['socialLinks'].forEach((v) {
//         socialLinks?.add(SocialLinks.fromJson(v));
//       });
//     }
//     websites = json['websites'] != null ? json['websites'].cast<String>() : [];
//     if (json['blockedUsers'] != null) {
//       blockedUsers = [];
//       json['blockedUsers'].forEach((v) {
//         blockedUsers?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['mutedUsers'] != null) {
//       mutedUsers = [];
//       json['mutedUsers'].forEach((v) {
//         mutedUsers?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['reports'] != null) {
//       reports = [];
//       json['reports'].forEach((v) {
//         reports?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['followers'] != null) {
//       followers = [];
//       json['followers'].forEach((v) {
//         followers?.add(Dynamic.fromJson(v));
//       });
//     }
//     createdAt = json['createdAt'];
//     updatedAt = json['updatedAt'];
//     v = json['__v'];
//     latestPost = json['latestPost'] != null ? LatestPost.fromJson(json['latestPost']) : null;
//   }
//   Verification? verification;
//   Ownership? ownership;
//   String? id;
//   String? name;
//   String? username;
//   String? bio;
//   String? logoUrl;
//   List<SocialLinks>? socialLinks;
//   List<String>? websites;
//   List<dynamic>? blockedUsers;
//   List<dynamic>? mutedUsers;
//   List<dynamic>? reports;
//   List<dynamic>? followers;
//   String? createdAt;
//   String? updatedAt;
//   int? v;
//   LatestPost? latestPost;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     if (verification != null) {
//       map['verification'] = verification?.toJson();
//     }
//     if (ownership != null) {
//       map['ownership'] = ownership?.toJson();
//     }
//     map['_id'] = id;
//     map['name'] = name;
//     map['username'] = username;
//     map['bio'] = bio;
//     map['logoUrl'] = logoUrl;
//     if (socialLinks != null) {
//       map['socialLinks'] = socialLinks?.map((v) => v.toJson()).toList();
//     }
//     map['websites'] = websites;
//     if (blockedUsers != null) {
//       map['blockedUsers'] = blockedUsers?.map((v) => v.toJson()).toList();
//     }
//     if (mutedUsers != null) {
//       map['mutedUsers'] = mutedUsers?.map((v) => v.toJson()).toList();
//     }
//     if (reports != null) {
//       map['reports'] = reports?.map((v) => v.toJson()).toList();
//     }
//     if (followers != null) {
//       map['followers'] = followers?.map((v) => v.toJson()).toList();
//     }
//     map['createdAt'] = createdAt;
//     map['updatedAt'] = updatedAt;
//     map['__v'] = v;
//     if (latestPost != null) {
//       map['latestPost'] = latestPost?.toJson();
//     }
//     return map;
//   }
//
// }
//
// LatestPost latestPostFromJson(String str) => LatestPost.fromJson(json.decode(str));
// String latestPostToJson(LatestPost data) => json.encode(data.toJson());
// class LatestPost {
//   LatestPost({
//       this.taggedUsers,
//       this.media,
//       this.mediaTypes,
//       this.id,
//       this.type,
//       this.visibilityDuration,
//       this.song,
//       this.message,
//       this.title,
//       this.subTitle,
//       this.natureOfPost,
//       this.location,
//       this.latitude,
//       this.longitude,
//       this.locationMetadata,
//       this.mediaAspectRatio,
//       this.postVia,
//       this.referenceLink,
//       this.authorId,
//       this.createdBy,
//       this.updatedBy,
//       this.poll,
//       this.commentsCount,
//       this.likesCount,
//       this.repostCount,
//       this.viewsCount,
//       this.sharesCount,
//       this.createdAt,
//       this.updatedAt,
//       this.isReposted,
//       this.childrenPost,
//       this.thumbnail,
//       this.duration,});
//
//   LatestPost.fromJson(dynamic json) {
//     if (json['tagged_users'] != null) {
//       taggedUsers = [];
//       json['tagged_users'].forEach((v) {
//         taggedUsers?.add(Dynamic.fromJson(v));
//       });
//     }
//     media = json['media'] != null ? json['media'].cast<String>() : [];
//     mediaTypes = json['media_types'] != null ? json['media_types'].cast<String>() : [];
//     id = json['id'];
//     type = json['type'];
//     visibilityDuration = json['visibility_duration'];
//     song = json['song'];
//     message = json['message'];
//     title = json['title'];
//     subTitle = json['sub_title'];
//     natureOfPost = json['nature_of_post'];
//     location = json['location'];
//     latitude = json['latitude'];
//     longitude = json['longitude'];
//     locationMetadata = json['location_metadata'];
//     mediaAspectRatio = json['media_aspect_ratio'];
//     postVia = json['post_via'];
//     referenceLink = json['reference_link'];
//     authorId = json['author_id'];
//     createdBy = json['created_by'];
//     updatedBy = json['updated_by'];
//     poll = json['poll'];
//     commentsCount = json['comments_count'];
//     likesCount = json['likes_count'];
//     repostCount = json['repost_count'];
//     viewsCount = json['views_count'];
//     sharesCount = json['shares_count'];
//     createdAt = json['created_at'] != null ? CreatedAt.fromJson(json['created_at']) : null;
//     updatedAt = json['updated_at'] != null ? UpdatedAt.fromJson(json['updated_at']) : null;
//     isReposted = json['is_reposted'];
//     childrenPost = json['children_post'];
//     thumbnail = json['thumbnail'];
//     duration = json['duration'];
//   }
//   List<dynamic>? taggedUsers;
//   List<String>? media;
//   List<String>? mediaTypes;
//   String? id;
//   String? type;
//   int? visibilityDuration;
//   dynamic song;
//   String? message;
//   String? title;
//   String? subTitle;
//   String? natureOfPost;
//   String? location;
//   double? latitude;
//   double? longitude;
//   dynamic locationMetadata;
//   String? mediaAspectRatio;
//   String? postVia;
//   String? referenceLink;
//   String? authorId;
//   String? createdBy;
//   String? updatedBy;
//   dynamic poll;
//   int? commentsCount;
//   int? likesCount;
//   int? repostCount;
//   int? viewsCount;
//   int? sharesCount;
//   CreatedAt? createdAt;
//   UpdatedAt? updatedAt;
//   bool? isReposted;
//   dynamic childrenPost;
//   String? thumbnail;
//   int? duration;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     if (taggedUsers != null) {
//       map['tagged_users'] = taggedUsers?.map((v) => v.toJson()).toList();
//     }
//     map['media'] = media;
//     map['media_types'] = mediaTypes;
//     map['id'] = id;
//     map['type'] = type;
//     map['visibility_duration'] = visibilityDuration;
//     map['song'] = song;
//     map['message'] = message;
//     map['title'] = title;
//     map['sub_title'] = subTitle;
//     map['nature_of_post'] = natureOfPost;
//     map['location'] = location;
//     map['latitude'] = latitude;
//     map['longitude'] = longitude;
//     map['location_metadata'] = locationMetadata;
//     map['media_aspect_ratio'] = mediaAspectRatio;
//     map['post_via'] = postVia;
//     map['reference_link'] = referenceLink;
//     map['author_id'] = authorId;
//     map['created_by'] = createdBy;
//     map['updated_by'] = updatedBy;
//     map['poll'] = poll;
//     map['comments_count'] = commentsCount;
//     map['likes_count'] = likesCount;
//     map['repost_count'] = repostCount;
//     map['views_count'] = viewsCount;
//     map['shares_count'] = sharesCount;
//     if (createdAt != null) {
//       map['created_at'] = createdAt?.toJson();
//     }
//     if (updatedAt != null) {
//       map['updated_at'] = updatedAt?.toJson();
//     }
//     map['is_reposted'] = isReposted;
//     map['children_post'] = childrenPost;
//     map['thumbnail'] = thumbnail;
//     map['duration'] = duration;
//     return map;
//   }
//
// }
//
// UpdatedAt updatedAtFromJson(String str) => UpdatedAt.fromJson(json.decode(str));
// String updatedAtToJson(UpdatedAt data) => json.encode(data.toJson());
// class UpdatedAt {
//   UpdatedAt({
//       this.seconds,
//       this.nanos,});
//
//   UpdatedAt.fromJson(dynamic json) {
//     seconds = json['seconds'];
//     nanos = json['nanos'];
//   }
//   String? seconds;
//   int? nanos;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['seconds'] = seconds;
//     map['nanos'] = nanos;
//     return map;
//   }
//
// }
//
// CreatedAt createdAtFromJson(String str) => CreatedAt.fromJson(json.decode(str));
// String createdAtToJson(CreatedAt data) => json.encode(data.toJson());
// class CreatedAt {
//   CreatedAt({
//       this.seconds,
//       this.nanos,});
//
//   CreatedAt.fromJson(dynamic json) {
//     seconds = json['seconds'];
//     nanos = json['nanos'];
//   }
//   String? seconds;
//   int? nanos;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['seconds'] = seconds;
//     map['nanos'] = nanos;
//     return map;
//   }
//
// }
//
// SocialLinks socialLinksFromJson(String str) => SocialLinks.fromJson(json.decode(str));
// String socialLinksToJson(SocialLinks data) => json.encode(data.toJson());
// class SocialLinks {
//   SocialLinks({
//       this.id,
//       this.channel,
//       this.platform,
//       this.url,
//       this.v,});
//
//   SocialLinks.fromJson(dynamic json) {
//     id = json['_id'];
//     channel = json['channel'];
//     platform = json['platform'];
//     url = json['url'];
//     v = json['__v'];
//   }
//   String? id;
//   String? channel;
//   String? platform;
//   String? url;
//   int? v;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['channel'] = channel;
//     map['platform'] = platform;
//     map['url'] = url;
//     map['__v'] = v;
//     return map;
//   }
//
// }
//
// Ownership ownershipFromJson(String str) => Ownership.fromJson(json.decode(str));
// String ownershipToJson(Ownership data) => json.encode(data.toJson());
// class Ownership {
//   Ownership({
//       this.claimedBy,
//       this.claimedAt,});
//
//   Ownership.fromJson(dynamic json) {
//     claimedBy = json['claimedBy'];
//     claimedAt = json['claimedAt'];
//   }
//   String? claimedBy;
//   String? claimedAt;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['claimedBy'] = claimedBy;
//     map['claimedAt'] = claimedAt;
//     return map;
//   }
//
// }
//
// Verification verificationFromJson(String str) => Verification.fromJson(json.decode(str));
// String verificationToJson(Verification data) => json.encode(data.toJson());
// class Verification {
//   Verification({
//       this.isVerified,});
//
//   Verification.fromJson(dynamic json) {
//     isVerified = json['isVerified'];
//   }
//   bool? isVerified;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['isVerified'] = isVerified;
//     return map;
//   }
//
// }