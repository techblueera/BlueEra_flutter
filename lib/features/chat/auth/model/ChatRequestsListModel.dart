/// Response model for `GET chat-service/chat/requests`.
///
/// Each `ChatRequest` represents a pending chat request originating from a
/// `reply_to_symbol` message — see lib/docs/reply-to-symbol-integration-guide.md.
class ChatRequestsListModel {
  ChatRequestsListModel({this.success, this.message, this.data, this.pagination});

  ChatRequestsListModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) => data!.add(ChatRequest.fromJson(v)));
    }
    pagination = json['pagination'] != null
        ? ChatRequestsPagination.fromJson(json['pagination'])
        : null;
  }

  bool? success;
  String? message;
  List<ChatRequest>? data;
  ChatRequestsPagination? pagination;

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.map((v) => v.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class ChatRequest {
  ChatRequest({
    this.conversationId,
    this.status,
    this.originSymbolId,
    this.requestedAt,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageId,
    this.initiator,
  });

  ChatRequest.fromJson(dynamic json) {
    conversationId = json['conversation_id']?.toString();
    status = json['status']?.toString();
    originSymbolId = json['origin_symbol_id']?.toString();
    requestedAt = json['requested_at']?.toString();
    lastMessage = json['last_message']?.toString();
    lastMessageType = json['last_message_type']?.toString();
    lastMessageId = json['last_message_id'];
    initiator = json['initiator'] != null
        ? ChatRequestInitiator.fromJson(json['initiator'])
        : null;
  }

  String? conversationId;
  String? status;
  String? originSymbolId;
  String? requestedAt;
  String? lastMessage;
  String? lastMessageType;
  dynamic lastMessageId;
  ChatRequestInitiator? initiator;

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'status': status,
        'origin_symbol_id': originSymbolId,
        'requested_at': requestedAt,
        'last_message': lastMessage,
        'last_message_type': lastMessageType,
        'last_message_id': lastMessageId,
        if (initiator != null) 'initiator': initiator!.toJson(),
      };
}

class ChatRequestInitiator {
  ChatRequestInitiator({this.id, this.name, this.contact, this.profileImage});

  ChatRequestInitiator.fromJson(dynamic json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    contact = json['contact']?.toString();
    profileImage = json['profile_image']?.toString();
  }

  String? id;
  String? name;
  String? contact;
  String? profileImage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact': contact,
        'profile_image': profileImage,
      };
}

class ChatRequestsPagination {
  ChatRequestsPagination({this.limit, this.nextCursor, this.hasMore});

  ChatRequestsPagination.fromJson(dynamic json) {
    limit = json['limit'] is int
        ? json['limit'] as int
        : int.tryParse(json['limit']?.toString() ?? '');
    nextCursor = json['next_cursor']?.toString();
    hasMore = json['has_more'] is bool
        ? json['has_more'] as bool
        : (json['has_more']?.toString().toLowerCase() == 'true');
  }

  int? limit;
  String? nextCursor;
  bool? hasMore;

  Map<String, dynamic> toJson() => {
        'limit': limit,
        'next_cursor': nextCursor,
        'has_more': hasMore,
      };
}
