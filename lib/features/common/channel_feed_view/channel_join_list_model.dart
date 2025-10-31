import 'dart:convert';
ChannelJoinListModel channelJoinListModelFromJson(String str) => ChannelJoinListModel.fromJson(json.decode(str));
String channelJoinListModelToJson(ChannelJoinListModel data) => json.encode(data.toJson());
class ChannelJoinListModel {
  ChannelJoinListModel({
      this.success, 
      this.message, 
      this.data, 
      this.count,});

  ChannelJoinListModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(UserChannelData.fromJson(v));
      });
    }
    count = json['count'];
  }
  bool? success;
  String? message;
  List<UserChannelData>? data;
  int? count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['count'] = count;
    return map;
  }

}

UserChannelData dataFromJson(String str) => UserChannelData.fromJson(json.decode(str));
String dataToJson(UserChannelData data) => json.encode(data.toJson());
class UserChannelData {
  UserChannelData({
      this.id, 
      this.accountType, 
      this.username, 
      this.profileImage, 
      this.designation, 
      this.name, 
      this.businessId, 
      this.businessName, 
      this.businessCategory,});

  UserChannelData.fromJson(dynamic json) {
    id = json['id'];
    accountType = json['account_type'];
    username = json['username'];
    profileImage = json['profile_image'];
    designation = json['designation'];
    name = json['name'];
    businessId = json['business_id'];
    businessName = json['business_name'];
    businessCategory = json['business_category'];
  }
  String? id;
  String? accountType;
  String? username;
  String? profileImage;
  dynamic designation;
  String? name;
  String? businessId;
  String? businessName;
  String? businessCategory;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['account_type'] = accountType;
    map['username'] = username;
    map['profile_image'] = profileImage;
    map['designation'] = designation;
    map['name'] = name;
    map['business_id'] = businessId;
    map['business_name'] = businessName;
    map['business_category'] = businessCategory;
    return map;
  }

}