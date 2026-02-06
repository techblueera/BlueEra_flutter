import 'dart:convert';

PersonalProfileDetailsModel personalProfileDetailsModelFromJson(String str) =>
    PersonalProfileDetailsModel.fromJson(json.decode(str));

String personalProfileDetailsModelToJson(PersonalProfileDetailsModel data) =>
    json.encode(data.toJson());

class PersonalProfileDetailsModel {
  PersonalProfileDetailsModel({
    this.status,
    this.message,
    this.user,
    this.isProfileCreated,
    this.isRiderServiceUser,
    this.isEarnServiceUser,
  });

  PersonalProfileDetailsModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    isProfileCreated = json['isProfileCreated'];
    isRiderServiceUser = json['isRiderServiceUser'];
    isEarnServiceUser = json['isEarnServiceUser'];
  }

  bool? status;
  String? message;
  User? user;
  bool? isProfileCreated;
  bool? isRiderServiceUser;
  bool? isEarnServiceUser;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    map['isProfileCreated'] = isProfileCreated;
    map['isRiderServiceUser'] = isRiderServiceUser;
    map['isEarnServiceUser'] = isEarnServiceUser;
    return map;
  }
}

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  User({
    this.id,
    this.name,
    this.gender,
    this.contactNo,
    this.profession,
    this.designation,
    this.sector,
    this.profileImage,
    this.coverPicture,
    this.username,
    this.dateOfBirth,
    this.bio,
    this.email,
    this.highestEducation,
    this.specilization,
    this.subDivision,
    this.department,
    this.emailVerified,
    this.introVideo,
    this.objective,
    this.skills,
    this.art,
    this.userLocation,
    this.referral_points,
    this.referral_code,
    this.profileType,
    this.schoolOrCollegeName,
    this.pincode
  });

  User.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    sector = json['sector'];
    profileImage = json['profile_image'];
    coverPicture = json['coverPicture'];
    username = json['username'];
    dateOfBirth = json['date_of_birth'] != null
        ? DateOfBirth.fromJson(json['date_of_birth'])
        : null;

    bio = json['bio'];
    email = json['email'];
    highestEducation = json['highest_education'];
    specilization = json['specilization'];
    department = json['department'];
    subDivision = json['subDivision'];
    location = json['location'];
    emailVerified = json['emailVerified'];
    introVideo = json['introVideo'];
    referral_code = json['referral_code'];
    referral_points = json['referral_points'].toString();
    objective = json['objective'];
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    art = json['art'] != null ? new Art.fromJson(json['art']) : null;
    userLocation = json['user_location'] != null ? new UserLocation.fromJson(json['user_location']) : null;
    profileType = json['profileType'];
    schoolOrCollegeName = json['schoolOrCollegeName'];
    pincode = json['pincode'];
  }

  String? id;
  String? name;
  String? gender;
  String? contactNo;
  String? profession;
  String? designation;
  String? referral_points;
  String? referral_code;
  String? sector;
  String? profileImage;
  String? coverPicture;
  String? username;
  DateOfBirth? dateOfBirth;
  String? bio;
  String? objective;
  String? email;
  bool? emailVerified;
  String? highestEducation;
  String? specilization;
  String? department;
  String? subDivision;
  String? location;
  String? introVideo;
  List<String>? skills;
  Art? art;
  UserLocation? userLocation;
  String? profileType;
  String? schoolOrCollegeName;
  String? pincode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
    map['referral_code'] = referral_code;
    map['referral_points'] = referral_points;
    map['sector'] = sector;
    map['profile_image'] = profileImage;
    map['coverPicture'] = coverPicture;
    map['username'] = username;
    if (dateOfBirth != null) {
      map['date_of_birth'] = dateOfBirth?.toJson();
    }

    map['bio'] = bio;
    map['objective'] = objective;
    map['email'] = email;
    map['emailVerified'] = emailVerified;
    map['specilization'] = specilization;
    map['department'] = department;
    map['subDivision'] = subDivision;
    map['highest_education'] = highestEducation;
    map['location'] = location;
    map['introVideo'] = introVideo;
    map['skills'] = skills;
    if (this.art != null) {
      map['art'] = this.art!.toJson();
    }
    if (this.userLocation != null) {
      map['user_location'] = this.userLocation!.toJson();
    }
    map['profileType'] = profileType;
    map['schoolOrCollegeName'] = schoolOrCollegeName;
    map['pincode'] = pincode;
    return map;
  }
}

DateOfBirth dateOfBirthFromJson(String str) =>
    DateOfBirth.fromJson(json.decode(str));

String dateOfBirthToJson(DateOfBirth data) => json.encode(data.toJson());

class DateOfBirth {
  DateOfBirth({
    this.date,
    this.month,
    this.year,
  });

  DateOfBirth.fromJson(dynamic json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }

  int? date;
  int? month;
  int? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }
}

UserLocation userLocationFromJson(String str) =>
    UserLocation.fromJson(json.decode(str));

String userLocationToJson(UserLocation data) =>
    json.encode(data.toJson());

class UserLocation {
  final double? lat;
  final double? lon;

  const UserLocation({
    this.lat,
    this.lon,
  });

  factory UserLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserLocation();

    return UserLocation(
      lat: _parseDouble(json['lat']),
      lon: _parseDouble(json['lon']),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
  };

  // Safely parse dynamic → double?
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}


// class Projects {
//   String? title;
//   String? description;
//   String? sId;
//
//   Projects({this.title, this.description, this.sId});
//
//   Projects.fromJson(Map<String, dynamic> json) {
//     title = json['title'];
//     description = json['description'];
//     sId = json['_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['title'] = this.title;
//     data['description'] = this.description;
//     data['_id'] = this.sId;
//     return data;
//   }
// }
//
// class Experiences {
//   String? companyName;
//   String? rolesAndResponsibility;
//   String? sId;
//
//   Experiences({this.companyName, this.rolesAndResponsibility, this.sId});
//
//   Experiences.fromJson(Map<String, dynamic> json) {
//     companyName = json['companyName'];
//     rolesAndResponsibility = json['rolesAndResponsibility'];
//     sId = json['_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['companyName'] = this.companyName;
//     data['rolesAndResponsibility'] = this.rolesAndResponsibility;
//     data['_id'] = this.sId;
//     return data;
//   }
// }

class Art {
  String? artName;
  String? artType;

  Art({this.artName, this.artType});

  Art.fromJson(Map<String, dynamic> json) {
    artName = json['artName'];
    artType = json['artType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['artName'] = this.artName;
    data['artType'] = this.artType;
    return data;
  }
}
