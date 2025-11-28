class AiReplyMessageModel {
  final String reply;
  final String conversationId;
  final String timestamp;

  AiReplyMessageModel({
    required this.reply,
    required this.conversationId,
    required this.timestamp,
  });

  factory AiReplyMessageModel.fromJson(Map<String, dynamic> json) {
    return AiReplyMessageModel(
      reply: json['reply'] ?? '',
      conversationId: json['conversationId'] ?? '',
      timestamp: json['timestamp'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'conversationId': conversationId,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'AiReplyMessageModel(reply: $reply, conversationId: $conversationId, timestamp: $timestamp)';
  }
}
