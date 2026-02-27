class ReminderChatListModel {
  final String conversationId;
  final String name;
  final String profileImagePath;
  final int messageCount;
  final String? updatedAt;

  ReminderChatListModel({
    required this.conversationId,
    required this.name,
    required this.profileImagePath,
    required this.messageCount,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    "conversation_id": conversationId,
    "name": name,
    "profileImagePath": profileImagePath,
    "messageCount": messageCount,
    "updatedAt": updatedAt,
  };

  factory ReminderChatListModel.fromJson(Map<String, dynamic> json) {
    return ReminderChatListModel(
      conversationId: json["conversation_id"],
      name: json["name"],
      profileImagePath: json["profileImagePath"],
      messageCount: json["messageCount"],
      updatedAt: json["updatedAt"],
    );
  }
}