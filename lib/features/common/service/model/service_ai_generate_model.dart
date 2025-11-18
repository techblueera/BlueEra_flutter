import 'dart:convert';

ServiceAiGenerateModel serviceAiGenerateModelFromJson(String str) =>
    ServiceAiGenerateModel.fromJson(json.decode(str));

String serviceAiGenerateModelToJson(ServiceAiGenerateModel data) =>
    json.encode(data.toJson());

class ServiceAiGenerateModel {
  String? serviceName;
  String? category;
  String? subCategory;
  String? serviceDescription;
  List<String>? serviceFacilities;
  List<String>? userGuide;
  List<String>? possibleVariants;
  List<String>? possibleAddOns;

  ServiceAiGenerateModel({
    this.serviceName,
    this.category,
    this.subCategory,
    this.serviceDescription,
    this.serviceFacilities,
    this.userGuide,
    this.possibleVariants,
    this.possibleAddOns,
  });

  ServiceAiGenerateModel.fromJson(Map<String, dynamic> json) {
    serviceName = json['service_name']?.toString();
    category = json['category']?.toString();
    subCategory = json['sub_category']?.toString();
    serviceDescription = json['service_description']?.toString();

    if (json['service_facilities'] != null && json['service_facilities'] is List) {
      serviceFacilities = List<String>.from(
          (json['service_facilities'] as List).map((e) => e.toString()));
    }

    if (json['user_guide'] != null && json['user_guide'] is List) {
      userGuide =
      List<String>.from((json['user_guide'] as List).map((e) => e.toString()));
    }

    if (json['possible_variants'] != null && json['possible_variants'] is List) {
      possibleVariants = List<String>.from(
          (json['possible_variants'] as List).map((e) => e.toString()));
    }

    if (json['possible_add_ons'] != null && json['possible_add_ons'] is List) {
      possibleAddOns = List<String>.from(
          (json['possible_add_ons'] as List).map((e) => e.toString()));
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['service_name'] = serviceName;
    map['category'] = category;
    map['sub_category'] = subCategory;
    map['service_description'] = serviceDescription;
    map['service_facilities'] = serviceFacilities;
    map['user_guide'] = userGuide;
    map['possible_variants'] = possibleVariants;
    map['possible_add_ons'] = possibleAddOns;
    return map;
  }
}
