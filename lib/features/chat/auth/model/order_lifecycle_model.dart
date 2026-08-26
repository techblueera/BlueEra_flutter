/// Models for the server-driven order lifecycle.
///
/// **The one rule (guide §1):** the backend computes the state machine and
/// emits `availableActions[]`; Flutter renders that list and sends the action
/// back. Nothing in this file derives a button, a deadline or a status string
/// from the client clock.
///
/// **Three data planes, three shapes (guide §2).** Conflating them is what made
/// the app look static:
///
///   * **Plane A** — `metadata.lifecycle` on a chat card, pushed over
///     `productOrderLifecycle`. Role-split action lists, a banner, deadlines.
///     **No money, no items.** → [OrderLifecycle.fromJson]
///   * **Plane B** — `GET <svc>/api/orders/:id/actions`. Carries **`actor`**
///     (`customer`|`owner`|`admin`), a caller-scoped `availableActions`, and
///     bare-string `cancellationReasons`. **No `lifecycle`, no `banner`, no
///     `paymentSummary`.** → [OrderActionsModel.fromJson]
///   * **Plane C** — every action response: the **whole order**, with all money
///     under **`data.payment.*`** and `warning` as a **sibling of `data`**.
///     → [OrderActionsModel.fromJson] (same parser, different keys present)
///
/// Every parser is deliberately tolerant: an unknown key is ignored, a missing
/// list becomes empty, and an unknown action string simply renders no button
/// (see `order_action_bar.dart`). A newer backend must never crash an older
/// build.
library;

/// Canonical action strings. Used for the `switch` in the action bar and for
/// per-action busy keys — never to *decide* whether an action is allowed.
class OrderAction {
  // Customer
  static const submitPayment = 'SUBMIT_PAYMENT';
  static const viewPickupCode = 'VIEW_PICKUP_CODE';
  static const findRider = 'FIND_RIDER';
  static const contactShop = 'CONTACT_SHOP';
  static const raiseIssue = 'RAISE_ISSUE';
  static const confirmRefundReceived = 'CONFIRM_REFUND_RECEIVED';

  // Owner
  static const acceptOrder = 'ACCEPT_ORDER';
  static const rejectOrder = 'REJECT_ORDER';
  static const setPrepEta = 'SET_PREP_ETA';
  static const markReady = 'MARK_READY';
  static const verifyPayment = 'VERIFY_PAYMENT';
  static const rejectPayment = 'REJECT_PAYMENT';
  static const confirmHandover = 'CONFIRM_HANDOVER';
  static const reportNoShow = 'REPORT_NO_SHOW';
  static const markRefundSent = 'MARK_REFUND_SENT';
  static const contactCustomer = 'CONTACT_CUSTOMER';

  // Admin (guide §10.4) — consumer builds render read-only, never this UI.
  static const adminOverride = 'ADMIN_OVERRIDE';

  // Both
  static const cancelOrder = 'CANCEL_ORDER';
}

/// `/actions.actor` — **the** source of truth for whose buttons to render.
///
/// The app used to look for `isOwner` / `role`, which the service never sends,
/// so the value was always null and both parties fell through to the same
/// guess — buyer and seller saw the same card (guide §0 cause 1).
class OrderActor {
  static const customer = 'customer';
  static const owner = 'owner';
  static const admin = 'admin';
}

/// `lifecycle.orderStatus` values. Compared only for cosmetics (badge colour,
/// collapsed summary, which countdown to show) — never to gate an action.
class OrderStatusValue {
  static const placed = 'placed';
  static const accepted = 'accepted';
  static const inProgress = 'in-progress';
  static const ready = 'ready';
  static const dispatched = 'dispatched';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const expired = 'expired';

  static bool isTerminal(String? s) =>
      s == completed || s == cancelled || s == expired;
}

/// `lifecycle.sellerStatus` — this shop's own square in a multi-shop order.
class SellerStatusValue {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const handedOver = 'handed_over';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
}

/// `lifecycle.paymentState` values.
class PaymentStateValue {
  static const pending = 'pending';
  static const submitted = 'submitted';
  static const underReview = 'under_review';
  static const verified = 'verified';
  static const rejected = 'rejected';
  static const expired = 'expired';
  static const refundPending = 'refund_pending';
  static const refunded = 'refunded';
}

/// `deliveryType` on the order.
class OrderDeliveryTypeValue {
  static const selfPickup = 'self-pickup';
  static const rider = 'rider';
}

/// Typed error codes the order endpoints answer with. Branch on these, never
/// on `message` text (guide §10.1).
class OrderErrorCode {
  // Stale state — the other party moved first. Normal, not exceptional.
  static const actionNotAvailable = 'ACTION_NOT_AVAILABLE';
  static const concurrentModification = 'CONCURRENT_MODIFICATION';
  static const paymentConflict = 'PAYMENT_CONFLICT';
  static const invalidSellerTransition = 'INVALID_SELLER_TRANSITION';
  static const invalidPaymentTransition = 'INVALID_PAYMENT_TRANSITION';
  static const orderTerminal = 'ORDER_TERMINAL';

  // Access / identity
  static const notAPartyToOrder = 'NOT_A_PARTY_TO_ORDER';
  static const notOrderCustomer = 'NOT_ORDER_CUSTOMER';
  static const orderNotFound = 'ORDER_NOT_FOUND';
  static const invalidOrderId = 'INVALID_ORDER_ID';

  // Retired paths — this build is calling something the server removed.
  static const useLifecycleEndpoint = 'USE_LIFECYCLE_ENDPOINT';
  static const useHandoverEndpoint = 'USE_HANDOVER_ENDPOINT';

  // Payment
  static const utrAlreadyUsed = 'UTR_ALREADY_USED';
  static const tooManyPaymentAttempts = 'TOO_MANY_PAYMENT_ATTEMPTS';
  static const utrRequired = 'UTR_REQUIRED';
  static const screenshotRequired = 'SCREENSHOT_REQUIRED';
  static const invalidAmount = 'INVALID_AMOUNT';

  // Handover
  static const pickupCodeRequired = 'PICKUP_CODE_REQUIRED';
  static const pickupCodeMismatch = 'PICKUP_CODE_MISMATCH';
  static const cashNotCollected = 'CASH_NOT_COLLECTED';

  // Reasons / refunds / prep
  static const refundReferenceRequired = 'REFUND_REFERENCE_REQUIRED';
  static const reasonRequired = 'REASON_REQUIRED';
  static const invalidReason = 'INVALID_REASON';
  static const invalidPrepEta = 'INVALID_PREP_ETA';

  // Checkout / dispatch
  static const deliveryLocationRequired = 'DELIVERY_LOCATION_REQUIRED';
  static const fareMismatch = 'FARE_MISMATCH';
  static const outsideDeliveryRadius = 'OUTSIDE_DELIVERY_RADIUS';

  /// Synthesised client-side when the request never reached the server
  /// (timeout, DNS, airplane mode). Retrying is always safe — every action is
  /// a server-side compare-and-set.
  static const network = 'NETWORK_ERROR';

  /// A conflict that simply means the other party moved first.
  static bool isStaleState(String? code) =>
      code == actionNotAvailable ||
      code == concurrentModification ||
      code == paymentConflict ||
      code == invalidSellerTransition ||
      code == invalidPaymentTransition ||
      code == orderTerminal;

  /// Field-level codes the sheet/dialog that raised them renders **inline**.
  /// A toast on top of these would just cover the field.
  static bool isFieldLevel(String? code) =>
      code == utrRequired ||
      code == screenshotRequired ||
      code == invalidAmount ||
      code == utrAlreadyUsed ||
      code == pickupCodeRequired ||
      code == pickupCodeMismatch ||
      code == cashNotCollected ||
      code == refundReferenceRequired ||
      code == reasonRequired ||
      code == invalidReason ||
      code == invalidPrepEta;
}

num? _parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first);
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

// ─────────────────────────────────────────────────────────────────────────
//  Deadlines
// ─────────────────────────────────────────────────────────────────────────

/// Server-authored deadlines. **Every countdown in the UI is driven from
/// here** — never from `createdAt + constant`. A null field means "no clock
/// running for this step", which is not the same as "expired" (guide §8.1).
class OrderDeadlines {
  final DateTime? acceptBy;
  final DateTime? payBy;
  final DateTime? readyBy;
  final DateTime? pickupBy;

  /// A packed doorstep order must have a rider collecting it by here (25 min).
  final DateTime? dispatchBy;

  /// A collected doorstep order must reach the customer by here (90 min).
  final DateTime? deliverBy;

  final DateTime? hardExpiryAt;

  const OrderDeadlines({
    this.acceptBy,
    this.payBy,
    this.readyBy,
    this.pickupBy,
    this.dispatchBy,
    this.deliverBy,
    this.hardExpiryAt,
  });

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  factory OrderDeadlines.fromJson(Map<String, dynamic> json) {
    return OrderDeadlines(
      acceptBy: _dt(json['acceptBy']),
      payBy: _dt(json['payBy']),
      readyBy: _dt(json['readyBy']),
      pickupBy: _dt(json['pickupBy']),
      dispatchBy: _dt(json['dispatchBy']),
      deliverBy: _dt(json['deliverBy']),
      hardExpiryAt: _dt(json['hardExpiryAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'acceptBy': acceptBy?.toUtc().toIso8601String(),
        'payBy': payBy?.toUtc().toIso8601String(),
        'readyBy': readyBy?.toUtc().toIso8601String(),
        'pickupBy': pickupBy?.toUtc().toIso8601String(),
        'dispatchBy': dispatchBy?.toUtc().toIso8601String(),
        'deliverBy': deliverBy?.toUtc().toIso8601String(),
        'hardExpiryAt': hardExpiryAt?.toUtc().toIso8601String(),
      };

  bool get isEmpty =>
      acceptBy == null &&
      payBy == null &&
      readyBy == null &&
      pickupBy == null &&
      dispatchBy == null &&
      deliverBy == null &&
      hardExpiryAt == null;
}

// ─────────────────────────────────────────────────────────────────────────
//  Payment — `data.payment.*` on Plane C
// ─────────────────────────────────────────────────────────────────────────

/// **All money lives in `data.payment.*` on an action response** (guide §2.3).
/// `/actions` returns no money at all, which is why the pay sheet and the
/// shop's verification card refresh through an action response or `/track`
/// rather than through `/actions`.
///
/// The legacy `paymentSummary` key names are still accepted so a card that was
/// hydrated by an older build keeps rendering.
class OrderPaymentSummary {
  final String? method;
  final String? state;

  final num? amountDue;
  final num? amountPaid;

  final String? utrNo;
  final String? screenshotUrl;
  final String? upiId;
  final String? paymentQrId;

  final String? submittedAt;
  final String? verifiedAt;
  final String? rejectedAt;
  final String? rejectionReason;

  /// How many times the customer has submitted. The server caps at 5 and then
  /// answers `TOO_MANY_PAYMENT_ATTEMPTS`.
  final int? submissionCount;

  /// The UPI submission window (30 min).
  final String? dueBy;

  /// `"shop"` today, always — the customer paid the shop's own VPA.
  final String? refundOwedBy;
  final String? refundRequestedAt;

  /// Set when the shop **claims** it sent the money. A claim, not a closure.
  final String? refundInitiatedAt;
  final String? refundReference;
  final String? refundedAt;

  const OrderPaymentSummary({
    this.method,
    this.state,
    this.amountDue,
    this.amountPaid,
    this.utrNo,
    this.screenshotUrl,
    this.upiId,
    this.paymentQrId,
    this.submittedAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.submissionCount,
    this.dueBy,
    this.refundOwedBy,
    this.refundRequestedAt,
    this.refundInitiatedAt,
    this.refundReference,
    this.refundedAt,
  });

  factory OrderPaymentSummary.fromJson(Map<String, dynamic> json) {
    return OrderPaymentSummary(
      method: (json['method'] ?? json['paymentMethod'])?.toString(),
      state:
          (json['state'] ?? json['paymentState'] ?? json['status'])?.toString(),
      amountDue: _parseNum(json['amountDue'] ?? json['amount_due']),
      amountPaid: _parseNum(json['amountPaid'] ?? json['amount_paid']),
      utrNo: (json['utrNo'] ?? json['utr_no'] ?? json['utr'])?.toString(),
      screenshotUrl:
          (json['screenshotUrl'] ?? json['screenshot_url'])?.toString(),
      upiId: (json['upiId'] ?? json['upi_id'])?.toString(),
      paymentQrId: (json['paymentQrId'] ?? json['payment_qr_id'])?.toString(),
      submittedAt: json['submittedAt']?.toString(),
      verifiedAt: json['verifiedAt']?.toString(),
      rejectedAt: json['rejectedAt']?.toString(),
      rejectionReason:
          (json['rejectionReason'] ?? json['rejectedReason'] ?? json['reason'])
              ?.toString(),
      submissionCount: _parseInt(json['submissionCount']),
      dueBy: json['dueBy']?.toString(),
      refundOwedBy: json['refundOwedBy']?.toString(),
      refundRequestedAt: json['refundRequestedAt']?.toString(),
      refundInitiatedAt: json['refundInitiatedAt']?.toString(),
      refundReference:
          (json['refundReference'] ?? json['refund_reference'])?.toString(),
      refundedAt: json['refundedAt']?.toString(),
    );
  }

  /// True when the customer typed an amount that differs from the order total.
  /// Drives the amber highlight on the shop's verification card — the whole
  /// point is that the comparison is effortless before they tap.
  ///
  /// The backend tolerates ±₹1, so anything inside that is not a mismatch.
  bool get hasMismatch {
    final due = amountDue;
    final paid = amountPaid;
    if (due == null || paid == null) return false;
    return (due - paid).abs() > 1;
  }

  bool get isEmpty =>
      amountDue == null &&
      amountPaid == null &&
      (utrNo ?? '').isEmpty &&
      (screenshotUrl ?? '').isEmpty &&
      state == null;

  /// This summary laid over [base], field by field.
  ///
  /// **`/track`'s `paymentSummary` carries no refund fields at all** — not
  /// `refundOwedBy`, `refundRequestedAt`, `refundInitiatedAt`,
  /// `refundReference` or `refundedAt`. Replacing wholesale on a track refresh
  /// would therefore erase the refund state an action response had already
  /// delivered, and the card would drop from *"the shop says it sent ₹500"*
  /// back to *"the shop owes you ₹500"* — the exact distinction
  /// `refundInitiatedAt` carries.
  ///
  /// So a key the newer payload did not mention keeps the value we already
  /// had. That makes reading refunds from Plane A / Plane C (the normal path,
  /// since the refund UI is only reachable from a card just acted on or
  /// patched by socket) safe even when a cold `/track` lands on top.
  OrderPaymentSummary mergedOver(OrderPaymentSummary base) {
    return OrderPaymentSummary(
      method: method ?? base.method,
      state: state ?? base.state,
      amountDue: amountDue ?? base.amountDue,
      amountPaid: amountPaid ?? base.amountPaid,
      utrNo: utrNo ?? base.utrNo,
      screenshotUrl: screenshotUrl ?? base.screenshotUrl,
      upiId: upiId ?? base.upiId,
      paymentQrId: paymentQrId ?? base.paymentQrId,
      submittedAt: submittedAt ?? base.submittedAt,
      verifiedAt: verifiedAt ?? base.verifiedAt,
      rejectedAt: rejectedAt ?? base.rejectedAt,
      rejectionReason: rejectionReason ?? base.rejectionReason,
      submissionCount: submissionCount ?? base.submissionCount,
      dueBy: dueBy ?? base.dueBy,
      refundOwedBy: refundOwedBy ?? base.refundOwedBy,
      refundRequestedAt: refundRequestedAt ?? base.refundRequestedAt,
      refundInitiatedAt: refundInitiatedAt ?? base.refundInitiatedAt,
      refundReference: refundReference ?? base.refundReference,
      refundedAt: refundedAt ?? base.refundedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Delivery block on the order
// ─────────────────────────────────────────────────────────────────────────

/// The address the order was created with, read back off Plane C.
///
/// **The app never re-asks for this.** A doorstep order already carries its
/// drop point, so dispatch (§7.2) reuses it rather than opening an address
/// sheet the customer already filled in at checkout.
class OrderDeliveryInfo {
  final String? addressLine;
  final String? landmark;
  final String? city;
  final String? pincode;
  final String? contactName;
  final String? contactNo;
  final String? instructions;

  final double? latitude;
  final double? longitude;

  final double? distanceKm;
  final num? feeEstimate;
  final int? etaMinutes;

  const OrderDeliveryInfo({
    this.addressLine,
    this.landmark,
    this.city,
    this.pincode,
    this.contactName,
    this.contactNo,
    this.instructions,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.feeEstimate,
    this.etaMinutes,
  });

  /// Reads the coordinate back out of whichever shape the order stored:
  /// `location.coordinates` / `coordinates` (**`[lng, lat]`**, GeoJSON order)
  /// or flat `latitude` / `longitude`.
  factory OrderDeliveryInfo.fromJson(Map<String, dynamic> json) {
    double? lat = _parseDouble(json['latitude'] ?? json['lat']);
    double? lng = _parseDouble(json['longitude'] ?? json['lng']);

    dynamic coords = json['coordinates'];
    if (coords == null && json['location'] is Map) {
      coords = Map<String, dynamic>.from(json['location'])['coordinates'];
    }
    if (coords is List && coords.length >= 2) {
      // GeoJSON is [lng, lat] — the order the rider gate reads.
      lng = _parseDouble(coords[0]) ?? lng;
      lat = _parseDouble(coords[1]) ?? lat;
    }

    return OrderDeliveryInfo(
      addressLine: (json['addressLine'] ?? json['address'])?.toString(),
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(),
      contactName: json['contactName']?.toString(),
      contactNo: json['contactNo']?.toString(),
      instructions: json['instructions']?.toString(),
      latitude: lat,
      longitude: lng,
      distanceKm: _parseDouble(json['distanceKm']),
      feeEstimate: _parseNum(json['feeEstimate']),
      etaMinutes: _parseInt(json['etaMinutes']),
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}

// ─────────────────────────────────────────────────────────────────────────
//  Cancellation
// ─────────────────────────────────────────────────────────────────────────

/// One role-scoped cancellation reason offered by `/actions`.
///
/// **Never hard-code this list** — a customer must not be able to pick
/// `ITEM_UNAVAILABLE`, and the server rejects it with `INVALID_REASON` anyway.
/// The service sends **bare strings**; the `{code,label}` object shape is
/// accepted too in case that ever changes.
class OrderCancellationReason {
  final String code;
  final String label;
  final bool requiresComment;

  const OrderCancellationReason({
    required this.code,
    required this.label,
    this.requiresComment = false,
  });

  factory OrderCancellationReason.fromJson(dynamic raw) {
    if (raw is String) {
      return OrderCancellationReason(code: raw, label: _humanise(raw));
    }
    final json = Map<String, dynamic>.from(raw as Map);
    final code =
        (json['code'] ?? json['reasonCode'] ?? json['value'] ?? '').toString();
    final label =
        (json['label'] ?? json['text'] ?? json['title'] ?? '').toString();
    return OrderCancellationReason(
      code: code,
      label: label.isNotEmpty ? label : _humanise(code),
      requiresComment:
          json['requiresComment'] == true || json['commentRequired'] == true,
    );
  }

  /// `ITEM_UNAVAILABLE` → `Item unavailable`. This is the normal path, not a
  /// fallback: the service sends bare codes.
  static String _humanise(String code) {
    if (code.isEmpty) return '';
    final words = code.toLowerCase().replaceAll('_', ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// Who cancelled, why, and when — rendered on a grey terminal card.
class OrderCancellationInfo {
  final String? reasonCode;
  final String? comment;
  final String? cancelledBy;
  final String? cancelledAt;

  const OrderCancellationInfo({
    this.reasonCode,
    this.comment,
    this.cancelledBy,
    this.cancelledAt,
  });

  factory OrderCancellationInfo.fromJson(Map<String, dynamic> json) {
    return OrderCancellationInfo(
      reasonCode: json['reasonCode']?.toString(),
      comment: json['comment']?.toString(),
      cancelledBy: (json['cancelledBy'] ?? json['by'])?.toString(),
      cancelledAt: (json['cancelledAt'] ?? json['at'])?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Plane A — the chat card's lifecycle block
// ─────────────────────────────────────────────────────────────────────────

/// The `metadata.lifecycle` block carried on every order chat card.
///
/// **The card's primary source — it renders with zero network calls.** It
/// carries no money and no items; those live in `metadata.order`, already on
/// the card.
///
/// [banner] is server-authored and already worded. Render it **verbatim**.
/// Building a string from [orderStatus] is exactly how the app and the server
/// drifted apart before.
class OrderLifecycle {
  String? orderStatus;
  String? sellerStatus;
  String? paymentMethod;
  String? paymentState;
  List<String> customerActions;
  List<String> ownerActions;
  OrderDeadlines deadlines;
  String? lastEvent;
  String? lastEventAt;
  String? banner;
  String? reasonCode;
  bool refundDue;

  /// `"SELF_PICKUP_FALLBACK"` when a packed doorstep order found no rider —
  /// the order stays alive and the customer is offered collection (guide §7.6).
  String? suggestion;

  /// `"shop"` today, always. The platform never held the money — with direct
  /// UPI the customer paid the shop's own VPA — so the copy must say the shop
  /// returns it, never "we will refund you". Guide §6.9.
  String? refundOwedBy;

  /// Set once the owner claims they sent the refund. Their claim does **not**
  /// close the refund; only `CONFIRM_REFUND_RECEIVED` does.
  String? refundInitiatedAt;
  String? refundReference;

  num? refundAmount;

  /// Whether the payload this came from actually mentioned `refundDue`.
  ///
  /// `/actions` does not send it, and a plain `false` from a payload that never
  /// spoke about refunds must not clear a `true` the socket delivered — that
  /// would make the refund block vanish on the next app resume.
  final bool refundDueStated;

  OrderLifecycle({
    this.orderStatus,
    this.sellerStatus,
    this.paymentMethod,
    this.paymentState,
    List<String>? customerActions,
    List<String>? ownerActions,
    OrderDeadlines? deadlines,
    this.lastEvent,
    this.lastEventAt,
    this.banner,
    this.reasonCode,
    this.refundDue = false,
    this.suggestion,
    this.refundOwedBy,
    this.refundInitiatedAt,
    this.refundReference,
    this.refundAmount,
    this.refundDueStated = true,
  })  : customerActions = customerActions ?? const [],
        ownerActions = ownerActions ?? const [],
        deadlines = deadlines ?? const OrderDeadlines();

  static List<String> _actions(dynamic v) {
    if (v is! List) return const [];
    return v
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  factory OrderLifecycle.fromJson(Map<String, dynamic> json) {
    return OrderLifecycle(
      orderStatus: json['orderStatus']?.toString(),
      sellerStatus: json['sellerStatus']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      paymentState: json['paymentState']?.toString(),
      customerActions: _actions(json['customerActions']),
      ownerActions: _actions(json['ownerActions']),
      deadlines: json['deadlines'] is Map
          ? OrderDeadlines.fromJson(
              Map<String, dynamic>.from(json['deadlines']))
          : const OrderDeadlines(),
      lastEvent: json['lastEvent']?.toString(),
      lastEventAt: json['lastEventAt']?.toString(),
      banner: json['banner']?.toString(),
      reasonCode: json['reasonCode']?.toString(),
      refundDue: json['refundDue'] == true,
      suggestion: json['suggestion']?.toString(),
      refundOwedBy: json['refundOwedBy']?.toString(),
      refundInitiatedAt: json['refundInitiatedAt']?.toString(),
      refundReference: json['refundReference']?.toString(),
      refundAmount: _parseNum(json['refundAmount']),
      refundDueStated: json.containsKey('refundDue'),
      // `seenEvents` is the server's own dedupe ledger — never read, never
      // rendered.
    );
  }

  Map<String, dynamic> toJson() => {
        'orderStatus': orderStatus,
        'sellerStatus': sellerStatus,
        'paymentMethod': paymentMethod,
        'paymentState': paymentState,
        'customerActions': customerActions,
        'ownerActions': ownerActions,
        'deadlines': deadlines.toJson(),
        'lastEvent': lastEvent,
        'lastEventAt': lastEventAt,
        'banner': banner,
        'reasonCode': reasonCode,
        'refundDue': refundDue,
        'suggestion': suggestion,
        'refundOwedBy': refundOwedBy,
        'refundInitiatedAt': refundInitiatedAt,
        'refundReference': refundReference,
        'refundAmount': refundAmount,
      };

  /// Actions for the viewer. `isOwner` is the *shop* side of the card.
  ///
  /// The role split exists only on Plane A, where one stored card serves both
  /// readers. Plane B's `availableActions` is already caller-scoped.
  List<String> actionsFor({required bool isOwner}) =>
      isOwner ? ownerActions : customerActions;

  bool get isTerminal => OrderStatusValue.isTerminal(orderStatus);
  bool get isCancelledOrExpired =>
      orderStatus == OrderStatusValue.cancelled ||
      orderStatus == OrderStatusValue.expired;
  bool get isCompleted => orderStatus == OrderStatusValue.completed;
  bool get isReady => orderStatus == OrderStatusValue.ready;

  bool get isUpi => paymentMethod == 'upi';
  bool get isCash => paymentMethod == 'cash';

  /// `PRODUCT_ORDER_REMINDER` is **not** a state change — update the banner,
  /// don't re-animate the card, don't move it in the list (guide §9.1).
  bool get isReminderEvent => (lastEvent ?? '').endsWith('_REMINDER');

  /// `..._NEEDS_ATTENTION` → neutral info strip. The internal reason code is
  /// never shown to either party (guide §9.3).
  bool get needsAttention => (lastEvent ?? '').endsWith('_NEEDS_ATTENTION');

  /// A packed doorstep order that found no rider. Not a cancellation, and it
  /// must not look like one (guide §7.6).
  bool get isNoRider =>
      suggestion == 'SELF_PICKUP_FALLBACK' ||
      (lastEvent ?? '').endsWith('_NO_RIDER');

  /// The shop has been sitting on a ready order past the decision point, so
  /// its card changes **shape**, not just text (guide §9.2).
  bool get needsPickupDecision =>
      (lastEvent ?? '').contains('PICKUP_OWNER_ACTION');

  /// This lifecycle laid over [base], field by field, as a **new** instance.
  ///
  /// The case that matters is `/actions`, which the service documents as
  /// carrying no `lifecycle` and **no `banner`** — only the flat status fields.
  /// Replacing wholesale on a refresh therefore blanked the card's status line
  /// and it fell back to the neutral "Order update" placeholder. A field the
  /// newer payload did not mention keeps the value we already had.
  ///
  /// Action lists are the deliberate exception: they **replace**, never merge,
  /// because every payload that carries them carries the complete set, and a
  /// merge would leave a button the server had just withdrawn.
  OrderLifecycle mergedOver(OrderLifecycle base) {
    return OrderLifecycle(
      orderStatus: orderStatus ?? base.orderStatus,
      sellerStatus: sellerStatus ?? base.sellerStatus,
      paymentMethod: paymentMethod ?? base.paymentMethod,
      paymentState: paymentState ?? base.paymentState,
      customerActions:
          customerActions.isNotEmpty ? customerActions : base.customerActions,
      ownerActions: ownerActions.isNotEmpty ? ownerActions : base.ownerActions,
      deadlines: deadlines.isEmpty ? base.deadlines : deadlines,
      lastEvent: lastEvent ?? base.lastEvent,
      lastEventAt: lastEventAt ?? base.lastEventAt,
      banner: banner ?? base.banner,
      reasonCode: reasonCode ?? base.reasonCode,
      refundDue: refundDueStated ? refundDue : base.refundDue,
      refundDueStated: refundDueStated || base.refundDueStated,
      suggestion: suggestion ?? base.suggestion,
      refundOwedBy: refundOwedBy ?? base.refundOwedBy,
      refundInitiatedAt: refundInitiatedAt ?? base.refundInitiatedAt,
      refundReference: refundReference ?? base.refundReference,
      refundAmount: refundAmount ?? base.refundAmount,
    );
  }

  /// Copy the server's fields onto this instance, in place. Used by the socket
  /// patch so an existing card object updates without being rebuilt.
  ///
  /// Action lists **replace**, never merge — a socket payload always carries
  /// the complete list, and merging would leave a button the server withdrew.
  void applyFrom(OrderLifecycle other) {
    orderStatus = other.orderStatus ?? orderStatus;
    sellerStatus = other.sellerStatus ?? sellerStatus;
    paymentMethod = other.paymentMethod ?? paymentMethod;
    paymentState = other.paymentState ?? paymentState;
    customerActions = other.customerActions;
    ownerActions = other.ownerActions;
    if (!other.deadlines.isEmpty) deadlines = other.deadlines;
    lastEvent = other.lastEvent ?? lastEvent;
    lastEventAt = other.lastEventAt ?? lastEventAt;
    banner = other.banner ?? banner;
    reasonCode = other.reasonCode ?? reasonCode;
    // A socket payload always carries the whole block, so its `refundDue` is
    // authoritative — but a payload that never mentioned the key must not
    // clear a refund we already know about.
    if (other.refundDueStated) refundDue = other.refundDue;
    suggestion = other.suggestion ?? suggestion;
    refundOwedBy = other.refundOwedBy ?? refundOwedBy;
    refundInitiatedAt = other.refundInitiatedAt ?? refundInitiatedAt;
    refundReference = other.refundReference ?? refundReference;
    refundAmount = other.refundAmount ?? refundAmount;
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Planes B and C — `/actions` and every action response
// ─────────────────────────────────────────────────────────────────────────

/// The authoritative answer from `GET /api/orders/:orderId/actions` **and**
/// the envelope every action response uses (so a caller applies fresh state
/// without a second round-trip).
///
/// Three envelope shapes are handled by the one parser:
///
///  * `{ success, data: {...}, warning? }` — `/actions` and most verbs.
///    **`warning` is a sibling of `data`**, which is why it is read before the
///    unwrap (guide §0 cause 5).
///  * a **bare order** with `availableActions` and no wrapper — `PUT /ready`.
///  * `{ success, data: { orderId, orderNumber, pickupCode } }` — `/pickup-code`.
class OrderActionsModel {
  final String orderId;
  final String? orderNumber;

  /// `customer` | `owner` | `admin`, straight off `/actions`. **This is the
  /// role**, and the only correct answer to "whose buttons do I draw".
  final String? actor;

  /// Caller-scoped on Plane B/C. Rendered directly.
  final List<String> availableActions;

  final OrderLifecycle lifecycle;
  final OrderDeadlines deadlines;

  /// From `data.payment.*`. Null on `/actions`, which carries no money.
  final OrderPaymentSummary? paymentSummary;

  final OrderCancellationInfo? cancellation;
  final List<OrderCancellationReason> cancellationReasons;

  /// `self-pickup` | `rider`. Drives whether the card auto-dispatches at
  /// `ready` (§7.2).
  final String? deliveryType;

  /// The address the order already carries. Dispatch reuses it.
  final OrderDeliveryInfo? delivery;

  /// The rider order this product order is already attached to, if any. An
  /// empty value at `ready` on a doorstep order is the auto-dispatch trigger.
  final String? rideOrderId;

  final num? grandTotal;
  final int? totalItems;

  /// An admin is already looking at this order. Neutral strip on **both**
  /// cards; the reason code is never exposed (guide §9.3).
  final bool needsAttention;

  final bool? isTerminalFlag;

  /// Present on a success-with-caveat (e.g. the amount entered is lower than
  /// the total). Amber note, **not** an error.
  final String? warning;

  final String? pickupCode;

  const OrderActionsModel({
    required this.orderId,
    this.orderNumber,
    this.actor,
    required this.availableActions,
    required this.lifecycle,
    required this.deadlines,
    this.paymentSummary,
    this.cancellation,
    this.cancellationReasons = const [],
    this.deliveryType,
    this.delivery,
    this.rideOrderId,
    this.grandTotal,
    this.totalItems,
    this.needsAttention = false,
    this.isTerminalFlag,
    this.warning,
    this.pickupCode,
  });

  factory OrderActionsModel.fromJson(Map<String, dynamic> raw,
      {String? fallbackOrderId}) {
    // ⚠ `warning` is a SIBLING of `data`, not inside it. Read it first — this
    // is why the amount-mismatch note never used to appear.
    final rootWarning = raw['warning']?.toString();

    Map<String, dynamic> json = raw;
    if (json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data']);
    }

    // Plane A nests `lifecycle`; Planes B and C put the same fields flat, and
    // `PUT /ready` answers a bare order with no wrapper at all.
    final lifecycleJson = json['lifecycle'] is Map
        ? Map<String, dynamic>.from(json['lifecycle'])
        : json;
    final lifecycle = OrderLifecycle.fromJson(lifecycleJson);

    final deadlines = json['deadlines'] is Map
        ? OrderDeadlines.fromJson(Map<String, dynamic>.from(json['deadlines']))
        : lifecycle.deadlines;

    // ── The role ────────────────────────────────────────────────────────
    //
    // `/actions` and the action responses call it `actor`; **`/track` calls the
    // same thing `viewerRole`** and will keep doing so — the admin panel reads
    // that key — so both are accepted. Without this a model built from a track
    // response has a null role and everything downstream falls back to the
    // card's own `myMessage` guess.
    final actor = json['actor']?.toString() ??
        json['viewerRole']?.toString() ??
        // Tolerated legacy spellings; no service sends these today.
        (json['role']?.toString() == 'business'
            ? OrderActor.owner
            : json['role']?.toString()) ??
        (json['isOwner'] is bool
            ? (json['isOwner'] == true ? OrderActor.owner : OrderActor.customer)
            : null);

    final bool? owner = actor == null
        ? null
        : (actor == OrderActor.owner || actor == 'business');

    // `availableActions` is already caller-scoped. Only when it is absent
    // entirely (a card seeded from Plane A) does the role split answer.
    List<String> actions = OrderLifecycle._actions(json['availableActions']);
    if (actions.isEmpty && owner != null) {
      actions = owner ? lifecycle.ownerActions : lifecycle.customerActions;
    }

    // ── Money: `data.payment.*`, with the legacy key tolerated ───────────
    OrderPaymentSummary? payment;
    if (json['payment'] is Map) {
      payment = OrderPaymentSummary.fromJson(
          Map<String, dynamic>.from(json['payment']));
    } else if (json['paymentSummary'] is Map) {
      payment = OrderPaymentSummary.fromJson(
          Map<String, dynamic>.from(json['paymentSummary']));
    }
    if (payment != null && payment.isEmpty) payment = null;

    final reasonsRaw = json['cancellationReasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw
            .map(OrderCancellationReason.fromJson)
            .where((r) => r.code.isNotEmpty)
            .toList(growable: false)
        : const <OrderCancellationReason>[];

    // `needsAttention` has three shapes, and only reading two of them left the
    // strip permanently invisible on a track refresh:
    //
    //   /actions          → a bare bool
    //   action responses  → { flagged: true, reason, flaggedAt, note }
    //   /track            → { reason, flaggedAt }   ← NO `flagged` key,
    //                       and `null` when it is not flagged
    //
    // So on `/track` **the presence of the object is the flag**.
    bool attention = json['needsAttention'] == true;
    if (json['needsAttention'] is Map) {
      final m = Map<String, dynamic>.from(json['needsAttention']);
      attention = m['flagged'] == true ||
          (m['flagged'] == null && m.isNotEmpty);
    }
    // NOTE: `needsAttention.reason` is deliberately never parsed onto the
    // model. `/track` sends it to every party including the customer, but the
    // values are an internal ops taxonomy — PAYMENT_REVIEW, CUSTOMER_NO_SHOW,
    // DISPUTED, RIDER_LATE — and half of them accuse somebody. The card shows
    // one neutral strip and nothing else (guide §9.3).

    final deliveryJson = json['delivery'] is Map
        ? Map<String, dynamic>.from(json['delivery'])
        : null;

    return OrderActionsModel(
      orderId:
          (json['orderId'] ?? json['_id'] ?? fallbackOrderId ?? '').toString(),
      orderNumber: json['orderNumber']?.toString(),
      actor: actor,
      availableActions: actions,
      lifecycle: lifecycle,
      deadlines: deadlines,
      paymentSummary: payment,
      cancellation: json['cancellation'] is Map
          ? OrderCancellationInfo.fromJson(
              Map<String, dynamic>.from(json['cancellation']))
          : null,
      cancellationReasons: reasons,
      deliveryType: json['deliveryType']?.toString(),
      delivery: deliveryJson == null
          ? null
          : OrderDeliveryInfo.fromJson(deliveryJson),
      rideOrderId: (json['rideOrderId'] ??
              json['ride_order_id'] ??
              deliveryJson?['rideOrderId'])
          ?.toString(),
      grandTotal: _parseNum(json['grandTotal']),
      totalItems: _parseInt(json['totalItems']),
      needsAttention: attention,
      isTerminalFlag: json['isTerminal'] is bool ? json['isTerminal'] : null,
      warning: rootWarning ?? json['warning']?.toString(),
      pickupCode: (json['pickupCode'] ?? json['pickup_code'])?.toString(),
    );
  }

  bool get isOwner => actor == OrderActor.owner;
  bool get isAdmin => actor == OrderActor.admin;

  /// Null when the server did not say — the card then falls back to its own
  /// `myMessage` heuristic, which is a guess and should be temporary.
  bool? get isOwnerOrNull => actor == null ? null : (actor == OrderActor.owner);

  bool get isTerminal => isTerminalFlag ?? lifecycle.isTerminal;

  bool get isRiderOrder => deliveryType == OrderDeliveryTypeValue.rider;

  /// A doorstep order that is packed and has no rider attached yet. This is
  /// the auto-dispatch trigger — no button, no second decision (guide §7.2).
  bool get needsRiderDispatch =>
      isRiderOrder &&
      lifecycle.isReady &&
      (rideOrderId == null || rideOrderId!.isEmpty);

  /// The role-scoped list to render. Falls back to the lifecycle's own split
  /// lists when the server answered with only those (a Plane A seed).
  List<String> actionsFor({required bool isOwner}) {
    if (availableActions.isNotEmpty) return availableActions;
    return lifecycle.actionsFor(isOwner: isOwner);
  }

  /// A copy carrying [fresh]'s server truth over this one's cached extras.
  ///
  /// Two responses do **not** describe the order's state at all — the bare
  /// `{ pickupCode }` and a `{ success: true }` acknowledgement — and merging
  /// their empty lifecycle over a live card would blank its banner, its status
  /// and its buttons. So the state fields are only taken from a payload that
  /// actually carries a status.
  OrderActionsModel mergedWith(OrderActionsModel fresh) {
    final describesState = fresh.lifecycle.orderStatus != null;
    // `/track` is authoritative about the buttons even in the shape where it
    // leads with the role and the action list rather than the status, so a
    // non-empty list is always taken. An EMPTY list is only honoured from a
    // payload that described the state — "no actions available" is a real
    // answer, but a bare acknowledgement must not strip the card.
    final takesActions = describesState || fresh.availableActions.isNotEmpty;
    final base = paymentSummary;
    final incoming = fresh.paymentSummary;
    return OrderActionsModel(
      orderId: fresh.orderId.isNotEmpty ? fresh.orderId : orderId,
      orderNumber: fresh.orderNumber ?? orderNumber,
      actor: fresh.actor ?? actor,
      availableActions:
          takesActions ? fresh.availableActions : availableActions,
      // Field-wise, not wholesale: `/actions` describes the state but carries
      // no banner, and a bare acknowledgement describes nothing at all.
      lifecycle:
          describesState ? fresh.lifecycle.mergedOver(lifecycle) : lifecycle,
      deadlines: fresh.deadlines.isEmpty ? deadlines : fresh.deadlines,
      paymentSummary: incoming == null
          ? base
          : (base == null ? incoming : incoming.mergedOver(base)),
      cancellation: fresh.cancellation ?? cancellation,
      cancellationReasons: fresh.cancellationReasons.isNotEmpty
          ? fresh.cancellationReasons
          : cancellationReasons,
      deliveryType: fresh.deliveryType ?? deliveryType,
      delivery: fresh.delivery ?? delivery,
      rideOrderId: (fresh.rideOrderId?.isNotEmpty == true)
          ? fresh.rideOrderId
          : rideOrderId,
      grandTotal: fresh.grandTotal ?? grandTotal,
      totalItems: fresh.totalItems ?? totalItems,
      needsAttention: takesActions ? fresh.needsAttention : needsAttention,
      isTerminalFlag: fresh.isTerminalFlag ?? isTerminalFlag,
      warning: fresh.warning,
      pickupCode: fresh.pickupCode ?? pickupCode,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Delivery quote (rider leg)
// ─────────────────────────────────────────────────────────────────────────

/// `GET rider-service/fare/chat-dispatch/quote`.
///
/// An infeasible address answers **200 with `feasible:false`** — that is a UI
/// state, not an error (guide §5.3).
class DeliveryQuote {
  final bool feasible;

  /// `OUTSIDE_DELIVERY_RADIUS` etc. when [feasible] is false.
  final String? reason;
  final String? message;
  final double? maxDistanceKm;

  final double? distanceKm;
  final num? deliveryFee;
  final num? riderPayout;
  final bool peak;

  final int? etaMinutes;
  final int? etaMin;
  final int? etaMax;

  /// The fee breakdown, rendered behind a "How is this calculated?"
  /// disclosure. Kept raw — every key is a label/number pair.
  final Map<String, dynamic> breakdown;

  final num? orderValue;
  final bool feeExceedsOrderValue;
  final bool feeIsHighVsOrder;
  final double? feeToOrderRatio;
  final String? suggestion;

  const DeliveryQuote({
    required this.feasible,
    this.reason,
    this.message,
    this.maxDistanceKm,
    this.distanceKm,
    this.deliveryFee,
    this.riderPayout,
    this.peak = false,
    this.etaMinutes,
    this.etaMin,
    this.etaMax,
    this.breakdown = const {},
    this.orderValue,
    this.feeExceedsOrderValue = false,
    this.feeIsHighVsOrder = false,
    this.feeToOrderRatio,
    this.suggestion,
  });

  factory DeliveryQuote.fromJson(Map<String, dynamic> raw) {
    Map<String, dynamic> json = raw;
    if (json['data'] is Map && json['feasible'] == null) {
      json = Map<String, dynamic>.from(json['data']);
    }
    final eta = json['etaRange'] is Map
        ? Map<String, dynamic>.from(json['etaRange'])
        : const <String, dynamic>{};
    final eco = json['economics'] is Map
        ? Map<String, dynamic>.from(json['economics'])
        : const <String, dynamic>{};
    return DeliveryQuote(
      // Absent `feasible` means the server answered a plain quote — treat it
      // as feasible rather than silently disabling delivery.
      feasible: json['feasible'] != false,
      reason: json['reason']?.toString(),
      message: json['message']?.toString(),
      maxDistanceKm: _parseDouble(json['maxDistanceKm']),
      distanceKm: _parseDouble(json['distanceKm']),
      deliveryFee: _parseNum(json['deliveryFee'] ?? json['fare']),
      riderPayout: _parseNum(json['riderPayout']),
      peak: json['peak'] == true,
      etaMinutes: _parseInt(json['etaMinutes']),
      etaMin: _parseInt(eta['min']),
      etaMax: _parseInt(eta['max']),
      breakdown: json['breakdown'] is Map
          ? Map<String, dynamic>.from(json['breakdown'])
          : const {},
      orderValue: _parseNum(eco['orderValue']),
      feeExceedsOrderValue: eco['feeExceedsOrderValue'] == true,
      feeIsHighVsOrder: eco['feeIsHighVsOrder'] == true,
      feeToOrderRatio: _parseDouble(eco['feeToOrderRatio']),
      suggestion: eco['suggestion']?.toString(),
    );
  }

  /// Amber-note trigger. Never blocks the order — a customer who wants their
  /// ₹10 item delivered may pay ₹84 for it; they just must not be surprised.
  bool get shouldWarnAboutFee => feeExceedsOrderValue || feeIsHighVsOrder;

  String get etaLabel {
    if (etaMin != null && etaMax != null) return '$etaMin–$etaMax min';
    if (etaMinutes != null) return '$etaMinutes min';
    return '';
  }

  /// Human-readable rows for the "How is this calculated?" disclosure.
  List<MapEntry<String, String>> get breakdownRows {
    const labels = <String, String>{
      'baseFee': 'Base fee',
      'baseKm': 'Included distance',
      'chargeableKm': 'Extra distance',
      'perKmFee': 'Per km',
      'peakMultiplier': 'Peak multiplier',
      'minimumFeeApplied': 'Minimum fee applied',
      'maximumFeeApplied': 'Maximum fee applied',
    };
    final rows = <MapEntry<String, String>>[];
    labels.forEach((key, label) {
      final v = breakdown[key];
      if (v == null) return;
      if (v is bool) {
        if (v) rows.add(MapEntry(label, 'Yes'));
        return;
      }
      if (key.endsWith('Km')) {
        rows.add(MapEntry(label, '$v km'));
      } else if (key == 'peakMultiplier') {
        if (_parseDouble(v) != 1) rows.add(MapEntry(label, '×$v'));
      } else {
        rows.add(MapEntry(label, '₹$v'));
      }
    });
    return rows;
  }
}
