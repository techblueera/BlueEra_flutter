class ChildrenOfGroceryCategoryResponse {
  String? sId;
  String? name;
  String? key;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? iV;

  ChildrenOfGroceryCategoryResponse(
      {this.sId,
        this.name,
        this.key,
        this.isActive,
        this.parentId,
        this.level,
        this.createdAt,
        this.updatedAt,
        this.iV});

  ChildrenOfGroceryCategoryResponse.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['key'] = this.key;
    data['isActive'] = this.isActive;
    data['parentId'] = this.parentId;
    data['level'] = this.level;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }

  static List<ChildrenOfGroceryCategoryResponse> fromJsonList(List<dynamic> list) =>
      list.map((e) => ChildrenOfGroceryCategoryResponse.fromJson(e as Map<String, dynamic>)).toList();
}