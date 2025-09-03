class VideoCategoryResponse {
  bool? success;
  List<VideoCategoryData>? data;

  VideoCategoryResponse({this.success, this.data});

  VideoCategoryResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <VideoCategoryData>[];
      json['data'].forEach((v) {
        data!.add(new VideoCategoryData.fromJson(v));
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

class VideoCategoryData {
  String? sId;
  String? name;
  String? slug;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? iV;

  VideoCategoryData(
      {this.sId,
        this.name,
        this.slug,
        this.description,
        this.createdAt,
        this.updatedAt,
        this.iV});

  VideoCategoryData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    slug = json['slug'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['slug'] = this.slug;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}