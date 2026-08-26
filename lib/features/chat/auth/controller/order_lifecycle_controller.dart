import 'dart:developer';

import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/repo/order_lifecycle_repo.dart';
import 'package:get/get.dart';

/// Outcome of one lifecycle call. Success carries the fresh
/// [OrderActionsModel] the server returned, so the caller applies it directly
/// instead of re-fetching (guide §1.1).
class OrderCallResult {
  final bool ok;
  final OrderActionsModel? model;
  final String? code;
  final String? message;
  final int? statusCode;

  /// Raw success body — used by the pickup-code call, which answers with a
  /// bare `{ pickupCode }` rather than a full actions envelope.
  final Map<String, dynamic>? raw;

  const OrderCallResult({
    required this.ok,
    this.model,
    this.code,
    this.message,
    this.statusCode,
    this.raw,
  });

  /// A conflict that simply means the other party moved first. Normal, not
  /// exceptional — the caller refreshes and carries on.
  bool get isStaleState => OrderErrorCode.isStaleState(code);

  /// A success carrying a caveat — e.g. the customer typed an amount that
  /// doesn't match the total. Amber note, never an error (guide §2.3).
  String? get warning => model?.warning;
}

/// Single owner of order-lifecycle state for every open order in the app.
///
/// **Flutter no longer decides what a user can do.** This controller holds
/// what the server said (`availableActions`, deadlines, payment summary,
/// cancellation reasons) keyed by order id, exposes a busy flag per
/// *(order, action)* pair so one tapped button spins without freezing the
/// card, and normalises every failure into a typed `code`.
///
/// Registered permanently — chat cards, the checkout screen and the socket
/// handler all reach the same instance via `Get.find` / [instance].
class OrderLifecycleController extends GetxController {
  final OrderLifecycleRepo _repo = OrderLifecycleRepo();

  static OrderLifecycleController get instance =>
      Get.isRegistered<OrderLifecycleController>()
          ? Get.find<OrderLifecycleController>()
          : Get.put(OrderLifecycleController(), permanent: true);

  /// Authoritative state per order id. Rx so a card rebuilds the moment a
  /// socket patch or an action response lands.
  final RxMap<String, OrderActionsModel> orders =
      <String, OrderActionsModel>{}.obs;

  /// Busy keys, `"<orderId>:<ACTION>"`. Only the tapped button disables — the
  /// other party's updates must keep landing on the same card.
  final RxSet<String> busyKeys = <String>{}.obs;

  /// Orders whose last call failed on the transport (no server answer). Drives
  /// the card's Retry affordance. Retrying is always safe: every action is
  /// idempotent server-side.
  final RxSet<String> networkFailedOrders = <String>{}.obs;

  /// Service prefix remembered per order so a refresh triggered from the
  /// socket or an app resume hits the right vertical.
  final Map<String, String> _serviceOf = {};

  /// Open orders currently on screen. Populated by the cards; drained on app
  /// resume / socket reconnect (guide §5.2).
  final Set<String> _visibleOpenOrderIds = <String>{};

  // ── Bookkeeping ────────────────────────────────────────────────────────

  String _busyKey(String orderId, String action) => '$orderId:$action';

  bool isBusy(String orderId, String action) =>
      busyKeys.contains(_busyKey(orderId, action));

  /// True while *any* action on this order is in flight.
  bool isOrderBusy(String orderId) =>
      busyKeys.any((k) => k.startsWith('$orderId:'));

  OrderActionsModel? stateOf(String orderId) => orders[orderId];

  String serviceOf(String orderId) =>
      _serviceOf[orderId] ?? OrderServiceApi.defaultOrderService;

  /// Register a card as visible so a resume/reconnect refreshes it. Terminal
  /// orders are deliberately still tracked — a cancelled order that owes money
  /// is not finished business (guide §3.6.1).
  void trackVisibleOrder(String orderId,
      {String service = OrderServiceApi.defaultOrderService}) {
    if (orderId.isEmpty) return;
    _serviceOf[orderId] = service;
    _visibleOpenOrderIds.add(orderId);
  }

  void untrackVisibleOrder(String orderId) =>
      _visibleOpenOrderIds.remove(orderId);

  /// Seed the store from a chat card's `metadata.lifecycle` so the card can
  /// render its buttons with **no network call at all** (guide §1.1).
  /// Never overwrites a state that came from `/actions` unless the incoming
  /// lifecycle is newer, which the socket patch signals by passing
  /// [force] = true.
  void seedFromLifecycle(
    String orderId,
    OrderLifecycle lifecycle, {
    String service = OrderServiceApi.defaultOrderService,
    bool force = false,
  }) {
    if (orderId.isEmpty) return;
    _serviceOf[orderId] = service;
    if (!force && orders.containsKey(orderId)) return;
    final existing = orders[orderId];
    orders[orderId] = OrderActionsModel(
      orderId: orderId,
      orderNumber: existing?.orderNumber,
      availableActions: const [],
      actor: existing?.actor,
      lifecycle: lifecycle,
      deadlines: lifecycle.deadlines,
      paymentSummary: existing?.paymentSummary,
      cancellation: existing?.cancellation,
      cancellationReasons: existing?.cancellationReasons ?? const [],
      deliveryType: existing?.deliveryType,
      delivery: existing?.delivery,
      rideOrderId: existing?.rideOrderId,
      grandTotal: existing?.grandTotal,
      totalItems: existing?.totalItems,
      needsAttention: existing?.needsAttention ?? false,
      pickupCode: existing?.pickupCode,
    );
  }

  // ── Authoritative refresh ──────────────────────────────────────────────

  /// `GET /api/orders/:orderId/actions`. Call it when the order sheet opens,
  /// after any error, on socket reconnect and on app foreground — never on a
  /// timer (guide §5.2).
  Future<OrderCallResult> refreshActions(String orderId,
      {String? service}) async {
    if (orderId.isEmpty) {
      return const OrderCallResult(ok: false, code: 'MISSING_ORDER_ID');
    }
    final svc = service ?? serviceOf(orderId);
    _serviceOf[orderId] = svc;
    return _run(
      orderId: orderId,
      action: 'REFRESH',
      call: () => _repo.getActions(orderId, service: svc),
    );
  }

  /// Refresh every card currently on screen. Wired to socket reconnect and
  /// `AppLifecycleState.resumed`. A missed socket event is the difference
  /// between a shop staring at a stale Accept button and a shop that knows the
  /// order was auto-cancelled ten minutes ago.
  Future<void> refreshVisibleOrders() async {
    final ids = _visibleOpenOrderIds.toList(growable: false);
    for (final id in ids) {
      await refreshActions(id);
    }
  }

  // ── Owner actions ──────────────────────────────────────────────────────

  Future<OrderCallResult> acceptOrder(String orderId,
          {int? prepEtaMinutes, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.acceptOrder,
        call: () => _repo.accept(orderId,
            prepEtaMinutes: prepEtaMinutes,
            service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> rejectOrder(String orderId,
          {required String reasonCode, String? comment, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.rejectOrder,
        call: () => _repo.reject(orderId,
            reasonCode: reasonCode,
            comment: comment,
            service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> setPrepEta(String orderId,
          {required int prepEtaMinutes, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.setPrepEta,
        call: () => _repo.setPrepEta(orderId,
            prepEtaMinutes: prepEtaMinutes,
            service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> markReady(String orderId, {String? service}) => _run(
        orderId: orderId,
        action: OrderAction.markReady,
        call: () =>
            _repo.markReady(orderId, service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> verifyPayment(String orderId,
          {num? amountReceived, String? note, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.verifyPayment,
        call: () => _repo.verifyPayment(orderId,
            amountReceived: amountReceived,
            note: note,
            service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> rejectPayment(String orderId,
          {required String reason, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.rejectPayment,
        call: () => _repo.rejectPayment(orderId,
            reason: reason, service: service ?? serviceOf(orderId)),
      );

  /// A `PICKUP_CODE_MISMATCH` (403) must NOT close the dialog — the caller
  /// shakes the field and lets the shop retype. `handled: false` is passed so
  /// no toast fires over the open dialog.
  Future<OrderCallResult> confirmHandover(String orderId,
          {required String pickupCode, bool? collectedCash, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.confirmHandover,
        toastOnError: false,
        call: () => _repo.handover(orderId,
            pickupCode: pickupCode,
            collectedCash: collectedCash,
            service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> reportNoShow(String orderId,
          {String? comment, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.reportNoShow,
        call: () => _repo.noShow(orderId,
            comment: comment, service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> markRefundSent(String orderId,
          {required String refundReference, String? note, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.markRefundSent,
        toastOnError: false,
        call: () => _repo.refundSent(orderId,
            refundReference: refundReference,
            note: note,
            service: service ?? serviceOf(orderId)),
      );

  // ── Customer actions ───────────────────────────────────────────────────

  /// Errors here are surfaced as inline field errors by the sheet, so no toast
  /// fires — the sheet stays open on `UTR_ALREADY_USED` and friends.
  Future<OrderCallResult> submitPayment(String orderId,
          {required String utrNo,
          required num amountPaid,
          required String screenshotUrl,
          String? paymentQrId,
          String? upiId,
          String? transactionRef,
          String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.submitPayment,
        toastOnError: false,
        call: () => _repo.submitPayment(orderId,
            utrNo: utrNo,
            amountPaid: amountPaid,
            screenshotUrl: screenshotUrl,
            paymentQrId: paymentQrId,
            upiId: upiId,
            transactionRef: transactionRef,
            service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> fetchPickupCode(String orderId, {String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.viewPickupCode,
        call: () =>
            _repo.pickupCode(orderId, service: service ?? serviceOf(orderId)),
      );

  Future<OrderCallResult> confirmRefundReceived(String orderId,
          {String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.confirmRefundReceived,
        call: () => _repo.refundReceived(orderId,
            service: service ?? serviceOf(orderId)),
      );

  // ── Either party ───────────────────────────────────────────────────────

  Future<OrderCallResult> cancelOrder(String orderId,
          {required String reasonCode, String? comment, String? service}) =>
      _run(
        orderId: orderId,
        action: OrderAction.cancelOrder,
        call: () => _repo.cancel(orderId,
            reasonCode: reasonCode,
            comment: comment,
            service: service ?? serviceOf(orderId)),
      );

  // ── Delivery quote ─────────────────────────────────────────────────────

  /// Fetch a delivery quote. Returns null only when the call itself failed —
  /// an out-of-radius address comes back as a [DeliveryQuote] with
  /// `feasible:false`, which is a UI state, not an error.
  Future<DeliveryQuote?> fetchDeliveryQuote({
    required double shopLat,
    required double shopLng,
    required double dropLat,
    required double dropLng,
    double? distanceInKm,
    num? orderValue,
  }) async {
    try {
      final res = await _repo.deliveryQuote(
        shopLat: shopLat,
        shopLng: shopLng,
        dropLat: dropLat,
        dropLng: dropLng,
        distanceInKm: distanceInKm,
        orderValue: orderValue,
      );
      final body = res.response?.data;
      if (body is! Map) return null;
      final json = Map<String, dynamic>.from(body);
      // A 4xx still parses — `feasible:false` may ride on either.
      if (!res.isSuccess && json['feasible'] == null) return null;
      return DeliveryQuote.fromJson(json);
    } catch (e) {
      log('deliveryQuote failed: $e');
      return null;
    }
  }

  // ── Plumbing ───────────────────────────────────────────────────────────

  /// Runs one lifecycle call: sets the busy flag, normalises the response into
  /// an [OrderCallResult], applies a successful envelope to [orders], and
  /// routes a failure through [handleError].
  ///
  /// **No optimistic updates.** Every one of these actions can legitimately
  /// fail with a 409, and an optimistically-hidden Accept button that comes
  /// back is worse than a spinner (guide §6).
  Future<OrderCallResult> _run({
    required String orderId,
    required String action,
    required Future<ResponseModel> Function() call,
    bool toastOnError = true,
  }) async {
    final key = _busyKey(orderId, action);
    // Double-tap guard: the second tap is a no-op, not a second request.
    if (busyKeys.contains(key)) {
      return const OrderCallResult(ok: false, code: 'IN_FLIGHT');
    }
    busyKeys.add(key);
    busyKeys.refresh();

    try {
      final res = await call();
      final body = res.response?.data;
      final json = body is Map ? Map<String, dynamic>.from(body) : null;

      if (res.isSuccess) {
        networkFailedOrders.remove(orderId);
        OrderActionsModel? model;
        if (json != null) {
          final parsed =
              OrderActionsModel.fromJson(json, fallbackOrderId: orderId);
          // Only apply when the server actually described the order. A bare
          // `{success:true}` must not wipe the buttons off the card.
          final describesOrder = parsed.availableActions.isNotEmpty ||
              parsed.lifecycle.orderStatus != null ||
              parsed.lifecycle.customerActions.isNotEmpty ||
              parsed.lifecycle.ownerActions.isNotEmpty ||
              parsed.paymentSummary != null ||
              (parsed.pickupCode ?? '').isNotEmpty;
          if (describesOrder) {
            // MERGE, don't replace. `/actions` carries no money at all
            // (guide §2.2), so a plain refresh must not erase the
            // `data.payment.*` block an action response just delivered.
            final existing = orders[orderId];
            model = existing == null ? parsed : existing.mergedWith(parsed);
            orders[orderId] = model;
          } else {
            model = orders[orderId];
          }
        }
        return OrderCallResult(
          ok: true,
          model: model,
          statusCode: res.response?.statusCode,
          raw: json,
          message: json?['message']?.toString(),
        );
      }

      final code = _codeOf(json);
      final result = OrderCallResult(
        ok: false,
        code: code,
        message: _messageOf(json),
        statusCode: res.response?.statusCode,
        raw: json,
      );
      await handleError(orderId, result, toast: toastOnError);
      return result;
    } catch (e) {
      // `ApiBaseHelper.handleError` rethrows a plain String for transport
      // failures (timeout / DNS / airplane mode). The request may or may not
      // have reached the server, so we never guess — we surface Retry.
      log('order action $action failed for $orderId: $e');
      networkFailedOrders.add(orderId);
      networkFailedOrders.refresh();
      final result = OrderCallResult(
        ok: false,
        code: OrderErrorCode.network,
        message: e.toString(),
      );
      if (toastOnError) {
        commonSnackBar(message: 'Network problem. Please try again.');
      }
      return result;
    } finally {
      busyKeys.remove(key);
      busyKeys.refresh();
    }
  }

  /// Error codes arrive as `code`, `errorCode`, or nested under `error`.
  String? _codeOf(Map<String, dynamic>? json) {
    if (json == null) return null;
    final direct = json['code'] ?? json['errorCode'] ?? json['error_code'];
    if (direct != null) return direct.toString();
    final err = json['error'];
    if (err is Map) {
      final nested = err['code'] ?? err['errorCode'];
      if (nested != null) return nested.toString();
    }
    return null;
  }

  String? _messageOf(Map<String, dynamic>? json) {
    if (json == null) return null;
    final m = json['message'] ?? json['error'];
    if (m is String) return m;
    if (m is Map) return m['message']?.toString();
    return null;
  }

  /// The one place errors are branched — **on `code`, never on `message`**
  /// (guide §6). `ACTION_NOT_AVAILABLE` is normal, not exceptional: it means
  /// the other party moved first, so it is a refresh cue.
  Future<void> handleError(String orderId, OrderCallResult result,
      {bool toast = true}) async {
    final code = result.code;

    // Field-level codes are rendered inline by the sheet/dialog that raised
    // them — a toast on top would just cover the field.
    if (OrderErrorCode.isFieldLevel(code)) return;

    switch (code) {
      case OrderErrorCode.orderTerminal:
        // Silent: the order really is finished, the card just needs to say so.
        await _silentRefresh(orderId);
        break;

      case OrderErrorCode.actionNotAvailable:
      case OrderErrorCode.concurrentModification:
      case OrderErrorCode.paymentConflict:
      case OrderErrorCode.invalidSellerTransition:
      case OrderErrorCode.invalidPaymentTransition:
        // NORMAL, not exceptional — the other party moved first. A refresh
        // cue, never a red banner (guide §10.1).
        await _silentRefresh(orderId);
        if (toast) {
          commonSnackBar(
              message:
                  'This order has changed. Please check the updated details.');
        }
        break;

      case OrderErrorCode.notAPartyToOrder:
      case OrderErrorCode.notOrderCustomer:
        if (toast) {
          commonSnackBar(message: 'You no longer have access to this order.');
        }
        break;

      case OrderErrorCode.orderNotFound:
      case OrderErrorCode.invalidOrderId:
        if (toast) {
          commonSnackBar(message: 'This order could not be found.');
        }
        break;

      case OrderErrorCode.useLifecycleEndpoint:
      case OrderErrorCode.useHandoverEndpoint:
        // This build is calling a retired path. Ship a fix; meanwhile say so.
        if (toast) {
          commonSnackBar(message: 'Please update the app to continue.');
        }
        break;

      case OrderErrorCode.tooManyPaymentAttempts:
        if (toast) {
          commonSnackBar(message: 'Please contact the shop.');
        }
        break;

      default:
        if (toast) {
          commonSnackBar(
              message: result.message?.isNotEmpty == true
                  ? result.message!
                  : 'Something went wrong. Please try again.');
        }
    }
  }

  /// Refresh without recursing back into [handleError] — used from inside it.
  Future<void> _silentRefresh(String orderId) async {
    final key = _busyKey(orderId, 'REFRESH');
    if (busyKeys.contains(key)) return;
    busyKeys.add(key);
    try {
      final res = await _repo.getActions(orderId, service: serviceOf(orderId));
      final body = res.response?.data;
      if (res.isSuccess && body is Map) {
        final parsed = OrderActionsModel.fromJson(
            Map<String, dynamic>.from(body),
            fallbackOrderId: orderId);
        final existing = orders[orderId];
        orders[orderId] =
            existing == null ? parsed : existing.mergedWith(parsed);
      }
    } catch (_) {
      // Best-effort — the card keeps whatever it had and offers Retry.
    } finally {
      busyKeys.remove(key);
      busyKeys.refresh();
    }
  }

  /// `GET /track` — the **only** read that returns money and the stored
  /// delivery address, because `/actions` carries neither (guide §2.4).
  ///
  /// Called when a flow needs Plane C data on a card that has so far only been
  /// rendered from `metadata.lifecycle`: the pay sheet's amount due, the
  /// shop's verification card, and the coordinates auto-dispatch reuses.
  Future<OrderCallResult> refreshTrack(String orderId, {String? service}) {
    if (orderId.isEmpty) {
      return Future.value(
          const OrderCallResult(ok: false, code: 'MISSING_ORDER_ID'));
    }
    final svc = service ?? serviceOf(orderId);
    _serviceOf[orderId] = svc;
    return _run(
      orderId: orderId,
      action: 'TRACK',
      toastOnError: false,
      call: () => _repo.track(orderId, service: svc),
    );
  }

  /// Make sure this order's money block is loaded, fetching it only if it is
  /// missing. Cheap to call before opening a sheet that shows amounts.
  Future<OrderPaymentSummary?> ensurePayment(String orderId,
      {String? service}) async {
    final cached = orders[orderId]?.paymentSummary;
    if (cached != null) return cached;
    await refreshTrack(orderId, service: service);
    return orders[orderId]?.paymentSummary;
  }

  /// The viewer's role **as the server reports it**. Null until `/actions` or
  /// an action response has answered for this order — the caller then falls
  /// back to its own heuristic, which is a guess and says so.
  bool? actorIsOwner(String orderId) => orders[orderId]?.isOwnerOrNull;

  /// Apply a `productOrderLifecycle` socket payload. Called by
  /// [ChatViewController] after it patches the message's metadata.
  void applySocketLifecycle(String orderId, Map<String, dynamic> lifecycleJson,
      {String? service}) {
    if (orderId.isEmpty) return;
    final lifecycle = OrderLifecycle.fromJson(lifecycleJson);
    final existing = orders[orderId];
    if (existing == null) {
      seedFromLifecycle(orderId, lifecycle,
          service: service ?? serviceOf(orderId), force: true);
      return;
    }
    existing.lifecycle.applyFrom(lifecycle);
    orders[orderId] = OrderActionsModel(
      orderId: orderId,
      orderNumber: existing.orderNumber,
      // The socket payload is role-split; drop the stale flat list so the
      // action bar reads the role list that just arrived. Action lists
      // REPLACE, never merge — the payload always carries the complete set.
      availableActions: const [],
      actor: existing.actor,
      lifecycle: existing.lifecycle,
      deadlines: lifecycle.deadlines.isEmpty
          ? existing.deadlines
          : lifecycle.deadlines,
      paymentSummary: existing.paymentSummary,
      cancellation: existing.cancellation,
      cancellationReasons: existing.cancellationReasons,
      deliveryType: existing.deliveryType,
      delivery: existing.delivery,
      rideOrderId: existing.rideOrderId,
      grandTotal: existing.grandTotal,
      totalItems: existing.totalItems,
      needsAttention: existing.needsAttention,
      pickupCode: existing.pickupCode,
    );
  }
}
