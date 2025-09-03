class FollowingModel {
  final bool? success;
  final String? message;
  final List<Following>? data;
  final FollowingMeta? meta;

  FollowingModel({
    this.success,
    this.message,
    this.data,
    this.meta,
  });

  factory FollowingModel.fromJson(Map<String, dynamic> json) {
    return FollowingModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)?.map((e) => Following.fromJson(e as Map<String, dynamic>)).toList(),
      meta: json['meta'] != null ? FollowingMeta.fromJson(json['meta'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.map((e) => e.toJson()).toList(),
        'meta': meta?.toJson(),
      };
}

class Following {
  final int? id;
  final String? name;
  final String? username;
  final String? profileImage;
  final ReelProfile? reelProfile;
  final bool? isFollowing;
  final bool? isSelf;

  Following({
    this.id,
    this.name,
    this.username,
    this.profileImage,
    this.reelProfile,
    this.isFollowing,
    this.isSelf,
  });

  factory Following.fromJson(Map<String, dynamic> json) {
    return Following(
      id: json['id'] as int?,
      name: json['name'] as String?,
      username: json['username'] as String?,
      profileImage: json['profile_image'] as String?,
      reelProfile:
          json['reelProfile'] != null ? ReelProfile.fromJson(json['reelProfile'] as Map<String, dynamic>) : null,
      isFollowing: json['isFollowing'] as bool?,
      isSelf: json['isSelf'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'profile_image': profileImage,
        'reelProfile': reelProfile?.toJson(),
        'isFollowing': isFollowing,
        'isSelf': isSelf,
      };
}

class ReelProfile {
  final int? id;
  final String? channelName;
  final String? profileImage;
  final String? channelBio;

  ReelProfile({
    this.id,
    this.channelName,
    this.profileImage,
    this.channelBio,
  });

  factory ReelProfile.fromJson(Map<String, dynamic> json) {
    return ReelProfile(
      id: json['id'] as int?,
      channelName: json['channel_name'] as String?,
      profileImage: json['profile_image'] as String?,
      channelBio: json['channel_bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_name': channelName,
        'profile_image': profileImage,
        'channel_bio': channelBio,
      };
}

class FollowingMeta {
  final int? total;
  final bool? isOwnProfile;

  FollowingMeta({
    this.total,
    this.isOwnProfile,
  });

  factory FollowingMeta.fromJson(Map<String, dynamic> json) {
    return FollowingMeta(
      total: json['total'] as int?,
      isOwnProfile: json['isOwnProfile'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'isOwnProfile': isOwnProfile,
      };
}
