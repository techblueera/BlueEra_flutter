class ProfessionalContactsResponse {
  final bool? success;
  final String? message;
  final Map<String, List<ProfessionalContact>>? data;

  ProfessionalContactsResponse({
    this.success,
    this.message,
    this.data,
  });

  factory ProfessionalContactsResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, List<ProfessionalContact>> parsedData = {};

    if (json['data'] != null) {
      if(json['data'] is Map){
        json['data'].forEach((key, value) {
          parsedData[key] = (value as List)
              .map((e) => ProfessionalContact.fromJson(e))
              .toList();
        });
      }
    }

    return ProfessionalContactsResponse(
      success: json['success'],
      message: json['message'],
      data: parsedData.isNotEmpty ? parsedData : null,
    );
  }
}

class ProfessionalContact {
  final User? user;
  final dynamic business;

  ProfessionalContact({
    this.user,
    this.business,
  });

  factory ProfessionalContact.fromJson(Map<String, dynamic> json) {
    return ProfessionalContact(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      business: json['business'],
    );
  }
}

class User {
  final String? id;
  final String? name;
  final String? gender;
  final String? contactNo;
  final String? profession;
  final String? designation;
  final String? profileImage;
  final String? username;
  final DateOfBirth? dateOfBirth;
  final String? accountType;
  final String? language;
  final String? email;
  final String? location;
  final String? highestEducation;
  final String? bio;
  final String? specialization;
  final String? sector;
  final UserLocation? userLocation;
  final bool? emailVerified;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic>? skills;
  final List<dynamic>? projects;
  final List<dynamic>? experiences;
  final SocialLinks? socialLinks;

  User({
    this.id,
    this.name,
    this.gender,
    this.contactNo,
    this.profession,
    this.designation,
    this.profileImage,
    this.username,
    this.dateOfBirth,
    this.accountType,
    this.language,
    this.email,
    this.location,
    this.highestEducation,
    this.bio,
    this.specialization,
    this.sector,
    this.userLocation,
    this.emailVerified,
    this.createdAt,
    this.updatedAt,
    this.skills,
    this.projects,
    this.experiences,
    this.socialLinks,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      contactNo: json['contact_no'],
      profession: json['profession'],
      designation: json['designation'],
      profileImage: json['profile_image'],
      username: json['username'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateOfBirth.fromJson(json['date_of_birth'])
          : null,
      accountType: json['account_type'],
      language: json['language'],
      email: json['email'],
      location: json['location'],
      highestEducation: json['highest_education'],
      bio: json['bio'],
      specialization: json['specialization'],
      sector: json['sector'],
      userLocation: json['user_location'] != null
          ? UserLocation.fromJson(json['user_location'])
          : null,
      emailVerified: json['email_verified'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      skills: json['skills'],
      projects: json['projects'],
      experiences: json['experiences'],
      socialLinks: json['social_links'] != null
          ? SocialLinks.fromJson(json['social_links'])
          : null,
    );
  }
}

class DateOfBirth {
  final int? date;
  final int? month;
  final int? year;

  DateOfBirth({
    this.date,
    this.month,
    this.year,
  });

  factory DateOfBirth.fromJson(Map<String, dynamic> json) {
    return DateOfBirth(
      date: json['date'],
      month: json['month'],
      year: json['year'],
    );
  }
}

class UserLocation {
  final double? lat;
  final double? lon;

  UserLocation({
    this.lat,
    this.lon,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
    );
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
}
