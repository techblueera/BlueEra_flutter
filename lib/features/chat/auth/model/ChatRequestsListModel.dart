/// Response model for `GET chat-service/chat/requests`.
///
/// Each [ChatRequest] represents a pending chat request originating from a
/// `reply_to_symbol` message — see
/// `lib/docs/symbol-reply-request-integration-guide.md`.
///
/// v1.1 of the contract supports two views over the same shape:
///   • `role=incoming` (default) — the caller is the **recipient**; each card
///     carries an `initiator` block.
///   • `role=sent` — the caller is the **initiator**; each card carries a
///     `recipient` block instead.
///
/// Both views use the same model. Use [ChatRequest.counterparty] to access
/// "the other person on this card" without caring which role you're in.
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
    this.recipient,
    this.viewerRole,
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
        ? ChatRequestParty.fromJson(json['initiator'])
        : null;
    recipient = json['recipient'] != null
        ? ChatRequestParty.fromJson(json['recipient'])
        : null;
    viewerRole = json['viewer_role']?.toString();
  }

  String? conversationId;
  String? status;
  String? originSymbolId;
  String? requestedAt;
  String? lastMessage;
  String? lastMessageType;
  dynamic lastMessageId;

  /// Present when the caller is the recipient (`role=incoming`) or when
  /// `GET /chat/requests/:id` resolves both parties.
  ChatRequestParty? initiator;

  /// Present when the caller is the initiator (`role=sent`) or when
  /// `GET /chat/requests/:id` resolves both parties.
  ChatRequestParty? recipient;

  /// `"initiator"` | `"recipient"`. Only returned by
  /// `GET /chat/requests/:id` so the client can branch UI affordances
  /// (Cancel vs Accept/Decline) without comparing user IDs.
  String? viewerRole;

  /// Returns the "other person" on this card regardless of which role view
  /// you're rendering. Falls back gracefully if the server omits one side.
  ChatRequestParty? get counterparty => recipient ?? initiator;

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'status': status,
        'origin_symbol_id': originSymbolId,
        'requested_at': requestedAt,
        'last_message': lastMessage,
        'last_message_type': lastMessageType,
        'last_message_id': lastMessageId,
        if (initiator != null) 'initiator': initiator!.toJson(),
        if (recipient != null) 'recipient': recipient!.toJson(),
        if (viewerRole != null) 'viewer_role': viewerRole,
      };
}

/// Either side of a request — initiator OR recipient. Both sides share the
/// same shape, so a single class covers both.
class ChatRequestParty {
  ChatRequestParty({this.id, this.name, this.contact, this.profileImage});

  ChatRequestParty.fromJson(dynamic json) {
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

/// Back-compat alias — older call sites referenced `ChatRequestInitiator`.
typedef ChatRequestInitiator = ChatRequestParty;

class ChatRequestsPagination {
  ChatRequestsPagination({this.limit, this.nextCursor, this.hasMore, this.role});

  ChatRequestsPagination.fromJson(dynamic json) {
    limit = json['limit'] is int
        ? json['limit'] as int
        : int.tryParse(json['limit']?.toString() ?? '');
    nextCursor = json['next_cursor']?.toString();
    hasMore = json['has_more'] is bool
        ? json['has_more'] as bool
        : (json['has_more']?.toString().toLowerCase() == 'true');
    role = json['role']?.toString();
  }

  int? limit;
  String? nextCursor;
  bool? hasMore;

  /// `"incoming"` | `"sent"` — echoed back by the server so the client can
  /// confirm which view it received (handy when paginating).
  String? role;

  Map<String, dynamic> toJson() => {
        'limit': limit,
        'next_cursor': nextCursor,
        'has_more': hasMore,
        if (role != null) 'role': role,
      };
}