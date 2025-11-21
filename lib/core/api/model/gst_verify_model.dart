import 'dart:convert';
GstVerifyModel gstVerifyModelFromJson(String str) => GstVerifyModel.fromJson(json.decode(str));
String gstVerifyModelToJson(GstVerifyModel data) => json.encode(data.toJson());
class GstVerifyModel {
  GstVerifyModel({
      this.success, 
      this.isVerified, 
      this.data,});

  GstVerifyModel.fromJson(dynamic json) {
    success = json['success'];
    isVerified = json['is_verified'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  bool? success;
  bool? isVerified;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['is_verified'] = isVerified;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.gstin, 
      this.tradeName,
      this.registrationDate,
  });

  Data.fromJson(dynamic json) {
    gstin = json['gstin'];
    tradeName = json['tradeName'];
    registrationDate = json['registrationDate'];
  }
  String? gstin;
  String? tradeName;
  String? registrationDate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['gstin'] = gstin;
    map['tradeName'] = tradeName;
    map['registrationDate'] = registrationDate;

    return map;
  }

}
