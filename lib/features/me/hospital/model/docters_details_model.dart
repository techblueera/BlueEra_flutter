class DoctorsDetailsModel {
  String? id;
  String? businessId;
  String? departmentId;
  String? name;
  String? specialization;
  String? qualification;
  String? photo;
  String? availability;
  String? leaveFrom;
  String? leaveTo;
  int? fees;
  bool? isOnLeave;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  DoctorsDetailsModel({
    this.id,
    this.businessId,
    this.departmentId,
    this.name,
    this.specialization,
    this.qualification,
    this.leaveTo,
    this.leaveFrom,
    this.photo,
    this.availability,
    this.fees,
    this.isOnLeave,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory DoctorsDetailsModel.fromJson(Map<String, dynamic> json) {
    return DoctorsDetailsModel(
      id: json['_id'] as String?,
      businessId: json['businessId'] as String?,
      departmentId: json['departmentId'] as String?,
      name: json['name'] as String?,
      leaveFrom: json['leaveFrom']?.toString(),
      leaveTo: json['leaveTo']?.toString(),
      specialization: json['specialization'] as String?,
      qualification: json['qualification'] as String?,
      photo: json['photo'] as String?,
      availability: json['availability'] as String?,
      fees: json['fees'] is int
          ? json['fees']
          : int.tryParse(json['fees']?.toString() ?? ''),
      isOnLeave: json['isOnLeave'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'] as int?,
    );
  }

  /// ✅ copyWith
  DoctorsDetailsModel copyWith({
    String? id,
    String? businessId,
    String? departmentId,
    String? name,
    String? specialization,
    String? qualification,
    String? photo,
    String? availability,
    String? leaveFrom,
    String? leaveTo,
    int? fees,
    bool? isOnLeave,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return DoctorsDetailsModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      photo: photo ?? this.photo,
      availability: availability ?? this.availability,
      leaveFrom: leaveFrom ?? this.leaveFrom,
      leaveTo: leaveTo ?? this.leaveTo,
      fees: fees ?? this.fees,
      isOnLeave: isOnLeave ?? this.isOnLeave,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "businessId": businessId,
      "departmentId": departmentId,
      "name": name,
      "specialization": specialization,
      "qualification": qualification,
      "photo": photo,
      "availability": availability,
      "fees": fees,
      "isOnLeave": isOnLeave,
      "leaveFrom": leaveFrom,
      "leaveTo": leaveTo,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "__v": v,
    };
  }
}
