import 'dart:convert';
ServiceAiGenerateModel serviceAiGenerateModelFromJson(String str) => ServiceAiGenerateModel.fromJson(json.decode(str));
String serviceAiGenerateModelToJson(ServiceAiGenerateModel data) => json.encode(data.toJson());
class ServiceAiGenerateModel {
  ServiceAiGenerateModel({
      this.serviceName, 
      this.category, 
      this.subCategory, 
      this.serviceDescription, 
      this.serviceFacilities, 
      this.userGuide, 
      this.possibleVariants, 
      this.possibleAddOns,});

  ServiceAiGenerateModel.fromJson(dynamic json) {
    serviceName = json['service_name'];
    category = json['category'];
    subCategory = json['sub_category'];
    serviceDescription = json['service_description'];
    serviceFacilities = json['service_facilities'] != null ? json['service_facilities'].cast<String>() : [];
    userGuide = json['user_guide'] != null ? json['user_guide'].cast<String>() : [];
    possibleVariants = json['possible_variants'] != null ? json['possible_variants'].cast<String>() : [];
    possibleAddOns = json['possible_add_ons'] != null ? json['possible_add_ons'].cast<String>() : [];
  }
  String? serviceName;
  String? category;
  String? subCategory;
  String? serviceDescription;
  List<String>? serviceFacilities;
  List<String>? userGuide;
    List<String>? possibleVariants;
  List<String>? possibleAddOns;

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