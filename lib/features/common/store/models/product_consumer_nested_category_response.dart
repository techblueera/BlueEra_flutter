class ProductConsumerNestedCategoryResponse {
  bool? success;
  ProductCategoryFilters? filters;
  int? totalCategories;
  List<ProductNestedCategory>? data;

  ProductConsumerNestedCategoryResponse({
    this.success,
    this.filters,
    this.totalCategories,
    this.data,
  });

  ProductConsumerNestedCategoryResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    filters = json['filters'] != null
        ? ProductCategoryFilters.fromJson(json['filters'])
        : null;
    totalCategories = json['totalCategories'];
    if (json['data'] != null) {
      data = <ProductNestedCategory>[];
      json['data'].forEach((v) {
        data!.add(ProductNestedCategory.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (filters != null) map['filters'] = filters!.toJson();
    map['totalCategories'] = totalCategories;
    if (data != null) map['data'] = data!.map((v) => v.toJson()).toList();
    return map;
  }
}

class ProductCategoryFilters {
  String? group;

  ProductCategoryFilters({this.group});

  ProductCategoryFilters.fromJson(Map<String, dynamic> json) {
    group = json['group'];
  }

  Map<String, dynamic> toJson() {
    return {'group': group};
  }
}

class ProductNestedCategory {
  String? sId;
  String? name;
  String? key;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? group;
  String? subGroup;
  List<ProductNestedCategory>? children;

  ProductNestedCategory({
    this.sId,
    this.name,
    this.key,
    this.isActive,
    this.parentId,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.group,
    this.subGroup,
    this.children,
  });

  ProductNestedCategory.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    group = json['group'];
    subGroup = json['subGroup'];
    if (json['children'] != null) {
      children = <ProductNestedCategory>[];
      json['children'].forEach((v) {
        children!.add(ProductNestedCategory.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = sId;
    map['name'] = name;
    map['key'] = key;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = iV;
    map['group'] = group;
    map['subGroup'] = subGroup;
    if (children != null) {
      map['children'] = children!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
