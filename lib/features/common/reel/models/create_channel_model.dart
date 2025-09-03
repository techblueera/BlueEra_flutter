class CreateChannelModel {
  final bool success;
  final String message;
  final ChannelData data;

  CreateChannelModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CreateChannelModel.fromJson(Map<String, dynamic> json) {
    return CreateChannelModel(
      success: json['success'],
      message: json['message'],
      data: ChannelData.fromJson(json['data']),
    );
  }
}

class ChannelData {
  final String name;
  final String username;
  final String bio;
  final String logoUrl;
  final List<String> socialLinks;
  final List<String> websites;
  final Verification verification;
  final List<String> blockedUsers;
  final List<String> mutedUsers;
  final List<String> reports;
  final Ownership ownership;
  final List<String> followers;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  ChannelData({
    required this.name,
    required this.username,
    required this.bio,
    required this.logoUrl,
    required this.socialLinks,
    required this.websites,
    required this.verification,
    required this.blockedUsers,
    required this.mutedUsers,
    required this.reports,
    required this.ownership,
    required this.followers,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory ChannelData.fromJson(Map<String, dynamic> json) {
    return ChannelData(
      name: json['name'],
      username: json['username'],
      bio: json['bio'],
      logoUrl: json['logoUrl'],
      socialLinks: List<String>.from(json['socialLinks']),
      websites: List<String>.from(json['websites']),
      verification: Verification.fromJson(json['verification']),
      blockedUsers: List<String>.from(json['blockedUsers']),
      mutedUsers: List<String>.from(json['mutedUsers']),
      reports: List<String>.from(json['reports']),
      ownership: Ownership.fromJson(json['ownership']),
      followers: List<String>.from(json['followers']),
      id: json['_id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }
}

class Verification {
  final bool isVerified;

  Verification({required this.isVerified});

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(isVerified: json['isVerified']);
  }
}

class Ownership {
  final String claimedBy;
  final String claimedAt;

  Ownership({
    required this.claimedBy,
    required this.claimedAt,
  });

  factory Ownership.fromJson(Map<String, dynamic> json) {
    return Ownership(
      claimedBy: json['claimedBy'],
      claimedAt: json['claimedAt'],
    );
  }
}
