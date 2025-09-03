class BlockUserResponse {
  final bool success;
  final String message;
  final BlockedUserData data;

  BlockUserResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BlockUserResponse.fromJson(Map<String, dynamic> json) {
    return BlockUserResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: BlockedUserData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data.toJson(),
  };
}

class BlockedUserData {
  final String blockedBy;
  final String blockedTo;
  final String type;
  final int duration;
  final String createdBy;
  final String? updatedBy;
  final String status;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  BlockedUserData({
    required this.blockedBy,
    required this.blockedTo,
    required this.type,
    required this.duration,
    required this.createdBy,
    required this.updatedBy,
    required this.status,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory BlockedUserData.fromJson(Map<String, dynamic> json) {
    return BlockedUserData(
      blockedBy: json['blockedBy'],
      blockedTo: json['blockedTo'],
      type: json['type'],
      duration: json['duration'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      status: json['status'],
      id: json['_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    'blockedBy': blockedBy,
    'blockedTo': blockedTo,
    'type': type,
    'duration': duration,
    'created_by': createdBy,
    'updated_by': updatedBy,
    'status': status,
    '_id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    '__v': v,
  };
}
