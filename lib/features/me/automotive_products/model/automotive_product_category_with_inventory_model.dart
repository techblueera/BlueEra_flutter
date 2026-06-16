class AutomotiveProductCategoryWithInventoryModel {
  String? sId;
  String? name;
  String? key;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? description;
  String? image;
  List<AutomotiveProductCategoryWithInventoryModel>? children;

  AutomotiveProductCategoryWithInventoryModel({
    this.sId,
    this.name,
    this.key,
    this.isActive,
    this.parentId,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.description,
    this.image,
    this.children,
  });

  AutomotiveProductCategoryWithInventoryModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    description = json['description'];
    image = json['image'];

    if (json['children'] != null) {
      children = <AutomotiveProductCategoryWithInventoryModel>[];
      json['children'].forEach((v) {
        children!.add(AutomotiveProductCategoryWithInventoryModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['key'] = key;
    data['isActive'] = isActive;
    data['parentId'] = parentId;
    data['level'] = level;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['description'] = description;
    data['image'] = image;
    if (children != null) {
      data['children'] = children!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
