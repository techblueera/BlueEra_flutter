class MedicalCategory {
  final String? id;
  final String? businessId;
  final String? name;
  final String? icon;
  final int? v;

  MedicalCategory({
    this.id,
    this.businessId,
    this.name,
    this.icon,
    this.v,
  });

  factory MedicalCategory.fromJson(Map<String, dynamic> json) {
    return MedicalCategory(
      id: json['_id'],
      businessId: json['businessId'],
      name: json['name'],
      icon: json['icon'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'name': name,
      'icon': icon,
      '__v': v,
    };
  }
}
