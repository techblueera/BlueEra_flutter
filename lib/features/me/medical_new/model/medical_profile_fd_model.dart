class MedicalProfileFdModel {
  MedicalProfile? profile;
  MedicalContactInfo? contactInfo;
  List<MedicalGallery>? galleries;
  List<MedicalTestimonial>? testimonials;
  List<MedicalPopularProduct>? popularProducts;

  MedicalProfileFdModel({this.profile, this.contactInfo, this.galleries, this.testimonials, this.popularProducts});

  MedicalProfileFdModel.fromJson(Map<String, dynamic> json) {
    profile = json['profile'] != null ? MedicalProfile.fromJson(json['profile']) : null;
    contactInfo = json['contactInfo'] != null ? MedicalContactInfo.fromJson(json['contactInfo']) : null;
    if (json['galleries'] != null) {
      galleries = <MedicalGallery>[];
      json['galleries'].forEach((v) => galleries!.add(MedicalGallery.fromJson(v)));
    }
    if (json['testimonials'] != null) {
      testimonials = <MedicalTestimonial>[];
      json['testimonials'].forEach((v) => testimonials!.add(MedicalTestimonial.fromJson(v)));
    }
    if (json['popularProducts'] != null) {
      popularProducts = <MedicalPopularProduct>[];
      json['popularProducts'].forEach((v) => popularProducts!.add(MedicalPopularProduct.fromJson(v)));
    }
  }
}

class MedicalProfile {
  String? id;
  String? name;
  String? description;
  String? coverUrl;
  String? logoUrl;
  String? userId;
  String? businessId;

  MedicalProfile({this.id, this.name, this.description, this.coverUrl, this.logoUrl, this.userId, this.businessId});

  MedicalProfile.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    coverUrl = json['coverUrl'];
    logoUrl = json['logoUrl'];
    userId = json['userId'];
    businessId = json['businessId'];
  }
}

class MedicalAboutUs {
  String? id;
  String? logo;
  String? medicalStoreImage;
  String? businessId;

  MedicalAboutUs({this.id, this.logo, this.medicalStoreImage, this.businessId});

  MedicalAboutUs.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    logo = json['logo'];
    medicalStoreImage = json['medicalStoreImage'];
    businessId = json['businessId'];
  }
}

class MedicalContactInfo {
  String? id;
  String? pharmacyName;
  String? name;
  String? email;
  String? phoneNo;
  String? phone;
  String? websiteUrl;
  String? website;
  String? address;
  String? pincode;
  String? description;
  String? openFrom;
  String? openTill;
  MedicalLocation? location;
  String? businessId;

  MedicalContactInfo({
    this.id,
    this.pharmacyName,
    this.name,
    this.email,
    this.phoneNo,
    this.phone,
    this.websiteUrl,
    this.website,
    this.address,
    this.pincode,
    this.description,
    this.openFrom,
    this.openTill,
    this.location,
    this.businessId,
  });

  MedicalContactInfo.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    pharmacyName = json['pharmacyName'];
    name = json['name'];
    email = json['email'];
    phoneNo = json['phoneNo'];
    phone = json['phone'];
    websiteUrl = json['websiteUrl'];
    website = json['website'];
    address = json['address'];
    pincode = json['pincode'];
    description = json['description'];
    openFrom = json['openFrom'];
    openTill = json['openTill'];
    location = json['location'] != null ? MedicalLocation.fromJson(json['location']) : null;
    businessId = json['businessId'];
  }
}

class MedicalTestimonial {
  String? id;
  String? name;
  String? image;
  num? rating;
  String? message;
  String? designation;
  bool? isActive;
  String? businessId;
  String? createdAt;
  String? updatedAt;

  MedicalTestimonial({
    this.id,
    this.name,
    this.image,
    this.rating,
    this.message,
    this.designation,
    this.isActive,
    this.businessId,
    this.createdAt,
    this.updatedAt,
  });

  MedicalTestimonial.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    image = json['image'];
    rating = json['rating'];
    message = json['message'];
    designation = json['designation'];
    isActive = json['isActive'];
    businessId = json['businessId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
}

class NearestPharmacy {
  String? id;
  String? pharmacyName;
  String? address;
  String? pincode;
  String? phone;
  double? distance;
  MedicalLocation? location;

  NearestPharmacy({
    this.id,
    this.pharmacyName,
    this.address,
    this.pincode,
    this.phone,
    this.distance,
    this.location,
  });

  NearestPharmacy.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    pharmacyName = json['pharmacyName'];
    address = json['address'];
    pincode = json['pincode'];
    phone = json['phone'];
    distance = (json['distance'] as num?)?.toDouble();
    location = json['location'] != null ? MedicalLocation.fromJson(json['location']) : null;
  }
}

class MedicalLocation {
  String? name;
  String? type;
  List<double>? coordinates;

  MedicalLocation({this.name, this.type, this.coordinates});

  MedicalLocation.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'] != null
        ? List<double>.from(json['coordinates'].map((x) => (x as num).toDouble()))
        : null;
  }
}

class MedicalGallery {
  String? id;
  String? title;
  List<String>? imageUrls;

  MedicalGallery({this.id, this.title, this.imageUrls});

  MedicalGallery.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    title = json['title'];
    imageUrls = json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [];
  }
}

class MedicalPopularProduct {
  String? id;
  String? name;
  List<MedicalProductImage>? images;
  List<MedicalProductVariant>? variants;

  MedicalPopularProduct({this.id, this.name, this.images, this.variants});

  MedicalPopularProduct.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    if (json['images'] != null) {
      images = <MedicalProductImage>[];
      json['images'].forEach((v) => images!.add(MedicalProductImage.fromJson(v)));
    }
    if (json['variants'] != null) {
      variants = <MedicalProductVariant>[];
      json['variants'].forEach((v) => variants!.add(MedicalProductVariant.fromJson(v)));
    }
  }
}

class MedicalProductImage {
  String? url;
  String? id;

  MedicalProductImage({this.url, this.id});

  MedicalProductImage.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    id = json['_id'];
  }
}

class MedicalProductVariant {
  String? id;
  num? weight;
  String? unit;
  MedicalPricing? pricing;

  MedicalProductVariant({this.id, this.weight, this.unit, this.pricing});

  MedicalProductVariant.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    weight = json['weight'];
    unit = json['unit'];
    pricing = json['pricing'] != null ? MedicalPricing.fromJson(json['pricing']) : null;
  }
}

class MedicalPricing {
  num? mrp;
  num? sellingPrice;
  num? discount;

  MedicalPricing({this.mrp, this.sellingPrice, this.discount});

  MedicalPricing.fromJson(Map<String, dynamic> json) {
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    discount = json['discount'];
  }
}
