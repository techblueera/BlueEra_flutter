class RiderAssociation {
  final String id;
  final String riderUserId;
  final String businessUserId;
  final String requestedBy;
  final String status;
  final String statusReason;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RiderAssociation({
    required this.id,
    required this.riderUserId,
    required this.businessUserId,
    required this.requestedBy,
    required this.status,
    required this.statusReason,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RiderAssociation.fromJson(Map<String, dynamic> json) {
    return RiderAssociation(
      id: json['_id'] ?? '',
      riderUserId: json['riderUserId'] ?? '',
      businessUserId: json['businessUserId'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      status: json['status'] ?? '',
      statusReason: json['statusReason'] ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
