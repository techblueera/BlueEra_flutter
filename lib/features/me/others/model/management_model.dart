class ManagementModel {
  bool? success;
  List<ManagementData>? data;

  ManagementModel({this.success, this.data});

  ManagementModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <ManagementData>[];
      json['data'].forEach((v) {
        data!.add(new ManagementData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ManagementData {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? name;
  String? position;
  String? qualification;
  String? message;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;

  ManagementData(
      {this.sId,
      this.userId,
      this.businessProfileId,
      this.name,
      this.position,
      this.qualification,
      this.message,
      this.imageUrl,
      this.createdAt,
      this.updatedAt,
      this.iV});

  ManagementData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    message = json['message'];
    imageUrl = json['imageUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['businessProfileId'] = this.businessProfileId;
    data['name'] = this.name;
    data['position'] = this.position;
    data['qualification'] = this.qualification;
    data['message'] = this.message;
    data['imageUrl'] = this.imageUrl;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
