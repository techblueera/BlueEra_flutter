class WardModel {
  final String? id;
  final String? businessId;
  final String? departmentId;
  final String? name;
  final String? type;
  final int? totalBeds;
  final int? availableBeds;
  final int? fees;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  const WardModel({
    this.id,
    this.businessId,
    this.departmentId,
    this.name,
    this.type,
    this.totalBeds,
    this.availableBeds,
    this.fees,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  /// from json
  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      id: json['_id'],
      businessId: json['businessId'],
      departmentId: json['departmentId'],
      name: json['name'],
      type: json['type'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
      fees: json['fees'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      v: json['__v'],
    );
  }

  /// to json
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'departmentId': departmentId,
      'name': name,
      'type': type,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'fees': fees,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }

  /// copyWith
  WardModel copyWith({
    String? id,
    String? businessId,
    String? departmentId,
    String? name,
    String? type,
    int? totalBeds,
    int? availableBeds,
    int? fees,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return WardModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      type: type ?? this.type,
      totalBeds: totalBeds ?? this.totalBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      fees: fees ?? this.fees,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }
}
