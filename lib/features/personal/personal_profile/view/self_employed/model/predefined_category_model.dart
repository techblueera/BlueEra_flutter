class PredefinedCategoryModel {
  String? category;
  String? segment;
  List<String>? items;

  PredefinedCategoryModel({this.category, this.segment, this.items});

  PredefinedCategoryModel.fromJson(Map<String, dynamic> json) {
    category = json['category'];
    segment = json['segment'];
    items = json['items'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category'] = this.category;
    data['segment'] = this.segment;
    data['items'] = this.items;
    return data;
  }
}