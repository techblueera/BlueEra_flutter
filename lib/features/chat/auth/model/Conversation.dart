/// _id : "68919f37aa80ff5dee8458c0"
/// is_group : false
/// type : "personal"
/// blocked_by_admin : false
/// created_by_admin : false
/// public_group : false
/// updated_at : "2025-08-05T06:13:05.724Z"
/// created_at : "2025-08-05T06:05:43.508Z"
/// __v : 0
/// last_message : "Ffff"
/// last_message_id : "6891a0f1aa80ff5dee845a41"
/// last_message_type : "text"

class Conversation {
  Conversation({
      this.id, 
      this.isGroup, 
      this.type, 
      this.blockedByAdmin, 
      this.createdByAdmin, 
      this.publicGroup, 
      this.updatedAt, 
      this.createdAt, 
      this.v, 
      this.lastMessage, 
      this.lastMessageId, 
      this.lastMessageType,});

  Conversation.fromJson(dynamic json) {
    id = json['_id'];
    isGroup = json['is_group'];
    type = json['type'];
    blockedByAdmin = json['blocked_by_admin'];
    createdByAdmin = json['created_by_admin'];
    publicGroup = json['public_group'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    v = json['__v'];
    lastMessage = json['last_message'];
    lastMessageId = json['last_message_id'];
    lastMessageType = json['last_message_type'];
  }
  String? id;
  bool? isGroup;
  String? type;
  bool? blockedByAdmin;
  bool? createdByAdmin;
  bool? publicGroup;
  String? updatedAt;
  String? createdAt;
  num? v;
  String? lastMessage;
  String? lastMessageId;
  String? lastMessageType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['is_group'] = isGroup;
    map['type'] = type;
    map['blocked_by_admin'] = blockedByAdmin;
    map['created_by_admin'] = createdByAdmin;
    map['public_group'] = publicGroup;
    map['updated_at'] = updatedAt;
    map['created_at'] = createdAt;
    map['__v'] = v;
    map['last_message'] = lastMessage;
    map['last_message_id'] = lastMessageId;
    map['last_message_type'] = lastMessageType;
    return map;
  }

}