/// `GET <service>/api/orders/:orderId/track` — the **order steps** payload.
///
/// This is the one order surface that works for every ported vertical today,
/// grocery included, which is why the steps screen is built entirely on it
/// (`ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §7).
///
/// Everything here is defensive on purpose. `/track` is served by five
/// different services at five different stages of the lifecycle rollout, so a
/// key is absent as often as it is null, `stages[]` may be empty, `orderStatus`
/// and `currentStage` may disagree (§6.3 S5), and a stage may carry a `key`
/// this build has never heard of (S2). None of those are errors — they are the
/// documented contract, and the parser preserves them rather than normalising
/// them away.
library;

import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

bool? _boolOrNull(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return null;
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

/// One shop's square inside a multi-shop stage (§6.3 S7).
class OrderStageBusiness {
  final String? businessId;
  final String? name;

  /// `pending` | `ready` | anything the server invents next. Rendered as text,
  /// never switched on for layout.
  final String? status;

  final DateTime? at;

  const OrderStageBusiness({
    this.businessId,
    this.name,
    this.status,
    this.at,
  });

  factory OrderStageBusiness.fromJson(Map<String, dynamic> json) {
    final biz = _map(json['business']);
    return OrderStageBusiness(
      businessId: (json['businessId'] ??
              json['business_id'] ??
              json['_id'] ??
              biz?['_id'] ??
              biz?['id'])
          ?.toString(),
      name: (json['name'] ??
              json['businessName'] ??
              json['business_name'] ??
              biz?['name'] ??
              biz?['businessName'])
          ?.toString(),
      status: (json['status'] ?? json['state'])?.toString(),
      at: _dt(json['at'] ?? json['readyAt'] ?? json['updatedAt']),
    );
  }

  bool get isReady {
    final s = status?.toLowerCase();
    return s == 'ready' || s == 'completed' || s == 'handed_over';
  }
}

/// One node of the stepper. **Label is server copy** — rendered verbatim, and
/// the only reason an unknown `key` still draws correctly (§6.2, §6.3 S2).
class OrderStage {
  final String key;
  final String label;
  final bool done;
  final DateTime? at;
  final List<OrderStageBusiness> businesses;

  /// Rendered under the label when the server sends one. Optional everywhere.
  final String? note;

  const OrderStage({
    required this.key,
    required this.label,
    required this.done,
    this.at,
    this.businesses = const [],
    this.note,
  });

  factory OrderStage.fromJson(Map<String, dynamic> json) {
    final key = (json['key'] ?? json['stage'] ?? json['name'] ?? '').toString();
    final rawLabel = (json['label'] ?? json['title'] ?? '').toString().trim();
    return OrderStage(
      key: key,
      // A stage with no label at all is the only case where the key is shown,
      // and it is humanised first — `ready_for_pickup` → `Ready for pickup`.
      label: rawLabel.isNotEmpty ? rawLabel : humaniseStageKey(key),
      done: _boolOrNull(json['done'] ?? json['completed'] ?? json['isDone']) ??
          false,
      at: _dt(json['at'] ?? json['completedAt'] ?? json['timestamp']),
      businesses: _mapList(json['businesses'] ?? json['shops'])
          .map(OrderStageBusiness.fromJson)
          .toList(growable: false),
      note: (json['note'] ?? json['description'])?.toString(),
    );
  }

  /// `ready_for_pickup` / `ready-for-pickup` / `readyForPickup` → `Ready for
  /// pickup`. Used only when the server sent no label.
  static String humaniseStageKey(String key) {
    if (key.isEmpty) return 'Step';
    final spaced = key
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .toLowerCase();
    if (spaced.isEmpty) return 'Step';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// One side of `payment` — `payment.customer` drives the customer's row,
/// `payment.owner` the shop's (§6.4).
class OrderTrackPaymentSide {
  /// `false` on every grocery self-pickup order: money changes hands at the
  /// counter, so there is nothing to collect in the app and **no pay button**
  /// (P1).
  final bool applicable;

  /// Server copy — *"Paid at the store counter on pickup."* Printed verbatim.
  final String? note;

  final num? amount;
  final num? amountPaid;

  /// Deliberately nullable, and deliberately ignored for self-pickup: a cash
  /// order that was paid at the counter still reports `isPaid: false` (P7).
  final bool? isPaid;

  final String? paymentState;
  final String? paymentMethod;

  /// `"shop"` today, always. The copy must never say *we* will refund (P6).
  final String? refundOwedBy;

  final String? rejectionReason;

  const OrderTrackPaymentSide({
    this.applicable = false,
    this.note,
    this.amount,
    this.amountPaid,
    this.isPaid,
    this.paymentState,
    this.paymentMethod,
    this.refundOwedBy,
    this.rejectionReason,
  });

  factory OrderTrackPaymentSide.fromJson(Map<String, dynamic> json) {
    return OrderTrackPaymentSide(
      applicable: _boolOrNull(json['applicable'] ?? json['required']) ?? false,
      note: (json['note'] ?? json['message'])?.toString(),
      amount: _num(json['amount'] ?? json['amountDue'] ?? json['due']),
      amountPaid: _num(json['amountPaid'] ?? json['paid']),
      isPaid: _boolOrNull(json['isPaid'] ?? json['paid']),
      paymentState:
          (json['paymentState'] ?? json['state'] ?? json['status'])?.toString(),
      paymentMethod: (json['paymentMethod'] ?? json['method'])?.toString(),
      refundOwedBy: json['refundOwedBy']?.toString(),
      rejectionReason:
          (json['rejectionReason'] ?? json['reason'] ?? json['rejectReason'])
              ?.toString(),
    );
  }

  bool get isSubmitted =>
      paymentState == PaymentStateValue.submitted ||
      paymentState == PaymentStateValue.underReview;

  bool get isRejected => paymentState == PaymentStateValue.rejected;

  bool get isRefundPending => paymentState == PaymentStateValue.refundPending;

  bool get isRefunded => paymentState == PaymentStateValue.refunded;
}

/// The `payment` block. **Absent means hide the whole row** (P3) — which is
/// why this is only ever constructed when the key is actually there.
class OrderTrackPayment {
  final OrderTrackPaymentSide? customer;
  final OrderTrackPaymentSide? owner;

  const OrderTrackPayment({this.customer, this.owner});

  factory OrderTrackPayment.fromJson(Map<String, dynamic> json) {
    final customer = _map(json['customer']);
    final owner = _map(json['owner'] ?? json['business'] ?? json['seller']);
    // Some services send the customer block flat rather than nested.
    final flat = customer == null && owner == null && json.isNotEmpty;
    return OrderTrackPayment(
      customer: customer != null
          ? OrderTrackPaymentSide.fromJson(customer)
          : (flat ? OrderTrackPaymentSide.fromJson(json) : null),
      owner: owner != null ? OrderTrackPaymentSide.fromJson(owner) : null,
    );
  }
}

/// The rider leg, when there is one. Null on every self-pickup order, and a
/// null here means the whole rider block is hidden — no empty map, no
/// "waiting for rider" (§6.3 S10).
class OrderTrackRider {
  final String? riderId;
  final String? name;
  final String? phone;
  final String? photo;
  final String? vehicleNumber;
  final String? status;
  final String? rideOrderId;
  final String? otp;
  final double? latitude;
  final double? longitude;
  final num? etaMinutes;

  const OrderTrackRider({
    this.riderId,
    this.name,
    this.phone,
    this.photo,
    this.vehicleNumber,
    this.status,
    this.rideOrderId,
    this.otp,
    this.latitude,
    this.longitude,
    this.etaMinutes,
  });

  /// Built from whichever of `rider` / `riderLeg` / `rideOrder` the service
  /// sent. Returns null when none of them carries anything renderable — a
  /// `{}` or a block with no name and no id is *not* a rider.
  static OrderTrackRider? fromAny(
    Map<String, dynamic>? rider,
    Map<String, dynamic>? riderLeg,
    Map<String, dynamic>? rideOrder,
  ) {
    final merged = <String, dynamic>{
      ...?rideOrder,
      ...?riderLeg,
      ...?rider,
    };
    if (merged.isEmpty) return null;

    final nested = _map(merged['rider']) ?? const {};
    final loc = _map(merged['location']) ?? _map(nested['location']);
    final coords = loc?['coordinates'];
    double? lat, lng;
    if (coords is List && coords.length >= 2) {
      // GeoJSON: [lng, lat].
      lng = _num(coords[0])?.toDouble();
      lat = _num(coords[1])?.toDouble();
    } else {
      lat = _num(merged['latitude'] ?? nested['latitude'])?.toDouble();
      lng = _num(merged['longitude'] ?? nested['longitude'])?.toDouble();
    }

    final built = OrderTrackRider(
      riderId: (merged['riderId'] ?? nested['_id'] ?? nested['id'])?.toString(),
      name:
          (merged['name'] ?? merged['riderName'] ?? nested['name'])?.toString(),
      phone: (merged['phone'] ??
              merged['contact'] ??
              nested['phone'] ??
              nested['contact'])
          ?.toString(),
      photo: (merged['profile_image'] ??
              merged['profileImage'] ??
              nested['profile_image'] ??
              nested['profileImage'])
          ?.toString(),
      vehicleNumber:
          (merged['vehicleNumber'] ?? nested['vehicleNumber'])?.toString(),
      status: (merged['status'] ?? merged['rideStatus'])?.toString(),
      rideOrderId:
          (merged['rideOrderId'] ?? merged['_id'] ?? merged['id'])?.toString(),
      otp: (merged['otp'] ?? merged['pickupOtp'])?.toString(),
      latitude: lat,
      longitude: lng,
      etaMinutes: _num(merged['etaMinutes'] ?? merged['eta']),
    );

    final hasSomething = (built.name ?? '').isNotEmpty ||
        (built.riderId ?? '').isNotEmpty ||
        (built.phone ?? '').isNotEmpty ||
        (built.status ?? '').isNotEmpty;
    return hasSomething ? built : null;
  }

  bool get hasLocation => latitude != null && longitude != null;
}

/// One line of the order.
class OrderTrackItem {
  final String? name;
  final String? variantLabel;
  final String? imageUrl;
  final num quantity;
  final num? mrp;
  final num? sellingPrice;

  const OrderTrackItem({
    this.name,
    this.variantLabel,
    this.imageUrl,
    this.quantity = 1,
    this.mrp,
    this.sellingPrice,
  });

  /// Image resolution follows C15: variant images first, then the product's
  /// own, then nothing (the caller renders a placeholder tile — never an empty
  /// box).
  factory OrderTrackItem.fromJson(Map<String, dynamic> json) {
    final variant = _map(json['productVariant']) ?? _map(json['variant']);
    final product = _map(variant?['product']) ?? _map(json['product']);

    String? firstImage(dynamic images) {
      if (images is! List) return null;
      for (final img in images) {
        final url = img is Map ? (img['url'] ?? img['image']) : img;
        final s = url?.toString() ?? '';
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    final unit = (variant?['unit'] ?? variant?['size'] ?? variant?['weight'])
        ?.toString();
    final unitLabel =
        (variant?['unitLabel'] ?? variant?['packSize'])?.toString();

    return OrderTrackItem(
      name: (json['name'] ??
              product?['name'] ??
              variant?['name'] ??
              json['productName'])
          ?.toString(),
      variantLabel: (unitLabel?.isNotEmpty == true)
          ? unitLabel
          : (unit?.isNotEmpty == true ? unit : null),
      imageUrl: firstImage(variant?['images']) ??
          firstImage(product?['images']) ??
          firstImage(json['images']) ??
          (json['image'] ?? json['imageUrl'])?.toString(),
      quantity: _num(json['quantity'] ?? json['qty']) ?? 1,
      mrp: _num(json['mrp']),
      sellingPrice: _num(json['sellingPrice'] ?? json['price']),
    );
  }

  num? get lineTotal {
    final unit = sellingPrice ?? mrp;
    return unit == null ? null : unit * quantity;
  }

  bool get isDiscounted =>
      mrp != null && sellingPrice != null && mrp! > sellingPrice!;
}

/// The whole `/track` answer.
class OrderTrackModel {
  final String orderId;
  final String? orderNumber;

  /// Drives the **chip** (§6.1). It is allowed to disagree with
  /// [currentStage] — never assert they match (S5).
  final String? orderStatus;

  /// Drives the **stepper**'s current node when `stages[].done` alone is
  /// ambiguous. Wins over [orderStatus] for the stepper (S5).
  final String? currentStage;

  /// Never cached by the caller — re-read on every fetch (S6).
  final bool isTerminal;

  final List<OrderStage> stages;
  final OrderTrackPayment? payment;
  final OrderTrackRider? rider;
  final String? deliveryType;
  final num? grandTotal;
  final num? totalMRP;
  final num? discount;
  final List<OrderTrackItem> items;
  final DateTime? createdAt;
  final String? businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessId;
  final String? customerName;
  final String? customerPhone;
  final String? customerId;
  final String? pickupCode;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  /// Present only on the ported verticals. Null for grocery, today and for
  /// every order — which is the documented fallback, not an error (§1).
  final OrderLifecycle? lifecycle;

  /// `availableActions` when `/track` carries them. Empty is a valid state.
  final List<String> availableActions;

  /// `actor` when `/track` says who is asking. Null → the caller falls back to
  /// its own role guess.
  final String? actor;

  const OrderTrackModel({
    required this.orderId,
    this.orderNumber,
    this.orderStatus,
    this.currentStage,
    this.isTerminal = false,
    this.stages = const [],
    this.payment,
    this.rider,
    this.deliveryType,
    this.grandTotal,
    this.totalMRP,
    this.discount,
    this.items = const [],
    this.createdAt,
    this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessId,
    this.customerName,
    this.customerPhone,
    this.customerId,
    this.pickupCode,
    this.cancellationReason,
    this.cancelledAt,
    this.lifecycle,
    this.availableActions = const [],
    this.actor,
  });

  /// Accepts every envelope `/track` is served in: bare, `{data: …}`,
  /// `{order: …}`, and `{data: {order: …}}`.
  factory OrderTrackModel.fromJson(Map<String, dynamic> json,
      {String? fallbackOrderId}) {
    var root = json;
    final data = _map(root['data']);
    if (data != null) root = data;
    // Keep the outer body around: `stages` sometimes sits beside `order`
    // rather than inside it.
    final outer = root;
    final order = _map(root['order']) ?? const {};
    dynamic pick(String key) => outer[key] ?? order[key];

    final business = _map(pick('business')) ??
        _map(pick('shop')) ??
        _map(pick('receiverUser')) ??
        const {};
    final customer = _map(pick('customer')) ?? _map(pick('user')) ?? const {};

    final stagesRaw = _mapList(pick('stages') ?? pick('steps'));

    final paymentRaw = _map(pick('payment'));

    final rider = OrderTrackRider.fromAny(
      _map(pick('rider')),
      _map(pick('riderLeg')),
      _map(pick('rideOrder')),
    );

    final cancellation = _map(pick('cancellation'));

    return OrderTrackModel(
      orderId: (pick('orderId') ??
              pick('_id') ??
              pick('id') ??
              fallbackOrderId ??
              '')
          .toString(),
      orderNumber: (pick('orderNumber') ?? pick('order_number'))?.toString(),
      orderStatus: (pick('orderStatus') ?? pick('status'))?.toString(),
      currentStage:
          (pick('currentStage') ?? pick('current_stage') ?? pick('stage'))
              ?.toString(),
      isTerminal: _boolOrNull(pick('isTerminal')) ??
          OrderStatusValue.isTerminal(
              (pick('orderStatus') ?? pick('status'))?.toString()),
      stages: stagesRaw.map(OrderStage.fromJson).toList(growable: false),
      payment:
          paymentRaw == null ? null : OrderTrackPayment.fromJson(paymentRaw),
      rider: rider,
      deliveryType: pick('deliveryType')?.toString(),
      grandTotal: _num(pick('grandTotal') ?? pick('totalAmount')),
      totalMRP: _num(pick('totalMRP')),
      discount: _num(pick('discount')),
      items: _mapList(pick('items'))
          .map(OrderTrackItem.fromJson)
          .toList(growable: false),
      createdAt: _dt(pick('createdAt') ?? pick('placedAt')),
      businessName:
          (business['name'] ?? business['businessName'] ?? pick('businessName'))
              ?.toString(),
      businessAddress:
          (business['address'] ?? business['location'])?.toString(),
      businessPhone: (business['contact'] ?? business['phone'])?.toString(),
      businessId: (business['_id'] ??
              business['id'] ??
              business['businessId'] ??
              pick('businessId'))
          ?.toString(),
      customerName: (customer['name'] ?? customer['fullName'])?.toString(),
      customerPhone: (customer['contact'] ?? customer['phone'])?.toString(),
      customerId:
          (customer['_id'] ?? customer['id'] ?? pick('userId'))?.toString(),
      pickupCode: (pick('pickupCode') ?? pick('pickup_code'))?.toString(),
      cancellationReason: (cancellation?['reason'] ??
              cancellation?['reasonCode'] ??
              pick('cancellationReason'))
          ?.toString(),
      cancelledAt: _dt(cancellation?['at'] ?? pick('cancelledAt')),
      lifecycle: _map(pick('lifecycle')) == null
          ? null
          : OrderLifecycle.fromJson(_map(pick('lifecycle'))!),
      availableActions: (pick('availableActions') is List)
          ? (pick('availableActions') as List)
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList(growable: false)
          : const [],
      actor: pick('actor')?.toString(),
    );
  }

  // ── Derived state the steps UI asks for ──────────────────────────────

  bool get isCancelled =>
      orderStatus == OrderStatusValue.cancelled ||
      orderStatus == OrderStatusValue.expired;

  bool get isCompleted => orderStatus == OrderStatusValue.completed;

  /// The index of the node the order is standing on.
  ///
  /// **`currentStage` wins** when it names a real stage — a live capture has
  /// `orderStatus: placed` alongside `currentStage: ready_for_pickup`, and the
  /// stepper must follow the stage (§6.3 S5). Otherwise it is the first stage
  /// that is not done, which is also what "future steps are hollow" means.
  int get currentIndex {
    if (stages.isEmpty) return -1;
    final key = (currentStage ?? '').trim().toLowerCase();
    if (key.isNotEmpty) {
      final i = stages.indexWhere((s) => s.key.toLowerCase() == key);
      if (i >= 0) return i;
    }
    final firstOpen = stages.indexWhere((s) => !s.done);
    // Everything done → the last node is where it stands.
    return firstOpen >= 0 ? firstOpen : stages.length - 1;
  }

  /// The last stage the order actually completed. A cancelled order stops
  /// here and the grey terminal node is appended after it — completed history
  /// is never greyed out (S9).
  int get lastDoneIndex {
    var last = -1;
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].done) last = i;
    }
    return last;
  }

  /// Multi-shop orders carry a `businesses[]` on at least one stage (S7).
  bool get isMultiShop => stages.any((s) => s.businesses.length > 1);

  bool get isSelfPickup =>
      deliveryType == null || deliveryType == OrderDeliveryTypeValue.selfPickup;

  /// Actions for the viewer, server-first. `/track` may carry a caller-scoped
  /// `availableActions`, or a role-split `lifecycle`; when it carries neither
  /// the list is empty, which is a valid and common state (C6, B2).
  List<String> actionsFor({required bool isOwner}) {
    if (availableActions.isNotEmpty) return availableActions;
    return lifecycle?.actionsFor(isOwner: isOwner) ?? const [];
  }

  /// Whether the viewer is the shop, according to the server. Null when
  /// `/track` did not say — the caller keeps its own guess (B3).
  bool? get actorIsOwner {
    switch (actor) {
      case OrderActor.owner:
        return true;
      case OrderActor.customer:
        return false;
      default:
        return null;
    }
  }
}
