import 'messageMediaUrl.dart';

class GroupDetailsModel {
  final String? id;
  final String? type;
  final String? groupName;
  final String? groupProfileImage;
  final List<GroupMembersListModel>? members;
  final bool? blockedByAdmin;
  final bool? createdByAdmin;
  final bool? publicGroup;
  final bool? ordersConversation;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int? v;
  final String? description;
  final String? lastMessage;
  final String? lastMessageId;
  final String? lastMessageType;
  final String? groupCoverImage;
  final List<GroupMediaModel>? media;

  const GroupDetailsModel({
    this.id,
    this.groupCoverImage,
    this.type,
    this.groupName,
    this.groupProfileImage,
    this.members,
    this.blockedByAdmin,
    this.createdByAdmin,
    this.publicGroup,
    this.ordersConversation,
    this.updatedAt,
    this.createdAt,
    this.v,
    this.description,
    this.lastMessage,
    this.lastMessageId,
    this.lastMessageType,
    this.media,
  });

  GroupDetailsModel copyWith({
    String? id,
    String? type,
    String? groupName,
    String? groupProfileImage,
    List<GroupMembersListModel>? members,
    bool? blockedByAdmin,
    bool? createdByAdmin,
    String? groupCoverImage,
    bool? publicGroup,
    bool? ordersConversation,
    DateTime? updatedAt,
    DateTime? createdAt,
    int? v,
    String? description,
    String? lastMessage,
    String? lastMessageId,
    String? lastMessageType,
    List<GroupMediaModel>? media,
  }) {
    return GroupDetailsModel(
      id: id ?? this.id,
      type: type ?? this.type,
      groupName: groupName ?? this.groupName,
      groupProfileImage: groupProfileImage ?? this.groupProfileImage,
      members: members ?? this.members,
      blockedByAdmin: blockedByAdmin ?? this.blockedByAdmin,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      publicGroup: publicGroup ?? this.publicGroup,
      ordersConversation: ordersConversation ?? this.ordersConversation,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      v: v ?? this.v,
      description: description ?? this.description,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      groupCoverImage: groupCoverImage ?? this.groupCoverImage,
      media: media ?? this.media,
    );
  }

  factory GroupDetailsModel.fromJson(Map<String, dynamic> json) {
    return GroupDetailsModel(
      id: json['_id'] as String?,
      type: json['type'] as String?,
      groupName: json['group_name'] as String?,
      groupProfileImage: json['group_profile_image'] as String?,
      groupCoverImage: json['group_cover_image'] as String?,
      members: (json['members'] as List?)
          ?.map((e) => GroupMembersListModel.fromJson(e))
          .toList(),
      blockedByAdmin: json['blocked_by_admin'] as bool?,
      createdByAdmin: json['created_by_admin'] as bool?,
      publicGroup: json['public_group'] as bool?,
      ordersConversation: json['orders_conversation'] as bool?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      v: json['__v'] as int?,
      description: json['description'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageId: json['last_message_id'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      media: (json['media'] as List?)
          ?.map((e) => GroupMediaModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'group_name': groupName,
      'group_profile_image': groupProfileImage,
      'members': members?.map((e) => e.toJson()).toList(),
      'blocked_by_admin': blockedByAdmin,
      'created_by_admin': createdByAdmin,
      'public_group': publicGroup,
      'orders_conversation': ordersConversation,
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      '__v': v,
      'description': description,
      'last_message': lastMessage,
      'last_message_id': lastMessageId,
      "group_cover_image": groupCoverImage,
      'last_message_type': lastMessageType,
      'media': media?.map((e) => e.toJson()).toList(),
    };
  }
}

class GroupMembersListModel {
  final String? id;
  final String? accountType;
  final String? name;
  final String? contact;
  final String? businessId;
  final String? profileImage;
  final String? email;
  final String? location;
  final bool? isAdmin;

  const GroupMembersListModel({
    this.id,
    this.accountType,
    this.name,
    this.contact,
    this.businessId,
    this.profileImage,
    this.email,
    this.location,
    this.isAdmin,
  });

  GroupMembersListModel copyWith({
    String? id,
    String? accountType,
    String? name,
    String? contact,
    String? businessId,
    String? profileImage,
    String? email,
    String? location,
    bool? isAdmin,
  }) {
    return GroupMembersListModel(
      id: id ?? this.id,
      accountType: accountType ?? this.accountType,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      businessId: businessId ?? this.businessId,
      profileImage: profileImage ?? this.profileImage,
      email: email ?? this.email,
      location: location ?? this.location,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  factory GroupMembersListModel.fromJson(Map<String, dynamic> json) {
    return GroupMembersListModel(
      id: json['id'] as String?,
      accountType: json['account_type'] as String?,
      name: json['name'] as String?,
      contact: json['contact']?.toString(),
      businessId: json['business_id'] as String?,
      profileImage: json['profile_image'] as String?,
      email: json['email'] as String?,
      location: json['location'] as String?,
      isAdmin: json['is_admin'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_type': accountType,
      'name': name,
      'contact': contact,
      'business_id': businessId,
      'profile_image': profileImage,
      'email': email,
      'location': location,
      'is_admin': isAdmin,
    };
  }
}

class GroupMediaModel {
  final String? id;
  final String? messageType;
  final List<MessageMediaUrl>? url;
  final String? senderId;
  final DateTime? createdAt;

  const GroupMediaModel({
    this.id,
    this.messageType,
    this.url,
    this.senderId,
    this.createdAt,
  });

  factory GroupMediaModel.fromJson(Map<String, dynamic> json) {
    return GroupMediaModel(
      id: json['_id'] as String?,
      messageType: json['message_type'] as String?,
      senderId: json['senderId'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      url: (json['url'] as List?)
          ?.map((e) => MessageMediaUrl.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'message_type': messageType,
      'senderId': senderId,
      'created_at': createdAt?.toIso8601String(),
      'url': url?.map((e) => e.toJson()).toList(),
    };
  }
}


