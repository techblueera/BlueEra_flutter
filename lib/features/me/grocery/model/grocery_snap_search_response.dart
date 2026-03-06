import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';

class GrocerySnapSearchResponseModel {
  bool? success;
  String? message;
  ProductSnapSearchData? data;

  GrocerySnapSearchResponseModel({this.success, this.message, this.data});

  GrocerySnapSearchResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new ProductSnapSearchData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ProductSnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<FoundProducts>? foundProducts;
  List<MissingProducts>? missingProducts;

  ProductSnapSearchData(
      {this.totalDetected,
        this.foundCount,
        this.missingCount,
        this.foundProducts,
        this.missingProducts});

  ProductSnapSearchData.fromJson(Map<String, dynamic> json) {
    totalDetected = json['totalDetected'];
    foundCount = json['foundCount'];
    missingCount = json['missingCount'];
    if (json['foundProducts'] != null) {
      foundProducts = <FoundProducts>[];
      json['foundProducts'].forEach((v) {
        foundProducts!.add(new FoundProducts.fromJson(v));
      });
    }
    if (json['missingProducts'] != null) {
      missingProducts = <MissingProducts>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(new MissingProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalDetected'] = this.totalDetected;
    data['foundCount'] = this.foundCount;
    data['missingCount'] = this.missingCount;
    if (this.foundProducts != null) {
      data['foundProducts'] =
          this.foundProducts!.map((v) => v.toJson()).toList();
    }
    if (this.missingProducts != null) {
      data['missingProducts'] =
          this.missingProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FoundProducts {
  String? aiIdentifiedAs;
  ProductDetails? productDetails;
  List<VariantsData>? variants;

  FoundProducts({this.aiIdentifiedAs, this.productDetails, this.variants});

  FoundProducts.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];
    productDetails = json['productDetails'] != null
        ? new ProductDetails.fromJson(json['productDetails'])
        : null;
    if (json['variants'] != null) {
      variants = <VariantsData>[];
      json['variants'].forEach((v) {
        variants!.add(new VariantsData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['aiIdentifiedAs'] = this.aiIdentifiedAs;
    if (this.productDetails != null) {
      data['productDetails'] = this.productDetails!.toJson();
    }
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductDetails {
  String? sId;
  String? name;
  String? description;
  String? brand;
  String? category;
  List<String>? tags;
  List<Images>? images;
  bool? isActive;
  bool? isVegetarian;
  String? countryOfOrigin;
  NutritionalInfo? nutritionalInfo;
  ManufacturerDetails? manufacturerDetails;
  String? createdAt;
  String? updatedAt;
  int? iV;
  double? score;

  ProductDetails(
      {this.sId,
        this.name,
        this.description,
        this.brand,
        this.category,
        this.tags,
        this.images,
        this.isActive,
        this.isVegetarian,
        this.countryOfOrigin,
        this.nutritionalInfo,
        this.manufacturerDetails,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.score});

  ProductDetails.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    category = json['category'];
    tags = json['tags'].cast<String>();
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
      });
    }
    isActive = json['isActive'];
    isVegetarian = json['isVegetarian'];
    countryOfOrigin = json['countryOfOrigin'];
    nutritionalInfo = json['nutritionalInfo'] != null
        ? new NutritionalInfo.fromJson(json['nutritionalInfo'])
        : null;
    manufacturerDetails = json['manufacturerDetails'] != null
        ? new ManufacturerDetails.fromJson(json['manufacturerDetails'])
        : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    score = json['score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['brand'] = this.brand;
    data['category'] = this.category;
    data['tags'] = this.tags;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    data['isActive'] = this.isActive;
    data['isVegetarian'] = this.isVegetarian;
    data['countryOfOrigin'] = this.countryOfOrigin;
    if (this.nutritionalInfo != null) {
      data['nutritionalInfo'] = this.nutritionalInfo!.toJson();
    }
    if (this.manufacturerDetails != null) {
      data['manufacturerDetails'] = this.manufacturerDetails!.toJson();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['score'] = this.score;
    return data;
  }
}

class Images {
  String? url;
  String? sId;

  Images({this.url, this.sId});

  Images.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['_id'] = this.sId;
    return data;
  }
}

class NutritionalInfo {
  String? calories;
  String? protein;
  String? carbohydrates;
  String? fiber;
  String? fat;

  NutritionalInfo(
      {this.calories, this.protein, this.carbohydrates, this.fiber, this.fat});

  NutritionalInfo.fromJson(Map<String, dynamic> json) {
    calories = json['calories'];
    protein = json['protein'];
    carbohydrates = json['carbohydrates'];
    fiber = json['fiber'];
    fat = json['fat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['calories'] = this.calories;
    data['protein'] = this.protein;
    data['carbohydrates'] = this.carbohydrates;
    data['fiber'] = this.fiber;
    data['fat'] = this.fat;
    return data;
  }
}

class ManufacturerDetails {
  String? name;
  String? address;
  String? customerCare;

  ManufacturerDetails({this.name, this.address, this.customerCare});

  ManufacturerDetails.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    customerCare = json['customerCare'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['address'] = this.address;
    data['customerCare'] = this.customerCare;
    return data;
  }
}

class MissingProducts {
  String? name;
  String? brand;
  String? searchKeywords;

  MissingProducts({this.name, this.brand, this.searchKeywords});

  MissingProducts.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['brand'] = this.brand;
    data['searchKeywords'] = this.searchKeywords;
    return data;
  }
}