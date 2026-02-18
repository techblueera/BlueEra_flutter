import 'package:BlueEra/core/constants/app_enum.dart';

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
  String? imageUrl;
  String? tagId;
  List<SubCategories>? subCategories;

  BusinessType? businessType; // custom business type

  CategoryData(
      {this.type,
        this.id,
        this.name,
        this.imageUrl,
        this.tagId,
        this.subCategories,
        this.businessType,
      });

  CategoryData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    id = json['_id'];
    name = json['name'];
    imageUrl = json['image_url'];
    tagId = json['tag_id'];
    if (json['subcategories'] != null) {
      subCategories = <SubCategories>[];
      json['subcategories'].forEach((v) {
        subCategories!.add(new SubCategories.fromJson(v));
      });
    }
    businessType = json['businessType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['_id'] = this.id;
    data['name'] = this.name;
    data['image_url'] = this.imageUrl;
    data['tag_id'] = this.tagId;
    if (this.subCategories != null) {
      data['subcategories'] =
          this.subCategories!.map((v) => v.toJson()).toList();
    }
    data['businessType'] = this.businessType;
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