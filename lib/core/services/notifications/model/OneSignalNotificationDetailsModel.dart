/// conversation_type : "personal"
/// conversation_id : "688ccca504a57723eabf5a00"
/// sender_user : {"contact":"7798871464","name":"Amol Bro BlueCs"}
/// message_id : "6890bd915ca63550875c3620"
/// message_type : "text"
/// message : "Qrvwrvwrv"
/// operation : "sent_message"

class OneSignalNotificationDetailsModel {
  OneSignalNotificationDetailsModel({
      this.conversationType, 
      this.conversationId, 
      this.senderUser, 
      this.messageId, 
      this.messageType, 
      this.message, 
      this.operation,});

  OneSignalNotificationDetailsModel.fromJson(dynamic json) {
    conversationType = json['conversation_type'];
    conversationId = json['conversation_id'];
    senderUser = json['sender_user'] != null ? SenderUser.fromJson(json['sender_user']) : null;
    messageId = json['message_id'];
    messageType = json['message_type'];
    message = json['message'];
    operation = json['operation'];
  }
  String? conversationType;
  String? conversationId;
  SenderUser? senderUser;
  String? messageId;
  String? messageType;
  String? message;
  String? operation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['conversation_type'] = conversationType;
    map['conversation_id'] = conversationId;
    if (senderUser != null) {
      map['sender_user'] = senderUser?.toJson();
    }
    map['message_id'] = messageId;
    map['message_type'] = messageType;
    map['message'] = message;
    map['operation'] = operation;
    return map;
  }

}

/// contact : "7798871464"
/// name : "Amol Bro BlueCs"

class SenderUser {
  SenderUser({
      this.contact, 
      this.id,
      this.name,});

  SenderUser.fromJson(dynamic json) {
    contact = json['contact'];
    name = json['name'];
    id = json['id'];
  }
  String? contact;
  String? id;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['contact'] = contact;
    map['name'] = name;
    map['id'] = id;
    return map;
  }

}