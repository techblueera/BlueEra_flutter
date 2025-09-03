class NotificationDataModel {
  bool? success;
  List<NotificationDataList>? data;
  String? message;

  NotificationDataModel({this.success, this.data, this.message});

  NotificationDataModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <NotificationDataList>[];
      json['data'].forEach((v) {
        data!.add(new NotificationDataList.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class NotificationDataList {
  String? sId;
  String? type;
  String? status;
  String? sentBy;
  String? sentTo;
  Metadata? metadata;
  int? iV;
  String? createdAt;
  String? updatedAt;
  String? message;
  User? user;

  NotificationDataList(
      {this.sId,
        this.type,
        this.status,
        this.sentBy,
        this.sentTo,
        this.metadata,
        this.iV,
        this.createdAt,
        this.updatedAt,
        this.message,
        this.user});

  NotificationDataList.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    type = json['type'];
    status = json['status'];
    sentBy = json['sentBy'];
    sentTo = json['sentTo'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    iV = json['__v'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    message = json['message'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['type'] = this.type;
    data['status'] = this.status;
    data['sentBy'] = this.sentBy;
    data['sentTo'] = this.sentTo;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['__v'] = this.iV;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['message'] = this.message;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class Metadata {
  String? postId;
  String? senderName;

  Metadata({this.postId, this.senderName});

  Metadata.fromJson(Map<String, dynamic> json) {
    postId = json['post_id'];
    senderName = json['senderName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['post_id'] = this.postId;
    data['senderName'] = this.senderName;
    return data;
  }
}

class User {
  String? id;
  String? name;
  String? profileImage;

  User({this.id, this.name, this.profileImage});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile_image'] = this.profileImage;
    return data;
  }
}