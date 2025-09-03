/// message : {"_id":"6888e19ef8df63a4ced762a0","message_type":"video","sub_type":"message","who_seen_the_message":["68763d966cbe951b99f684da"],"message_read":0,"url":[{"url":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/6888a996c4eec09d3f37f0ce/files/1753801117856_Screenrecording_20250729_202804.mp4","type":"file","name":"Screenrecording_20250729_202804.mp4","size":3467316,"mimetype":"application/mp4","_id":"6888e19ef8df63a4ced762a1"}],"forward_id":null,"reply_id":null,"senderId":"68763d966cbe951b99f684da","conversation_id":"6888a996c4eec09d3f37f0ce","likes_count":0,"forwards_count":0,"replies_count":6,"updated_at":"2025-07-30T13:49:50.373Z","created_at":"2025-07-29T14:58:38.023Z","__v":0,"is_saved":false}
/// comments : [{"_id":"688a226062b1d146d44be58b","message":"Morning You ","message_type":"text","sub_type":"comment","who_seen_the_message":["68763d966cbe951b99f684da"],"delete_from_everyone":false,"message_read":0,"forward_id":null,"reply_id":"6888e19ef8df63a4ced762a0","senderId":"68763d966cbe951b99f684da","conversation_id":"6888a996c4eec09d3f37f0ce","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-30T13:47:12.137Z","url":[],"created_at":"2025-07-30T13:47:12.137Z","__v":0,"my_comment":true,"is_liked":false,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"688a171962b1d146d44be3ea","message":"Oiii Ghh","message_type":"text","sub_type":"comment","who_seen_the_message":["68763d966cbe951b99f684da"],"delete_from_everyone":false,"message_read":0,"forward_id":null,"reply_id":"6888e19ef8df63a4ced762a0","senderId":"68763d966cbe951b99f684da","conversation_id":"6888a996c4eec09d3f37f0ce","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-30T12:59:05.871Z","url":[],"created_at":"2025-07-30T12:59:05.871Z","__v":0,"my_comment":true,"is_liked":false,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"688a15f0eb5a05803b6db69d","message":"Good Morning KKK","message_type":"text","sub_type":"comment","who_seen_the_message":["68763d966cbe951b99f684da"],"delete_from_everyone":false,"message_read":0,"forward_id":null,"reply_id":"6888e19ef8df63a4ced762a0","senderId":"68763d966cbe951b99f684da","conversation_id":"6888a996c4eec09d3f37f0ce","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-30T12:54:08.699Z","url":[],"created_at":"2025-07-30T12:54:08.699Z","__v":0,"my_comment":true,"is_liked":false,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}},{"_id":"688a13df1ada1cfb22fa0007","message":"Hiiii Mmmq","message_type":"text","sub_type":"comment","who_seen_the_message":["68763d966cbe951b99f684da"],"delete_from_everyone":false,"message_read":0,"forward_id":null,"reply_id":"6888e19ef8df63a4ced762a0","senderId":"68763d966cbe951b99f684da","conversation_id":"6888a996c4eec09d3f37f0ce","likes_count":0,"forwards_count":0,"replies_count":0,"updated_at":"2025-07-30T12:45:19.782Z","url":[],"created_at":"2025-07-30T12:45:19.782Z","__v":0,"my_comment":true,"is_liked":false,"sender":{"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}}]
/// totalPages : 1
/// currentPage : 1

class GetMediaMsgCommentsModel {
  GetMediaMsgCommentsModel({
      this.message, 
      this.comments, 
      this.totalPages, 
      this.currentPage,});

  GetMediaMsgCommentsModel.fromJson(dynamic json) {
    message = json['message'] != null ? Message.fromJson(json['message']) : null;
    if (json['comments'] != null) {
      comments = [];
      json['comments'].forEach((v) {
        comments?.add(Comments.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    currentPage = json['currentPage'];
  }
  Message? message;
  List<Comments>? comments;
  num? totalPages;
  num? currentPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (message != null) {
      map['message'] = message?.toJson();
    }
    if (comments != null) {
      map['comments'] = comments?.map((v) => v.toJson()).toList();
    }
    map['totalPages'] = totalPages;
    map['currentPage'] = currentPage;
    return map;
  }

}

/// _id : "688a226062b1d146d44be58b"
/// message : "Morning You "
/// message_type : "text"
/// sub_type : "comment"
/// who_seen_the_message : ["68763d966cbe951b99f684da"]
/// delete_from_everyone : false
/// message_read : 0
/// forward_id : null
/// reply_id : "6888e19ef8df63a4ced762a0"
/// senderId : "68763d966cbe951b99f684da"
/// conversation_id : "6888a996c4eec09d3f37f0ce"
/// likes_count : 0
/// forwards_count : 0
/// replies_count : 0
/// updated_at : "2025-07-30T13:47:12.137Z"
/// url : []
/// created_at : "2025-07-30T13:47:12.137Z"
/// __v : 0
/// my_comment : true
/// is_liked : false
/// sender : {"_id":"68763d966cbe951b99f684da","contact_no":"6381213588","username":"usermd4gkkaalgc0y","deleted_at":null,"account_type":"BUSINESS","language":"ENG","referral_points":0,"last_seen":null,"role":null,"created_at":"2025-07-15T11:37:58.472Z","updated_at":"2025-07-15T11:37:58.472Z","__v":0}

class Comments {
  Comments({
      this.id, 
      this.message, 
      this.messageType, 
      this.subType, 
      this.whoSeenTheMessage, 
      this.deleteFromEveryone, 
      this.messageRead, 
      this.forwardId, 
      this.replyId, 
      this.senderId, 
      this.conversationId, 
      this.likesCount, 
      this.forwardsCount, 
      this.repliesCount, 
      this.updatedAt, 
      this.url, 
      this.createdAt, 
      this.v, 
      this.myComment, 
      this.isLiked, 
      this.sender,});

  Comments.fromJson(dynamic json) {
    id = json['_id'];
    message = json['message'];
    messageType = json['message_type'];
    subType = json['sub_type'];
    whoSeenTheMessage = json['who_seen_the_message'] != null ? json['who_seen_the_message'].cast<String>() : [];
    deleteFromEveryone = json['delete_from_everyone'];
    messageRead = json['message_read'];
    forwardId = json['forward_id'];
    replyId = json['reply_id'];
    senderId = json['senderId'];
    conversationId = json['conversation_id'];
    likesCount = json['likes_count'];
    forwardsCount = json['forwards_count'];
    repliesCount = json['replies_count'];
    updatedAt = json['updated_at'];
    if (json['url'] != null) {
      url = [];
      json['url'].forEach((v) {
        url?.add(v);
      });
    }
    createdAt = json['created_at'];
    v = json['__v'];
    myComment = json['my_comment'];
    isLiked = json['is_liked'];
    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;
  }
  String? id;
  String? message;
  String? messageType;
  String? subType;
  List<String>? whoSeenTheMessage;
  bool? deleteFromEveryone;
  num? messageRead;
  dynamic forwardId;
  String? replyId;
  String? senderId;
  String? conversationId;
  int? likesCount;
  num? forwardsCount;
  num? repliesCount;
  String? updatedAt;
  List<dynamic>? url;
  String? createdAt;
  num? v;
  bool? myComment;
  bool? isLiked;
  Sender? sender;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['message'] = message;
    map['message_type'] = messageType;
    map['sub_type'] = subType;
    map['who_seen_the_message'] = whoSeenTheMessage;
    map['delete_from_everyone'] = deleteFromEveryone;
    map['message_read'] = messageRead;
    map['forward_id'] = forwardId;
    map['reply_id'] = replyId;
    map['senderId'] = senderId;
    map['conversation_id'] = conversationId;
    map['likes_count'] = likesCount;
    map['forwards_count'] = forwardsCount;
    map['replies_count'] = repliesCount;
    map['updated_at'] = updatedAt;
    if (url != null) {
      map['url'] = url?.map((v) => v.toJson()).toList();
    }
    map['created_at'] = createdAt;
    map['__v'] = v;
    map['my_comment'] = myComment;
    map['is_liked'] = isLiked;
    if (sender != null) {
      map['sender'] = sender?.toJson();
    }
    return map;
  }

}

/// _id : "68763d966cbe951b99f684da"
/// contact_no : "6381213588"
/// username : "usermd4gkkaalgc0y"
/// deleted_at : null
/// account_type : "BUSINESS"
/// language : "ENG"
/// referral_points : 0
/// last_seen : null
/// role : null
/// created_at : "2025-07-15T11:37:58.472Z"
/// updated_at : "2025-07-15T11:37:58.472Z"
/// __v : 0

class Sender {
  Sender({
      this.id,
      this.contactNo,
      this.username,
      this.name,
      this.deletedAt,
      this.accountType,
      this.language,
      this.referralPoints,
      this.lastSeen,
      this.role,
      this.createdAt,
      this.profileImage,
      this.updatedAt,
      this.v,});

  Sender.fromJson(dynamic json) {
    id = json['_id'];
    contactNo = json['contact_no'];
    username = json['username'];
    name = json['name'];
    deletedAt = json['deleted_at'];
    accountType = json['account_type'];
    profileImage = json['profile_image'];
    language = json['language'];
    referralPoints = json['referral_points'];
    lastSeen = json['last_seen'];
    role = json['role'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
  }
  String? id;
  String? contactNo;
  String? username;
  String? name;
  dynamic deletedAt;
  String? accountType;
  String? profileImage;
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
    map['contact_no'] = contactNo;
    map['name'] = name;
    map['username'] = username;
    map['deleted_at'] = deletedAt;
    map['profile_image'] = profileImage;
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

/// _id : "6888e19ef8df63a4ced762a0"
/// message_type : "video"
/// sub_type : "message"
/// who_seen_the_message : ["68763d966cbe951b99f684da"]
/// message_read : 0
/// url : [{"url":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/6888a996c4eec09d3f37f0ce/files/1753801117856_Screenrecording_20250729_202804.mp4","type":"file","name":"Screenrecording_20250729_202804.mp4","size":3467316,"mimetype":"application/mp4","_id":"6888e19ef8df63a4ced762a1"}]
/// forward_id : null
/// reply_id : null
/// senderId : "68763d966cbe951b99f684da"
/// conversation_id : "6888a996c4eec09d3f37f0ce"
/// likes_count : 0
/// forwards_count : 0
/// replies_count : 6
/// updated_at : "2025-07-30T13:49:50.373Z"
/// created_at : "2025-07-29T14:58:38.023Z"
/// __v : 0
/// is_saved : false

class Message {
  Message({
      this.id, 
      this.messageType, 
      this.subType, 
      this.whoSeenTheMessage, 
      this.messageRead, 
      this.url, 
      this.forwardId, 
      this.replyId, 
      this.senderId, 
      this.conversationId, 
      this.likesCount, 
      this.forwardsCount, 
      this.repliesCount, 
      this.updatedAt, 
      this.createdAt, 
      this.v, 
      this.isSaved,});

  Message.fromJson(dynamic json) {
    id = json['_id'];
    messageType = json['message_type'];
    subType = json['sub_type'];
    whoSeenTheMessage = json['who_seen_the_message'] != null ? json['who_seen_the_message'].cast<String>() : [];
    messageRead = json['message_read'];
    if (json['url'] != null) {
      url = [];
      json['url'].forEach((v) {
        url?.add(Url.fromJson(v));
      });
    }
    forwardId = json['forward_id'];
    replyId = json['reply_id'];
    senderId = json['senderId'];
    conversationId = json['conversation_id'];
    likesCount = json['likes_count'];
    forwardsCount = json['forwards_count'];
    repliesCount = json['replies_count'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    v = json['__v'];
    isSaved = json['is_saved'];
  }
  String? id;
  String? messageType;
  String? subType;
  List<String>? whoSeenTheMessage;
  num? messageRead;
  List<Url>? url;
  dynamic forwardId;
  dynamic replyId;
  String? senderId;
  String? conversationId;
  num? likesCount;
  num? forwardsCount;
  num? repliesCount;
  String? updatedAt;
  String? createdAt;
  num? v;
  bool? isSaved;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['message_type'] = messageType;
    map['sub_type'] = subType;
    map['who_seen_the_message'] = whoSeenTheMessage;
    map['message_read'] = messageRead;
    if (url != null) {
      map['url'] = url?.map((v) => v.toJson()).toList();
    }
    map['forward_id'] = forwardId;
    map['reply_id'] = replyId;
    map['senderId'] = senderId;
    map['conversation_id'] = conversationId;
    map['likes_count'] = likesCount;
    map['forwards_count'] = forwardsCount;
    map['replies_count'] = repliesCount;
    map['updated_at'] = updatedAt;
    map['created_at'] = createdAt;
    map['__v'] = v;
    map['is_saved'] = isSaved;
    return map;
  }

}

/// url : "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/messages/6888a996c4eec09d3f37f0ce/files/1753801117856_Screenrecording_20250729_202804.mp4"
/// type : "file"
/// name : "Screenrecording_20250729_202804.mp4"
/// size : 3467316
/// mimetype : "application/mp4"
/// _id : "6888e19ef8df63a4ced762a1"

class Url {
  Url({
      this.url, 
      this.type, 
      this.name, 
      this.size, 
      this.mimetype, 
      this.id,});

  Url.fromJson(dynamic json) {
    url = json['url'];
    type = json['type'];
    name = json['name'];
    size = json['size'];
    mimetype = json['mimetype'];
    id = json['_id'];
  }
  String? url;
  String? type;
  String? name;
  num? size;
  String? mimetype;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['type'] = type;
    map['name'] = name;
    map['size'] = size;
    map['mimetype'] = mimetype;
    map['_id'] = id;
    return map;
  }

}