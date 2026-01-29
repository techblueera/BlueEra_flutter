
import 'get_categories_model.dart';

class SingleBusinessCategoryModelResponse {
  bool? success;
  Category? category;
  int? count;
  List<SubCategories>? subCategories;

  SingleBusinessCategoryModelResponse({
    this.success,
    this.category,
    this.count,
    this.subCategories,
  });

  factory SingleBusinessCategoryModelResponse.fromJson(Map<String, dynamic> json) =>
      SingleBusinessCategoryModelResponse(
        success: json["success"],
        category: json["category"] == null ? null : Category.fromJson(json["category"]),
        count: json["count"],
        subCategories: json["data"] == null
            ? []
            : List<SubCategories>.from(json["data"]!.map((x) => SubCategories.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "category": category?.toJson(),
    "count": count,
    "data": subCategories == null
        ? []
        : List<dynamic>.from(subCategories!.map((x) => x.toJson())),
  };
}

class Category {
  String? id;
  String? name;
  String? tagId;

  Category({
    this.id,
    this.name,
    this.tagId,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    tagId: json["tag_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "tag_id": tagId,
  };
}
