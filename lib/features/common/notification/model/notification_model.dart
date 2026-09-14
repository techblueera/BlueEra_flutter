import 'dart:convert';

import 'package:BlueEra/core/services/notification_tracking_service.dart';

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
  // Backend-supplied operation key (e.g. `profile_completion_reminder`,
  // `SYMBOL_VIEWED`). Drives tap redirection independent of the coarse
  // `notification_type`, so a notification without a `notification_type` can
  // still route to the right screen.
  String? originalOperation;
  // CONTACT_JOINED (contact-service): the BlueEra user id of the phonebook
  // contact who just joined, so the row can open their profile.
  String? contactUserId;
  // admin_video_promo: the promoted video. Note the casing — the stored inbox
  // row uses snake_case (`video_id`) while the FCM push uses camelCase
  // (`videoId`); they are written by different services, so accept either.
  String? videoId;
  // Snapshot of the type at compose time. Kept for the row's UI only (a short
  // gets a portrait-ish badge, a long a duration) — NEVER route off it: a
  // scheduled campaign can fire days later, so `navigateToVideoDetail` decides
  // from the live fetch instead.
  String? videoType;
  // 16:9 still. A video promo rendered as a plain text row gets ignored.
  String? videoThumbnail;
  String? videoTitle;
  // Campaign this row belongs to, for open-rate analytics.
  String? broadcastId;
  // Where the row should go when tapped.
  //
  // Casing differs BY LAYER, not by accident: the FCM push writes `deepLink`,
  // the stored inbox row writes `deep_link` — different producers. Both are
  // read, plus the pre-normalisation `link` / `url` spellings, so a row and its
  // push can never route differently.
  String? deepLink;
  // Campaign artwork. A promotion row rendered as plain text gets scrolled
  // past, so it stands in for the (absent) sender avatar on admin rows.
  String? imageUrl;

  Metadata({
    this.jobId,
    this.senderName,
    this.message,
    this.symbolId,
    this.conversationId,
    this.title,
    this.body,
    this.originalOperation,
    this.contactUserId,
    this.videoId,
    this.videoType,
    this.videoThumbnail,
    this.videoTitle,
    this.broadcastId,
    this.deepLink,
    this.imageUrl,
  });

  Metadata.fromJson(Map<String, dynamic> json) {
    jobId = json['jobId']??json['post_id'];
    senderName = json['senderName'];
    message = json['message'];
    symbolId = json['symbol_id'];
    conversationId = json['conversation_id'] ?? json['conversationId'];
    title = json['title'];
    body = json['body'];
    originalOperation = json['originalOperation'];
    contactUserId = json['contactUserId'] ?? json['contact_user_id'];
    videoId = json['video_id'] ?? json['videoId'];
    videoType = json['video_type'] ?? json['videoType'];
    videoThumbnail = json['video_thumbnail'] ?? json['videoThumbnail'];
    videoTitle = json['video_title'] ?? json['videoTitle'];
    broadcastId = json['broadcast_id'] ?? json['broadcastId'];
    // Resolved through the SHARED reader, not a local copy of the key list.
    //
    // This has to happen here, at parse time: `toJson()` only emits the fields
    // this class knows about, so a spelling the model did not recognise is
    // dropped and can never reach a reader further down. The stored row's exact
    // key is still unconfirmed (see OPEN_BACKEND_QUESTIONS.md), which is
    // precisely why the tolerant reader has to run against the RAW json.
    deepLink = NotificationTracking.deepLinkOf(json);
    imageUrl = json['image_url'] ?? json['imageUrl'];
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
    data['originalOperation'] = this.originalOperation;
    data['contactUserId'] = this.contactUserId;
    data['video_id'] = this.videoId;
    data['video_type'] = this.videoType;
    data['video_thumbnail'] = this.videoThumbnail;
    data['video_title'] = this.videoTitle;
    data['broadcast_id'] = this.broadcastId;
    data['deep_link'] = this.deepLink;
    data['image_url'] = this.imageUrl;
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