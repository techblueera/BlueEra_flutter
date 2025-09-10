class AllLikeUsersListModel {
  bool? success;
  String? message;
  List<LikeUserData>? data;

  AllLikeUsersListModel({this.success, this.message, this.data});

  AllLikeUsersListModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <LikeUserData>[];
      json['data'].forEach((v) {
        data!.add(new LikeUserData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LikeUserData {
  String? sId;
  String? accountType;
  String? username;
  String? profileImage;
  String? name;
  String? designation;

  LikeUserData(
      {this.sId,
        this.accountType,
        this.username,
        this.profileImage,
        this.name,
        this.designation});

  LikeUserData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    accountType = json['account_type'];
    username = json['username'];
    profileImage = json['profile_image'];
    name = json['name'];
    designation = json['designation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['account_type'] = this.accountType;
    data['username'] = this.username;
    data['profile_image'] = this.profileImage;
    data['name'] = this.name;
    data['designation'] = this.designation;
    return data;
  }
}