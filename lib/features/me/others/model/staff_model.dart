class StaffModel {
  bool? success;
  List<StaffData>? data;

  StaffModel({this.success, this.data});

  StaffModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <StaffData>[];
      json['data'].forEach((v) {
        data!.add(StaffData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StaffData {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? name;
  String? position;
  String? qualification;
  String? joinedFrom;
  String? joinedTo;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;

  StaffData({
    this.sId,
    this.userId,
    this.businessProfileId,
    this.name,
    this.position,
    this.qualification,
    this.joinedFrom,
    this.joinedTo,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  StaffData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    joinedFrom = json['joinedFrom'];
    joinedTo = json['joinedTo'];
    imageUrl = json['imageUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['businessProfileId'] = businessProfileId;
    data['name'] = name;
    data['position'] = position;
    data['qualification'] = qualification;
    data['joinedFrom'] = joinedFrom;
    data['joinedTo'] = joinedTo;
    data['imageUrl'] = imageUrl;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
