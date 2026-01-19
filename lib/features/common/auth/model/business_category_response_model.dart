class BusinessCategoryResponseModel {
  bool? success;
  int? count;
  List<BusinessCategory>? businessCategory;

  BusinessCategoryResponseModel({
    this.success,
    this.count,
    this.businessCategory,
  });

  factory BusinessCategoryResponseModel.fromJson(Map<String, dynamic> json) =>
      BusinessCategoryResponseModel(
        success: json["success"],
        count: json["count"],
        businessCategory: json["data"] == null
            ? []
            : List<BusinessCategory>.from(json["data"]!.map((x) => BusinessCategory.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "count": count,
    "data": businessCategory == null
        ? []
        : List<dynamic>.from(businessCategory!.map((x) => x.toJson())),
  };
}

class BusinessCategory {
  String? id;
  String? tagId;
  String? name;
  String? type;
  String? updatedAt;
  dynamic deletedAt;
  String? createdBy;
  bool? active;
  String? imageUrl;
  String? createdAt;
  int? v;

  BusinessCategory({
    this.id,
    this.tagId,
    this.name,
    this.type,
    this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.active,
    this.imageUrl,
    this.createdAt,
    this.v,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) => BusinessCategory(
    id: json["_id"],
    tagId: json["tag_id"],
    name: json["name"],
    type: json["type"],
    updatedAt: json["updated_at"],
    deletedAt: json["deleted_at"],
    createdBy: json["created_by"],
    active: json["active"],
    imageUrl: json["image_url"],
    createdAt: json["created_at"],
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "tag_id": tagId,
    "name": name,
    "type": type,
    "updated_at": updatedAt,
    "deleted_at": deletedAt,
    "created_by": createdBy,
    "active": active,
    "image_url": imageUrl,
    "created_at": createdAt,
    "__v": v,
  };
}