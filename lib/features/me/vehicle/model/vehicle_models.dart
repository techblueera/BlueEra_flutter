/// Domain models for the BlueEra vehicle service
/// (`vehicle-service/...` endpoints).
///
/// Mirrors `lib/docs/FLUTTER_INTEGRATION_GUIDE.md` § 2 — every model
/// exposes `fromJson`, `toJson` / `toCreateJson` and only emits
/// non-null fields when serialising for create/update calls so the
/// server can apply partial updates without nulling existing values.
library;

// ─────────────────────────────────────────────────────────────────────
// Common building blocks
// ─────────────────────────────────────────────────────────────────────

class VehicleLocation {
  final double? lat;
  final double? lon;
  final String? address;
  final String? city;
  final String? state;
  final int? pincode;

  VehicleLocation({
    this.lat,
    this.lon,
    this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> j) => VehicleLocation(
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        address: j['address'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        pincode: (j['pincode'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
      };
}

class VehiclePhoneNumber {
  final int? pre; // country code, default 91
  final String? number;

  VehiclePhoneNumber({this.pre, this.number});

  factory VehiclePhoneNumber.fromJson(Map<String, dynamic> j) =>
      VehiclePhoneNumber(
        pre: (j['pre'] as num?)?.toInt(),
        number: j['number'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (pre != null) 'pre': pre,
        if (number != null) 'number': number,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Vehicle
// ─────────────────────────────────────────────────────────────────────

enum VehicleFuelType { petrol, diesel, electric, cng, hybrid, other }

enum VehicleTransmission { manual, automatic, amt, cvt }

extension VehicleFuelTypeWire on VehicleFuelType {
  String get wire => name.toUpperCase();
  static VehicleFuelType? parse(String? s) {
    if (s == null) return null;
    return VehicleFuelType.values.firstWhere(
      (e) => e.wire == s.toUpperCase(),
      orElse: () => VehicleFuelType.other,
    );
  }
}

extension VehicleTransmissionWire on VehicleTransmission {
  String get wire => name.toUpperCase();
  static VehicleTransmission? parse(String? s) {
    if (s == null) return null;
    try {
      return VehicleTransmission.values
          .firstWhere((e) => e.wire == s.toUpperCase());
    } catch (_) {
      return null;
    }
  }
}

/// One entry of the server-controlled vehicle type taxonomy returned by
/// `GET /vehicles/types`. The picker must be populated from this list
/// (never hardcoded) — the chosen [value] (e.g. `"CAR"`) is sent back as
/// `category` on create/update; [label] is the human-facing display.
class VehicleType {
  final String value; // wire value, e.g. "CAR" — sent as `category`
  final String label; // display label, e.g. "Car"
  final String? icon; // optional icon key, e.g. "car"
  // Nested sub-types returned under `children` (e.g. PASSENGER →
  // [PASSENGER_2W, PASSENGER_4W]). Parsed recursively so the taxonomy
  // can be arbitrarily deep; the form currently surfaces the top level
  // as the parent category and its immediate `children` as the
  // sub-category options.
  final List<VehicleType> children;

  VehicleType({
    required this.value,
    required this.label,
    this.icon,
    this.children = const [],
  });

  factory VehicleType.fromJson(Map<String, dynamic> j) => VehicleType(
        value: (j['value'] ?? '') as String,
        label: (j['label'] ?? (j['value'] ?? '')) as String,
        icon: j['icon'] as String?,
        children: ((j['children'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => VehicleType.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

  bool get hasChildren => children.isNotEmpty;
}

/// The two upload flows. `condition` on the wire is the string `NEW` /
/// `USED`; these constants keep the branching readable and avoid stray
/// string literals across the UI.
class VehicleCondition {
  VehicleCondition._();
  static const String isNew = 'NEW';
  static const String used = 'USED';
}

/// A single server-controlled picker option (`{ value, label, icon }`)
/// returned by `GET /vehicles/conditions` and `GET /vehicles/options`.
/// The chosen [value] is what gets sent on create; [label] is shown.
class VehicleOption {
  final String value;
  final String label;
  final String? icon;

  VehicleOption({required this.value, required this.label, this.icon});

  factory VehicleOption.fromJson(Map<String, dynamic> j) => VehicleOption(
        value: (j['value'] ?? '') as String,
        label: (j['label'] ?? (j['value'] ?? '')) as String,
        icon: j['icon'] as String?,
      );

  static List<VehicleOption> listFrom(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((m) => VehicleOption.fromJson(Map<String, dynamic>.from(m)))
          .toList();
}

/// Parsed payload of `GET /vehicles/options` — every non-taxonomy
/// picker the upload form needs, in one object. Empty lists are a safe
/// default so the form still renders if the call hasn't resolved.
class VehicleOptionSets {
  final List<VehicleOption> availability; // NEW
  final List<VehicleOption> deliveryTime; // NEW
  final List<VehicleOption> specialOffers; // NEW (multi-select)
  final List<VehicleOption> ownership; // USED
  final List<VehicleOption> conditionGrade; // USED

  VehicleOptionSets({
    this.availability = const [],
    this.deliveryTime = const [],
    this.specialOffers = const [],
    this.ownership = const [],
    this.conditionGrade = const [],
  });

  factory VehicleOptionSets.fromJson(Map<String, dynamic> j) {
    final o = (j['options'] is Map)
        ? Map<String, dynamic>.from(j['options'] as Map)
        : j;
    return VehicleOptionSets(
      availability: VehicleOption.listFrom(o['availability']),
      deliveryTime: VehicleOption.listFrom(o['delivery_time']),
      specialOffers: VehicleOption.listFrom(o['special_offers']),
      ownership: VehicleOption.listFrom(o['ownership']),
      conditionGrade: VehicleOption.listFrom(o['condition_grade']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Catalog (Brand → Model → Variant) — "vehicles as products"
//
// A listing references a catalog `VehicleVariant` (`variant_id`); the
// server takes identity/taxonomy/specs from the catalog. The picker
// drills Brand → Model → Variant, then `GET /catalog/variants/{id}`
// returns a `prefill` payload the form drops in. List-item shapes aren't
// strictly documented, so these models read the documented keys and keep
// the raw map for anything extra.
// ─────────────────────────────────────────────────────────────────────

class VehicleBrand {
  final String id;
  final String name;
  final String? slug;
  final String? logo;
  final String? icon;
  final Map<String, dynamic> raw;

  VehicleBrand({
    required this.id,
    required this.name,
    this.slug,
    this.logo,
    this.icon,
    this.raw = const {},
  });

  factory VehicleBrand.fromJson(Map<String, dynamic> j) => VehicleBrand(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? j['brand'] ?? '') as String,
        slug: j['slug'] as String?,
        logo: (j['logo'] ?? j['image']) as String?,
        icon: j['icon'] as String?,
        raw: j,
      );

  static List<VehicleBrand> listFrom(dynamic raw) => ((raw as List?) ?? const [])
      .whereType<Map>()
      .map((m) => VehicleBrand.fromJson(Map<String, dynamic>.from(m)))
      .toList();
}

class VehicleModelCatalog {
  final String id;
  final String name;
  final String? brandId;
  final String? brandName;
  final String? image;
  final Map<String, dynamic> raw;

  VehicleModelCatalog({
    required this.id,
    required this.name,
    this.brandId,
    this.brandName,
    this.image,
    this.raw = const {},
  });

  factory VehicleModelCatalog.fromJson(Map<String, dynamic> j) =>
      VehicleModelCatalog(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? j['model'] ?? '') as String,
        brandId: (j['brand_id'] ?? j['brandId']) as String?,
        brandName: (j['brand_name'] ?? j['brand']) as String?,
        image: (j['image'] ?? j['cover_image']) as String?,
        raw: j,
      );

  static List<VehicleModelCatalog> listFrom(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((m) => VehicleModelCatalog.fromJson(Map<String, dynamic>.from(m)))
          .toList();
}

class VehicleVariant {
  final String id;
  final String name;
  final String? modelId;
  final double? exShowroomPrice;
  final String? fuelType;
  final String? transmission;
  final Map<String, dynamic> raw;

  VehicleVariant({
    required this.id,
    required this.name,
    this.modelId,
    this.exShowroomPrice,
    this.fuelType,
    this.transmission,
    this.raw = const {},
  });

  factory VehicleVariant.fromJson(Map<String, dynamic> j) => VehicleVariant(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? j['variant'] ?? '') as String,
        modelId: (j['model_id'] ?? j['modelId']) as String?,
        exShowroomPrice: (j['ex_showroom_price'] as num?)?.toDouble(),
        fuelType: j['fuel_type'] as String?,
        transmission: j['transmission'] as String?,
        raw: j,
      );

  static List<VehicleVariant> listFrom(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((m) => VehicleVariant.fromJson(Map<String, dynamic>.from(m)))
          .toList();
}

/// Parsed `prefill` payload of `GET /vehicles/catalog/variants/{id}`. Its
/// keys mirror the create-listing body — the client drops these into the
/// add-vehicle form, the user edits, then POSTs back. `variantId` is the
/// only field create strictly needs; the rest pre-fill the (catalog-owned,
/// server-authoritative) display fields.
class VehiclePrefill {
  final String? variantId;
  final String? brandId;
  final String? modelId;
  final String? categoryId;
  final String? name;
  final String? brand;
  final String? model;
  final String? variant;
  final String? category;
  final String? subCategory;
  final String? type;
  final VehicleFuelType? fuelType;
  final VehicleTransmission? transmission;
  final int? seatingCapacity;
  final int? engineCapacityCc;
  final String? mileage;
  final double? exShowroomPrice;
  final double? onRoadPrice;
  final List<String> colors;
  final String? coverImage;
  final List<String> images;
  final Map<String, dynamic> raw;

  VehiclePrefill({
    this.variantId,
    this.brandId,
    this.modelId,
    this.categoryId,
    this.name,
    this.brand,
    this.model,
    this.variant,
    this.category,
    this.subCategory,
    this.type,
    this.fuelType,
    this.transmission,
    this.seatingCapacity,
    this.engineCapacityCc,
    this.mileage,
    this.exShowroomPrice,
    this.onRoadPrice,
    this.colors = const [],
    this.coverImage,
    this.images = const [],
    this.raw = const {},
  });

  /// Accepts either the raw response (with a nested `prefill` object) or the
  /// `prefill` object itself.
  factory VehiclePrefill.fromJson(Map<String, dynamic> j) {
    final p = (j['prefill'] is Map)
        ? Map<String, dynamic>.from(j['prefill'] as Map)
        : j;
    return VehiclePrefill(
      variantId: (p['variant_id'] ?? p['_id'] ?? p['id']) as String?,
      brandId: p['brand_id'] as String?,
      modelId: p['model_id'] as String?,
      categoryId: p['category_id'] as String?,
      name: p['name'] as String?,
      brand: p['brand'] as String?,
      model: p['model'] as String?,
      variant: p['variant'] as String?,
      category: p['category'] as String?,
      subCategory: p['sub_category'] as String?,
      type: p['type'] as String?,
      fuelType: VehicleFuelTypeWire.parse(p['fuel_type'] as String?),
      transmission: VehicleTransmissionWire.parse(p['transmission'] as String?),
      seatingCapacity: (p['seating_capacity'] as num?)?.toInt(),
      engineCapacityCc: (p['engine_capacity_cc'] as num?)?.toInt(),
      mileage: p['mileage'] as String?,
      exShowroomPrice: (p['ex_showroom_price'] as num?)?.toDouble(),
      onRoadPrice: (p['on_road_price'] as num?)?.toDouble(),
      colors:
          ((p['colors'] as List?) ?? const []).whereType<String>().toList(),
      coverImage: p['cover_image'] as String?,
      images:
          ((p['images'] as List?) ?? const []).whereType<String>().toList(),
      raw: p,
    );
  }
}

class Vehicle {
  final String? id;
  final String? userId;
  final String? businessId;
  // Catalog ref — the only identity field create reads (the rest are
  // catalog-derived and ignored if sent). Required by POST /vehicles/create.
  final String? variantId;
  final String name;
  final String? description;
  final String? category; // L1 — PASSENGER / COMMERCIAL
  final String? subCategory; // L2 — e.g. PASSENGER_2W
  final String? type; // L3 — concrete leaf, e.g. MOTORCYCLE
  final String? condition; // NEW / USED
  final String? brand;
  final String? model;
  final String? variant;
  final int? year;
  final String? color; // USED
  final String? registrationNo; // USED
  final VehicleFuelType? fuelType;
  final VehicleTransmission? transmission;
  final int? seatingCapacity;
  final int? engineCapacityCc;
  final String? mileage;
  final double? price;
  final String? currency;
  final VehicleLocation? location;
  final String? coverImage;
  final List<String> images;
  final List<String> videos;
  final String? sellerName;
  final String? sellerMobile;

  // ─── NEW-flow detail fields ──────────────────────────────────────
  final String? availability;
  final String? deliveryTime;
  final double? exShowroomPrice;
  final double? onRoadPrice;
  final bool? emiAvailable;
  final double? downPayment;
  final double? monthlyEmi;
  final List<String> specialOffers;

  // ─── USED-flow detail fields ─────────────────────────────────────
  final int? manufacturingYear;
  final int? registrationYear;
  final String? ownership;
  final String? conditionGrade;
  final double? expectedPrice;
  final bool? isNegotiable;
  final int? kmDriven;
  final DateTime? insuranceValidTill;
  final bool? rcAvailable;
  final bool? pollutionCertificate;
  final bool? serviceHistory;

  final bool? isActive;
  final bool? isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── Display labels (decorated by server on reads) ───────────────
  final String? categoryLabel;
  final String? subCategoryLabel;
  final String? typeLabel;
  final String? conditionLabel;
  final String? availabilityLabel;
  final String? deliveryTimeLabel;
  final String? ownershipLabel;
  final String? conditionGradeLabel;
  final List<String> specialOffersLabels;

  /// Owner profile when hydrated by the server (gRPC enrichment).
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? business;

  Vehicle({
    this.id,
    this.userId,
    this.businessId,
    this.variantId,
    required this.name,
    this.description,
    this.category,
    this.subCategory,
    this.type,
    this.condition,
    this.brand,
    this.model,
    this.variant,
    this.year,
    this.color,
    this.registrationNo,
    this.fuelType,
    this.transmission,
    this.seatingCapacity,
    this.engineCapacityCc,
    this.mileage,
    this.price,
    this.currency,
    this.location,
    this.coverImage,
    this.images = const [],
    this.videos = const [],
    this.sellerName,
    this.sellerMobile,
    this.availability,
    this.deliveryTime,
    this.exShowroomPrice,
    this.onRoadPrice,
    this.emiAvailable,
    this.downPayment,
    this.monthlyEmi,
    this.specialOffers = const [],
    this.manufacturingYear,
    this.registrationYear,
    this.ownership,
    this.conditionGrade,
    this.expectedPrice,
    this.isNegotiable,
    this.kmDriven,
    this.insuranceValidTill,
    this.rcAvailable,
    this.pollutionCertificate,
    this.serviceHistory,
    this.isActive,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
    this.categoryLabel,
    this.subCategoryLabel,
    this.typeLabel,
    this.conditionLabel,
    this.availabilityLabel,
    this.deliveryTimeLabel,
    this.ownershipLabel,
    this.conditionGradeLabel,
    this.specialOffersLabels = const [],
    this.user,
    this.business,
  });

  bool get isUsed => (condition ?? '').toUpperCase() == VehicleCondition.used;
  bool get isNew => (condition ?? '').toUpperCase() == VehicleCondition.isNew;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        variantId: j['variant_id'] as String?,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        category: j['category'] as String?,
        subCategory: j['sub_category'] as String?,
        type: j['type'] as String?,
        condition: j['condition'] as String?,
        brand: j['brand'] as String?,
        model: j['model'] as String?,
        variant: j['variant'] as String?,
        year: (j['year'] as num?)?.toInt(),
        color: j['color'] as String?,
        registrationNo: j['registration_no'] as String?,
        fuelType: VehicleFuelTypeWire.parse(j['fuel_type'] as String?),
        transmission:
            VehicleTransmissionWire.parse(j['transmission'] as String?),
        seatingCapacity: (j['seating_capacity'] as num?)?.toInt(),
        engineCapacityCc: (j['engine_capacity_cc'] as num?)?.toInt(),
        mileage: j['mileage'] as String?,
        price: (j['price'] as num?)?.toDouble(),
        currency: j['currency'] as String?,
        location: j['location'] is Map<String, dynamic>
            ? VehicleLocation.fromJson(
                Map<String, dynamic>.from(j['location'] as Map))
            : null,
        coverImage: j['cover_image'] as String?,
        images:
            ((j['images'] as List?) ?? const []).whereType<String>().toList(),
        videos:
            ((j['videos'] as List?) ?? const []).whereType<String>().toList(),
        sellerName: j['seller_name'] as String?,
        sellerMobile: j['seller_mobile'] as String?,
        availability: j['availability'] as String?,
        deliveryTime: j['delivery_time'] as String?,
        exShowroomPrice: (j['ex_showroom_price'] as num?)?.toDouble(),
        onRoadPrice: (j['on_road_price'] as num?)?.toDouble(),
        emiAvailable: j['emi_available'] as bool?,
        downPayment: (j['down_payment'] as num?)?.toDouble(),
        monthlyEmi: (j['monthly_emi'] as num?)?.toDouble(),
        specialOffers: ((j['special_offers'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        manufacturingYear: (j['manufacturing_year'] as num?)?.toInt(),
        registrationYear: (j['registration_year'] as num?)?.toInt(),
        ownership: j['ownership'] as String?,
        conditionGrade: j['condition_grade'] as String?,
        expectedPrice: (j['expected_price'] as num?)?.toDouble(),
        isNegotiable: j['is_negotiable'] as bool?,
        kmDriven: (j['km_driven'] as num?)?.toInt(),
        insuranceValidTill:
            DateTime.tryParse(j['insurance_valid_till']?.toString() ?? ''),
        rcAvailable: j['rc_available'] as bool?,
        pollutionCertificate: j['pollution_certificate'] as bool?,
        serviceHistory: j['service_history'] as bool?,
        isActive: j['is_active'] as bool?,
        isVerified: j['is_verified'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
        categoryLabel: j['category_label'] as String?,
        subCategoryLabel: j['sub_category_label'] as String?,
        typeLabel: j['type_label'] as String?,
        conditionLabel: j['condition_label'] as String?,
        availabilityLabel: j['availability_label'] as String?,
        deliveryTimeLabel: j['delivery_time_label'] as String?,
        ownershipLabel: j['ownership_label'] as String?,
        conditionGradeLabel: j['condition_grade_label'] as String?,
        specialOffersLabels: ((j['special_offers_labels'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        user: j['user'] is Map
            ? Map<String, dynamic>.from(j['user'] as Map)
            : null,
        business: j['business'] is Map
            ? Map<String, dynamic>.from(j['business'] as Map)
            : null,
      );

  /// Wire payload for create / update.
  ///
  /// Only provided keys are emitted, and the flow-specific blocks are
  /// gated on [condition] so a NEW listing never carries used-only data
  /// (and vice-versa) — the server rejects cross-flow fields with 400.
  /// `registration_no` and `color` are USED-only, so they live in the
  /// USED block rather than the shared base.
  Map<String, dynamic> toCreateJson() {
    final body = <String, dynamic>{
      // Catalog ref — always-required by create. Identity/spec fields below
      // are catalog-derived (ignored if sent) but kept for the legacy/free-text
      // path and harmless when a `variant_id` is present.
      if (variantId != null) 'variant_id': variantId,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      if (type != null) 'type': type,
      if (condition != null) 'condition': condition,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (variant != null) 'variant': variant,
      if (year != null) 'year': year,
      if (fuelType != null) 'fuel_type': fuelType!.wire,
      if (transmission != null) 'transmission': transmission!.wire,
      if (seatingCapacity != null) 'seating_capacity': seatingCapacity,
      if (engineCapacityCc != null) 'engine_capacity_cc': engineCapacityCc,
      if (mileage != null) 'mileage': mileage,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (location != null) 'location': location!.toJson(),
      if (coverImage != null) 'cover_image': coverImage,
      if (images.isNotEmpty) 'images': images,
      if (videos.isNotEmpty) 'videos': videos,
      if (sellerName != null) 'seller_name': sellerName,
      if (sellerMobile != null) 'seller_mobile': sellerMobile,
      if (businessId != null) 'business_id': businessId,
    };

    if (isUsed) {
      body.addAll({
        if (color != null) 'color': color,
        if (registrationNo != null) 'registration_no': registrationNo,
        if (manufacturingYear != null) 'manufacturing_year': manufacturingYear,
        if (registrationYear != null) 'registration_year': registrationYear,
        if (ownership != null) 'ownership': ownership,
        if (conditionGrade != null) 'condition_grade': conditionGrade,
        if (expectedPrice != null) 'expected_price': expectedPrice,
        if (isNegotiable != null) 'is_negotiable': isNegotiable,
        if (kmDriven != null) 'km_driven': kmDriven,
        if (insuranceValidTill != null)
          'insurance_valid_till': insuranceValidTill!.toUtc().toIso8601String(),
        if (rcAvailable != null) 'rc_available': rcAvailable,
        if (pollutionCertificate != null)
          'pollution_certificate': pollutionCertificate,
        if (serviceHistory != null) 'service_history': serviceHistory,
      });
    } else if (isNew) {
      body.addAll({
        if (availability != null) 'availability': availability,
        if (deliveryTime != null) 'delivery_time': deliveryTime,
        if (exShowroomPrice != null) 'ex_showroom_price': exShowroomPrice,
        if (onRoadPrice != null) 'on_road_price': onRoadPrice,
        if (emiAvailable != null) 'emi_available': emiAvailable,
        if (emiAvailable == true && downPayment != null)
          'down_payment': downPayment,
        if (emiAvailable == true && monthlyEmi != null)
          'monthly_emi': monthlyEmi,
        if (specialOffers.isNotEmpty) 'special_offers': specialOffers,
      });
    }
    return body;
  }
}

class PaginatedVehicles {
  final List<Vehicle> vehicles;
  final int page;
  final int limit;
  final int total;

  PaginatedVehicles({
    required this.vehicles,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PaginatedVehicles.fromJson(Map<String, dynamic> j) =>
      PaginatedVehicles(
        vehicles: ((j['vehicles'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Vehicle.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        page: (j['page'] as num?)?.toInt() ?? 1,
        limit: (j['limit'] as num?)?.toInt() ?? 20,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );

  bool get hasMore => vehicles.length + ((page - 1) * limit) < total;
}

// ─────────────────────────────────────────────────────────────────────
// Facility
// ─────────────────────────────────────────────────────────────────────

class VehicleFacility {
  final String? id;
  final String? userId;
  final String? businessId;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final String? type;
  final bool? isActive;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleFacility({
    this.id,
    this.userId,
    this.businessId,
    required this.name,
    this.description,
    this.icon,
    this.image,
    this.type,
    this.isActive,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleFacility.fromJson(Map<String, dynamic> j) => VehicleFacility(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        icon: j['icon'] as String?,
        image: j['image'] as String?,
        type: j['type'] as String?,
        isActive: j['is_active'] as bool?,
        sortOrder: (j['sort_order'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (image != null) 'image': image,
        if (type != null) 'type': type,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Live photo
// ─────────────────────────────────────────────────────────────────────

class VehicleLivePhotoLocation {
  final double? lat;
  final double? lon;

  VehicleLivePhotoLocation({this.lat, this.lon});

  factory VehicleLivePhotoLocation.fromJson(Map<String, dynamic> j) =>
      VehicleLivePhotoLocation(
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };
}

class VehicleLivePhoto {
  final String? id;
  final String? userId;
  final String? businessId;
  final String imageUrl;
  final String? caption;
  final DateTime? capturedAt;
  final VehicleLivePhotoLocation? location;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleLivePhoto({
    this.id,
    this.userId,
    this.businessId,
    required this.imageUrl,
    this.caption,
    this.capturedAt,
    this.location,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleLivePhoto.fromJson(Map<String, dynamic> j) => VehicleLivePhoto(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        imageUrl: (j['image_url'] ?? '') as String,
        caption: j['caption'] as String?,
        capturedAt: DateTime.tryParse(j['captured_at']?.toString() ?? ''),
        location: j['location'] is Map
            ? VehicleLivePhotoLocation.fromJson(
                Map<String, dynamic>.from(j['location'] as Map))
            : null,
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'image_url': imageUrl,
        if (caption != null) 'caption': caption,
        if (capturedAt != null)
          'captured_at': capturedAt!.toUtc().toIso8601String(),
        if (location != null) 'location': location!.toJson(),
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Gallery item
// ─────────────────────────────────────────────────────────────────────

enum VehicleMediaType { image, video }

extension VehicleMediaTypeWire on VehicleMediaType {
  String get wire => name.toUpperCase();
  static VehicleMediaType parse(String? s) {
    if (s?.toUpperCase() == 'VIDEO') return VehicleMediaType.video;
    return VehicleMediaType.image;
  }
}

class VehicleGalleryItem {
  final String? id;
  final String? userId;
  final String? businessId;
  final String? album; // default "default"
  final String? title;
  final String? description;
  final VehicleMediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int? sortOrder;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleGalleryItem({
    this.id,
    this.userId,
    this.businessId,
    this.album,
    this.title,
    this.description,
    this.mediaType = VehicleMediaType.image,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.sortOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleGalleryItem.fromJson(Map<String, dynamic> j) =>
      VehicleGalleryItem(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        album: j['album'] as String?,
        title: j['title'] as String?,
        description: j['description'] as String?,
        mediaType: VehicleMediaTypeWire.parse(j['media_type'] as String?),
        mediaUrl: (j['media_url'] ?? '') as String,
        thumbnailUrl: j['thumbnail_url'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt(),
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'media_url': mediaUrl,
        'media_type': mediaType.wire,
        if (album != null) 'album': album,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Testimonial
// ─────────────────────────────────────────────────────────────────────

class VehicleTestimonial {
  final String? id;
  final String toUser;
  final String? fromUser;
  final String? businessId;
  final String title;
  final String description;
  final double? rating; // 0..5
  final String? image;
  final bool? isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Hydrated by server on read endpoints.
  final Map<String, dynamic>? from;
  final Map<String, dynamic>? fromBusiness;

  VehicleTestimonial({
    this.id,
    required this.toUser,
    this.fromUser,
    this.businessId,
    required this.title,
    required this.description,
    this.rating,
    this.image,
    this.isVisible,
    this.createdAt,
    this.updatedAt,
    this.from,
    this.fromBusiness,
  });

  factory VehicleTestimonial.fromJson(Map<String, dynamic> j) =>
      VehicleTestimonial(
        id: j['_id'] as String?,
        toUser: (j['toUser'] ?? '') as String,
        fromUser: j['fromUser'] as String?,
        businessId: j['business_id'] as String?,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        rating: (j['rating'] as num?)?.toDouble(),
        image: j['image'] as String?,
        isVisible: j['is_visible'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
        from: j['from'] is Map
            ? Map<String, dynamic>.from(j['from'] as Map)
            : null,
        fromBusiness: j['from_business'] is Map
            ? Map<String, dynamic>.from(j['from_business'] as Map)
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        'toUser': toUser,
        'title': title,
        'description': description,
        if (rating != null) 'rating': rating,
        if (image != null) 'image': image,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Contact us
// ─────────────────────────────────────────────────────────────────────

class VehicleContact {
  final String? id;
  final String? userId;
  final String? businessId;
  final String locationName;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final int? pincode;
  final double? lat;
  final double? lon;
  final VehiclePhoneNumber? phoneNumber;
  final VehiclePhoneNumber? alternatePhoneNumber;
  final String? email;
  final String? website;
  final String? openingHours;
  final String? mapLink;
  final bool? isPrimary;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleContact({
    this.id,
    this.userId,
    this.businessId,
    required this.locationName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.lat,
    this.lon,
    this.phoneNumber,
    this.alternatePhoneNumber,
    this.email,
    this.website,
    this.openingHours,
    this.mapLink,
    this.isPrimary,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleContact.fromJson(Map<String, dynamic> j) => VehicleContact(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        locationName: (j['location_name'] ?? '') as String,
        address: j['address'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        country: j['country'] as String?,
        pincode: (j['pincode'] as num?)?.toInt(),
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        phoneNumber: j['phone_number'] is Map
            ? VehiclePhoneNumber.fromJson(
                Map<String, dynamic>.from(j['phone_number'] as Map))
            : null,
        alternatePhoneNumber: j['alternate_phone_number'] is Map
            ? VehiclePhoneNumber.fromJson(
                Map<String, dynamic>.from(j['alternate_phone_number'] as Map))
            : null,
        email: j['email'] as String?,
        website: j['website'] as String?,
        openingHours: j['opening_hours'] as String?,
        mapLink: j['map_link'] as String?,
        isPrimary: j['is_primary'] as bool?,
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'location_name': locationName,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (pincode != null) 'pincode': pincode,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (phoneNumber != null) 'phone_number': phoneNumber!.toJson(),
        if (alternatePhoneNumber != null)
          'alternate_phone_number': alternatePhoneNumber!.toJson(),
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (openingHours != null) 'opening_hours': openingHours,
        if (mapLink != null) 'map_link': mapLink,
        if (isPrimary != null) 'is_primary': isPrimary,
        if (isActive != null) 'is_active': isActive,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// S3 presigned upload
// ─────────────────────────────────────────────────────────────────────

class VehicleUploadInit {
  final String uploadUrl; // S3 presigned PUT URL — 30 min validity
  final String publicUrl; // public URL to persist on the entity
  final String fileKey; // S3 object key

  VehicleUploadInit({
    required this.uploadUrl,
    required this.publicUrl,
    required this.fileKey,
  });

  factory VehicleUploadInit.fromJson(Map<String, dynamic> j) =>
      VehicleUploadInit(
        uploadUrl: (j['uploadUrl'] ?? '') as String,
        publicUrl: (j['publicUrl'] ?? '') as String,
        fileKey: (j['fileKey'] ?? '') as String,
      );
}

/// Presigned S3 **POST** policy from `GET /upload/init-v2` (preferred). S3
/// enforces the declared Content-Type and a hard size cap via the signed
/// policy. Build a multipart body with all [fields] first, then the file
/// last, and POST it to [url]; persist [publicUrl] afterwards.
class VehicleUploadInitV2 {
  final String url; // S3 bucket POST endpoint
  final Map<String, dynamic> fields; // policy fields (append before file)
  final String publicUrl; // public URL to persist on the entity
  final String fileKey; // S3 object key
  final int? maxSizeBytes; // hard size cap S3 enforces

  VehicleUploadInitV2({
    required this.url,
    required this.fields,
    required this.publicUrl,
    required this.fileKey,
    this.maxSizeBytes,
  });

  factory VehicleUploadInitV2.fromJson(Map<String, dynamic> j) =>
      VehicleUploadInitV2(
        url: (j['url'] ?? '') as String,
        fields: j['fields'] is Map
            ? Map<String, dynamic>.from(j['fields'] as Map)
            : const {},
        publicUrl: (j['publicUrl'] ?? '') as String,
        fileKey: (j['fileKey'] ?? '') as String,
        maxSizeBytes: (j['maxSizeBytes'] as num?)?.toInt(),
      );
}
