class FetchReelsModel {
  bool? status;
  String? message;
  List<GetReelsData>? data;

  FetchReelsModel({this.status, this.message, this.data});

  FetchReelsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <GetReelsData>[];
      json['data'].forEach((v) {
        data!.add(new GetReelsData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GetReelsData {
  dynamic id;
  String? caption;
  String? videoUrl;
  String? videoImage;
  dynamic songId;
  int? shareCount;
  bool? isFake;
  String? createdAt;
  List<String>? keywords;
  int? userId;
  String? name;
  String? userName;
  String? userImage;
  bool? isVerified;
  bool? isLike;
  bool? isBookmark;
  bool? isFollow;
  int? totalLikes;
  int? totalComments;
  String? time;
  bool? isProfileImageBanned;
  bool? allow_comments;
  String? songTitle;
  String? songImage;
  String? songLink;
  String? singerName;
  String? long_video_title;
  String? video_sub_title;
  String? video_long_link;
  List<TaggedUsersDetails>? taggedUsersDetails;

  GetReelsData(
      {this.id,
      this.caption,
      this.video_sub_title,
      this.long_video_title,
      this.video_long_link,
      this.videoUrl,
      this.videoImage,
      this.songId,
      this.shareCount,
      this.isFake,
      this.createdAt,
      this.keywords,
      this.userId,
      this.allow_comments,
      this.name,
      this.userName,
      this.userImage,
      this.isVerified,
      this.isLike,
      this.isBookmark,
      this.isFollow,
      // this.totalLikes,
      this.totalComments,
      this.time,
      this.isProfileImageBanned,
      this.songTitle,
      this.songImage,
      this.songLink,
      this.taggedUsersDetails,
      this.singerName});

  GetReelsData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    caption = json['caption'];
    video_long_link = json['video_long_link'];
    long_video_title = json['long_video_title'];
    video_sub_title = json['video_sub_title'];
    videoUrl = json['video'];
    videoImage = json['thumbnail'];
    songId = json['songId'];
    shareCount = json['shareCount'];
    isFake = json['isFake'];
    createdAt = json['createdAt'];
    allow_comments = json['allow_comments'];
    keywords = json['keywords']!=null?json['keywords'].cast<String>():[];
    userId = json['authorId'];
    name = json['name'];
    userName = json['userName'];
    userImage = json['userImage'];
    isVerified = json['isVerified'];
    isLike = json['isLiked'];
    isFollow = json['isFollow'];
    totalLikes = json['likes_count'];
    totalComments = json['comments_count'];
    time = json['time'];
    isProfileImageBanned = json['isProfileImageBanned'];
    songTitle = json['songTitle'];
    songImage = json['songImage'];
    songLink = json['songLink'];
    singerName = json['singerName'];
    isBookmark = json['isBookmark'];
    taggedUsersDetails= json["tagged_users_details"] != null
        ? List<TaggedUsersDetails>.from(json["tagged_users_details"].map((x) => TaggedUsersDetails.fromJson(x)))
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['caption'] = this.caption;
    data['video_long_link'] = this.video_long_link;
    data['video_sub_title'] = this.video_sub_title;
    data['long_video_title'] = this.long_video_title;
    data['video'] = this.videoUrl;
    data['thumbnail'] = this.videoImage;
    data['songId'] = this.songId;
    data['shareCount'] = this.shareCount;
    data['isFake'] = this.isFake;
    data['createdAt'] = this.createdAt;
    data['keywords'] = this.keywords;
    data['allow_comments'] = this.allow_comments;
    data['authorId'] = this.userId;

    data['name'] = this.name;
    data['userName'] = this.userName;
    data['userImage'] = this.userImage;
    data['isVerified'] = this.isVerified;
    data['isLiked'] = this.isLike;
    data['isFollow'] = this.isFollow;
    data['likes_count'] = this.totalLikes;
    data['comments_count'] = this.totalComments;
    data['time'] = this.time;
    data['isProfileImageBanned'] = this.isProfileImageBanned;
    data['songTitle'] = this.songTitle;
    data['songImage'] = this.songImage;
    data['songLink'] = this.songLink;
    data['singerName'] = this.singerName;
    data['isBookmark'] = this.isBookmark;
    data['tagged_users_details'] = this.taggedUsersDetails;
    return data;
  }
}
class TaggedUsersDetails {
  int? id;
  String? username;
  String? accountType;
  String? profileImage;
  String? name;

  TaggedUsersDetails(
      {this.id,
        this.username,
        this.accountType,
        this.profileImage,
        this.name,
      });

  TaggedUsersDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    accountType = json['account_type'];
    profileImage = json['profile_image'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['account_type'] = this.accountType;
    data['profile_image'] = this.profileImage;
    data['name'] = this.name;
    return data;
  }
}
