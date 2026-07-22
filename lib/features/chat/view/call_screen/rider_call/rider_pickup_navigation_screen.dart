import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/pip_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../../auth/service/ride_location_publisher.dart';
import '../../../auth/controller/call_controller.dart';
import '../../../auth/model/rider_orders_details_model.dart';
import 'ride_navigation_overlay_controller.dart';
import 'passenger_destination_screen.dart';

/// Screen shown after rider accepts an order.
/// Shows map from rider's current location → pickup location with OTP verification.
class RiderPickupNavigationScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final double fareAmount;
  final double distanceKm;
  final String customerName;
  final String customerImage;
  final String otp;
  final String paymentMethod;
  final String orderId;
  final String customerUserId;

  const RiderPickupNavigationScreen({
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
    required this.otp,
    this.paymentMethod = 'Cash',
    this.orderId = '',
    this.customerUserId = '',
  });

  @override
  State<RiderPickupNavigationScreen> createState() =>
      _RiderPickupNavigationScreenState();
}

class _RiderPickupNavigationScreenState
    extends State<RiderPickupNavigationScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _routeCoords = [];

  // Live GPS stream so the rider marker + camera follow the rider as they head
  // to the pickup, instead of sitting frozen at the initial fix.
  StreamSubscription<Position>? _locationSubscription;

  // OTP
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _otpVerified = false;
  bool _otpError = false;
  bool _isStartingRide = false;

  LatLng get _riderLatLng {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat != 0.0 && lng != 0.0) return LatLng(lat, lng);
    return const LatLng(26.7836, 80.9013);
  }

  LatLng get _pickupLatLng => LatLng(widget.pickupLat, widget.pickupLng);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMarkers();
    _loadMarkerIcons();
    _fetchRoute();
    // Publish the rider's live position to the customer's tracking stream while
    // heading to pickup (heartbeat + retry handled by the publisher).
    RideLocationPublisher().start();
    RideLocationPublisher()
        .updatePosition(_riderLatLng.latitude, _riderLatLng.longitude);
    _startLocationTracking();
    // Hide floating overlay after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<RideNavigationOverlayController>()) {
        Get.find<RideNavigationOverlayController>().hideOverlay();
      }
      // If we somehow land here for an order whose pickup OTP was ALREADY
      // verified (status is picked-up), skip OTP entry entirely and go to the
      // destination — re-submitting the consumed OTP would be rejected.
      _redirectIfAlreadyPickedUp();
    });
    // Enable PiP auto-entry when user leaves the app
    if (Platform.isAndroid) {
      PipService.updatePipStatus(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid) {
      PipService.updatePipStatus(false);
    }
    RideLocationPublisher().stop();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;
    if (state == AppLifecycleState.inactive) {
      // App going to background — enter PiP
      PipService.enterPip();
    }
  }

  /// Vehicle glyph for the rider's own marker — the same asset the customer
  /// sees tracking this ride, so the vehicle looks identical on both sides.
  BitmapDescriptor? _riderIcon;

  /// Pin for the pickup marker — a place, so a pin, not a glyph. The app's own
  /// marker asset rather than Google's default teardrop.
  BitmapDescriptor? _customerIcon;

  Future<void> _loadMarkerIcons() async {
    try {
      // Both from the app's own assets: a vehicle glyph for the rider (which
      // moves and has a heading), a plain pin for the pickup (which doesn't).
      final rider = await getBytesFromSvgAsset('assets/svg/2_wheeler.svg', kVehicleMarkerSize);
      final pickup = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 40)),
        AppImageAssets.locationMarkerIcon,
      );
      if (!mounted) return;
      setState(() {
        if (rider.isNotEmpty) _riderIcon = BitmapDescriptor.bytes(rider);
        _customerIcon = pickup;
        // Re-stamp the markers already on the map with their icons.
        _restampMarker('rider', _riderIcon, flat: true);
        _restampMarker('pickup', _customerIcon);
      });
    } catch (_) {
      // Keep the default markers — a missing glyph must not blank the map.
    }
  }

  void _restampMarker(String id, BitmapDescriptor? icon, {bool flat = false}) {
    if (icon == null) return;
    final existing = _markers
        .where((m) => m.markerId.value == id)
        .cast<Marker?>()
        .firstWhere((_) => true, orElse: () => null);
    if (existing == null) return;
    _markers.remove(existing);
    _markers.add(existing.copyWith(iconParam: icon, flatParam: flat));
  }

  void _setupMarkers() {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderLatLng,
        icon: _riderIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        icon: _customerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickupLocation),
      ),
    ]);
  }

  /// Streams the rider's live GPS location and moves the 'rider' marker + the
  /// camera to follow it, so the map tracks the rider as they travel to the
  /// pickup (previously the marker stayed frozen at the initial fix).
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'rider');
        _markers.add(
          Marker(
            markerId: const MarkerId('rider'),
            position: newPos,
            icon: _riderIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
            // flat so `rotation` points the vehicle along the heading rather
            // than tipping a pin over.
            flat: true,
            rotation: position.heading,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      });
      // Push the position to the map-service so the customer's live-tracking
      // map follows the rider on the way to pickup. Throttling/heartbeat/retry
      // live in the publisher.
      RideLocationPublisher().updatePosition(newPos.latitude, newPos.longitude);
      // Gently follow the rider.
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
    });
  }

  Future<void> _fetchRoute() async {
    try {
      final polylinePoints = PolylinePoints(apiKey: googleMapKey);
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_riderLatLng.latitude, _riderLatLng.longitude),
          destination:
              PointLatLng(_pickupLatLng.latitude, _pickupLatLng.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        _routeCoords = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        final routeCoords = _routeCoords;

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('to_pickup'),
              points: routeCoords,
              width: 5,
              color: const Color(0xFF4285F4),
              geodesic: true,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        });

        _fitBounds(_riderLatLng, _pickupLatLng);
      }
    } catch (_) {}
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

  /// Looks the current order up in the rider-orders controller and, if it is
  /// already `picked-up`/`completed` (OTP consumed on a previous verify),
  /// skips OTP entry and jumps straight to the destination screen. This stops
  /// the pickup/OTP sheet from re-appearing — and re-prompting for an OTP the
  /// server would now reject — after the rider comes back to this screen.
  void _redirectIfAlreadyPickedUp() {
    if (widget.orderId.isEmpty) return;
    if (!Get.isRegistered<DeliverPartnerOrdersController>()) return;
    final ctrl = Get.find<DeliverPartnerOrdersController>();

    RiderOrdersDetailsModel? match;
    for (final list in <List<RiderOrdersDetailsModel>>[
      ctrl.onGoingOrders,
      ctrl.riderOrdersDetailsModel,
      ctrl.completedOrders,
    ]) {
      for (final o in list) {
        // widget.orderId is the Mongo _id (what the fare endpoints use), so
        // match on the model's `id`, not the human 'ORD-…' orderId.
        if (o.id == widget.orderId) {
          match = o;
          break;
        }
      }
      if (match != null) break;
    }

    // After the pickup OTP the ride order becomes 'in-progress' (parcel/goods
    // may report 'picked-up'); both — plus 'completed' — mean the OTP is
    // already consumed, so skip OTP entry and go straight to the destination.
    final status = match?.status;
    if (status == 'in-progress' ||
        status == 'picked-up' ||
        status == 'completed') {
      if (!mounted) return;
      _otpVerified = true;
      _startRide();
    }
  }

  /// Resolves the Mongo order id the fare endpoints expect, trying in order:
  ///   1. [widget.orderId] (threaded from the order card / PiP mini-card),
  ///   2. the fare-call CallController capture (incoming-call flow),
  ///   3. the live orders controller — matched to THIS pickup by the customer
  ///      id, or the single not-yet-picked-up ongoing order.
  ///
  /// Step 3 is what recovers the id when the screen is re-opened through the
  /// PiP / floating overlay, where widget.orderId can arrive empty.
  String _resolveOrderId() {
    if (widget.orderId.isNotEmpty) return widget.orderId;

    if (Get.isRegistered<CallController>()) {
      final cc = Get.find<CallController>();
      if (cc.fareCallOrderMongoId.value.isNotEmpty) {
        return cc.fareCallOrderMongoId.value;
      }
      if (cc.fareCallOrderId.value.isNotEmpty) {
        return cc.fareCallOrderId.value;
      }
    }

    if (Get.isRegistered<DeliverPartnerOrdersController>()) {
      final ctrl = Get.find<DeliverPartnerOrdersController>();
      // Only orders still awaiting the pickup OTP are valid candidates.
      final candidates = ctrl.onGoingOrders
          .where((o) =>
              o.status == 'accepted' ||
              o.status == 'confirmed' ||
              o.status == 'payment-pending')
          .toList();

      // Prefer the one for this customer; otherwise, if there's exactly one
      // pending pickup, it must be this one.
      RiderOrdersDetailsModel? match;
      if (widget.customerUserId.isNotEmpty) {
        for (final o in candidates) {
          if (o.user?.id == widget.customerUserId) {
            match = o;
            break;
          }
        }
      }
      match ??= candidates.length == 1 ? candidates.first : null;
      if (match != null) return match.id ?? '';
    }

    return '';
  }

  Future<void> _verifyOtp() async {
    // Trim each digit — FilteringTextInputFormatter strips non-digits but
    // belt-and-braces guards against stray whitespace / invisible chars
    // from paste actions that would make the server reject a visually
    // correct OTP.
    final entered = _otpControllers.map((c) => c.text.trim()).join();
    if (entered.length < 4) return;

    // Resolve the server-side order id — see [_resolveOrderId]. Some entry
    // paths (PiP / floating-overlay re-entry) lose widget.orderId, so we
    // recover it from the live orders controller before falling back to the
    // local OTP compare.
    final String orderId = _resolveOrderId();

    debugPrint(
        '[PICKUP_OTP] verifying entered=$entered orderId=$orderId widgetOtp=${widget.otp}');

    if (orderId.isEmpty) {
      // Only trust the local fallback when the caller actually supplied a
      // real OTP to compare against. Previously an empty widget.otp plus
      // empty widget.orderId silently rejected every correct code.
      if (widget.otp.isNotEmpty) {
        if (entered == widget.otp.trim()) {
          setState(() {
            _otpVerified = true;
            _otpError = false;
          });
          HapticFeedback.mediumImpact();
          _autoStartRideAfterVerify();
        } else {
          _handleOtpError();
        }
      } else {
        commonSnackBar(
            message: 'Unable to verify OTP: missing order reference.');
        _handleOtpError();
      }
      return;
    }

    // Call the API to verify pickup OTP
    final controller = Get.put(DeliverPartnerOrdersController());
    final success = await controller.verifyPickupOtpRideOrParcelApi(
      {ApiKeys.pickupOTP: entered},
      orderId,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _otpVerified = true;
        _otpError = false;
      });
      HapticFeedback.mediumImpact();
      _autoStartRideAfterVerify();
    } else {
      _handleOtpError();
    }
  }

  /// After OTP verification succeeds, briefly show the "Verified" state then
  /// auto-navigate to the ride screen so the rider doesn't have to tap
  /// "Start Ride" manually.
  void _autoStartRideAfterVerify() {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _isStartingRide) return;
      _startRide();
    });
  }

  void _handleOtpError() {
    setState(() => _otpError = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
      setState(() => _otpError = false);
    });
  }

  Future<void> _handleCallCustomer() async {
    if (widget.customerUserId.isEmpty) {
      commonSnackBar(message: 'Customer contact not available');
      return;
    }
    final callController = Get.find<CallController>();

    // Minimise the pickup screen into the floating PiP overlay so the ride /
    // OTP context is preserved while the call UI takes over. When the call
    // ends we restore this screen so the rider lands back on OTP entry.
    _minimiseToOverlay();

    final success = await callController.initiateCall(
      type: CallType.audio,
      otherUserId: widget.customerUserId,
      userName: widget.customerName,
      userImage: widget.customerImage,
    );
    if (!success) {
      _restorePickupScreenFromOverlay();
      return;
    }

    late final Worker callStatusWorker;
    callStatusWorker = ever<CallStatus>(callController.callStatus, (status) {
      if (status == CallStatus.idle || status == CallStatus.ended) {
        callStatusWorker.dispose();
        _restorePickupScreenFromOverlay();
      }
    });
  }

  /// After a customer call ends, bring the pickup/OTP screen back in front
  /// using the params captured in the overlay controller, then clear the
  /// overlay so it isn't left dangling on top of the restored screen.
  void _restorePickupScreenFromOverlay() {
    if (!Get.isRegistered<RideNavigationOverlayController>()) return;
    final overlayCtrl = Get.find<RideNavigationOverlayController>();
    if (overlayCtrl.screenType.value != 'pickup' ||
        overlayCtrl.screenParams.isEmpty) {
      return;
    }
    final p = Map<String, dynamic>.from(overlayCtrl.screenParams);
    overlayCtrl.hideOverlay();
    Get.to(() => RiderPickupNavigationScreen(
          pickupLocation: p['pickupLocation'] ?? '',
          dropLocation: p['dropLocation'] ?? '',
          pickupLat: (p['pickupLat'] as num?)?.toDouble() ?? 0,
          pickupLng: (p['pickupLng'] as num?)?.toDouble() ?? 0,
          dropLat: (p['dropLat'] as num?)?.toDouble() ?? 0,
          dropLng: (p['dropLng'] as num?)?.toDouble() ?? 0,
          fareAmount: (p['fareAmount'] as num?)?.toDouble() ?? 0,
          distanceKm: (p['distanceKm'] as num?)?.toDouble() ?? 0,
          customerName: p['customerName'] ?? '',
          customerImage: p['customerImage'] ?? '',
          otp: p['otp'] ?? '',
          paymentMethod: p['paymentMethod'] ?? 'Cash',
          orderId: p['orderId'] ?? '',
          customerUserId: p['customerUserId'] ?? '',
        ));
  }

  void _minimiseToOverlay() {
    final overlayCtrl = Get.put(RideNavigationOverlayController());
    // Once the pickup OTP is verified the order is already `picked-up` and the
    // OTP is consumed — re-opening the pickup/OTP screen would let the rider
    // re-submit it, which the server now rejects ("OTP incorrect"). So after
    // verification we minimise as the DESTINATION leg ('ride' → drop): both the
    // floating mini-map and any re-entry then land on the destination screen,
    // never back on OTP entry.
    final verified = _otpVerified;
    overlayCtrl.showOverlay(
      riderLatVal: _riderLatLng.latitude,
      riderLngVal: _riderLatLng.longitude,
      destLatVal: verified ? widget.dropLat : _pickupLatLng.latitude,
      destLngVal: verified ? widget.dropLng : _pickupLatLng.longitude,
      destLabelVal: verified ? widget.dropLocation : widget.pickupLocation,
      customerNameVal: widget.customerName,
      fareAmountVal: widget.fareAmount,
      routePoints: verified ? const [] : _routeCoords,
      type: verified ? 'ride' : 'pickup',
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
        'customerUserId': widget.customerUserId,
        'otp': widget.otp,
        'paymentMethod': widget.paymentMethod,
        'orderId': widget.orderId,
      },
    );

    // Popping is only safe when something is underneath. Accepting a ride from
    // a notification replaces the incoming screen (`Get.off`), so when the app
    // was launched BY that notification this is the only route on the stack —
    // an unguarded pop then empties the navigator and the app goes black with
    // the floating mini-map its sole surviving UI. Land on the rider dashboard
    // instead, which is where minimising is meant to leave the rider anyway.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.offAllNamed(RouteHelper.getRiderServiceScreenRoute());
    }
  }

  void _startRide() {
    setState(() => _isStartingRide = true);
    // Pickup OTP verified — move to the destination screen (rider carries the
    // passenger from pickup → drop): live map + fare + slide-to-complete.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PassengerDestinationScreen(
          pickupLocation: widget.pickupLocation,
          dropLocation: widget.dropLocation,
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          dropLat: widget.dropLat,
          dropLng: widget.dropLng,
          fareAmount: widget.fareAmount,
          distanceKm: widget.distanceKm,
          customerName: widget.customerName,
          customerImage: widget.customerImage,
          paymentMethod: widget.paymentMethod,
          orderId: widget.orderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimiseToOverlay();
      },
      child: Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _riderLatLng,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              // Fit after map ready
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitBounds(_riderLatLng, _pickupLatLng);
              });
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Recenter button
          Positioned(
            right: 16,
            bottom: 340,
            child: _buildRecenterButton(),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button — minimise to floating mini-map
              GestureDetector(
                onTap: _minimiseToOverlay,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Heading
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Heading to Pickup',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${widget.fareAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853),
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: () => _fitBounds(_riderLatLng, _pickupLatLng),
      child: Container(
        width: 46,
        height: 46,
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
        child: const Icon(Icons.my_location_rounded,
            color: Color(0xFF4285F4), size: 22),
      ),
    );
  }

  Widget _buildBottomPanel() {
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
          // Handle bar
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

          // Customer info + pickup address
          _buildCustomerPickupInfo(),

          const SizedBox(height: 20),

          // OTP section
          _buildOtpSection(),

          const SizedBox(height: 20),

          // Start Ride button (visible only after OTP verified)
          if (_otpVerified) _buildStartRideButton(),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildCustomerPickupInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Customer avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F0F0),
              border: Border.all(
                color: const Color(0xFF00C853).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: widget.customerImage.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.customerImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF9E9E9E),
                          size: 26),
                    ),
                  )
                : const Icon(Icons.person_rounded,
                    color: Color(0xFF9E9E9E), size: 26),
          ),
          const SizedBox(width: 14),
          // Name + pickup
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Color(0xFF00C853), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.pickupLocation,
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
          // Call / navigate buttons
          GestureDetector(
            onTap: _handleCallCustomer,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_rounded,
                  color: Color(0xFF00C853), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Label
          Row(
            children: [
              Icon(
                _otpVerified
                    ? Icons.check_circle_rounded
                    : Icons.pin_rounded,
                color: _otpVerified
                    ? const Color(0xFF00C853)
                    : _otpError
                        ? const Color(0xFFEA4335)
                        : const Color(0xFF1A1A2E),
                size: 20,
              ),
              const SizedBox(width: 8),
              // Flexible so the label ellipsizes instead of overflowing when
              // this section is rendered in the narrow PIP (mini call) view.
              Flexible(
                child: Text(
                  _otpVerified
                      ? 'OTP Verified'
                      : 'Enter 4-digit OTP from customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                    color: _otpVerified
                        ? const Color(0xFF00C853)
                        : _otpError
                            ? const Color(0xFFEA4335)
                            : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // OTP input boxes — the 4 fixed-width boxes total ~272px, so wrap in
          // a scale-down FittedBox so they shrink to fit the narrow PIP view
          // (no-op at full width).
          if (!_otpVerified)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildOtpBox(index)),
              ),
            ),
          if (_otpVerified)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00C853), size: 32),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'OTP ${_otpControllers.map((c) => c.text).join()} verified',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00C853),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final hasError = _otpError;

    return Container(
      width: 56,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'OpenSans',
          color: hasError ? const Color(0xFFEA4335) : const Color(0xFF1A1A2E),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasError
              ? const Color(0xFFEA4335).withValues(alpha: 0.05)
              : const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFEA4335)
                  : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFEA4335)
                  : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFEA4335)
                  : const Color(0xFF4285F4),
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          // Auto-verify when all 4 digits entered
          if (index == 3 && value.isNotEmpty) {
            _verifyOtp();
          }
          // Handle backspace on empty
          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildStartRideButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isStartingRide ? null : _startRide,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFF00C853).withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isStartingRide
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Start Ride',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
