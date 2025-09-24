class GenerateAiProductContent {
  final String? name;
  final String? description;
  final String? brand;
  final String? userGuide;
  final num? mrpPerUnit;
  final ExpiryTime? expiryTime;
  final ProductWarranty? productWarranty;
  final List<String>? tags;
  final List<AddMoreDetail>? addMoreDetails;
  final List<AddProductFeature>? addProductFeatures;
  final LinkOrReferralWebsite? linkOrReferealWebsite;
  final List<Varient>? varient;

  GenerateAiProductContent({
    this.name,
    this.description,
    this.brand,
    this.userGuide,
    this.productWarranty,
    this.mrpPerUnit,
    this.expiryTime,
    this.tags,
    this.addMoreDetails,
    this.addProductFeatures,
    this.linkOrReferealWebsite,
    this.varient,
  });

  factory GenerateAiProductContent.fromJson(Map<String, dynamic> json) {
    return GenerateAiProductContent(
      name: json['name'],
      description: json['description'],
      brand: json['brand'],
      userGuide: json['user_guide'],
      mrpPerUnit: json['mrp_per_unit'],
      productWarranty: json['productWarrenty'] != null
          ? ProductWarranty.fromJson(json['productWarrenty'])
          : null,
      expiryTime: json['expiry_time'] != null
          ? ExpiryTime.fromJson(json['expiry_time'])
          : null,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      addMoreDetails: (json['addMoreDetails'] as List?)
          ?.map((e) => AddMoreDetail.fromJson(e))
          .toList(),
      addProductFeatures: (json['addProductFeatures'] as List?)
          ?.map((e) => AddProductFeature.fromJson(e))
          .toList(),
      linkOrReferealWebsite: json['linkOrReferealWebsite'] != null
          ? LinkOrReferralWebsite.fromJson(json['linkOrReferealWebsite'])
          : null,
      varient: (json['varient'] as List?)
          ?.map((e) => Varient.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'brand': brand,
      'user_guide': userGuide,
      'productWarrenty': productWarranty?.toJson,
      'mrp_per_unit': mrpPerUnit,
      'expiry_time': expiryTime?.toJson(),
      'tags': tags,
      'addMoreDetails': addMoreDetails?.map((e) => e.toJson()).toList(),
      'addProductFeatures': addProductFeatures?.map((e) => e.toJson()).toList(),
      'linkOrReferealWebsite': linkOrReferealWebsite?.toJson(),
      'varient': varient?.map((e) => e.toJson()).toList(),
    };
  }

  GenerateAiProductContent copyWith({
    String? name,
    String? description,
    String? brand,
    String? userGuide,
    ProductWarranty? productWarrenty,
    num? mrpPerUnit,
    ExpiryTime? expiryTime,
    List<String>? tags,
    List<AddMoreDetail>? addMoreDetails,
    List<AddProductFeature>? addProductFeatures,
    LinkOrReferralWebsite? linkOrReferealWebsite,
    List<Varient>? varient,
  }) {
    return GenerateAiProductContent(
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      userGuide: userGuide ?? this.userGuide,
      productWarranty: productWarrenty ?? this.productWarranty,
      mrpPerUnit: mrpPerUnit ?? this.mrpPerUnit,
      expiryTime: expiryTime ?? this.expiryTime,
      tags: tags ?? this.tags,
      addMoreDetails: addMoreDetails ?? this.addMoreDetails,
      addProductFeatures: addProductFeatures ?? this.addProductFeatures,
      linkOrReferealWebsite: linkOrReferealWebsite ?? this.linkOrReferealWebsite,
      varient: varient ?? this.varient,
    );
  }
}

class ProductWarranty {
  final int? date;
  final int? month;
  final int? year;
  final int? week;
  final bool? lifetime;

  ProductWarranty({this.date, this.month, this.year, this.week, this.lifetime});

  factory ProductWarranty.fromJson(Map<String, dynamic> json) {
    return ProductWarranty(
      date: json['date'],
      month: json['month'],
      year: json['year'],
      week: json['week'],
      lifetime: json['lifetime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'month': month,
      'year': year,
      'week': week,
      'lifetime': lifetime,
    };
  }

  ProductWarranty copyWith({
    int? date,
    int? month,
    int? year,
    int? week,
    bool? lifetime,
  }) {
    return ProductWarranty(
      date: date ?? this.date,
      month: month ?? this.month,
      year: year ?? this.year,
      week: week ?? this.week,
      lifetime: lifetime ?? this.lifetime,
    );
  }

  /// Convert to human-readable string
  String get asText {
    // if (lifetime == true) return "Lifetime";

    if (year != null && year! > 0) {
      return year == 1 ? "1 Year" : "$year Years";
    }
    if (month != null && month! > 0) {
      return month == 1 ? "1 Month" : "$month Months";
    }
    if (week != null && week! > 0) {
      return week == 1 ? "1 Week" : "$week Weeks";
    }
    if (date != null && date! > 0) {
      return date == 1 ? "1 Day" : "$date Days";
    }
    return "No Expiry";
  }

  /// Convert to dropdown binding (durationType + value)
  Map<String, dynamic> get asDropdownBinding {
    // if (lifetime == true) {
    //   return {"type": "Life Time", "value": 1};
    // }
    if (year != null && year! > 0) {
      return {"type": "Year", "value": year};
    }
    if (month != null && month! > 0) {
      return {"type": "Month", "value": month};
    }
    if (week != null && week! > 0) {
      return {"type": "Week", "value": week};
    }
    if (date != null && date! > 0) {
      return {"type": "Day", "value": date};
    }
    return {"type": "Day", "value": 1};
  }
}

class ExpiryTime {
  final int? date;
  final int? month;
  final int? year;
  final int? week;
  final bool? lifetime;

  ExpiryTime({this.date, this.month, this.year, this.week, this.lifetime});

  factory ExpiryTime.fromJson(Map<String, dynamic> json) {
    return ExpiryTime(
      date: json['date'],
      month: json['month'],
      year: json['year'],
      week: json['week'],
      lifetime: json['lifetime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'month': month,
      'year': year,
      'week': week,
      'lifetime': lifetime,
    };
  }

  ExpiryTime copyWith({
    int? date,
    int? month,
    int? year,
    int? week,
    bool? lifetime,
  }) {
    return ExpiryTime(
      date: date ?? this.date,
      month: month ?? this.month,
      year: year ?? this.year,
      week: week ?? this.week,
      lifetime: lifetime ?? this.lifetime,
    );
  }

  /// Convert to human-readable string
  String get asText {
    if (lifetime == true) return "Lifetime";

    if (year != null && year! > 0) {
      return year == 1 ? "1 Year" : "$year Years";
    }
    if (month != null && month! > 0) {
      return month == 1 ? "1 Month" : "$month Months";
    }
    if (week != null && week! > 0) {
      return week == 1 ? "1 Week" : "$week Weeks";
    }
    if (date != null && date! > 0) {
      return date == 1 ? "1 Day" : "$date Days";
    }
    return "No Expiry";
  }

  /// Convert to dropdown binding (durationType + value)
  Map<String, dynamic> get asDropdownBinding {
    if (lifetime == true) {
      return {"type": "Life Time", "value": 1};
    }
    if (year != null && year! > 0) {
      return {"type": "Year", "value": year};
    }
    if (month != null && month! > 0) {
      return {"type": "Month", "value": month};
    }
    if (week != null && week! > 0) {
      return {"type": "Week", "value": week};
    }
    if (date != null && date! > 0) {
      return {"type": "Day", "value": date};
    }
    return {"type": "Day", "value": 1};
  }
}

class AddMoreDetail {
  final String? title;
  final String? details;

  AddMoreDetail({this.title, this.details});

  factory AddMoreDetail.fromJson(Map<String, dynamic> json) {
    return AddMoreDetail(
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

  AddMoreDetail copyWith({
    String? title,
    String? details,
  }) {
    return AddMoreDetail(
      title: title ?? this.title,
      details: details ?? this.details,
    );
  }
}

class AddProductFeature {
  final String? title;

  AddProductFeature({this.title});

  factory AddProductFeature.fromJson(Map<String, dynamic> json) {
    return AddProductFeature(title: json['title']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title};
  }

  AddProductFeature copyWith({String? title}) {
    return AddProductFeature(title: title ?? this.title);
  }
}

class LinkOrReferralWebsite {
  final String? title;

  LinkOrReferralWebsite({this.title});

  factory LinkOrReferralWebsite.fromJson(Map<String, dynamic> json) {
    return LinkOrReferralWebsite(title: json['title']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title};
  }

  LinkOrReferralWebsite copyWith({String? title}) {
    return LinkOrReferralWebsite(title: title ?? this.title);
  }
}

class Varient {
  final Attributes? attributes;
  final String? sku;
  final String? hsn;
  final num? sellingPrice;
  final num? mrp;

  Varient({
    this.attributes,
    this.sku,
    this.hsn,
    this.sellingPrice,
    this.mrp,
  });

  factory Varient.fromJson(Map<String, dynamic> json) {
    return Varient(
      attributes: json['attributes'] != null
          ? Attributes.fromJson(json['attributes'])
          : null,
      sku: json['sku'],
      hsn: json['hsn'],
      sellingPrice: json['sellingPrice'],
      mrp: json['mrp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attributes': attributes?.toJson(),
      'sku': sku,
      'hsn': hsn,
      'sellingPrice': sellingPrice,
      'mrp': mrp,
    };
  }

  Varient copyWith({
    Attributes? attributes,
    String? sku,
    String? hsn,
    num? sellingPrice,
    num? mrp,
  }) {
    return Varient(
      attributes: attributes ?? this.attributes,
      sku: sku ?? this.sku,
      hsn: hsn ?? this.hsn,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
    );
  }
}

class Attributes {
  final String? color;
  final String? size;

  Attributes({this.color, this.size});

  factory Attributes.fromJson(Map<String, dynamic> json) {
    return Attributes(
      color: json['color'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'size': size,
    };
  }

  Attributes copyWith({
    String? color,
    String? size,
  }) {
    return Attributes(
      color: color ?? this.color,
      size: size ?? this.size,
    );
  }
}
