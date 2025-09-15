class PostResponse {
  final bool success;
  final String? message;
  final List<Post> data;
  final Pagination pagination;

  PostResponse({
    required this.success,
    this.message,
    required this.data,
    required this.pagination,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) {
    return PostResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data:
          (json['data'] as List?)?.map((e) => Post.fromJson(e)).toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  PostResponse copyWith({
    bool? success,
    String? message,
    List<Post>? data,
    Pagination? pagination,
  }) {
    return PostResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      pagination: pagination ?? this.pagination,
    );
  }
}

class Post {
  final String id;
  final String? authorId;
  final String? message;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? title;
  final String? subTitle;
  final String? type;
  final String? natureOfPost;
  final String? referenceLink;
  final int? commentsCount;
  final int? likesCount;
  final int? repostCount;
  final int? viewsCount;
  final int? sharesCount;
  final int? totalEngagement;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? quesOptions;
  final List<User>? taggedUsers;
  final List<String>? media;
  // final LocationMetadata? locationMetadata;
  final Poll? poll;
  final bool? isLiked;
  final User? user;
  final bool? isPostSavedLocal;
  final Song? song;
  final int? visibilityDuration;

  Post({
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
    // this.locationMetadata,
    this.poll,
    this.isLiked,
    this.user,
    this.isPostSavedLocal,
    this.song,
    this.visibilityDuration
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
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
      quesOptions: json['ques_options'] is List
          ? (json['ques_options'] as List).map((e) => e.toString()).toList()
          : null,
      taggedUsers:
          (json['tagged_users_details'] as List<dynamic>?)?.map((e) => User.fromJson(e as Map<String, dynamic>)).toList(),
      media: (json['media'] as List?)?.map((e) => e.toString()).toList(),
      // locationMetadata: json['location_metadata'] != null
      //     ? LocationMetadata.fromJson(json['location_metadata'])
      //     : null,
      poll: json['poll'] != null ? Poll.fromJson(json['poll']) : null,
      isLiked: json['isLiked'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      isPostSavedLocal: json['isPostSavedLocal'],
      song: json['song'] != null ? Song.fromJson(json['song']) : null,
      visibilityDuration: json['visibility_duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      // 'location_metadata': locationMetadata?.toJson(),
      'poll': poll?.toJson(),
      'isLiked': isLiked,
      'user': user?.toJson(),
      'isPostSavedLocal': isPostSavedLocal,
      'song': song?.toJson(),
      'visibility_duration': visibilityDuration,
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? message,
    String? location,
    double? latitude,
    double? longitude,
    String? title,
    String? subTitle,
    String? type,
    String? natureOfPost,
    String? referenceLink,
    int? commentsCount,
    int? likesCount,
    int? repostCount,
    int? viewsCount,
    int? sharesCount,
    int? totalEngagement,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? quesOptions,
    List<User>? taggedUsers,
    List<String>? media,
    // LocationMetadata? locationMetadata,
    Poll? poll,
    bool? isLiked,
    User? user,
    bool? isPostSavedLocal,
    Song? song,
    int? visibilityDuration,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      message: message ?? this.message,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      type: type ?? this.type,
      natureOfPost: natureOfPost ?? this.natureOfPost,
      referenceLink: referenceLink ?? this.referenceLink,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      repostCount: repostCount ?? this.repostCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      totalEngagement: totalEngagement ?? this.totalEngagement,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quesOptions: quesOptions ?? this.quesOptions,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      media: media ?? this.media,
      // locationMetadata: locationMetadata ?? this.locationMetadata,
      poll: poll ?? this.poll,
      isLiked: isLiked ?? this.isLiked,
      user: user ?? this.user,
      isPostSavedLocal: isPostSavedLocal ?? this.isPostSavedLocal,
      song: song ?? this.song,
      visibilityDuration: visibilityDuration ?? this.visibilityDuration,
    );
  }
}

class User {
  final String? id;
  final String? username;
  final String? profileImage;
  final String? designation;
  final String? accountType;
  final String? name;
  final String? businessName;
  final String? business_id;
  final String? categoryOfBusiness;
  final String? subCategoryOfBusiness;
  final String? natureOfBusiness;

  User({
    this.id,
    this.username,
    this.profileImage,
    this.designation,
    this.accountType,
    this.name,
    this.businessName,
    this.business_id,
    this.categoryOfBusiness,
    this.subCategoryOfBusiness,
    this.natureOfBusiness
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profile_image'],
      designation: json['designation'],
      accountType: json['account_type'],
      name: json['name'],
      businessName: json['business_name'],
      business_id: json['business_id'],
      natureOfBusiness: json['natureOfBusiness'],
      categoryOfBusiness: json['categoryOfBusiness'],
      subCategoryOfBusiness: json['subCategoryOfBusiness']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'profile_image': profileImage,
      'designation': designation,
      'account_type': accountType,
      'name': name,
      'business_name': businessName,
      'business_id': business_id,
      'categoryOfBusiness': categoryOfBusiness,
      'subCategoryOfBusiness': subCategoryOfBusiness,
      'natureOfBusiness': natureOfBusiness,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? profileImage,
    String? designation,
    String? accountType,
    String? name,
    String? businessName,
    String? businessCategory,
    String? categoryOfBusiness,
    String? subCategoryOfBusiness,
    String? natureOfBusiness,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      designation: designation ?? this.designation,
      accountType: accountType ?? this.accountType,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      natureOfBusiness: natureOfBusiness ?? this.natureOfBusiness,
      categoryOfBusiness: categoryOfBusiness ?? this.categoryOfBusiness,
      subCategoryOfBusiness: subCategoryOfBusiness ?? this.subCategoryOfBusiness,
    );
  }
}

class Poll {
  final String? question;
  final List<PollOption> options;

  Poll({
    this.question,
    required this.options,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      question: json['question'],
      options: (json['options'] as List?)
              ?.map((e) => PollOption.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  Poll copyWith({
    String? question,
    List<PollOption>? options,
  }) {
    return Poll(
      question: question ?? this.question,
      options: options ?? this.options,
    );
  }
}

class PollOption {
  final String text;
  final bool isCorrect;
  List<String>? votes;

  PollOption({
    required this.text,
    required this.isCorrect,
    required this.votes,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      votes: (json['votes'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCorrect': isCorrect,
      'votes': votes,
    };
  }

  PollOption copyWith({
    String? text,
    bool? isCorrect,
    List<String>? votes,
  }) {
    return PollOption(
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      votes: votes ?? this.votes,
    );
  }
}

class CategoryDetails {
  final String id;
  final String name;

  CategoryDetails({
    required this.id,
    required this.name,
  });

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name
    };
  }

  CategoryDetails copyWith({
     String? id,
     String? name
  }) {
    return CategoryDetails(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

class SubCategoryDetails {
  final String id;
  final String name;

  SubCategoryDetails({
    required this.id,
    required this.name,
  });

  factory SubCategoryDetails.fromJson(Map<String, dynamic> json) {
    return SubCategoryDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name
    };
  }

  SubCategoryDetails copyWith({
    String? id,
    String? name
  }) {
    return SubCategoryDetails(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

// class LocationMetadata {
//   final double? lat;
//   final double? long;
//   final String? state;
//   final String? distance;
//   final String? name;
//
//   LocationMetadata({
//     this.lat,
//     this.long,
//     this.state,
//     this.distance,
//     this.name,
//   });
//
//   factory LocationMetadata.fromJson(Map<String, dynamic> json) {
//     return LocationMetadata(
//       lat: (json['lat'] as num?)?.toDouble(),
//       long: (json['long'] as num?)?.toDouble(),
//       state: json['state'],
//       distance: json['distance'],
//       name: json['name'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'lat': lat,
//       'long': long,
//       'state': state,
//       'distance': distance,
//       'name': name,
//     };
//   }
//
//   LocationMetadata copyWith({
//     double? lat,
//     double? long,
//     String? state,
//     String? distance,
//     String? name,
//   }) {
//     return LocationMetadata(
//       lat: lat ?? this.lat,
//       long: long ?? this.long,
//       state: state ?? this.state,
//       distance: distance ?? this.distance,
//       name: name ?? this.name,
//     );
//   }
// }

class Pagination {
  final int? page;
  final int? limit;
  final String? type;

  Pagination({
    this.page,
    this.limit,
    this.type,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'type': type,
    };
  }

  Pagination copyWith({
    int? page,
    int? limit,
    String? type,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      type: type ?? this.type,
    );
  }
}

class Song {
  final String id;
  final String name;
  final String artist;
  final String coverUrl;
  final String externalUrl;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.coverUrl,
    required this.externalUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      externalUrl: json['externalUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "artist": artist,
      "coverUrl": coverUrl,
      "externalUrl": externalUrl,
    };
  }
}


