

class CategoryResponseModel {
  final bool success;
  final List<CategoryModel> data;

  CategoryResponseModel({
    required this.success,
    required this.data,
  });

  factory CategoryResponseModel.fromJson(Map<String, dynamic> json) {
    return CategoryResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? List<CategoryModel>.from(
              json['data'].map((x) => CategoryModel.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((x) => x.toJson()).toList(),
    };
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int v;

  CategoryModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      '__v': v,
    };
  }
}