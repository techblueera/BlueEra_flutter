import 'dart:io';

import 'package:BlueEra/features/chat/auth/model/replyParantMessage.dart';

import 'Conversation.dart';
import 'messageMediaUrl.dart';

/// messages : [{"url":[],"_id":0,"message":"2025-07-25T09:14:19.107Z","message_type":"date","who_seen_the_message":[],"message_read":0,"video_time":"","audio_time":"","latitude":"","longitude":"","shared_contact_name":"","shared_contact_profile_image":"","shared_contact_number":"","forward_id":null,"reply_id":0,"status_id":0,"created_at":"","updated_at":"","senderId":0,"conversation_id":0,"delete_for_me":"","delete_from_everyone":false,"is_save_message":false,"my_message":false,"sender":{"profile_image":"","_id":0,"username":"","name":"","last_name":"","contact_no":""}},{"_id":"68834aebd37dcddbbe519b8d","message":"","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:14:19.107Z","__v":0,"message_id":"68834aebd37dcddbbe519b8d","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68834bc0d37dcddbbe519ba0","message":"hiiii","message_type":"text","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:17:52.251Z","__v":0,"message_id":"68834bc0d37dcddbbe519ba0","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"6883500be2c0ad7335a44caa","message":"usksjsn","message_type":"text","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:36:11.130Z","__v":0,"message_id":"6883500be2c0ad7335a44caa","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"6883501be2c0ad7335a44cc9","message":"","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:36:27.380Z","__v":0,"message_id":"6883501be2c0ad7335a44cc9","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"6883506ae2c0ad7335a44d00","message":"","message_type":"audio","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"url":[{"url":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/68834aebd37dcddbbe519b87/audios/1753436266448_countdown-from-10-190389.mp3","type":"audio","name":"countdown-from-10-190389.mp3","size":1493786,"mimetype":"audio/mpeg","_id":"6883506ae2c0ad7335a44d01"}],"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","created_at":"2025-07-25T09:37:46.636Z","__v":0,"message_id":"6883506ae2c0ad7335a44d00","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"688350e2e2c0ad7335a44d20","message_type":"contact","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"shared_contact_name":"~😎bhavesh Bro Bluecs","shared_contact_number":"+918980697555","forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:39:46.551Z","__v":0,"message_id":"688350e2e2c0ad7335a44d20","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68835107e2c0ad7335a44d3c","message":"","message_type":"video","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:40:23.951Z","__v":0,"message_id":"68835107e2c0ad7335a44d3c","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"688351b8e2c0ad7335a44d88","message":"2/206 \n2/206, Salem, 636012","message_type":"location","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"latitude":"11.753994700000002","longitude":"78.13363799999999","forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:43:20.589Z","__v":0,"message_id":"688351b8e2c0ad7335a44d88","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"688351dae2c0ad7335a44d91","message":"","message_type":"document","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T09:43:54.833Z","__v":0,"message_id":"688351dae2c0ad7335a44d91","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"6883593fe2c0ad7335a44e09","message":"","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T10:15:27.028Z","__v":0,"message_id":"6883593fe2c0ad7335a44e09","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68835a3aa6df53c877f4d709","message":"","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T10:19:38.184Z","__v":0,"message_id":"68835a3aa6df53c877f4d709","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68835a99a6df53c877f4d710","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T10:21:13.291Z","__v":0,"message_id":"68835a99a6df53c877f4d710","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68835af6a6df53c877f4d717","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","url":[],"created_at":"2025-07-25T10:22:46.740Z","__v":0,"message_id":"68835af6a6df53c877f4d717","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68835baba6df53c877f4d71e","message_type":"image","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"url":[{"url":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/68834aebd37dcddbbe519b87/images/1753439147695_Screenshot_20250725_141401.jpg","type":"image","name":"Screenshot_20250725_141401.jpg","size":1057257,"mimetype":"image/jpeg","_id":"68835baba6df53c877f4d71f"}],"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","created_at":"2025-07-25T10:25:47.857Z","__v":0,"message_id":"68835baba6df53c877f4d71e","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"68835c3ca6df53c877f4d728","message":"","message_type":"document","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"url":[{"url":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/68834aebd37dcddbbe519b87/documents/1753439292329_ChoiceOrder_471434 (2) praveen kumar final.pdf","type":"document","name":"ChoiceOrder_471434 (2) praveen kumar final.pdf","size":97764,"mimetype":"application/pdf","_id":"68835c3ca6df53c877f4d729"}],"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"68834aebd37dcddbbe519b87","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-25T10:28:39.611Z","created_at":"2025-07-25T10:28:12.393Z","__v":0,"message_id":"68835c3ca6df53c877f4d728","is_save_message":false,"my_message":true,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}}]
/// totalPages : 1
/// currentPage : 1

class GetListOfMessageData {
  GetListOfMessageData({
      this.messages, 
      this.totalPages, 
      this.currentPage,});

  GetListOfMessageData.fromJson(dynamic json) {
    if (json['messages'] != null) {
      messages = [];
      json['messages'].forEach((v) {
        messages?.add(Messages.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    currentPage = json['currentPage'];
  }
  List<Messages>? messages;
  num? totalPages;
  num? currentPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (messages != null) {
      map['messages'] = messages?.map((v) => v.toJson()).toList();
    }
    map['totalPages'] = totalPages;
    map['currentPage'] = currentPage;
    return map;
  }

}

/// url : []
/// _id : 0
/// message : "2025-07-25T09:14:19.107Z"
/// message_type : "date"
/// who_seen_the_message : []
/// message_read : 0
/// video_time : ""
/// audio_time : ""
/// latitude : ""
/// longitude : ""
/// shared_contact_name : ""
/// shared_contact_profile_image : ""
/// shared_contact_number : ""
/// forward_id : null
/// reply_id : 0
/// status_id : 0
/// created_at : ""
/// updated_at : ""
/// senderId : 0
/// conversation_id : 0
/// delete_for_me : ""
/// delete_from_everyone : false
/// is_save_message : false
/// my_message : false
/// sender : {"profile_image":"","_id":0,"username":"","name":"","last_name":"","contact_no":""}

class Messages {
  Messages({
      this.url, 
      this.id, 
      this.message, 
      this.status,
      this.messageType,
      this.whoSeenTheMessage, 
      this.messageRead, 
      this.videoTime, 
      this.audioTime, 
      this.sendStatus,
      this.sendPendingMsgParams,
      this.latitude,
      this.longitude, 
      this.sharedContactName, 
      this.sharedContactProfileImage, 
      this.sharedContactNumber, 
      this.forwardId, 
      this.userId,
      this.replyId,
      this.statusId, 
      this.createdAt, 
      this.updatedAt, 
      this.senderId, 
      this.docFileName,
      this.conversationId,
      this.pendingFilePaths,
      this.deleteForMe,
      this.deleteFromEveryone, 
      this.isSaveMessage, 
      this.myMessage, 
      this.sendLoadingFile,
      this.sender,});

  Messages.fromJson(dynamic json) {
    if (json['url'] != null) {
      url = [];
      json['url'].forEach((v) {
        url?.add(MessageMediaUrl.fromJson(v));
      });
    }
    id = json['_id'].toString();
    message = json['message'];
    status = json['status'];
    messageType = json['message_type'];
    subType = json['sub_type'];
    if (json['who_seen_the_message'] != null) {
      whoSeenTheMessage = [];
      json['who_seen_the_message'].forEach((v) {
        whoSeenTheMessage?.add(v);
      });
    }
    messageRead = json['message_read'];
    videoTime = json['video_time'];
    audioTime = json['audio_time'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    sharedContactName = json['shared_contact_name'];
    sharedContactProfileImage = json['shared_contact_profile_image'];
    sharedContactNumber = json['shared_contact_number'];
    forwardId = json['forward_id'];
    replyId = json['reply_id'].toString();
    statusId = json['status_id'].toString();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    docFileName = json['docFileName'];
    senderId = json['senderId'].toString();
    conversationId = json['conversation_id'].toString();
    deleteForMe = json['delete_for_me'];
    sendStatus = json['sendStatus'];
    sendPendingMsgParams = json['sendPendingMsgParams'];
    deleteFromEveryone = json['delete_from_everyone'];
    isSaveMessage = json['is_save_message'];
    myMessage = json['my_message'];
    userId = json['userId'];
    pendingFilePaths = json['pendingFilePaths'];
    likes_count = json['likes_count'].toString();
    forwards_count = json['forwards_count'].toString();
    replies_count = json['replies_count'].toString();
    is_liked = json['is_liked'];
    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;
    if (json['sendLoadingFile'] != null) {
      sendLoadingFile = [];
      json['sendLoadingFile'].forEach((v) {
        sendLoadingFile?.add(v);
      });
    }
    replyParentMessage = json['parentMessage'] != null
        ? new ReplyParentMessage.fromJson(json['parentMessage'])
        : null;
    conversation = json['conversation'] != null
        ? new Conversation.fromJson(json['conversation'])
        : null;
  }
  List<MessageMediaUrl>? url;
  String? id;
  String? message;
  String? status;
  String? messageType;
  String? subType;
  List<dynamic>? whoSeenTheMessage;
  int? messageRead;
  String? videoTime;
  List<dynamic>? pendingFilePaths;
  String? audioTime;
  String? sendStatus;
  Map<String,dynamic>? sendPendingMsgParams;
  String? latitude;
  String? longitude;
  String? sharedContactName;
  String? sharedContactProfileImage;
  String? sharedContactNumber;
  dynamic forwardId;
  String? replyId;
  String? statusId;
  String? docFileName;
  String? userId;
  String? createdAt;
  String? updatedAt;

  String? senderId;
  String? conversationId;
  String? deleteForMe;
  bool? deleteFromEveryone;
  bool? isSaveMessage;
  bool? myMessage;
  Sender? sender;
  List<File>? sendLoadingFile;
  ReplyParentMessage? replyParentMessage;
  Conversation? conversation;
  String? likes_count;
  String? forwards_count;
  String? replies_count;
  bool? is_liked;
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (url != null) {
      map['url'] = url?.map((v) => v.toJson()).toList();
    }
    map['_id'] = id;
    map['message'] = message;
    map['status'] = status;
    map['message_type'] = messageType;
    map['sub_type'] = subType;
    if (whoSeenTheMessage != null) {
      map['who_seen_the_message'] = whoSeenTheMessage?.map((v) => v).toList();
    }
    map['message_read'] = messageRead;
    map['video_time'] = videoTime;
    map['audio_time'] = audioTime;
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['shared_contact_name'] = sharedContactName;
    map['shared_contact_profile_image'] = sharedContactProfileImage;
    map['shared_contact_number'] = sharedContactNumber;
    map['forward_id'] = forwardId;
    map['reply_id'] = replyId;
    map['sendStatus'] = sendStatus;
    map['sendPendingMsgParams'] = sendPendingMsgParams;
    map['status_id'] = statusId;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['userId'] = userId;
    map['docFileName'] = docFileName;
    map['senderId'] = senderId;
    map['pendingFilePaths'] = pendingFilePaths;
    map['conversation_id'] = conversationId;
    map['delete_for_me'] = deleteForMe;
    map['delete_from_everyone'] = deleteFromEveryone;
    map['is_save_message'] = isSaveMessage;
    map['my_message'] = myMessage;
    map['likes_count'] = likes_count;
    map['forwards_count'] = forwards_count;
    map['replies_count'] = replies_count;
    map['is_liked'] = is_liked;
    map['parentMessage'] = replyParentMessage;
    map['conversation'] = conversation;
    if (sendLoadingFile != null) {
      map['sendLoadingFile'] = sendLoadingFile?.map((v) => v).toList();
    }
    if (sender != null) {
      map['sender'] = sender?.toJson();
    }
    return map;
  }

}

/// profile_image : ""
/// _id : 0
/// username : ""
/// name : ""
/// last_name : ""
/// contact_no : ""

class Sender {
  Sender({
      this.profileImage, 
      this.id, 
      this.username, 
      this.name, 
      this.lastName, 
      this.contactNo,});

  Sender.fromJson(dynamic json) {
    profileImage = json['profile_image'];
    id = json['_id'].toString();
    username = json['username'];
    name = json['name'];
    lastName = json['last_name'];
    contactNo = json['contact_no'];
  }
  String? profileImage;
  String? id;
  String? username;
  String? name;
  String? lastName;
  String? contactNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['profile_image'] = profileImage;
    map['_id'] = id;
    map['username'] = username;
    map['name'] = name;
    map['last_name'] = lastName;
    map['contact_no'] = contactNo;
    return map;
  }

}