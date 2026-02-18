class Department {
  final String id;
  final String name;
  final String type;
  final String key;
  final String description;
  final String hospitalId;
  final String userId;
  final String createdAt;
  final String updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.key,
    required this.type,
    required this.description,
    required this.hospitalId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  static List<Department> listFromJson(dynamic data) {
    final arr = (data is Map<String, dynamic>) ? (data['data'] as List?) : (data as List?);
    return (arr ?? []).map((e) => Department.fromJson(e as Map<String, dynamic>)).toList();
  }
}
