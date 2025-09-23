class AddServiceResponseModel {
  final Service? service;
  final UploadUrls? uploadUrls;

  AddServiceResponseModel({this.service, this.uploadUrls});

  factory AddServiceResponseModel.fromJson(Map<String, dynamic> json) {
    return AddServiceResponseModel(
      service: json['service'] != null ? Service.fromJson(json['service']) : null,
      uploadUrls: json['uploadUrls'] != null ? UploadUrls.fromJson(json['uploadUrls']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service?.toJson(),
      'uploadUrls': uploadUrls?.toJson(),
    };
  }
}

class Service {
  final String? userId;
  final String? type;
  final String? title;
  final String? description;
  final List<String>? photos;
  final List<Timing>? timings;
  final List<String>? facilities;
  final String? priceType;
  final PriceRange? priceRange;
  final String? perUnit;
  final List<Discount>? discounts;
  final List<ExtraDetail>? extraDetails;
  final bool? isActive;
  final bool? isDeleted;
  final String? id;
  final List<dynamic>? addOns;
  final List<dynamic>? priceOptions;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  Service({
    this.userId,
    this.type,
    this.title,
    this.description,
    this.photos,
    this.timings,
    this.facilities,
    this.priceType,
    this.priceRange,
    this.perUnit,
    this.discounts,
    this.extraDetails,
    this.isActive,
    this.isDeleted,
    this.id,
    this.addOns,
    this.priceOptions,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      timings: json['timings'] != null
          ? List<Timing>.from(json['timings'].map((x) => Timing.fromJson(x)))
          : null,
      facilities: json['facilities'] != null ? List<String>.from(json['facilities']) : null,
      priceType: json['priceType'],
      priceRange: json['priceRange'] != null ? PriceRange.fromJson(json['priceRange']) : null,
      perUnit: json['perUnit'],
      discounts: json['discounts'] != null
          ? List<Discount>.from(json['discounts'].map((x) => Discount.fromJson(x)))
          : null,
      extraDetails: json['extraDetails'] != null
          ? List<ExtraDetail>.from(json['extraDetails'].map((x) => ExtraDetail.fromJson(x)))
          : null,
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      id: json['_id'],
      addOns: json['addOns'] ?? [],
      priceOptions: json['priceOptions'] ?? [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'photos': photos,
      'timings': timings?.map((x) => x.toJson()).toList(),
      'facilities': facilities,
      'priceType': priceType,
      'priceRange': priceRange?.toJson(),
      'perUnit': perUnit,
      'discounts': discounts?.map((x) => x.toJson()).toList(),
      'extraDetails': extraDetails?.map((x) => x.toJson()).toList(),
      'isActive': isActive,
      'isDeleted': isDeleted,
      '_id': id,
      'addOns': addOns,
      'priceOptions': priceOptions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

class Timing {
  final String? start;
  final String? end;
  final bool? special;

  Timing({this.start, this.end, this.special});

  factory Timing.fromJson(Map<String, dynamic> json) {
    return Timing(
      start: json['start'],
      end: json['end'],
      special: json['special'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'special': special,
    };
  }
}

class PriceRange {
  final int? min;
  final int? max;

  PriceRange({this.min, this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: json['min'],
      max: json['max'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

class Discount {
  final String? name;
  final String? description;
  final String? type;

  Discount({this.name, this.description, this.type});

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      name: json['name'],
      description: json['description'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
    };
  }
}

class ExtraDetail {
  final String? title;
  final String? details;

  ExtraDetail({this.title, this.details});

  factory ExtraDetail.fromJson(Map<String, dynamic> json) {
    return ExtraDetail(
      title: json['title'],
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details': details,
    };
  }
}

class UploadUrls {
  final List<String>? images;

  UploadUrls({this.images});

  factory UploadUrls.fromJson(Map<String, dynamic> json) {
    return UploadUrls(
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'images': images,
    };
  }
}
