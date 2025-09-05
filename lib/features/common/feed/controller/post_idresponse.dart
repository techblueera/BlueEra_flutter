// To parse this JSON data, do
//
//     final postByIdResponseModalClass = postByIdResponseModalClassFromJson(jsonString);

import 'dart:convert';

import '../../../../core/api/model/personal_profile_details_model.dart';

PostByIdResponseModalClass postByIdResponseModalClassFromJson(String str) =>
    PostByIdResponseModalClass.fromJson(json.decode(str));

String postByIdResponseModalClassToJson(PostByIdResponseModalClass data) =>
    json.encode(data.toJson());

class PostByIdResponseModalClass {
  bool? success;
  String? message;
  PostByIdResponseModalClassData? data;

  PostByIdResponseModalClass({
    this.success,
    this.message,
    this.data,
  });

  factory PostByIdResponseModalClass.fromJson(Map<String, dynamic> json) =>
      PostByIdResponseModalClass(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : PostByIdResponseModalClassData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class PostByIdResponseModalClassData {
  String? id;
  String? type;
  dynamic message;
  dynamic title;
  dynamic subTitle;
  dynamic natureOfPost;
  dynamic location;
  double? latitude;
  double? longitude;
  List<dynamic>? taggedUsers;
  List<String>? media;
  dynamic mediaAspectRatio;
  String? postVia;
  dynamic referenceLink;
  String? authorId;
  String? createdBy;
  String? updatedBy;
  dynamic poll;
  int? commentsCount;
  int? likesCount;
  int? repostCount;
  int? viewsCount;
  int? sharesCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;
  bool? isLiked;
   User? user;

  PostByIdResponseModalClassData({
    this.id,
    this.type,
    this.message,
    this.title,
    this.subTitle,
    this.natureOfPost,
    this.location,
    this.latitude,
    this.longitude,
    this.taggedUsers,
    this.media,
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
    this.createdAt,
    this.updatedAt,
    this.v,
    this.isLiked,
    this.user,

  });

  factory PostByIdResponseModalClassData.fromJson(Map<String, dynamic> json) =>
      PostByIdResponseModalClassData(
        id: json["_id"],
        type: json["type"],
        message: json["message"],
        title: json["title"],
        subTitle: json["sub_title"],
        natureOfPost: json["nature_of_post"],
        location: json["location"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        taggedUsers: json["tagged_users"] == null
            ? []
            : List<dynamic>.from(json["tagged_users"]!.map((x) => x)),
        media: json["media"] == null
            ? []
            : List<String>.from(json["media"]!.map((x) => x)),
        mediaAspectRatio: json["media_aspect_ratio"],
        postVia: json["post_via"],
        referenceLink: json["reference_link"],
        authorId: json["authorId"],
        createdBy: json["created_by"],
        updatedBy: json["updated_by"],
        poll: json["poll"],
        commentsCount: json["comments_count"],
        likesCount: json["likes_count"],
        repostCount: json["repost_count"],
        viewsCount: json["views_count"],
        sharesCount: json["shares_count"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
        isLiked: json["isLiked"],
        user: json['user'] != null ? User.fromJson(json['user']) : null,

      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "type": type,
        "message": message,
        "title": title,
        "sub_title": subTitle,
        "nature_of_post": natureOfPost,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "tagged_users": taggedUsers == null
            ? []
            : List<dynamic>.from(taggedUsers!.map((x) => x)),
        "media": media == null ? [] : List<dynamic>.from(media!.map((x) => x)),
        "media_aspect_ratio": mediaAspectRatio,
        "post_via": postVia,
        "reference_link": referenceLink,
        "authorId": authorId,
        "created_by": createdBy,
        "updated_by": updatedBy,
        "poll": poll,
        "comments_count": commentsCount,
        "likes_count": likesCount,
        "repost_count": repostCount,
        "views_count": viewsCount,
        "shares_count": sharesCount,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
        "isLiked": isLiked,
    'user': user?.toJson(),

  };
}
