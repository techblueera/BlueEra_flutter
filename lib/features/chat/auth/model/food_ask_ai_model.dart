import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';

class FoodAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  FoodAskAiModel({
    super.conversationId,
    super.role,
    super.timestamp,
    super.message,
    this.data,
  });

  FoodAskAiModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    message = json['reply'] ?? json['content'];
    conversationId = json['conversationId'];
    suggestions = json['suggestions'] != null
        ? List<String>.from(json['suggestions'])
        : null;
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['reply'] = this.message;
    data['conversationId'] = this.conversationId;
    data['suggestions'] = this.suggestions;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['timestamp'] = this.timestamp;
    return data;
  }
}

class Data {
  bool? success;
  List<FoodData>? foodData;
  Pagination? pagination;

  Data({this.success, this.foodData, this.pagination});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      foodData = <FoodData>[];
      json['data'].forEach((v) {
        foodData!.add(new FoodData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.foodData != null) {
      data['data'] = this.foodData!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class FoodData {
  String? sId;
  String? businessId;
  ProductVariant? productVariant;
  Product? product;
  Location? location;
  Price? price;
  bool? isAvailable;
  int? preparationTime;
  int? rating;
  int? iV;
  String? createdAt;
  String? updatedAt;

  FoodData(
      {this.sId,
        this.businessId,
        this.productVariant,
        this.product,
        this.location,
        this.price,
        this.isAvailable,
        this.preparationTime,
        this.rating,
        this.iV,
        this.createdAt,
        this.updatedAt});

  FoodData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    productVariant = json['productVariant'] != null
        ? new ProductVariant.fromJson(json['productVariant'])
        : null;
    product =
    json['product'] != null ? new Product.fromJson(json['product']) : null;
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    price = json['price'] != null ? new Price.fromJson(json['price']) : null;
    isAvailable = json['isAvailable'];
    preparationTime = json['preparationTime'];
    rating = json['rating'];
    iV = json['__v'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    if (this.productVariant != null) {
      data['productVariant'] = this.productVariant!.toJson();
    }
    if (this.product != null) {
      data['product'] = this.product!.toJson();
    }
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    if (this.price != null) {
      data['price'] = this.price!.toJson();
    }
    data['isAvailable'] = this.isAvailable;
    data['preparationTime'] = this.preparationTime;
    data['rating'] = this.rating;
    data['__v'] = this.iV;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}

class ProductVariant {
  String? sId;
  String? variantName;
  String? quantityLabel;

  ProductVariant({this.sId, this.variantName, this.quantityLabel});

  ProductVariant.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    variantName = json['variantName'];
    quantityLabel = json['quantityLabel'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['variantName'] = this.variantName;
    data['quantityLabel'] = this.quantityLabel;
    return data;
  }
}

class Product {
  String? sId;
  String? name;
  String? description;
  List<String>? images;
  String? dietaryType;

  Product(
      {this.sId, this.name, this.description, this.images, this.dietaryType});

  Product.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    images = json['images'].cast<String>();
    dietaryType = json['dietaryType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['images'] = this.images;
    data['dietaryType'] = this.dietaryType;
    return data;
  }
}

class Location {
  String? type;
  List<double>? coordinates;
  String? address;
  String? pincode;

  Location({this.type, this.coordinates, this.address, this.pincode});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates'].cast<double>();
    address = json['address'];
    pincode = json['pincode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    data['address'] = this.address;
    data['pincode'] = this.pincode;
    return data;
  }
}

class Price {
  int? mrp;
  int? sellingPrice;
  String? currency;
  int? packingCharges;

  Price({this.mrp, this.sellingPrice, this.currency, this.packingCharges});

  Price.fromJson(Map<String, dynamic> json) {
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    packingCharges = json['packingCharges'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    data['currency'] = this.currency;
    data['packingCharges'] = this.packingCharges;
    return data;
  }
}

class Pagination {
  String? currentPage;
  int? totalPages;
  int? totalResults;
  String? limit;

  Pagination(
      {this.currentPage, this.totalPages, this.totalResults, this.limit});

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    totalResults = json['totalResults'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    data['totalResults'] = this.totalResults;
    data['limit'] = this.limit;
    return data;
  }
}
