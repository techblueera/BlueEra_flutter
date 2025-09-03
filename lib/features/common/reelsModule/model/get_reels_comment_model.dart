class GetReelCommentsModel {
  bool? success;
  String? message;
  List<ReelCommentsData>? data;

  GetReelCommentsModel({this.success, this.message, this.data});

  GetReelCommentsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ReelCommentsData>[];
      json['data'].forEach((v) {
        data!.add(new ReelCommentsData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ReelCommentsData {
  int? id;
  int? reelId;
  String? message;
  int? createdBy;
  String? createdAt;
  String? updatedAt;
  int? likesCount;
  int? updatedBy;
  Users? users;
  Count? cCount;
  bool? isLiked;
  int? repliesCount;

  ReelCommentsData(
      {this.id,
        this.reelId,
        this.message,
        this.createdBy,
        this.createdAt,
        this.updatedAt,
        this.likesCount,
        this.updatedBy,
        this.users,
        this.cCount,
        this.isLiked,
        this.repliesCount});

  ReelCommentsData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reelId = json['reel_id'];
    message = json['message'];
    createdBy = json['created_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    likesCount = json['likes_count'];
    updatedBy = json['updated_by'];
    users = json['users'] != null ? new Users.fromJson(json['users']) : null;

    cCount = json['_count'] != null ? new Count.fromJson(json['_count']) : null;
    isLiked = json['isLiked'];
    repliesCount = json['replies_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['reel_id'] = this.reelId;
    data['message'] = this.message;
    data['created_by'] = this.createdBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['likes_count'] = this.likesCount;
    data['updated_by'] = this.updatedBy;
    if (this.users != null) {
      data['users'] = this.users!.toJson();
    }

    if (this.cCount != null) {
      data['_count'] = this.cCount!.toJson();
    }
    data['isLiked'] = this.isLiked;
    data['replies_count'] = this.repliesCount;
    return data;
  }
}

class Users {
  int? id;
  String? name;
  String? username;
  String? profileImage;

  Users({this.id, this.name, this.username, this.profileImage});

  Users.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    username = json['username'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['username'] = this.username;
    data['profile_image'] = this.profileImage;
    return data;
  }
}

class Count {
  int? childComments;
  int? likes;

  Count({this.childComments, this.likes});

  Count.fromJson(Map<String, dynamic> json) {
    childComments = json['childComments'];
    likes = json['likes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['childComments'] = this.childComments;
    data['likes'] = this.likes;
    return data;
  }
}
