// file: models/audio_call_response.dart
class AudioCallResponse {
  final String roomId;
  final String conversationId;
  final Message message;
  final String jitsiToken;
  final String messageId;
  final bool success;

  AudioCallResponse({
    required this.roomId,
    required this.conversationId,
    required this.message,
    required this.jitsiToken,
    required this.messageId,
    required this.success,
  });

  factory AudioCallResponse.fromJson(Map<String, dynamic> json) {
    return AudioCallResponse(
      roomId: json['room_id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      message: Message.fromJson(json['message']),
      jitsiToken: json['jitsi_token'] ?? '',
      messageId: json['message_id'] ?? '',
      success: json['success'] ?? false,
    );
  }
}

class Message {
  final String message;
  final String messageType;
  final String subType;
  final int messageRead;
  final String senderId;
  final String conversationId;
  final int likesCount;
  final int forwardsCount;
  final int repliesCount;
  final String status;
  final Metadata metadata;
  final String updatedAt;
  final String id;
  final List<dynamic> url;
  final String createdAt;
  final int v;

  Message({
    required this.message,
    required this.messageType,
    required this.subType,
    required this.messageRead,
    required this.senderId,
    required this.conversationId,
    required this.likesCount,
    required this.forwardsCount,
    required this.repliesCount,
    required this.status,
    required this.metadata,
    required this.updatedAt,
    required this.id,
    required this.url,
    required this.createdAt,
    required this.v,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? '',
      subType: json['sub_type'] ?? '',
      messageRead: json['message_read'] ?? 0,
      senderId: json['senderId'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      forwardsCount: json['forwards_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      status: json['status'] ?? '',
      metadata: Metadata.fromJson(json['metadata'] ?? {}),
      updatedAt: json['updated_at'] ?? '',
      id: json['_id'] ?? '',
      url: List<dynamic>.from(json['url'] ?? []),
      createdAt: json['created_at'] ?? '',
      v: json['__v'] ?? 0,
    );
  }
}

class Metadata {
  final bool missedCall;
  final bool callAccept;
  final bool callDecline;
  final String roomId;
  final String otherUserId;

  Metadata({
    required this.missedCall,
    required this.callAccept,
    required this.callDecline,
    required this.roomId,
    required this.otherUserId,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      missedCall: json['missed_call'] ?? false,
      callAccept: json['call_accept'] ?? false,
      callDecline: json['call_decline'] ?? false,
      roomId: json['room_id'] ?? '',
      otherUserId: json['other_user_id'] ?? '',
    );
  }
}
