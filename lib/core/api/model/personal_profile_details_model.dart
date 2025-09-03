import 'dart:convert';
PersonalProfileDetailsModel personalProfileDetailsModelFromJson(String str) => PersonalProfileDetailsModel.fromJson(json.decode(str));
String personalProfileDetailsModelToJson(PersonalProfileDetailsModel data) => json.encode(data.toJson());
class PersonalProfileDetailsModel {
  PersonalProfileDetailsModel({
      this.status, 
      this.message, 
      this.user, 
      this.totalPosts,
      this.followingCount,
      this.followersCount,
      this.isProfileCreated,});

  PersonalProfileDetailsModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    followersCount = json['followersCount'];
    followingCount = json['followingCount'];
    totalPosts = json['totalPosts'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    isProfileCreated = json['isProfileCreated'];
  }
  bool? status;
  String? message;
  dynamic followersCount;
  dynamic followingCount;
  dynamic totalPosts;
  User? user;
  bool? isProfileCreated;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    map['followersCount'] = followersCount;
    map['followingCount'] = followingCount;
    map['totalPosts'] = totalPosts;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    map['isProfileCreated'] = isProfileCreated;
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
      this.username, 
      this.dateOfBirth, 
      this.deletedAt, 
      this.accountType, 
      this.language, 
      this.referralPoints, 
      this.lastSeen, 
      this.role, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.bio, 
      this.currentOrganisation, 
      this.email, 
      this.highestEducation, 
      this.specilization,
      this.subDivision,
      this.department,
      this.emailVerified,
      this.introVideo,
      this.objective,
      this.skills,
    this.projects,
    this.art,
    this.experiences,
      this.location,});

  User.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    sector = json['sector'];
    profileImage = json['profile_image'];
    username = json['username'];
    dateOfBirth = json['date_of_birth'] != null ? DateOfBirth.fromJson(json['date_of_birth']) : null;
    deletedAt = json['deleted_at'];
    accountType = json['account_type'];
    language = json['language'];
    referralPoints = json['referral_points'];
    lastSeen = json['last_seen'];
    role = json['role'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
    bio = json['bio'];
    currentOrganisation = json['current_organisation'];
    email = json['email'];
    highestEducation = json['highest_education'];
    specilization = json['specilization'];
    department = json['department'];
    subDivision = json['subDivision'];
    location = json['location'];
    emailVerified = json['emailVerified'];
    introVideo = json['introVideo'];
    objective = json['objective'];
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    if (json['projects'] != null) {
      projects = <Projects>[];
      json['projects'].forEach((v) {
        projects!.add(new Projects.fromJson(v));
      });
    }
    if (json['experiences'] != null) {
      experiences = <Experiences>[];
      json['experiences'].forEach((v) {
        experiences!.add(new Experiences.fromJson(v));
      });
    }
    art = json['art'] != null ? new Art.fromJson(json['art']) : null;

  }
  String? id;
  String? name;
  String? gender;
  String? contactNo;
  String? profession;
  String? designation;
  String? sector;
  String? profileImage;
  String? username;
  DateOfBirth? dateOfBirth;
  dynamic deletedAt;
  String? accountType;
  String? language;
  int? referralPoints;
  dynamic lastSeen;
  dynamic role;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? bio;
  String? objective;
  String? currentOrganisation;
  String? email;
  bool? emailVerified;
  String? highestEducation;
  String? specilization;
  String? department;
  String? subDivision;
  String? location;
  String? introVideo;
  List<String>? skills;
  List<Projects>? projects;
  List<Experiences>? experiences;
  Art? art;




  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
    map['sector'] = sector;
    map['profile_image'] = profileImage;
    map['username'] = username;
    if (dateOfBirth != null) {
      map['date_of_birth'] = dateOfBirth?.toJson();
    }
    map['deleted_at'] = deletedAt;
    map['account_type'] = accountType;
    map['language'] = language;
    map['referral_points'] = referralPoints;
    map['last_seen'] = lastSeen;
    map['role'] = role;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    map['bio'] = bio;
    map['objective'] = objective;
    map['current_organisation'] = currentOrganisation;
    map['email'] = email;
    map['emailVerified'] = emailVerified;
    map['specilization'] = specilization;
    map['department'] = department;
    map['subDivision'] = subDivision;
    map['highest_education'] = highestEducation;
    map['location'] = location;
    map['introVideo'] = introVideo;
    map['skills'] = skills;
    if (this.projects != null) {
      map['projects'] = this.projects!.map((v) => v.toJson()).toList();
    }
    if (this.experiences != null) {
      map['experiences'] = this.experiences!.map((v) => v.toJson()).toList();
    }
    if (this.art != null) {
      map['art'] = this.art!.toJson();
    }
    return map;
  }

}

DateOfBirth dateOfBirthFromJson(String str) => DateOfBirth.fromJson(json.decode(str));
String dateOfBirthToJson(DateOfBirth data) => json.encode(data.toJson());
class DateOfBirth {
  DateOfBirth({
      this.date, 
      this.month, 
      this.year,});

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


class Projects {
  String? title;
  String? description;
  String? sId;

  Projects({this.title, this.description, this.sId});

  Projects.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    description = json['description'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['description'] = this.description;
    data['_id'] = this.sId;
    return data;
  }
}

class Experiences {
  String? companyName;
  String? rolesAndResponsibility;
  String? sId;

  Experiences({this.companyName, this.rolesAndResponsibility, this.sId});

  Experiences.fromJson(Map<String, dynamic> json) {
    companyName = json['companyName'];
    rolesAndResponsibility = json['rolesAndResponsibility'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['companyName'] = this.companyName;
    data['rolesAndResponsibility'] = this.rolesAndResponsibility;
    data['_id'] = this.sId;
    return data;
  }
}

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