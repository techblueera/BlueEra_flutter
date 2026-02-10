import 'dart:convert';
import '../../../../../core/api/model/images.dart';

List<MedicalOrdersModel> groceryOrdersModelFromList(List<dynamic> data) =>
    List<MedicalOrdersModel>.from(
        data.map((x) => MedicalOrdersModel.fromJson(x)));

String groceryOrdersModelToJson(List<MedicalOrdersModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MedicalOrdersModel {
  String? orderId;
  String? groceryOrderId;
  String? riderName;
  String? customerName;
  int? totalItems;
  num? totalPrice; // Changed to int based on JSON, use num or double if decimals expected
  String? createdAt;
  bool? isAvailabilityUpdated;
  num? missingItemsCount;
  List<GroceryItem>? items;

  MedicalOrdersModel({
    this.orderId,
    this.groceryOrderId,
    this.riderName,
    this.customerName,
    this.totalItems,
    this.totalPrice,
    this.isAvailabilityUpdated,
    this.createdAt,
    this.missingItemsCount,
    this.items,
  });

  factory MedicalOrdersModel.fromJson(Map<String, dynamic> json) =>
      MedicalOrdersModel(
        orderId: json["orderID"],
        groceryOrderId: json["groceryOrderId"],
        riderName: json["Ridername"],
        customerName: json["customername"],
        totalItems: json["totalItems"],
        totalPrice: json["totalPrice"],
        createdAt: json['createdAt'],
        isAvailabilityUpdated: json['isAvailabilityUpdated'],
        missingItemsCount: json['missingItemsCount'],
        items: json["items"] == null
            ? []
            : List<GroceryItem>.from(
            json["items"]!.map((x) => GroceryItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "orderID": orderId,
    "groceryOrderId": groceryOrderId,
    "Ridername": riderName,
    "customername": customerName,
    "totalItems": totalItems,
    "totalPrice": totalPrice,
    'createdAt': this.createdAt,
    'isAvailabilityUpdated': this.isAvailabilityUpdated,
    'missingItemsCount': this.missingItemsCount,
    "items": items == null
        ? []
        : List<dynamic>.from(items!.map((x) => x.toJson())),
  };
}

class GroceryItem {
  List<Batch>? batches;
  String? id;
  String? businessId;
  ProductVariant? productVariant;
  String? pincode;
  String? cityName;
  dynamic supplierInfo;
  dynamic location;
  int? reorderPoint;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? totalStock;

  GroceryItem({
    this.batches,
    this.id,
    this.businessId,
    this.productVariant,
    this.pincode,
    this.cityName,
    this.supplierInfo,
    this.location,
    this.reorderPoint,
    this.createdAt,
    this.updatedAt,
    this.totalStock,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    batches: json["batches"] == null
        ? []
        : List<Batch>.from(json["batches"]!.map((x) => Batch.fromJson(x))),
    id: json["id"],
    businessId: json["businessId"],
    productVariant: json["productVariant"] == null
        ? null
        : ProductVariant.fromJson(json["productVariant"]),
    pincode: json["pincode"],
    cityName: json["cityName"],
    supplierInfo: json["supplierInfo"],
    location: json["location"],
    reorderPoint: json["reorderPoint"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    totalStock: json["totalStock"],
  );

  Map<String, dynamic> toJson() => {
    "batches": batches == null
        ? []
        : List<dynamic>.from(batches!.map((x) => x.toJson())),
    "id": id,
    "businessId": businessId,
    "productVariant": productVariant?.toJson(),
    "pincode": pincode,
    "cityName": cityName,
    "supplierInfo": supplierInfo,
    "location": location,
    "reorderPoint": reorderPoint,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "totalStock": totalStock,
  };
}

class Batch {
  Map<String, dynamic>? fields;

  Batch({
    this.fields,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    fields: json["fields"],
  );

  Map<String, dynamic> toJson() => {
    "fields": fields,
  };
}

class Pricing {
  String? pincode;
  String? cityName;
  num? mrp;
  num? sellingPrice;
  String? currency;
  String? sId;

  Pricing(
      {this.pincode,
        this.cityName,
        this.mrp,
        this.sellingPrice,
        this.currency,
        this.sId});

  Pricing.fromJson(Map<String, dynamic> json) {
    pincode = json['pincode'];
    cityName = json['cityName'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pincode'] = this.pincode;
    data['cityName'] = this.cityName;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    data['currency'] = this.currency;
    data['_id'] = this.sId;
    return data;
  }
}

class ProductVariant {
  List<Pricing>? pricing;
  List<Images>? images;
  String? id;
  Product? product;
  String? variantName;
  String? unit;
  String? sku;
  String? barcode;
  dynamic dimensions;
  int? weight;
  DateTime? createdAt;
  DateTime? updatedAt;

  ProductVariant({
    this.pricing,
    this.images,
    this.id,
    this.product,
    this.variantName,
    this.unit,
    this.sku,
    this.barcode,
    this.dimensions,
    this.weight,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    pricing: json["pricing"] == null
        ? []
        : List<Pricing>.from(json["pricing"]!.map((x) => Pricing.fromJson(x))),
    images: json["images"] == null
        ? []
        : List<Images>.from(json["images"]!.map((x) => Images.fromJson(x))),
    id: json["id"],
    product:
    json["product"] == null ? null : Product.fromJson(json["product"]),
    variantName: json["variantName"],
    unit: json["unit"],
    sku: json["sku"],
    barcode: json["barcode"],
    dimensions: json["dimensions"],
    weight: json["weight"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "pricing": pricing == null
        ? []
        : List<dynamic>.from(pricing!.map((x) => x.toJson())),
    "images":
    images == null ? [] : List<dynamic>.from(images!.map((x) => x)),
    "id": id,
    "product": product?.toJson(),
    "variantName": variantName,
    "unit": unit,
    "sku": sku,
    "barcode": barcode,
    "dimensions": dimensions,
    "weight": weight,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class Product {
  List<String>? tags;
  List<Images>? images;
  String? id;
  String? name;
  String? description;
  String? brand;
  String? category;
  bool? isActive;
  bool? isVegetarian;
  String? countryOfOrigin;
  Batch? nutritionalInfo;
  DateTime? createdAt;
  DateTime? updatedAt;

  Product({
    this.tags,
    this.images,
    this.id,
    this.name,
    this.description,
    this.brand,
    this.category,
    this.isActive,
    this.isVegetarian,
    this.countryOfOrigin,
    this.nutritionalInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    tags: json["tags"] == null
        ? []
        : List<String>.from(json["tags"]!.map((x) => x)),
    images: json["images"] == null
        ? []
        : List<Images>.from(json["images"]!.map((x) => Images.fromJson(x))),
    id: json["id"],
    name: json["name"],
    description: json["description"],
    brand: json["brand"],
    category: json["category"],
    isActive: json["isActive"],
    isVegetarian: json["isVegetarian"],
    countryOfOrigin: json["countryOfOrigin"],
    nutritionalInfo: json["nutritionalInfo"] == null
        ? null
        : Batch.fromJson(json["nutritionalInfo"]),
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
    "images": images == null
        ? []
        : List<dynamic>.from(images!.map((x) => x.toJson())),
    "id": id,
    "name": name,
    "description": description,
    "brand": brand,
    "category": category,
    "isActive": isActive,
    "isVegetarian": isVegetarian,
    "countryOfOrigin": countryOfOrigin,
    "nutritionalInfo": nutritionalInfo?.toJson(),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}