/// message : "Posted offerings fetched successfully"
/// count : 1
/// data : [{"_id":"6958e58d3ed63aeb74d6c50b","name":"Test","description":"Fresh organic apples from the farm.","brand":"FarmFresh","catalogNodeId":"6958e54e3ed63aeb74d6c507","tags":["organic","fruit","fresh"],"images":[],"isActive":true,"type":"PRODUCT","availability":{"days":[]},"createdAt":"2026-01-03T09:46:53.321Z","updatedAt":"2026-01-03T09:46:53.321Z","__v":0,"variants":[{"_id":"6958e58d3ed63aeb74d6c50d","product":"6958e58d3ed63aeb74d6c50b","variantName":"500g Pack","unit":"kg","sku":"F9A-APL-500G","barcode":"9976543210451","pricing":[{"pincode":"110001","cityName":"Delhi","mrp":90,"sellingPrice":85,"currency":"INR","_id":"6958e58d3ed63aeb74d6c50e"}],"images":[],"weight":500,"createdAt":"2026-01-03T09:46:53.325Z","updatedAt":"2026-01-03T09:46:53.325Z","__v":0},{"_id":"6958e58d3ed63aeb74d6c510","product":"6958e58d3ed63aeb74d6c50b","variantName":"1kg Pack","unit":"kg","sku":"F9A-APL-1KG-V2","barcode":"9976543210452","pricing":[{"pincode":"110001","cityName":"Delhi","mrp":170,"sellingPrice":160,"currency":"INR","_id":"6958e58d3ed63aeb74d6c511"}],"images":[],"weight":1000,"createdAt":"2026-01-03T09:46:53.329Z","updatedAt":"2026-01-03T09:46:53.329Z","__v":0},{"_id":"6958e58d3ed63aeb74d6c513","product":"6958e58d3ed63aeb74d6c50b","variantName":"2kg Pack","unit":"kg","sku":"F9A-APL-2KG","barcode":"9976543210453","pricing":[{"pincode":"110001","cityName":"Delhi","mrp":320,"sellingPrice":300,"currency":"INR","_id":"6958e58d3ed63aeb74d6c514"}],"images":[],"weight":2000,"createdAt":"2026-01-03T09:46:53.331Z","updatedAt":"2026-01-03T09:46:53.331Z","__v":0}]}]

class MedicalAdminProductDetails {
  MedicalAdminProductDetails({
      this.message, 
      this.count, 
      this.data,});

  MedicalAdminProductDetails.fromJson(dynamic json) {
    message = json['message'];
    count = json['count'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(MedicalProductDetailsModel.fromJson(v));
      });
    }
  }
  String? message;
  num? count;
  List<MedicalProductDetailsModel>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    map['count'] = count;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// _id : "6958e58d3ed63aeb74d6c50b"
/// name : "Test"
/// description : "Fresh organic apples from the farm."
/// brand : "FarmFresh"
/// catalogNodeId : "6958e54e3ed63aeb74d6c507"
/// tags : ["organic","fruit","fresh"]
/// images : []
/// isActive : true
/// type : "PRODUCT"
/// availability : {"days":[]}
/// createdAt : "2026-01-03T09:46:53.321Z"
/// updatedAt : "2026-01-03T09:46:53.321Z"
/// __v : 0
/// variants : [{"_id":"6958e58d3ed63aeb74d6c50d","product":"6958e58d3ed63aeb74d6c50b","variantName":"500g Pack","unit":"kg","sku":"F9A-APL-500G","barcode":"9976543210451","pricing":[{"pincode":"110001","cityName":"Delhi","mrp":90,"sellingPrice":85,"currency":"INR","_id":"6958e58d3ed63aeb74d6c50e"}],"images":[],"weight":500,"createdAt":"2026-01-03T09:46:53.325Z","updatedAt":"2026-01-03T09:46:53.325Z","__v":0},{"_id":"6958e58d3ed63aeb74d6c510","product":"6958e58d3ed63aeb74d6c50b","variantName":"1kg Pack","unit":"kg","sku":"F9A-APL-1KG-V2","barcode":"9976543210452","pricing":[{"pincode":"110001","cityName":"Delhi","mrp":170,"sellingPrice":160,"currency":"INR","_id":"6958e58d3ed63aeb74d6c511"}],"images":[],"weight":1000,"createdAt":"2026-01-03T09:46:53.329Z","updatedAt":"2026-01-03T09:46:53.329Z","__v":0},{"_id":"6958e58d3ed63aeb74d6c513","product":"6958e58d3ed63aeb74d6c50b","variantName":"2kg Pack","unit":"kg","sku":"F9A-APL-2KG","barcode":"9976543210453","pricing":[{"pincode":"110001","cityName":"Delhi","mrp":320,"sellingPrice":300,"currency":"INR","_id":"6958e58d3ed63aeb74d6c514"}],"images":[],"weight":2000,"createdAt":"2026-01-03T09:46:53.331Z","updatedAt":"2026-01-03T09:46:53.331Z","__v":0}]

class MedicalProductDetailsModel {
  MedicalProductDetailsModel({
      this.id,
      this.name, 
      this.description, 
      this.brand, 
      this.catalogNodeId, 
      this.tags, 
      this.images, 
      this.isActive, 
      this.type, 
      this.availability, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.variants,});

  MedicalProductDetailsModel.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    catalogNodeId = json['catalogNodeId'];
    tags = json['tags'] != null ? json['tags'].cast<String>() : [];
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        images?.add(v);
      });
    }
    isActive = json['isActive'];
    type = json['type'];
    availability = json['availability'] != null ? Availability.fromJson(json['availability']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants?.add(Variants.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? description;
  String? brand;
  String? catalogNodeId;
  List<String>? tags;
  List<String>? images;
  bool? isActive;
  String? type;
  Availability? availability;
  String? createdAt;
  String? updatedAt;
  num? v;
  List<Variants>? variants;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['brand'] = brand;
    map['catalogNodeId'] = catalogNodeId;
    map['tags'] = tags;
    if (images != null) {
      map['images'] = images?.map((v) => v).toList();
    }
    map['isActive'] = isActive;
    map['type'] = type;
    if (availability != null) {
      map['availability'] = availability?.toJson();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// _id : "6958e58d3ed63aeb74d6c50d"
/// product : "6958e58d3ed63aeb74d6c50b"
/// variantName : "500g Pack"
/// unit : "kg"
/// sku : "F9A-APL-500G"
/// barcode : "9976543210451"
/// pricing : [{"pincode":"110001","cityName":"Delhi","mrp":90,"sellingPrice":85,"currency":"INR","_id":"6958e58d3ed63aeb74d6c50e"}]
/// images : []
/// weight : 500
/// createdAt : "2026-01-03T09:46:53.325Z"
/// updatedAt : "2026-01-03T09:46:53.325Z"
/// __v : 0

class Variants {
  Variants({
      this.id, 
      this.product, 
      this.variantName, 
      this.unit, 
      this.sku, 
      this.barcode, 
      this.pricing, 
      this.images, 
      this.weight, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Variants.fromJson(dynamic json) {
    id = json['_id'];
    product = json['product'];
    variantName = json['variantName'];
    unit = json['unit'];
    sku = json['sku'];
    barcode = json['barcode'];
    if (json['pricing'] != null) {
      pricing = [];
      json['pricing'].forEach((v) {
        pricing?.add(Pricing.fromJson(v));
      });
    }
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        images?.add(v);
      });
    }
    weight = json['weight'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? product;
  String? variantName;
  String? unit;
  String? sku;
  String? barcode;
  List<Pricing>? pricing;
  List<dynamic>? images;
  num? weight;
  String? createdAt;
  String? updatedAt;
  num? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['product'] = product;
    map['variantName'] = variantName;
    map['unit'] = unit;
    map['sku'] = sku;
    map['barcode'] = barcode;
    if (pricing != null) {
      map['pricing'] = pricing?.map((v) => v.toJson()).toList();
    }
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
    map['weight'] = weight;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

/// pincode : "110001"
/// cityName : "Delhi"
/// mrp : 90
/// sellingPrice : 85
/// currency : "INR"
/// _id : "6958e58d3ed63aeb74d6c50e"

class Pricing {
  Pricing({
      this.pincode, 
      this.cityName, 
      this.mrp, 
      this.sellingPrice, 
      this.currency, 
      this.id,});

  Pricing.fromJson(dynamic json) {
    pincode = json['pincode'];
    cityName = json['cityName'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    id = json['_id'];
  }
  String? pincode;
  String? cityName;
  num? mrp;
  num? sellingPrice;
  String? currency;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['pincode'] = pincode;
    map['cityName'] = cityName;
    map['mrp'] = mrp;
    map['sellingPrice'] = sellingPrice;
    map['currency'] = currency;
    map['_id'] = id;
    return map;
  }

}

/// days : []

class Availability {
  Availability({
      this.days,});

  Availability.fromJson(dynamic json) {
    if (json['days'] != null) {
      days = [];
      json['days'].forEach((v) {
        days?.add(v);
      });
    }
  }
  List<dynamic>? days;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (days != null) {
      map['days'] = days?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}