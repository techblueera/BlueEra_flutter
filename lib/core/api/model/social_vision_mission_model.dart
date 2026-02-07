class SocialVisionMissionModel {
  bool? success;
  SocialVisionMissionData? data;

  SocialVisionMissionModel({this.success, this.data});

  SocialVisionMissionModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? SocialVisionMissionData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SocialVisionMissionData {
  String? sId;
  String? userId;
  String? description;
  String? mediaType;
  String? mediaUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;

  SocialVisionMissionData(
      {this.sId,
      this.userId,
      this.description,
      this.mediaType,
      this.mediaUrl,
      this.createdAt,
      this.updatedAt,
      this.iV});

  SocialVisionMissionData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    description = json['description'];
    mediaType = json['mediaType'];
    mediaUrl = json['mediaUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['description'] = description;
    data['mediaType'] = mediaType;
    data['mediaUrl'] = mediaUrl;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
