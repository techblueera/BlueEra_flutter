import 'dart:convert';
GeneratePresignedUrl generatePresignedUrlFromJson(String str) => GeneratePresignedUrl.fromJson(json.decode(str));
String generatePresignedUrlToJson(GeneratePresignedUrl data) => json.encode(data.toJson());
class GeneratePresignedUrl {
  GeneratePresignedUrl({
      this.success, 
      this.message, 
      this.data,});

  GeneratePresignedUrl.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  bool? success;
  String? message;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
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
      this.uploadUrl, 
      this.publicUrl,
      this.key,});

  Data.fromJson(dynamic json) {
    publicUrl = json['publicUrl'];
    uploadUrl = json['uploadUrl'];
    key = json['key'];
  }
  String? uploadUrl;
  String? key;
  String? publicUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['publicUrl'] = publicUrl;
    map['uploadUrl'] = uploadUrl;
    map['key'] = key;
    return map;
  }

}