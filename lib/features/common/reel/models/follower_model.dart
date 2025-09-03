// import 'package:equatable/equatable.dart';
//
// class FollowerModel extends Equatable {
//   final bool? success;
//   final String? message;
//   final List<Follower>? data;
//   final FollowerMeta? meta;
//
//   const FollowerModel({
//     this.success,
//     this.message,
//     this.data,
//     this.meta,
//   });
//
//   factory FollowerModel.fromJson(Map<String, dynamic> json) {
//     return FollowerModel(
//       success: json['success'] as bool?,
//       message: json['message'] as String?,
//       data: (json['data'] as List<dynamic>?)?.map((e) => Follower.fromJson(e as Map<String, dynamic>)).toList(),
//       meta: json['meta'] != null ? FollowerMeta.fromJson(json['meta'] as Map<String, dynamic>) : null,
//     );
//   }
//
//   @override
//   List<Object?> get props => [success, message, data, meta];
// }
//
// class Follower extends Equatable {
//   final int? id;
//   final String? name;
//   final String? username;
//   final String? profileImage;
//   final ReelProfile? reelProfile;
//   final bool? isFollowing;
//   final bool? isSelf;
//
//   const Follower({
//     this.id,
//     this.name,
//     this.username,
//     this.profileImage,
//     this.reelProfile,
//     this.isFollowing,
//     this.isSelf,
//   });
//
//   factory Follower.fromJson(Map<String, dynamic> json) {
//     return Follower(
//       id: json['id'] as int?,
//       name: json['name'] as String?,
//       username: json['username'] as String?,
//       profileImage: json['profile_image'] as String?,
//       reelProfile:
//           json['reelProfile'] != null ? ReelProfile.fromJson(json['reelProfile'] as Map<String, dynamic>) : null,
//       isFollowing: json['isFollowing'] as bool?,
//       isSelf: json['isSelf'] as bool?,
//     );
//   }
//
//   @override
//   List<Object?> get props => [id, name, username, profileImage, reelProfile, isFollowing, isSelf];
// }
//
// class ReelProfile extends Equatable {
//   final int? id;
//   final String? channelName;
//   final String? profileImage;
//   final String? channelBio;
//
//   const ReelProfile({
//     this.id,
//     this.channelName,
//     this.profileImage,
//     this.channelBio,
//   });
//
//   factory ReelProfile.fromJson(Map<String, dynamic> json) {
//     return ReelProfile(
//       id: json['id'] as int?,
//       channelName: json['channel_name'] as String?,
//       profileImage: json['profile_image'] as String?,
//       channelBio: json['channel_bio'] as String?,
//     );
//   }
//
//   @override
//   List<Object?> get props => [id, channelName, profileImage, channelBio];
// }
//
// class FollowerMeta extends Equatable {
//   final int? total;
//   final bool? isOwnProfile;
//
//   const FollowerMeta({
//     this.total,
//     this.isOwnProfile,
//   });
//
//   factory FollowerMeta.fromJson(Map<String, dynamic> json) {
//     return FollowerMeta(
//       total: json['total'] as int?,
//       isOwnProfile: json['isOwnProfile'] as bool?,
//     );
//   }
//
//   @override
//   List<Object?> get props => [total, isOwnProfile];
// }
