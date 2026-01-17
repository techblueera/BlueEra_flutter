import 'dart:convert';

import 'get_categories_model.dart';


IndividualFieldsResponseModel individualFieldsResponseModelFromJson(String str) =>
    IndividualFieldsResponseModel.fromJson(json.decode(str));

String individualFieldsResponseModelToJson(IndividualFieldsResponseModel data) =>
    json.encode(data.toJson());

class IndividualFieldsResponseModel {
  bool? success;
  IndividualFieldsData? data;

  IndividualFieldsResponseModel({
    this.success,
    this.data,
  });

  factory IndividualFieldsResponseModel.fromJson(Map<String, dynamic> json) =>
      IndividualFieldsResponseModel(
        success: json["success"],
        data: json["data"] == null ? null : IndividualFieldsData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
  };
}

class IndividualFieldsData {
  String? name;
  String? tagId;
  List<IndividualFields>? fields;

  IndividualFieldsData({
    this.name,
    this.tagId,
    this.fields,
  });

  factory IndividualFieldsData.fromJson(Map<String, dynamic> json) => IndividualFieldsData(
    name: json["name"],
    tagId: json["tag_id"],
    fields: json["fields"] == null
        ? []
        : List<IndividualFields>.from(
        json["fields"]!.map((x) => IndividualFields.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "tag_id": tagId,
    "fields": fields == null
        ? []
        : List<dynamic>.from(fields!.map((x) => x.toJson())),
  };
}

class IndividualFields {
  String? name;
  String? tagId;
  List<SubCategories>? subcategories;

  IndividualFields({
    this.name,
    this.tagId,
    this.subcategories,
  });

  factory IndividualFields.fromJson(Map<String, dynamic> json) => IndividualFields(
    name: json["name"],
    tagId: json["tag_id"],
    subcategories: json["subcategories"] == null
        ? []
        : List<SubCategories>.from(
        json["subcategories"]!.map((x) => SubCategories.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "tag_id": tagId,
    "subcategories": subcategories == null
        ? []
        : List<SubCategories>.from(subcategories!.map((x) => x.toJson())),
  };
}
