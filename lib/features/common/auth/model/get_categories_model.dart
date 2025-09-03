class CategoryModel {
  bool? status;
  List<CategoryData>? data;

  CategoryModel({this.status, this.data});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <CategoryData>[];
      json['data'].forEach((v) {
        data!.add(new CategoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CategoryData {
  String? type;
  String? id;
  String? name;
  String? updatedAt;
  String? createdBy;
  String? updatedBy;
  bool? active;
  String? imageUrl;
  String? createdAt;
  int? iV;
  List<SubCategories>? subCategories;

  CategoryData(
      {this.type,
        this.id,
        this.name,
        this.updatedAt,
        this.createdBy,
        this.updatedBy,
        this.active,
        this.imageUrl,
        this.createdAt,
        this.iV,
        this.subCategories});

  CategoryData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    id = json['_id'];
    name = json['name'];
    updatedAt = json['updated_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    active = json['active'];
    imageUrl = json['image_url'];
    createdAt = json['created_at'];
    iV = json['__v'];
    if (json['subCategories'] != null) {
      subCategories = <SubCategories>[];
      json['subCategories'].forEach((v) {
        subCategories!.add(new SubCategories.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['_id'] = this.id;
    data['name'] = this.name;
    data['updated_at'] = this.updatedAt;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['active'] = this.active;
    data['image_url'] = this.imageUrl;
    data['created_at'] = this.createdAt;
    data['__v'] = this.iV;
    if (this.subCategories != null) {
      data['subCategories'] =
          this.subCategories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubCategories {
  String? sId;
  String? name;

  SubCategories({this.sId, this.name});

  SubCategories.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    return data;
  }
}

// class GetCategoriesModel {
//   bool? status;
//   List<CategoryData>? data;
//
//   GetCategoriesModel({this.status, this.data});
//
//   factory GetCategoriesModel.fromJson(Map<String, dynamic> json) {
//     return GetCategoriesModel(
//       status: json['status'] as bool?,
//       data: (json['data'] as List<dynamic>?)?.map((e) => CategoryData.fromJson(e as Map<String, dynamic>)).toList(),
//     );
//   }
// }
//
// class CategoryData {
//   String? id;
//   String? name;
//   String? type;
//   String? updatedAt;
//   dynamic deletedAt;
//   String? createdBy;
//   String? updatedBy;
//   bool? active;
//   String? imageUrl;
//   String? createdAt;
//   int? v;
//   List<SubCategories>? subCategories;
//
//   CategoryData({
//     this.id,
//     this.name,
//     this.type,
//     this.updatedAt,
//     this.deletedAt,
//     this.createdBy,
//     this.updatedBy,
//     this.active,
//     this.imageUrl,
//     this.createdAt,
//     this.v,
//   });
//
//   factory CategoryData.fromJson(Map<String, dynamic> json) {
//     return CategoryData(
//       id: json['_id'] as String?,
//       name: json['name'] as String?,
//       type: json['type'] as String?,
//       updatedAt: json['updated_at'] as String?,
//       deletedAt: json['deleted_at'],
//       createdBy: json['created_by'] as String?,
//       updatedBy: json['updated_by'] as String?,
//       active: json['active'] as bool?,
//       imageUrl: json['image_url'] as String?,
//       createdAt: json['created_at'] as String?,
//       v: json['__v'] as int?,
//         if (json['subCategories'] != null) {
//       subCategories = <SubCategories>[];
//       json['subCategories'].forEach((v) {
//         subCategories!.add(new SubCategories.fromJson(v));
//       });
//     }
//     );
//   }
// }
// class SubCategories {
//   String? sId;
//   String? name;
//
//   SubCategories({this.sId, this.name});
//
//   SubCategories.fromJson(Map<String, dynamic> json) {
//     sId = json['_id'];
//     name = json['name'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['_id'] = this.sId;
//     data['name'] = this.name;
//     return data;
//   }
// }