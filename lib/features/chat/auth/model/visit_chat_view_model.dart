class NewConvoContactVisitDetails {
  bool? status;
  String? message;
  Data? data;

  NewConvoContactVisitDetails({this.status, this.message, this.data});

  NewConvoContactVisitDetails.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? otherUserId;
  String? conversationStatus;
  String? conversationId;
  bool? isConversation;
  dynamic conversation;
  Sender? sender;

  Data(
      {this.otherUserId,
        this.conversationStatus,
        this.isConversation,
        this.conversation,
        this.sender});

  Data.fromJson(Map<String, dynamic> json) {
    otherUserId = json['other_user_id'];
    conversationStatus = json['conversation_status'];
    conversationId = json['conversation_id'];
    isConversation = json['is_conversation'];
    conversation = json['conversation'];
    sender =
    json['sender'] != null ? new Sender.fromJson(json['sender']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['other_user_id'] = this.otherUserId;
    data['conversation_status'] = this.conversationStatus;
    data['is_conversation'] = this.isConversation;
    data['conversation_id'] = this.conversationId;
    data['conversation'] = this.conversation;
    if (this.sender != null) {
      data['sender'] = this.sender!.toJson();
    }
    return data;
  }
}

class Sender {
  String? id;
  String? name;
  String? contact;
  String? profileImage;
  String? businessId;

  Sender({this.id, this.name, this.contact, this.profileImage,this.businessId});

  Sender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    contact = json['contact'];
    profileImage = json['profile_image'];
    businessId = json['business_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['contact'] = this.contact;
    data['profile_image'] = this.profileImage;
    data['business_id'] = this.businessId;
    return data;
  }
}




class NewConvMessageData {
  bool? status;
  NewConvoMessage? message;
  NewConvoData? data;

  NewConvMessageData({this.status, this.message, this.data});

  NewConvMessageData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message =
    json['message'] != null ? new NewConvoMessage.fromJson(json['message']??{}) : null;
    data = json['data'] != null ? new NewConvoData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class NewConvoMessage {
  bool? isConversation;
  String? conversationId;
  NewConvoConversation? conversation;
  Sender? sender;

  NewConvoMessage(
      {this.isConversation,
        this.conversationId,
        this.conversation,
        this.sender});

  NewConvoMessage.fromJson(Map<String, dynamic> json) {
    isConversation = json['is_conversation'];
    conversationId = json['conversation_id'];
    conversation = json['conversation'] != null
        ? new NewConvoConversation.fromJson(json['conversation'])
        : null;
    sender =
    json['sender'] != null ? new Sender.fromJson(json['sender']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_conversation'] = this.isConversation;
    data['conversation_id'] = this.conversationId;
    if (this.conversation != null) {
      data['conversation'] = this.conversation!.toJson();
    }
    if (this.sender != null) {
      data['sender'] = this.sender!.toJson();
    }
    return data;
  }
}

class NewConvoConversation {
  String? sId;
  bool? isGroup;
  String? type;
  bool? blockedByAdmin;
  bool? createdByAdmin;
  bool? publicGroup;
  String? updatedAt;
  String? createdAt;
  int? iV;
  String? lastMessage;
  String? lastMessageId;
  String? lastMessageType;

  NewConvoConversation(
      {this.sId,
        this.isGroup,
        this.type,
        this.blockedByAdmin,
        this.createdByAdmin,
        this.publicGroup,
        this.updatedAt,
        this.createdAt,
        this.iV,
        this.lastMessage,
        this.lastMessageId,
        this.lastMessageType});

  NewConvoConversation.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    isGroup = json['is_group'];
    type = json['type'];
    blockedByAdmin = json['blocked_by_admin'];
    createdByAdmin = json['created_by_admin'];
    publicGroup = json['public_group'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    iV = json['__v'];
    lastMessage = json['last_message'];
    lastMessageId = json['last_message_id'];
    lastMessageType = json['last_message_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['is_group'] = this.isGroup;
    data['type'] = this.type;
    data['blocked_by_admin'] = this.blockedByAdmin;
    data['created_by_admin'] = this.createdByAdmin;
    data['public_group'] = this.publicGroup;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    data['__v'] = this.iV;
    data['last_message'] = this.lastMessage;
    data['last_message_id'] = this.lastMessageId;
    data['last_message_type'] = this.lastMessageType;
    return data;
  }
}


class NewConvoData {
  String? otherUserId;

  NewConvoData({this.otherUserId});

  NewConvoData.fromJson(Map<String, dynamic> json) {
    otherUserId = json['other_user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['other_user_id'] = this.otherUserId;
    return data;
  }
}
