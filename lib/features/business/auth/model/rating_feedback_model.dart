class FeedbackResponse {
  final bool success;
  final List<FeedbackData> data;

  FeedbackResponse({
    required this.success,
    required this.data,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      success: json['success'] as bool,
      data: (json['data'] as List)
          .map((item) => FeedbackData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeedbackData {
  final String id;
  final String business;
  final FeedbackUser user;
  final int v;
  final String comment;
  final DateTime createdAt;
  final int rating;
  final String formattedCreatedAt;

  FeedbackData({
    required this.id,
    required this.business,
    required this.user,
    required this.v,
    required this.comment,
    required this.createdAt,
    required this.rating,
    required this.formattedCreatedAt,
  });

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      id: json['_id'] as String,
      business: json['business'] as String,
      user: FeedbackUser.fromJson(json['user'] as Map<String, dynamic>),
      v: json['__v'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      rating: json['rating'] as int,
      formattedCreatedAt: json['formatted_created_at'] as String,
    );
  }
}

class FeedbackUser {
  final String id;
  final String username;
  final String accountType;
  final List<UserBusiness> userBusiness;

  FeedbackUser({
    required this.id,
    required this.username,
    required this.accountType,
    required this.userBusiness,
  });

  factory FeedbackUser.fromJson(Map<String, dynamic> json) {
    return FeedbackUser(
      id: json['_id'] as String,
      username: json['username'] as String,
      accountType: json['account_type'] as String,
      userBusiness: (json['user_business'] as List)
          .map((item) => UserBusiness.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserBusiness {
  final String id;
  final String businessName;
  final String logo;
  final bool isActive;
  final bool businessIsVerified;

  UserBusiness({
    required this.id,
    required this.businessName,
    required this.logo,
    required this.isActive,
    required this.businessIsVerified,
  });

  factory UserBusiness.fromJson(Map<String, dynamic> json) {
    return UserBusiness(
      id: json['_id'] as String,
      businessName: json['business_name'] as String,
      logo: json['logo'] as String,
      isActive: json['isActive'] as bool,
      businessIsVerified: json['business_isVerified'] as bool,
    );
  }
}