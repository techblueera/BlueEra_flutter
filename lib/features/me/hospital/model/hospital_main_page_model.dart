class MainHospitalDepartmentResponse {
  final bool? success;
  final String? message;
  final List<Department>? data;

  MainHospitalDepartmentResponse({
    this.success,
    this.message,
    this.data,
  });

  factory MainHospitalDepartmentResponse.fromJson(
      Map<String, dynamic>? json) {
    if (json == null) return MainHospitalDepartmentResponse();

    return MainHospitalDepartmentResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
          .map((e) => Department.fromJson(e))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class Department {
  final String? id;
  final String? businessId;
  final String? name;
  final String? type;
  final String? parentId;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Department({
    this.id,
    this.businessId,
    this.name,
    this.type,
    this.parentId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Department.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Department();

    return Department(
      id: json['_id'],
      businessId: json['businessId'],
      name: json['name'],
      type: json['type'],
      parentId: json['parentId'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'name': name,
      'type': type,
      'parentId': parentId,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}
