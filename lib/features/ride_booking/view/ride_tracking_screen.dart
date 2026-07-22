import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/track_rider_live_location_page.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_completed_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_cancel_sheets.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_trip_details_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;

  /// Set once the live-tracking page has been opened for this booking.
  ///
  /// Never reset: the status poll reassigns `activeBooking` every 3s, and the
  /// page's back gesture minimises it to the floating mini-map rather than
  /// ending the session. Re-pushing on the next tick would trap the user on a
  /// screen they just chose to leave — the mini-map is how they get back.
  bool _liveTrackingOpened = false;

  /// Road route from the captain to the pickup. Empty until the Directions call
  /// lands — the map falls back to a dashed straight hint so it never reads as
  /// a real route.
  List<LatLng> _captainRoute = const [];

  /// The captain leg the [_captainRoute] was fetched for, rounded to ~11 m.
  /// The captain's position is re-polled every 5 s; without this the screen
  /// would fire a Directions request on every tick.
  String? _routeKey;

  /// Two-wheeler glyph for the captain marker, built once.
  BitmapDescriptor? _captainIcon;

  /// Pin for the pickup marker. A place gets a pin — only the moving vehicle
  /// gets a glyph. Uses the app's own marker asset rather than Google's default
  /// teardrop.
  BitmapDescriptor? _pickupIcon;

  @override
  void initState() {
    super.initState();
    _terminalWorker = ever(controller.terminalStatus, _onTerminalStatus);
    _rideStartedWorker = ever(controller.activeBooking, _onBookingChanged);
    // The ride can already be in progress when this screen is built — e.g.
    // re-entering after a background kill — so don't wait for a change.
    _onBookingChanged(controller.activeBooking.value);
    _loadCaptainIcon();
  }

  /// Builds both markers from the app's own assets: a vehicle glyph for the
  /// moving captain, a pin for the pickup.
  Future<void> _loadCaptainIcon() async {
    try {
      final captain = await getBytesFromSvgAsset('assets/svg/2_wheeler.svg', 90);
      final pickup = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 40)),
        AppImageAssets.locationMarkerIcon,
      );
      if (!mounted) return;
      setState(() {
        if (captain.isNotEmpty) _captainIcon = BitmapDescriptor.bytes(captain);
        _pickupIcon = pickup;
      });
    } catch (_) {
      // Keep the default markers — a missing glyph must not blank the map.
    }
  }

  void _maybeRefreshCaptainRoute(RideBooking booking) {
    final captain = booking.captain;
    final pickup = booking.pickup;
    if (captain?.latitude == null ||
        captain?.longitude == null ||
        !pickup.hasCoordinates) {
      return;
    }
    _refreshCaptainRoute(
      LatLng(captain!.latitude!, captain.longitude!),
      LatLng(pickup.latitude, pickup.longitude),
    );
  }

  /// Fetches the driving route captain → pickup so the line follows roads.
  ///
  /// Best-effort: a failure leaves the dashed hint in place. Skipped when the
  /// captain hasn't moved enough to change the route.
  Future<void> _refreshCaptainRoute(LatLng captain, LatLng pickup) async {
    final key = '${captain.latitude.toStringAsFixed(4)},'
        '${captain.longitude.toStringAsFixed(4)}>'
        '${pickup.latitude.toStringAsFixed(4)},'
        '${pickup.longitude.toStringAsFixed(4)}';
    if (key == _routeKey) return;
    _routeKey = key;

    try {
      final result =
          await PolylinePoints(apiKey: googleMapKey).getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(captain.latitude, captain.longitude),
          destination: PointLatLng(pickup.latitude, pickup.longitude),
          mode: TravelMode.driving,
        ),
      );
      if (!mounted || result.points.length < 2) return;
      setState(() {
        _captainRoute = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false);
      });
    } catch (_) {
      // Allow a retry on the next position change.
      _routeKey = null;
    }
  }

  @override
  void dispose() {
    _terminalWorker.dispose();
    _rideStartedWorker.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Hand over to the shared live-tracking page once the rider actually starts
  /// the trip (`in-progress`).
  ///
  /// Up to this point the interesting question is "where is my captain, and
  /// when does he reach me" — which this screen answers. Once moving, it
  /// becomes "where am I, and when do I arrive", which is what
  /// [TrackRiderLiveLocationPage] was built for: rider→drop route, distance to
  /// drop, and a minimise-to-floating-map so the ride keeps updating while the
  /// user does something else. Reused rather than rebuilt.
  void _onBookingChanged(RideBooking? booking) {
    if (booking == null || !mounted) return;
    // Runs on every poll tick (not just the on-trip transition) so the route
    // re-draws as the captain moves; _refreshCaptainRoute itself no-ops until
    // the position actually changes.
    _maybeRefreshCaptainRoute(booking);
    if (_liveTrackingOpened) return;
    if (booking.status != RideStatus.onTrip) return;
    if (!booking.drop.hasCoordinates) return;
    _openLiveTracking(booking);
  }

  Future<void> _openLiveTracking(RideBooking booking) async {
    _liveTrackingOpened = true;
    controller.pauseCaptainPolling();
    await Get.to(
      () => TrackRiderLiveLocationPage(
        riderId: booking.captain?.id ?? '',
        dropLat: booking.drop.latitude,
        dropLng: booking.drop.longitude,
        // Keyed on the order, not the rider — the backend resolves
        // `assignedRider` itself, which survives a reassignment.
        orderId: booking.rideId,
      ),
    );
    if (!mounted) return;
    controller.resumeCaptainPolling();
  }

  /// Opens live tracking on demand, from the "Track Rider" button.
  ///
  /// Same page the on-trip hand-over uses, but reachable as soon as a captain
  /// is assigned — the customer can watch the approach instead of waiting for
  /// the ride to start. Does NOT set [_liveTrackingOpened]: that flag exists to
  /// stop the automatic hand-over re-pushing on every poll tick, and a manual
  /// open must not suppress it.
  Future<void> _openTrackRider(RideBooking booking) async {
    controller.pauseCaptainPolling();
    await Get.to(
      () => TrackRiderLiveLocationPage(
        riderId: booking.captain?.id ?? '',
        dropLat: booking.drop.latitude,
        dropLng: booking.drop.longitude,
        orderId: booking.rideId,
      ),
    );
    if (!mounted) return;
    controller.resumeCaptainPolling();
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
      // Leaving tracking must go through the cancel flow, never a silent pop.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openCancelFlow();
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
      final pickup = booking?.pickup;
      final captain = booking?.captain;

      final pickupLatLng = pickup != null && pickup.hasCoordinates
          ? LatLng(pickup.latitude, pickup.longitude)
          : const LatLng(23.2599, 77.4126);
      final captainLatLng =
          (captain?.latitude != null && captain?.longitude != null)
              ? LatLng(captain!.latitude!, captain.longitude!)
              : null;

      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: pickupLatLng, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickupLatLng,
                icon: _pickupIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                // A pin points AT its coordinate — anchor the tip, not the
                // middle (which is right for the centred vehicle glyph).
                anchor: const Offset(0.5, 1.0),
                infoWindow: const InfoWindow(title: 'Pickup'),
              ),
              if (captainLatLng != null)
                Marker(
                  markerId: const MarkerId('captain'),
                  position: captainLatLng,
                  // Vehicle glyph, not a map pin — a pin reads as a place, and
                  // this is the thing that's moving.
                  icon: _captainIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  infoWindow: InfoWindow(
                    title: captain?.hasName == true ? captain!.name : 'Captain',
                  ),
                ),
            },
            polylines: {
              if (captainLatLng != null)
                if (_captainRoute.length >= 2)
                  Polyline(
                    polylineId: const PolylineId('captain-route'),
                    points: _captainRoute,
                    color: AppColors.primaryColor,
                    width: 5,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  )
                else
                  // Straight hint until the Directions call lands — dashed so
                  // it can't be mistaken for the road route.
                  Polyline(
                    polylineId: const PolylineId('captain-route-pending'),
                    points: [captainLatLng, pickupLatLng],
                    color: AppColors.primaryColor.withValues(alpha: 0.45),
                    width: 3,
                    patterns: [PatternItem.dash(18), PatternItem.gap(10)],
                  ),
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: RideCircleButton(
              icon: Icons.arrow_back,
              onTap: _openCancelFlow,
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
            // Once moving, the live map is the main event — and minimising it
            // pops back here, so there has to be a way in that doesn't depend
            // on finding the floating mini-map.
            if (booking.status == RideStatus.onTrip &&
                booking.drop.hasCoordinates) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => _openLiveTracking(booking),
                  icon: const Icon(Icons.my_location,
                      size: 20, color: RideStyle.ink),
                  label: CustomText(
                    'Track ride live',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RideStyle.ink,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    side: const BorderSide(color: RideStyle.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (booking.startOtp != null) ...[
              const SizedBox(height: 18),
              _otpRow(booking.startOtp!),
            ],
            const SizedBox(height: 16),
            _captainCard(booking),
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
              children: [
                TextSpan(
                  text: booking.status == RideStatus.onTrip
                      ? 'On the way to drop'
                      : 'Pickup in ',
                ),
                if (booking.status != RideStatus.onTrip)
                  TextSpan(
                    text: minutes == null ? '—' : '$minutes mins',
                    style: const TextStyle(color: RideStyle.pickup),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          CustomText(
            metres == null
                ? 'Captain is on the way'
                : 'Captain ${_formatDistance(metres)} away',
            fontSize: 15,
            color: RideStyle.inkMuted,
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Two ways to reach the captain, side by side. The single button that
          // used to sit here said "Message" but placed a phone call, and gave
          // no way to use the in-app call at all.
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
          const SizedBox(height: 10),
          // Available as soon as a captain is assigned — the customer can watch
          // the approach on the full map rather than waiting for the ride to
          // start and be taken there automatically.
          SizedBox(
            height: 46,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final booking = controller.activeBooking.value;
                if (booking != null) _openTrackRider(booking);
              },
              icon: const Icon(Icons.location_on_outlined,
                  size: 18, color: RideStyle.action),
              label: CustomText(
                'Track Rider',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RideStyle.action,
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.white,
                side: const BorderSide(color: RideStyle.action),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
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
              CustomText(
                'Pickup From',
                fontSize: 14,
                color: RideStyle.inkMuted,
              ),
              const SizedBox(height: 2),
              CustomText(
                booking.pickup.fullAddress,
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
