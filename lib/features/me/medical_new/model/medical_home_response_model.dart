class MedicalHomeResponseModel {
  BusinessProfile? businessProfile;
  dynamic aboutUs;
  dynamic contact;
  List<dynamic>? gallery;
  List<dynamic>? testimonials;
  InventorySummary? inventorySummary;

  MedicalHomeResponseModel({
    this.businessProfile,
    this.aboutUs,
    this.contact,
    this.gallery,
    this.testimonials,
    this.inventorySummary,
  });

  MedicalHomeResponseModel.fromJson(Map<String, dynamic> json) {
    businessProfile = json['businessProfile'] != null
        ? BusinessProfile.fromJson(json['businessProfile'])
        : null;
    aboutUs = json['aboutUs'];
    contact = json['contact'];
    gallery = json['gallery'];
    testimonials = json['testimonials'];
    inventorySummary = json['inventorySummary'] != null
        ? InventorySummary.fromJson(json['inventorySummary'])
        : null;
  }
}

class BusinessProfile {
  String? id;
  String? userId;
  String? businessName;
  String? logo;
  String? businessDescription;
  String? typeOfBusiness;
  String? address;
  String? cityStatePincode;
  String? websiteUrl;
  BusinessLocation? businessLocation;
  BusinessNumber? businessNumber;
  List<OwnerDetail>? ownerDetails;
  num? avgRating;
  String? totalRatings;
  String? createdAt;
  String? updatedAt;

  BusinessProfile({
    this.id,
    this.userId,
    this.businessName,
    this.logo,
    this.businessDescription,
    this.typeOfBusiness,
    this.address,
    this.cityStatePincode,
    this.websiteUrl,
    this.businessLocation,
    this.businessNumber,
    this.ownerDetails,
    this.avgRating,
    this.totalRatings,
    this.createdAt,
    this.updatedAt,
  });

  BusinessProfile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    businessName = json['business_name'];
    logo = json['logo'];
    businessDescription = json['business_description'];
    typeOfBusiness = json['type_of_business'];
    address = json['address'];
    cityStatePincode = json['city_state_pincode'];
    websiteUrl = json['website_url'];
    businessLocation = json['business_location'] != null
        ? BusinessLocation.fromJson(json['business_location'])
        : null;
    businessNumber = json['business_number'] != null
        ? BusinessNumber.fromJson(json['business_number'])
        : null;
    if (json['owner_details'] != null) {
      ownerDetails = <OwnerDetail>[];
      json['owner_details'].forEach((v) {
        ownerDetails!.add(OwnerDetail.fromJson(v));
      });
    }
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings']?.toString();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}

class BusinessLocation {
  double? lat;
  double? lon;

  BusinessLocation({this.lat, this.lon});

  BusinessLocation.fromJson(Map<String, dynamic> json) {
    lat = (json['lat'] as num?)?.toDouble();
    lon = (json['lon'] as num?)?.toDouble();
  }
}

class BusinessNumber {
  PhoneEntry? officeMobNo;
  PhoneEntry? officeLandlineNo;

  BusinessNumber({this.officeMobNo, this.officeLandlineNo});

  BusinessNumber.fromJson(Map<String, dynamic> json) {
    officeMobNo = json['office_mob_no'] != null
        ? PhoneEntry.fromJson(json['office_mob_no'])
        : null;
    officeLandlineNo = json['office_landline_no'] != null
        ? PhoneEntry.fromJson(json['office_landline_no'])
        : null;
  }

  String? get formattedMobile {
    if (officeMobNo?.number == null || officeMobNo!.number == '0') return null;
    final pre = officeMobNo?.pre ?? '';
    return '+$pre ${officeMobNo!.number}';
  }
}

class PhoneEntry {
  dynamic pre;
  String? number;

  PhoneEntry({this.pre, this.number});

  PhoneEntry.fromJson(Map<String, dynamic> json) {
    pre = json['pre'];
    number = json['number']?.toString();
  }
}

class OwnerDetail {
  String? name;
  String? roleInBusiness;
  String? email;

  OwnerDetail({this.name, this.roleInBusiness, this.email});

  OwnerDetail.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    roleInBusiness = json['role_in_business'];
    email = json['email'];
  }
}

class InventorySummary {
  List<PopularProduct>? popularProducts;
  List<CategoryWithProducts>? categoriesWithProducts;

  InventorySummary({this.popularProducts, this.categoriesWithProducts});

  InventorySummary.fromJson(Map<String, dynamic> json) {
    if (json['popularProducts'] != null) {
      popularProducts = <PopularProduct>[];
      json['popularProducts'].forEach((v) {
        popularProducts!.add(PopularProduct.fromJson(v));
      });
    }
    if (json['categoriesWithProducts'] != null) {
      categoriesWithProducts = <CategoryWithProducts>[];
      json['categoriesWithProducts'].forEach((v) {
        categoriesWithProducts!.add(CategoryWithProducts.fromJson(v));
      });
    }
  }
}

class PopularProduct {
  String? sId;
  String? businessId;
  PopularVariant? variant;
  PopularProductInfo? product;
  PopularBatch? batches;
  PopularCategory? category;

  PopularProduct({
    this.sId,
    this.businessId,
    this.variant,
    this.product,
    this.batches,
    this.category,
  });

  PopularProduct.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    variant = json['variant'] != null
        ? PopularVariant.fromJson(json['variant'])
        : null;
    product = json['product'] != null
        ? PopularProductInfo.fromJson(json['product'])
        : null;
    batches = json['batches'] != null
        ? PopularBatch.fromJson(json['batches'])
        : null;
    category = json['category'] != null
        ? PopularCategory.fromJson(json['category'])
        : null;
  }
}

class PopularVariant {
  String? sId;
  String? variantName;
  String? unit;
  String? quantity;
  List<PopularPricing>? pricing;
  List<ProductImageItem>? images;

  PopularVariant({
    this.sId,
    this.variantName,
    this.unit,
    this.quantity,
    this.pricing,
    this.images,
  });

  PopularVariant.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    variantName = json['variantName'];
    unit = json['unit'];
    quantity = json['quantity'];
    if (json['pricing'] != null) {
      pricing = <PopularPricing>[];
      json['pricing'].forEach((v) {
        pricing!.add(PopularPricing.fromJson(v));
      });
    }
    if (json['images'] != null) {
      images = <ProductImageItem>[];
      json['images'].forEach((v) {
        images!.add(ProductImageItem.fromJson(v));
      });
    }
  }
}

class PopularPricing {
  num? mrp;
  num? sellingPrice;
  String? currency;

  PopularPricing({this.mrp, this.sellingPrice, this.currency});

  PopularPricing.fromJson(Map<String, dynamic> json) {
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
  }
}

class PopularProductInfo {
  String? sId;
  String? name;
  String? brand;
  String? description;
  List<ProductImageItem>? images;

  PopularProductInfo({this.sId, this.name, this.brand, this.description, this.images});

  PopularProductInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    brand = json['brand'];
    description = json['description'];
    if (json['images'] != null) {
      images = <ProductImageItem>[];
      json['images'].forEach((v) {
        images!.add(ProductImageItem.fromJson(v));
      });
    }
  }
}

class PopularBatch {
  num? mrp;
  num? sellingPrice;
  int? quantity;

  PopularBatch({this.mrp, this.sellingPrice, this.quantity});

  PopularBatch.fromJson(Map<String, dynamic> json) {
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    quantity = json['quantity'];
  }
}

class PopularCategory {
  String? sId;
  String? name;
  String? key;

  PopularCategory({this.sId, this.name, this.key});

  PopularCategory.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
  }
}

class ProductImageItem {
  String? url;
  String? altText;
  String? sId;

  ProductImageItem({this.url, this.altText, this.sId});

  ProductImageItem.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    altText = json['altText'];
    sId = json['_id'];
  }
}

/// Nested category tree: level 0 → 1 → 2 → 3 (with products at leaf)
class CategoryWithProducts {
  String? sId;
  String? name;
  String? key;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  List<CategoryWithProducts>? children;
  List<CategoryProduct>? products;

  CategoryWithProducts({
    this.sId,
    this.name,
    this.key,
    this.isActive,
    this.parentId,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.children,
    this.products,
  });

  CategoryWithProducts.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'] ?? json['categoryName'];
    key = json['key'] ?? json['categoryKey'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    if (json['children'] != null) {
      children = <CategoryWithProducts>[];
      json['children'].forEach((v) {
        children!.add(CategoryWithProducts.fromJson(v));
      });
    }
    if (json['products'] != null) {
      products = <CategoryProduct>[];
      json['products'].forEach((v) {
        products!.add(CategoryProduct.fromJson(v));
      });
    }
  }

  /// Recursively collect all products from this node and all descendants
  List<CategoryProduct> getAllProducts() {
    List<CategoryProduct> all = [];
    if (products != null) all.addAll(products!);
    if (children != null) {
      for (final child in children!) {
        all.addAll(child.getAllProducts());
      }
    }
    return all;
  }

  /// Check if this category or any descendant has products
  bool get hasProducts {
    if (products != null && products!.isNotEmpty) return true;
    if (children != null) {
      for (final child in children!) {
        if (child.hasProducts) return true;
      }
    }
    return false;
  }
}

class CategoryProduct {
  String? sId;
  String? name;
  String? genericName;
  String? description;
  String? brand;
  List<ProductImageItem>? images;
  String? productForm;
  bool? isPrescriptionRequired;
  List<CategoryProductVariant>? variants;

  CategoryProduct({
    this.sId,
    this.name,
    this.genericName,
    this.description,
    this.brand,
    this.images,
    this.productForm,
    this.isPrescriptionRequired,
    this.variants,
  });

  CategoryProduct.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    genericName = json['generic_name'];
    description = json['description'];
    brand = json['brand'];
    if (json['images'] != null) {
      images = <ProductImageItem>[];
      json['images'].forEach((v) {
        images!.add(ProductImageItem.fromJson(v));
      });
    }
    productForm = json['product_form'];
    isPrescriptionRequired = json['is_prescription_required'];
    if (json['variants'] != null) {
      variants = <CategoryProductVariant>[];
      json['variants'].forEach((v) {
        variants!.add(CategoryProductVariant.fromJson(v));
      });
    }
  }
}

class CategoryProductVariant {
  String? sId;
  String? variantName;
  String? unit;
  String? sku;
  List<PopularPricing>? pricing;
  List<ProductImageItem>? images;
  CategoryInventory? inventory;

  CategoryProductVariant({
    this.sId,
    this.variantName,
    this.unit,
    this.sku,
    this.pricing,
    this.images,
    this.inventory,
  });

  CategoryProductVariant.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    variantName = json['variantName'];
    unit = json['unit'];
    sku = json['sku'];
    if (json['pricing'] != null) {
      pricing = <PopularPricing>[];
      json['pricing'].forEach((v) {
        pricing!.add(PopularPricing.fromJson(v));
      });
    }
    if (json['images'] != null) {
      images = <ProductImageItem>[];
      json['images'].forEach((v) {
        images!.add(ProductImageItem.fromJson(v));
      });
    }
    inventory = json['inventory'] != null
        ? CategoryInventory.fromJson(json['inventory'])
        : null;
  }
}

class CategoryInventory {
  String? inventoryId;
  String? pincode;
  String? cityName;
  List<CategoryBatch>? batches;

  CategoryInventory({this.inventoryId, this.pincode, this.cityName, this.batches});

  CategoryInventory.fromJson(Map<String, dynamic> json) {
    inventoryId = json['inventoryId'];
    pincode = json['pincode'];
    cityName = json['cityName'];
    if (json['batches'] != null) {
      batches = <CategoryBatch>[];
      json['batches'].forEach((v) {
        batches!.add(CategoryBatch.fromJson(v));
      });
    }
  }
}

class CategoryBatch {
  String? batchNumber;
  int? quantity;
  num? mrp;
  num? sellingPrice;
  String? sId;

  CategoryBatch({this.batchNumber, this.quantity, this.mrp, this.sellingPrice, this.sId});

  CategoryBatch.fromJson(Map<String, dynamic> json) {
    batchNumber = json['batchNumber'];
    quantity = json['quantity'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    sId = json['_id'];
  }
}
