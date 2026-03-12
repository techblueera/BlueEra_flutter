// import 'dart:convert';
// NewMedicalProductModel newMedicalProductModelFromJson(String str) => NewMedicalProductModel.fromJson(json.decode(str));
// String newMedicalProductModelToJson(NewMedicalProductModel data) => json.encode(data.toJson());
// class NewMedicalProductModel {
//   NewMedicalProductModel({
//       this.success,
//       this.data,
//       this.pagination,});
//
//   NewMedicalProductModel.fromJson(dynamic json) {
//     success = json['success'];
//     if (json['data'] != null) {
//       data = [];
//       json['data'].forEach((v) {
//         data?.add(MedicalProductData.fromJson(v));
//       });
//     }
//     pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
//   }
//   bool? success;
//   List<MedicalProductData>? data;
//   Pagination? pagination;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['success'] = success;
//     if (data != null) {
//       map['data'] = data?.map((v) => v.toJson()).toList();
//     }
//     if (pagination != null) {
//       map['pagination'] = pagination?.toJson();
//     }
//     return map;
//   }
//
// }
//
// Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
// String paginationToJson(Pagination data) => json.encode(data.toJson());
// class Pagination {
//   Pagination({
//       this.total,
//       this.page,
//       this.limit,
//       this.totalPages,});
//
//   Pagination.fromJson(dynamic json) {
//     total = json['total'];
//     page = json['page'];
//     limit = json['limit'];
//     totalPages = json['totalPages'];
//   }
//   int? total;
//   int? page;
//   int? limit;
//   int? totalPages;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['total'] = total;
//     map['page'] = page;
//     map['limit'] = limit;
//     map['totalPages'] = totalPages;
//     return map;
//   }
//
// }
//
// MedicalProductData dataFromJson(String str) => MedicalProductData.fromJson(json.decode(str));
// String dataToJson(Data data) => json.encode(data.toJson());
// class MedicalProductData {
//   MedicalProductData({
//       this.id,
//       this.brand,
//       this.name,
//       this.v,
//       this.category,
//       this.contraindications,
//       this.countryOfOrigin,
//       this.createdAt,
//       this.drugInteractions,
//       this.filterKeywords,
//       this.images,
//       this.indications,
//       this.isActive,
//       this.isVegetarian,
//       this.isPrescriptionRequired,
//       this.sideEffects,
//       this.tags,
//       this.updatedAt,
//       this.variants,});
//
//   MedicalProductData.fromJson(dynamic json) {
//     id = json['_id'];
//     brand = json['brand'];
//     name = json['name'];
//     v = json['__v'];
//     category = json['category'] != null ? Category.fromJson(json['category']) : null;
//     if (json['contraindications'] != null) {
//       contraindications = [];
//       json['contraindications'].forEach((v) {
//         contraindications?.add(Dynamic.fromJson(v));
//       });
//     }
//     countryOfOrigin = json['countryOfOrigin'];
//     createdAt = json['createdAt'];
//     if (json['drug_interactions'] != null) {
//       drugInteractions = [];
//       json['drug_interactions'].forEach((v) {
//         drugInteractions?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['filterKeywords'] != null) {
//       filterKeywords = [];
//       json['filterKeywords'].forEach((v) {
//         filterKeywords?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['images'] != null) {
//       images = [];
//       json['images'].forEach((v) {
//         images?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['indications'] != null) {
//       indications = [];
//       json['indications'].forEach((v) {
//         indications?.add(Dynamic.fromJson(v));
//       });
//     }
//     isActive = json['isActive'];
//     isVegetarian = json['isVegetarian'];
//     isPrescriptionRequired = json['is_prescription_required'];
//     if (json['side_effects'] != null) {
//       sideEffects = [];
//       json['side_effects'].forEach((v) {
//         sideEffects?.add(Dynamic.fromJson(v));
//       });
//     }
//     if (json['tags'] != null) {
//       tags = [];
//       json['tags'].forEach((v) {
//         tags?.add(Dynamic.fromJson(v));
//       });
//     }
//     updatedAt = json['updatedAt'];
//     if (json['variants'] != null) {
//       variants = [];
//       json['variants'].forEach((v) {
//         variants?.add(Dynamic.fromJson(v));
//       });
//     }
//   }
//   String? id;
//   String? brand;
//   String? name;
//   int? v;
//   Category? category;
//   List<dynamic>? contraindications;
//   String? countryOfOrigin;
//   String? createdAt;
//   List<dynamic>? drugInteractions;
//   List<dynamic>? filterKeywords;
//   List<dynamic>? images;
//   List<dynamic>? indications;
//   bool? isActive;
//   bool? isVegetarian;
//   bool? isPrescriptionRequired;
//   List<dynamic>? sideEffects;
//   List<dynamic>? tags;
//   String? updatedAt;
//   List<dynamic>? variants;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['brand'] = brand;
//     map['name'] = name;
//     map['__v'] = v;
//     if (category != null) {
//       map['category'] = category?.toJson();
//     }
//     if (contraindications != null) {
//       map['contraindications'] = contraindications?.map((v) => v.toJson()).toList();
//     }
//     map['countryOfOrigin'] = countryOfOrigin;
//     map['createdAt'] = createdAt;
//     if (drugInteractions != null) {
//       map['drug_interactions'] = drugInteractions?.map((v) => v.toJson()).toList();
//     }
//     if (filterKeywords != null) {
//       map['filterKeywords'] = filterKeywords?.map((v) => v.toJson()).toList();
//     }
//     if (images != null) {
//       map['images'] = images?.map((v) => v.toJson()).toList();
//     }
//     if (indications != null) {
//       map['indications'] = indications?.map((v) => v.toJson()).toList();
//     }
//     map['isActive'] = isActive;
//     map['isVegetarian'] = isVegetarian;
//     map['is_prescription_required'] = isPrescriptionRequired;
//     if (sideEffects != null) {
//       map['side_effects'] = sideEffects?.map((v) => v.toJson()).toList();
//     }
//     if (tags != null) {
//       map['tags'] = tags?.map((v) => v.toJson()).toList();
//     }
//     map['updatedAt'] = updatedAt;
//     if (variants != null) {
//       map['variants'] = variants?.map((v) => v.toJson()).toList();
//     }
//     return map;
//   }
//
// }
//
// Category categoryFromJson(String str) => Category.fromJson(json.decode(str));
// String categoryToJson(Category data) => json.encode(data.toJson());
// class Category {
//   Category({
//       this.id,
//       this.name,
//       this.key,
//       this.parentId,
//       this.level,});
//
//   Category.fromJson(dynamic json) {
//     id = json['_id'];
//     name = json['name'];
//     key = json['key'];
//     parentId = json['parentId'] != null ? ParentId.fromJson(json['parentId']) : null;
//     level = json['level'];
//   }
//   String? id;
//   String? name;
//   String? key;
//   ParentId? parentId;
//   int? level;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['name'] = name;
//     map['key'] = key;
//     if (parentId != null) {
//       map['parentId'] = parentId?.toJson();
//     }
//     map['level'] = level;
//     return map;
//   }
//
// }
//
// ParentId parentIdFromJson(String str) => ParentId.fromJson(json.decode(str));
// String parentIdToJson(ParentId data) => json.encode(data.toJson());
// class ParentId {
//   ParentId({
//       this.id,
//       this.name,
//       this.key,
//       this.parentId,
//       this.level,});
//
//   ParentId.fromJson(dynamic json) {
//     id = json['_id'];
//     name = json['name'];
//     key = json['key'];
//     parentId = json['parentId'] != null ? ParentId.fromJson(json['parentId']) : null;
//     level = json['level'];
//   }
//   String? id;
//   String? name;
//   String? key;
//   ParentId? parentId;
//   int? level;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['name'] = name;
//     map['key'] = key;
//     if (parentId != null) {
//       map['parentId'] = parentId?.toJson();
//     }
//     map['level'] = level;
//     return map;
//   }
//
// }
//
// ParentId parentIdFromJson(String str) => ParentId.fromJson(json.decode(str));
// String parentIdToJson(ParentId data) => json.encode(data.toJson());
// class ParentId {
//   ParentId({
//       this.id,
//       this.name,
//       this.key,
//       this.parentId,
//       this.level,});
//
//   ParentId.fromJson(dynamic json) {
//     id = json['_id'];
//     name = json['name'];
//     key = json['key'];
//     parentId = json['parentId'] != null ? ParentId.fromJson(json['parentId']) : null;
//     level = json['level'];
//   }
//   String? id;
//   String? name;
//   String? key;
//   ParentId? parentId;
//   int? level;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['name'] = name;
//     map['key'] = key;
//     if (parentId != null) {
//       map['parentId'] = parentId?.toJson();
//     }
//     map['level'] = level;
//     return map;
//   }
//
// }
//
// ParentId parentIdFromJson(String str) => ParentId.fromJson(json.decode(str));
// String parentIdToJson(ParentId data) => json.encode(data.toJson());
// class ParentId {
//   ParentId({
//       this.id,
//       this.name,
//       this.key,
//       this.parentId,
//       this.level,});
//
//   ParentId.fromJson(dynamic json) {
//     id = json['_id'];
//     name = json['name'];
//     key = json['key'];
//     parentId = json['parentId'];
//     level = json['level'];
//   }
//   String? id;
//   String? name;
//   String? key;
//   dynamic parentId;
//   int? level;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['name'] = name;
//     map['key'] = key;
//     map['parentId'] = parentId;
//     map['level'] = level;
//     return map;
//   }
//
// }