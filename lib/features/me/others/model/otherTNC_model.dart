class OtherTNCModel {
  bool? success;
  List<OtherTNCData>? data;

  OtherTNCModel({this.success, this.data});

  OtherTNCModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <OtherTNCData>[];
      json['data'].forEach((v) {
        data!.add(OtherTNCData.fromJson(v));
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

class OtherTNCData {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? title;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? iV;

  OtherTNCData(
      {this.sId,
      this.userId,
      this.businessProfileId,
      this.title,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.iV});

  OtherTNCData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    title = json['title'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['businessProfileId'] = businessProfileId;
    data['title'] = title;
    data['description'] = description;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
