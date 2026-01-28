abstract class BaseAiChatModel {
  String? conversationId;
  String? role;
  String? message;
  String? timestamp;

  BaseAiChatModel({
    this.conversationId,
    this.role,
    this.message,
    this.timestamp,
  });
}