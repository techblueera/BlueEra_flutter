import 'dart:convert';

/// Follower Res model
FollowerResModel followerResModelFromJson(String str) => FollowerResModel.fromJson(json.decode(str));
String followerResModelToJson(FollowerResModel data) => json.encode(data.toJson());
class FollowerResModel {
  FollowerResModel({
      this.success, 
      this.data,});

  FollowerResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FollowerData.fromJson(v));
      });
    }
  }
  bool? success;
  List<FollowerData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

FollowerData dataFromJson(String str) => FollowerData.fromJson(json.decode(str));
String dataToJson(FollowerData data) => json.encode(data.toJson());
class FollowerData {
  FollowerData({
      this.id, 
      this.follower, 
      this.followedAt,});

  FollowerData.fromJson(dynamic json) {
    id = json['_id'];
    follower = json['follower'] != null ? FollowingFollower.fromJson(json['follower']) : null;
    followedAt = json['followed_at'];
  }
  String? id;
  FollowingFollower? follower;
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

/// Following Res model
FollowingResModel FollowingResModelFromJson(String str) => FollowingResModel.fromJson(json.decode(str));
String FollowingResModelToJson(FollowingResModel data) => json.encode(data.toJson());
class FollowingResModel {
  FollowingResModel({
    this.success,
    this.data,});

  FollowingResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FollowingData.fromJson(v));
      });
    }
  }
  bool? success;
  List<FollowingData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

FollowingData followingDataFromJson(String str) => FollowingData.fromJson(json.decode(str));
String followingDataToJson(FollowingData data) => json.encode(data.toJson());
class FollowingData {
  FollowingData({
    this.id,
    this.following,
    this.followedAt,});

  FollowingData.fromJson(dynamic json) {
    id = json['_id'];
    following = json['following'] != null ? FollowingFollower.fromJson(json['following']) : null;
    followedAt = json['followed_at'];
  }
  String? id;
  FollowingFollower? following;
  String? followedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (following != null) {
      map['following'] = following?.toJson();
    }
    map['followed_at'] = followedAt;
    return map;
  }

}

FollowingFollower followingFollowerFromJson(String str) => FollowingFollower.fromJson(json.decode(str));
String followingFollowerToJson(FollowingFollower data) => json.encode(data.toJson());
class FollowingFollower {
  FollowingFollower({
    this.id,
    this.name,
    this.profileImage,
    this.username,
    this.accountType,});

  FollowingFollower.fromJson(dynamic json) {
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
