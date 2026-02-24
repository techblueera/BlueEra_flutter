class EmergencyContactRes {
  bool? success;
  EmergencyContactData? data;
  EmergencyContactRes({this.success, this.data});
  EmergencyContactRes.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    final d = json['data'];
    if (d is Map<String, dynamic>) {
      data = EmergencyContactData.fromJson(d);
    } else {
      data = null;
    }
  }
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class EmergencyContactData {
  String? id;
  String? emergencyNumber;
  String? appointmentNumber;
  String? hospitalId;
  String? userId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  EmergencyContactData({
    this.id,
    this.emergencyNumber,
    this.appointmentNumber,
    this.hospitalId,
    this.userId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  EmergencyContactData.fromJson(Map<String, dynamic> json) {
    id = json['_id']?.toString();
    emergencyNumber = json['emergencyNumber']?.toString();
    appointmentNumber = json['appointmentNumber']?.toString();
    hospitalId = json['hospitalId']?.toString();
    userId = json['userId']?.toString();
    isActive = json['isActive'] as bool?;
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    v = json['__v'] is int ? json['__v'] as int : int.tryParse("${json['__v']}");
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'emergencyNumber': emergencyNumber,
      'appointmentNumber': appointmentNumber,
      'hospitalId': hospitalId,
      'userId': userId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}
