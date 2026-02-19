
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
    this.groupName,
    this.groupProfileImage,
    this.lastMessageType,
    this.createdAt,
    this.tagged,
    this.updatedAt,
    this.unreadCount,
    this.publicGroup,
    this.sender,
    this.symbolData,
  });

  ChatList.fromJson(dynamic json) {
    conversationId = json['conversation_id'];
    isGroup = json['is_group'];
    lastMessage = json['last_message'];
    groupName = json['group_name']?.toString();
    groupProfileImage = json['group_profile_image']?.toString();
    lastMessageType = json['last_message_type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    unreadCount = json['unread_count'];
    tagged = json['tagged'];
    publicGroup = json['public_group'];

    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;

    /// NEW: symbolData parsing
    if (json['symbolData'] != null) {
      symbolData = (json['symbolData'] as List)
          .map((e) => SymbolDataModel.fromJson(e))
          .toList();
    }
  }

  String? conversationId;
  bool? isGroup;
  String? lastMessage;
  String? lastMessageType;
  String? createdAt;
  String? updatedAt;
  String? groupName;
  String? groupProfileImage;
  num? unreadCount;
  bool? publicGroup;
  bool? tagged;
  Sender? sender;

  /// NEW FIELD
  List<SymbolDataModel>? symbolData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['conversation_id'] = conversationId;
    map['is_group'] = isGroup;
    map['last_message'] = lastMessage;
    map['last_message_type'] = lastMessageType;
    map['created_at'] = createdAt;
    map['group_name'] = groupName;
    map['group_profile_image'] = groupProfileImage;
    map['updated_at'] = updatedAt;
    map['unread_count'] = unreadCount;
    map['tagged'] = tagged;
    map['public_group'] = publicGroup;

    if (sender != null) {
      map['sender'] = sender?.toJson();
    }

    /// NEW
    if (symbolData != null) {
      map['symbolData'] = symbolData!.map((e) => e.toJson()).toList();
    }

    return map;
  }

  bool inSearchEvents(String searchQuery) {
    String lowerCaseQuery = searchQuery.toLowerCase();

    return ((sender?.name?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
        (sender?.contactNo?.toLowerCase().contains(lowerCaseQuery) ?? false));
  }
}

class SymbolDataModel {
  List<String>? taggedUsers;
  List<String>? media;
  List<String>? mediaTypes;
  String? id;
  String? type;
  int? visibilityDuration;
  String? song;
  String? message;
  String? title;
  String? subTitle;
  String? natureOfPost;
  String? location;
  double? latitude;
  double? longitude;
  dynamic locationMetadata;
  String? mediaAspectRatio;
  String? postVia;
  String? referenceLink;
  String? authorId;
  String? createdBy;
  String? updatedBy;
  dynamic poll;
  int? commentsCount;
  int? likesCount;
  int? repostCount;
  int? viewsCount;
  int? sharesCount;
  String? createdAt;
  String? updatedAt;
  bool? isReposted;
  dynamic childrenPost;
  String? thumbnail;
  int? duration;
  int? mediaHeight;
  int? mediaWidth;

  SymbolDataModel({
    this.taggedUsers,
    this.media,
    this.mediaTypes,
    this.id,
    this.type,
    this.visibilityDuration,
    this.song,
    this.message,
    this.title,
    this.subTitle,
    this.natureOfPost,
    this.location,
    this.latitude,
    this.longitude,
    this.locationMetadata,
    this.mediaAspectRatio,
    this.postVia,
    this.referenceLink,
    this.authorId,
    this.createdBy,
    this.updatedBy,
    this.poll,
    this.commentsCount,
    this.likesCount,
    this.repostCount,
    this.viewsCount,
    this.sharesCount,
    this.createdAt,
    this.updatedAt,
    this.isReposted,
    this.childrenPost,
    this.thumbnail,
    this.duration,
    this.mediaHeight,
    this.mediaWidth,
  });

  factory SymbolDataModel.fromJson(Map<String, dynamic> json) {
    return SymbolDataModel(
      taggedUsers: List<String>.from(json['tagged_users'] ?? []),
      media: List<String>.from(json['media'] ?? []),
      mediaTypes: List<String>.from(json['media_types'] ?? []),
      id: json['id'],
      type: json['type'],
      visibilityDuration: json['visibility_duration'],
      song: json['song'],
      message: json['message'],
      title: json['title'],
      subTitle: json['sub_title'],
      natureOfPost: json['nature_of_post'],
      location: json['location'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      locationMetadata: json['location_metadata'],
      mediaAspectRatio: json['media_aspect_ratio'],
      postVia: json['post_via'],
      referenceLink: json['reference_link'],
      authorId: json['author_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      poll: json['poll'],
      commentsCount: json['comments_count'],
      likesCount: json['likes_count'],
      repostCount: json['repost_count'],
      viewsCount: json['views_count'],
      sharesCount: json['shares_count'],
      createdAt: json['created_at'] ,
      updatedAt: json['updated_at'],
      isReposted: json['is_reposted'],
      childrenPost: json['children_post'],
      thumbnail: json['thumbnail'],
      duration: json['duration'],
      mediaHeight: json['media_height'],
      mediaWidth: json['media_width'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tagged_users": taggedUsers ?? [],
      "media": media ?? [],
      "media_types": mediaTypes ?? [],
      "id": id,
      "type": type,
      "visibility_duration": visibilityDuration,
      "song": song,
      "message": message,
      "title": title,
      "sub_title": subTitle,
      "nature_of_post": natureOfPost,
      "location": location,
      "latitude": latitude,
      "longitude": longitude,
      "location_metadata": locationMetadata,
      "media_aspect_ratio": mediaAspectRatio,
      "post_via": postVia,
      "reference_link": referenceLink,
      "author_id": authorId,
      "created_by": createdBy,
      "updated_by": updatedBy,
      "poll": poll,
      "comments_count": commentsCount,
      "likes_count": likesCount,
      "repost_count": repostCount,
      "views_count": viewsCount,
      "shares_count": sharesCount,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "is_reposted": isReposted,
      "children_post": childrenPost,
      "thumbnail": thumbnail,
      "duration": duration,
      "media_height": mediaHeight,
      "media_width": mediaWidth,
    };
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
      this.businessId, 
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
    id = json['_id'] ?? json['id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no']==null?json['contact']:json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    profileImage = json['profile_image'];
    businessId = json['business_id'];
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
  String? businessId;
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
  // Future<void> processProfileImage() async {
  //   if (profileImage != null && id != null) {
  //     final localPath = await UserImageStorage.getUserImage(id??"");
  //     if (localPath?.isNotEmpty??false) {
  //       profileImage = localPath;
  //     }
  //   }
  // }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
    map['profile_image'] = profileImage;
    map['business_id'] = businessId;
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