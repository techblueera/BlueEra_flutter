class OpenedMessageDataModel {
  final String? conversationId;
  final String? messageId;
  final String? senderProfileImage;
  final String? priority;
  final String? type;
  final String? title;
  final String? message;
  final String? userId;
  final String? conversationType;
  final String? senderName;
  final String? senderId;
  final String? messageType;
  final String? senderContact;
  final String? notificationId;
  final String? senderType;
  final String? operation;
  final DateTime? timestamp;

  OpenedMessageDataModel({
    this.conversationId,
    this.messageId,
    this.senderProfileImage,
    this.priority,
    this.type,
    this.title,
    this.message,
    this.userId,
    this.conversationType,
    this.senderName,
    this.senderId,
    this.messageType,
    this.senderContact,
    this.notificationId,
    this.senderType,
    this.operation,
    this.timestamp,
  });

  factory OpenedMessageDataModel.fromJson(Map<String, dynamic> json) {
    return OpenedMessageDataModel(
      conversationId: json['conversationId'],
      messageId: json['messageId'],
      senderProfileImage: json['senderProfileImage'],
      priority: json['priority'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      userId: json['userId'],
      conversationType: json['conversationType'],
      senderName: json['senderName'],
      senderId: json['senderId'],
      messageType: json['messageType'],
      senderContact: json['senderContact']?.toString(),
      notificationId: json['notificationId']?.toString(),
      senderType: json['senderType'],
      operation: json['operation'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'messageId': messageId,
      'senderProfileImage': senderProfileImage,
      'priority': priority,
      'type': type,
      'title': title,
      'message': message,
      'userId': userId,
      'conversationType': conversationType,
      'senderName': senderName,
      'senderId': senderId,
      'messageType': messageType,
      'senderContact': senderContact,
      'notificationId': notificationId,
      'senderType': senderType,
      'operation': operation,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}
