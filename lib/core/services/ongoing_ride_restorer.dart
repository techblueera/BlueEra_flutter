import 'dart:async';

import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/ongoing_ride_store.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';

/// Rebuilds the customer's ongoing ride/booking state after an app relaunch.
///
/// The overlay controller holding it is in-memory, so a kill loses the whole
/// "Your Ongoing Ride/Booking" affordance while the ride is still running.
/// [OngoingRideStore] persists a small snapshot for exactly this; this puts it
/// back and then confirms with the order-status API that the ride is still
/// alive.
///
/// Lives here rather than on a screen because more than one entry point needs
/// it: the Discover chip and the Connect tab's card both render the same state,
/// and whichever the user lands on first has to be the one that restores it.
/// Repeat calls are cheap — an already-tracked ride returns immediately, and
/// [_inFlight] stops two tabs mounting at once from both hitting the API.
class OngoingRideRestorer {
  const OngoingRideRestorer._();

  static bool _inFlight = false;

  /// Restore the snapshot if there is one and nothing is being tracked yet.
  ///
  /// Applies the snapshot optimistically first, so the card/chip appears
  /// immediately, then clears it if the server says the ride already ended. A
  /// failed status check deliberately KEEPS the optimistic state — a network
  /// blip is not evidence the ride is over.
  static Future<void> restoreIfNeeded() async {
    if (_inFlight) return;
    final overlayCtrl = getOrPut(() => RideNavigationOverlayController());
    // Already tracking this session (e.g. minimized just now) — nothing to do.
    if (overlayCtrl.hasOngoingCustomerRide) return;

    _inFlight = true;
    try {
      final snap = await OngoingRideStore.read();
      if (snap == null) return;
      final orderId = (snap['orderId'] ?? '').toString();
      if (orderId.isEmpty) {
        await OngoingRideStore.clear();
        return;
      }

      double toD(dynamic v) =>
          (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

      // 1) Optimistically rebuild the card from the snapshot.
      overlayCtrl.restoreCustomerRide(
        orderId: orderId,
        riderName: (snap['riderName'] ?? '').toString(),
        riderImageVal: (snap['riderImage'] ?? '').toString(),
        riderContactVal: (snap['riderContact'] ?? '').toString(),
        pickupLabel: (snap['pickupLabel'] ?? '').toString(),
        dropLabelVal: (snap['dropLabel'] ?? '').toString(),
        bookingTimeLabelVal: (snap['bookingTimeLabel'] ?? '').toString(),
        riderLatVal: toD(snap['riderLat']),
        riderLngVal: toD(snap['riderLng']),
        pickupLat: toD(snap['pickupLat']),
        pickupLng: toD(snap['pickupLng']),
      );

      // 2) Re-seed DiscoverController so opening the card resumes live tracking.
      final dc = getOrPut(() => DiscoverController());
      final riderId = (snap['riderId'] ?? '').toString();
      if (riderId.isNotEmpty) dc.fareCallAcceptedRiderId.value = riderId;
      dc.fareCallAcceptedRiderInfo.value = {
        'riderId': riderId,
        'name': (snap['riderName'] ?? '').toString(),
        'profileImage': (snap['riderImage'] ?? '').toString(),
        'contact': (snap['riderContact'] ?? '').toString(),
      };
      dc.fareCallOrderId.value = orderId;
      dc.selectedFromLat?.value = toD(snap['pickupLat']);
      dc.selectedFromLong?.value = toD(snap['pickupLng']);
      dc.selectedFromAddress?.value = (snap['pickupLabel'] ?? '').toString();
      dc.selectedToLat?.value = toD(snap['dropLat']);
      dc.selectedToLong?.value = toD(snap['dropLng']);
      dc.selectedToAddress?.value = (snap['dropLabel'] ?? '').toString();
      // Pull the customer's OTPs back from the server. They are not in the
      // snapshot (they must come from the source the rider is verified
      // against), and without this the ongoing chip has no OTP to show until
      // the customer opens a tracking screen.
      unawaited(dc.hydrateFareCallDeliveryOtp(orderId));

      // 3) Confirm the ride is still ongoing via the suitable API. A terminal
      // status clears the card; transient failures keep the optimistic card.
      try {
        final res = await ChatViewRepo().checkTrackOrderStatusSilentApi(orderId);
        if (res.isSuccess) {
          final status =
              res.response?.data?['status']?.toString().toLowerCase() ?? '';
          if (status == 'completed' ||
              status == 'cancelled' ||
              status == 'rejected') {
            await OngoingRideStore.clear();
            overlayCtrl.clearRideData();
          }
        }
      } catch (_) {}
    } finally {
      _inFlight = false;
    }
  }
}
