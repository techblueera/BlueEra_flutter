/// _id : "68dcaa3fd0dc5de645817be8"
/// userId : "68beb748ae9530cebdebcb6a"
/// type : "food"
/// title : "regerg"
/// description : "vdgvwdegfewgfew............................."
/// photos : []
/// category : "Noodles"
/// shelfLife : "6 hours"
/// keyIngredients : ["Noodles","Masala Mix","Vegetables (Peas, Corn)","Tomato"]
/// servingOptions : [{"size":"Single Plate","serves":1}]
/// accompaniments : ["None"]
/// variants : [{"name":"Jumbo Pack","description":"Double the noodles, double the delight! Perfect for sharing."},{"name":"Spicy Level Upgrade","description":"Extra chilies added for those who like it hot!"}]
/// nutritionalSummary_per100g : {"calories_kcal":"120-150","protein_g":"3-5","carbs_g":"18-22","fat_g":"3-6"}
/// keyMinerals : ["Iron","Calcium"]
/// seoTags : ["Noodles","Masala Maggi","Spicy Noodles","Indian Cuisine"]
/// facilities : []
/// priceType : "multiple"
/// priceOptions : [{"label":"Default","price":65}]
/// isActive : true
/// isDeleted : false
/// addOns : []
/// timings : []
/// discounts : []
/// extraDetails : []
/// createdAt : "2025-10-01T04:12:47.866Z"
/// updatedAt : "2025-10-01T04:12:47.866Z"
/// __v : 0

class GetFoodDetailsModel {
  GetFoodDetailsModel({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    List<String>? photos,
    String? category,
    String? subCategory,   // ✅ added
    String? shelfLife,
    List<String>? keyIngredients,
    List<ServingOptions>? servingOptions,
    List<String>? accompaniments,
    List<Variants>? variants,
    NutritionalSummaryPer100g? nutritionalSummaryPer100g,
    List<String>? keyMinerals,
    List<String>? seoTags,
    List<dynamic>? facilities,
    String? priceType,
    List<PriceOptions>? priceOptions,
    bool? isActive,
    bool? isDeleted,
    List<dynamic>? addOns,
    List<dynamic>? timings,
    List<dynamic>? discounts,
    List<dynamic>? extraDetails,
    String? createdAt,
    String? singlePrice,
    String? updatedAt,
    num? v,
    String? availability,   // ✅ added
    String? vegType,        // ✅ added
  }) {
    _id = id;
    _userId = userId;
    _type = type;
    _title = title;
    _description = description;
    _photos = photos;
    _category = category;
    _subCategory = subCategory;   // ✅ added
    _shelfLife = shelfLife;
    _keyIngredients = keyIngredients;
    _servingOptions = servingOptions;
    _accompaniments = accompaniments;
    _variants = variants;
    _nutritionalSummaryPer100g = nutritionalSummaryPer100g;
    _keyMinerals = keyMinerals;
    _seoTags = seoTags;
    _facilities = facilities;
    _priceType = priceType;
    _priceOptions = priceOptions;
    _isActive = isActive;
    _isDeleted = isDeleted;
    _addOns = addOns;
    _timings = timings;
    _discounts = discounts;
    _extraDetails = extraDetails;
    _createdAt = createdAt;
    _singlePrice = singlePrice;
    _updatedAt = updatedAt;
    _v = v;
    _availability = availability;   // ✅ added
    _vegType = vegType;             // ✅ added
  }

  GetFoodDetailsModel.fromJson(dynamic json) {
    _id = json['_id'];
    _userId = json['userId'];
    _type = json['type'];
    _title = json['title'];
    _description = json['description'];
    if (json['photos'] != null) {
      _photos = [];
      json['photos'].forEach((v) {
        _photos?.add(v);
      });
    }
    _category = json['category'];
    _subCategory = json['subCategory']; // ✅ added
    _shelfLife = json['shelfLife'];
    _keyIngredients = json['keyIngredients'] != null ? json['keyIngredients'].cast<String>() : [];
    if (json['servingOptions'] != null) {
      _servingOptions = [];
      json['servingOptions'].forEach((v) {
        _servingOptions?.add(ServingOptions.fromJson(v));
      });
    }
    _accompaniments = json['accompaniments'] != null ? json['accompaniments'].cast<String>() : [];
    if (json['variants'] != null) {
      _variants = [];
      json['variants'].forEach((v) {
        _variants?.add(Variants.fromJson(v));
      });
    }
    _nutritionalSummaryPer100g = json['nutritionalSummary_per100g'] != null
        ? NutritionalSummaryPer100g.fromJson(json['nutritionalSummary_per100g'])
        : null;
    _keyMinerals = json['keyMinerals'] != null ? json['keyMinerals'].cast<String>() : [];
    _seoTags = json['seoTags'] != null ? json['seoTags'].cast<String>() : [];
    if (json['facilities'] != null) {
      _facilities = [];
      json['facilities'].forEach((v) {
        _facilities?.add(v);
      });
    }
    _priceType = json['priceType'];
    if (json['priceOptions'] != null) {
      _priceOptions = [];
      json['priceOptions'].forEach((v) {
        _priceOptions?.add(PriceOptions.fromJson(v));
      });
    }
    _isActive = json['isActive'];
    _isDeleted = json['isDeleted'];
    if (json['addOns'] != null) {
      _addOns = [];
      json['addOns'].forEach((v) {
        _addOns?.add(v);
      });
    }
    if (json['timings'] != null) {
      _timings = [];
      json['timings'].forEach((v) {
        _timings?.add(v);
      });
    }
    if (json['discounts'] != null) {
      _discounts = [];
      json['discounts'].forEach((v) {
        _discounts?.add(v);
      });
    }
    if (json['extraDetails'] != null) {
      _extraDetails = [];
      json['extraDetails'].forEach((v) {
        _extraDetails?.add(v);
      });
    }
    _createdAt = json['createdAt'];
    _singlePrice = json['singlePrice']?.toString();
    _updatedAt = json['updatedAt'];
    _v = json['__v'];
    _availability = json['availability']; // ✅ added
    _vegType = json['vegType'];           // ✅ added
  }

  String? _id;
  String? _userId;
  String? _type;
  String? _title;
  String? _description;
  List<String>? _photos;
  String? _category;
  String? _subCategory;   // ✅ added
  String? _shelfLife;
  List<String>? _keyIngredients;
  List<ServingOptions>? _servingOptions;
  List<String>? _accompaniments;
  List<Variants>? _variants;
  NutritionalSummaryPer100g? _nutritionalSummaryPer100g;
  List<String>? _keyMinerals;
  List<String>? _seoTags;
  List<dynamic>? _facilities;
  String? _priceType;
  List<PriceOptions>? _priceOptions;
  bool? _isActive;
  bool? _isDeleted;
  List<dynamic>? _addOns;
  List<dynamic>? _timings;
  List<dynamic>? _discounts;
  List<dynamic>? _extraDetails;
  String? _createdAt;
  String? _singlePrice;
  String? _updatedAt;
  num? _v;
  String? _availability;  // ✅ added
  String? _vegType;       // ✅ added

  GetFoodDetailsModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    List<String>? photos,
    String? category,
    String? subCategory,   // ✅ added
    String? shelfLife,
    List<String>? keyIngredients,
    List<ServingOptions>? servingOptions,
    List<String>? accompaniments,
    List<Variants>? variants,
    NutritionalSummaryPer100g? nutritionalSummaryPer100g,
    List<String>? keyMinerals,
    List<String>? seoTags,
    List<dynamic>? facilities,
    String? priceType,
    List<PriceOptions>? priceOptions,
    bool? isActive,
    bool? isDeleted,
    List<dynamic>? addOns,
    List<dynamic>? timings,
    List<dynamic>? discounts,
    List<dynamic>? extraDetails,
    String? createdAt,
    String? singlePrice,
    String? updatedAt,
    num? v,
    String? availability,   // ✅ added
    String? vegType,        // ✅ added
  }) =>
      GetFoodDetailsModel(
        id: id ?? _id,
        userId: userId ?? _userId,
        type: type ?? _type,
        title: title ?? _title,
        description: description ?? _description,
        photos: photos ?? _photos,
        category: category ?? _category,
        subCategory: subCategory ?? _subCategory,   // ✅ added
        shelfLife: shelfLife ?? _shelfLife,
        keyIngredients: keyIngredients ?? _keyIngredients,
        servingOptions: servingOptions ?? _servingOptions,
        accompaniments: accompaniments ?? _accompaniments,
        variants: variants ?? _variants,
        nutritionalSummaryPer100g:
        nutritionalSummaryPer100g ?? _nutritionalSummaryPer100g,
        keyMinerals: keyMinerals ?? _keyMinerals,
        seoTags: seoTags ?? _seoTags,
        facilities: facilities ?? _facilities,
        priceType: priceType ?? _priceType,
        priceOptions: priceOptions ?? _priceOptions,
        isActive: isActive ?? _isActive,
        isDeleted: isDeleted ?? _isDeleted,
        addOns: addOns ?? _addOns,
        timings: timings ?? _timings,
        discounts: discounts ?? _discounts,
        extraDetails: extraDetails ?? _extraDetails,
        createdAt: createdAt ?? _createdAt,
        singlePrice: singlePrice ?? _singlePrice,
        updatedAt: updatedAt ?? _updatedAt,
        v: v ?? _v,
        availability: availability ?? _availability, // ✅ added
        vegType: vegType ?? _vegType,               // ✅ added
      );

  // ✅ Getters
  String? get id => _id;
  String? get userId => _userId;
  String? get type => _type;
  String? get title => _title;
  String? get description => _description;
  List<String>? get photos => _photos;
  String? get category => _category;
  String? get subCategory => _subCategory;   // ✅ added
  String? get shelfLife => _shelfLife;
  List<String>? get keyIngredients => _keyIngredients;
  List<ServingOptions>? get servingOptions => _servingOptions;
  List<String>? get accompaniments => _accompaniments;
  List<Variants>? get variants => _variants;
  NutritionalSummaryPer100g? get nutritionalSummaryPer100g => _nutritionalSummaryPer100g;
  List<String>? get keyMinerals => _keyMinerals;
  List<String>? get seoTags => _seoTags;
  List<dynamic>? get facilities => _facilities;
  String? get priceType => _priceType;
  List<PriceOptions>? get priceOptions => _priceOptions;
  bool? get isActive => _isActive;
  bool? get isDeleted => _isDeleted;
  List<dynamic>? get addOns => _addOns;
  List<dynamic>? get timings => _timings;
  List<dynamic>? get discounts => _discounts;
  List<dynamic>? get extraDetails => _extraDetails;
  String? get createdAt => _createdAt;
  String? get singlePrice => _singlePrice;
  String? get updatedAt => _updatedAt;
  num? get v => _v;
  String? get availability => _availability;  // ✅ added
  String? get vegType => _vegType;            // ✅ added

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['userId'] = _userId;
    map['type'] = _type;
    map['title'] = _title;
    map['description'] = _description;
    if (_photos != null) {
      map['photos'] = _photos?.map((v) => v).toList();
    }
    map['category'] = _category;
    map['subCategory'] = _subCategory;   // ✅ added
    map['shelfLife'] = _shelfLife;
    map['keyIngredients'] = _keyIngredients;
    if (_servingOptions != null) {
      map['servingOptions'] = _servingOptions?.map((v) => v.toJson()).toList();
    }
    map['accompaniments'] = _accompaniments;
    if (_variants != null) {
      map['variants'] = _variants?.map((v) => v.toJson()).toList();
    }
    if (_nutritionalSummaryPer100g != null) {
      map['nutritionalSummary_per100g'] = _nutritionalSummaryPer100g?.toJson();
    }
    map['keyMinerals'] = _keyMinerals;
    map['seoTags'] = _seoTags;
    if (_facilities != null) {
      map['facilities'] = _facilities?.map((v) => v.toJson()).toList();
    }
    map['priceType'] = _priceType;
    if (_priceOptions != null) {
      map['priceOptions'] = _priceOptions?.map((v) => v.toJson()).toList();
    }
    map['isActive'] = _isActive;
    map['isDeleted'] = _isDeleted;
    if (_addOns != null) {
      map['addOns'] = _addOns?.map((v) => v.toJson()).toList();
    }
    if (_timings != null) {
      map['timings'] = _timings?.map((v) => v.toJson()).toList();
    }
    if (_discounts != null) {
      map['discounts'] = _discounts?.map((v) => v.toJson()).toList();
    }
    if (_extraDetails != null) {
      map['extraDetails'] = _extraDetails?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = _createdAt;
    map['singlePrice'] = _singlePrice;
    map['updatedAt'] = _updatedAt;
    map['__v'] = _v;
    map['availability'] = _availability; // ✅ added
    map['vegType'] = _vegType;           // ✅ added
    return map;
  }
}

/// label : "Default"
/// price : 65

class PriceOptions {
  PriceOptions({
      String? label, 
      num? price,}){
    _label = label;
    _price = price;
}

  PriceOptions.fromJson(dynamic json) {
    _label = json['label'];
    _price = json['price'];
  }
  String? _label;
  num? _price;
PriceOptions copyWith({  String? label,
  num? price,
}) => PriceOptions(  label: label ?? _label,
  price: price ?? _price,
);
  String? get label => _label;
  num? get price => _price;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['label'] = _label;
    map['price'] = _price;
    return map;
  }

}

/// calories_kcal : "120-150"
/// protein_g : "3-5"
/// carbs_g : "18-22"
/// fat_g : "3-6"

class NutritionalSummaryPer100g {
  NutritionalSummaryPer100g({
      String? caloriesKcal, 
      String? proteinG, 
      String? carbsG, 
      String? fatG,}){
    _caloriesKcal = caloriesKcal;
    _proteinG = proteinG;
    _carbsG = carbsG;
    _fatG = fatG;
}

  NutritionalSummaryPer100g.fromJson(dynamic json) {
    _caloriesKcal = json['calories_kcal'];
    _proteinG = json['protein_g'];
    _carbsG = json['carbs_g'];
    _fatG = json['fat_g'];
  }
  String? _caloriesKcal;
  String? _proteinG;
  String? _carbsG;
  String? _fatG;
NutritionalSummaryPer100g copyWith({  String? caloriesKcal,
  String? proteinG,
  String? carbsG,
  String? fatG,
}) => NutritionalSummaryPer100g(  caloriesKcal: caloriesKcal ?? _caloriesKcal,
  proteinG: proteinG ?? _proteinG,
  carbsG: carbsG ?? _carbsG,
  fatG: fatG ?? _fatG,
);
  String? get caloriesKcal => _caloriesKcal;
  String? get proteinG => _proteinG;
  String? get carbsG => _carbsG;
  String? get fatG => _fatG;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['calories_kcal'] = _caloriesKcal;
    map['protein_g'] = _proteinG;
    map['carbs_g'] = _carbsG;
    map['fat_g'] = _fatG;
    return map;
  }

}

/// name : "Jumbo Pack"
/// description : "Double the noodles, double the delight! Perfect for sharing."

class Variants {
  Variants({
      String? name, 
      String? description,}){
    _name = name;
    _description = description;
}

  Variants.fromJson(dynamic json) {
    _name = json['name'];
    _description = json['description'];
  }
  String? _name;
  String? _description;
Variants copyWith({  String? name,
  String? description,
}) => Variants(  name: name ?? _name,
  description: description ?? _description,
);
  String? get name => _name;
  String? get description => _description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['description'] = _description;
    return map;
  }

}

/// size : "Single Plate"
/// serves : 1

class ServingOptions {
  ServingOptions({
      String? size, 
      num? serves,}){
    _size = size;
    _serves = serves;
}

  ServingOptions.fromJson(dynamic json) {
    _size = json['size'];
    _serves = json['serves'];
  }
  String? _size;
  num? _serves;
ServingOptions copyWith({  String? size,
  num? serves,
}) => ServingOptions(  size: size ?? _size,
  serves: serves ?? _serves,
);
  String? get size => _size;
  num? get serves => _serves;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['size'] = _size;
    map['serves'] = _serves;
    return map;
  }

}