class ProfessionServiceOfferedResponse {
  bool? success;
  Data? data;

  ProfessionServiceOfferedResponse({this.success, this.data});

  ProfessionServiceOfferedResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? sId;
  String? category;
  int? iV;
  String? createdAt;
  bool? isActive;
  List<String>? servicesOffered;
  String? updatedAt;

  Data(
      {this.sId,
        this.category,
        this.iV,
        this.createdAt,
        this.isActive,
        this.servicesOffered,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    category = json['category'];
    iV = json['__v'];
    createdAt = json['createdAt'];
    isActive = json['isActive'];
    servicesOffered = json['servicesOffered'].cast<String>();
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['category'] = this.category;
    data['__v'] = this.iV;
    data['createdAt'] = this.createdAt;
    data['isActive'] = this.isActive;
    data['servicesOffered'] = this.servicesOffered;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}