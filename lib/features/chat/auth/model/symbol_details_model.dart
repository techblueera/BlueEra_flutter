class SymbolDetailsModel {
  String? id;
  String? userId;
  String? type;
  String? content;
  String? caption;
  DateTime? expiresAt;
  String? visibility;
  List<String>? hiddenFrom;
  List<String>? taggedUsers;
  int? likesCount;
  int? commentsCount;
  int? seenCount;

  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;
  List<dynamic>? likes;
  List<dynamic>? comments;
  List<dynamic>? seen;
  List<dynamic>? taggedUsersPopulated;
  UserModel? user;

  SymbolDetailsModel({
    this.id,
    this.userId,
    this.type,
    this.content,
    this.caption,
    this.expiresAt,
    this.visibility,
    this.hiddenFrom,
    this.taggedUsers,
    this.likesCount,
    this.commentsCount,
    this.seenCount,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.likes,
    this.comments,
    this.seen,
    this.taggedUsersPopulated,
    this.user,
  });

  factory SymbolDetailsModel.fromJson(Map<String, dynamic> json) {
    return SymbolDetailsModel(
      id: json['_id'],
      userId: json['user_id'],
      type: json['type'],
      content: json['content'],
      caption: json['caption'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      visibility: json['visibility'],
      hiddenFrom: json['hidden_from'] != null
          ? List<String>.from(json['hidden_from'])
          : [],
      taggedUsers: json['tagged_users'] != null
          ? List<String>.from(json['tagged_users'])
          : [],
      likesCount: json['likes_count'],
      commentsCount: json['comments_count'],
      seenCount: json['seen_count'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      v: json['__v'],
      likes: json['likes'] ?? [],
      comments: json['comments'] ?? [],
      seen: json['seen'] ?? [],
      taggedUsersPopulated: json['tagged_users_populated'] ?? [],
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'type': type,
      'content': content,
      'caption': caption,
      'expires_at': expiresAt?.toIso8601String(),
      'visibility': visibility,
      'hidden_from': hiddenFrom,
      'tagged_users': taggedUsers,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'seen_count': seenCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      '__v': v,
      'likes': likes,
      'comments': comments,
      'seen': seen,
      'tagged_users_populated': taggedUsersPopulated,
      'user': user?.toJson(),
    };
  }
}
class UserModel {
  String? id;
  String? name;
  String? gender;
  String? contactNo;
  String? profession;
  String? designation;
  String? profileImage;
  String? username;
  String? email;
  bool? emailVerified;
  String? bio;
  String? language;
  String? accountType;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserModel({
    this.id,
    this.name,
    this.gender,
    this.contactNo,
    this.profession,
    this.designation,
    this.profileImage,
    this.username,
    this.email,
    this.emailVerified,
    this.bio,
    this.language,
    this.accountType,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      contactNo: json['contact_no'],
      profession: json['profession'],
      designation: json['designation'],
      profileImage: json['profile_image'],
      username: json['username'],
      email: json['email'],
      emailVerified: json['email_verified'],
      bio: json['bio'],
      language: json['language'],
      accountType: json['account_type'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'contact_no': contactNo,
      'profession': profession,
      'designation': designation,
      'profile_image': profileImage,
      'username': username,
      'email': email,
      'email_verified': emailVerified,
      'bio': bio,
      'language': language,
      'account_type': accountType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
