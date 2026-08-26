import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/rider_service_api.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:get/get.dart';

/// One round of the broadcast race, exactly as it arrived.
///
/// Rows are **appended, never rewritten** — that is the detail that makes the
/// live block read as work in progress rather than as a placeholder.
class BroadcastRound {
  final int index;
  final double radiusKm;
  final int notified;

  const BroadcastRound({
    required this.index,
    required this.radiusKm,
    required this.notified,
  });

  /// `ridersNotified: 0` is a real and common answer. It reads as
  /// *"none nearby"*, never as "0 partners called" (guide §7.4 rule 2).
  bool get foundNobody => notified <= 0;
}

/// Everything the live search block needs, built **only** from what actually
/// arrives on `ride:broadcast:searching` plus our own dispatch timestamp
/// (guide §7.4).
///
/// Two honesty rules are encoded here:
///
///  1. **No invented denominator.** "17 of 23" is not derivable, so
///     [calledTotal] is printed as a complete sentence — `17 partners called`
///     — and never as "N of M".
///  2. **Zero is an answer.** A round that rang nobody says so.
class BroadcastSearch {
  /// The product order this search belongs to.
  final String productOrderId;

  /// The rider order created by the dispatch. The socket keys on this.
  String rideOrderId;

  /// When `POST /chat-dispatch/orders` returned. The countdown is one shared
  /// 60 s timer from here — it does **not** restart per round.
  final DateTime startedAt;

  final List<BroadcastRound> rounds = <BroadcastRound>[];

  int currentRound = 0;
  int totalRounds = 3;
  double radiusKm = 0;

  /// A partner accepted. Terminal, and the happy path.
  bool assigned = false;
  String? assignedRiderId;

  /// Every round ran and nobody accepted. **Not a cancellation** — the goods
  /// are packed and waiting (guide §7.6).
  bool exhausted = false;

  /// The fee and ETA the customer already agreed to, pinned for the duration.
  final num? fare;
  final String? etaLabel;

  BroadcastSearch({
    required this.productOrderId,
    required this.rideOrderId,
    required this.startedAt,
    this.fare,
    this.etaLabel,
  });

  /// **Cumulative — a single round's value is not the total.**
  int get calledTotal => rounds.fold(0, (n, r) => n + r.notified);

  /// The whole race is 3 rounds × 20 s.
  static const Duration totalWindow = Duration(seconds: 60);

  Duration get remaining {
    final left = totalWindow - DateTime.now().difference(startedAt);
    return left.isNegative ? Duration.zero : left;
  }

  bool get isSearching => !assigned && !exhausted;

  /// Progress within the whole race: eases inside a round, jumps at the
  /// boundary. **Never indeterminate** — we know exactly how long this takes.
  double get progress {
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    final total = totalWindow.inMilliseconds;
    final p = elapsed / total;
    return p.clamp(0.0, 1.0);
  }

  void applyRound(BroadcastRound row) {
    final at = rounds.indexWhere((r) => r.index == row.index);
    if (at >= 0) {
      // A repeated event for the same round replaces it rather than
      // double-counting the partners it rang.
      rounds[at] = row;
    } else {
      rounds.add(row);
    }
    rounds.sort((a, b) => a.index.compareTo(b.index));
    currentRound = row.index;
    radiusKm = row.radiusKm;
  }
}

/// Owns the automatic rider dispatch and the live search state for order
/// cards (guide §7).
///
/// **There is no "find a rider" button for a doorstep order.** The customer
/// chose delivery at checkout, gave the address and saw the fee; when the shop
/// packs it, the card dispatches. This controller is where that happens, once
/// per order, with a guard so a rebuild cannot fire it twice.
///
/// It does **not** register its own socket listeners: `ChatSocketService`
/// replaces any existing handler for an event name, so a second
/// `ride:broadcast:searching` listener would silently kill the multi-shop
/// screen's. [DiscoverController] owns those three handlers and fans every
/// payload in here first (guide §11).
class OrderBroadcastController extends GetxController with RiderServiceApi {
  static OrderBroadcastController get instance =>
      Get.isRegistered<OrderBroadcastController>()
          ? Get.find<OrderBroadcastController>()
          : Get.put(OrderBroadcastController(), permanent: true);

  /// Live searches, keyed by **product** order id.
  final RxMap<String, BroadcastSearch> searches =
      <String, BroadcastSearch>{}.obs;

  /// rider order id → product order id, so a socket payload finds its card.
  final Map<String, String> _rideToOrder = {};

  /// Orders with a dispatch in flight. Guards the auto-trigger against a
  /// rebuild firing it twice.
  final RxSet<String> dispatching = <String>{}.obs;

  /// Orders this session has already dispatched, successfully or not. A failed
  /// attempt is removed so a retry is possible; a successful one stays.
  final Set<String> _dispatched = {};

  /// Orders whose dispatch could not even be attempted (no shop coordinates,
  /// no drop point). The card shows an honest fallback rather than a spinner.
  final RxSet<String> undispatchable = <String>{}.obs;

  final Map<String, Timer> _polls = {};

  BroadcastSearch? searchFor(String orderId) => searches[orderId];

  bool isDispatching(String orderId) => dispatching.contains(orderId);

  // ─────────────────────────────────────────────────────────────────────
  //  Dispatch
  // ─────────────────────────────────────────────────────────────────────

  /// The **automatic** trigger (guide §7.2).
  ///
  /// Nothing server-side dispatches on `PRODUCT_ORDER_READY`: `markOrderReady`
  /// sets `deadlines.dispatchBy` (25 min) and lets the sweeper escalate if no
  /// rider ever collects. So the app fires it the moment the card turns
  /// `ready` — one call, with the 3-minute server guard answering `429` on a
  /// duplicate and the sweeper as the safety net.
  ///
  /// Only the **customer's** device dispatches. Both parties see the same
  /// card; two dispatches would race for no reason.
  void autoDispatchIfNeeded({
    required OrderActionsModel? state,
    required String orderId,
    required bool isOwner,
    required String service,
    required String businessId,
    required String selfpickupType,
    required String orderFor,
    num? orderValue,
  }) {
    if (isOwner || orderId.isEmpty) return;
    if (state == null || !state.needsRiderDispatch) return;
    if (_dispatched.contains(orderId) ||
        dispatching.contains(orderId) ||
        searches.containsKey(orderId)) {
      return;
    }
    _dispatched.add(orderId);
    unawaited(dispatch(
      orderId: orderId,
      service: service,
      businessId: businessId,
      selfpickupType: selfpickupType,
      orderFor: orderFor,
      orderValue: orderValue ?? state.grandTotal,
    ));
  }

  /// Create the broadcast ride for an order that already knows where it is
  /// going. **Never re-asks for an address** — the drop comes off the order.
  Future<bool> dispatch({
    required String orderId,
    required String service,
    required String businessId,
    required String selfpickupType,
    required String orderFor,
    num? orderValue,
    String vehicleType = 'TWO_WHEELER',

    /// A drop point chosen in-card for a **self-pickup** order the customer
    /// changed their mind about (guide §5.5). A doorstep order never passes
    /// this — its address is already on the order and re-asking would be the
    /// exact behaviour v3 removes.
    OrderDeliveryInfo? dropOverride,
  }) async {
    if (dispatching.contains(orderId)) return false;
    dispatching.add(orderId);
    dispatching.refresh();
    undispatchable.remove(orderId);
    try {
      final lifecycle = OrderLifecycleController.instance;

      // The drop point lives on the order. `/actions` carries no address, so
      // hydrate from `/track` when the card has only been seeded from
      // `metadata.lifecycle`.
      OrderDeliveryInfo? drop = dropOverride;
      if (drop == null || !drop.hasCoordinates) {
        drop = lifecycle.stateOf(orderId)?.delivery;
      }
      if (drop == null || !drop.hasCoordinates) {
        await lifecycle.refreshTrack(orderId, service: service);
        drop = lifecycle.stateOf(orderId)?.delivery;
      }
      if (drop == null || !drop.hasCoordinates) {
        log('broadcast dispatch aborted — order $orderId has no drop point');
        undispatchable.add(orderId);
        undispatchable.refresh();
        _dispatched.remove(orderId);
        return false;
      }

      // The shop's own coordinates, resolved the same way the manual flow did.
      final orderNow = getOrPut(() => OrderNowController());
      await orderNow.viewBusinessForLocation(businessId, 'BUSINESS');
      final shopLat = double.tryParse(orderNow.lat.value) ?? 0.0;
      final shopLng = double.tryParse(orderNow.long.value) ?? 0.0;
      if (shopLat == 0.0 && shopLng == 0.0) {
        log('broadcast dispatch aborted — no shop location for $businessId');
        undispatchable.add(orderId);
        undispatchable.refresh();
        _dispatched.remove(orderId);
        return false;
      }

      final params = <String, dynamic>{
        'selfpickupOrderId': orderId,
        'selfpickupType': selfpickupType,
        ApiKeys.businessId: businessId,
        // ⚠ `orderType: "broadcast"` with NO `selectedRiders`. The default,
        // "standard", *requires* a hand-picked list — that is the manual flow
        // this replaces (guide §7.1).
        'orderType': 'broadcast',
        'shopLocation': {
          ApiKeys.address: orderNow.address.value,
          ApiKeys.latitude: shopLat,
          ApiKeys.longitude: shopLng,
        },
        ApiKeys.dropLocation: {
          ApiKeys.address: drop.addressLine ?? '',
          ApiKeys.latitude: drop.latitude,
          ApiKeys.longitude: drop.longitude,
        },
        ApiKeys.orderFor: orderFor,
        ApiKeys.modeOfPayment: 'prepaid',
        'vehicleType': vehicleType,
        // The fee the customer agreed to at checkout, sent as a confirmation.
        if (drop.feeEstimate != null) ApiKeys.fare: drop.feeEstimate,
        if (drop.distanceKm != null) 'distance_in_km': drop.distanceKm,
        if (orderValue != null) 'orderValue': orderValue,
      };

      final ResponseModel res = await ApiBaseHelper().postHTTP(
        chatDispatchOrders,
        params: params,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

      final body = res.response?.data;
      final json = body is Map ? Map<String, dynamic>.from(body) : null;

      if (!res.isSuccess) {
        final code = (json?['code'] ?? json?['errorCode'])?.toString();
        // 429 = the 3-minute duplicate guard. A dispatch is already running;
        // that is a success from the card's point of view.
        if (res.response?.statusCode == 429) {
          _startSearch(orderId,
              rideOrderId: _rideIdOf(json) ?? '',
              fare: drop.feeEstimate,
              etaLabel:
                  drop.etaMinutes == null ? null : '${drop.etaMinutes} min');
          return true;
        }
        log('broadcast dispatch failed for $orderId: $code ${res.response?.statusCode}');
        _dispatched.remove(orderId);
        undispatchable.add(orderId);
        undispatchable.refresh();
        return false;
      }

      _startSearch(
        orderId,
        rideOrderId: _rideIdOf(json) ?? '',
        fare: drop.feeEstimate,
        etaLabel: drop.etaMinutes == null ? null : '${drop.etaMinutes} min',
      );
      return true;
    } catch (e) {
      log('broadcast dispatch threw for $orderId: $e');
      _dispatched.remove(orderId);
      return false;
    } finally {
      dispatching.remove(orderId);
      dispatching.refresh();
    }
  }

  String? _rideIdOf(Map<String, dynamic>? json) {
    if (json == null) return null;
    final data =
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final id = data['orderId'] ?? data['_id'] ?? data['id'];
    return id?.toString();
  }

  void _startSearch(String orderId,
      {required String rideOrderId, num? fare, String? etaLabel}) {
    final search = BroadcastSearch(
      productOrderId: orderId,
      rideOrderId: rideOrderId,
      startedAt: DateTime.now(),
      fare: fare,
      etaLabel: etaLabel,
    );
    if (rideOrderId.isNotEmpty) _rideToOrder[rideOrderId] = orderId;
    searches[orderId] = search;
    searches.refresh();
    _startPoll(orderId);
  }

  /// Retry after an exhausted search — the customer tapped **Try again**.
  Future<bool> retry({
    required String orderId,
    required String service,
    required String businessId,
    required String selfpickupType,
    required String orderFor,
    num? orderValue,
  }) {
    searches.remove(orderId);
    _dispatched.remove(orderId);
    return dispatch(
      orderId: orderId,
      service: service,
      businessId: businessId,
      selfpickupType: selfpickupType,
      orderFor: orderFor,
      orderValue: orderValue,
    );
  }

  /// The customer cancelled the search itself. The **order** is untouched —
  /// the goods are still packed and can still be collected.
  Future<void> cancelSearch(String orderId) async {
    final search = searches[orderId];
    _stopPoll(orderId);
    searches.remove(orderId);
    searches.refresh();
    _dispatched.remove(orderId);
    final rideId = search?.rideOrderId ?? '';
    if (rideId.isEmpty) return;
    try {
      await ApiBaseHelper().postHTTP(
        cancelFareOrder(rideId),
        params: const {'reason': 'CUSTOMER_CANCELLED_SEARCH'},
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
    } catch (_) {
      // Best-effort: the search is already gone from the card, and the ride
      // expires on its own if nobody accepts.
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Socket fan-in — called by DiscoverController's listeners
  // ─────────────────────────────────────────────────────────────────────

  /// `ride:broadcast:searching` — `{ orderId, wave, totalWaves, radiusKm,
  /// ridersNotified }`, roughly every 20 s.
  void onSearching(dynamic data) {
    final search = _resolve(data);
    if (search == null) return;
    final json = Map<String, dynamic>.from(data as Map);
    final wave = int.tryParse('${json['wave'] ?? ''}') ?? search.currentRound;
    search.totalRounds =
        int.tryParse('${json['totalWaves'] ?? ''}') ?? search.totalRounds;
    search.applyRound(BroadcastRound(
      index: wave,
      radiusKm: double.tryParse('${json['radiusKm'] ?? ''}') ?? search.radiusKm,
      notified: int.tryParse('${json['ridersNotified'] ?? ''}') ?? 0,
    ));
    searches.refresh();
  }

  /// `ride:broadcast:accepted` — a partner won the race.
  void onAccepted(dynamic data) {
    final search = _resolve(data);
    if (search == null) return;
    final json = Map<String, dynamic>.from(data as Map);
    search.assigned = true;
    search.assignedRiderId = json['riderId']?.toString();
    searches.refresh();
    _stopPoll(search.productOrderId);
  }

  /// `ride:broadcast:exhausted` — every round ran, nobody accepted.
  ///
  /// **This is not a cancellation and must not look like one.** The goods
  /// exist and are packed (guide §7.6).
  void onExhausted(dynamic data) {
    final search = _resolve(data);
    if (search == null) return;
    search.exhausted = true;
    searches.refresh();
    _stopPoll(search.productOrderId);
  }

  /// `ride:broadcast:closed` goes to the **losing partners** so they can
  /// dismiss their popups. It is deliberately not handled here — showing it to
  /// a customer would read as "your delivery was closed".
  BroadcastSearch? _resolve(dynamic data) {
    if (data is! Map) return null;
    final rideId = (data['orderId'] ?? data['rideOrderId'])?.toString() ?? '';
    if (rideId.isEmpty) return null;

    final mapped = _rideToOrder[rideId];
    if (mapped != null) return searches[mapped];

    // The dispatch response did not name the ride order (or named it
    // differently). If exactly one search is running, it is this one.
    final live = searches.values.where((s) => s.isSearching).toList();
    if (live.length == 1) {
      live.first.rideOrderId = rideId;
      _rideToOrder[rideId] = live.first.productOrderId;
      return live.first;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  The 3 s safety-net poll
  // ─────────────────────────────────────────────────────────────────────

  /// Socket first, poll to converge. If the poll wins, the UI must land in the
  /// identical state (guide §7.3). The poll stops on accept or exhaust — it is
  /// one of only two justified timers in this flow.
  void _startPoll(String orderId) {
    _stopPoll(orderId);
    _polls[orderId] = Timer.periodic(const Duration(seconds: 3), (_) async {
      final search = searches[orderId];
      if (search == null || !search.isSearching) {
        _stopPoll(orderId);
        return;
      }
      final rideId = search.rideOrderId;
      if (rideId.isEmpty) {
        // Nothing to poll yet; the socket is still the primary path. Give up
        // once the whole window has passed with no id and no events.
        if (DateTime.now().difference(search.startedAt) >
            BroadcastSearch.totalWindow * 2) {
          search.exhausted = true;
          searches.refresh();
          _stopPoll(orderId);
        }
        return;
      }
      try {
        final res = await ChatViewRepo().checkTrackOrderStatusSilentApi(rideId);
        if (!res.isSuccess) return;
        final data = res.response?.data;
        if (data is! Map) return;
        final status = (data['status'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll('_', '-');
        const assigned = {
          'payment-pending',
          'confirmed',
          'assigned',
          'accepted',
          'in-progress',
          'picked-up',
          'completed',
        };
        if (assigned.contains(status)) {
          search.assigned = true;
          final meta = data['metadata'];
          final rider = (meta is Map) ? meta['assignedRider'] : null;
          if (rider is Map) {
            search.assignedRiderId =
                (rider['riderId'] ?? rider['_id'])?.toString();
          }
          searches.refresh();
          _stopPoll(orderId);
        } else if (status == 'rejected' || status == 'cancelled') {
          search.exhausted = true;
          searches.refresh();
          _stopPoll(orderId);
        }
      } catch (_) {
        // Best-effort — the socket path and the next tick both remain.
      }
    });
  }

  void _stopPoll(String orderId) {
    _polls.remove(orderId)?.cancel();
  }

  @override
  void onClose() {
    for (final t in _polls.values) {
      t.cancel();
    }
    _polls.clear();
    super.onClose();
  }
}
