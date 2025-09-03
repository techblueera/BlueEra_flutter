// hive_chat_list_model.dart
import 'package:hive/hive.dart';

import 'hive_sender_model.dart';

part 'hive_chatlist_model.g.dart';

@HiveType(typeId: 12)
class HiveChatList extends HiveObject {
  @HiveField(0)
  String? conversationId;

  @HiveField(1)
  bool? isGroup;

  @HiveField(2)
  String? lastMessage;

  @HiveField(3)
  String? lastMessageType;

  @HiveField(4)
  String? createdAt;

  @HiveField(5)
  String? updatedAt;

  @HiveField(6)
  num? unreadCount;

  @HiveField(7)
  bool? publicGroup;

  @HiveField(8)
  HiveSender? sender;

  HiveChatList({
    this.conversationId,
    this.isGroup,
    this.lastMessage,
    this.lastMessageType,
    this.createdAt,
    this.updatedAt,
    this.unreadCount,
    this.publicGroup,
    this.sender,
  });
}
