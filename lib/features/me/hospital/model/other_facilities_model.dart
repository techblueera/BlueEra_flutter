class OtherFacilities {
  final String id;
  final bool ambulance;
  final bool pmSwasthyaBimaYojana;
  final bool bloodBank;
  final bool diagnosticDepartments;
  final bool medicalStore;
  final List<String> cashlessInsurance;
  final String hospitalId;
  final String userId;
  final String createdAt;
  final String updatedAt;

  OtherFacilities({
    required this.id,
    required this.ambulance,
    required this.pmSwasthyaBimaYojana,
    required this.bloodBank,
    required this.diagnosticDepartments,
    required this.medicalStore,
    required this.cashlessInsurance,
    required this.hospitalId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OtherFacilities.fromJson(Map<String, dynamic> json) {
    final cash = json['cashlessInsurance'];
    return OtherFacilities(
      id: json['_id']?.toString() ?? '',
      ambulance: (json['ambulance'] ?? false) == true,
      pmSwasthyaBimaYojana: (json['pmSwasthyaBimaYojana'] ?? false) == true,
      bloodBank: (json['bloodBank'] ?? false) == true,
      diagnosticDepartments: (json['diagnosticDepartments'] ?? false) == true,
      medicalStore: (json['medicalStore'] ?? false) == true,
      cashlessInsurance: cash is List ? cash.map((e) => e.toString()).toList() : <String>[],
      hospitalId: json['hospitalId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
