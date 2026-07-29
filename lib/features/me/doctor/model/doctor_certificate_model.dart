/// One "Certificate & Award" belonging to a standalone doctor.
///
/// Returned inline by `GET /doctors/me` and `GET /doctors/full/:userId`, and
/// standalone by `GET /doctor-certificates/me`.
class DoctorCertificate {
  final String? id;
  final String? doctorProfileId;
  final String? userId;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? issuedBy;
  final DateTime? issuedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DoctorCertificate({
    this.id,
    this.doctorProfileId,
    this.userId,
    this.title,
    this.description,
    this.imageUrl,
    this.issuedBy,
    this.issuedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorCertificate.fromJson(Map<String, dynamic> json) {
    return DoctorCertificate(
      id: json['_id']?.toString(),
      doctorProfileId: json['doctorProfileId']?.toString(),
      userId: json['userId']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      issuedBy: json['issuedBy']?.toString(),
      issuedDate: DateTime.tryParse(json['issuedDate']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static List<DoctorCertificate> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DoctorCertificate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
