class EmergencyCare {
  final String id;
  final bool emergencyCasualty;
  final bool traumaCare;
  final bool icu;
  final bool ccu;
  final bool nicu;
  final bool picu;
  final String hospitalId;
  final String userId;
  final String createdAt;
  final String updatedAt;

  EmergencyCare({
    required this.id,
    required this.emergencyCasualty,
    required this.traumaCare,
    required this.icu,
    required this.ccu,
    required this.nicu,
    required this.picu,
    required this.hospitalId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyCare.fromJson(Map<String, dynamic> json) {
    return EmergencyCare(
      id: json['_id']?.toString() ?? '',
      emergencyCasualty: (json['emergencyCasualty'] ?? false) == true,
      traumaCare: (json['traumaCare'] ?? false) == true,
      icu: (json['icu'] ?? false) == true,
      ccu: (json['ccu'] ?? false) == true,
      nicu: (json['nicu'] ?? false) == true,
      picu: (json['picu'] ?? false) == true,
      hospitalId: json['hospitalId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
