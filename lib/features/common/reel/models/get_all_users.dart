import 'package:get/get.dart';

class GetAllUsers {
  final bool status;
  final List<UsersData> data;

  GetAllUsers({
    required this.status,
    required this.data,
  });

  factory GetAllUsers.fromJson(Map<String, dynamic> json) {
    return GetAllUsers(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => UsersData.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class UsersData {
  final String id;
  final String accountType;
  final String? businessName;
  final String? logo;
  final bool? businessIsVerified;
  final String? name;
  final String? username;
  final String? profileImage;
  final String? message;
  final String? designation;
  final CategoryOfBusiness? categoryOfBusiness;
  final RxBool isSelected = false.obs;


  UsersData({
    required this.id,
    required this.accountType,
    this.businessName,
    this.logo,
    this.businessIsVerified,
    this.name,
    this.username,
    this.profileImage,
    this.message,
    this.designation,
    this.categoryOfBusiness,
  });

  factory UsersData.fromJson(Map<String, dynamic> json) {
    return UsersData(
      id: json['_id'] ?? '',
      accountType: json['account_type'] ?? '',
      businessName: json['business_name'],
      logo: json['logo'],
      businessIsVerified: json['business_isVerified'],
      name: json['name'],
      username: json['username'],
      profileImage: json['profile_image'],
      message: json['message'],
      designation: json['designation'],
      categoryOfBusiness: json['category_Of_Business'] == null
          ? null
          : CategoryOfBusiness.fromJson(
          json['category_Of_Business'] as Map<String, dynamic>),
    );
  }
}


class CategoryOfBusiness {
  final String id;
  final String name;

  CategoryOfBusiness({required this.id, required this.name});

  factory CategoryOfBusiness.fromJson(Map<String, dynamic> json) =>
      CategoryOfBusiness(
        id: json['_id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'_id': id, 'name': name};
}
