// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_messages_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveMessageAdapter extends TypeAdapter<HiveMessage> {
  @override
  final int typeId = 14;

  @override
  HiveMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveMessage(
      messageId: fields[0] as String?,
      message: fields[1] as String?,
      messageType: fields[2] as String?,
      senderId: fields[3] as String?,
      conversationId: fields[4] as String?,
      myMessage: fields[5] as bool?,
      createdAt: fields[6] as String?,
      localMediaPaths: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveMessage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.messageType)
      ..writeByte(3)
      ..write(obj.senderId)
      ..writeByte(4)
      ..write(obj.conversationId)
      ..writeByte(5)
      ..write(obj.myMessage)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.localMediaPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
