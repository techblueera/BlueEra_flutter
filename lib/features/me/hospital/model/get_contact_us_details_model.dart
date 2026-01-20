class HospitalContactUsDetailsModel {
  String? id;
  String? businessId;
  String? hospitalName;
  String? website;
  String? address;
  String? admissionPhone;
  String? principalPhone;
  String? email;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  HospitalContactUsDetailsModel({
    this.id,
    this.businessId,
    this.hospitalName,
    this.website,
    this.address,
    this.admissionPhone,
    this.principalPhone,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  /// 🔁 copyWith (all fields)
  HospitalContactUsDetailsModel copyWith({
    String? id,
    String? businessId,
    String? hospitalName,
    String? website,
    String? address,
    String? admissionPhone,
    String? principalPhone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return HospitalContactUsDetailsModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      hospitalName: hospitalName ?? this.hospitalName,
      website: website ?? this.website,
      address: address ?? this.address,
      admissionPhone: admissionPhone ?? this.admissionPhone,
      principalPhone: principalPhone ?? this.principalPhone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  factory HospitalContactUsDetailsModel.fromJson(Map<String, dynamic> json) {
    return HospitalContactUsDetailsModel(
      id: json['_id'],
      businessId: json['businessId'],
      hospitalName: json['hospitalName'],
      website: json['website'],
      address: json['address'],
      admissionPhone: json['admissionPhone']?.toString(),
      principalPhone: json['principalPhone']?.toString(),
      email: json['email'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'hospitalName': hospitalName,
      'website': website,
      'address': address,
      'admissionPhone': admissionPhone,
      'principalPhone': principalPhone,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}
