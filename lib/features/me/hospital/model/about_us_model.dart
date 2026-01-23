class HospitalAboutUsModel {
  final String? id;
  final String? businessId;
  final String? history;
  final String? management;
  final String? visionMission;
  final List<String>? gallery;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  HospitalAboutUsModel({
    this.id,
    this.businessId,
    this.history,
    this.management,
    this.visionMission,
    this.gallery,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  /// FROM JSON
  factory HospitalAboutUsModel.fromJson(Map<String, dynamic> json) {
    return HospitalAboutUsModel(
      id: json['_id'],
      businessId: json['businessId'],
      history: json['history'],
      management: json['management'],
      visionMission: json['visionMission'],
      gallery: (json['gallery'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'],
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'history': history,
      'management': management,
      'visionMission': visionMission,
      'gallery': gallery,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }

  /// COPY WITH
  HospitalAboutUsModel copyWith({
    String? id,
    String? businessId,
    String? history,
    String? management,
    String? visionMission,
    List<String>? gallery,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return HospitalAboutUsModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      history: history ?? this.history,
      management: management ?? this.management,
      visionMission: visionMission ?? this.visionMission,
      gallery: gallery ?? this.gallery,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }
}
