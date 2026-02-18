class IpdWard {
  final String id;
  final String name;
  final String imageUrl;
  final int bedCount;
  final String description;
  final int fees;
  final String hospitalId;
  final String userId;
  final String departmentId;
  final String createdAt;
  final String updatedAt;
  final int v;

  IpdWard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.bedCount,
    required this.description,
    required this.fees,
    required this.hospitalId,
    required this.userId,
    required this.departmentId,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory IpdWard.fromJson(Map<String, dynamic> json) {
    return IpdWard(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      bedCount: json['bedCount'] ?? 0,
      description: json['description']?.toString() ?? '',
      fees: json['fees'] ?? 0,
      hospitalId: json['hospitalId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      v: json['__v'] ?? 0,
    );
  }

  static List<IpdWard> listFromJson(dynamic data) {
    final arr = (data is Map<String, dynamic>) ? (data['data'] as List?) : (data as List?);
    return (arr ?? []).map((e) => IpdWard.fromJson(e as Map<String, dynamic>)).toList();
  }
}
