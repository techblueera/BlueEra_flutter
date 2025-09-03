class Media {
  final int? id;
  final String? url;
  final int? companyId;
  final DateTime? createdAt;
  final dynamic updatedAt;
  final int? createdBy;
  final int? updatedBy;
  // final dynamic deletedAt;

  Media({
    required this.id,
    required this.url,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    // required this.deletedAt,
  });

  Media copyWith({
    int? id,
    String? url,
    int? companyId,
    DateTime? createdAt,
    dynamic updatedAt,
    int? createdBy,
    int? updatedBy,
    // dynamic deletedAt,
  }) =>
      Media(
        id: id ?? this.id,
        url: url ?? this.url,
        companyId: companyId ?? this.companyId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
        // deletedAt: deletedAt ?? this.deletedAt,
      );

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json["id"] ?? 0,
        url: json["url"] ?? '',
        companyId: json["company_id"] ?? 0,
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        createdBy: json["created_by"] ?? 0,
        updatedBy: json["updated_by"] ?? 0,
        // deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "url": url,
        "company_id": companyId,
        "created_at": createdAt!=null ?createdAt!.toIso8601String():'',
        "updated_at":  updatedAt!=null ?updatedAt!.toIso8601String():'',
        "created_by": createdBy,
        "updated_by": updatedBy,
        // "deleted_at": deletedAt,
      };
}
