import 'package:hive/hive.dart';

part 'post_hive_model.g.dart';

@HiveType(typeId: 1)
class PostHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? authorId;

  @HiveField(2)
  final String? message;

  @HiveField(3)
  final String? location;

  @HiveField(4)
  final double? latitude;

  @HiveField(5)
  final double? longitude;

  @HiveField(6)
  final String? title;

  @HiveField(7)
  final String? subTitle;

  @HiveField(8)
  final String? type;

  @HiveField(9)
  final String? natureOfPost;

  @HiveField(10)
  final String? referenceLink;

  @HiveField(11)
  final int? commentsCount;

  @HiveField(12)
  final int? likesCount;

  @HiveField(13)
  final int? repostCount;

  @HiveField(14)
  final int? viewsCount;

  @HiveField(15)
  final int? sharesCount;

  @HiveField(16)
  final int? totalEngagement;

  @HiveField(17)
  final DateTime? createdAt;

  @HiveField(18)
  final DateTime? updatedAt;

  @HiveField(19)
  final List<String>? quesOptions;

  @HiveField(20)
  final List<User>? taggedUsers;

  @HiveField(21)
  final List<String>? media;

  @HiveField(22)
  final Poll? poll;

  @HiveField(23)
  final bool? isLiked;

  @HiveField(24)
  final User? user;

  @HiveField(25)
  final bool? isPostSavedLocal;

  PostHiveModel({
    required this.id,
    this.authorId,
    this.message,
    this.location,
    this.latitude,
    this.longitude,
    this.title,
    this.subTitle,
    this.type,
    this.natureOfPost,
    this.referenceLink,
    this.commentsCount,
    this.likesCount,
    this.repostCount,
    this.viewsCount,
    this.sharesCount,
    this.totalEngagement,
    this.createdAt,
    this.updatedAt,
    this.quesOptions,
    this.taggedUsers,
    this.media,
    this.poll,
    this.isLiked,
    this.user,
    this.isPostSavedLocal,
  });

  factory PostHiveModel.fromJson(Map<String, dynamic> json) => PostHiveModel(
    id: json['_id'],
    authorId: json['authorId'],
    message: json['message'],
    location: json['location'],
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    title: json['title'],
    subTitle: json['sub_title'],
    type: json['type'],
    natureOfPost: json['nature_of_post'],
    referenceLink: json['reference_link'],
    commentsCount: json['comments_count'],
    likesCount: json['likes_count'],
    repostCount: json['repost_count'],
    viewsCount: json['views_count'],
    sharesCount: json['shares_count'],
    totalEngagement: json['totalEngagement'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'])
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'])
        : null,
    quesOptions: (json['ques_options'] as List?)
        ?.map((e) => e.toString())
        .toList(),
    taggedUsers: (json['tagged_users_details'] as List<dynamic>?)
        ?.map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList(),
    media:
    (json['media'] as List?)?.map((e) => e.toString()).toList(),
    poll: json['poll'] != null ? Poll.fromJson(json['poll']) : null,
    isLiked: json['isLiked'],
    user: json['user'] != null ? User.fromJson(json['user']) : null,
    isPostSavedLocal: json['isPostSavedLocal'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'authorId': authorId,
    'message': message,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'title': title,
    'sub_title': subTitle,
    'type': type,
    'nature_of_post': natureOfPost,
    'reference_link': referenceLink,
    'comments_count': commentsCount,
    'likes_count': likesCount,
    'repost_count': repostCount,
    'views_count': viewsCount,
    'shares_count': sharesCount,
    'totalEngagement': totalEngagement,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'ques_options': quesOptions,
    'tagged_users_details': taggedUsers?.map((e) => e.toJson()).toList(),
    'media': media,
    'poll': poll?.toJson(),
    'isLiked': isLiked,
    'user': user?.toJson(),
    'isPostSavedLocal': isPostSavedLocal,
  };
}

@HiveType(typeId: 2)
class Poll {
  @HiveField(0)
  final String? question;

  @HiveField(1)
  final List<PollOption> options;

  Poll({this.question, required this.options});

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
    question: json['question'],
    options: (json['options'] as List<dynamic>?)
        ?.map((e) => PollOption.fromJson(e))
        .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options.map((e) => e.toJson()).toList(),
  };
}

@HiveType(typeId: 3)
class PollOption {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isCorrect;

  @HiveField(2)
  final List<String>? votes;

  PollOption({required this.text, required this.isCorrect, required this.votes});

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
    text: json['text'] ?? '',
    isCorrect: json['isCorrect'] ?? false,
    votes: (json['votes'] as List?)?.map((e) => e.toString()).toList()
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'isCorrect': isCorrect,
    'votes': votes,
  };
}

@HiveType(typeId: 4)
class User {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String profileImage;

  @HiveField(2)
  final String? designation;

  @HiveField(3)
  final String? accountType;

  @HiveField(4)
  final String? name;

  @HiveField(5)
  final String? businessName;

  @HiveField(6)
  final String? business_id;

  @HiveField(7)
  final String? businessCategory;

  User({
    required this.username,
    required this.profileImage,
    this.designation,
    this.accountType,
    this.name,
    this.businessName,
    this.business_id,
    this.businessCategory
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'] ?? '',
    profileImage: json['profile_image'] ?? '',
    designation: json['designation'],
    accountType: json['account_type'],
    name: json['name'],
    businessName: json['business_name'],
    business_id: json['business_id'],
    businessCategory: json['business_category'],
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'profile_image': profileImage,
    'designation': designation,
    'account_type': accountType,
    'name': name,
    'business_name': businessName,
    'business_id': business_id,
    'business_category': businessCategory
  };
}

