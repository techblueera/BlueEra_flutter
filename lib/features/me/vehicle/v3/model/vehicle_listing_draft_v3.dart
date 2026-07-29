/// The add-listing form's payload, and the one place the NEW/USED split is
/// decided.
///
/// Per §2 of the integration guide both conditions are Inventory rows and
/// share their identity and specs (both come from the catalog). What differs
/// is the extra keys the seller supplies, and where photos come from:
///
/// | | NEW | USED |
/// |---|---|---|
/// | Photos | from the catalog | **seller uploads their own** |
/// | Extra keys | `on_road_price`, `availability`, `delivery_time`, `emi_available`, `special_offers` | `km_driven`, `ownership`, `registration_year`, `condition_grade`, `expected_price`, `is_negotiable`, `insurance_valid_till`, `rc_available`, `service_history`, `description` |
///
/// [toFields] emits only the keys for the chosen condition, so a seller who
/// switches NEW→USED mid-form can't leak stale NEW keys into the request.
/// (The server drops unknown keys silently rather than rejecting them, but
/// sending an `on_road_price` on a used bike would still be wrong data.)
class VehicleListingDraftV3 {
  /// The colour id — **required on create**, and the reason the catalog walk
  /// cannot stop at a trim. See guide §4 step 5.
  final String productVariantId;

  /// `NEW` or `USED` — use [VehicleListingCondition].
  final String condition;

  // ── Shared ────────────────────────────────────────────────────────
  final String address;
  final String city;
  final String state;
  final String pincode;

  /// Sent as plain `lat`/`lng` fields. The server builds the GeoJSON point —
  /// the guide is explicit that a client must never send `location` itself.
  final double? lat;
  final double? lng;

  // ── USED only ─────────────────────────────────────────────────────
  final int? kmDriven;
  final String? ownership;
  final int? registrationYear;
  final String? conditionGrade;
  final num? expectedPrice;
  final bool? isNegotiable;
  final String? insuranceValidTill;
  final bool? rcAvailable;
  final String? serviceHistory;
  final String? description;

  // ── NEW only ──────────────────────────────────────────────────────
  final num? onRoadPrice;
  final String? availability;
  final String? deliveryTime;
  final bool? emiAvailable;
  final String? specialOffers;

  /// Local file paths of the seller's photos. USED listings only — a NEW
  /// listing shows the catalog's artwork, so it uploads nothing.
  final List<String> imagePaths;

  /// Optional local path for the cover. When omitted the server promotes the
  /// first `images` entry, so the form doesn't force a choice.
  final String? coverImagePath;

  const VehicleListingDraftV3({
    required this.productVariantId,
    required this.condition,
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.lat,
    this.lng,
    this.kmDriven,
    this.ownership,
    this.registrationYear,
    this.conditionGrade,
    this.expectedPrice,
    this.isNegotiable,
    this.insuranceValidTill,
    this.rcAvailable,
    this.serviceHistory,
    this.description,
    this.onRoadPrice,
    this.availability,
    this.deliveryTime,
    this.emiAvailable,
    this.specialOffers,
    this.imagePaths = const [],
    this.coverImagePath,
  });

  bool get isNew => condition.toUpperCase() == VehicleListingCondition.isNew;

  /// Max photos the server accepts on one listing. Exceeding it is a 400
  /// (`LIMIT_UNEXPECTED_FILE`), so the picker caps here rather than finding
  /// out from the response.
  static const int maxImages = 12;

  /// Scalar fields for the request body. Files are attached separately by the
  /// repo (see [imagePaths]) because they need `MultipartFile` wrappers.
  ///
  /// Nulls and empty strings are dropped so a half-filled optional section
  /// doesn't post empty values over server defaults.
  Map<String, dynamic> toFields() {
    final fields = <String, dynamic>{
      'productVariant': productVariantId,
      'condition': condition.toUpperCase(),
    };

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      fields[key] = value is String ? value.trim() : value;
    }

    put('address', address);
    put('city', city);
    put('state', state);
    put('pincode', pincode);
    put('lat', lat);
    put('lng', lng);

    if (isNew) {
      put('on_road_price', onRoadPrice);
      put('availability', availability);
      put('delivery_time', deliveryTime);
      put('emi_available', emiAvailable);
      put('special_offers', specialOffers);
    } else {
      put('km_driven', kmDriven);
      put('ownership', ownership);
      put('registration_year', registrationYear);
      put('condition_grade', conditionGrade);
      put('expected_price', expectedPrice);
      put('is_negotiable', isNegotiable);
      put('insurance_valid_till', insuranceValidTill);
      put('rc_available', rcAvailable);
      put('service_history', serviceHistory);
      put('description', description);
    }

    return fields;
  }

  /// Client-side validation. Returns the first problem, or null when the
  /// draft is submittable.
  ///
  /// Deliberately thin: only what the server treats as required on create
  /// (`productVariant` + `condition`), the photo cap it 400s on, and the one
  /// piece of USED data a listing is useless without — an asking price.
  String? validate() {
    if (productVariantId.trim().isEmpty) {
      return 'Pick a colour before publishing this listing.';
    }
    final normalised = condition.toUpperCase();
    if (normalised != VehicleListingCondition.isNew &&
        normalised != VehicleListingCondition.used) {
      return 'Choose whether this vehicle is new or used.';
    }
    if (imagePaths.length > maxImages) {
      return 'You can attach at most $maxImages photos.';
    }
    if (!isNew) {
      if (expectedPrice == null || expectedPrice! <= 0) {
        return 'Enter the price you are asking for this vehicle.';
      }
      if (imagePaths.isEmpty) {
        return 'Add at least one photo of the vehicle.';
      }
    }
    return null;
  }

  VehicleListingDraftV3 copyWith({
    String? productVariantId,
    String? condition,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? lat,
    double? lng,
    int? kmDriven,
    String? ownership,
    int? registrationYear,
    String? conditionGrade,
    num? expectedPrice,
    bool? isNegotiable,
    String? insuranceValidTill,
    bool? rcAvailable,
    String? serviceHistory,
    String? description,
    num? onRoadPrice,
    String? availability,
    String? deliveryTime,
    bool? emiAvailable,
    String? specialOffers,
    List<String>? imagePaths,
    String? coverImagePath,
  }) {
    return VehicleListingDraftV3(
      productVariantId: productVariantId ?? this.productVariantId,
      condition: condition ?? this.condition,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      kmDriven: kmDriven ?? this.kmDriven,
      ownership: ownership ?? this.ownership,
      registrationYear: registrationYear ?? this.registrationYear,
      conditionGrade: conditionGrade ?? this.conditionGrade,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      insuranceValidTill: insuranceValidTill ?? this.insuranceValidTill,
      rcAvailable: rcAvailable ?? this.rcAvailable,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      description: description ?? this.description,
      onRoadPrice: onRoadPrice ?? this.onRoadPrice,
      availability: availability ?? this.availability,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      emiAvailable: emiAvailable ?? this.emiAvailable,
      specialOffers: specialOffers ?? this.specialOffers,
      imagePaths: imagePaths ?? this.imagePaths,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }
}

/// The two conditions, as the wire spells them.
///
/// Separate from the legacy `VehicleCondition` in `model/vehicle_models.dart`
/// so the v3 flow doesn't pull the old API's model file in behind it — the
/// string values are identical, which is what matters at the boundary.
class VehicleListingCondition {
  const VehicleListingCondition._();

  static const String isNew = 'NEW';
  static const String used = 'USED';
}

/// Picker options for the USED-only enum fields. The rebuilt service exposes
/// no `/options` endpoint (the old one is in the removed list), so these are
/// client-side.
class VehicleListingOptions {
  const VehicleListingOptions._();

  static const List<String> ownership = [
    'First Owner',
    'Second Owner',
    'Third Owner',
    'Fourth Owner or more',
  ];

  static const List<String> conditionGrade = [
    'Excellent',
    'Good',
    'Fair',
    'Needs Work',
  ];

  static const List<String> availability = [
    'In Stock',
    'Limited Stock',
    'Booking Open',
    'Out of Stock',
  ];

  /// Convenience for the trim/colour helpers — a listing model year can't
  /// sensibly predate this.
  static const int earliestRegistrationYear = 1980;
}

/// `5,20,000` — Indian digit grouping (last three, then pairs), no decimals.
/// Prices and odometer readings in this service are whole numbers.
String _groupIndian(num value) {
  final whole = value.round().abs().toString();
  final sign = value < 0 ? '-' : '';
  if (whole.length <= 3) return '$sign$whole';

  final last3 = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final pairs = <String>[];
  while (rest.length > 2) {
    pairs.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) pairs.insert(0, rest);
  return '$sign${pairs.join(',')},$last3';
}

/// Small helper the form and cards share: `₹5,20,000` from a raw number.
String formatVehiclePriceV3(num? value) =>
    value == null ? '' : '₹${_groupIndian(value)}';

/// `42,000 km` for the odometer line.
String formatKilometresV3(int? km) =>
    km == null ? '' : '${_groupIndian(km)} km';
