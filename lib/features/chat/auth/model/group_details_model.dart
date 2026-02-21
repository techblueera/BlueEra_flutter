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

  GroupDetailsModel({
    this.id,
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
  });

  factory GroupDetailsModel.fromJson(Map<String, dynamic> json) {
    return GroupDetailsModel(
      id: json['_id'],
      type: json['type'],
      groupName: json['group_name'],
      groupProfileImage:json['group_profile_image'],
      members: (json['members'] as List?)
          ?.map((e) => GroupMembersListModel.fromJson(e))
          .toList(),
      blockedByAdmin: json['blocked_by_admin'],
      createdByAdmin: json['created_by_admin'],
      publicGroup: json['public_group'],
      ordersConversation: json['orders_conversation'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      v: json['__v'],
      description: json['description'],
      lastMessage: json['last_message'],
      lastMessageId: json['last_message_id'],
      lastMessageType: json['last_message_type'],
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
      'last_message_type': lastMessageType,
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

  GroupMembersListModel({
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

  factory GroupMembersListModel.fromJson(Map<String, dynamic> json) {
    return GroupMembersListModel(
      id: json['id'],
      accountType: json['account_type'],
      name: json['name'],
      contact: json['contact']?.toString(),
      businessId: json['business_id'],
      profileImage: json['profile_image'],
      email: json['email'],
      location: json['location'],
      isAdmin: json['is_admin'],
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