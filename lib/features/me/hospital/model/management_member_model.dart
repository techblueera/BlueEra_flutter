class ManagementMember {
  final String id;
  final String name;
  final String imageUrl;
  final String position;
  final String education;
  final String description;
  final String hospitalId;
  final String userId;
  final String createdAt; 
  final String updatedAt;   

  ManagementMember({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.position,
    required this.education,
    required this.description,
    required this.hospitalId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManagementMember.fromJson(Map<String, dynamic> json) {
    return ManagementMember(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      education: json['education']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  static List<ManagementMember> listFromJson(dynamic data) {
    final arr = (data is Map<String, dynamic>) ? (data['data'] as List?) : (data as List?);
    return (arr ?? []).map((e) => ManagementMember.fromJson(e as Map<String, dynamic>)).toList();
  }
}
