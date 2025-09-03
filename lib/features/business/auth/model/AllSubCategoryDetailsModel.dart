/// success : true
/// message : "Subcategories fetched successfully"
/// data : [{"_id":"686e69ad99a2fcbabf0d8d59","name":"test1","updated_at":"2025-07-09T13:09:35.526Z","deleted_at":null,"created_by":"686e41359343cd7dc2dab821","updated_by":"686e41359343cd7dc2dab821","category_id":"686e4aba60024f8e3765784e","active":false,"created_at":"2025-07-09T13:07:57.781Z","__v":0},{"_id":"6874bac12205959d281dfdbb","name":"string","updated_at":"2025-07-14T08:07:29.327Z","deleted_at":null,"category_id":"686e4aba60024f8e3765784e","active":false,"created_at":"2025-07-14T08:07:29.327Z","__v":0},{"_id":"6874bb082205959d281dfdbe","name":"Good product","updated_at":"2025-07-14T08:08:40.019Z","deleted_at":null,"category_id":"686e4aba60024f8e3765784e","active":false,"created_at":"2025-07-14T08:08:40.019Z","__v":0}]

class AllSubCategoryDetailsModel {
  AllSubCategoryDetailsModel({
      this.success, 
      this.message, 
      this.data,});

  AllSubCategoryDetailsModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SubCategoryData.fromJson(v));
      });
    }
  }
  bool? success;
  String? message;
  List<SubCategoryData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// _id : "686e69ad99a2fcbabf0d8d59"
/// name : "test1"
/// updated_at : "2025-07-09T13:09:35.526Z"
/// deleted_at : null
/// created_by : "686e41359343cd7dc2dab821"
/// updated_by : "686e41359343cd7dc2dab821"
/// category_id : "686e4aba60024f8e3765784e"
/// active : false
/// created_at : "2025-07-09T13:07:57.781Z"
/// __v : 0

class SubCategoryData {
  SubCategoryData({
      this.id, 
      this.name, 
      this.updatedAt, 
      this.deletedAt, 
      this.createdBy, 
      this.updatedBy, 
      this.categoryId, 
      this.active, 
      this.createdAt, 
      this.v,});

  SubCategoryData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    categoryId = json['category_id'];
    active = json['active'];
    createdAt = json['created_at'];
    v = json['__v'];
  }
  String? id;
  String? name;
  String? updatedAt;
  dynamic deletedAt;
  String? createdBy;
  String? updatedBy;
  String? categoryId;
  bool? active;
  String? createdAt;
  num? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['updated_at'] = updatedAt;
    map['deleted_at'] = deletedAt;
    map['created_by'] = createdBy;
    map['updated_by'] = updatedBy;
    map['category_id'] = categoryId;
    map['active'] = active;
    map['created_at'] = createdAt;
    map['__v'] = v;
    return map;
  }

}