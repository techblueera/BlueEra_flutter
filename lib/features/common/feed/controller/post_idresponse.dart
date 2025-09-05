// To parse this JSON data, do
//
//     final postByIdResponseModalClass = postByIdResponseModalClassFromJson(jsonString);

import 'dart:convert';

import 'package:BlueEra/features/common/feed/models/posts_response.dart';

PostByIdResponseModalClass postByIdResponseModalClassFromJson(String str) =>
    PostByIdResponseModalClass.fromJson(json.decode(str));

String postByIdResponseModalClassToJson(PostByIdResponseModalClass data) =>
    json.encode(data.toJson());

class PostByIdResponseModalClass {
  bool? success;
  String? message;
  Post? data;

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
            : Post.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

