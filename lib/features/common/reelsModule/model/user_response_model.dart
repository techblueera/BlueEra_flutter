class UserResponseModel {
  final bool success;
  final String message;
   List<TagUserData> data;

  UserResponseModel({
    this.success = false,
    this.message = '',
    this.data = const [],
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => TagUserData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class TagUserData {
  final int id;
  final String username;
  final String profileImage;
  final String name;
  final UserResponseCompany? company;
  final String accountType;

  TagUserData({
    this.id = 0,
    this.username = '',
    this.profileImage = '',
    this.name = '',
    this.company,
    this.accountType = '',
  });

  factory TagUserData.fromJson(Map<String, dynamic> json) {
    return TagUserData(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      profileImage: json['profile_image'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] != null
          ? UserResponseCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      accountType: json['account_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile_image': profileImage,
      'name': name,
      'company': company?.toJson(),
      'account_type': accountType,
    };
  }
}

class UserResponseCompany {
  final String companyName;
  final String userName;

  UserResponseCompany({
    this.companyName = '',
    this.userName = '',
  });

  factory UserResponseCompany.fromJson(Map<String, dynamic> json) {
    return UserResponseCompany(
      companyName: json['company_name'] ?? '',
      userName: json['user_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'user_name': userName,
    };
  }
}
