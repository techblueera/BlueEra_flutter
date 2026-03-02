class CheckChatConversationModel {
  bool? status;
  String? message;
  CheckChatData? data;

  CheckChatConversationModel({
    this.status,
    this.message,
    this.data,
  });

  CheckChatConversationModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null
        ? CheckChatData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}
class CheckChatData {
  String? otherUserId;
  String? conversationStatus;
  String? button;
  bool? isConversation;
  String? conversationId;
  CheckChatConversation? conversation;
  CheckChatSender? sender;

  CheckChatData({
    this.otherUserId,
    this.conversationStatus,
    this.button,
    this.isConversation,
    this.conversationId,
    this.conversation,
    this.sender,
  });

  CheckChatData.fromJson(Map<String, dynamic> json) {
    otherUserId = json['other_user_id'];
    conversationStatus = json['conversation_status'];
    button = json['button'];
    isConversation = json['is_conversation'];
    conversationId = json['conversation_id'];
    conversation = json['conversation'] != null
        ? CheckChatConversation.fromJson(json['conversation'])
        : null;
    sender = json['sender'] != null
        ? CheckChatSender.fromJson(json['sender'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['other_user_id'] = otherUserId;
    data['conversation_status'] = conversationStatus;
    data['button'] = button;
    data['is_conversation'] = isConversation;
    data['conversation_id'] = conversationId;
    if (conversation != null) {
      data['conversation'] = conversation!.toJson();
    }
    if (sender != null) {
      data['sender'] = sender!.toJson();
    }
    return data;
  }
}
class CheckChatConversation {
  String? id;
  String? type;
  String? groupCoverImage;
  bool? blockedByAdmin;
  bool? createdByAdmin;
  bool? publicGroup;
  bool? ordersConversation;
  String? updatedAt;
  String? createdAt;
  int? version;
  String? lastMessage;
  String? lastMessageId;
  String? lastMessageType;

  CheckChatConversation({
    this.id,
    this.type,
    this.groupCoverImage,
    this.blockedByAdmin,
    this.createdByAdmin,
    this.publicGroup,
    this.ordersConversation,
    this.updatedAt,
    this.createdAt,
    this.version,
    this.lastMessage,
    this.lastMessageId,
    this.lastMessageType,
  });

  CheckChatConversation.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    type = json['type'];
    groupCoverImage = json['group_cover_image'];
    blockedByAdmin = json['blocked_by_admin'];
    createdByAdmin = json['created_by_admin'];
    publicGroup = json['public_group'];
    ordersConversation = json['orders_conversation'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    version = json['__v'];
    lastMessage = json['last_message'];
    lastMessageId = json['last_message_id'];
    lastMessageType = json['last_message_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = id;
    data['type'] = type;
    data['group_cover_image'] = groupCoverImage;
    data['blocked_by_admin'] = blockedByAdmin;
    data['created_by_admin'] = createdByAdmin;
    data['public_group'] = publicGroup;
    data['orders_conversation'] = ordersConversation;
    data['updated_at'] = updatedAt;
    data['created_at'] = createdAt;
    data['__v'] = version;
    data['last_message'] = lastMessage;
    data['last_message_id'] = lastMessageId;
    data['last_message_type'] = lastMessageType;
    return data;
  }
}
class CheckChatSender {
  String? id;
  String? accountType;
  String? name;
  String? contact;
  String? businessId;
  String? profileImage;
  String? email;
  String? location;

  CheckChatSender({
    this.id,
    this.accountType,
    this.name,
    this.contact,
    this.businessId,
    this.profileImage,
    this.email,
    this.location,
  });

  CheckChatSender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountType = json['account_type'];
    name = json['name'];
    contact = json['contact'];
    businessId = json['business_id'];
    profileImage = json['profile_image'];
    email = json['email'];
    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['account_type'] = accountType;
    data['name'] = name;
    data['contact'] = contact;
    data['business_id'] = businessId;
    data['profile_image'] = profileImage;
    data['email'] = email;
    data['location'] = location;
    return data;
  }
}