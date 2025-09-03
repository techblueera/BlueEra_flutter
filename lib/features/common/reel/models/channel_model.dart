class ChannelModel {
  final bool success;
  final String message;
  final ChannelData data;

  ChannelModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ChannelData.fromJson(json['data']),
    );
  }
}

class ChannelData {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String logoUrl;
  final Verification verification;
  final Ownership ownership;
  final List<SocialLink> socialLinks;
  final List<String> websites;
  final List<String> blockedUsers;
  final List<String> mutedUsers;
  final List<String> reports;
  final List<String> followers;
  final bool isFollowing;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChannelData({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.logoUrl,
    required this.verification,
    required this.ownership,
    required this.socialLinks,
    required this.websites,
    required this.blockedUsers,
    required this.mutedUsers,
    required this.reports,
    required this.followers,
    required this.isFollowing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelData.fromJson(Map<String, dynamic> json) {
    return ChannelData(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      verification: Verification.fromJson(json['verification']),
      ownership: Ownership.fromJson(json['ownership']),
      socialLinks: (json['socialLinks'] as List<dynamic>)
          .map((e) => SocialLink.fromJson(e))
          .toList(),
      websites: List<String>.from(json['websites'] ?? []),
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      mutedUsers: List<String>.from(json['mutedUsers'] ?? []),
      reports: List<String>.from(json['reports'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
      isFollowing: json['isFollowing'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Verification {
  final bool isVerified;

  Verification({required this.isVerified});

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(isVerified: json['isVerified'] ?? false);
  }
}

class Ownership {
  final String claimedBy;
  final DateTime claimedAt;

  Ownership({required this.claimedBy, required this.claimedAt});

  factory Ownership.fromJson(Map<String, dynamic> json) {
    return Ownership(
      claimedBy: json['claimedBy'] ?? '',
      claimedAt: DateTime.parse(json['claimedAt']),
    );
  }
}

class SocialLink {
  final String id;
  final String platform;
  final String url;

  SocialLink({required this.id, required this.platform, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: json['_id'] ?? '',
      platform: json['platform'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
