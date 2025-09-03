import 'dart:convert';
FollowFollowingResModel followFollowingResModelFromJson(String str) => FollowFollowingResModel.fromJson(json.decode(str));
String followFollowingResModelToJson(FollowFollowingResModel data) => json.encode(data.toJson());
class FollowFollowingResModel {
  FollowFollowingResModel({
      this.success, 
      this.data,});

  FollowFollowingResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FollowFollowingData.fromJson(v));
      });
    }
  }
  bool? success;
  List<FollowFollowingData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

FollowFollowingData dataFromJson(String str) => FollowFollowingData.fromJson(json.decode(str));
String dataToJson(FollowFollowingData data) => json.encode(data.toJson());
class FollowFollowingData {
  FollowFollowingData({
      this.id, 
      this.follower, 
      this.followedAt,});

  FollowFollowingData.fromJson(dynamic json) {
    id = json['_id'];
    follower = json['follower'] != null ? Follower.fromJson(json['follower']) : null;
    followedAt = json['followed_at'];
  }
  String? id;
  Follower? follower;
  String? followedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (follower != null) {
      map['follower'] = follower?.toJson();
    }
    map['followed_at'] = followedAt;
    return map;
  }

}

Follower followerFromJson(String str) => Follower.fromJson(json.decode(str));
String followerToJson(Follower data) => json.encode(data.toJson());
class Follower {
  Follower({
      this.id, 
      this.name, 
      this.profileImage, 
      this.username, 
      this.accountType,});

  Follower.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    profileImage = json['profile_image'];
    username = json['username'];
    accountType = json['account_type'];
  }
  String? id;
  String? name;
  String? profileImage;
  String? username;
  String? accountType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['profile_image'] = profileImage;
    map['username'] = username;
    map['account_type'] = accountType;
    return map;
  }

}