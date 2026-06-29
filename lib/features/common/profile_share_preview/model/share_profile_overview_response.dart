/// Backs the public share-card overview returned by
/// `GET user-service/share/users/{userId}/profile-overview`.
///
/// Trimmed compared to the full user object — only the fields the share
/// landing screen renders. The endpoint does **not** wrap the body under a
/// `data` envelope, so callers parse from the raw response body, not
/// `ResponseModel.data`.
class ShareProfileOverviewResponse {
  final bool success;
  final ShareUser? user;
  final bool isFollowing;
  final int totalPosts;
  final int followersCount;
  final int followingCount;

  ShareProfileOverviewResponse({
    required this.success,
    this.user,
    this.isFollowing = false,
    this.totalPosts = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory ShareProfileOverviewResponse.fromJson(Map<String, dynamic> json) {
    return ShareProfileOverviewResponse(
      success: json['success'] == true,
      user: json['user'] is Map<String, dynamic>
          ? ShareUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      isFollowing: json['isFollowing'] == true,
      totalPosts: _asInt(json['totalPosts']),
      followersCount: _asInt(json['followersCount']),
      followingCount: _asInt(json['followingCount']),
    );
  }
}

class ShareUser {
  final String? id;
  final String? name;
  final String? username;
  final String? accountType;

  /// Business sub-category for `accountType == BUSINESS` (e.g. "grocery",
  /// "food", "medical", "Hostels & Stay Service"). Drives which Discover
  /// detail screen the "Open Profile in App" CTA opens. Backend should
  /// populate `business_category` on the share-overview response.
  final String? businessCategory;

  /// Profession type for `accountType == INDIVIDUAL` (e.g. "Skilled Work",
  /// "Consultant"). Drives which Discover detail screen the "Open Profile
  /// in App" CTA opens. Backend should populate `profession_type` on the
  /// share-overview response.
  final String? professionType;
  final String? profileImage;
  final String? bio;
  final String? objective;
  final String? language;
  final String? referralCode;
  final ShareSocialLinks socialLinks;
  final List<String> skills;
  final List<String> projects;
  final List<String> experiences;
  final double avgRating;
  final int totalRatings;

  ShareUser({
    this.id,
    this.name,
    this.username,
    this.accountType,
    this.businessCategory,
    this.professionType,
    this.profileImage,
    this.bio,
    this.objective,
    this.language,
    this.referralCode,
    ShareSocialLinks? socialLinks,
    this.skills = const [],
    this.projects = const [],
    this.experiences = const [],
    this.avgRating = 0.0,
    this.totalRatings = 0,
  }) : socialLinks = socialLinks ?? ShareSocialLinks();

  factory ShareUser.fromJson(Map<String, dynamic> json) {
    return ShareUser(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      accountType: json['account_type']?.toString(),
      businessCategory: json['business_category']?.toString(),
      professionType: json['profession_type']?.toString(),
      profileImage: json['profile_image']?.toString(),
      bio: json['bio']?.toString(),
      objective: json['objective']?.toString(),
      language: json['language']?.toString(),
      referralCode: json['referral_code']?.toString(),
      socialLinks: json['social_links'] is Map<String, dynamic>
          ? ShareSocialLinks.fromJson(
              json['social_links'] as Map<String, dynamic>)
          : ShareSocialLinks(),
      skills: _asStringList(json['skills']),
      projects: _asStringList(json['projects']),
      experiences: _asStringList(json['experiences']),
      avgRating: _asDouble(json['avg_rating']),
      totalRatings: _asInt(json['total_ratings']),
    );
  }
}

class ShareSocialLinks {
  final String? youtube;
  final String? twitter;
  final String? linkedin;
  final String? instagram;
  final String? website;

  ShareSocialLinks({
    this.youtube,
    this.twitter,
    this.linkedin,
    this.instagram,
    this.website,
  });

  factory ShareSocialLinks.fromJson(Map<String, dynamic> json) {
    return ShareSocialLinks(
      youtube: json['youtube']?.toString(),
      twitter: json['twitter']?.toString(),
      linkedin: json['linkedin']?.toString(),
      instagram: json['instagram']?.toString(),
      website: json['website']?.toString(),
    );
  }

  bool get hasAny =>
      _nonEmpty(youtube) ||
      _nonEmpty(twitter) ||
      _nonEmpty(linkedin) ||
      _nonEmpty(instagram) ||
      _nonEmpty(website);
}

bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }
  return const [];
}
