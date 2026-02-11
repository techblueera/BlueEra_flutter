class FacilityOther {
  String? id;
  String label;
  bool isActive;
  String details;

  FacilityOther({
    this.id,
    required this.label,
    required this.isActive,
    required this.details,
  });

  factory FacilityOther.fromJson(Map<String, dynamic> json) => FacilityOther(
        id: json["_id"],
        label: json["label"] ?? "",
        isActive: json["isActive"] ?? false,
        details: json["details"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "_id": id,
        "label": label,
        "isActive": isActive,
        "details": details,
      };
}

class Facilities {
  String? id;
  String? laboratoryId;
  String? userId;
  bool wheelchairAssistance;
  bool doctorConsultationTieUp;
  bool insuranceCashlessSupport;
  bool homeSampleCollection;
  bool digitalReport;
  List<FacilityOther> other;

  Facilities({
    this.id,
    this.laboratoryId,
    this.userId,
    this.wheelchairAssistance = false,
    this.doctorConsultationTieUp = false,
    this.insuranceCashlessSupport = false,
    this.homeSampleCollection = false,
    this.digitalReport = false,
    List<FacilityOther>? other,
  }) : other = other ?? [];

  factory Facilities.fromJson(Map<String, dynamic> json) => Facilities(
        id: json["_id"],
        laboratoryId: json["laboratoryId"],
        userId: json["userId"],
        wheelchairAssistance: json["wheelchairAssistance"] ?? false,
        doctorConsultationTieUp: json["doctorConsultationTieUp"] ?? false,
        insuranceCashlessSupport: json["insuranceCashlessSupport"] ?? false,
        homeSampleCollection: json["homeSampleCollection"] ?? false,
        digitalReport: json["digitalReport"] ?? false,
        other: (json["other"] as List? ?? [])
            .map((e) => FacilityOther.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "_id": id,
        "laboratoryId": laboratoryId,
        "wheelchairAssistance": wheelchairAssistance,
        "doctorConsultationTieUp": doctorConsultationTieUp,
        "insuranceCashlessSupport": insuranceCashlessSupport,
        "homeSampleCollection": homeSampleCollection,
        "digitalReport": digitalReport,
        "other": other.map((e) => e.toJson()).toList(),
      };
}
