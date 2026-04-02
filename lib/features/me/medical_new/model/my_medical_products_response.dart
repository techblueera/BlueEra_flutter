import '../../../../../core/api/model/images.dart';
import 'medical_product_model.dart';

class MyMedicalProductsModel {
  List<Data>? data;
  Pagination? pagination;

  MyMedicalProductsModel({this.data, this.pagination});

  MyMedicalProductsModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Data {
  Category? category;

  Data({this.category});

  Data.fromJson(Map<String, dynamic> json) {
    category = json['category'] != null
        ? new Category.fromJson(json['category'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.category != null) {
      data['category'] = this.category!.toJson();
    }
    return data;
  }
}

class Category {
  String? sId;
  String? name;
  int? productVariantCount;
  String? image;
  List<Products>? products;
  String? lastUpdate;

  Category({this.sId, this.name, this.productVariantCount, this.image, this.products});

  Category.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    productVariantCount = json['productVariantCount'];
    image = json['image'];
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
    lastUpdate = json['lastUpdate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['productVariantCount'] = this.productVariantCount;
    data['image'] = this.image;
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    data['lastUpdate'] = this.lastUpdate;
    return data;
  }
}

class Products {
  String? sId;
  String? name;
  String? description;
  String? brand;
  List<Images>? images;
  List<MedicalProductVariants>? variants;
  String? lastInventoryAddedOrUpdated;

  Products(
      {this.sId,
        this.name,
        this.description,
        this.brand,
        this.images,
        this.variants,
        this.lastInventoryAddedOrUpdated});

  Products.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
      });
    }
    if (json['variants'] != null) {
      variants = <MedicalProductVariants>[];
      json['variants'].forEach((v) {
        variants!.add(new MedicalProductVariants.fromJson(v));
      });
    }
    lastInventoryAddedOrUpdated = json['lastInventoryAddedOrUpdated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['brand'] = this.brand;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    data['lastInventoryAddedOrUpdated'] = this.lastInventoryAddedOrUpdated;
    return data;
  }
}

class MedicalProductVariants {
  String? sId;
  String? variantName;
  String? unit;
  String? sku;
  List<Pricing>? pricing;
  List<Images>? images;
  int? weight;
  Inventory? inventory;

  MedicalProductVariants(
      {this.sId,
        this.variantName,
        this.unit,
        this.sku,
        this.pricing,
        this.images,
        this.weight,
        this.inventory});

  MedicalProductVariants.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    variantName = json['variantName'];
    unit = json['unit'];
    sku = json['sku'];
    if (json['pricing'] != null) {
      pricing = <Pricing>[];
      json['pricing'].forEach((v) {
        pricing!.add(new Pricing.fromJson(v));
      });
    }
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
      });
    }
    weight = json['weight'];
    inventory = json['product'] != null
        ? new Inventory.fromJson(json['product'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['variantName'] = this.variantName;
    data['unit'] = this.unit;
    data['sku'] = this.sku;
    if (this.pricing != null) {
      data['pricing'] = this.pricing!.map((v) => v.toJson()).toList();
    }
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    data['weight'] = this.weight;
    if (this.inventory != null) {
      data['product'] = this.inventory!.toJson();
    }
    return data;
  }
}

class Inventory {
  String? inventoryId;
  String? pincode;
  String? cityName;
  List<Batches>? batches;

  Inventory({this.inventoryId, this.pincode, this.cityName, this.batches});

  Inventory.fromJson(Map<String, dynamic> json) {
    inventoryId = json['inventoryId'];
    pincode = json['pincode'];
    cityName = json['cityName'];
    if (json['batches'] != null) {
      batches = <Batches>[];
      json['batches'].forEach((v) {
        batches!.add(new Batches.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['inventoryId'] = this.inventoryId;
    data['pincode'] = this.pincode;
    data['cityName'] = this.cityName;
    if (this.batches != null) {
      data['batches'] = this.batches!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Batches {
  String? batchNumber;
  int? quantity;
  int? mrp;
  int? sellingPrice;
  String? sId;

  Batches(
      {this.batchNumber, this.quantity, this.mrp, this.sellingPrice, this.sId});

  Batches.fromJson(Map<String, dynamic> json) {
    batchNumber = json['batchNumber'];
    quantity = json['quantity'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['batchNumber'] = this.batchNumber;
    data['quantity'] = this.quantity;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    data['_id'] = this.sId;
    return data;
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Pagination({this.total, this.page, this.limit, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['page'] = this.page;
    data['limit'] = this.limit;
    data['totalPages'] = this.totalPages;
    return data;
  }
}