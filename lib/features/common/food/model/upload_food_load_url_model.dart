/// service : {"userId":"68db73e3cc805d4e15cace66","type":"food","title":"Steamed Idly Delight,South Indian Idly Treat,Fluffy Idly Breakfast","description":"Light, fluffy, and steamed to perfection! Enjoy this South Indian breakfast staple with sambar & chutney.","photos":["services-service/images/68dfcb12e4a3120ba7a3fb3c/3a774199-284a-49d7-9e73-2eda0dd2b3f7"],"category":"Food Item","subCategory":"Veg","addOns":[],"keyIngredients":["Rice","Urad Dal","Fenugreek Seeds"],"servingOptions":[{"size":"Single Plate","serves":2}],"accompaniments":["Sambar","Coconut Chutney"],"nutritionalSummary_per100g":{"calories_kcal":"120-150","protein_g":"3-5","carbs_g":"25-30","fat_g":"1-2"},"keyMinerals":["Iron","Calcium"],"seoTags":["Idly","South Indian Breakfast","Steamed Food"],"facilities":[],"priceType":"single","singlePrice":100,"isActive":true,"isDeleted":false,"_id":"68dfcb12e4a3120ba7a3fb3c","variants":[],"timings":[],"priceOptions":[],"discounts":[],"extraDetails":[],"createdAt":"2025-10-03T13:09:38.100Z","updatedAt":"2025-10-03T13:09:38.111Z","__v":1}
/// uploadUrls : {"images":["https://be-video-service.s3.ap-south-1.amazonaws.com/services-service/images/68dfcb12e4a3120ba7a3fb3c/3a774199-284a-49d7-9e73-2eda0dd2b3f7?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAXYKJVYM5PVYDXDM2%2F20251003%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20251003T130938Z&X-Amz-Expires=3600&X-Amz-Signature=d6ebb0af1557953a0ae585c008a7bac877c6e0239d49980acf20a71d32b7c603&X-Amz-SignedHeaders=host&x-amz-checksum-crc32=AAAAAA%3D%3D&x-amz-sdk-checksum-algorithm=CRC32&x-id=PutObject"]}

class UploadFoodLoadUrlModel {
  UploadFoodLoadUrlModel({
      this.service, 
      this.uploadUrls,});

  UploadFoodLoadUrlModel.fromJson(dynamic json) {
    service = json['service'] != null ? Service.fromJson(json['service']) : null;
    uploadUrls = json['uploadUrls'] != null ? UploadUrls.fromJson(json['uploadUrls']) : null;
  }
  Service? service;
  UploadUrls? uploadUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (service != null) {
      map['service'] = service?.toJson();
    }
    if (uploadUrls != null) {
      map['uploadUrls'] = uploadUrls?.toJson();
    }
    return map;
  }

}

/// images : ["https://be-video-service.s3.ap-south-1.amazonaws.com/services-service/images/68dfcb12e4a3120ba7a3fb3c/3a774199-284a-49d7-9e73-2eda0dd2b3f7?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAXYKJVYM5PVYDXDM2%2F20251003%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20251003T130938Z&X-Amz-Expires=3600&X-Amz-Signature=d6ebb0af1557953a0ae585c008a7bac877c6e0239d49980acf20a71d32b7c603&X-Amz-SignedHeaders=host&x-amz-checksum-crc32=AAAAAA%3D%3D&x-amz-sdk-checksum-algorithm=CRC32&x-id=PutObject"]

class UploadUrls {
  UploadUrls({
      this.images,});

  UploadUrls.fromJson(dynamic json) {
    images = json['images'] != null ? json['images'].cast<String>() : [];
  }
  List<String>? images;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['images'] = images;
    return map;
  }

}

/// userId : "68db73e3cc805d4e15cace66"
/// type : "food"
/// title : "Steamed Idly Delight,South Indian Idly Treat,Fluffy Idly Breakfast"
/// description : "Light, fluffy, and steamed to perfection! Enjoy this South Indian breakfast staple with sambar & chutney."
/// photos : ["services-service/images/68dfcb12e4a3120ba7a3fb3c/3a774199-284a-49d7-9e73-2eda0dd2b3f7"]
/// category : "Food Item"
/// subCategory : "Veg"
/// addOns : []
/// keyIngredients : ["Rice","Urad Dal","Fenugreek Seeds"]
/// servingOptions : [{"size":"Single Plate","serves":2}]
/// accompaniments : ["Sambar","Coconut Chutney"]
/// nutritionalSummary_per100g : {"calories_kcal":"120-150","protein_g":"3-5","carbs_g":"25-30","fat_g":"1-2"}
/// keyMinerals : ["Iron","Calcium"]
/// seoTags : ["Idly","South Indian Breakfast","Steamed Food"]
/// facilities : []
/// priceType : "single"
/// singlePrice : 100
/// isActive : true
/// isDeleted : false
/// _id : "68dfcb12e4a3120ba7a3fb3c"
/// variants : []
/// timings : []
/// priceOptions : []
/// discounts : []
/// extraDetails : []
/// createdAt : "2025-10-03T13:09:38.100Z"
/// updatedAt : "2025-10-03T13:09:38.111Z"
/// __v : 1

class Service {
  Service({
      this.userId, 
      this.type, 
      this.title, 
      this.description, 
      this.photos, 
      this.category, 
      this.subCategory, 
      this.addOns, 
      this.keyIngredients, 
      this.servingOptions, 
      this.accompaniments, 
      this.nutritionalSummaryPer100g, 
      this.keyMinerals, 
      this.seoTags, 
      this.facilities, 
      this.priceType, 
      this.singlePrice, 
      this.isActive, 
      this.isDeleted, 
      this.id, 
      this.variants, 
      this.timings, 
      this.priceOptions, 
      this.discounts, 
      this.extraDetails, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Service.fromJson(dynamic json) {
    userId = json['userId'];
    type = json['type'];
    title = json['title'];
    description = json['description'];
    photos = json['photos'] != null ? json['photos'].cast<String>() : [];
    category = json['category'];
    subCategory = json['subCategory'];
    if (json['addOns'] != null) {
      addOns = [];
      json['addOns'].forEach((v) {
        addOns?.add([]);
      });
    }
    keyIngredients = json['keyIngredients'] != null ? json['keyIngredients'].cast<String>() : [];
    if (json['servingOptions'] != null) {
      servingOptions = [];
      json['servingOptions'].forEach((v) {
        servingOptions?.add(ServingOptions.fromJson(v));
      });
    }
    accompaniments = json['accompaniments'] != null ? json['accompaniments'].cast<String>() : [];
    nutritionalSummaryPer100g = json['nutritionalSummary_per100g'] != null ? NutritionalSummaryPer100g.fromJson(json['nutritionalSummary_per100g']) : null;
    keyMinerals = json['keyMinerals'] != null ? json['keyMinerals'].cast<String>() : [];
    seoTags = json['seoTags'] != null ? json['seoTags'].cast<String>() : [];
    if (json['facilities'] != null) {
      facilities = [];
      json['facilities'].forEach((v) {
        facilities?.add(v);
      });
    }
    priceType = json['priceType'];
    singlePrice = json['singlePrice'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    id = json['_id'];
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants?.add(v);
      });
    }
    if (json['timings'] != null) {
      timings = [];
      json['timings'].forEach((v) {
        timings?.add(v);
      });
    }
    if (json['priceOptions'] != null) {
      priceOptions = [];
      json['priceOptions'].forEach((v) {
        priceOptions?.add(v);
      });
    }
    if (json['discounts'] != null) {
      discounts = [];
      json['discounts'].forEach((v) {
        discounts?.add(v);
      });
    }
    if (json['extraDetails'] != null) {
      extraDetails = [];
      json['extraDetails'].forEach((v) {
        extraDetails?.add(v);
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? userId;
  String? type;
  String? title;
  String? description;
  List<String>? photos;
  String? category;
  String? subCategory;
  List<dynamic>? addOns;
  List<String>? keyIngredients;
  List<ServingOptions>? servingOptions;
  List<String>? accompaniments;
  NutritionalSummaryPer100g? nutritionalSummaryPer100g;
  List<String>? keyMinerals;
  List<String>? seoTags;
  List<dynamic>? facilities;
  String? priceType;
  num? singlePrice;
  bool? isActive;
  bool? isDeleted;
  String? id;
  List<dynamic>? variants;
  List<dynamic>? timings;
  List<dynamic>? priceOptions;
  List<dynamic>? discounts;
  List<dynamic>? extraDetails;
  String? createdAt;
  String? updatedAt;
  num? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = userId;
    map['type'] = type;
    map['title'] = title;
    map['description'] = description;
    map['photos'] = photos;
    map['category'] = category;
    map['subCategory'] = subCategory;
    if (addOns != null) {
      map['addOns'] = addOns?.map((v) => v.toJson()).toList();
    }
    map['keyIngredients'] = keyIngredients;
    if (servingOptions != null) {
      map['servingOptions'] = servingOptions?.map((v) => v.toJson()).toList();
    }
    map['accompaniments'] = accompaniments;
    if (nutritionalSummaryPer100g != null) {
      map['nutritionalSummary_per100g'] = nutritionalSummaryPer100g?.toJson();
    }
    map['keyMinerals'] = keyMinerals;
    map['seoTags'] = seoTags;
    if (facilities != null) {
      map['facilities'] = facilities?.map((v) => v.toJson()).toList();
    }
    map['priceType'] = priceType;
    map['singlePrice'] = singlePrice;
    map['isActive'] = isActive;
    map['isDeleted'] = isDeleted;
    map['_id'] = id;
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    if (timings != null) {
      map['timings'] = timings?.map((v) => v.toJson()).toList();
    }
    if (priceOptions != null) {
      map['priceOptions'] = priceOptions?.map((v) => v.toJson()).toList();
    }
    if (discounts != null) {
      map['discounts'] = discounts?.map((v) => v.toJson()).toList();
    }
    if (extraDetails != null) {
      map['extraDetails'] = extraDetails?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

/// calories_kcal : "120-150"
/// protein_g : "3-5"
/// carbs_g : "25-30"
/// fat_g : "1-2"

class NutritionalSummaryPer100g {
  NutritionalSummaryPer100g({
      this.caloriesKcal, 
      this.proteinG, 
      this.carbsG, 
      this.fatG,});

  NutritionalSummaryPer100g.fromJson(dynamic json) {
    caloriesKcal = json['calories_kcal'];
    proteinG = json['protein_g'];
    carbsG = json['carbs_g'];
    fatG = json['fat_g'];
  }
  String? caloriesKcal;
  String? proteinG;
  String? carbsG;
  String? fatG;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['calories_kcal'] = caloriesKcal;
    map['protein_g'] = proteinG;
    map['carbs_g'] = carbsG;
    map['fat_g'] = fatG;
    return map;
  }

}

/// size : "Single Plate"
/// serves : 2

class ServingOptions {
  ServingOptions({
      this.size, 
      this.serves,});

  ServingOptions.fromJson(dynamic json) {
    size = json['size'];
    serves = json['serves'];
  }
  String? size;
  num? serves;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['size'] = size;
    map['serves'] = serves;
    return map;
  }

}