import 'dart:convert';

GuestUserDetailModel guestUserDetailModelFromJson(String str) =>
    GuestUserDetailModel.fromJson(json.decode(str));

/// Response model for `user-service/user/getGuestUser/{id}`.
///
/// Used to pre-fill the name + profile image on the individual / business
/// account-creation screens when a guest upgrades their account.
class GuestUserDetailModel {
  GuestUserDetailModel({this.status, this.message, this.user});

  GuestUserDetailModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    user = json['user'] != null ? GuestUserDetail.fromJson(json['user']) : null;
  }

  bool? status;
  String? message;
  GuestUserDetail? user;
}

class GuestUserDetail {
  GuestUserDetail({
    this.id,
    this.username,
    this.name,
    this.email,
    this.contactNo,
    this.profileImage,
  });

  GuestUserDetail.fromJson(dynamic json) {
    id = json['_id'];
    username = json['username'];
    name = json['name'];
    email = json['email'];
    contactNo = json['contact_no'];
    profileImage = json['profile_image'];
  }

  String? id;
  String? username;
  String? name;
  String? email;
  String? contactNo;
  String? profileImage;
}
