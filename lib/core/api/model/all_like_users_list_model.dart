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
  String? business_name;
  String? designation;
  String? business_id;

  LikeUserData(
      {this.sId,
        this.accountType,
        this.business_id,
        this.username,
        this.profileImage,
        this.business_name,
        this.name,
        this.designation});

  LikeUserData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    business_id = json['business_id'];
    accountType = json['account_type'];
    username = json['username'];
    profileImage = json['profile_image'];
    business_name = json['business_name'];
    name = json['name'];
    designation = json['designation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['business_id'] = this.business_id;
    data['account_type'] = this.accountType;
    data['username'] = this.username;
    data['profile_image'] = this.profileImage;
    data['business_name'] = this.business_name;
    data['name'] = this.name;
    data['designation'] = this.designation;
    return data;
  }
}