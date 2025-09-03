// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_sender_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSenderAdapter extends TypeAdapter<HiveSender> {
  @override
  final int typeId = 13;

  @override
  HiveSender read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSender(
      id: fields[0] as String?,
      name: fields[1] as String?,
      profileImage: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSender obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.profileImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
