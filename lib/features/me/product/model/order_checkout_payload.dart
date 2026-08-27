import 'package:uuid/uuid.dart';

/// One checkout ATTEMPT's idempotency key.
///
/// The case that matters is the retry-after-timeout: the request succeeded,
/// the response was lost, the user taps again. With the key they get the same
/// order back with `200`. Without it they get two orders and one very confused
/// shop.
///
/// The rules, and why:
///
///  * **[begin] when the checkout sheet OPENS** — not on every tap. A key
///    regenerated per tap defeats the whole point.
///  * **[complete] after the order is created** — a NEW order needs a NEW key,
///    otherwise the customer's second order comes back as the first one.
///  * `201` = created, `200` = you already created this one. **Both are
///    success.**
///
/// The in-session `isPlacingOrder` guard that already exists in these
/// controllers is kept — it stops a double-tap inside one session — but it
/// does not survive a lost response, which is exactly what this key is for.
class CheckoutAttempt {
  static const Uuid _uuid = Uuid();

  String? _attemptId;

  /// Call when the checkout sheet opens.
  void begin() => _attemptId = _uuid.v4();

  /// The key to send. Generates one lazily if [begin] was never called, so a
  /// caller that forgets still gets retry safety within the attempt.
  String get key => _attemptId ??= _uuid.v4();

  /// Call once the order is created (201 **or** 200).
  void complete() => _attemptId = null;

  bool get isActive => _attemptId != null;
}

/// The `delivery` block on `POST /api/orders`.
///
/// **Required when `deliveryType == 'rider'`**, and it must carry a real
/// coordinate: the rider-order gate reads **only** `delivery.location.
/// coordinates` or `delivery.coordinates`, as GeoJSON **`[longitude,
/// latitude]` — lng first**. A flat `latitude` / `longitude` pair alone is
/// rejected with `400 DELIVERY_LOCATION_REQUIRED`, which is why every doorstep
/// order used to fail even with a complete address (guide §0 cause 6, §5.4).
///
/// It also records what the customer was actually shown at checkout —
/// `distanceKm`, `feeEstimate`, `etaMinutes` come straight from the quote — so
/// a later dispute has the quoted numbers rather than a recomputed guess.
/// **There is no endpoint to attach the quote later**: no
/// `PATCH /:orderId/delivery-quote` exists, so anything not sent here is lost
/// forever (guide §0 cause 7).
class OrderDeliveryDetails {
  final String? addressLine;
  final String? landmark;
  final String? city;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? contactName;
  final String? contactNo;
  final String? instructions;

  /// From `GET /fare/chat-dispatch/quote`.
  final double? distanceKm;
  final num? feeEstimate;
  final int? etaMinutes;

  const OrderDeliveryDetails({
    this.addressLine,
    this.landmark,
    this.city,
    this.pincode,
    this.latitude,
    this.longitude,
    this.contactName,
    this.contactNo,
    this.instructions,
    this.distanceKm,
    this.feeEstimate,
    this.etaMinutes,
  });

  /// True once there is a real point to deliver to. **The checkout gate is
  /// this getter** — a typed address with no coordinate does not pass, because
  /// neither the order gate nor the rider search can use it.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Null keys are omitted rather than sent as null — the backend treats the
  /// whole block as optional and a half-null address is worse than none.
  Map<String, dynamic> toJson() => {
        if (addressLine != null && addressLine!.isNotEmpty)
          'addressLine': addressLine,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (pincode != null && pincode!.isNotEmpty) 'pincode': pincode,

        // ⚠ THE SHAPE THAT MATTERS. GeoJSON, [lng, lat], lng first.
        if (hasCoordinates)
          'location': {
            'type': 'Point',
            'coordinates': [longitude, latitude],
          },
        // Sent alongside for anything that reads the flat pair for display.
        // It is NOT a substitute: the gate above ignores these two.
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,

        if (contactName != null && contactName!.isNotEmpty)
          'contactName': contactName,
        if (contactNo != null && contactNo!.isNotEmpty) 'contactNo': contactNo,
        if (instructions != null && instructions!.isNotEmpty)
          'instructions': instructions,

        // The quote the customer was shown. Nowhere else to put it later.
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (feeEstimate != null) 'feeEstimate': feeEstimate,
        if (etaMinutes != null) 'etaMinutes': etaMinutes,
      };

  bool get isEmpty => toJson().isEmpty;

  OrderDeliveryDetails copyWithQuote({
    double? distanceKm,
    num? feeEstimate,
    int? etaMinutes,
  }) =>
      OrderDeliveryDetails(
        addressLine: addressLine,
        landmark: landmark,
        city: city,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        contactName: contactName,
        contactNo: contactNo,
        instructions: instructions,
        distanceKm: distanceKm ?? this.distanceKm,
        feeEstimate: feeEstimate ?? this.feeEstimate,
        etaMinutes: etaMinutes ?? this.etaMinutes,
      );
}

/// How the customer will pay. `cash` is the default; `upi` switches the order
/// into the submit → verify flow, where money is only requested **after** the
/// shop accepts.
class OrderPaymentMethod {
  static const cash = 'cash';
  static const upi = 'upi';
}

/// `deliveryType` values accepted by `POST /api/orders`.
class OrderDeliveryType {
  static const selfPickup = 'self-pickup';
  static const rider = 'rider';
}
