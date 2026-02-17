import 'dart:convert';
VisionMissionRes visionMissionResFromJson(String str) => VisionMissionRes.fromJson(json.decode(str));
String visionMissionResToJson(VisionMissionRes data) => json.encode(data.toJson());
class VisionMissionRes {
  bool? success;
  VisionMissionData? data;
  VisionMissionRes({this.success, this.data});
  VisionMissionRes.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? VisionMissionData.fromJson(json['data']) : null;
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
class VisionMissionData {
  String? id;
  String? visionAndMission;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  VisionMissionData({
    this.id,
    this.visionAndMission,
    this.hospitalId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });
  VisionMissionData.fromJson(dynamic json) {
    id = json['_id'];
    visionAndMission = json['visionAndMission'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['visionAndMission'] = visionAndMission;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}
