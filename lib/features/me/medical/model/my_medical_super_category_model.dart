class MyMedicalSuperCategoryModel {
  String? sId;
  String? name;
  String? key;
  String? description;
  String? image;
  bool? isActive;
  int? level;
  String? createdAt;
  String? updatedAt;

  MyMedicalSuperCategoryModel(
      {this.sId,
        this.name,
        this.key,
        this.description,
        this.image,
        this.isActive,
        this.level,
        this.createdAt,
        this.updatedAt});

  MyMedicalSuperCategoryModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
    description = json['description'];
    image = json['image'];
    isActive = json['isActive'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['key'] = this.key;
    data['description'] = this.description;
    data['image'] = this.image;
    data['isActive'] = this.isActive;
    data['level'] = this.level;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}