/// Models for the server-driven order lifecycle.
///
/// **The one rule:** the backend computes the state machine and emits
/// `availableActions[]`; Flutter renders that list and sends the action back.
/// Nothing in this file derives a button, a deadline or a status string from
/// the client clock. See `lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md` §0.
///
/// Two sources feed the same shape:
///   • `metadata.lifecycle` on a chat card  → [OrderLifecycle.fromJson]
///   • `GET /api/orders/:id/actions`        → [OrderActionsModel.fromJson]
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

  // Both
  static const cancelOrder = 'CANCEL_ORDER';
}

/// `lifecycle.orderStatus` values. Compared only for cosmetics (badge colour,
/// collapsed summary) — never to gate an action.
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

/// Typed error codes the order endpoints answer with. Branch on these, never
/// on `message` text. See the guide §6.
class OrderErrorCode {
  static const actionNotAvailable = 'ACTION_NOT_AVAILABLE';
  static const concurrentModification = 'CONCURRENT_MODIFICATION';
  static const paymentConflict = 'PAYMENT_CONFLICT';
  static const orderTerminal = 'ORDER_TERMINAL';
  static const notAPartyToOrder = 'NOT_A_PARTY_TO_ORDER';
  static const useLifecycleEndpoint = 'USE_LIFECYCLE_ENDPOINT';
  static const useHandoverEndpoint = 'USE_HANDOVER_ENDPOINT';
  static const utrAlreadyUsed = 'UTR_ALREADY_USED';
  static const tooManyPaymentAttempts = 'TOO_MANY_PAYMENT_ATTEMPTS';
  static const utrRequired = 'UTR_REQUIRED';
  static const screenshotRequired = 'SCREENSHOT_REQUIRED';
  static const invalidAmount = 'INVALID_AMOUNT';
  static const pickupCodeMismatch = 'PICKUP_CODE_MISMATCH';
  static const cashNotCollected = 'CASH_NOT_COLLECTED';
  static const refundReferenceRequired = 'REFUND_REFERENCE_REQUIRED';
  static const invalidReason = 'INVALID_REASON';
  static const fareMismatch = 'FARE_MISMATCH';
  static const outsideDeliveryRadius = 'OUTSIDE_DELIVERY_RADIUS';
  /// Synthesised client-side when the request never reached the server
  /// (timeout, DNS, airplane mode). Retrying is always safe.
  static const network = 'NETWORK_ERROR';
}

// ─────────────────────────────────────────────────────────────────────────
//  Deadlines
// ─────────────────────────────────────────────────────────────────────────

/// Server-authored deadlines. **Every countdown in the UI is driven from
/// here** — never from `createdAt + constant`. A null field means "no clock
/// running for this step", which is not the same as "expired".
class OrderDeadlines {
  final DateTime? acceptBy;
  final DateTime? payBy;
  final DateTime? readyBy;
  final DateTime? pickupBy;
  final DateTime? hardExpiryAt;

  const OrderDeadlines({
    this.acceptBy,
    this.payBy,
    this.readyBy,
    this.pickupBy,
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
      hardExpiryAt: _dt(json['hardExpiryAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'acceptBy': acceptBy?.toUtc().toIso8601String(),
        'payBy': payBy?.toUtc().toIso8601String(),
        'readyBy': readyBy?.toUtc().toIso8601String(),
        'pickupBy': pickupBy?.toUtc().toIso8601String(),
        'hardExpiryAt': hardExpiryAt?.toUtc().toIso8601String(),
      };

  bool get isEmpty =>
      acceptBy == null &&
      payBy == null &&
      readyBy == null &&
      pickupBy == null &&
      hardExpiryAt == null;
}

// ─────────────────────────────────────────────────────────────────────────
//  Payment summary
// ─────────────────────────────────────────────────────────────────────────

/// What the owner's verification card and the payment sheet need to show the
/// amounts side by side. `amountDue` is what the sheet pre-fills.
class OrderPaymentSummary {
  final num? amountDue;
  final num? amountPaid;
  final String? utrNo;
  final String? screenshotUrl;
  final String? upiId;
  final String? paymentQrId;
  final String? method;
  final String? state;
  final String? submittedAt;
  final String? rejectedReason;
  final String? refundReference;
  final String? refundInitiatedAt;
  final String? refundOwedBy;

  const OrderPaymentSummary({
    this.amountDue,
    this.amountPaid,
    this.utrNo,
    this.screenshotUrl,
    this.upiId,
    this.paymentQrId,
    this.method,
    this.state,
    this.submittedAt,
    this.rejectedReason,
    this.refundReference,
    this.refundInitiatedAt,
    this.refundOwedBy,
  });

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  factory OrderPaymentSummary.fromJson(Map<String, dynamic> json) {
    return OrderPaymentSummary(
      amountDue: _num(json['amountDue'] ?? json['amount_due'] ?? json['due']),
      amountPaid:
          _num(json['amountPaid'] ?? json['amount_paid'] ?? json['paid']),
      utrNo: (json['utrNo'] ?? json['utr_no'] ?? json['utr'])?.toString(),
      screenshotUrl:
          (json['screenshotUrl'] ?? json['screenshot_url'])?.toString(),
      upiId: (json['upiId'] ?? json['upi_id'])?.toString(),
      paymentQrId:
          (json['paymentQrId'] ?? json['payment_qr_id'])?.toString(),
      method: (json['method'] ?? json['paymentMethod'])?.toString(),
      state: (json['state'] ?? json['paymentState'] ?? json['status'])
          ?.toString(),
      submittedAt: json['submittedAt']?.toString(),
      rejectedReason:
          (json['rejectedReason'] ?? json['rejectionReason'] ?? json['reason'])
              ?.toString(),
      refundReference:
          (json['refundReference'] ?? json['refund_reference'])?.toString(),
      refundInitiatedAt: json['refundInitiatedAt']?.toString(),
      refundOwedBy: json['refundOwedBy']?.toString(),
    );
  }

  /// True when the customer typed an amount that differs from the order total.
  /// Drives the amber highlight on the owner's verification card — the whole
  /// point is that the comparison is effortless before they tap.
  bool get hasMismatch {
    final due = amountDue;
    final paid = amountPaid;
    if (due == null || paid == null) return false;
    return (due - paid).abs() > 0.009;
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Cancellation
// ─────────────────────────────────────────────────────────────────────────

/// One role-scoped cancellation reason offered by `/actions`. **Never
/// hard-code this list** — a customer must not be able to pick
/// `ITEM_UNAVAILABLE`, and the server rejects it with `INVALID_REASON` anyway.
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
    final code = (json['code'] ?? json['reasonCode'] ?? json['value'] ?? '')
        .toString();
    final label = (json['label'] ?? json['text'] ?? json['title'] ?? '')
        .toString();
    return OrderCancellationReason(
      code: code,
      label: label.isNotEmpty ? label : _humanise(code),
      requiresComment:
          json['requiresComment'] == true || json['commentRequired'] == true,
    );
  }

  /// `ITEM_UNAVAILABLE` → `Item unavailable`. Only a fallback for when the
  /// server sends bare codes.
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
//  Lifecycle
// ─────────────────────────────────────────────────────────────────────────

/// The `metadata.lifecycle` block carried on every order chat card, and the
/// same block returned by `/actions`.
///
/// [banner] is server-authored and already localised in tone — render it
/// **verbatim** as the card's status line. Building a string from
/// [orderStatus] is exactly how the app and the server drifted apart before.
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

  /// `"shop"` today, always. The platform never held the money — with direct
  /// UPI the customer paid the shop's own VPA — so the copy must say the shop
  /// returns it, never "we will refund you". Guide §3.6.1.
  String? refundOwedBy;

  /// Set once the owner claims they sent the refund. Their claim does **not**
  /// close the refund; only `CONFIRM_REFUND_RECEIVED` does.
  String? refundInitiatedAt;
  String? refundReference;

  num? refundAmount;

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
    this.refundOwedBy,
    this.refundInitiatedAt,
    this.refundReference,
    this.refundAmount,
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
      refundOwedBy: json['refundOwedBy']?.toString(),
      refundInitiatedAt: json['refundInitiatedAt']?.toString(),
      refundReference: json['refundReference']?.toString(),
      refundAmount: OrderPaymentSummary._num(json['refundAmount']),
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
        'refundOwedBy': refundOwedBy,
        'refundInitiatedAt': refundInitiatedAt,
        'refundReference': refundReference,
        'refundAmount': refundAmount,
      };

  /// Actions for the viewer. `isOwner` is the *shop* side of the card.
  List<String> actionsFor({required bool isOwner}) =>
      isOwner ? ownerActions : customerActions;

  bool get isTerminal => OrderStatusValue.isTerminal(orderStatus);
  bool get isCancelledOrExpired =>
      orderStatus == OrderStatusValue.cancelled ||
      orderStatus == OrderStatusValue.expired;
  bool get isCompleted => orderStatus == OrderStatusValue.completed;

  bool get isUpi => paymentMethod == 'upi';
  bool get isCash => paymentMethod == 'cash';

  /// `PRODUCT_ORDER_REMINDER` is **not** a state change — update the banner,
  /// don't re-animate the card. Guide §3.7.
  bool get isReminderEvent => (lastEvent ?? '').endsWith('_REMINDER');

  /// `..._NEEDS_ATTENTION` → neutral info strip. The internal reason code is
  /// never shown to either party.
  bool get needsAttention => (lastEvent ?? '').endsWith('_NEEDS_ATTENTION');

  /// Copy the server's fields onto this instance, in place. Used by the socket
  /// patch so an existing card object updates without being rebuilt.
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
    refundDue = other.refundDue;
    refundOwedBy = other.refundOwedBy ?? refundOwedBy;
    refundInitiatedAt = other.refundInitiatedAt ?? refundInitiatedAt;
    refundReference = other.refundReference ?? refundReference;
    refundAmount = other.refundAmount ?? refundAmount;
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  /actions response
// ─────────────────────────────────────────────────────────────────────────

/// The authoritative answer from `GET /api/orders/:orderId/actions`, and the
/// same envelope every successful action call returns (so the caller can apply
/// the fresh state without a second round-trip).
///
/// The server scopes `availableActions` to the caller's role, so the model
/// keeps both that flat list and the role-split lists from `lifecycle` — the
/// action bar prefers the flat list when present.
class OrderActionsModel {
  final String orderId;
  final List<String> availableActions;
  final OrderLifecycle lifecycle;
  final OrderDeadlines deadlines;
  final OrderPaymentSummary? paymentSummary;
  final OrderCancellationInfo? cancellation;
  final List<OrderCancellationReason> cancellationReasons;

  /// Present on a payment submit that succeeded with a caveat (e.g. the amount
  /// entered is lower than the total). Amber note, **not** an error.
  final String? warning;

  /// `true` when the viewer is the shop for this order, as reported by the
  /// server. Null when the server didn't say — the card falls back to its own
  /// `myMessage` heuristic.
  final bool? isOwner;

  final String? pickupCode;

  const OrderActionsModel({
    required this.orderId,
    required this.availableActions,
    required this.lifecycle,
    required this.deadlines,
    this.paymentSummary,
    this.cancellation,
    this.cancellationReasons = const [],
    this.warning,
    this.isOwner,
    this.pickupCode,
  });

  /// Unwraps `{ data: {...} }` / `{ order: {...} }` envelopes and reads the
  /// lifecycle whether it arrives nested under `lifecycle` or flattened at the
  /// top level.
  factory OrderActionsModel.fromJson(Map<String, dynamic> raw,
      {String? fallbackOrderId}) {
    Map<String, dynamic> json = raw;
    if (json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data']);
    }

    final lifecycleJson = json['lifecycle'] is Map
        ? Map<String, dynamic>.from(json['lifecycle'])
        : json;
    final lifecycle = OrderLifecycle.fromJson(lifecycleJson);

    final deadlines = json['deadlines'] is Map
        ? OrderDeadlines.fromJson(Map<String, dynamic>.from(json['deadlines']))
        : lifecycle.deadlines;

    // Prefer the flat, role-scoped list; fall back to whichever role list the
    // lifecycle block carries a value for.
    List<String> actions = OrderLifecycle._actions(json['availableActions']);
    final bool? owner = json['isOwner'] is bool
        ? json['isOwner'] as bool
        : (json['role']?.toString() == 'business' ||
                json['role']?.toString() == 'owner')
            ? true
            : (json['role']?.toString() == 'customer' ? false : null);
    if (actions.isEmpty) {
      if (owner == true) {
        actions = lifecycle.ownerActions;
      } else if (owner == false) {
        actions = lifecycle.customerActions;
      }
    }

    final reasonsRaw = json['cancellationReasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw
            .map(OrderCancellationReason.fromJson)
            .where((r) => r.code.isNotEmpty)
            .toList(growable: false)
        : const <OrderCancellationReason>[];

    return OrderActionsModel(
      orderId: (json['orderId'] ?? json['_id'] ?? fallbackOrderId ?? '')
          .toString(),
      availableActions: actions,
      lifecycle: lifecycle,
      deadlines: deadlines,
      paymentSummary: json['paymentSummary'] is Map
          ? OrderPaymentSummary.fromJson(
              Map<String, dynamic>.from(json['paymentSummary']))
          : null,
      cancellation: json['cancellation'] is Map
          ? OrderCancellationInfo.fromJson(
              Map<String, dynamic>.from(json['cancellation']))
          : null,
      cancellationReasons: reasons,
      warning: json['warning']?.toString(),
      isOwner: owner,
      pickupCode: (json['pickupCode'] ?? json['pickup_code'])?.toString(),
    );
  }

  /// The role-scoped list to render. Falls back to the lifecycle's own split
  /// lists when the server answered with only those.
  List<String> actionsFor({required bool isOwner}) {
    if (availableActions.isNotEmpty) return availableActions;
    return lifecycle.actionsFor(isOwner: isOwner);
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Delivery quote (rider leg)
// ─────────────────────────────────────────────────────────────────────────

/// `GET /fare/chat-dispatch/quote`. An infeasible address answers **200 with
/// `feasible:false`** — that is a UI state, not an error.
class DeliveryQuote {
  final bool feasible;
  final double? distanceKm;
  final num? deliveryFee;
  final int? etaMinutes;
  final int? etaMin;
  final int? etaMax;
  final String? message;
  final bool feeExceedsOrderValue;
  final bool feeIsHighVsOrder;
  final double? feeToOrderRatio;
  final String? suggestion;

  const DeliveryQuote({
    required this.feasible,
    this.distanceKm,
    this.deliveryFee,
    this.etaMinutes,
    this.etaMin,
    this.etaMax,
    this.message,
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
    int? asInt(dynamic v) =>
        v == null ? null : int.tryParse(v.toString().split('.').first);
    return DeliveryQuote(
      // Absent `feasible` means the server answered a plain quote — treat it
      // as feasible rather than silently disabling delivery.
      feasible: json['feasible'] != false,
      distanceKm: double.tryParse(json['distanceKm']?.toString() ?? ''),
      deliveryFee: OrderPaymentSummary._num(json['deliveryFee'] ?? json['fare']),
      etaMinutes: asInt(json['etaMinutes']),
      etaMin: asInt(eta['min']),
      etaMax: asInt(eta['max']),
      message: json['message']?.toString(),
      feeExceedsOrderValue: eco['feeExceedsOrderValue'] == true,
      feeIsHighVsOrder: eco['feeIsHighVsOrder'] == true,
      feeToOrderRatio:
          double.tryParse(eco['feeToOrderRatio']?.toString() ?? ''),
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
}
