class AutomotiveSubChildORRootCategoryResponse {
  bool? status;
  List<AutomotiveCategoryData>? data;

  AutomotiveSubChildORRootCategoryResponse({this.status, this.data});

  AutomotiveSubChildORRootCategoryResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <AutomotiveCategoryData>[];
      json['data'].forEach((v) {
        data!.add(new AutomotiveCategoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AutomotiveCategoryData {
  String? sId;
  String? name;
  String? parent;
  bool? root;

  AutomotiveCategoryData({this.sId, this.name, this.parent});

  AutomotiveCategoryData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    parent = json['parent'];
    root = json['root'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['parent'] = this.parent;
    data['root'] = this.root;
    return data;
  }
}