class OpdDoctor {
  final String id;
  final String name;
  final String? education;
  final String description;
  final String departmentId;
  final String? position;
  final int? fees;
  final String imageUrl;
  final String timing;
  final String hospitalId;
  final String userId;
  final String createdAt;
  final String updatedAt;

  OpdDoctor({
    required this.id,
    required this.name,
    this.education,
    required this.description,
    required this.departmentId,
    this.position,
    this.fees,
    required this.imageUrl,
    required this.timing,
    required this.hospitalId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpdDoctor.fromJson(Map<String, dynamic> json) {
    return OpdDoctor(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      education: json['education']?.toString(),
      description: json['description']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      position: json['position']?.toString(),
      fees: json['fees'] is num ? (json['fees'] as num).toInt() : int.tryParse('${json['fees'] ?? ''}'),
      imageUrl: json['imageUrl']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  static List<OpdDoctor> listFromJson(dynamic data) {
    final arr = (data is Map<String, dynamic>) ? (data['data'] as List?) : (data as List?);
    return (arr ?? []).map((e) => OpdDoctor.fromJson(e as Map<String, dynamic>)).toList();
  }
}
