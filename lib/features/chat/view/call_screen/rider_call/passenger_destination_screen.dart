import 'dart:async';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/controller/upi_payment_controller.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../../auth/service/ride_location_publisher.dart';
import 'ride_navigation_overlay_controller.dart';

/// Rider-side destination screen shown once the order is `picked-up`
/// (pickup OTP verified). The rider is now carrying the passenger from the
/// pickup point to the drop/destination.
///
/// Shows a live map (the rider marker + route keep updating as the rider
/// moves), the passenger info, the live remaining distance to the destination,
/// the total trip distance measured from pickup, the fare, and a
/// slide-to-complete control that closes the ride.
///
/// This is a RIDER-only surface — completing here calls
/// [DeliverPartnerOrdersController.completePickupRiderApi], which only reports
/// the rider's location + marks the ride complete. The customer side is
/// untouched.
/// Route colours.
///
/// Blue, not the screen's green: Google's own basemap paints trunk roads and
/// highways green, so a green route vanished into exactly the roads a ride
/// spends most of its time on. Blue is the one hue the basemap reserves for
/// water, which a route never runs along for long enough to be confusing.
///
/// It also matches [RiderPickupNavigationScreen], so the line the rider follows
/// to the pickup and the line they follow to the drop are the same colour.
const Color _kRouteColor = Color(0xFF4285F4);

/// Darker edge drawn under the route so it keeps its shape against pale roads
/// and against satellite imagery.
const Color _kRouteCasingColor = Color(0xFF0B57D0);

/// Zoom for the driving view — close enough to read the road being ridden and
/// the next turn on it.
///
/// The map deliberately opens here rather than fitted to the whole trip: on
/// anything longer than a couple of kilometres a whole-route fit scales the
/// road under the wheels down to a hairline, which is the one thing the rider
/// is actually looking at. The whole route is one tap away on the
/// show-whole-route button for when they want to place the trip.
const double _kNavZoom = 16.5;

class PassengerDestinationScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  /// Fare shown to the rider for this trip.
  final double fareAmount;

  /// Total pickup → drop trip distance (km), as computed at booking time.
  final double distanceKm;

  final String customerName;
  final String customerImage;
  final String paymentMethod;
  final String orderId;

  /// The customer's user id, for the rider→customer rating on the completion
  /// panel. Optional: the entry points that don't carry it (PiP, notification
  /// resume) fall back to
  /// [DeliverPartnerOrdersController.customerIdForOrder].
  final String customerUserId;

  const PassengerDestinationScreen({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.fareAmount,
    required this.distanceKm,
    required this.customerName,
    this.customerImage = '',
    this.paymentMethod = 'Cash',
    this.orderId = '',
    this.customerUserId = '',
  });

  @override
  State<PassengerDestinationScreen> createState() =>
      _PassengerDestinationScreenState();
}

class _PassengerDestinationScreenState
    extends State<PassengerDestinationScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _routeCoords = [];

  StreamSubscription<Position>? _locationSubscription;
  LatLng? _currentRiderPosition;

  /// Origin the current route polyline was computed from — used to decide when
  /// the rider has moved far enough to refresh the route.
  LatLng? _routeOrigin;

  /// Live straight-line distance (km) from the rider to the drop.
  double _remainingKm = 0;

  bool _rideCompleted = false;
  bool _isEndingRide = false;
  double _dragX = 0;

  /// Stars the rider has given the customer on the completion panel, 0 = not
  /// rated yet. Submitted on tap — a rider standing at the drop shouldn't have
  /// to pick a score AND press a second button.
  int _customerRating = 0;
  bool _ratingSubmitting = false;
  bool _ratingSubmitted = false;

  // ------------------------------------------------------------- map controls

  /// Camera follows the rider. Turned OFF the moment the rider touches the map,
  /// because the old behaviour animated the camera back on every GPS tick —
  /// panning ahead to check a turn was undone a second later, which made the
  /// map feel broken rather than helpful.
  bool _followRider = true;

  MapType _mapType = MapType.normal;

  /// On by default: this is a working navigation map, and the traffic layer is
  /// the single most useful thing on it for choosing a lane or a turn.
  bool _trafficEnabled = true;

  /// True when the position stream can't run (permission denied, location
  /// services off) or has errored. Surfaced in the status bar because the
  /// consequence is invisible otherwise: the rider drives on while the
  /// customer's map shows them parked at the pickup point.
  bool _gpsUnavailable = false;

  /// Rider's own UPI id (VPA), for the collection QR on the completion sheet.
  /// Null while loading, or when the rider has no UPI configured.
  String? _riderUpiId;

  /// True when the fare is still to be collected in person. `prepaid` rides
  /// were paid online at booking — a QR there invites a double payment.
  bool get _collectsPayment =>
      widget.paymentMethod.toLowerCase() != 'prepaid' &&
      widget.paymentMethod.toLowerCase() != 'online' &&
      widget.fareAmount > 0;

  /// Scannable UPI payload. The amount IS included here (unlike the chat
  /// payment sheet, which asks the payer to type it) — the fare is known
  /// exactly, and pre-filling it removes the most common way a rider gets
  /// underpaid at the end of a trip.
  String get _upiPayString => Uri.parse('upi://pay').replace(
        queryParameters: {
          'pa': _riderUpiId ?? '',
          'pn': 'BlueEra Rider',
          'am': widget.fareAmount.toStringAsFixed(2),
          'cu': 'INR',
          if (widget.orderId.isNotEmpty) 'tn': 'Ride ${widget.orderId}',
        },
      ).toString();

  LatLng get _dropLatLng => LatLng(widget.dropLat, widget.dropLng);

  @override
  void initState() {
    super.initState();
    // Seed the rider position from the last known location so the map has a
    // sensible origin before the first GPS fix arrives.
    final seedLat = LocationService.lat;
    final seedLng = LocationService.lng;
    _currentRiderPosition = (seedLat != 0 || seedLng != 0)
        ? LatLng(seedLat, seedLng)
        : LatLng(widget.pickupLat, widget.pickupLng);
    _recomputeRemaining();
    _setupStaticMarkers();
    _updateRiderMarker(heading: 0);
    _loadRiderIcon();
    _fetchRoute(_currentRiderPosition!);
    // Publish the rider's live position to the customer's tracking stream for
    // the duration of the ride (heartbeat + retry handled by the publisher).
    RideLocationPublisher().start();
    // Seed the first ping from the last known fix so the customer's map isn't
    // blank until the first GPS tick arrives.
    final seed = _currentRiderPosition;
    if (seed != null) {
      RideLocationPublisher().updatePosition(seed.latitude, seed.longitude);
    }
    _startLocationTracking();
    // The floating mini-map is the stand-in for THIS screen — leaving it up
    // once the full map is open puts the same ride on screen twice, with the
    // PiP sitting over the controls. Dismissed after the first frame to avoid
    // mutating an observable during build.
    //
    // dismissOverlay (not hideOverlay): it only hides the overlay and keeps the
    // ride data, so the ongoing-ride card in the orders tab survives and
    // minimising from here can raise the PiP again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<RideNavigationOverlayController>()) {
        Get.find<RideNavigationOverlayController>().dismissOverlay();
      }
    });
  }

  @override
  void dispose() {
    RideLocationPublisher().stop();
    _mapController?.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _setupStaticMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: _dropLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: 'Destination', snippet: widget.dropLocation),
      ),
    );
  }

  /// Vehicle glyph for the rider's own marker, built once. Same asset the
  /// customer sees, so both sides of the ride show the same vehicle.
  BitmapDescriptor? _riderIcon;
  double _lastHeading = 0;

  Future<void> _loadRiderIcon() async {
    try {
      final bytes = await getBytesFromSvgAsset('assets/svg/2_wheeler.svg', kVehicleMarkerSize);
      if (!mounted || bytes.isEmpty) return;
      setState(() {
        _riderIcon = BitmapDescriptor.bytes(bytes);
        _updateRiderMarker(heading: _lastHeading);
      });
    } catch (_) {
      // Keep the default marker.
    }
  }

  void _updateRiderMarker({required double heading}) {
    final pos = _currentRiderPosition;
    if (pos == null) return;
    _lastHeading = heading;
    _markers.removeWhere((m) => m.markerId.value == 'rider_live');
    _markers.add(
      Marker(
        markerId: const MarkerId('rider_live'),
        position: pos,
        icon: _riderIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
        // flat so the glyph lies on the road and `rotation` points it along the
        // direction of travel instead of spinning a pin.
        flat: true,
        rotation: heading,
        anchor: const Offset(0.5, 0.5),
      ),
    );
  }

  void _recomputeRemaining() {
    final pos = _currentRiderPosition;
    if (pos == null) return;
    _remainingKm = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.dropLat,
          widget.dropLng,
        ) /
        1000.0;
  }

  /// Draws the driving route from [origin] to the drop. Called on init and
  /// whenever the rider has drifted far enough from the last route origin, so
  /// the polyline keeps tracking the road ahead as the ride progresses.
  Future<void> _fetchRoute(LatLng origin) async {
    _routeOrigin = origin;
    try {
      final polylinePoints = PolylinePoints(apiKey: googleMapKey);
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(_dropLatLng.latitude, _dropLatLng.longitude),
          mode: TravelMode.driving,
        ),
      );
      if (!mounted) return;
      if (result.points.isNotEmpty) {
        _routeCoords =
            result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        setState(() {
          _polylines
            ..removeWhere((p) =>
                p.polylineId.value == 'ride_route' ||
                p.polylineId.value == 'ride_route_casing')
            // Drawn as two stacked lines: a dark casing under a brighter core.
            // A single flat line disappears into whatever it crosses — that is
            // what a green route did over green trunk roads — whereas the
            // casing gives the route its own edge on any basemap, including the
            // satellite/hybrid view.
            ..add(
              Polyline(
                polylineId: const PolylineId('ride_route_casing'),
                points: _routeCoords,
                width: 10,
                color: _kRouteCasingColor,
                geodesic: true,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                zIndex: 0,
              ),
            )
            ..add(
              Polyline(
                polylineId: const PolylineId('ride_route'),
                points: _routeCoords,
                width: 6,
                color: _kRouteColor,
                geodesic: true,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                zIndex: 1,
              ),
            );
        });
        // Redrawing the line must not move the camera. This runs again every
        // ~150 m of travel, and refitting the whole trip each time dragged the
        // view off the road ahead every few seconds — the exact opposite of
        // what a driving rider needs. Only the rider asks for the wide view,
        // via the show-whole-route button, and when they have they keep it.
        if (!_followRider) _fitBounds(origin, _dropLatLng);
      }
    } catch (_) {
      // Route drawing is best-effort — the ride still works without a polyline.
    }
  }

  Future<void> _startLocationTracking() async {
    // Without this the stream just errors and dies on a device where location
    // is off or was never granted, and the ride runs to completion with the
    // customer watching a stationary marker. Checked rather than assumed: the
    // rider may have reached this screen from a notification, without ever
    // passing a screen that asks.
    if (!await _ensureLocationPermission()) {
      if (mounted) setState(() => _gpsUnavailable = true);
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) {
        if (!mounted || _rideCompleted) return;
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _gpsUnavailable = false;
          _currentRiderPosition = newPos;
          _updateRiderMarker(heading: position.heading);
          _recomputeRemaining();
        });
        // Push the position to the map-service so the customer's live-tracking
        // map follows the rider. Throttling/heartbeat/retry live in the
        // publisher.
        RideLocationPublisher()
            .updatePosition(newPos.latitude, newPos.longitude);
        // Follow the rider — unless they've taken manual control of the camera.
        if (_followRider) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
        }
        // Refresh the drawn route once the rider has moved ~150 m from the
        // origin it was last computed for, so the polyline stays on-road without
        // hammering the directions API on every GPS tick.
        final origin = _routeOrigin;
        if (origin == null ||
            Geolocator.distanceBetween(origin.latitude, origin.longitude,
                    newPos.latitude, newPos.longitude) >
                150) {
          _fetchRoute(newPos);
        }
      },
      // A stream error (services switched off mid-ride, platform hiccup) used
      // to kill the subscription silently. Say so, and keep the last known
      // position publishing on the heartbeat.
      onError: (_) {
        if (mounted) setState(() => _gpsUnavailable = true);
      },
      cancelOnError: false,
    );
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    if (_mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _completeRide() async {
    if (_isEndingRide) return;
    setState(() => _isEndingRide = true);

    final orderId = widget.orderId;
    if (orderId.isNotEmpty) {
      final controller = Get.put(DeliverPartnerOrdersController());
      final success = await controller.completePickupRiderApi(orderId);
      if (!success) {
        if (mounted) setState(() => _isEndingRide = false);
        return;
      }
    }

    if (!mounted) return;
    // Stop live tracking — the ride is done.
    _locationSubscription?.cancel();
    setState(() {
      _rideCompleted = true;
      _isEndingRide = false;
    });
    // Fetch the rider's own UPI id so the completion sheet can show a QR for
    // the passenger to scan. Fired here rather than in initState so a ride that
    // is minimised or abandoned never makes the call.
    _loadPayoutQr();
  }

  /// Load the signed-in rider's UPI id for the collection QR.
  ///
  /// Only for rides the rider still has to collect for — a `prepaid` trip was
  /// already paid online, and showing a QR there invites a double payment.
  Future<void> _loadPayoutQr() async {
    if (!_collectsPayment) return;
    final me = userId;
    if (me.isEmpty) return;
    final controller = Get.put(UpiPaymentController());
    await controller.fetchUserUpi(me);
    if (!mounted) return;
    setState(() => _riderUpiId = controller.upiId.value);
  }

  /// QR the passenger scans to pay the fare, shown on the completion sheet.
  ///
  /// Three states, because a blank square at the moment of collection is worse
  /// than any of them: loading, no-UPI-configured (fall back to cash), and the
  /// code itself.
  Widget _buildCollectionQr() {
    final upi = _riderUpiId;

    if (upi == null) {
      // Either still loading or the rider has no UPI on file. Either way the
      // instruction is the same and unambiguous, so don't split hairs in the UI.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 20, color: Color(0xFFB26A00)),
              const SizedBox(width: 10),
              Expanded(
                // Same treatment as the earnings line on this sheet: the amount
                // is the number being handed over, so it outweighs the wording.
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB26A00),
                      fontFamily: 'OpenSans',
                    ),
                    children: [
                      const TextSpan(text: 'Collect '),
                      TextSpan(
                        text: '₹${widget.fareAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' in cash'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Ask the passenger to scan to pay',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontFamily: 'OpenSans',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: QrImageView(
            data: _upiPayString,
            version: QrVersions.auto,
            size: 148,
            // High correction: this is scanned off a phone held at arm's length,
            // often in sunlight, sometimes with a cracked screen.
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            gapless: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          upi,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'OpenSans',
          ),
        ),
      ],
    );
  }

  /// Minimise back to the floating PiP overlay so the rider can keep the ride
  /// running while using the rest of the app. Mirrors the previous ride
  /// screen so the overlay + ongoing-order card keep working unchanged.
  void _minimiseToOverlay() {
    final overlayCtrl = Get.put(RideNavigationOverlayController());
    final currentRider =
        _currentRiderPosition ?? LatLng(widget.pickupLat, widget.pickupLng);
    overlayCtrl.showOverlay(
      riderLatVal: currentRider.latitude,
      riderLngVal: currentRider.longitude,
      destLatVal: _dropLatLng.latitude,
      destLngVal: _dropLatLng.longitude,
      destLabelVal: widget.dropLocation,
      customerNameVal: widget.customerName,
      fareAmountVal: widget.fareAmount,
      routePoints: _routeCoords,
      type: 'ride',
      params: {
        'pickupLocation': widget.pickupLocation,
        'dropLocation': widget.dropLocation,
        'pickupLat': widget.pickupLat,
        'pickupLng': widget.pickupLng,
        'dropLat': widget.dropLat,
        'dropLng': widget.dropLng,
        'fareAmount': widget.fareAmount,
        'distanceKm': widget.distanceKm,
        'customerName': widget.customerName,
        'customerImage': widget.customerImage,
        'paymentMethod': widget.paymentMethod,
        'orderId': widget.orderId,
        // Carried so re-entering from the mini-map can still rate the customer.
        'customerUserId': widget.customerUserId,
      },
    );
    // Guarded: this screen is reached by `pushReplacement` from the pickup
    // screen, so when the whole chain started from a notification launch it is
    // the only route on the stack and an unguarded pop blanks the app.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.offAllNamed(RouteHelper.getRiderServiceScreenRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // While completed, back simply closes the screen; otherwise it
        // minimises the live ride into the floating overlay.
        if (_rideCompleted) {
          Navigator.of(context).pop();
        } else {
          _minimiseToOverlay();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Any touch on the map hands the camera to the rider. Detecting it
            // here rather than via onCameraMoveStarted, which can't tell a
            // gesture from our own follow animation.
            Listener(
              onPointerDown: (_) {
                if (_followRider) setState(() => _followRider = false);
              },
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentRiderPosition ?? _dropLatLng,
                  zoom: _kNavZoom,
                ),
                markers: _markers,
                polylines: _polylines,
                mapType: _mapType,
                trafficEnabled: _trafficEnabled,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Settle on the rider once the controller is ready. The
                  // initial camera is already there, so this only corrects for
                  // a GPS fix that landed between build and map creation.
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (!mounted || !_followRider) return;
                    final pos = _currentRiderPosition;
                    if (pos == null) return;
                    _mapController
                        ?.animateCamera(CameraUpdate.newLatLngZoom(pos, _kNavZoom));
                  });
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopStatusBar(),
            ),
            // Hidden once the ride is over — the completion panel is about
            // payment, and steering a map you're no longer driving is noise.
            if (!_rideCompleted)
              Positioned(
                right: 16,
                bottom: 300,
                child: _buildMapControls(),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child:
                  _rideCompleted ? _buildCompletedPanel() : _buildRidePanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _rideCompleted
                        ? const Color(0xFF4285F4)
                        : const Color(0xFF00C853),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _rideCompleted
                            ? 'Ride Completed'
                            : 'Heading to destination',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // The rider is the only one who can fix this, and without
                      // saying it the failure is invisible: they drive on while
                      // the customer's map shows them parked at the pickup.
                      if (_gpsUnavailable && !_rideCompleted)
                        Text(
                          'Location off — customer can’t see you move',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: Colors.orange.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (!_rideCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_remainingKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The map controls, bottom-up in order of how often a riding rider reaches
  /// for them: recenter first (thumb-closest), then the wider-view and layer
  /// controls, with hand-off to Google Maps at the top.
  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _mapButton(
          icon: Icons.assistant_direction_rounded,
          tooltip: 'Navigate in Google Maps',
          onTap: _openInGoogleMaps,
          // The one control that leaves the app, so it's coloured as an action
          // rather than a map toggle.
          foreground: Colors.white,
          background: const Color(0xFF00C853),
        ),
        const SizedBox(height: 8),
        _mapButton(
          icon: _mapType == MapType.normal
              ? Icons.layers_outlined
              : Icons.layers_rounded,
          tooltip: 'Map type',
          onTap: _toggleMapType,
          active: _mapType != MapType.normal,
        ),
        const SizedBox(height: 8),
        _mapButton(
          icon: Icons.traffic_rounded,
          tooltip: 'Traffic',
          onTap: () => setState(() => _trafficEnabled = !_trafficEnabled),
          active: _trafficEnabled,
        ),
        const SizedBox(height: 8),
        _buildZoomPill(),
        const SizedBox(height: 8),
        _mapButton(
          icon: Icons.zoom_out_map_rounded,
          tooltip: 'Show whole route',
          onTap: _fitWholeRoute,
        ),
        const SizedBox(height: 8),
        _mapButton(
          // Filled while following, hollow once the rider has taken over — the
          // icon IS the state, so there's no separate indicator to read.
          icon: _followRider
              ? Icons.my_location_rounded
              : Icons.location_searching_rounded,
          tooltip: _followRider ? 'Following you' : 'Recenter on you',
          onTap: _recenterOnRider,
          active: _followRider,
        ),
      ],
    );
  }

  /// Zoom in/out as one stacked pill — two related controls reading as one
  /// object, and half the vertical space of two separate buttons.
  Widget _buildZoomPill() {
    return Container(
      width: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomHalf(Icons.add_rounded, () => _zoom(zoomIn: true)),
          Container(width: 24, height: 1, color: Colors.grey.shade300),
          _zoomHalf(Icons.remove_rounded, () => _zoom(zoomIn: false)),
        ],
      ),
    );
  }

  Widget _zoomHalf(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 46,
        height: 42,
        child: Icon(icon, color: const Color(0xFF1A1A2E), size: 22),
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
    Color? foreground,
    Color? background,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              size: 22,
              color: foreground ??
                  (active ? const Color(0xFF4285F4) : const Color(0xFF5F6875)),
            ),
          ),
        ),
      ),
    );
  }

  /// Snap back to the rider and resume following.
  void _recenterOnRider() {
    final pos = _currentRiderPosition;
    setState(() => _followRider = true);
    if (pos == null) return;
    // Zoom in as well as centre: the rider taps this to see the road they're
    // on, and leaving them at a whole-route zoom answers a different question.
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, _kNavZoom));
  }

  /// Whole-trip view. Leaves follow OFF — re-enabling it would animate straight
  /// back to the rider and undo the tap.
  void _fitWholeRoute() {
    setState(() => _followRider = false);
    _fitBounds(_currentRiderPosition ?? _dropLatLng, _dropLatLng);
  }

  void _zoom({required bool zoomIn}) {
    // Manual zoom is manual control; following would fight the next GPS tick.
    if (_followRider) setState(() => _followRider = false);
    _mapController
        ?.animateCamera(zoomIn ? CameraUpdate.zoomIn() : CameraUpdate.zoomOut());
  }

  /// normal → hybrid → normal. Satellite without labels is skipped: street
  /// names are the reason a rider switches to imagery in the first place.
  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  /// Hand off to Google Maps for turn-by-turn. The in-app map shows the route
  /// but gives no spoken directions, which is what a rider on an unfamiliar
  /// road actually needs. Publishing continues — the ride is unaffected.
  void _openInGoogleMaps() {
    openGoogleMaps(
      latitude: _dropLatLng.latitude,
      longitude: _dropLatLng.longitude,
    );
  }

  Widget _buildRidePanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildPassengerInfo(),
          const SizedBox(height: 16),
          _buildMetricsRow(),
          const SizedBox(height: 20),
          _buildSlideToComplete(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildPassengerInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDF1F7),
              image: widget.customerImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.customerImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.customerImage.isEmpty
                ? const Icon(Icons.person_rounded,
                    color: Color(0xFF9AA5B4), size: 26)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName.isNotEmpty
                      ? widget.customerName
                      : 'Passenger',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'OpenSans',
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: Color(0xFFFF5252)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        widget.dropLocation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'OpenSans',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetric(
              icon: Icons.navigation_rounded,
              label: '${_remainingKm.toStringAsFixed(1)} km',
              sublabel: 'To destination',
              color: const Color(0xFF00C853),
            ),
            _divider(),
            _buildMetric(
              icon: Icons.route_rounded,
              label: '${widget.distanceKm.toStringAsFixed(1)} km',
              sublabel: 'Trip distance',
              color: const Color(0xFF4285F4),
            ),
            _divider(),
            _buildMetric(
              icon: Icons.currency_rupee_rounded,
              label: '₹${widget.fareAmount.toStringAsFixed(0)}',
              sublabel: 'Fare',
              color: const Color(0xFFFFA000),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.grey.shade300,
      );

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'OpenSans',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontFamily: 'OpenSans',
          ),
        ),
      ],
    );
  }

  Widget _buildSlideToComplete() {
    if (_isEndingRide) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 54,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Color(0xFF00C853),
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sliderWidth = constraints.maxWidth;
          const buttonSize = 54.0;
          return Container(
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(buttonSize / 2),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Text(
                    'Slide to complete ride',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'OpenSans',
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  left: _dragX,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragX = (_dragX + details.delta.dx)
                            .clamp(0, sliderWidth - buttonSize);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      if (_dragX > (sliderWidth - buttonSize) * 0.7) {
                        _completeRide();
                      }
                      setState(() => _dragX = 0);
                    },
                    child: Container(
                      height: buttonSize,
                      width: buttonSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(buttonSize / 2),
                      ),
                      child: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The customer's id for the rating call. Entry points that pass it win;
  /// the rest are resolved from the rider's loaded orders by order id.
  String get _customerUserId {
    if (widget.customerUserId.isNotEmpty) return widget.customerUserId;
    if (widget.orderId.isEmpty) return '';
    return Get.put(DeliverPartnerOrdersController())
        .customerIdForOrder(widget.orderId);
  }

  Future<void> _submitCustomerRating(int stars) async {
    if (_ratingSubmitting || _ratingSubmitted) return;
    final userId = _customerUserId;
    if (userId.isEmpty) {
      commonSnackBar(message: 'Customer details not available to rate');
      return;
    }
    setState(() {
      _customerRating = stars;
      _ratingSubmitting = true;
    });
    final ok = await Get.put(DeliverPartnerOrdersController()).rateCustomer(
      userId: userId,
      orderId: widget.orderId,
      rating: stars,
    );
    if (!mounted) return;
    setState(() {
      _ratingSubmitting = false;
      _ratingSubmitted = ok;
      // A failed submit rolls the stars back so the row doesn't read as saved.
      if (!ok) _customerRating = 0;
    });
  }

  /// Rider → customer rating. Hidden once there is no customer to attribute it
  /// to, since a vote the server would reject is worse than no prompt.
  Widget _buildRateCustomer() {
    if (widget.orderId.isEmpty) return const SizedBox.shrink();
    final rated = _ratingSubmitted ||
        Get.put(DeliverPartnerOrdersController())
            .ratedCustomerOrderIds
            .contains(widget.orderId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              rated
                  ? 'Thanks for rating ${widget.customerName}'
                  : 'How was ${widget.customerName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'OpenSans',
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            if (_ratingSubmitting)
              const SizedBox(
                height: 32,
                width: 32,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = star <= _customerRating;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(),
                    onPressed: rated ? null : () => _submitCustomerRating(star),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 30,
                      color: filled
                          ? const Color(0xFFFFA000)
                          : Colors.grey.shade400,
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF00C853), size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ride Completed!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'OpenSans',
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          // The amount carries the weight — it's the number the rider checks
          // against what the passenger hands over (or scans below), so it is
          // bold against the surrounding grey rather than uniform with it.
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'OpenSans',
              ),
              children: [
                const TextSpan(text: 'You earned '),
                TextSpan(
                  text: '₹${widget.fareAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const TextSpan(text: ' for this trip'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (_collectsPayment) ...[
            const SizedBox(height: 18),
            _buildCollectionQr(),
          ],
          const SizedBox(height: 18),
          _buildRateCustomer(),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Guarded — this screen is reached by `pushReplacement`, so on a
                // notification-launched ride it can be the only route on the
                // stack and a bare pop would leave the app blank.
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.offAllNamed(RouteHelper.getRiderServiceScreenRoute());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
