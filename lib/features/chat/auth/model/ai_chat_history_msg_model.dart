class AiChatHistoryMessageModel {
  final String role;
  final String content;
  final String? id;
  final String? timestamp;

  AiChatHistoryMessageModel({
    required this.role,
    required this.content,
    this.id,
    this.timestamp,
  });

  factory AiChatHistoryMessageModel.fromJson(Map<String, dynamic> json) {
    return AiChatHistoryMessageModel(
      role: json["role"] ?? "",
      content: json["content"] ?? "",
      id: json["_id"],
      timestamp: json["timestamp"] != null
          ? json["timestamp"].toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "role": role,
      "content": content,
      "_id": id,
      "timestamp": timestamp,
    };
  }
}
