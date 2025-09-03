
import 'GetChatListModel.dart';
import 'messageMediaUrl.dart';

/// _id : "68877c229b1f6d346d7729ae"
/// message : "hehs"
/// message_type : "text"
/// sub_type : "message"
/// who_seen_the_message : ["68763d966cbe951b99f684da"]
/// message_read : 0
/// forward_id : null
/// reply_id : null
/// senderId : "68763d966cbe951b99f684da"
/// conversation_id : "68877a5d9b1f6d346d772843"
/// likes_count : 0
/// forwards_count : 0
/// replies_count : 0
/// updated_at : "2025-07-28T13:33:22.331Z"
/// url : []
/// created_at : "2025-07-28T13:33:22.331Z"
/// __v : 0
/// my_message : true

class ReplyParentMessage {
  ReplyParentMessage({
      this.id, 
      this.message, 
      this.messageType, 
      this.subType, 
      this.whoSeenTheMessage, 
      this.messageRead, 
      this.forwardId, 
      this.replyId, 
      this.senderId, 
      this.conversationId, 
      this.likesCount, 
      this.forwardsCount, 
      this.repliesCount, 
      this.updatedAt, 
      this.url, 
      this.createdAt, 
      this.v,
      this.sender,
      this.myMessage,});

  ReplyParentMessage.fromJson(dynamic json) {
    id = json['_id'];
    message = json['message'];
    messageType = json['message_type'];
    subType = json['sub_type'];
    whoSeenTheMessage = json['who_seen_the_message'] != null ? json['who_seen_the_message'].cast<String>() : [];
    messageRead = json['message_read'];
    forwardId = json['forward_id'];
    replyId = json['reply_id'];
    senderId = json['senderId'];
    conversationId = json['conversation_id'];
    likesCount = json['likes_count'];
    forwardsCount = json['forwards_count'];
    repliesCount = json['replies_count'];
    updatedAt = json['updated_at'];
    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;
    if (json['url'] != null) {
      url = [];
      json['url'].forEach((v) {
        url?.add(MessageMediaUrl.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    v = json['__v'];
    myMessage = json['my_message'];
  }
  String? id;
  String? message;
  String? messageType;
  String? subType;
  List<String>? whoSeenTheMessage;
  num? messageRead;
  dynamic forwardId;
  dynamic replyId;
  String? senderId;
  String? conversationId;
  num? likesCount;
  num? forwardsCount;
  num? repliesCount;
  String? updatedAt;
  List<MessageMediaUrl>? url;
  String? createdAt;
  num? v;
  Sender? sender;
  bool? myMessage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['message'] = message;
    map['message_type'] = messageType;
    map['sub_type'] = subType;
    map['who_seen_the_message'] = whoSeenTheMessage;
    map['message_read'] = messageRead;
    map['forward_id'] = forwardId;
    map['reply_id'] = replyId;
    map['senderId'] = senderId;
    map['conversation_id'] = conversationId;
    map['likes_count'] = likesCount;
    map['forwards_count'] = forwardsCount;
    map['replies_count'] = repliesCount;
    map['updated_at'] = updatedAt;
    if (url != null) {
      map['url'] = url?.map((v) => v.toJson()).toList();
    }
    if (sender != null) {
      map['sender'] = sender?.toJson();
    }
    map['created_at'] = createdAt;
    map['__v'] = v;
    map['my_message'] = myMessage;
    return map;
  }

}