import 'dart:convert';

/// Response model for
/// `GET /api/other-service/business-profile/search?categoryOfBusiness=...`.
///
/// Each item bundles the business profile, its services (whose `title` powers
/// the chips), its weekly timings (for the open/closed pill), and a
/// `priceRange` aggregate (for the footer price label).
class OtherServiceBusinessSearchResModel {
  bool? success;
  List<OtherServiceBusinessItem>? data;

  OtherServiceBusinessSearchResModel({this.success, this.data});

  OtherServiceBusinessSearchResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'] as bool?;
    final raw = json['data'];
    if (raw is List) {
      data = raw
          .whereType<Map>()
          .map((m) =>
              OtherServiceBusinessItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }
}

class OtherServiceBusinessItem {
  OtherBusinessProfile? profile;
  List<OtherServiceItem> services;
  OtherTimings? timings;
  OtherPriceRange? priceRange;
  List<OtherContactUs> contactUs;
  List<OtherManagementItem> management;
  List<OtherGalleryItem> gallery;

  OtherServiceBusinessItem({
    this.profile,
    this.services = const [],
    this.timings,
    this.priceRange,
    this.contactUs = const [],
    this.management = const [],
    this.gallery = const [],
  });

  OtherServiceBusinessItem.fromJson(Map<String, dynamic> json)
      : services = const [],
        contactUs = const [],
        management = const [],
        gallery = const [] {
    final p = json['profile'];
    if (p is Map) {
      profile = OtherBusinessProfile.fromJson(Map<String, dynamic>.from(p));
    }

    final s = json['services'];
    if (s is List) {
      services = s
          .whereType<Map>()
          .map((m) => OtherServiceItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    final t = json['timings'];
    if (t is Map) {
      timings = OtherTimings.fromJson(Map<String, dynamic>.from(t));
    }

    final pr = json['priceRange'];
    if (pr is Map) {
      priceRange = OtherPriceRange.fromJson(Map<String, dynamic>.from(pr));
    }

    final c = json['contactUs'];
    if (c is List) {
      contactUs = c
          .whereType<Map>()
          .map((m) => OtherContactUs.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    final m = json['management'];
    if (m is List) {
      management = m
          .whereType<Map>()
          .map(
              (e) => OtherManagementItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final g = json['gallery'];
    if (g is List) {
      gallery = g
          .whereType<Map>()
          .map((e) => OtherGalleryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  String? get id => profile?.id;
}

class OtherBusinessProfile {
  String? id;
  String? businessId;
  String? userId;
  String? profileName;
  String? businessName;
  String? type;
  String? typeOfBusiness;
  String? categoryOfBusiness;
  String? subCategoryOfBusiness;
  /// Human-readable category label from `/full` (`category_details.name`).
  /// The hero uses this in preference to the raw `categoryOfBusiness` slug
  /// (e.g. "Banking Sector" vs. "BANKING_SECTOR").
  String? categoryDetailsName;
  /// Human-readable sub-category label from `/full`
  /// (`sub_category_details.name`), e.g. "Digital Bank".
  String? subCategoryDetailsName;
  /// `profile.rating` — legacy integer field, kept for back-compat with the
  /// search-list rendering. `avgRating` from `/full` is the display value.
  double? rating;
  /// `profile.avg_rating` from `/full` — the server-computed average that
  /// the hero shows next to `totalRatings`.
  double? avgRating;
  /// `profile.total_ratings` from `/full` — used to render "(N reviews)".
  int? totalRatings;
  String? coverUrl;
  String? logoUrl;
  String? address;
  /// `profile.business_description` from `/full` — the paragraph the hero
  /// renders in its description block.
  String? businessDescription;
  /// `profile.website_url` from `/full`.
  String? websiteUrl;
  OtherLatLng? businessLocation;
  OtherProfileLocation? location;
  OtherDateOfIncorporation? dateOfIncorporation;

  OtherBusinessProfile({
    this.id,
    this.businessId,
    this.userId,
    this.profileName,
    this.businessName,
    this.type,
    this.typeOfBusiness,
    this.categoryOfBusiness,
    this.subCategoryOfBusiness,
    this.categoryDetailsName,
    this.subCategoryDetailsName,
    this.rating,
    this.avgRating,
    this.totalRatings,
    this.coverUrl,
    this.logoUrl,
    this.address,
    this.businessDescription,
    this.websiteUrl,
    this.businessLocation,
    this.location,
    this.dateOfIncorporation,
  });

  OtherBusinessProfile.fromJson(Map<String, dynamic> json) {
    id = json['_id']?.toString();
    businessId = json['businessId']?.toString();
    userId = json['userId']?.toString();
    profileName = json['profileName']?.toString();
    businessName = (json['business_name'] ?? json['businessName'])?.toString();
    type = json['type']?.toString();
    typeOfBusiness = json['type_of_business']?.toString();
    categoryOfBusiness = json['category_Of_Business']?.toString();
    subCategoryOfBusiness = json['sub_category_Of_Business']?.toString();
    final catDetails = json['category_details'];
    if (catDetails is Map) {
      categoryDetailsName = catDetails['name']?.toString();
    }
    final subCatDetails = json['sub_category_details'];
    if (subCatDetails is Map) {
      subCategoryDetailsName = subCatDetails['name']?.toString();
    }
    final r = json['rating'];
    rating = r is num ? r.toDouble() : null;
    final avg = json['avg_rating'];
    avgRating = avg is num ? avg.toDouble() : null;
    final tot = json['total_ratings'];
    totalRatings = tot is num ? tot.toInt() : null;
    coverUrl = json['coverUrl']?.toString();
    logoUrl = json['logoUrl']?.toString();
    address = (json['address'] ?? json['full_address'])?.toString();
    businessDescription = json['business_description']?.toString();
    websiteUrl = json['website_url']?.toString();
    businessLocation = OtherLatLng.fromRaw(json['business_location']);
    final l = json['location'];
    if (l is Map) {
      location = OtherProfileLocation.fromJson(Map<String, dynamic>.from(l));
    }
    final doi = json['date_of_incorporation'];
    if (doi is Map) {
      dateOfIncorporation =
          OtherDateOfIncorporation.fromJson(Map<String, dynamic>.from(doi));
    }
  }
}

/// Profile-level `location` block:
/// `{ "address": "...", "coordinates": [lng, lat] }`. Same GeoJSON shape used
/// by the branch's `OtherBranchLocation`, but keys on `address` instead of
/// `name` — kept as a separate type so each field is named for what it holds.
class OtherProfileLocation {
  String? address;
  List<double>? coordinates;

  OtherProfileLocation({this.address, this.coordinates});

  OtherProfileLocation.fromJson(Map<String, dynamic> json) {
    address = json['address']?.toString();
    final c = json['coordinates'];
    if (c is List) {
      coordinates = c
          .map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0.0)
          .toList();
    }
  }
}

/// The API sends `business_location` as a JSON string:
/// `{"lat":"21.17","lon":"72.87"}`. This helper handles string-and-map variants.
class OtherLatLng {
  final double? lat;
  final double? lng;

  OtherLatLng({this.lat, this.lng});

  bool get isValid => lat != null && lng != null && lat != 0.0 && lng != 0.0;

  static OtherLatLng? fromRaw(dynamic raw) {
    if (raw == null) return null;
    try {
      Map<String, dynamic> m;
      if (raw is String) {
        if (raw.trim().isEmpty) return null;
        m = Map<String, dynamic>.from(jsonDecode(raw));
      } else if (raw is Map) {
        m = Map<String, dynamic>.from(raw);
      } else {
        return null;
      }
      final lat = double.tryParse((m['lat'] ?? '').toString());
      final lng = double.tryParse((m['lon'] ?? m['lng'] ?? '').toString());
      if (lat == null || lng == null) return null;
      return OtherLatLng(lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }
}

class OtherDateOfIncorporation {
  int? date;
  int? month;
  int? year;

  OtherDateOfIncorporation({this.date, this.month, this.year});

  OtherDateOfIncorporation.fromJson(Map<String, dynamic> json) {
    date = (json['date'] as num?)?.toInt();
    month = (json['month'] as num?)?.toInt();
    year = (json['year'] as num?)?.toInt();
  }
}

class OtherServiceItem {
  String? id;
  String? title;
  String? description;
  String? category;
  String? subCategory;
  String? priceType;
  num? singlePrice;
  OtherPriceRange? priceRange;
  String? perUnit;
  List<String> photos;
  bool? isActive;
  bool? isDeleted;

  OtherServiceItem({
    this.id,
    this.title,
    this.description,
    this.category,
    this.subCategory,
    this.priceType,
    this.singlePrice,
    this.priceRange,
    this.perUnit,
    this.photos = const [],
    this.isActive,
    this.isDeleted,
  });

  OtherServiceItem.fromJson(Map<String, dynamic> json) : photos = const [] {
    id = (json['id'] ?? json['_id'])?.toString();
    title = json['title']?.toString();
    description = json['description']?.toString();
    category = json['category']?.toString();
    subCategory = json['subCategory']?.toString();
    priceType = json['priceType']?.toString();
    final sp = json['singlePrice'];
    singlePrice = sp is num ? sp : null;
    final pr = json['priceRange'];
    if (pr is Map) {
      priceRange = OtherPriceRange.fromJson(Map<String, dynamic>.from(pr));
    }
    perUnit = json['perUnit']?.toString();
    final ph = json['photos'];
    if (ph is List) {
      photos = ph
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    isActive = json['isActive'] as bool?;
    isDeleted = json['isDeleted'] as bool?;
  }
}

class OtherPriceRange {
  num? min;
  num? max;

  OtherPriceRange({this.min, this.max});

  OtherPriceRange.fromJson(Map<String, dynamic> json) {
    final mn = json['min'];
    final mx = json['max'];
    min = mn is num ? mn : null;
    max = mx is num ? mx : null;
  }

  bool get hasAnyValue => min != null || max != null;
}

class OtherTimings {
  OtherDayTiming? monday;
  OtherDayTiming? tuesday;
  OtherDayTiming? wednesday;
  OtherDayTiming? thursday;
  OtherDayTiming? friday;
  OtherDayTiming? saturday;
  OtherDayTiming? sunday;

  OtherTimings({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  OtherTimings.fromJson(Map<String, dynamic> json) {
    OtherDayTiming? read(String key) {
      final v = json[key];
      if (v is Map) {
        return OtherDayTiming.fromJson(Map<String, dynamic>.from(v));
      }
      return null;
    }

    monday = read('monday');
    tuesday = read('tuesday');
    wednesday = read('wednesday');
    thursday = read('thursday');
    friday = read('friday');
    saturday = read('saturday');
    sunday = read('sunday');
  }

  /// Looks up the day matching [DateTime.weekday] (1 = Monday … 7 = Sunday).
  OtherDayTiming? forWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
    }
    return null;
  }
}

class OtherDayTiming {
  bool? isOpen;
  String? openTime;
  String? closeTime;

  OtherDayTiming({this.isOpen, this.openTime, this.closeTime});

  OtherDayTiming.fromJson(Map<String, dynamic> json) {
    isOpen = json['isOpen'] as bool?;
    openTime = json['openTime']?.toString();
    closeTime = json['closeTime']?.toString();
  }

  bool get hasHours =>
      isOpen == true &&
      (openTime?.isNotEmpty ?? false) &&
      (closeTime?.isNotEmpty ?? false);
}

class OtherContactUs {
  String? id;
  OtherBranch? branch;

  OtherContactUs({this.id, this.branch});

  OtherContactUs.fromJson(Map<String, dynamic> json) {
    id = json['_id']?.toString();
    final b = json['branch'];
    if (b is Map) {
      branch = OtherBranch.fromJson(Map<String, dynamic>.from(b));
    }
  }
}

class OtherBranch {
  String? name;
  String? website;
  OtherBranchLocation? location;

  OtherBranch({this.name, this.website, this.location});

  OtherBranch.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    website = json['website']?.toString();
    final l = json['location'];
    if (l is Map) {
      location = OtherBranchLocation.fromJson(Map<String, dynamic>.from(l));
    }
  }
}

class OtherBranchLocation {
  String? name;
  List<double>? coordinates;

  OtherBranchLocation({this.name, this.coordinates});

  OtherBranchLocation.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    final c = json['coordinates'];
    if (c is List) {
      coordinates = c
          .map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0.0)
          .toList();
    }
  }
}

class OtherManagementItem {
  String? id;
  String? name;
  String? position;
  String? imageUrl;

  OtherManagementItem({this.id, this.name, this.position, this.imageUrl});

  OtherManagementItem.fromJson(Map<String, dynamic> json) {
    id = json['_id']?.toString();
    name = json['name']?.toString();
    position = json['position']?.toString();
    imageUrl = json['imageUrl']?.toString();
  }
}

class OtherGalleryItem {
  String? id;
  String? title;
  List<String> imageUrls;

  OtherGalleryItem({this.id, this.title, this.imageUrls = const []});

  OtherGalleryItem.fromJson(Map<String, dynamic> json) : imageUrls = const [] {
    id = json['_id']?.toString();
    title = json['title']?.toString();
    final u = json['imageUrls'];
    if (u is List) {
      imageUrls =
          u.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
  }
}
