/// Lightweight model for the `user-service/user/by-phone/{phone}` response's
/// `user` object. Only the fields the phone-lookup bottom sheet needs are
/// parsed; the API returns many more.
class UserByPhoneModel {
  final String id;
  final String name;
  final String? contactNo;
  final String? profileImage;
  final String? username;
  final String? location;
  final String? bio;
  final String? accountType;

  UserByPhoneModel({
    required this.id,
    required this.name,
    this.contactNo,
    this.profileImage,
    this.username,
    this.location,
    this.bio,
    this.accountType,
  });

  factory UserByPhoneModel.fromJson(Map<String, dynamic> json) {
    return UserByPhoneModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactNo: json['contact_no']?.toString(),
      profileImage: json['profile_image']?.toString(),
      username: json['username']?.toString(),
      location: json['location']?.toString(),
      bio: json['bio']?.toString(),
      accountType: json['account_type']?.toString(),
    );
  }
}
