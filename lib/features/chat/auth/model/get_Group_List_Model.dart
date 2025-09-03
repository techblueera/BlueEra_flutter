

class GroupChatListModel {
  final bool? success;
  final String? type;
  final List<GroupChatList>? chatList;
  final List<dynamic>? archived;

  GroupChatListModel({
    this.success,
    this.type,
    this.chatList,
    this.archived,
  });

  factory GroupChatListModel.fromJson(Map<String, dynamic> json) {
    return GroupChatListModel(
      success: json['success'] as bool?,
      type: json['type'] as String?,
      chatList: (json['chatList'] as List<dynamic>?)
          ?.map((e) => GroupChatList.fromJson(e as Map<String, dynamic>))
          .toList(),
      archived: json['archived'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'type': type,
      'chatList': chatList?.map((e) => e.toJson()).toList(),
      'archived': archived,
    };
  }
}

class GroupChatList {
  final String? conversationId;
  final String? type;
  final String? groupName;
  final String? groupProfileImage;
  final String? lastMessage;
  final String? lastMessageType;
  final String? createdAt;
  final String? updatedAt;
  final int? unreadCount;
  final bool? publicGroup;
  final dynamic sender;

  GroupChatList({
    this.conversationId,
    this.type,
    this.groupName,
    this.groupProfileImage,
    this.lastMessage,
    this.lastMessageType,
    this.createdAt,
    this.updatedAt,
    this.unreadCount,
    this.publicGroup,
    this.sender,
  });

  factory GroupChatList.fromJson(Map<String, dynamic> json) {
    return GroupChatList(
      conversationId: json['conversation_id'] as String?,
      type: json['type'] as String?,
      groupName: json['group_name'] as String?,
      groupProfileImage: json['group_profile_image'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      unreadCount: json['unread_count'] as int?,
      publicGroup: json['public_group'] as bool?,
      sender:  json['sender']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'type': type,
      'group_name': groupName,
      'group_profile_image': groupProfileImage,
      'last_message': lastMessage,
      'last_message_type': lastMessageType,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'unread_count': unreadCount,
      'public_group': publicGroup,
      'sender': sender,
    };
  }
}
