/// success : true
/// chatList : [{"conversation_id":"687baa79fabe9b852eb68f7b","is_group":false,"last_message":"it's backend issue ","last_message_type":"text","created_at":"2025-07-19T14:23:53.538Z","updated_at":"2025-07-19T14:25:07.896Z","unread_count":5,"public_group":false,"sender":{"_id":"687baa0ca598e3558edda1d7","name":"good person","gender":"Male","contact_no":"9363029058","profession":"GOVERNMENT_JOB","designation":"asxasasx","profile_image":"https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/temp/profile/1752934924281_cropped_image_01752934892306.png","username":"usermdac70amcd3bf","date_of_birth":{"date":8,"month":4,"year":2018},"deleted_at":null,"account_type":"INDIVIDUAL","language":"ENG","referral_points":0,"last_seen":null,"highest_education":null,"role":null,"current_organisation":null,"bio":null,"introVideo":null,"social_links":{"youtube":null,"twitter":null,"linkedin":null,"instagram":null,"website":null},"created_at":"2025-07-19T14:22:04.609Z","updated_at":"2025-07-19T14:22:04.609Z","__v":0}}]
/// archived : []

class GetChatListModel {
  GetChatListModel({
      this.success, 
      this.type,
      this.chatList,
      this.archived,});

  GetChatListModel.fromJson(dynamic json) {
    success = json['success'];
    type = json['type'];
    if (json['chatList'] != null) {
      chatList = [];
      json['chatList'].forEach((v) {
        chatList?.add(ChatList.fromJson(v));
      });
    }
    if (json['archived'] != null) {
      archived = [];
      json['archived'].forEach((v) {
        archived?.add(v);
      });
    }
  }
  bool? success;
  String? type;
  List<ChatList?>? chatList;
  List<dynamic>? archived;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['type'] = type;
    if (chatList != null) {
      map['chatList'] = chatList?.map((v) => v?.toJson()).toList();
    }
    if (archived != null) {
      map['archived'] = archived?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// conversation_id : "687baa79fabe9b852eb68f7b"
/// is_group : false
/// last_message : "it's backend issue "
/// last_message_type : "text"
/// created_at : "2025-07-19T14:23:53.538Z"
/// updated_at : "2025-07-19T14:25:07.896Z"
/// unread_count : 5
/// public_group : false
/// sender : {"_id":"687baa0ca598e3558edda1d7","name":"good person","gender":"Male","contact_no":"9363029058","profession":"GOVERNMENT_JOB","designation":"asxasasx","profile_image":"https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/temp/profile/1752934924281_cropped_image_01752934892306.png","username":"usermdac70amcd3bf","date_of_birth":{"date":8,"month":4,"year":2018},"deleted_at":null,"account_type":"INDIVIDUAL","language":"ENG","referral_points":0,"last_seen":null,"highest_education":null,"role":null,"current_organisation":null,"bio":null,"introVideo":null,"social_links":{"youtube":null,"twitter":null,"linkedin":null,"instagram":null,"website":null},"created_at":"2025-07-19T14:22:04.609Z","updated_at":"2025-07-19T14:22:04.609Z","__v":0}

class ChatList {
  ChatList({
      this.conversationId, 
      this.isGroup, 
      this.lastMessage, 
      this.lastMessageType, 
      this.createdAt, 
      this.updatedAt, 
      this.unreadCount, 
      this.publicGroup, 
      this.sender,});

  ChatList.fromJson(dynamic json) {
    conversationId = json['conversation_id'];
    isGroup = json['is_group'];
    lastMessage = json['last_message'];
    lastMessageType = json['last_message_type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    unreadCount = json['unread_count'];
    publicGroup = json['public_group'];
    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;
  }
  String? conversationId;
  bool? isGroup;
  String? lastMessage;
  String? lastMessageType;
  String? createdAt;
  String? updatedAt;
  num? unreadCount;
  bool? publicGroup;
  Sender? sender;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['conversation_id'] = conversationId;
    map['is_group'] = isGroup;
    map['last_message'] = lastMessage;
    map['last_message_type'] = lastMessageType;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['unread_count'] = unreadCount;
    map['public_group'] = publicGroup;
    if (sender != null) {
      map['sender'] = sender?.toJson();
    }
    return map;
  }
  bool inSearchEvents(String searchQuery){
    String lowerCaseQuery=searchQuery.toLowerCase();
    print("sdkcmlksdmc ${(sender?.name?.toLowerCase().contains(lowerCaseQuery)??false)||(sender?.contactNo?.toLowerCase().contains(lowerCaseQuery)??false)} ");
    return ((sender?.name?.toLowerCase().contains(lowerCaseQuery)??false)||(sender?.contactNo?.toLowerCase().contains(lowerCaseQuery)??false));
  }

}

/// _id : "687baa0ca598e3558edda1d7"
/// name : "good person"
/// gender : "Male"
/// contact_no : "9363029058"
/// profession : "GOVERNMENT_JOB"
/// designation : "asxasasx"
/// profile_image : "https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/temp/profile/1752934924281_cropped_image_01752934892306.png"
/// username : "usermdac70amcd3bf"
/// date_of_birth : {"date":8,"month":4,"year":2018}
/// deleted_at : null
/// account_type : "INDIVIDUAL"
/// language : "ENG"
/// referral_points : 0
/// last_seen : null
/// highest_education : null
/// role : null
/// current_organisation : null
/// bio : null
/// introVideo : null
/// social_links : {"youtube":null,"twitter":null,"linkedin":null,"instagram":null,"website":null}
/// created_at : "2025-07-19T14:22:04.609Z"
/// updated_at : "2025-07-19T14:22:04.609Z"
/// __v : 0

class Sender {
  Sender({
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
      this.highestEducation, 
      this.role, 
      this.currentOrganisation, 
      this.bio, 
      this.introVideo, 
      this.socialLinks, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Sender.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no']==null?json['contact']:json['contact_no'];
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
    highestEducation = json['highest_education'];
    role = json['role'];
    currentOrganisation = json['current_organisation'];
    bio = json['bio'];
    introVideo = json['introVideo'];
    socialLinks = json['social_links'] != null ? SocialLinks.fromJson(json['social_links']) : null;
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
  dynamic highestEducation;
  dynamic role;
  dynamic currentOrganisation;
  dynamic bio;
  dynamic introVideo;
  SocialLinks? socialLinks;
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
    map['highest_education'] = highestEducation;
    map['role'] = role;
    map['current_organisation'] = currentOrganisation;
    map['bio'] = bio;
    map['introVideo'] = introVideo;
    if (socialLinks != null) {
      map['social_links'] = socialLinks?.toJson();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

/// youtube : null
/// twitter : null
/// linkedin : null
/// instagram : null
/// website : null

class SocialLinks {
  SocialLinks({
      this.youtube, 
      this.twitter, 
      this.linkedin, 
      this.instagram, 
      this.website,});

  SocialLinks.fromJson(dynamic json) {
    youtube = json['youtube'];
    twitter = json['twitter'];
    linkedin = json['linkedin'];
    instagram = json['instagram'];
    website = json['website'];
  }
  dynamic youtube;
  dynamic twitter;
  dynamic linkedin;
  dynamic instagram;
  dynamic website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['youtube'] = youtube;
    map['twitter'] = twitter;
    map['linkedin'] = linkedin;
    map['instagram'] = instagram;
    map['website'] = website;
    return map;
  }

}

/// date : 8
/// month : 4
/// year : 2018

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