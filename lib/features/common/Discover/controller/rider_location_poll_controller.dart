import 'dart:async';

import 'package:get/get.dart';

import '../../../chat/auth/repo/chat_view_repo.dart';

/// Customer-side live rider-location poller.
///
/// Replaces the map-provider SSE (`LiveTrachRiderController`) on the tracking
/// screens: it hits `rider-service/fare/orders/{orderId}/rider-location` every
/// [interval] (10s default) and exposes the SAME reactive fields the SSE
/// controller did (`liveLat` / `liveLng` / `rideCompleted`) so the existing
/// `ever(...)` marker workers keep working unchanged. It additionally surfaces
/// order `status` and the server-computed distances.
///
/// Keyed on `orderId` (not `riderId`) — the backend resolves `assignedRider`
/// itself, which is safer if the rider is reassigned. See
/// docs/backend/RIDER_LOCATION_POLLING_GUIDE.md.
class RiderLocationPollController extends GetxController {
  // Same reactive surface as the old SSE controller so map widgets bind to it
  // with no changes.
  final liveLat = 0.0.obs;
  final liveLng = 0.0.obs;
  final rideCompleted = false.obs;

  // Extra signals the poll endpoint returns that the SSE did not.
  final orderStatus = ''.obs;
  final distanceToPickupKm = RxnDouble();
  final distanceToDropKm = RxnDouble();
  final lastSeen = RxnString();

  /// True once at least one fix has been applied, so screens can tell "no
  /// marker yet" from "marker at 0,0".
  final hasFix = false.obs;

  Timer? _timer;
  String? _orderId;
  bool _requestInFlight = false;

  /// Start polling for [orderId]. Fires once immediately, then every [interval].
  /// Safe to call repeatedly — it restarts cleanly.
  void startPolling(String orderId,
      {Duration interval = const Duration(seconds: 10)}) {
    if (orderId.isEmpty) return;
    stopPolling();
    _orderId = orderId;
    rideCompleted.value = false;
    _tick(); // immediate first fetch — don't wait a full interval for marker 1
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    final orderId = _orderId;
    if (_requestInFlight || orderId == null) return; // no overlapping polls
    _requestInFlight = true;
    try {
      final response = await ChatViewRepo().getRiderLiveLocationApi(orderId);
      if (!response.isSuccess) return; // network/HTTP blip — next tick retries

      final data = _payload(response.response?.data);
      if (data == null) return;

      orderStatus.value = (data['status'] ?? '').toString();

      // Ride over (completed / cancelled / rejected / pending-with-no-rider):
      // stop the timer for good.
      if (data['rideActive'] == false) {
        rideCompleted.value = true;
        stopPolling();
        return;
      }

      final rider = data['rider'];
      if (rider is Map) {
        final lat = (rider['latitude'] as num?)?.toDouble();
        final lng = (rider['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          liveLat.value = lat;
          liveLng.value = lng;
          lastSeen.value = rider['lastSeen']?.toString();
          hasFix.value = true;
        }
      }
      // rider == null while rideActive == true → transient gRPC/offline gap;
      // keep the last marker and keep polling.

      distanceToPickupKm.value = (data['distanceToPickupKm'] as num?)?.toDouble();
      distanceToDropKm.value = (data['distanceToDropKm'] as num?)?.toDouble();
    } catch (_) {
      // Swallow — the timer stays alive and the next tick retries.
    } finally {
      _requestInFlight = false;
    }
  }

  /// The poll fields sit at the root of the body, but some gateway responses
  /// wrap the payload in `{ data: {...} }`. Accept either.
  Map<dynamic, dynamic>? _payload(dynamic body) {
    if (body is! Map) return null;
    final inner = body['data'];
    if (inner is Map && (inner.containsKey('rideActive') ||
        inner.containsKey('rider') ||
        inner.containsKey('status'))) {
      return inner;
    }
    return body;
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}
