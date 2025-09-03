// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostHiveModelAdapter extends TypeAdapter<PostHiveModel> {
  @override
  final int typeId = 1;

  @override
  PostHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostHiveModel(
      id: fields[0] as String,
      authorId: fields[1] as String?,
      message: fields[2] as String?,
      location: fields[3] as String?,
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
      title: fields[6] as String?,
      subTitle: fields[7] as String?,
      type: fields[8] as String?,
      natureOfPost: fields[9] as String?,
      referenceLink: fields[10] as String?,
      commentsCount: fields[11] as int?,
      likesCount: fields[12] as int?,
      repostCount: fields[13] as int?,
      viewsCount: fields[14] as int?,
      sharesCount: fields[15] as int?,
      totalEngagement: fields[16] as int?,
      createdAt: fields[17] as DateTime?,
      updatedAt: fields[18] as DateTime?,
      quesOptions: (fields[19] as List?)?.cast<String>(),
      taggedUsers: (fields[20] as List?)?.cast<User>(),
      media: (fields[21] as List?)?.cast<String>(),
      poll: fields[22] as Poll?,
      isLiked: fields[23] as bool?,
      user: fields[24] as User?,
      isPostSavedLocal: fields[25] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, PostHiveModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorId)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.title)
      ..writeByte(7)
      ..write(obj.subTitle)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.natureOfPost)
      ..writeByte(10)
      ..write(obj.referenceLink)
      ..writeByte(11)
      ..write(obj.commentsCount)
      ..writeByte(12)
      ..write(obj.likesCount)
      ..writeByte(13)
      ..write(obj.repostCount)
      ..writeByte(14)
      ..write(obj.viewsCount)
      ..writeByte(15)
      ..write(obj.sharesCount)
      ..writeByte(16)
      ..write(obj.totalEngagement)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.updatedAt)
      ..writeByte(19)
      ..write(obj.quesOptions)
      ..writeByte(20)
      ..write(obj.taggedUsers)
      ..writeByte(21)
      ..write(obj.media)
      ..writeByte(22)
      ..write(obj.poll)
      ..writeByte(23)
      ..write(obj.isLiked)
      ..writeByte(24)
      ..write(obj.user)
      ..writeByte(25)
      ..write(obj.isPostSavedLocal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PollAdapter extends TypeAdapter<Poll> {
  @override
  final int typeId = 2;

  @override
  Poll read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Poll(
      question: fields[0] as String?,
      options: (fields[1] as List).cast<PollOption>(),
    );
  }

  @override
  void write(BinaryWriter writer, Poll obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.options);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PollOptionAdapter extends TypeAdapter<PollOption> {
  @override
  final int typeId = 3;

  @override
  PollOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PollOption(
      text: fields[0] as String,
      isCorrect: fields[1] as bool,
      votes: (fields[2] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PollOption obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.isCorrect)
      ..writeByte(2)
      ..write(obj.votes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 4;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      username: fields[0] as String,
      profileImage: fields[1] as String,
      designation: fields[2] as String?,
      accountType: fields[3] as String?,
      name: fields[4] as String?,
      businessName: fields[5] as String?,
      business_id: fields[6] as String?,
      businessCategory: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.profileImage)
      ..writeByte(2)
      ..write(obj.designation)
      ..writeByte(3)
      ..write(obj.accountType)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.businessName)
      ..writeByte(6)
      ..write(obj.business_id)
      ..writeByte(7)
      ..write(obj.businessCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
