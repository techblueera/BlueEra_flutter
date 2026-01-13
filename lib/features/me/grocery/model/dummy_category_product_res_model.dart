import 'dart:convert';
DummyCategoryProductResModel dummyCategoryProductResModelFromJson(String str) => DummyCategoryProductResModel.fromJson(json.decode(str));
String dummyCategoryProductResModelToJson(DummyCategoryProductResModel data) => json.encode(data.toJson());
class DummyCategoryProductResModel {
  DummyCategoryProductResModel({
      this.categories, 
      this.products,});

  DummyCategoryProductResModel.fromJson(dynamic json) {
    if (json['categories'] != null) {
      categories = [];
      json['categories'].forEach((v) {
        categories?.add(DummyCategories.fromJson(v));
      });
    }
    if (json['products'] != null) {
      products = [];
      json['products'].forEach((v) {
        products?.add(DummyProducts.fromJson(v));
      });
    }
  }
  List<DummyCategories>? categories;
  List<DummyProducts>? products;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (categories != null) {
      map['categories'] = categories?.map((v) => v.toJson()).toList();
    }
    if (products != null) {
      map['products'] = products?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

DummyProducts productsFromJson(String str) => DummyProducts.fromJson(json.decode(str));
String productsToJson(DummyProducts data) => json.encode(data.toJson());
class DummyProducts {
  DummyProducts({
      this.id, 
      this.categoryId, 
      this.name, 
      this.description, 
      this.imageUrl, 
      this.isVeg, 
      this.tag, 
      this.variants,});

  DummyProducts.fromJson(dynamic json) {
    id = json['id'];
    categoryId = json['categoryId'];
    name = json['name'];
    description = json['description'];
    imageUrl = json['imageUrl'];
    isVeg = json['isVeg'];
    tag = json['tag'];
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants?.add(Variants.fromJson(v));
      });
    }
  }
  String? id;
  String? categoryId;
  String? name;
  String? description;
  String? imageUrl;
  bool? isVeg;
  String? tag;
  List<Variants>? variants;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['categoryId'] = categoryId;
    map['name'] = name;
    map['description'] = description;
    map['imageUrl'] = imageUrl;
    map['isVeg'] = isVeg;
    map['tag'] = tag;
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Variants variantsFromJson(String str) => Variants.fromJson(json.decode(str));
String variantsToJson(Variants data) => json.encode(data.toJson());
class Variants {
  Variants({
      this.name, 
      this.weight, 
      this.price, 
      this.mrp,});

  Variants.fromJson(dynamic json) {
    name = json['name'];
    weight = json['weight'];
    price = json['price'];
    mrp = json['mrp'];
  }
  String? name;
  String? weight;
  int? price;
  int? mrp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['weight'] = weight;
    map['price'] = price;
    map['mrp'] = mrp;
    return map;
  }

}

DummyCategories categoriesFromJson(String str) => DummyCategories.fromJson(json.decode(str));
String categoriesToJson(DummyCategories data) => json.encode(data.toJson());
class DummyCategories {
  DummyCategories({
      this.id, 
      this.name, 
      this.image,});

  DummyCategories.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
  }
  String? id;
  String? name;
  String? image;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['image'] = image;
    return map;
  }

}