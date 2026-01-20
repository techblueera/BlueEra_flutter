class BedDetailsModel {
  String? businessId;
  String? wardId;
  String? bedNumber;
  String? name;
  String? image;
  String? description;
  int? fees;
  bool? isOccupied;
  String? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  BedDetailsModel({
    this.businessId,
    this.wardId,
    this.bedNumber,
    this.name,
    this.image,
    this.description,
    this.fees,
    this.isOccupied,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  /// ✅ copyWith
  BedDetailsModel copyWith({
    String? businessId,
    String? wardId,
    String? bedNumber,
    String? name,
    String? image,
    String? description,
    int? fees,
    bool? isOccupied,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return BedDetailsModel(
      businessId: businessId ?? this.businessId,
      wardId: wardId ?? this.wardId,
      bedNumber: bedNumber ?? this.bedNumber,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      fees: fees ?? this.fees,
      isOccupied: isOccupied ?? this.isOccupied,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  factory BedDetailsModel.fromJson(Map<String, dynamic> json) {
    return BedDetailsModel(
      businessId: json['businessId'],
      wardId: json['wardId'],
      bedNumber: json['bedNumber'],
      name: json['name'],
      image: json['image'],
      description: json['description'],
      fees: json['fees'],
      isOccupied: json['isOccupied'],
      id: json['_id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'wardId': wardId,
      'name': name,
      'bedNumber': bedNumber,
      'image': image,
      'description': description,
      'fees': fees,
      'isOccupied': isOccupied,
      '_id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}
