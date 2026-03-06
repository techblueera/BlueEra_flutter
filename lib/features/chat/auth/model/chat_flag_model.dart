import 'dart:ui';

class ChatFlagModel {
  final String id;
  final String label;
  final String emoji;
  final int colorValue;

  ChatFlagModel({
    required this.id,
    required this.label,
    required this.emoji,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'emoji': emoji,
        'colorValue': colorValue,
      };

  factory ChatFlagModel.fromJson(Map<String, dynamic> json) => ChatFlagModel(
        id: json['id'],
        label: json['label'],
        emoji: json['emoji'],
        colorValue: json['colorValue'],
      );

  static List<ChatFlagModel> get defaultFlags => [
        ChatFlagModel(id: 'priority', label: 'Priority', emoji: '\u2B50', colorValue: 0xFFFFC107),
        ChatFlagModel(id: 'new_customer', label: 'New customer', emoji: '\uD83D\uDEA9', colorValue: 0xFFE53935),
        ChatFlagModel(id: 'new_order', label: 'New order', emoji: '\uD83C\uDD95', colorValue: 0xFF2196F3),
        ChatFlagModel(id: 'pending_payment', label: 'Pending payment', emoji: '\u23F3', colorValue: 0xFFFF9800),
        ChatFlagModel(id: 'order_complete', label: 'Order complete', emoji: '\u2705', colorValue: 0xFF4CAF50),
        ChatFlagModel(id: 'important', label: 'Important', emoji: '\u2B50', colorValue: 0xFFFFEB3B),
        ChatFlagModel(id: 'follow_up', label: 'Follow up', emoji: '\uD83D\uDD14', colorValue: 0xFF9C27B0),
        ChatFlagModel(id: 'lead', label: 'Lead', emoji: '\uD83C\uDFAF', colorValue: 0xFFFF5722),
        ChatFlagModel(id: 'inquiry', label: 'Inquiry', emoji: '\uD83D\uDCAC', colorValue: 0xFF00BCD4),
        ChatFlagModel(id: 'quotation', label: 'Quotation', emoji: '\uD83D\uDCC4', colorValue: 0xFF607D8B),
        ChatFlagModel(id: 'processing', label: 'Processing', emoji: '\u2699\uFE0F', colorValue: 0xFF795548),
        ChatFlagModel(id: 'shipped', label: 'Shipped', emoji: '\uD83D\uDE9A', colorValue: 0xFF3F51B5),
        ChatFlagModel(id: 'negotiation', label: 'Negotiation', emoji: '\uD83E\uDD1D', colorValue: 0xFF009688),
      ];
}

class ConversationFlag {
  final String conversationId;
  final ChatFlagModel flag;

  ConversationFlag({
    required this.conversationId,
    required this.flag,
  });

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'flag': flag.toJson(),
      };

  factory ConversationFlag.fromJson(Map<String, dynamic> json) =>
      ConversationFlag(
        conversationId: json['conversationId'],
        flag: ChatFlagModel.fromJson(json['flag']),
      );
}
