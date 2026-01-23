class AboutOrganisationModel {
  bool? success;
  List<AboutOrganisationData>? data;

  AboutOrganisationModel({this.success, this.data});

  AboutOrganisationModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <AboutOrganisationData>[];
      json['data'].forEach((v) {
        data!.add(AboutOrganisationData.fromJson(v));
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

class AboutOrganisationData {
  String? sId;
  String? userId;
  String? businessProfileId;
  String? imageUrl;
  String? title;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? iV;

  AboutOrganisationData(
      {this.sId,
      this.userId,
      this.businessProfileId,
      this.imageUrl,
      this.title,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.iV});

  AboutOrganisationData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrl = json['imageUrl'];
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
    data['imageUrl'] = imageUrl;
    data['title'] = title;
    data['description'] = description;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
