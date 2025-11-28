import 'dart:convert';

import 'package:BlueEra/features/common/feed/models/posts_response.dart';

AllMessagePostResModel allMessagePostResModelFromJson(String str) =>
    AllMessagePostResModel.fromJson(json.decode(str));

String allMessagePostResModelToJson(AllMessagePostResModel data) =>
    json.encode(data.toJson());

class AllMessagePostResModel {
  AllMessagePostResModel({
    this.success,
    this.data,
    this.meta,
  });

  AllMessagePostResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Post.fromJson(v));
      });
    }
    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  bool? success;
  List<Post>? data;
  Meta? meta;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (meta != null) {
      map['meta'] = meta?.toJson();
    }
    return map;
  }
}

Meta metaFromJson(String str) => Meta.fromJson(json.decode(str));

String metaToJson(Meta data) => json.encode(data.toJson());

class Meta {
  Meta({
    this.nextCursor,
  });

  Meta.fromJson(dynamic json) {
    nextCursor = json['next_cursor'];
  }

  String? nextCursor;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['next_cursor'] = nextCursor;
    return map;
  }
}
