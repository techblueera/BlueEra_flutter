/// Response model for GET /riders/associations/shops
class AssociatedShopsResponse {
  List<AssociatedShop>? shops;
  AssociatedShopsPagination? pagination;

  AssociatedShopsResponse({this.shops, this.pagination});

  AssociatedShopsResponse.fromJson(dynamic json) {
    if (json['shops'] != null) {
      shops = [];
      json['shops'].forEach((v) {
        shops!.add(AssociatedShop.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? AssociatedShopsPagination.fromJson(json['pagination'])
        : null;
  }
}

class AssociatedShop {
  String? associationId;
  String? businessUserId;
  AssociatedBusiness? business;
  String? distance;
  AssociatedGrocery? grocery;

  AssociatedShop({
    this.associationId,
    this.businessUserId,
    this.business,
    this.distance,
    this.grocery,
  });

  AssociatedShop.fromJson(dynamic json) {
    associationId = json['associationId'];
    businessUserId = json['businessUserId'];
    business = json['business'] != null
        ? AssociatedBusiness.fromJson(json['business'])
        : null;
    distance = json['distance'];
    grocery = json['grocery'] != null
        ? AssociatedGrocery.fromJson(json['grocery'])
        : null;
  }
}

class AssociatedBusiness {
  String? id;
  String? businessName;
  String? logo;
  AssociatedCategory? categoryOfBusiness;
  String? address;
  String? cityStatePincode;
  AssociatedLocation? businessLocation;
  AssociatedBusinessNumber? businessNumber;
  num? avgRating;
  num? totalRatings;
  bool? isActive;
  bool? businessIsVerified;

  AssociatedBusiness({
    this.id,
    this.businessName,
    this.logo,
    this.categoryOfBusiness,
    this.address,
    this.cityStatePincode,
    this.businessLocation,
    this.businessNumber,
    this.avgRating,
    this.totalRatings,
    this.isActive,
    this.businessIsVerified,
  });

  AssociatedBusiness.fromJson(dynamic json) {
    id = json['id'];
    businessName = json['business_name'];
    logo = json['logo'];
    categoryOfBusiness = json['category_of_business'] != null
        ? AssociatedCategory.fromJson(json['category_of_business'])
        : null;
    address = json['address'];
    cityStatePincode = json['city_state_pincode'];
    businessLocation = json['business_location'] != null
        ? AssociatedLocation.fromJson(json['business_location'])
        : null;
    businessNumber = json['business_number'] != null
        ? AssociatedBusinessNumber.fromJson(json['business_number'])
        : null;
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings'];
    isActive = json['isActive'];
    businessIsVerified = json['business_isVerified'];
  }
}

class AssociatedCategory {
  String? name;

  AssociatedCategory({this.name});

  AssociatedCategory.fromJson(dynamic json) {
    name = json['name'];
  }
}

class AssociatedLocation {
  num? lat;
  num? lon;

  AssociatedLocation({this.lat, this.lon});

  AssociatedLocation.fromJson(dynamic json) {
    lat = json['lat'];
    lon = json['lon'];
  }
}

class AssociatedBusinessNumber {
  AssociatedPhoneNumber? officeMobNo;

  AssociatedBusinessNumber({this.officeMobNo});

  AssociatedBusinessNumber.fromJson(dynamic json) {
    officeMobNo = json['office_mob_no'] != null
        ? AssociatedPhoneNumber.fromJson(json['office_mob_no'])
        : null;
  }
}

class AssociatedPhoneNumber {
  String? number;

  AssociatedPhoneNumber({this.number});

  AssociatedPhoneNumber.fromJson(dynamic json) {
    number = json['number'];
  }
}

class AssociatedGrocery {
  int? totalProducts;
  List<AssociatedParentCategory>? parentCategories;

  AssociatedGrocery({this.totalProducts, this.parentCategories});

  AssociatedGrocery.fromJson(dynamic json) {
    totalProducts = json['totalProducts'];
    if (json['parentCategories'] != null) {
      parentCategories = [];
      json['parentCategories'].forEach((v) {
        parentCategories!.add(AssociatedParentCategory.fromJson(v));
      });
    }
  }
}

class AssociatedParentCategory {
  AssociatedCategoryInfo? category;
  int? count;

  AssociatedParentCategory({this.category, this.count});

  AssociatedParentCategory.fromJson(dynamic json) {
    category = json['category'] != null
        ? AssociatedCategoryInfo.fromJson(json['category'])
        : null;
    count = json['count'];
  }
}

class AssociatedCategoryInfo {
  String? id;
  String? name;
  String? image;

  AssociatedCategoryInfo({this.id, this.name, this.image});

  AssociatedCategoryInfo.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
  }
}

class AssociatedShopsPagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  AssociatedShopsPagination({this.page, this.limit, this.total, this.totalPages});

  AssociatedShopsPagination.fromJson(dynamic json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    totalPages = json['totalPages'];
  }
}
