import 'dart:convert';
HospitalHistoryRes hospitalHistoryResFromJson(String str) => HospitalHistoryRes.fromJson(json.decode(str));
String hospitalHistoryResToJson(HospitalHistoryRes data) => json.encode(data.toJson());
class HospitalHistoryRes {
  bool? success;
  HospitalHistoryData? data;
  HospitalHistoryRes({this.success, this.data});
  HospitalHistoryRes.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? HospitalHistoryData.fromJson(json['data']) : null;
  }
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}
class HospitalHistoryData {
  String? id;
  String? history;
  String? imageUrl;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  HospitalHistoryData({
    this.id,
    this.history,
    this.imageUrl,
    this.hospitalId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });
  HospitalHistoryData.fromJson(dynamic json) {
    id = json['_id'];
    history = json['history'];
    imageUrl = json['imageUrl'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['history'] = history;
    map['imageUrl'] = imageUrl;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}
