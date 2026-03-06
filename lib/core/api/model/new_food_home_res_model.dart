import 'dart:convert';
FoodHomeResModel newFoodHomeResModelFromJson(String str) => FoodHomeResModel.fromJson(json.decode(str));
String newFoodHomeResModelToJson(FoodHomeResModel data) => json.encode(data.toJson());
class FoodHomeResModel {
  FoodHomeResModel({
      this.success, 
      this.data,});

  FoodHomeResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? FoodData.fromJson(json['data']) : null;
  }
  bool? success;
  FoodData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

FoodData dataFromJson(String str) => FoodData.fromJson(json.decode(str));
String dataToJson(FoodData data) => json.encode(data.toJson());
class FoodData {
  FoodData({
      this.foodMenu, 
      this.restaurantSpecials,
      this.businessProfile,
    this.gallery,
      this.contact,

  });

  FoodData.fromJson(dynamic json) {
    businessProfile = json['businessProfile'] != null ? BusinessProfile.fromJson(json['businessProfile']) : null;

    if (json['foodMenu'] != null) {
      foodMenu = [];
      json['foodMenu'].forEach((v) {
        foodMenu?.add(FoodMenu.fromJson(v));
      });
    }
    if (json['restaurantSpecials'] != null) {
      restaurantSpecials = [];
      json['restaurantSpecials'].forEach((v) {
        // restaurantSpecials?.add(Dynamic.fromJson(v));
      });
    }
    if (json['gallery'] != null) {
      gallery = [];
      json['gallery'].forEach((v) {
        gallery?.add(Gallery.fromJson(v));
      });
    }
    contact = json['contact'] != null ? Contact.fromJson(json['contact']) : null;
  }
  List<FoodMenu>? foodMenu;
  List<dynamic>? restaurantSpecials;
  List<Gallery>? gallery;
  Contact? contact;

  BusinessProfile? businessProfile;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (businessProfile != null) {
      map['businessProfile'] = businessProfile?.toJson();
    }
    if (foodMenu != null) {
      map['foodMenu'] = foodMenu?.map((v) => v.toJson()).toList();
    }
    if (restaurantSpecials != null) {
      map['restaurantSpecials'] = restaurantSpecials?.map((v) => v.toJson()).toList();
    }
    if (gallery != null) {
      map['gallery'] = gallery?.map((v) => v.toJson()).toList();
    }
    if (contact != null) {
      map['contact'] = contact?.toJson();
    }

    return map;
  }

}

Contact contactFromJson(String str) => Contact.fromJson(json.decode(str));
String contactToJson(Contact data) => json.encode(data.toJson());
class Contact {
  Contact({
      this.id, 
      this.businessId, 
      this.v, 
      this.createdAt, 
      this.department, 
      this.email, 
      this.location, 
      this.name, 
      this.pageLink, 
      this.phone, 
      this.updatedAt,});

  Contact.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    department = json['department'];
    email = json['email'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    name = json['name'];
    pageLink = json['pageLink'];
    phone = json['phone'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? businessId;
  int? v;
  String? createdAt;
  String? department;
  String? email;
  Location? location;
  String? name;
  String? pageLink;
  String? phone;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['department'] = department;
    map['email'] = email;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['name'] = name;
    map['pageLink'] = pageLink;
    map['phone'] = phone;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.name, 
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? name;
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}

Gallery galleryFromJson(String str) => Gallery.fromJson(json.decode(str));
String galleryToJson(Gallery data) => json.encode(data.toJson());
class Gallery {
  Gallery({
      this.id, 
      this.businessId, 
      this.imageUrls, 
      this.title, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Gallery.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    imageUrls = json['imageUrls'] != null ? json['imageUrls'].cast<String>() : [];
    title = json['title'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  List<String>? imageUrls;
  String? title;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['imageUrls'] = imageUrls;
    map['title'] = title;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

FoodMenu foodMenuFromJson(String str) => FoodMenu.fromJson(json.decode(str));
String foodMenuToJson(FoodMenu data) => json.encode(data.toJson());
class FoodMenu {
  FoodMenu({
      this.id, 
      this.name, 
      this.key, 
      this.isActive, 
      this.parentId, 
      this.level, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.image, 
      this.subCategories,});

  FoodMenu.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    image = json['image'];
    if (json['subCategories'] != null) {
      subCategories = [];
      json['subCategories'].forEach((v) {
        subCategories?.add(SubCategories.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? key;
  bool? isActive;
  dynamic parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? image;
  List<SubCategories>? subCategories;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['image'] = image;
    if (subCategories != null) {
      map['subCategories'] = subCategories?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

SubCategories subCategoriesFromJson(String str) => SubCategories.fromJson(json.decode(str));
String subCategoriesToJson(SubCategories data) => json.encode(data.toJson());
class SubCategories {
  SubCategories({
      this.id, 
      this.name, 
      this.key, 
      this.type, 
      this.isActive, 
      this.parentId, 
      this.level, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.image, 
      this.items,});

  SubCategories.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    type = json['type'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    image = json['image'];
    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items?.add(Items.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? key;
  String? type;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? image;
  List<Items>? items;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['type'] = type;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['image'] = image;
    if (items != null) {
      map['items'] = items?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Items itemsFromJson(String str) => Items.fromJson(json.decode(str));
String itemsToJson(Items data) => json.encode(data.toJson());
class Items {
  Items({
      this.id, 
      this.businessId, 
      this.productVariant, 
      this.product, 
      this.location, 
      this.price, 
      this.isAvailable, 
      this.preparationTime, 
      this.rating, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Items.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    if (json['productVariant'] != null) {
      productVariant = [];
      json['productVariant'].forEach((v) {
        productVariant?.add(ProductVariant.fromJson(v));
      });
    }
    product = json['product'] != null ? Product.fromJson(json['product']) : null;
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    price = json['price'] != null ? Price.fromJson(json['price']) : null;
    isAvailable = json['isAvailable'];
    preparationTime = json['preparationTime'];
    rating = json['rating'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  List<ProductVariant>? productVariant;
  Product? product;
  Location? location;
  Price? price;
  bool? isAvailable;
  int? preparationTime;
  int? rating;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    if (productVariant != null) {
      map['productVariant'] = productVariant?.map((v) => v.toJson()).toList();
    }
    if (product != null) {
      map['product'] = product?.toJson();
    }
    if (location != null) {
      map['location'] = location?.toJson();
    }
    if (price != null) {
      map['price'] = price?.toJson();
    }
    map['isAvailable'] = isAvailable;
    map['preparationTime'] = preparationTime;
    map['rating'] = rating;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Price priceFromJson(String str) => Price.fromJson(json.decode(str));
String priceToJson(Price data) => json.encode(data.toJson());
class Price {
  Price({
      this.mrp, 
      this.sellingPrice, 
      this.currency, 
      this.packingCharges,});

  Price.fromJson(dynamic json) {
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    packingCharges = json['packingCharges'];
  }
  int? mrp;
  int? sellingPrice;
  String? currency;
  int? packingCharges;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['mrp'] = mrp;
    map['sellingPrice'] = sellingPrice;
    map['currency'] = currency;
    map['packingCharges'] = packingCharges;
    return map;
  }

}


Product productFromJson(String str) => Product.fromJson(json.decode(str));
String productToJson(Product data) => json.encode(data.toJson());
class Product {
  Product({
      this.id, 
      this.name, 
      this.description, 
      this.images, 
      this.dietaryType,});

  Product.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    dietaryType = json['dietaryType'];
  }
  String? id;
  String? name;
  String? description;
  List<String>? images;
  String? dietaryType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['images'] = images;
    map['dietaryType'] = dietaryType;
    return map;
  }

}

ProductVariant productVariantFromJson(String str) => ProductVariant.fromJson(json.decode(str));
String productVariantToJson(ProductVariant data) => json.encode(data.toJson());
class ProductVariant {
  ProductVariant({
      this.id, 
      this.variantName, 
      this.quantityLabel,});

  ProductVariant.fromJson(dynamic json) {
    id = json['_id'];
    variantName = json['variantName'];
    quantityLabel = json['quantityLabel'];
  }
  String? id;
  String? variantName;
  String? quantityLabel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['variantName'] = variantName;
    map['quantityLabel'] = quantityLabel;
    return map;
  }

}



BusinessProfile businessProfileFromJson(String str) => BusinessProfile.fromJson(json.decode(str));
String businessProfileToJson(BusinessProfile data) => json.encode(data.toJson());
class BusinessProfile {
  BusinessProfile({
    this.ownerDetails,
    this.livePhotos,
    this.ratings,
    this.id,
    this.userId,
    this.businessName,
    this.dateOfIncorporation,
    this.typeOfBusiness,
    this.logo,
    this.categoryOfBusiness,
    this.subCategoryOfBusiness,
    this.businessDescription,
    this.businessNumber,
    this.natureOfBusiness,
    this.cityStatePincode,
    this.address,
    this.gst,
    this.isActive,
    this.businessIsVerified,
    this.businessLocation,
    this.websiteUrl,
    this.createdAt,
    this.updatedAt,
    this.avgRating,
    this.totalRatings,});

  BusinessProfile.fromJson(dynamic json) {
    if (json['owner_details'] != null) {
      ownerDetails = [];
      json['owner_details'].forEach((v) {
        ownerDetails?.add(OwnerDetails.fromJson(v));
      });
    }
    livePhotos = json['live_photos'] != null ? json['live_photos'].cast<String>() : [];
    if (json['ratings'] != null) {
      ratings = [];
      json['ratings'].forEach((v) {
        // ratings?.add(Dynamic.fromJson(v));
      });
    }
    id = json['id'];
    userId = json['user_id'];
    businessName = json['business_name'];
    dateOfIncorporation = json['date_of_incorporation'] != null ? DateOfIncorporation.fromJson(json['date_of_incorporation']) : null;
    typeOfBusiness = json['type_of_business'];
    logo = json['logo'];
    categoryOfBusiness = json['category_of_business'];
    subCategoryOfBusiness = json['sub_category_of_business'] != null ? SubCategoryOfBusiness.fromJson(json['sub_category_of_business']) : null;
    businessDescription = json['business_description'];
    businessNumber = json['business_number'] != null ? BusinessNumber.fromJson(json['business_number']) : null;
    natureOfBusiness = json['Nature_of_Business'];
    cityStatePincode = json['city_state_pincode'];
    address = json['address'];
    gst = json['gst'] != null ? Gst.fromJson(json['gst']) : null;
    isActive = json['isActive'];
    businessIsVerified = json['business_isVerified'];
    businessLocation = json['business_location'] != null ? BusinessLocation.fromJson(json['business_location']) : null;
    websiteUrl = json['website_url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings'];
  }
  List<OwnerDetails>? ownerDetails;
  List<String>? livePhotos;
  List<dynamic>? ratings;
  String? id;
  String? userId;
  String? businessName;
  DateOfIncorporation? dateOfIncorporation;
  String? typeOfBusiness;
  String? logo;
  dynamic categoryOfBusiness;
  SubCategoryOfBusiness? subCategoryOfBusiness;
  String? businessDescription;
  BusinessNumber? businessNumber;
  String? natureOfBusiness;
  String? cityStatePincode;
  String? address;
  Gst? gst;
  bool? isActive;
  bool? businessIsVerified;
  BusinessLocation? businessLocation;
  String? websiteUrl;
  String? createdAt;
  String? updatedAt;
  int? avgRating;
  String? totalRatings;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (ownerDetails != null) {
      map['owner_details'] = ownerDetails?.map((v) => v.toJson()).toList();
    }
    map['live_photos'] = livePhotos;
    if (ratings != null) {
      map['ratings'] = ratings?.map((v) => v.toJson()).toList();
    }
    map['id'] = id;
    map['user_id'] = userId;
    map['business_name'] = businessName;
    if (dateOfIncorporation != null) {
      map['date_of_incorporation'] = dateOfIncorporation?.toJson();
    }
    map['type_of_business'] = typeOfBusiness;
    map['logo'] = logo;
    map['category_of_business'] = categoryOfBusiness;
    if (subCategoryOfBusiness != null) {
      map['sub_category_of_business'] = subCategoryOfBusiness?.toJson();
    }
    map['business_description'] = businessDescription;
    if (businessNumber != null) {
      map['business_number'] = businessNumber?.toJson();
    }
    map['Nature_of_Business'] = natureOfBusiness;
    map['city_state_pincode'] = cityStatePincode;
    map['address'] = address;
    if (gst != null) {
      map['gst'] = gst?.toJson();
    }
    map['isActive'] = isActive;
    map['business_isVerified'] = businessIsVerified;
    if (businessLocation != null) {
      map['business_location'] = businessLocation?.toJson();
    }
    map['website_url'] = websiteUrl;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['avg_rating'] = avgRating;
    map['total_ratings'] = totalRatings;
    return map;
  }

}

BusinessLocation businessLocationFromJson(String str) => BusinessLocation.fromJson(json.decode(str));
String businessLocationToJson(BusinessLocation data) => json.encode(data.toJson());
class BusinessLocation {
  BusinessLocation({
    this.lat,
    this.lon,});

  BusinessLocation.fromJson(dynamic json) {
    lat = json['lat'];
    lon = json['lon'];
  }
  double? lat;
  double? lon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lat'] = lat;
    map['lon'] = lon;
    return map;
  }

}

Gst gstFromJson(String str) => Gst.fromJson(json.decode(str));
String gstToJson(Gst data) => json.encode(data.toJson());
class Gst {
  Gst({
    this.have,
    this.number,
    this.gstVerification,});

  Gst.fromJson(dynamic json) {
    have = json['have'];
    number = json['number'];
    gstVerification = json['gst_verification'];
  }
  bool? have;
  String? number;
  bool? gstVerification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['have'] = have;
    map['number'] = number;
    map['gst_verification'] = gstVerification;
    return map;
  }

}

BusinessNumber businessNumberFromJson(String str) => BusinessNumber.fromJson(json.decode(str));
String businessNumberToJson(BusinessNumber data) => json.encode(data.toJson());
class BusinessNumber {
  BusinessNumber({
    this.officeMobNo,
    this.officeLandlineNo,});

  BusinessNumber.fromJson(dynamic json) {
    officeMobNo = json['office_mob_no'] != null ? OfficeMobNo.fromJson(json['office_mob_no']) : null;
    officeLandlineNo = json['office_landline_no'] != null ? OfficeLandlineNo.fromJson(json['office_landline_no']) : null;
  }
  OfficeMobNo? officeMobNo;
  OfficeLandlineNo? officeLandlineNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (officeMobNo != null) {
      map['office_mob_no'] = officeMobNo?.toJson();
    }
    if (officeLandlineNo != null) {
      map['office_landline_no'] = officeLandlineNo?.toJson();
    }
    return map;
  }

}

OfficeLandlineNo officeLandlineNoFromJson(String str) => OfficeLandlineNo.fromJson(json.decode(str));
String officeLandlineNoToJson(OfficeLandlineNo data) => json.encode(data.toJson());
class OfficeLandlineNo {
  OfficeLandlineNo({
    this.pre,
    this.number,});

  OfficeLandlineNo.fromJson(dynamic json) {
    pre = json['pre'];
    number = json['number'];
  }
  int? pre;
  String? number;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['pre'] = pre;
    map['number'] = number;
    return map;
  }

}

OfficeMobNo officeMobNoFromJson(String str) => OfficeMobNo.fromJson(json.decode(str));
String officeMobNoToJson(OfficeMobNo data) => json.encode(data.toJson());
class OfficeMobNo {
  OfficeMobNo({
    this.pre,
    this.number,});

  OfficeMobNo.fromJson(dynamic json) {
    pre = json['pre'];
    number = json['number'];
  }
  int? pre;
  String? number;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['pre'] = pre;
    map['number'] = number;
    return map;
  }

}

SubCategoryOfBusiness subCategoryOfBusinessFromJson(String str) => SubCategoryOfBusiness.fromJson(json.decode(str));
String subCategoryOfBusinessToJson(SubCategoryOfBusiness data) => json.encode(data.toJson());
class SubCategoryOfBusiness {
  SubCategoryOfBusiness({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    this.categoryId,
    this.active,});

  SubCategoryOfBusiness.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    categoryId = json['category_id'];
    active = json['active'];
  }
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? createdBy;
  String? updatedBy;
  String? categoryId;
  bool? active;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['deleted_at'] = deletedAt;
    map['created_by'] = createdBy;
    map['updated_by'] = updatedBy;
    map['category_id'] = categoryId;
    map['active'] = active;
    return map;
  }

}

DateOfIncorporation dateOfIncorporationFromJson(String str) => DateOfIncorporation.fromJson(json.decode(str));
String dateOfIncorporationToJson(DateOfIncorporation data) => json.encode(data.toJson());
class DateOfIncorporation {
  DateOfIncorporation({
    this.date,
    this.month,
    this.year,});

  DateOfIncorporation.fromJson(dynamic json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }
  int? date;
  int? month;
  int? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }

}

OwnerDetails ownerDetailsFromJson(String str) => OwnerDetails.fromJson(json.decode(str));
String ownerDetailsToJson(OwnerDetails data) => json.encode(data.toJson());
class OwnerDetails {
  OwnerDetails({
    this.name,
    this.roleInBusiness,
    this.email,});

  OwnerDetails.fromJson(dynamic json) {
    name = json['name'];
    roleInBusiness = json['role_in_business'];
    email = json['email'];
  }
  String? name;
  String? roleInBusiness;
  String? email;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['role_in_business'] = roleInBusiness;
    map['email'] = email;
    return map;
  }

}