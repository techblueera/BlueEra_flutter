import 'dart:convert';

import 'package:BlueEra/core/constants/app_enum.dart';

PersonalProfessionModel personalProfessionModelFromJson(String str) =>
    PersonalProfessionModel.fromJson(json.decode(str));

String personalProfessionModelToJson(PersonalProfessionModel data) =>
    json.encode(data.toJson());

class PersonalProfessionModel {
  PersonalProfessionModel({
    this.data,
    this.status,
  });

  PersonalProfessionModel.fromJson(dynamic json) {
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(ProfessionTypeData.fromJson(v));
      });
    }
    status = json['status'];
  }

  List<ProfessionTypeData>? data;
  bool? status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['status'] = status;
    return map;
  }
}

ProfessionTypeData dataFromJson(String str) =>
    ProfessionTypeData.fromJson(json.decode(str));

String dataToJson(ProfessionTypeData data) => json.encode(data.toJson());

class ProfessionTypeData {
  ProfessionTypeData({
    this.id,
    this.name,
    this.tagId,
    this.profileType,
    this.imageUrl,
    this.subcategoriesFiledName,
    this.individualProfileType,
  });

  ProfessionTypeData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    tagId = json['tag_id'];
    profileType = json['profileType'];
    imageUrl = json['image_url'];

    if (json['subcategories_filedName'] != null) {
      subcategoriesFiledName = [];
      json['subcategories_filedName'].forEach((v) {
        subcategoriesFiledName?.add(SubcategoriesFiledName.fromJson(v));
      });
    }
    individualProfileType = json['individualProfileType'];
    isActive = json['isActive'];
    deletedAt = json['deletedAt']?.toString();
  }

  String? id;
  String? name;
  String? tagId;
  String? profileType;
  String? imageUrl;
  List<SubcategoriesFiledName>? subcategoriesFiledName;
  IndividualProfileType? individualProfileType;  // custom Individual Profile type

  /// Retired professions come back with `isActive: false`, soft-deleted ones
  /// with a non-null `deletedAt`. `GET individual-professions` returns BOTH —
  /// it does not filter server-side the way the business categories endpoint
  /// does — and the profile-category change endpoint rejects them with
  /// `422 unknown_category`. Any picker built on this list must drop them
  /// (see [isSelectable]) or it offers options that always fail.
  bool? isActive;
  String? deletedAt;

  /// Whether this profession may be OFFERED to a user. Absent flags mean
  /// active: the field is omitted for ordinary rows, so defaulting the other
  /// way would empty the picker.
  bool get isSelectable => isActive != false && deletedAt == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['tag_id'] = tagId;
    map['profileType'] = profileType;
    map['image_url'] = imageUrl;

    if (subcategoriesFiledName != null) {
      map['subcategories_filedName'] =
          subcategoriesFiledName?.map((v) => v.toJson()).toList();
    }
    map['individualProfileType'] = individualProfileType;
    // Round-tripped so the Hive cache keeps them: the catalog is persisted and
    // read back cache-first, and a cached row that lost these flags would let
    // a retired profession back into the picker on the next cold start.
    map['isActive'] = isActive;
    map['deletedAt'] = deletedAt;
    return map;
  }
}

SubcategoriesFiledName subcategoriesFiledNameFromJson(String str) =>
    SubcategoriesFiledName.fromJson(json.decode(str));

String subcategoriesFiledNameToJson(SubcategoriesFiledName data) =>
    json.encode(data.toJson());

class SubcategoriesFiledName {
  SubcategoriesFiledName({
    this.name,
    this.tagId,
    this.id,
  });

  SubcategoriesFiledName.fromJson(dynamic json) {
    name = json['name'];
    tagId = json['tag_id'];
    id = json['_id'];
  }

  String? name;
  String? tagId;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['tag_id'] = tagId;
    map['_id'] = id;
    return map;
  }
}
