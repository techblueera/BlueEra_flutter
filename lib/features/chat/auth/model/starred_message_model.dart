import 'GetListOfMessageData.dart';

/// A single starred (saved) chat message together with the conversation
/// details needed to render it in the global "Starred Messages" list — the
/// message alone doesn't carry the partner's display name/avatar.
class StarredMessage {
  final Messages message;
  final String? conversationId;
  final String? conversationName;
  final String? conversationProfileImage;

  /// Other party's user id (used so the row can deep-link back to the chat).
  final String? userId;

  /// Epoch millis when the user starred it — newest entries surface first.
  final int starredAt;

  StarredMessage({
    required this.message,
    this.conversationId,
    this.conversationName,
    this.conversationProfileImage,
    this.userId,
    required this.starredAt,
  });

  /// Stable identity for a starred entry. Server message ids are unique, but
  /// fall back to conversation + created_at for pending/local messages that
  /// haven't received an id yet.
  String get key =>
      message.id ?? '${conversationId ?? ''}_${message.createdAt ?? ''}';

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'conversation_id': conversationId,
        'conversation_name': conversationName,
        'conversation_profile_image': conversationProfileImage,
        'user_id': userId,
        'starred_at': starredAt,
      };

  factory StarredMessage.fromJson(Map<String, dynamic> json) => StarredMessage(
        message: Messages.fromJson(json['message']),
        conversationId: json['conversation_id'],
        conversationName: json['conversation_name'],
        conversationProfileImage: json['conversation_profile_image'],
        userId: json['user_id'],
        starredAt: json['starred_at'] ?? 0,
      );
}
