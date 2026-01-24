class OtherDownloadsModel {
  bool? success;
  List<OtherDownloadsData>? data;

  OtherDownloadsModel({this.success, this.data});

  OtherDownloadsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <OtherDownloadsData>[];
      json['data'].forEach((v) {
        data!.add(OtherDownloadsData.fromJson(v));
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

class OtherDownloadsData {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? imageUrl;
  String? title;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? iV;

  OtherDownloadsData(
      {this.sId,
      this.userId,
      this.businessProfileId,
      this.imageUrl,
      this.title,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.iV});

  OtherDownloadsData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrl = json['downloadUrl'];
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
    data['downloadUrl'] = imageUrl;
    data['title'] = title;
    data['description'] = description;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
