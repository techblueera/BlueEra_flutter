class AiReplyMessageModel {
  final String reply;
  final String conversationId;
  final String timestamp;

  /// Active language lock for this conversation, echoed back by the backend.
  /// Null until the user has selected a language.
  final String? language;

  AiReplyMessageModel({
    required this.reply,
    required this.conversationId,
    required this.timestamp,
    this.language,
  });

  factory AiReplyMessageModel.fromJson(Map<String, dynamic> json) {
    return AiReplyMessageModel(
      reply: json['reply'] ?? '',
      conversationId: json['conversationId'] ?? '',
      timestamp: json['timestamp'].toString(),
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'conversationId': conversationId,
      'timestamp': timestamp,
      'language': language,
    };
  }

  @override
  String toString() {
    return 'AiReplyMessageModel(reply: $reply, conversationId: $conversationId, timestamp: $timestamp, language: $language)';
  }
}
