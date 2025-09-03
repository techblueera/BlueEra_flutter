/// success : true
/// message : "Request found"
/// data : [{"_id":"687a20a099c3e4d4ba1c6dcc","request_to":"68763f506fada6abbb59f762","request_by":"6879f36ab852f9d5e9f30733","status":"pending","created_at":"2025-07-18T08:14:53.200Z","updated_at":"2025-07-18T08:14:53.200Z","__v":0,"user":{"_id":"6879f36ab852f9d5e9f30733","name":"Ansh","gender":"Male","contact_no":"8287339523","profession":"GOVERNMENT_JOB","designation":"Manager","profile_image":"https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/temp/profile/1752822633737_cropped_image_01752822595030.png","username":"usermd8hc8f2pf9r5","date_of_birth":{"date":6,"month":4,"year":1997},"deleted_at":null,"account_type":"INDIVIDUAL","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-18T07:10:34.143Z","updated_at":"2025-07-18T07:10:34.143Z","__v":0}}]

class GetChatRequestProfileDetailsModel {
  GetChatRequestProfileDetailsModel({
      this.success, 
      this.message, 
      this.data,});

  GetChatRequestProfileDetailsModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
  }
  bool? success;
  String? message;
  List<Data>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// _id : "687a20a099c3e4d4ba1c6dcc"
/// request_to : "68763f506fada6abbb59f762"
/// request_by : "6879f36ab852f9d5e9f30733"
/// status : "pending"
/// created_at : "2025-07-18T08:14:53.200Z"
/// updated_at : "2025-07-18T08:14:53.200Z"
/// __v : 0
/// user : {"_id":"6879f36ab852f9d5e9f30733","name":"Ansh","gender":"Male","contact_no":"8287339523","profession":"GOVERNMENT_JOB","designation":"Manager","profile_image":"https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/temp/profile/1752822633737_cropped_image_01752822595030.png","username":"usermd8hc8f2pf9r5","date_of_birth":{"date":6,"month":4,"year":1997},"deleted_at":null,"account_type":"INDIVIDUAL","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-18T07:10:34.143Z","updated_at":"2025-07-18T07:10:34.143Z","__v":0}

class Data {
  Data({
      this.id, 
      this.requestTo, 
      this.requestBy, 
      this.status, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.user,});

  Data.fromJson(dynamic json) {
    id = json['_id'];
    requestTo = json['request_to'];
    requestBy = json['request_by'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  String? id;
  String? requestTo;
  String? requestBy;
  String? status;
  String? createdAt;
  String? updatedAt;
  num? v;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['request_to'] = requestTo;
    map['request_by'] = requestBy;
    map['status'] = status;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }

}

/// _id : "6879f36ab852f9d5e9f30733"
/// name : "Ansh"
/// gender : "Male"
/// contact_no : "8287339523"
/// profession : "GOVERNMENT_JOB"
/// designation : "Manager"
/// profile_image : "https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/temp/profile/1752822633737_cropped_image_01752822595030.png"
/// username : "usermd8hc8f2pf9r5"
/// date_of_birth : {"date":6,"month":4,"year":1997}
/// deleted_at : null
/// account_type : "INDIVIDUAL"
/// language : "ENG"
/// referral_points : 0
/// last_seen : null
/// role : null
/// created_at : "2025-07-18T07:10:34.143Z"
/// updated_at : "2025-07-18T07:10:34.143Z"
/// __v : 0

class User {
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
      this.deletedAt, 
      this.accountType, 
      this.language, 
      this.referralPoints, 
      this.lastSeen, 
      this.role, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  User.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
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
  }
  String? id;
  String? name;
  String? gender;
  String? contactNo;
  String? profession;
  String? designation;
  String? profileImage;
  String? username;
  DateOfBirth? dateOfBirth;
  dynamic deletedAt;
  String? accountType;
  String? language;
  num? referralPoints;
  dynamic lastSeen;
  dynamic role;
  String? createdAt;
  String? updatedAt;
  num? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
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
    return map;
  }

}

/// date : 6
/// month : 4
/// year : 1997

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
  num? date;
  num? month;
  num? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }

}