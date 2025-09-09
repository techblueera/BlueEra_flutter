class CommentModelResponse {
  bool? success;
  String? message;
  List<CommentData>? data;

  CommentModelResponse({this.success, this.message, this.data});

  CommentModelResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <CommentData>[];
      json['data'].forEach((v) {
        data!.add(new CommentData.fromJson(v));
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

class CommentData {
  String? sId;
  String? message;
  List<String>? media;
  String? timeAgo;
  int? likesCount;
  bool? isLiked;
  int? repliesCount;
  CreatedBy? createdBy;
  List<Replies>? replies;

  CommentData(
      {this.sId,
        this.message,
        this.media,
        this.timeAgo,
        this.likesCount,
        this.isLiked,
        this.repliesCount,
        this.createdBy,
        this.replies});

  CommentData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    message = json['message'];
    media = json['media'].cast<String>();
    timeAgo = json['time_ago'];
    likesCount = json['likes_count'];
    isLiked = json['isLiked'];
    repliesCount = json['replies_count'];
    createdBy = json['created_by'] != null
        ? new CreatedBy.fromJson(json['created_by'])
        : null;
    if (json['replies'] != null) {
      replies = <Replies>[];
      json['replies'].forEach((v) {
        replies!.add(new Replies.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['message'] = this.message;
    data['media'] = this.media;
    data['time_ago'] = this.timeAgo;
    data['likes_count'] = this.likesCount;
    data['isLiked'] = this.isLiked;
    data['replies_count'] = this.repliesCount;
    if (this.createdBy != null) {
      data['created_by'] = this.createdBy!.toJson();
    }
    if (this.replies != null) {
      data['replies'] = this.replies!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  CommentData copyWith({
    String? sId,
    String? message,
    List<String>? media,
    String? timeAgo,
    int? likesCount,
    bool? isLiked,
    int? repliesCount,
    CreatedBy? createdBy,
    List<Replies>? replies,
  }) {
    return CommentData(
      sId: sId ?? this.sId,
      message: message ?? this.message,
      media: media ?? this.media,
      timeAgo: timeAgo ?? this.timeAgo,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      repliesCount: repliesCount ?? this.repliesCount,
      createdBy: createdBy ?? this.createdBy,
      replies: replies ?? this.replies,
    );
  }
}

class CreatedBy {
  String? sId;
  String? accountType;
  String? username;
  String? profilePic;
  String? designation;
  String? name;
  String? businessName;
  String? businessCategory;

  CreatedBy({
    this.sId,
    this.accountType,
    this.username,
    this.profilePic,
    this.designation,
    this.name,
    this.businessName,
    this.businessCategory
  });

  CreatedBy.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    accountType = json['account_type'];
    username = json['username'];
    profilePic = json['profile_image'];
    designation = json['designation'];
    name = json['name'];
    businessName = json['business_name'];
    businessCategory = json['business_category'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['account_type'] = accountType;
    data['username'] = username;
    data['profile_image'] = profilePic;
    data['designation'] = designation;
    data['name'] = name;
    data['business_name'] = businessName;
    data['business_category'] = businessCategory;
    return data;
  }
}

class Replies {
  String? sId;
  String? message;
  List<String>? media;
  String? timeAgo;
  int? likesCount;
  bool? isLiked;
  CreatedBy? createdBy;

  Replies(
      {this.sId,
        this.message,
        this.media,
        this.timeAgo,
        this.likesCount,
        this.isLiked,
        this.createdBy});

  Replies.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    message = json['message'];
    media = json['media'].cast<String>();
    timeAgo = json['time_ago'];
    likesCount = json['likes_count'];
    isLiked = json['isLiked'];
    createdBy = json['created_by'] != null
        ? new CreatedBy.fromJson(json['created_by'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['message'] = this.message;
    data['media'] = this.media;
    data['time_ago'] = this.timeAgo;
    data['likes_count'] = this.likesCount;
    data['isLiked'] = this.isLiked;
    if (this.createdBy != null) {
      data['created_by'] = this.createdBy!.toJson();
    }
    return data;
  }

  Replies copyWith({
    String? sId,
    String? message,
    List<String>? media,
    String? timeAgo,
    int? likesCount,
    bool? isLiked,
    CreatedBy? createdBy,
  }) {
    return Replies(
      sId: sId ?? this.sId,
      message: message ?? this.message,
      media: media ?? this.media,
      timeAgo: timeAgo ?? this.timeAgo,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdBy: createdBy ?? this.createdBy,
    );
  }

}