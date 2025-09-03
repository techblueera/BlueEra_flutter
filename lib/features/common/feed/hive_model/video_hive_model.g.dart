// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoFeedItemHiveAdapter extends TypeAdapter<VideoFeedItemHive> {
  @override
  final int typeId = 5;

  @override
  VideoFeedItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoFeedItemHive(
      videoId: fields[0] as String?,
      position: fields[1] as int?,
      score: fields[2] as String?,
      reason: fields[3] as String?,
      video: fields[4] as VideoDataHive?,
      author: fields[5] as AuthorHive?,
      channel: fields[6] as ChannelHive?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoFeedItemHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.position)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.video)
      ..writeByte(5)
      ..write(obj.author)
      ..writeByte(6)
      ..write(obj.channel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoFeedItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VideoDataHiveAdapter extends TypeAdapter<VideoDataHive> {
  @override
  final int typeId = 6;

  @override
  VideoDataHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoDataHive(
      id: fields[0] as String?,
      userId: fields[1] as String?,
      channelId: fields[2] as String?,
      type: fields[3] as String?,
      status: fields[4] as String?,
      title: fields[5] as String?,
      subheading: fields[6] as String?,
      description: fields[7] as String?,
      caption: fields[8] as String?,
      coverUrl: fields[9] as String?,
      videoUrl: fields[10] as String?,
      duration: fields[11] as int?,
      transcodedUrls: (fields[12] as Map?)?.cast<String, String>(),
      tags: (fields[13] as List?)?.cast<String>(),
      keywords: (fields[14] as List?)?.cast<String>(),
      categories: (fields[15] as List?)?.cast<CategoryHive>(),
      song: fields[17] as SongHive?,
      location: fields[16] as LocationHive?,
      isCollaboration: fields[18] as bool?,
      allowComments: fields[19] as bool?,
      allowGifting: fields[20] as bool?,
      taggedUser: (fields[21] as List?)?.cast<TaggedUserHive>(),
      isMatureContent: fields[22] as bool?,
      relatedVideoLink: fields[23] as String?,
      acceptBookingsOrEnquiries: fields[24] as bool?,
      isBrandPromotion: fields[25] as bool?,
      brandPromotionLink: fields[26] as String?,
      stats: fields[27] as StatsHive?,
      createdAt: fields[28] as String?,
      updatedAt: fields[29] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoDataHive obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.channelId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.subheading)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.caption)
      ..writeByte(9)
      ..write(obj.coverUrl)
      ..writeByte(10)
      ..write(obj.videoUrl)
      ..writeByte(11)
      ..write(obj.duration)
      ..writeByte(12)
      ..write(obj.transcodedUrls)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.keywords)
      ..writeByte(15)
      ..write(obj.categories)
      ..writeByte(16)
      ..write(obj.location)
      ..writeByte(17)
      ..write(obj.song)
      ..writeByte(18)
      ..write(obj.isCollaboration)
      ..writeByte(19)
      ..write(obj.allowComments)
      ..writeByte(20)
      ..write(obj.allowGifting)
      ..writeByte(21)
      ..write(obj.taggedUser)
      ..writeByte(22)
      ..write(obj.isMatureContent)
      ..writeByte(23)
      ..write(obj.relatedVideoLink)
      ..writeByte(24)
      ..write(obj.acceptBookingsOrEnquiries)
      ..writeByte(25)
      ..write(obj.isBrandPromotion)
      ..writeByte(26)
      ..write(obj.brandPromotionLink)
      ..writeByte(27)
      ..write(obj.stats)
      ..writeByte(28)
      ..write(obj.createdAt)
      ..writeByte(29)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoDataHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuthorHiveAdapter extends TypeAdapter<AuthorHive> {
  @override
  final int typeId = 7;

  @override
  AuthorHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthorHive(
      id: fields[0] as String?,
      accountType: fields[1] as String?,
      username: fields[2] as String?,
      profileImage: fields[3] as String?,
      name: fields[4] as String?,
      designation: fields[5] as String?,
      isVerified: fields[6] as bool?,
      followersCount: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AuthorHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountType)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.profileImage)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.designation)
      ..writeByte(6)
      ..write(obj.isVerified)
      ..writeByte(7)
      ..write(obj.followersCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChannelHiveAdapter extends TypeAdapter<ChannelHive> {
  @override
  final int typeId = 8;

  @override
  ChannelHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelHive(
      websites: (fields[0] as List?)?.cast<String>(),
      id: fields[1] as String?,
      name: fields[2] as String?,
      username: fields[3] as String?,
      bio: fields[4] as String?,
      logoUrl: fields[5] as String?,
      coverImageUrl: fields[6] as String?,
      category: fields[7] as String?,
      gstCode: fields[8] as String?,
      isVerified: fields[9] as bool?,
      claimedBy: fields[10] as String?,
      createdAt: fields[11] as String?,
      updatedAt: fields[12] as String?,
      isFollowing: fields[13] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ChannelHive obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.websites)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.bio)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.coverImageUrl)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.gstCode)
      ..writeByte(9)
      ..write(obj.isVerified)
      ..writeByte(10)
      ..write(obj.claimedBy)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.isFollowing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryHiveAdapter extends TypeAdapter<CategoryHive> {
  @override
  final int typeId = 9;

  @override
  CategoryHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryHive(
      id: fields[0] as String?,
      name: fields[1] as String?,
      slug: fields[2] as String?,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.slug)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaggedUserHiveAdapter extends TypeAdapter<TaggedUserHive> {
  @override
  final int typeId = 10;

  @override
  TaggedUserHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaggedUserHive(
      id: fields[0] as String,
      username: fields[1] as String,
      accountType: fields[2] as String,
      profileImage: fields[3] as String,
      name: fields[4] as String,
      designation: fields[5] as String,
      isVerified: fields[6] as bool,
      followersCount: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TaggedUserHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.accountType)
      ..writeByte(3)
      ..write(obj.profileImage)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.designation)
      ..writeByte(6)
      ..write(obj.isVerified)
      ..writeByte(7)
      ..write(obj.followersCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaggedUserHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationHiveAdapter extends TypeAdapter<LocationHive> {
  @override
  final int typeId = 11;

  @override
  LocationHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationHive(
      id: fields[0] as String?,
      name: fields[1] as String?,
      lat: fields[2] as double?,
      lng: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SongHiveAdapter extends TypeAdapter<SongHive> {
  @override
  final int typeId = 12;

  @override
  SongHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongHive(
      id: fields[0] as String?,
      name: fields[1] as String?,
      artist: fields[2] as String?,
      coverUrl: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SongHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.coverUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StatsHiveAdapter extends TypeAdapter<StatsHive> {
  @override
  final int typeId = 13;

  @override
  StatsHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StatsHive(
      views: fields[0] as int?,
      likes: fields[1] as int?,
      shares: fields[2] as int?,
      comments: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StatsHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.views)
      ..writeByte(1)
      ..write(obj.likes)
      ..writeByte(2)
      ..write(obj.shares)
      ..writeByte(3)
      ..write(obj.comments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
