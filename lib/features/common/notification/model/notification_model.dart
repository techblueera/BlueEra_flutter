import 'dart:convert';

class NotificationDataModel {
  bool? success;
  List<NotificationDataList>? data;
  String? message;

  NotificationDataModel({this.success, this.data, this.message});

  NotificationDataModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <NotificationDataList>[];
      json['data'].forEach((v) {
        data!.add(new NotificationDataList.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class NotificationDataList {
  String? sId;
  String? type;
  String? status;
  String? sentBy;
  String? sentTo;
  Metadata? metadata;
  int? iV;
  String? createdAt;
  String? updatedAt;
  String? message;
  String? notification_type;
  User? user;
  SenderProfile? senderProfile;


  NotificationDataList(
      {this.sId,
        this.type,
        this.status,
        this.sentBy,
        this.sentTo,
        this.metadata,
        this.iV,
        this.createdAt,
        this.updatedAt,
        this.message,
        this.senderProfile,
        this.notification_type,
        this.user});

  NotificationDataList.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    type = json['type'];
    status = json['status'];
    sentBy = json['sentBy'];
    sentTo = json['sentTo'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    iV = json['__v'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    message = json['message'];
    notification_type = json['notification_type'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    senderProfile = json['sender_profile'] != null ? SenderProfile.fromJson(json['sender_profile']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['type'] = this.type;
    data['status'] = this.status;
    data['sentBy'] = this.sentBy;
    data['sentTo'] = this.sentTo;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['__v'] = this.iV;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['message'] = this.message;
    data['notification_type'] = this.notification_type;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (senderProfile != null) {
      data['sender_profile'] = senderProfile?.toJson();
    }
    return data;
  }
}

class Metadata {
  String? jobId;
  String? senderName;
  String? message;
  String? symbolId;
  // Chat/call notifications carry the conversation to open. Call ops use the
  // snake_case `conversation_id`; AI-greeting chat ops use camelCase
  // `conversationId` — accept either.
  String? conversationId;
  // Some notifications (AI greetings, ride status updates, profile reminders,
  // etc.) carry their display text in metadata.title / metadata.body and leave
  // the top-level `message` empty — parse them so those rows aren't blank.
  String? title;
  String? body;

  Metadata({
    this.jobId,
    this.senderName,
    this.message,
    this.symbolId,
    this.conversationId,
    this.title,
    this.body,
  });

  Metadata.fromJson(Map<String, dynamic> json) {
    jobId = json['jobId']??json['post_id'];
    senderName = json['senderName'];
    message = json['message'];
    symbolId = json['symbol_id'];
    conversationId = json['conversation_id'] ?? json['conversationId'];
    title = json['title'];
    body = json['body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['jobId'] = this.jobId;
    data['senderName'] = this.senderName;
    data['message'] = this.message;
    data['symbol_id'] = this.symbolId;
    data['conversation_id'] = this.conversationId;
    data['title'] = this.title;
    data['body'] = this.body;
    return data;
  }
}

class User {
  String? id;
  String? name;
  String? profileImage;

  User({this.id, this.name, this.profileImage});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile_image'] = this.profileImage;
    return data;
  }
}



SenderProfile senderProfileFromJson(String str) => SenderProfile.fromJson(json.decode(str));
String senderProfileToJson(SenderProfile data) => json.encode(data.toJson());
class SenderProfile {
  SenderProfile({
    this.id,
    this.name,
    this.profileImage,
    this.username,
    this.account_type,
    this.email,});

  SenderProfile.fromJson(dynamic json) {
    id = json['id'] ?? json['_id'];
    name = json['name'];
    profileImage = json['profile_image'];
    username = json['username'];
    email = json['email'];
    account_type = json['account_type'];
  }
  String? id;
  String? name;
  String? profileImage;
  String? username;
  String? email;
  String? account_type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_image'] = profileImage;
    map['username'] = username;
    map['email'] = email;
    map['account_type'] = account_type;
    return map;
  }

}