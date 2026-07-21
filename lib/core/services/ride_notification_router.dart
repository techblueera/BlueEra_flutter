import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/ride_ring_notification.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/track_rider_live_location_page.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/repo/ride_booking_repo.dart';
import 'package:get/get.dart';

/// Routes a ride notification (or its action button) to the right place, after
/// checking what the order is actually doing NOW.
///
/// A notification is a snapshot of the past. It survives being swiped away,
/// sits in the shade for hours, and can be tapped long after the ride ended —
/// so acting on the operation alone lands people on a tracking map for a
/// finished ride, or on the rider's job screen when they are the passenger.
/// Every entry point here re-reads `fare/orders/{orderId}/status` first and
/// decides from that.
///
/// Terminal rides deliberately **do not navigate**: the user may be mid-task,
/// and yanking them to another screen to tell them "this already finished" is
/// worse than a toast. The floating mini-map is cleared at the same time so
/// nothing keeps pointing at a dead order.
class RideNotificationRouter {
  const RideNotificationRouter._();

  /// Order-id keys seen across the ride notification producers.
  static const List<String> _orderIdKeys = [
    'orderId',
    'order_id',
    'rideId',
    'ride_id',
  ];

  /// Action-button prefixes that mean "take me to this ride". The order id is
  /// the suffix, e.g. `track_ride_ORD-1784629649264`.
  static const List<String> actionPrefixes = [
    'track_ride_',
    'view_order_',
    'accept_order_',
    'contact_rider_',
  ];

  /// Pull the order id out of an action id, or null if the prefix doesn't match
  /// one of [actionPrefixes].
  static String? orderIdFromActionId(String actionId) {
    for (final prefix in actionPrefixes) {
      if (actionId.startsWith(prefix) && actionId.length > prefix.length) {
        return actionId.substring(prefix.length);
      }
    }
    return null;
  }

  /// Pull the order id out of an FCM data payload / its nested metadata.
  static String? orderIdFromPayload(Map<dynamic, dynamic>? data, {Map? metadata}) {
    for (final source in [metadata, data]) {
      if (source == null) continue;
      for (final key in _orderIdKeys) {
        final value = source[key];
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
    }
    return null;
  }

  /// Open the ride identified by [orderId], validating its live status first.
  ///
  /// [fallback] runs when there is no usable order id — the caller's existing
  /// behaviour, so an unparseable payload is no worse than before.
  static Future<void> open(
    String? orderId, {
    Map<dynamic, dynamic>? data,
    void Function()? fallback,
  }) async {
    final id = (orderId ?? '').trim();
    if (id.isEmpty) {
      rideNotifLog('route: no orderId in payload → fallback');
      (fallback ?? _openRiderService)();
      return;
    }

    rideNotifLog('route: orderId=$id — checking live status…');
    final RideOrderSnapshot? snapshot = await _fetchStatus(id);
    if (snapshot == null) {
      // Network blip or a 404 for an order this account can't see. Say so
      // rather than opening a map that will sit on "Finding rider location".
      rideNotifLog('route: status lookup FAILED for $id');
      commonSnackBar(message: 'Could not open this ride. Please try again.');
      return;
    }
    rideNotifLog(
      'route: $id status=${snapshot.rawStatus} → ${snapshot.status.name} '
      'viewer=${snapshot.isViewerTheRider ? "RIDER" : "CUSTOMER"}',
    );

    // A rider tapping their own job belongs on the rider screens, not on the
    // customer's tracking map. Decided from the order, not the notification,
    // because both parties can receive alerts for the same ride.
    if (snapshot.isViewerTheRider) {
      rideNotifLog('route: viewer is the rider → rider service screen');
      (fallback ?? _openRiderService)();
      return;
    }

    if (!snapshot.status.isActive) {
      rideNotifLog('route: ride already ended → stay put + toast');
      _handleFinishedRide(snapshot.status);
      return;
    }

    if (!snapshot.status.hasCaptain) {
      // Broadcast waves still running — there is no rider to track yet.
      rideNotifLog('route: no captain assigned yet → toast only');
      commonSnackBar(
        message: 'Still finding a captain for this ride. Hang tight.',
      );
      return;
    }

    _openTracking(id, data: data);
  }

  /// Ride is over. Per product decision: stay put, explain, and stop the
  /// floating mini-map from advertising a dead order.
  static void _handleFinishedRide(RideStatus status) {
    clearOngoingRideOverlay();
    commonSnackBar(
      message: switch (status) {
        RideStatus.completed => 'This ride has already been completed.',
        RideStatus.cancelled => 'This ride was cancelled.',
        _ => 'This ride has already ended.',
      },
    );
  }

  /// Drop the floating overlay and its retained ride data.
  ///
  /// Safe to call when no overlay exists — it only touches the controller if
  /// one is registered, so this never constructs it as a side effect.
  static void clearOngoingRideOverlay() {
    if (!Get.isRegistered<RideNavigationOverlayController>()) {
      rideNotifLog('overlay: none registered — nothing to clear');
      return;
    }
    Get.find<RideNavigationOverlayController>().clearRideData();
    rideNotifLog('overlay: cleared (PiP removed, ride data dropped)');
  }

  static void _openTracking(String orderId, {Map<dynamic, dynamic>? data}) {
    final drop = _resolveDrop(orderId, data);
    rideNotifLog(
      'route: → TrackRiderLiveLocationPage orderId=$orderId '
      'drop=${drop == null ? "(none — rider-only map)" : "${drop.$1},${drop.$2}"}',
    );
    Get.to(
      () => TrackRiderLiveLocationPage(
        riderId: _resolveRiderId(orderId),
        dropLat: drop?.$1 ?? 0,
        dropLng: drop?.$2 ?? 0,
        orderId: orderId,
      ),
    );
  }

  /// Drop coordinates for the destination marker.
  ///
  /// The status response carries no drop location, so this prefers the live
  /// booking (the common case — the user booked in this session) and falls back
  /// to whatever the notification payload carried. Null when neither has it;
  /// the page then tracks the rider without a destination marker rather than
  /// routing to the null island.
  static (double, double)? _resolveDrop(
    String orderId,
    Map<dynamic, dynamic>? data,
  ) {
    if (Get.isRegistered<RideBookingController>()) {
      final booking = Get.find<RideBookingController>().activeBooking.value;
      if (booking != null &&
          booking.rideId == orderId &&
          booking.drop.hasCoordinates) {
        return (booking.drop.latitude, booking.drop.longitude);
      }
    }

    for (final key in ['dropLocation', 'drop', 'dropLatLng']) {
      final raw = data?[key];
      if (raw is! Map) continue;
      final lat = _toDouble(raw['latitude'] ?? raw['lat']);
      final lng = _toDouble(raw['longitude'] ?? raw['lng']);
      if (lat != null && lng != null && (lat != 0 || lng != 0)) return (lat, lng);
      final coords = raw['coordinates'];
      if (coords is List && coords.length >= 2) {
        final cLng = _toDouble(coords[0]);
        final cLat = _toDouble(coords[1]);
        if (cLat != null && cLng != null) return (cLat, cLng);
      }
    }
    return null;
  }

  static String _resolveRiderId(String orderId) {
    if (!Get.isRegistered<RideBookingController>()) return '';
    final booking = Get.find<RideBookingController>().activeBooking.value;
    if (booking == null || booking.rideId != orderId) return '';
    return booking.captain?.id ?? '';
  }

  static Future<RideOrderSnapshot?> _fetchStatus(String orderId) async {
    try {
      final response = await RideBookingRepo().getBookingStatus(orderId);
      if (!response.isSuccess) return null;
      // `fare/*` returns payloads unwrapped; `ResponseModel.data` reads
      // `body['data']`, so fall back to the raw body.
      final body = response.data ?? response.response?.data;
      if (body is! Map) return null;
      return RideOrderSnapshot.fromStatus(body);
    } catch (_) {
      return null;
    }
  }

  static void _openRiderService() =>
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// What `fare/orders/{id}/status` says about an order right now.
class RideOrderSnapshot {
  const RideOrderSnapshot({
    required this.status,
    required this.rawStatus,
    required this.isViewerTheRider,
  });

  final RideStatus status;

  /// The server's own string, kept for logging — an unmapped value silently
  /// becomes `searching`, and seeing the raw text is the only way to notice.
  final String rawStatus;

  /// True when the signed-in account is the assigned rider rather than the
  /// passenger — the two need opposite screens for the same notification.
  final bool isViewerTheRider;

  factory RideOrderSnapshot.fromStatus(Map<dynamic, dynamic> body) {
    final metadata = body['metadata'];
    final meta = metadata is Map ? metadata : const {};

    // `assignedRider` is either a bare id or the full rider object.
    final assigned = meta['assignedRider'];
    final assignedId = assigned is Map
        ? (assigned['id'] ?? assigned['riderId'] ?? '').toString()
        : (assigned ?? '').toString();

    final me = userId;
    final raw = body['status']?.toString() ?? '';
    return RideOrderSnapshot(
      status: RideStatus.fromString(raw),
      rawStatus: raw.isEmpty ? '(absent)' : raw,
      isViewerTheRider:
          me.isNotEmpty && assignedId.isNotEmpty && assignedId == me,
    );
  }
}
