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

  /// Business profile id (from the sibling `business._id`). Present for BUSINESS
  /// users; used to open their business visiting profile. Null for individuals.
  final String? businessId;

  /// Business category name from `category_details.name` (e.g. "Watches &
  /// Eyewear"). Present for BUSINESS users; null for individuals.
  final String? categoryName;

  /// Individual user's designation (e.g. "Bike Rider"), shown as the header
  /// subtext when there's no business category.
  final String? designation;

  UserByPhoneModel({
    required this.id,
    required this.name,
    this.contactNo,
    this.profileImage,
    this.username,
    this.location,
    this.bio,
    this.accountType,
    this.businessId,
    this.categoryName,
    this.designation,
  });

  /// Header subtext for the phone-lookup UI: the business category when set,
  /// otherwise the individual's designation, otherwise null.
  String? get subtitle {
    if ((categoryName ?? '').trim().isNotEmpty) return categoryName;
    if ((designation ?? '').trim().isNotEmpty) return designation;
    return null;
  }

  /// [json] is the response's `user` object; [business] is the sibling
  /// `business` object, which is where `category_details` actually lives. Both
  /// are checked so the category resolves regardless of which side carries it.
  factory UserByPhoneModel.fromJson(Map<String, dynamic> json,
      {Map<String, dynamic>? business}) {
    final category = business?['category_details'] ?? json['category_details'];
    return UserByPhoneModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactNo: json['contact_no']?.toString(),
      profileImage: json['profile_image']?.toString(),
      username: json['username']?.toString(),
      location: json['location']?.toString(),
      bio: json['bio']?.toString(),
      accountType: json['account_type']?.toString(),
      businessId: business?['_id']?.toString() ?? business?['id']?.toString(),
      categoryName: category is Map ? category['name']?.toString() : null,
      designation: json['designation']?.toString(),
    );
  }
}
