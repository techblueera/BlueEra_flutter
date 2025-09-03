// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_chatlist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveChatListAdapter extends TypeAdapter<HiveChatList> {
  @override
  final int typeId = 12;

  @override
  HiveChatList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveChatList(
      conversationId: fields[0] as String?,
      isGroup: fields[1] as bool?,
      lastMessage: fields[2] as String?,
      lastMessageType: fields[3] as String?,
      createdAt: fields[4] as String?,
      updatedAt: fields[5] as String?,
      unreadCount: fields[6] as num?,
      publicGroup: fields[7] as bool?,
      sender: fields[8] as HiveSender?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveChatList obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.conversationId)
      ..writeByte(1)
      ..write(obj.isGroup)
      ..writeByte(2)
      ..write(obj.lastMessage)
      ..writeByte(3)
      ..write(obj.lastMessageType)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.unreadCount)
      ..writeByte(7)
      ..write(obj.publicGroup)
      ..writeByte(8)
      ..write(obj.sender);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveChatListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
