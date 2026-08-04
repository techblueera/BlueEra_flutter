import 'dart:convert';

class FinanceSearchResModel {
  bool? success;
  List<FinanceBusinessItem>? data;

  FinanceSearchResModel({this.success, this.data});

  FinanceSearchResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <FinanceBusinessItem>[];
      json['data'].forEach((v) {
        data!.add(FinanceBusinessItem.fromJson(v));
      });
    }
  }
}

class FinanceBusinessItem {
  String? id;
  String? userId;
  String? businessProfileId;
  // be_user_service `businesses._id` — the only id the rating endpoints
  // accept (see lib/docs/rating-ui-integration.md §1). Empty when the
  // owner has no business record or the gRPC enrichment failed; UIs must
  // hide the rating submit CTA in that case.
  String? businessId;
  String? profileName;
  String? description;
  String? logoUrl;
  String? coverUrl;
  String? type;
  String? category;
  FinanceLocation? location;
  List<FinanceContactUs>? contactUs;
  List<FinanceAboutOrganisation>? aboutOrganisation;
  List<FinanceManagement>? management;
  List<FinanceStaff>? staff;
  List<FinanceBlog>? blogs;
  List<FinanceGallery>? gallery;
  String? createdAt;
  String? updatedAt;
  double? rating;
  /// `profile.avg_rating` from `/full` — server-computed display average.
  /// Falls back to [rating] when the endpoint doesn't provide it (older
  /// search-list rows).
  double? avgRating;
  /// `profile.total_ratings` from `/full` — used to render "(N reviews)".
  int? totalRatings;
  /// `profile.business_description` from `/full` — the paragraph the
  /// [VisitBusinessHero] renders below the identity block. Populated from
  /// the `/full` payload; the search-list rows leave it null.
  String? businessDescription;
  /// Human-readable category label from `/full` (`category_details.name`).
  /// The chip prefers this over the raw [category] slug (e.g.
  /// "Banking Sector" vs. "BANKING_SECTOR").
  String? categoryDetailsName;
  /// Human-readable sub-category label from `/full`
  /// (`sub_category_details.name`), e.g. "Digital Bank".
  String? subCategoryDetailsName;
  bool? rbiRegistered;
  List<String>? accountType;
  FinanceBusinessHours? businessHours;
  FinanceDetails? financeDetails;
  FinanceTimings? timings;
  String? websiteUrl;

  FinanceBusinessItem({
    this.id,
    this.userId,
    this.businessProfileId,
    this.profileName,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.type,
    this.category,
    this.location,
    this.contactUs,
    this.aboutOrganisation,
    this.management,
    this.staff,
    this.blogs,
    this.gallery,
    this.createdAt,
    this.updatedAt,
  });

  FinanceBusinessItem.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    id = json['_id'] ?? profile?['_id'];
    userId = json['userId'] ?? profile?['userId'];
    businessProfileId = json['businessProfileId'] ?? profile?['businessProfileId'];
    businessId = json['businessId'] ?? profile?['businessId'];
    profileName = json['profileName'] ?? profile?['profileName'];
    description = json['description'] ?? profile?['description'];
    logoUrl = (json['logoUrl'] ?? profile?['logoUrl'])?.toString().trim();
    coverUrl = (json['coverUrl'] ?? profile?['coverUrl'])?.toString().trim();
    type = json['type'] ?? profile?['type'];
    // The full-profile API exposes the category as `category_Of_Business`
    // (with a `sub_category_Of_Business` fallback); the search API uses
    // `category`. Support all so the chip renders in both flows.
    category = json['category'] ??
        profile?['category'] ??
        json['category_Of_Business'] ??
        profile?['category_Of_Business'] ??
        json['sub_type'] ??
        profile?['sub_type'];
    // Prefer an explicit GeoJSON `location` (carries `address` +
    // `coordinates`); check both the top level AND `profile.location` —
    // the /search response nests it under profile. Fall back to the
    // profile's `business_location` ("{\"lat\":..,\"lon\":..}") which
    // only carries coordinates when neither is present.
    final locationRaw = json['location'] ?? profile?['location'];
    location = locationRaw is Map
        ? FinanceLocation.fromJson(Map<String, dynamic>.from(locationRaw))
        : FinanceLocation.fromBusinessLocation(
            profile?['business_location'] ?? json['business_location']);
    if (json['contactUs'] != null) {
      contactUs = <FinanceContactUs>[];
      json['contactUs'].forEach((v) {
        contactUs!.add(FinanceContactUs.fromJson(v));
      });
    }
    if (json['aboutOrganisation'] != null) {
      aboutOrganisation = <FinanceAboutOrganisation>[];
      json['aboutOrganisation'].forEach((v) {
        aboutOrganisation!.add(FinanceAboutOrganisation.fromJson(v));
      });
    }
    if (json['management'] != null) {
      management = <FinanceManagement>[];
      json['management'].forEach((v) {
        management!.add(FinanceManagement.fromJson(v));
      });
    }
    if (json['staff'] != null) {
      staff = <FinanceStaff>[];
      json['staff'].forEach((v) {
        staff!.add(FinanceStaff.fromJson(v));
      });
    }
    if (json['blogs'] != null) {
      blogs = <FinanceBlog>[];
      json['blogs'].forEach((v) {
        blogs!.add(FinanceBlog.fromJson(v));
      });
    }
    if (json['gallery'] != null) {
      gallery = <FinanceGallery>[];
      json['gallery'].forEach((v) {
        gallery!.add(FinanceGallery.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];

    final ratingVal = json['rating'] ?? profile?['rating'];
    rating = ratingVal is num ? ratingVal.toDouble() : null;

    final avgRatingVal = json['avg_rating'] ?? profile?['avg_rating'];
    avgRating = avgRatingVal is num ? avgRatingVal.toDouble() : null;

    final totalRatingsVal = json['total_ratings'] ?? profile?['total_ratings'];
    totalRatings = totalRatingsVal is num ? totalRatingsVal.toInt() : null;

    // `/full` uses `profile.business_description`; the search endpoint has
    // `description` at the row level. Accept either so both flows populate.
    businessDescription = (json['business_description'] ??
            profile?['business_description'] ??
            json['description'] ??
            profile?['description'])
        ?.toString();

    final catDetails = json['category_details'] ?? profile?['category_details'];
    if (catDetails is Map) {
      categoryDetailsName = catDetails['name']?.toString();
    }
    final subCatDetails =
        json['sub_category_details'] ?? profile?['sub_category_details'];
    if (subCatDetails is Map) {
      subCategoryDetailsName = subCatDetails['name']?.toString();
    }

    rbiRegistered = (json['rbiRegistered'] ?? profile?['rbiRegistered']) as bool?;

    final accountTypeRaw = json['accountType'] ?? profile?['accountType'];
    if (accountTypeRaw is List) {
      accountType = accountTypeRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    final businessHoursRaw = json['businessHours'] ?? profile?['businessHours'];
    if (businessHoursRaw is Map) {
      businessHours = FinanceBusinessHours.fromJson(Map<String, dynamic>.from(businessHoursRaw));
    }

    final financeDetailsRaw = json['financeDetails'] ?? profile?['financeDetails'];
    if (financeDetailsRaw is Map) {
      financeDetails = FinanceDetails.fromJson(Map<String, dynamic>.from(financeDetailsRaw));
    }

    final timingsRaw = json['timings'] ?? profile?['timings'];
    if (timingsRaw is Map) {
      timings = FinanceTimings.fromJson(Map<String, dynamic>.from(timingsRaw));
    }

    // Profile-level website (used as a fallback when no contactUs branch
    // provides one). Lives under `profile.website_url` in the detail
    // response; also accept a top-level key for forward compat.
    final websiteRaw = json['website_url'] ?? profile?['website_url'];
    final websiteStr = websiteRaw?.toString().trim() ?? '';
    websiteUrl = websiteStr.isEmpty ? null : websiteStr;
  }

  /// Branch website if any contactUs entry has one, otherwise the
  /// profile-level [websiteUrl]. Returns `null` when neither is set.
  String? get effectiveWebsite {
    final branch = contactUs?.firstOrNull?.branch?.website?.trim() ?? '';
    if (branch.isNotEmpty) return branch;
    final fallback = websiteUrl?.trim() ?? '';
    return fallback.isEmpty ? null : fallback;
  }
}

class FinanceTimings {
  FinanceDayTiming? monday;
  FinanceDayTiming? tuesday;
  FinanceDayTiming? wednesday;
  FinanceDayTiming? thursday;
  FinanceDayTiming? friday;
  FinanceDayTiming? saturday;
  FinanceDayTiming? sunday;

  FinanceTimings({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  FinanceTimings.fromJson(Map<String, dynamic> json) {
    FinanceDayTiming? read(String key) {
      final v = json[key];
      if (v is Map) {
        return FinanceDayTiming.fromJson(Map<String, dynamic>.from(v));
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

  /// Returns the day's timing for a [DateTime.weekday] (1 = Monday … 7 = Sunday).
  FinanceDayTiming? forWeekday(int weekday) {
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

class FinanceDayTiming {
  bool? isOpen;
  String? openTime;
  String? closeTime;

  FinanceDayTiming({this.isOpen, this.openTime, this.closeTime});

  FinanceDayTiming.fromJson(Map<String, dynamic> json) {
    isOpen = json['isOpen'] as bool?;
    openTime = json['openTime']?.toString();
    closeTime = json['closeTime']?.toString();
  }

  bool get hasHours => isOpen == true && (openTime?.isNotEmpty ?? false) && (closeTime?.isNotEmpty ?? false);
}

class FinanceBusinessHours {
  String? openTime;
  String? closeTime;

  FinanceBusinessHours({this.openTime, this.closeTime});

  FinanceBusinessHours.fromJson(Map<String, dynamic> json) {
    openTime = json['openTime']?.toString();
    closeTime = json['closeTime']?.toString();
  }

  bool get hasHours => (openTime?.isNotEmpty ?? false) && (closeTime?.isNotEmpty ?? false);
}

class FinanceDetails {
  int? minBalance;
  String? openOnlineTime;
  double? savingRatePA;
  double? fdRatePA;
  String? fdMaxTenure;

  FinanceDetails({
    this.minBalance,
    this.openOnlineTime,
    this.savingRatePA,
    this.fdRatePA,
    this.fdMaxTenure,
  });

  FinanceDetails.fromJson(Map<String, dynamic> json) {
    final mb = json['minBalance'];
    minBalance = mb is num ? mb.toInt() : null;
    openOnlineTime = json['openOnlineTime']?.toString();
    final sr = json['savingRatePA'];
    savingRatePA = sr is num ? sr.toDouble() : null;
    final fr = json['fdRatePA'];
    fdRatePA = fr is num ? fr.toDouble() : null;
    fdMaxTenure = json['fdMaxTenure']?.toString();
  }
}

class FinanceLocation {
  String? name;
  String? address;
  List<double>? coordinates;

  FinanceLocation({this.name, this.address, this.coordinates});

  FinanceLocation.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    if (json['coordinates'] != null) {
      coordinates = List<double>.from(json['coordinates'].map((x) => (x as num).toDouble()));
    }
  }

  /// Builds a location from the profile's `business_location`, which the API
  /// sends as a JSON string like `{"lat":"21.17","lon":"72.87"}`. Returns null
  /// when the value is missing or unparseable. The screen reads
  /// `coordinates[0]` as latitude and `coordinates[1]` as longitude, so we
  /// order them [lat, lon] here.
  static FinanceLocation? fromBusinessLocation(dynamic raw) {
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
      final lon = double.tryParse((m['lon'] ?? m['lng'] ?? '').toString());
      if (lat == null || lon == null) return null;
      return FinanceLocation(coordinates: [lat, lon]);
    } catch (_) {
      return null;
    }
  }
}

class FinanceManagement {
  String? id;
  String? name;
  String? position;
  String? qualification;
  String? message;
  String? imageUrl;

  FinanceManagement({
    this.id,
    this.name,
    this.position,
    this.qualification,
    this.message,
    this.imageUrl,
  });

  FinanceManagement.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    message = json['message'];
    imageUrl = json['imageUrl']?.toString().trim();
  }
}

class FinanceContactUs {
  String? id;
  FinanceBranch? branch;
  List<FinanceDepartment>? departments;

  FinanceContactUs({this.id, this.branch, this.departments});

  FinanceContactUs.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    branch = json['branch'] != null ? FinanceBranch.fromJson(json['branch']) : null;
    if (json['departments'] != null) {
      departments = <FinanceDepartment>[];
      json['departments'].forEach((v) {
        departments!.add(FinanceDepartment.fromJson(v));
      });
    }
  }
}

class FinanceBranch {
  FinanceLocation? location;
  String? name;
  String? website;

  FinanceBranch({this.location, this.name, this.website});

  FinanceBranch.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null ? FinanceLocation.fromJson(json['location']) : null;
    name = json['name'];
    website = json['website'];
  }
}

class FinanceDepartment {
  String? id;
  String? department;
  String? role;
  String? email;
  String? phone;

  FinanceDepartment({this.id, this.department, this.role, this.email, this.phone});

  FinanceDepartment.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    department = json['department'];
    role = json['role'];
    email = json['email'];
    phone = json['phone'];
  }
}

class FinanceAboutOrganisation {
  String? id;
  String? imageUrl;
  String? title;
  String? description;

  FinanceAboutOrganisation({this.id, this.imageUrl, this.title, this.description});

  FinanceAboutOrganisation.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    imageUrl = json['imageUrl']?.toString().trim();
    title = json['title'];
    description = json['description'];
  }
}

class FinanceStaff {
  String? id;
  String? name;
  String? position;
  String? qualification;
  String? imageUrl;

  FinanceStaff({this.id, this.name, this.position, this.qualification, this.imageUrl});

  FinanceStaff.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    position = json['position'];
    qualification = json['qualification'];
    imageUrl = json['imageUrl']?.toString().trim();
  }
}

class FinanceBlog {
  String? id;
  String? imageUrl;
  String? title;
  String? blog;

  FinanceBlog({this.id, this.imageUrl, this.title, this.blog});

  FinanceBlog.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    imageUrl = json['imageUrl']?.toString().trim();
    title = json['title'];
    blog = json['blog'];
  }
}

class FinanceGallery {
  String? id;
  String? title;
  List<String>? imageUrls;

  FinanceGallery({this.id, this.title, this.imageUrls});

  FinanceGallery.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    title = json['title'];
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls'].map((x) => x.toString().trim()));
    }
  }
}
