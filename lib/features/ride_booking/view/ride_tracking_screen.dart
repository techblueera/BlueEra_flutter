import 'dart:developer';

import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/route_polyline_service.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_completed_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_cancel_sheets.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_trip_details_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/map/osrm_routing.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:url_launcher/url_launcher.dart';

/// Captain assigned + live tracking (screenshot 5).
///
/// The captain marker is driven by the controller's 5s location poll; this
/// screen only renders. When the ride reaches a terminal state it unwinds the
/// whole flow back to the home screen.
class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final RideBookingController controller = Get.find<RideBookingController>();
  late final Worker _terminalWorker;
  late final Worker _rideStartedWorker;
  BlueMapController? _mapController;

  /// Road route from the captain to the pickup. Empty until the Directions call
  /// lands — the map falls back to a dashed straight hint so it never reads as
  /// a real route.
  List<LatLng> _captainRoute = const [];

  /// Two-wheeler glyph for the captain marker, and the pin for the route
  /// target. A place gets a pin — only the moving vehicle gets a glyph.
  ///
  /// Built once and held, because [BlueMap] compares marker children by
  /// identity: rebuilding these in `build` would make every frame look like a
  /// visual change and redraw both markers continuously.
  ///
  /// They are plain widgets now. The map used to need rasterised
  /// `BitmapDescriptor`s, so both were produced asynchronously in `initState`
  /// and written back with `setState` — meaning the first frames of a live ride
  /// drew default pins until the encode finished. Widgets are correct from the
  /// first frame.
  static const Widget _captainIcon = LocalAssets(
    imagePath: 'assets/svg/2_wheeler.svg',
    width: kVehicleMarkerSize,
    height: kVehicleMarkerSize,
  );

  // Not const: AppImageAssets paths are runtime strings.
  static final Widget _targetPin = LocalAssets(
    imagePath: AppImageAssets.locationMarkerIcon,
    width: 30,
    height: 40,
  );

  /// The in-ride issue the customer flagged, if any. Kept so the chip shows an
  /// acknowledged state instead of silently resetting.
  String? _reportedIssue;

  /// Minutes along [_captainRoute], measured from the Directions reply. Used
  /// for the drop ETA once moving — the payload only ever sends a pickup ETA.
  int? _routeEtaMinutes;

  @override
  void initState() {
    super.initState();
    _terminalWorker = ever(controller.terminalStatus, _onTerminalStatus);
    _rideStartedWorker = ever(controller.activeBooking, _onBookingChanged);
    // The ride can already be in progress when this screen is built — e.g.
    // re-entering after a background kill — so don't wait for a change.
    _onBookingChanged(controller.activeBooking.value);
  }

  /// The end of the leg the captain is currently driving.
  ///
  /// The line answers a different question either side of the OTP: before the
  /// ride it is "how does the captain reach ME", after it is "how do WE reach
  /// the drop". The marker, the route and the dashed hint all read this, so
  /// they can never disagree about which end is being drawn.
  RidePlace _routeTargetPlace(RideBooking booking) =>
      booking.status == RideStatus.onTrip ? booking.drop : booking.pickup;

  void _maybeRefreshCaptainRoute(RideBooking booking) {
    final captain = booking.captain;
    if (captain?.latitude == null || captain?.longitude == null) return;

    final target = _routeTargetPlace(booking);
    if (!target.hasCoordinates) return;

    _refreshCaptainRoute(
      LatLng(captain!.latitude!, captain.longitude!),
      LatLng(target.latitude, target.longitude),
    );
  }

  /// Fetches the driving route captain → pickup so the line follows roads.
  ///
  /// Best-effort: when [RoutePolylineService] declines (throttled) or fails, the
  /// line already on screen stays put rather than being cleared. The caching and
  /// rate limiting that used to live here now live in that service, so every
  /// screen drawing a route gets them — and so two screens drawing the SAME leg
  /// share one call. See docs/GOOGLE_MAPS_COST_GUIDE.md §3.4.
  Future<void> _refreshCaptainRoute(LatLng captain, LatLng pickup) async {
    final result = await RoutePolylineService.fetch(
      origin: PointLatLng(captain.latitude, captain.longitude),
      destination: PointLatLng(pickup.latitude, pickup.longitude),
    );
    if (!mounted || result == null || result.points.length < 2) return;

    final seconds = result.totalDurationValue;
    setState(() {
      _captainRoute = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);
      // Drives the on-trip "Reaching drop location in N mins" line. The
      // booking payload carries a PICKUP eta only, so once moving the ETA has
      // to come off the route we just measured.
      // Zero means the router returned no duration — keep the previous ETA.
      if (seconds > 0) {
        _routeEtaMinutes = (seconds / 60).round();
      }
    });
  }

  @override
  void dispose() {
    _terminalWorker.dispose();
    _rideStartedWorker.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// This screen IS the live tracking — its own map shows the captain moving
  /// and the route ahead, before and after the ride starts. There is no
  /// hand-over to a second full-screen map: that was a duplicate surface for
  /// the same information, and the chat/orders flow keeps its own page.
  void _onBookingChanged(RideBooking? booking) {
    if (booking == null || !mounted) return;
    // Runs on every poll tick so the route re-draws as the captain moves;
    // _refreshCaptainRoute itself no-ops until the position actually changes.
    _maybeRefreshCaptainRoute(booking);
  }

  void _onTerminalStatus(RideStatus? status) {
    if (status == null || !mounted) return;

    // A completed ride gets a screen, not a toast: it's the only moment the
    // customer has a receipt to check and something to say about the trip.
    if (status == RideStatus.completed) {
      final booking = controller.activeBooking.value;
      if (booking != null) {
        _openRideCompleted(booking);
        return;
      }
    }

    final message = switch (status) {
      RideStatus.completed => 'Ride completed. Thanks for riding with us!',
      // Read BEFORE resetTrip() clears activeBooking.
      RideStatus.cancelled => _cancellationMessage(),
      _ => 'This ride has ended.',
    };
    controller.resetTrip();
    Get.until((route) => route.isFirst);
    Get.snackbar('Ride', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows the summary, then unwinds the whole booking flow once dismissed.
  ///
  /// The booking is passed by value because `resetTrip()` clears
  /// `activeBooking` — it runs on dismissal so the fare and captain stay
  /// readable while the screen is up.
  void _openRideCompleted(RideBooking booking) {
    Get.off(
      () => RideCompletedScreen(
        booking: booking,
        onDone: () {
          controller.resetTrip();
          Get.until((route) => route.isFirst);
        },
      ),
    );
  }

  /// Names who cancelled, because the two cases need opposite things from the
  /// customer: their own cancellation just needs confirming, while a captain's
  /// leaves them stranded and needing to rebook.
  String _cancellationMessage() {
    final booking = controller.activeBooking.value;
    if (booking == null) return 'This ride was cancelled.';
    final reason = booking.cancellationReasonLabel;

    if (booking.isCancelledByCaptain) {
      return reason == null
          ? 'Your captain cancelled this ride. Please book again.'
          : 'Your captain cancelled this ride ($reason). Please book again.';
    }
    if (booking.isCancelledByCustomer) {
      return 'Your ride was cancelled.';
    }
    return 'This ride was cancelled.';
  }

  /// Leaving means different things either side of the OTP.
  ///
  /// BEFORE the ride starts, backing out is abandoning a booking, so it goes
  /// through the cancel confirmation. AFTER the OTP is handed over the ride is
  /// running and cannot be cancelled — asking "cancel your ride?" there is
  /// wrong, and offering it at all is worse. Minimise into the floating
  /// mini-map instead, so the customer can use the rest of the app while the
  /// ride carries on; tapping the mini-map re-opens live tracking.
  void _handleLeave() {
    final booking = controller.activeBooking.value;
    if (booking != null && booking.status == RideStatus.onTrip) {
      _minimiseToOverlay(booking);
      return;
    }
    _openCancelFlow();
  }

  /// Publishes the floating mini-map and unwinds to the home screen.
  ///
  /// Typed `ride_booking` rather than `track_rider`: tapping the PiP must come
  /// back to THIS details screen — the one the customer minimised — and live
  /// tracking is a button away from here. `track_rider` jumps straight to the
  /// map, which is the chat flow's behaviour, not this one's.
  void _minimiseToOverlay(RideBooking booking) {
    final overlay = Get.put(RideNavigationOverlayController());
    overlay.showOverlay(
      riderLatVal: booking.captain?.latitude ?? 0,
      riderLngVal: booking.captain?.longitude ?? 0,
      destLatVal: booking.drop.latitude,
      destLngVal: booking.drop.longitude,
      destLabelVal: booking.drop.title,
      customerNameVal: AppStrings.trackYourRider.tr,
      fareAmountVal: booking.fare,
      routePoints: const [],
      type: 'ride_booking',
      params: {
        'riderId': booking.captain?.id ?? '',
        'dropLat': booking.drop.latitude,
        'dropLng': booking.drop.longitude,
        'orderId': booking.rideId,
      },
    );
    Get.until((route) => route.isFirst);
  }

  Future<void> _openCancelFlow() async {
    final cancelled = await showRideCancelFlow(controller: controller);
    if (cancelled == true && mounted) {
      controller.resetTrip();
      Get.until((route) => route.isFirst);
    }
  }

  /// Hands off to the phone's dialler.
  Future<void> _dialCaptain() async {
    final phone = controller.activeBooking.value?.captain?.phone;
    if (phone == null || phone.isEmpty) {
      commonSnackBar(message: 'Captain phone number is unavailable');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Places the in-app (WebRTC) audio call, so neither side's real number is
  /// exposed. Keyed on the captain's user id rather than the phone number.
  Future<void> _callCaptainInApp() async {
    final captain = controller.activeBooking.value?.captain;
    if (captain == null || captain.id.isEmpty) {
      commonSnackBar(message: 'Captain is not available for an in-app call');
      return;
    }
    if (!Get.isRegistered<CallController>()) {
      commonSnackBar(message: 'Calling is unavailable right now');
      return;
    }
    await Get.find<CallController>().initiateCall(
      type: CallType.audio,
      otherUserId: captain.id,
      userName: captain.hasName ? captain.name : 'Captain',
      userImage: captain.photoUrl ?? '',
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: RideStyle.ink),
        label: CustomText(
          label,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RideStyle.ink,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          side: const BorderSide(color: RideStyle.hairline),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            Expanded(flex: 5, child: _mapArea()),
            Expanded(flex: 5, child: _sheet()),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- map

  Widget _mapArea() {
    return Obx(() {
      final booking = controller.activeBooking.value;
      final captain = booking?.captain;

      // End of the leg being driven — pickup before the ride, drop once moving.
      final target = booking == null ? null : _routeTargetPlace(booking);
      final targetLatLng = (target != null && target.hasCoordinates)
          ? LatLng(target.latitude, target.longitude)
          : const LatLng(23.2599, 77.4126);
      final captainLatLng =
          (captain?.latitude != null && captain?.longitude != null)
              ? LatLng(captain!.latitude!, captain.longitude!)
              : null;

      return Stack(
        children: [
          BlueMap(
            initialCenter: targetLatLng,
            initialZoom: 15,
            myLocationEnabled: true,
            onMapCreated: (c) => _mapController = c,
            markers: [
              // The pin marks whichever end the captain is currently driving
              // to. Before the ride that is the pickup; once moving it is the
              // drop — and it MUST switch, because the route line switches
              // with it. Leaving a pickup pin up mid-ride left the line running
              // from the bike to an unmarked point while a stale pin sat
              // unconnected beside it.
              BlueMapMarker(
                id: 'route-target',
                position: targetLatLng,
                child: _targetPin,
                // A pin points AT its coordinate — anchor the tip, not the
                // middle (which is right for the centred vehicle glyph).
                anchor: BlueMarkerAnchor.bottom,
              ),
              if (captainLatLng != null)
                BlueMapMarker(
                  id: 'captain',
                  position: captainLatLng,
                  // Vehicle glyph, not a map pin — a pin reads as a place, and
                  // this is the thing that's moving.
                  child: _captainIcon,
                ),
            ],
            polylines: [
              if (captainLatLng != null)
                if (_captainRoute.length >= 2)
                  BlueMapPolyline(
                    id: 'captain-route',
                    points: _captainRoute,
                    color: AppColors.primaryColor,
                    width: 5,
                  )
                else
                  // Straight hint until the route lands — dotted so it can't be
                  // mistaken for the road route.
                  BlueMapPolyline(
                    id: 'captain-route-pending',
                    // Same end the real route uses, so the hint doesn't point
                    // somewhere else for the second before it lands.
                    points: [captainLatLng, targetLatLng],
                    color: AppColors.primaryColor.withValues(alpha: 0.45),
                    width: 3,
                    isDotted: true,
                  ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: RideCircleButton(
              // Chevron-down once moving: the action is "minimise", not "go
              // back" — a back arrow there implies the ride can be abandoned.
              icon: controller.activeBooking.value?.status == RideStatus.onTrip
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.arrow_back,
              onTap: _handleLeave,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                RideCircleButton(
                  icon: Icons.share_outlined,
                  iconColor: AppColors.primaryColor,
                  onTap: () => commonSnackBar(
                    message: 'Ride sharing is coming soon',
                  ),
                ),
                const SizedBox(width: 10),
                RideCircleButton(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primaryColor,
                  onTap: () => commonSnackBar(
                    message: 'Safety options are coming soon',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ------------------------------------------------------------------ sheet

  /// In-ride issue reporter, shown only once moving.
  ///
  /// STATIC: the reason list is hardcoded and there is no feedback endpoint on
  /// the ride service, so a tap is logged and acknowledged locally. Swap the
  /// list for a server-driven one and POST from [_reportIssue] when the API
  /// exists — the cancel-reason sheet already does exactly that.
  Widget _buildIssuesCard(RideBooking booking) {
    const issues = [
      'Demanded extra cash',
      'Unclean Helmet',
      'Rash Driving',
      'Wrong Vehicle',
      'No issues',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RideStyle.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Any issues with your ride?',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: RideStyle.ink,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: issues.map((issue) {
              final selected = _reportedIssue == issue;
              return GestureDetector(
                onTap: () => _reportIssue(booking, issue),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? RideStyle.action.withValues(alpha: 0.10)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? RideStyle.action : RideStyle.hairline,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: CustomText(
                    issue,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? RideStyle.action : RideStyle.ink,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _reportIssue(RideBooking booking, String issue) {
    setState(() => _reportedIssue = issue);
    if (issue == 'No issues') return;
    log('ride issue — order=${booking.rideId} issue=$issue');
    commonSnackBar(message: 'Thanks — we\'ve noted this and will follow up.');
  }

  Widget _sheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
        boxShadow: RideStyle.sheetShadow,
      ),
      child: Obx(() {
        final booking = controller.activeBooking.value;
        if (booking == null) return const SizedBox.shrink();
        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).padding.bottom + 18,
          ),
          children: [
            const RideSheetHandle(),
            _etaBanner(booking),
            // The PIN starts the ride, so it is only useful BEFORE the ride
            // starts. Once on-trip the customer has already handed it over and
            // leaving it on screen just invites them to read it out again.
            if (booking.startOtp != null &&
                booking.status != RideStatus.onTrip) ...[
              const SizedBox(height: 18),
              _otpRow(booking.startOtp!),
            ],
            const SizedBox(height: 16),
            _captainCard(booking),
            if (booking.status == RideStatus.onTrip) ...[
              const SizedBox(height: 16),
              _buildIssuesCard(booking),
            ],
            const SizedBox(height: 16),
            _pickupFromRow(booking),
          ],
        );
      }),
    );
  }

  Widget _etaBanner(RideBooking booking) {
    final minutes = booking.pickupEtaMinutes;
    final metres = booking.captainDistanceMeters;
    final onTrip = booking.status == RideStatus.onTrip;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: RideStyle.pickup.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
              ),
              children: onTrip
                  ? [
                      const TextSpan(text: 'Reaching drop location'),
                      if (_routeEtaMinutes != null)
                        TextSpan(
                          text: ' in $_routeEtaMinutes'
                              ' min${_routeEtaMinutes == 1 ? '' : 's'}',
                          style: const TextStyle(color: RideStyle.pickup),
                        ),
                    ]
                  : [
                      const TextSpan(text: 'Pickup in '),
                      TextSpan(
                        text: minutes == null ? '—' : '$minutes mins',
                        style: const TextStyle(color: RideStyle.pickup),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 3),
          CustomText(
            // Once moving, where the captain is relative to the PICKUP is no
            // longer the question — where the ride ends up is.
            onTrip
                ? (booking.drop.title.isNotEmpty
                    ? 'Reaching ${booking.drop.title}'
                    : 'On the way to your drop')
                : metres == null
                    ? 'Captain is on the way'
                    : 'Captain ${_formatDistance(metres)} away',
            fontSize: 15,
            color: RideStyle.inkMuted,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// "Bike · Splendor" — category then model, dropping whichever is absent.
  ///
  /// `assignedRider` sends the raw enum (`twoWheelerRider`), which is not
  /// something to show a customer, so it goes through the same display-name
  /// map the vehicle list uses.
  String? _vehicleLine(RideCaptain captain) {
    final type = captain.vehicleType;
    final parts = <String>[
      if (type != null && type.isNotEmpty)
        RideBookingController.kVehicleTypeNames[type] ?? type,
      if (captain.vehicleModel?.isNotEmpty == true) captain.vehicleModel!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String _formatDistance(int metres) =>
      metres >= 1000 ? '${(metres / 1000).toStringAsFixed(1)} km' : '$metres m';

  /// The 4-digit start PIN, one boxed digit each.
  Widget _otpRow(String otp) {
    final digits = otp.split('');
    return Row(
      children: [
        Expanded(
          child: CustomText(
            'Start your order with PIN',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: RideStyle.ink,
          ),
        ),
        for (final digit in digits)
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RideStyle.hairline),
            ),
            child: CustomText(
              digit,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: RideStyle.ink,
            ),
          ),
      ],
    );
  }

  Widget _captainCard(RideBooking booking) {
    final captain = booking.captain;
    if (captain == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RideStyle.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The plate is the biggest thing on the card — it is what
                    // the customer matches against the vehicle pulling up. Say
                    // so explicitly while it is still loading, rather than
                    // leaving a 21pt blank where it belongs.
                    CustomText(
                      captain.vehicleNumber?.isNotEmpty == true
                          ? captain.vehicleNumber!
                          : 'Vehicle details coming…',
                      fontSize: captain.vehicleNumber?.isNotEmpty == true
                          ? 21
                          : 15,
                      fontWeight: FontWeight.w700,
                      color: captain.vehicleNumber?.isNotEmpty == true
                          ? RideStyle.ink
                          : RideStyle.inkMuted,
                    ),
                    if (_vehicleLine(captain) != null)
                      CustomText(
                        _vehicleLine(captain)!,
                        fontSize: 15,
                        color: RideStyle.inkMuted,
                      ),
                    const SizedBox(height: 2),
                    CustomText(
                      captain.hasName
                          ? captain.name.toUpperCase()
                          : 'Your captain',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: RideStyle.ink,
                    ),
                    if (captain.totalOrders != null &&
                        captain.totalOrders! > 0) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        '${captain.totalOrders} rides completed',
                        fontSize: 13,
                        color: RideStyle.inkMuted,
                      ),
                    ],
                    // STATIC: the captain payload carries no languages field,
                    // so this is a fixed line rather than per-captain data.
                    // Read it off the model once the backend sends one.
                    const SizedBox(height: 2),
                    CustomText(
                      'Speaks English, Hindi',
                      fontSize: 13,
                      color: RideStyle.inkMuted,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    backgroundImage: (captain.photoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(captain.photoUrl!)
                        : null,
                    child: (captain.photoUrl?.isEmpty ?? true)
                        ? const Icon(Icons.person,
                            size: 30, color: RideStyle.inkMuted)
                        : null,
                  ),
                  if (captain.rating != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            captain.rating!.toStringAsFixed(1),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: RideStyle.ink,
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star,
                              size: 14, color: RideStyle.star),
                        ],
                      ),
                    ),
                  ],
                  // Derived, not server-sent — there is no "top captain" flag
                  // on the payload, so it is earned on the rating + trip count
                  // we DO get. Read a real flag here if the backend adds one.
                  if ((captain.rating ?? 0) >= 4.7 &&
                      (captain.totalOrders ?? 0) >= 500) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: RideStyle.action.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: RideStyle.action, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: RideStyle.action),
                          const SizedBox(width: 3),
                          CustomText(
                            'Top Captain',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RideStyle.action,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Contact buttons are for BEFORE the ride: finding each other at the
          // pickup is what a call is for. Once the customer is in the vehicle
          // the captain is right there, so the card drops to identity only.
          if (booking.status != RideStatus.onTrip) ...[
            const SizedBox(height: 14),
            // Two ways to reach the captain, side by side. The single button
            // that used to sit here said "Message" but placed a phone call, and
            // gave no way to use the in-app call at all.
            Row(
              children: [
                Expanded(
                  child: _contactButton(
                    icon: Icons.call_outlined,
                    label: captain.firstName.isNotEmpty
                        ? 'Call ${captain.firstName}'
                        : 'Call captain',
                    onPressed: _dialCaptain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _contactButton(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'App call',
                    onPressed: _callCaptainInApp,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pickupFromRow(RideBooking booking) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Before the ride the useful address is where the captain is
              // coming to; once moving it is where the customer is going.
              CustomText(
                booking.status == RideStatus.onTrip ? 'Drop to' : 'Pickup From',
                fontSize: 14,
                color: RideStyle.inkMuted,
              ),
              const SizedBox(height: 2),
              CustomText(
                booking.status == RideStatus.onTrip
                    ? booking.drop.fullAddress
                    : booking.pickup.fullAddress,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: RideStyle.ink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () => showRideTripDetailsSheet(controller),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: RideStyle.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: CustomText(
            'Trip Details',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RideStyle.ink,
          ),
        ),
      ],
    );
  }
}
