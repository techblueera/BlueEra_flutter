import 'package:hive/hive.dart';

part 'hive_messages_model.g.dart';

@HiveType(typeId: 14)
class HiveMessage extends HiveObject {
  @HiveField(0)
  String? messageId;

  @HiveField(1)
  String? message;

  @HiveField(2)
  String? messageType;

  @HiveField(3)
  String? senderId;

  @HiveField(4)
  String? conversationId;

  @HiveField(5)
  bool? myMessage;

  @HiveField(6)
  String? createdAt;

  @HiveField(7)
  List<String>? localMediaPaths;

  HiveMessage({
    this.messageId,
    this.message,
    this.messageType,
    this.senderId,
    this.conversationId,
    this.myMessage,
    this.createdAt,
    this.localMediaPaths,
  });
}
