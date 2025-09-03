class GroupMembersListModel {
  final String id;
  final String? gender;
  final String? contactNo;
  final String? profession;
  final String? designation;
  final String? sector;
  final bool? isEnded;
  final String? name ;
  final String? username;
  final DateOfBirth? dateOfBirth;
  final String? accountType;
  final String? language;
  final int? referralPoints;
  final String? referralCode;
  final String? lastSeen;
  final UserLocation? userLocation;
  final SocialLinks? socialLinks;
  final bool? emailVerified;
  final String? createdAt;
  final String? updatedAt;

  GroupMembersListModel({
    required this.id,
    required this.name,
    this.gender,
    this.contactNo,
    this.profession,
    this.designation,
    this.sector,
    this.isEnded,
    this.username,
    this.dateOfBirth,
    this.accountType,
    this.language,
    this.referralPoints,
    this.referralCode,
    this.lastSeen,
    this.userLocation,
    this.socialLinks,
    this.emailVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupMembersListModel.fromJson(Map<String, dynamic> json) {
    return GroupMembersListModel(
      id: json['_id'] ?? json['id'],
name: json['name']??json['name'],
      gender: json['gender'],
      contactNo: json['contact_no'],
      profession: json['profession'],
      designation: json['designation'],
      sector: json['sector'],
      isEnded: json['is_ended'],
      username: json['username'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateOfBirth.fromJson(json['date_of_birth'])
          : null,
      accountType: json['account_type'],
      language: json['language'],
      referralPoints: json['referral_points'],
      referralCode: json['referral_code'],
      lastSeen: json['last_seen'],
      userLocation: json['user_location'] != null
          ? UserLocation.fromJson(json['user_location'])
          : null,
      socialLinks: json['social_links'] != null
          ? SocialLinks.fromJson(json['social_links'])
          : null,
      emailVerified: json['emailVerified'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name':name,
      'gender': gender,
      'contact_no': contactNo,
      'profession': profession,
      'designation': designation,
      'sector': sector,
      'is_ended': isEnded,
      'username': username,
      'date_of_birth': dateOfBirth?.toJson(),
      'account_type': accountType,
      'language': language,
      'referral_points': referralPoints,
      'referral_code': referralCode,
      'last_seen': lastSeen,
      'user_location': userLocation?.toJson(),
      'social_links': socialLinks?.toJson(),
      'emailVerified': emailVerified,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class DateOfBirth {
  final int? date;
  final int? month;
  final int? year;

  DateOfBirth({this.date, this.month, this.year});

  factory DateOfBirth.fromJson(Map<String, dynamic> json) {
    return DateOfBirth(
      date: json['date'],
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'month': month,
      'year': year,
    };
  }
}

class UserLocation {
  final double? lat;
  final double? lon;

  UserLocation({this.lat, this.lon});

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }
}

class SocialLinks {
  final String? youtube;
  final String? twitter;
  final String? linkedin;
  final String? instagram;
  final String? website;

  SocialLinks({
    this.youtube,
    this.twitter,
    this.linkedin,
    this.instagram,
    this.website,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      youtube: json['youtube'],
      twitter: json['twitter'],
      linkedin: json['linkedin'],
      instagram: json['instagram'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youtube': youtube,
      'twitter': twitter,
      'linkedin': linkedin,
      'instagram': instagram,
      'website': website,
    };
  }
}
