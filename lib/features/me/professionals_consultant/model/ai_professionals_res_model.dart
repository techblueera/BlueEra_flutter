// import 'dart:convert';
// AiProfessionalsResModel aiProfessionalsResModelFromJson(String str) => AiProfessionalsResModel.fromJson(json.decode(str));
// String aiProfessionalsResModelToJson(AiProfessionalsResModel data) => json.encode(data.toJson());
// class AiProfessionalsResModel {
//   AiProfessionalsResModel({
//       this.success,
//       this.message,
//       this.data,});
//
//   AiProfessionalsResModel.fromJson(dynamic json) {
//     success = json['success'];
//     message = json['message'];
//     data = json['data'] != null ? AiProfessionalsData.fromJson(json['data']) : null;
//   }
//   bool? success;
//   String? message;
//   AiProfessionalsData? data;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['success'] = success;
//     map['message'] = message;
//     if (data != null) {
//       map['data'] = data?.toJson();
//     }
//     return map;
//   }
//
// }
//
// AiProfessionalsData dataFromJson(String str) => AiProfessionalsData.fromJson(json.decode(str));
// String dataToJson(AiProfessionalsData data) => json.encode(data.toJson());
// class AiProfessionalsData {
//   AiProfessionalsData({
//       this.basicDetails,
//       this.about,
//       this.pricing,
//       this.portfolio,});
//
//   AiProfessionalsData.fromJson(dynamic json) {
//     basicDetails = json['basicDetails'] != null ? AiProfessionalsDataBasicDetails.fromJson(json['basicDetails']) : null;
//     about = json['about'] != null ? AiProfessionalsDataAbout.fromJson(json['about']) : null;
//     pricing = json['pricing'] != null ? AiProfessionalsDataPricing.fromJson(json['pricing']) : null;
//     if (json['portfolio'] != null) {
//       portfolio = [];
//       json['portfolio'].forEach((v) {
//         portfolio?.add(AiProfessionalsDataPortfolio.fromJson(v));
//       });
//     }
//   }
//   AiProfessionalsDataBasicDetails? basicDetails;
//   AiProfessionalsDataAbout? about;
//   AiProfessionalsDataPricing? pricing;
//   List<AiProfessionalsDataPortfolio>? portfolio;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     if (basicDetails != null) {
//       map['basicDetails'] = basicDetails?.toJson();
//     }
//     if (about != null) {
//       map['about'] = about?.toJson();
//     }
//     if (pricing != null) {
//       map['pricing'] = pricing?.toJson();
//     }
//     if (portfolio != null) {
//       map['portfolio'] = portfolio?.map((v) => v.toJson()).toList();
//     }
//     return map;
//   }
//
// }
//
// AiProfessionalsDataPortfolio portfolioFromJson(String str) => AiProfessionalsDataPortfolio.fromJson(json.decode(str));
// String portfolioToJson(AiProfessionalsDataPortfolio data) => json.encode(data.toJson());
// class AiProfessionalsDataPortfolio {
//   AiProfessionalsDataPortfolio({
//       this.projectTitle,
//       this.category,
//       this.description,
//       this.teamSize,});
//
//   AiProfessionalsDataPortfolio.fromJson(dynamic json) {
//     projectTitle = json['projectTitle'];
//     category = json['category'];
//     description = json['description'];
//     teamSize = json['teamSize'];
//   }
//   String? projectTitle;
//   String? category;
//   String? description;
//   int? teamSize;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['projectTitle'] = projectTitle;
//     map['category'] = category;
//     map['description'] = description;
//     map['teamSize'] = teamSize;
//     return map;
//   }
//
// }
//
// AiProfessionalsDataPricing pricingFromJson(String str) => AiProfessionalsDataPricing.fromJson(json.decode(str));
// String pricingToJson(AiProfessionalsDataPricing data) => json.encode(data.toJson());
// class AiProfessionalsDataPricing {
//   AiProfessionalsDataPricing({
//       this.amount,
//       this.type,
//       this.consultationMode,});
//
//   AiProfessionalsDataPricing.fromJson(dynamic json) {
//     amount = json['amount'];
//     type = json['type'];
//     consultationMode = json['consultationMode'];
//   }
//   int? amount;
//   String? type;
//   String? consultationMode;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['amount'] = amount;
//     map['type'] = type;
//     map['consultationMode'] = consultationMode;
//     return map;
//   }
//
// }
//
// AiProfessionalsDataAbout aboutFromJson(String str) => AiProfessionalsDataAbout.fromJson(json.decode(str));
// String aboutToJson(AiProfessionalsDataAbout data) => json.encode(data.toJson());
// class AiProfessionalsDataAbout {
//   AiProfessionalsDataAbout({
//       this.totalExperience,
//       this.description,
//       this.majorProjectsDescription,});
//
//   AiProfessionalsDataAbout.fromJson(dynamic json) {
//     totalExperience = json['totalExperience'] != null ? TotalExperience.fromJson(json['totalExperience']) : null;
//     description = json['description'];
//     majorProjectsDescription = json['majorProjectsDescription'];
//   }
//   TotalExperience? totalExperience;
//   String? description;
//   String? majorProjectsDescription;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     if (totalExperience != null) {
//       map['totalExperience'] = totalExperience?.toJson();
//     }
//     map['description'] = description;
//     map['majorProjectsDescription'] = majorProjectsDescription;
//     return map;
//   }
//
// }
//
// TotalExperience totalExperienceFromJson(String str) => TotalExperience.fromJson(json.decode(str));
// String totalExperienceToJson(TotalExperience data) => json.encode(data.toJson());
// class TotalExperience {
//   TotalExperience({
//       this.years,
//       this.months,});
//
//   TotalExperience.fromJson(dynamic json) {
//     years = json['years'];
//     months = json['months'];
//   }
//   int? years;
//   int? months;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['years'] = years;
//     map['months'] = months;
//     return map;
//   }
//
// }
//
// AiProfessionalsDataBasicDetails basicDetailsFromJson(String str) => AiProfessionalsDataBasicDetails.fromJson(json.decode(str));
// String basicDetailsToJson(AiProfessionalsDataBasicDetails data) => json.encode(data.toJson());
// class AiProfessionalsDataBasicDetails {
//   AiProfessionalsDataBasicDetails({
//       this.shortTagline,
//       this.professionalTitle,});
//
//   AiProfessionalsDataBasicDetails.fromJson(dynamic json) {
//     shortTagline = json['shortTagline'];
//     professionalTitle = json['professionalTitle'];
//   }
//   String? shortTagline;
//   String? professionalTitle;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['shortTagline'] = shortTagline;
//     map['professionalTitle'] = professionalTitle;
//     return map;
//   }
//
// }