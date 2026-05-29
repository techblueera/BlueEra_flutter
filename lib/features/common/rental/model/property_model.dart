class PriceRange {
  // Wire format expects strings — kept here as String so the model
  // round-trips without ad-hoc coercion at every call site.
  // `fromJson` tolerates legacy numeric payloads via `.toString()`.
  final String min;
  final String max;

  const PriceRange({this.min = '', this.max = ''});

  factory PriceRange.fromJson(Map<String, dynamic> json) => PriceRange(
        min: json['min']?.toString() ?? '',
        max: json['max']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

class GeoLocation {
  final String type;
  final List<double> coordinates;

  const GeoLocation({this.type = 'Point', this.coordinates = const []});

  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
        type: json['type'] ?? 'Point',
        coordinates: (json['coordinates'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;
}

class PlotAreaDetails {
  final String? totalArea;
  final String? length;
  final String? breadth;

  const PlotAreaDetails({this.totalArea, this.length, this.breadth});

  factory PlotAreaDetails.fromJson(Map<String, dynamic> json) =>
      PlotAreaDetails(
        totalArea: json['totalArea'],
        length: json['length'],
        breadth: json['breadth'],
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (totalArea != null) data['totalArea'] = totalArea;
    if (length != null) data['length'] = length;
    if (breadth != null) data['breadth'] = breadth;
    return data;
  }
}

class ProjectLaunchInfo {
  final String? builderName;
  final String? reraRegistrationNumber;
  final String? projectLaunchMonth;
  final String? launchYear;
  final String? expectedPossessionMonth;
  final String? expectedPossessionYear;

  const ProjectLaunchInfo({
    this.builderName,
    this.reraRegistrationNumber,
    this.projectLaunchMonth,
    this.launchYear,
    this.expectedPossessionMonth,
    this.expectedPossessionYear,
  });

  factory ProjectLaunchInfo.fromJson(Map<String, dynamic> json) =>
      ProjectLaunchInfo(
        builderName: json['builderName'],
        reraRegistrationNumber: json['reraRegistrationNumber'],
        projectLaunchMonth: json['projectLaunchMonth'],
        launchYear: json['launchYear'],
        expectedPossessionMonth: json['expectedPossessionMonth'],
        expectedPossessionYear: json['expectedPossessionYear'],
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (builderName != null) data['builderName'] = builderName;
    if (reraRegistrationNumber != null) {
      data['reraRegistrationNumber'] = reraRegistrationNumber;
    }
    if (projectLaunchMonth != null) {
      data['projectLaunchMonth'] = projectLaunchMonth;
    }
    if (launchYear != null) data['launchYear'] = launchYear;
    if (expectedPossessionMonth != null) {
      data['expectedPossessionMonth'] = expectedPossessionMonth;
    }
    if (expectedPossessionYear != null) {
      data['expectedPossessionYear'] = expectedPossessionYear;
    }
    return data;
  }
}

class HouseAndApartment {
  final String? propertyLocation;
  final String? houseApartmentType;
  final String? bhk;
  final String? bathrooms;
  final String? availabilityStatus;
  final String? furnishing;
  final String? listedBy;
  final String? bachelorsAllowed;
  final String? areaDetails;
  final String? maintenance;
  final String? totalFloors;
  final String? floorNo;
  final String? carParking;
  final String? facing;

  const HouseAndApartment({
    this.propertyLocation,
    this.houseApartmentType,
    this.bhk,
    this.bathrooms,
    this.availabilityStatus,
    this.furnishing,
    this.listedBy,
    this.bachelorsAllowed,
    this.areaDetails,
    this.maintenance,
    this.totalFloors,
    this.floorNo,
    this.carParking,
    this.facing,
  });

  factory HouseAndApartment.fromJson(Map<String, dynamic> json) =>
      HouseAndApartment(
        propertyLocation: json['propertyLocation'],
        houseApartmentType: json['houseApartmentType'],
        bhk: json['bhk']?.toString(),
        bathrooms: json['bathrooms']?.toString(),
        availabilityStatus: json['availabilityStatus'],
        furnishing: json['furnishing'],
        listedBy: json['listedBy'],
        bachelorsAllowed:
            json['bachelorsAllowed'] ?? json['bachelorAllowed'],
        areaDetails: json['areaDetails'],
        maintenance: json['maintenance'],
        totalFloors: json['totalFloors']?.toString(),
        floorNo: json['floorNo']?.toString(),
        carParking: json['carParking']?.toString(),
        facing: json['facing'],
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (propertyLocation != null) data['propertyLocation'] = propertyLocation;
    if (houseApartmentType != null) {
      data['houseApartmentType'] = houseApartmentType;
    }
    if (bhk != null) data['bhk'] = bhk;
    if (bathrooms != null) data['bathrooms'] = bathrooms;
    if (availabilityStatus != null) {
      data['availabilityStatus'] = availabilityStatus;
    }
    if (furnishing != null) data['furnishing'] = furnishing;
    if (listedBy != null) data['listedBy'] = listedBy;
    if (bachelorsAllowed != null) {
      data['bachelorsAllowed'] = bachelorsAllowed;
    }
    if (areaDetails != null) data['areaDetails'] = areaDetails;
    if (maintenance != null) data['maintenance'] = maintenance;
    if (totalFloors != null) data['totalFloors'] = totalFloors;
    if (floorNo != null) data['floorNo'] = floorNo;
    if (carParking != null) data['carParking'] = carParking;
    if (facing != null) data['facing'] = facing;
    return data;
  }
}

class LandAndPlots {
  final String? propertyLocation;
  final String? projectType;
  final String? listedBy;
  final PlotAreaDetails? plotAreaDetails;
  final String? facing;

  const LandAndPlots({
    this.propertyLocation,
    this.projectType,
    this.listedBy,
    this.plotAreaDetails,
    this.facing,
  });

  factory LandAndPlots.fromJson(Map<String, dynamic> json) => LandAndPlots(
        propertyLocation: json['propertyLocation'],
        projectType: json['projectType'],
        listedBy: json['listedBy'],
        plotAreaDetails: json['plotAreaDetails'] is Map
            ? PlotAreaDetails.fromJson(json['plotAreaDetails'])
            : null,
        facing: json['facing'],
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (propertyLocation != null) data['propertyLocation'] = propertyLocation;
    if (projectType != null) data['projectType'] = projectType;
    if (listedBy != null) data['listedBy'] = listedBy;
    if (plotAreaDetails != null) {
      data['plotAreaDetails'] = plotAreaDetails!.toJson();
    }
    if (facing != null) data['facing'] = facing;
    return data;
  }
}

class ShopAndOffices {
  final String? propertyLocation;
  final String? furnishing;
  final String? projectStatus;
  final String? listedBy;
  final String? superBuiltupArea;
  final String? maintenance;
  final String? carParkings;
  final String? washrooms;

  const ShopAndOffices({
    this.propertyLocation,
    this.furnishing,
    this.projectStatus,
    this.listedBy,
    this.superBuiltupArea,
    this.maintenance,
    this.carParkings,
    this.washrooms,
  });

  factory ShopAndOffices.fromJson(Map<String, dynamic> json) => ShopAndOffices(
        propertyLocation: json['propertyLocation'],
        furnishing: json['furnishing'],
        projectStatus: json['projectStatus'],
        listedBy: json['listedBy'],
        superBuiltupArea: json['superBuiltupArea'],
        maintenance: json['maintenance'],
        carParkings: json['carParkings']?.toString(),
        washrooms: json['washrooms']?.toString(),
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (propertyLocation != null) data['propertyLocation'] = propertyLocation;
    if (furnishing != null) data['furnishing'] = furnishing;
    if (projectStatus != null) data['projectStatus'] = projectStatus;
    if (listedBy != null) data['listedBy'] = listedBy;
    if (superBuiltupArea != null) data['superBuiltupArea'] = superBuiltupArea;
    if (maintenance != null) data['maintenance'] = maintenance;
    if (carParkings != null) data['carParkings'] = carParkings;
    if (washrooms != null) data['washrooms'] = washrooms;
    return data;
  }
}

class NewProjectsAndProperties {
  final String? propertyLocation;
  final String? projectType;
  final String? projectStatus;
  final String? typeOfProperty;
  final String? area;
  final ProjectLaunchInfo? projectLaunchInformation;
  final List<String>? keyAmenities;
  final String? noOfTowers;
  final String? noOfFloors;
  final String? facing;
  final String? listedBy;

  const NewProjectsAndProperties({
    this.propertyLocation,
    this.projectType,
    this.projectStatus,
    this.typeOfProperty,
    this.area,
    this.projectLaunchInformation,
    this.keyAmenities,
    this.noOfTowers,
    this.noOfFloors,
    this.facing,
    this.listedBy,
  });

  factory NewProjectsAndProperties.fromJson(Map<String, dynamic> json) {
    List<String>? amenities;
    final raw = json['keyAmenities'];
    if (raw is List) {
      amenities = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      amenities = raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return NewProjectsAndProperties(
      propertyLocation: json['propertyLocation'],
      projectType: json['projectType'],
      projectStatus: json['projectStatus'],
      typeOfProperty: json['typeOfProperty'],
      area: json['area'],
      projectLaunchInformation: json['projectLaunchInformation'] is Map
          ? ProjectLaunchInfo.fromJson(json['projectLaunchInformation'])
          : null,
      keyAmenities: amenities,
      noOfTowers: json['noOfTowers']?.toString(),
      noOfFloors: json['noOfFloors']?.toString(),
      facing: json['facing'],
      listedBy: json['listedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (propertyLocation != null) data['propertyLocation'] = propertyLocation;
    if (projectType != null) data['projectType'] = projectType;
    if (projectStatus != null) data['projectStatus'] = projectStatus;
    if (typeOfProperty != null) data['typeOfProperty'] = typeOfProperty;
    if (area != null) data['area'] = area;
    if (projectLaunchInformation != null) {
      data['projectLaunchInformation'] = projectLaunchInformation!.toJson();
    }
    if (keyAmenities != null) data['keyAmenities'] = keyAmenities!.join(', ');
    if (noOfTowers != null) data['noOfTowers'] = noOfTowers;
    if (noOfFloors != null) data['noOfFloors'] = noOfFloors;
    if (facing != null) data['facing'] = facing;
    if (listedBy != null) data['listedBy'] = listedBy;
    return data;
  }
}

class PGAndGuestHouse {
  final String? propertyLocation;
  final String? subType;
  final String? roomType;
  final String? attachedBathroom;
  final String? furnishing;
  final String? listedBy;
  final String? carParking;
  final String? mealsIncluded;
  final List<String>? keyAmenities;

  const PGAndGuestHouse({
    this.propertyLocation,
    this.subType,
    this.roomType,
    this.attachedBathroom,
    this.furnishing,
    this.listedBy,
    this.carParking,
    this.mealsIncluded,
    this.keyAmenities,
  });

  factory PGAndGuestHouse.fromJson(Map<String, dynamic> json) {
    List<String>? amenities;
    final raw = json['keyAmenities'];
    if (raw is List) {
      amenities = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      amenities = raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return PGAndGuestHouse(
      propertyLocation: json['propertyLocation'],
      subType: json['subType'],
      roomType: json['roomType'],
      attachedBathroom: json['attachedBathroom'],
      furnishing: json['furnishing'],
      listedBy: json['listedBy'],
      carParking: json['carParking']?.toString(),
      mealsIncluded: json['mealsIncluded'],
      keyAmenities: amenities,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (propertyLocation != null) data['propertyLocation'] = propertyLocation;
    if (subType != null) data['subType'] = subType;
    if (roomType != null) data['roomType'] = roomType;
    if (attachedBathroom != null) data['attachedBathroom'] = attachedBathroom;
    if (furnishing != null) data['furnishing'] = furnishing;
    if (listedBy != null) data['listedBy'] = listedBy;
    if (carParking != null) data['carParking'] = carParking;
    if (mealsIncluded != null) data['mealsIncluded'] = mealsIncluded;
    if (keyAmenities != null) data['keyAmenities'] = keyAmenities!.join(', ');
    return data;
  }
}

class PropertyModel {
  final String? id;
  final String? userId;
  final String propertyName;
  final String description;
  final String propertyType;
  final String listingType;
  // Server-side creation timestamp (ISO-8601). Kept so the discover
  // screen can offer "Newest first" sorting; ISO strings sort
  // chronologically, so no DateTime parse is needed for ordering.
  final String? createdAt;
  // Wire format ships price as a string now — same coercion strategy
  // as [PriceRange.min] / [PriceRange.max]. `fromJson` calls
  // `?.toString()` so existing numeric server payloads keep parsing.
  final String price;
  final PriceRange? priceRange;
  final double rating;
  final int reviews;
  final List<String> propertyImages;
  final bool allInclusivePrice;
  final bool priceNegotiable;
  final bool taxAndGovtChargeExcluded;
  // Carries the deposit AMOUNT now (was a yes/no bool). Nullable so
  // the field is omitted from the payload when the user leaves it
  // blank.
  final String? securityDepositAmount;
  final bool electricityIncluded;
  final bool waterChargesIncluded;
  final String? priceType;
  // Free-text lister name that pairs with the `listedBy` role on
  // each type-specific sub-model. Sent on every payload (rent + sell).
  final String? listedByName;
  final GeoLocation? location;
  final HouseAndApartment? houseAndApartment;
  final LandAndPlots? landAndPlots;
  final ShopAndOffices? shopAndOffices;
  final NewProjectsAndProperties? newProjectsAndProperties;
  final PGAndGuestHouse? pgAndGuestHouse;

  const PropertyModel({
    this.id,
    this.userId,
    this.propertyName = '',
    this.description = '',
    this.propertyType = '',
    this.listingType = '',
    this.createdAt,
    this.price = '',
    this.priceRange,
    this.rating = 0,
    this.reviews = 0,
    this.propertyImages = const [],
    this.allInclusivePrice = false,
    this.priceNegotiable = false,
    this.taxAndGovtChargeExcluded = false,
    this.securityDepositAmount,
    this.electricityIncluded = false,
    this.waterChargesIncluded = false,
    this.priceType,
    this.listedByName,
    this.location,
    this.houseAndApartment,
    this.landAndPlots,
    this.shopAndOffices,
    this.newProjectsAndProperties,
    this.pgAndGuestHouse,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
        id: json['_id'] ?? json['id'],
        userId: json['userId'] ?? json['createdBy'],
        propertyName: json['propertyName'] ?? '',
        description: json['description'] ?? '',
        propertyType: json['propertyType'] ?? '',
        listingType: json['listingType'] ?? '',
        createdAt: json['createdAt']?.toString(),
        price: json['price']?.toString() ?? '',
        priceRange: json['priceRange'] is Map
            ? PriceRange.fromJson(json['priceRange'])
            : null,
        rating: (json['rating'] ?? 0).toDouble(),
        reviews: json['reviews'] ?? 0,
        propertyImages: (json['propertyImages'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        allInclusivePrice: json['allInclusivePrice'] ?? false,
        priceNegotiable: json['priceNegotiable'] ?? false,
        taxAndGovtChargeExcluded: json['taxAndGovtChargeExcluded'] ?? false,
        // Server echoes the amount back as a number; coerce via
        // `?.toString()` so the String? field doesn't throw a
        // "int is not a subtype of String" cast at construction.
        securityDepositAmount:
            json['securityDepositAmount']?.toString() ?? '',
        electricityIncluded: json['electricityIncluded'] ?? false,
        waterChargesIncluded: json['waterChargesIncluded'] ?? false,
        priceType: json['priceType'],
        listedByName: json['listedByName']?.toString(),
        location: json['location'] is Map
            ? GeoLocation.fromJson(json['location'])
            : null,
        houseAndApartment: json['houseAndApartment'] is Map
            ? HouseAndApartment.fromJson(json['houseAndApartment'])
            : null,
        landAndPlots: json['landAndPlots'] is Map
            ? LandAndPlots.fromJson(json['landAndPlots'])
            : null,
        shopAndOffices: json['shopAndOffices'] is Map
            ? ShopAndOffices.fromJson(json['shopAndOffices'])
            : null,
        newProjectsAndProperties: json['newProjectsAndProperties'] is Map
            ? NewProjectsAndProperties.fromJson(
                json['newProjectsAndProperties'])
            : null,
        pgAndGuestHouse: json['pgAndGuestHouse'] is Map
            ? PGAndGuestHouse.fromJson(json['pgAndGuestHouse'])
            : null,
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'propertyName': propertyName,
      'description': description,
      'propertyType': propertyType,
      'listingType': listingType,
    };

    if (priceRange != null) {
      data['priceRange'] = priceRange!.toJson();
    } else {
      data['price'] = price;
    }

    data['allInclusivePrice'] = allInclusivePrice;
    data['priceNegotiable'] = priceNegotiable;
    data['taxAndGovtChargeExcluded'] = taxAndGovtChargeExcluded;

    // priceType (duration) + securityDeposit (amount) flow on every
    // listing — rent and sell — per the new payload spec. Utility-
    // included flags stay rent-only because they're meaningless on a
    // sale listing.
    if (priceType != null) data['priceType'] = priceType;
    if (listedByName != null && listedByName!.isNotEmpty) {
      data['listedByName'] = listedByName;
    }
    if (securityDepositAmount != null) data['securityDepositAmount'] = securityDepositAmount;

    if (location != null) data['location'] = location!.toJson();

    if (listingType == 'Rent') {
      data['electricityIncluded'] = electricityIncluded;
      data['waterChargesIncluded'] = waterChargesIncluded;
    }

    if (houseAndApartment != null) {
      data['houseAndApartment'] = houseAndApartment!.toJson();
    }
    if (landAndPlots != null) {
      data['landAndPlots'] = landAndPlots!.toJson();
    }
    if (shopAndOffices != null) {
      data['shopAndOffices'] = shopAndOffices!.toJson();
    }
    if (newProjectsAndProperties != null) {
      data['newProjectsAndProperties'] = newProjectsAndProperties!.toJson();
    }
    if (pgAndGuestHouse != null) {
      data['pgAndGuestHouse'] = pgAndGuestHouse!.toJson();
    }

    return data;
  }

  String get displayLocation {
    return houseAndApartment?.propertyLocation ??
        landAndPlots?.propertyLocation ??
        shopAndOffices?.propertyLocation ??
        newProjectsAndProperties?.propertyLocation ??
        pgAndGuestHouse?.propertyLocation ??
        '';
  }

  bool get hasPriceRange =>
      priceRange != null && (num.tryParse(priceRange!.min) ?? 0) > 0;

  static const _typeLabels = {
    'HouseAndApartment': 'House & Apartment',
    'LandAndPlots': 'Land & Plots',
    'ShopAndOffices': 'Shop & Offices',
    'NewProjectsAndProperties': 'New Projects',
    'PGAndGuestHouse': 'PG & Guest House',
  };

  String get typeLabel => _typeLabels[propertyType] ?? propertyType;

  static String formatIndianPrice(num price) {
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formatted = rest.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '$formatted,$last3';
  }

  String get formattedPrice {
    String result;
    if (hasPriceRange) {
      final lo = num.tryParse(priceRange!.min) ?? 0;
      final hi = num.tryParse(priceRange!.max) ?? 0;
      result = '₹${formatIndianPrice(lo)} - ₹${formatIndianPrice(hi)}';
    } else {
      result = '₹${formatIndianPrice(num.tryParse(price) ?? 0)}';
    }
    if (listingType == 'Rent') result += '/mo';
    return result;
  }
}
