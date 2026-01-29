class MedicalProductDetailsModel {
  String? id;
  String? businessId;
  CategoryModel? category;
  String? name;
  String? description;
  String? image;
  String? createdAt;
  String? updatedAt;
  int? v;
  num? displayPrice;
  String? mrp;
  String? priceRange;
  int? variantCount;
  List<VariantModel>? variants;

  MedicalProductDetailsModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    businessId = json['businessId'];
    category = json['categoryId'] != null && json['categoryId'] is Map
        ? CategoryModel.fromJson(json['categoryId'])
        : null;
    name = json['name'];
    description = json['description'];
    image = json['image'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    displayPrice = json['displayPrice'];
    mrp = json['mrp']?.toString();
    priceRange = json['priceRange'];
    variantCount = json['variantCount'];
    variants = (json['variants'] as List?)
        ?.map((e) => VariantModel.fromJson(e))
        .toList();
  }
}

/// ================= CATEGORY =================
class CategoryModel {
  String? id;
  String? businessId;
  String? name;
  String? icon;
  int? v;

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    businessId = json['businessId'];
    name = json['name'];
    icon = json['icon'];
    v = json['__v'];
  }
}

/// ================= VARIANT =================
class VariantModel {
  String? id;
  String? businessId;
  String? productId;
  num? weight;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<VariantImage>? images;
  List<Inventory>? inventories;

  VariantModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    businessId = json['businessId'];
    productId = json['productId'];
    weight = json['weight'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];

    images = (json['images'] as List?)
        ?.map((e) => VariantImage.fromJson(e))
        .toList();

    inventories = (json['inventories'] as List?)
        ?.map((e) => Inventory.fromJson(e))
        .toList();
  }
}

/// ================= VARIANT IMAGE =================
class VariantImage {
  String? url;
  String? altText;
  String? id;

  VariantImage.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    altText = json['altText'];
    id = json['_id'];
  }
}

/// ================= INVENTORY =================
class Inventory {
  SupplierInfo? supplierInfo;
  LocationModel? location;
  String? pincode;
  String? cityName;
  num? reorderPoint;
  String? id;
  List<Batch>? batches;

  Inventory.fromJson(Map<String, dynamic> json) {
    supplierInfo = json['supplierInfo'] != null
        ? SupplierInfo.fromJson(json['supplierInfo'])
        : null;

    location = json['location'] != null
        ? LocationModel.fromJson(json['location'])
        : null;

    pincode = json['pincode']?.toString();
    cityName = json['cityName'];
    reorderPoint = json['reorderPoint'];
    id = json['_id'];

    batches = (json['batches'] as List?)
        ?.map((e) => Batch.fromJson(e))
        .toList();
  }
}

/// ================= SUPPLIER =================
class SupplierInfo {
  String? name;
  String? contact;

  SupplierInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    contact = json['contact']?.toString();
  }
}

/// ================= LOCATION =================
class LocationModel {
  String? aisle;
  String? shelf;

  LocationModel.fromJson(Map<String, dynamic> json) {
    aisle = json['aisle'];
    shelf = json['shelf'];
  }
}

/// ================= BATCH =================
class Batch {
  String? batchNumber;
  num? quantity;
  String? mfgDate;
  String? expiryDate;
  num? mrp;
  num? sellingPrice;
  String? id;

  Batch.fromJson(Map<String, dynamic> json) {
    batchNumber = json['batchNumber'];
    quantity = json['quantity'];
    mfgDate = json['mfgDate'];
    expiryDate = json['expiryDate'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    id = json['_id'];
  }
}