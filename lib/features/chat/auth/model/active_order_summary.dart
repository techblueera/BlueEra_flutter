import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_vertical_capabilities.dart';

/// One row of `GET <service>/api/orders/me` — just enough of an order to say,
/// on a screen that is not the order screen, **what is happening to it and by
/// when**.
///
/// ## Why this exists
///
/// Until now the only place a customer could learn that their order was ready
/// was inside the chat thread that carries its card. An order placed on Monday
/// and ready on Monday evening was invisible unless the customer happened to
/// reopen that conversation — and for grocery, where **978 of 1,099 production
/// orders expire** (guide §12), the order then died silently. The countdown
/// existed; nobody was looking at the screen it was drawn on.
///
/// So this is deliberately a **summary, not an order**. It answers one
/// question — "is something of mine waiting on me right now?" — and every tap
/// hands off to the order screen, which is the live surface (§11).
///
/// ## What it does NOT do
///
/// It renders **no action buttons**. The rule in §0 is that `/actions` decides
/// which buttons exist, and this list endpoint does not return `availableActions`
/// at all. A chip that guessed "the order is ready so show Hand over" would be
/// exactly the local legality rule the whole design forbids. One tap, to the
/// screen that knows.
class ActiveOrderSummary {
  final String orderId;
  final String? orderNumber;

  /// Which vertical's service owns it — needed for every follow-up call.
  final String service;

  /// The counterparty's name, for the one line of context the chip can show.
  final String? shopName;

  final String? deliveryType;

  /// Whether a rider has actually been assigned. A doorstep order with no
  /// rider is still searching (§6 C0); one with a rider is on its way.
  final bool riderAssigned;

  /// Everything stateful — status, payment state, deadlines — parsed by the
  /// same tolerant parser the cards use, because an `/orders/me` row and an
  /// `/actions` body name these fields identically.
  final OrderLifecycle lifecycle;

  final bool isTerminal;
  final bool needsAttention;

  /// Only used to derive grocery's clock, which the service does not send.
  final DateTime? createdAt;

  const ActiveOrderSummary({
    required this.orderId,
    required this.service,
    this.orderNumber,
    this.shopName,
    this.deliveryType,
    this.riderAssigned = false,
    required this.lifecycle,
    this.isTerminal = false,
    this.needsAttention = false,
    this.createdAt,
  });

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static DateTime? _dt(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  /// Tolerant by design: an `/orders/me` row is a whole order document, and
  /// which of its several dozen keys are present varies by vertical. Anything
  /// missing simply means that part of the chip does not draw.
  factory ActiveOrderSummary.fromJson(
    Map<String, dynamic> json, {
    required String service,
  }) {
    final business = _map(json['business']) ?? _map(json['shop']) ?? const {};
    final rider = _map(json['rider']);
    final riderLeg = json['riderLeg'];

    final status = (json['orderStatus'] ?? json['status'])?.toString();

    return ActiveOrderSummary(
      orderId: (json['orderId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? json['order_number'])?.toString(),
      service: service,
      shopName: (json['businessName'] ??
              business['name'] ??
              business['businessName'] ??
              json['shopName'])
          ?.toString(),
      deliveryType: json['deliveryType']?.toString(),
      // Either shape counts: an object with something in it, or the bare leg
      // string the service actually sends (§18.1).
      riderAssigned: (rider != null && rider.isNotEmpty) ||
          (riderLeg is String &&
              riderLeg.trim().isNotEmpty &&
              riderLeg.trim().toLowerCase() != RiderLegStatusName.notStarted),
      lifecycle: OrderLifecycle.fromJson(json),
      isTerminal: json['isTerminal'] == true || OrderStatusValue.isTerminal(status),
      needsAttention: json['needsAttention'] == true ||
          (_map(json['needsAttention'])?.isNotEmpty ?? false),
      createdAt: _dt(json['createdAt'] ?? json['placedAt']),
    );
  }

  /// Every envelope a list route is served in: a bare array, `{data: [...]}`,
  /// `{data: {orders: [...]}}`, `{orders: [...]}`.
  static List<ActiveOrderSummary> listFrom(dynamic body,
      {required String service}) {
    dynamic node = body;
    if (node is Map) {
      node = node['data'] ?? node['orders'] ?? node['result'] ?? node;
      if (node is Map) {
        node = node['orders'] ?? node['data'] ?? node['items'] ?? node['docs'];
      }
    }
    if (node is! List) return const [];
    return node
        .whereType<Map>()
        .map((e) => ActiveOrderSummary.fromJson(
            Map<String, dynamic>.from(e),
            service: service))
        .where((o) => o.orderId.isNotEmpty)
        .toList(growable: false);
  }

  bool get isSelfPickup =>
      deliveryType == null || deliveryType == OrderDeliveryTypeValue.selfPickup;

  /// **Money outlives the order** (§7). A cancelled order with a refund still
  /// owed is unfinished business and stays on the rail; a cancelled order that
  /// owes nothing is genuinely over and drops off.
  bool get hasOpenRefund =>
      lifecycle.paymentState == PaymentStateValue.refundPending ||
      lifecycle.refundDue;

  /// Whether this order still wants the customer's attention at all.
  bool get isLive => !isTerminal || hasOpenRefund;

  /// The deadline that matters at the stage this order is standing on — the
  /// §8.1 table, and nothing invented. Null draws no countdown (§8.1 rule 2).
  ///
  /// Grocery sends no `deadlines` block at all, so it falls through to the one
  /// derived clock, which is itself gated to `placed` (§12).
  DateTime? get deadline {
    final d = lifecycle.deadlines;
    if (hasOpenRefund) return null; // a refund has no clock

    switch (lifecycle.orderStatus) {
      case OrderStatusValue.placed:
        return d.acceptBy ??
            OrderVerticalCapabilities.derivedPlacedExpiry(
              service: service,
              orderStatus: lifecycle.orderStatus,
              createdAt: createdAt,
            );
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        // An unpaid UPI order is waiting on the customer's money before
        // anything else, so its clock is the one they can act on.
        if (_awaitingPayment && d.payBy != null) return d.payBy;
        return d.readyBy;
      case OrderStatusValue.ready:
        if (_awaitingPayment && d.payBy != null) return d.payBy;
        return isSelfPickup ? d.pickupBy : d.dispatchBy;
      case OrderStatusValue.dispatched:
        return d.deliverBy;
      default:
        return null;
    }
  }

  bool get _awaitingPayment =>
      lifecycle.paymentMethod == 'upi' &&
      (lifecycle.paymentState == PaymentStateValue.pending ||
          lifecycle.paymentState == PaymentStateValue.rejected ||
          lifecycle.paymentState == PaymentStateValue.expired);

  /// How loudly this order should sort on a rail that shows one thing at a
  /// time. **Lower is more urgent.** Purely presentational ranking — it never
  /// decides what a party is allowed to do.
  int get urgency {
    if (hasOpenRefund) return 5;
    if (_awaitingPayment) return 1;
    if (lifecycle.orderStatus == OrderStatusValue.ready && isSelfPickup) {
      return 0; // the customer is the only one who can move this forward
    }
    if (lifecycle.orderStatus == OrderStatusValue.ready) return 3;
    if (lifecycle.orderStatus == OrderStatusValue.dispatched) return 4;
    if (lifecycle.orderStatus == OrderStatusValue.placed) return 6;
    return 7;
  }
}

/// The one rider-leg value this file needs by name. The full vocabulary and
/// the customer copy live with the track model (`RiderLegStatus`); duplicating
/// the whole enum here to read one constant would be worse than naming it.
class RiderLegStatusName {
  static const notStarted = 'not-started';
}
