import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../environment_config.dart';
import '../../../../common/Discover/controller/rider_location_poll_controller.dart';
import '../../call_screen/rider_call/ride_navigation_overlay_controller.dart';

class TrackRiderLiveLocationPage extends StatefulWidget {
  const TrackRiderLiveLocationPage(
      {super.key,
      required this.riderId,
      required this.dropLat,
      required this.dropLng,
      this.orderId,
      this.minimiseToPip = true});

  final double dropLat;
  final double dropLng;
  final String riderId;
  final String? orderId;

  /// Whether backing out of this page raises the floating mini-map.
  ///
  /// True for the chat/orders flow, where this page is the top of its stack and
  /// there is nothing underneath to fall back to. False when pushed from the
  /// ride-booking flow's tracking screen: there IS a screen underneath, so back
  /// should simply return to it — raising a PiP over a full-screen ride detail
  /// is noise, and the PiP belongs to backing out of THAT screen.
  final bool minimiseToPip;

  @override
  State<TrackRiderLiveLocationPage> createState() =>
      _TrackRiderLiveLocationPageState();
}

class _TrackRiderLiveLocationPageState
    extends State<TrackRiderLiveLocationPage> {
  final orderController = Get.put(RiderLocationPollController());

  @override
  void initState() {
    // Poll the rider's live location on the order (10s). Keyed on orderId; the
    // launcher/overlay now forward it. Falls back to empty (no poll) if absent.
    orderController.startPolling(widget.orderId ?? '');
    // rideCompleted flips when the poll returns rideActive:false.
    _listenForCompletion();
    super.initState();
  }

  @override
  void dispose() {
    // Stop the 10s poll and release the controller (the old SSE version leaked
    // it — the timer would otherwise keep hitting the server after this page
    // is gone). Minimise-to-overlay shows last-known position; re-opening
    // restarts the poll.
    orderController.stopPolling();
    if (Get.isRegistered<RiderLocationPollController>()) {
      Get.delete<RiderLocationPollController>();
    }
    super.dispose();
  }

  void _listenForCompletion() {
    // Watch if live location stops (stream closed = ride likely completed)
    ever(orderController.rideCompleted, (completed) {
      if (completed && mounted) {
        commonSnackBar(message: 'Ride has been completed!');
        // Navigate back after a brief moment
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  /// Back press keeps the tracking session alive and shrinks it into the
  /// app-wide draggable floating mini-map (same overlay used by the rider
  /// navigation screens), so the user can move around the app while the ride
  /// keeps updating. Tapping the mini-map re-opens this page.
  void _minimiseToOverlay() {
    // Pushed over a screen that already owns this ride — just go back to it.
    // The PiP is raised by backing out of THAT screen, not this one.
    if (!widget.minimiseToPip) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    final overlayCtrl = Get.put(RideNavigationOverlayController());
    overlayCtrl.showOverlay(
      riderLatVal: orderController.liveLat.value,
      riderLngVal: orderController.liveLng.value,
      destLatVal: widget.dropLat,
      destLngVal: widget.dropLng,
      destLabelVal: '',
      customerNameVal: AppStrings.trackYourRider.tr,
      fareAmountVal: 0,
      routePoints: const [],
      type: 'track_rider',
      params: {
        'riderId': widget.riderId,
        'dropLat': widget.dropLat,
        'dropLng': widget.dropLng,
        'orderId': widget.orderId ?? '',
      },
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimiseToOverlay();
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.trackYourRider,
          onBackTap: _minimiseToOverlay,
        ),
        body: Obx(() {
          if ((orderController.liveLng.value == 0) ||
              (orderController.liveLat.value == 0)) {
            return Center(
              child: CustomText(AppStrings.findingRiderLocation),
            );
          } else {
            return SimpleGoogleMapsTracking(
              startLng: orderController.liveLng.value,
              startLat: orderController.liveLat.value,
              endLat: widget.dropLat,
              endLng: widget.dropLng,
            );
          }
        }),
      ),
    );
  }
}

class SimpleGoogleMapsTracking extends StatefulWidget {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  const SimpleGoogleMapsTracking({
    super.key,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  @override
  State<SimpleGoogleMapsTracking> createState() => _SimpleGoogleMapsTrackingState();
}

class _SimpleGoogleMapsTrackingState extends State<SimpleGoogleMapsTracking> {
  List<LatLng> polylineCoordinates = []; // Store road points here
  GoogleMapController? mapController;
  Marker? startMarker;
  Marker? endMarker;

  /// Vehicle glyph for [startMarker], built once from the shared SVG.
  BitmapDescriptor? _riderIcon;
  Set<Polyline> _polylines = {};
  Circle? liveLocationCircle;
  final riderController = Get.find<RiderLocationPollController>();

  StreamSubscription<Position>? positionStream;
  LatLng? currentPosition;

  /// The road route currently drawn, rider → drop. Held as coordinates (rather
  /// than only as a [Polyline]) so the passed-behind portion can be trimmed as
  /// the rider advances without going back to the network.
  List<LatLng> _routeCoords = const [];

  /// Guards against re-entering the Directions call while one is in flight —
  /// the poll ticks every 10 s and a slow response would otherwise stack up.
  bool _fetchingRoute = false;

  /// Whether the camera should keep following the rider.
  ///
  /// Turns off the moment the user pans the map: yanking the viewport back
  /// every 10 s makes it impossible to look ahead down the route. The recenter
  /// button turns it back on.
  bool _followRider = true;

  /// True while WE are animating the camera, so [_followRider] isn't cancelled
  /// by our own move — `onCameraMoveStarted` can't tell the two apart.
  bool _programmaticCamera = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();

    ever(riderController.liveLat, (_) => _updateRiderOnMap());
    ever(riderController.liveLng, (_) => _updateRiderOnMap());

  }

  /// False when the caller had no drop coordinates — e.g. tracking opened from
  /// a notification for an order this session never booked. The rider is still
  /// worth showing; routing to `0,0` is not.
  bool get _hasDestination => widget.endLat != 0 || widget.endLng != 0;

  Future<void> _getRoutePolyline() async {
    final riderLat = riderController.liveLat.value;
    final riderLng = riderController.liveLng.value;

    if (riderLat == 0 || riderLng == 0) return;
    if (!_hasDestination) return;
    if (_fetchingRoute) return;
    _fetchingRoute = true;

    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: googleMapKey);

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(riderLat, riderLng), // 🔥 LIVE rider location
          destination: PointLatLng(widget.endLat, widget.endLng),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        _setRoute(result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList());
      } else {
        print("NO ROUTE FOUND: ${result.errorMessage}");
      }
    } finally {
      _fetchingRoute = false;
    }
  }

  void _setRoute(List<LatLng> coords) {
    if (!mounted) return;
    setState(() {
      _routeCoords = coords;
      _polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: coords,
          width: 6,
          color: Colors.blue,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    });
  }

  /// Keeps the drawn route in step with the rider WITHOUT a network call.
  ///
  /// The route only becomes wrong when the rider leaves it; while they're
  /// following it, the only change needed is dropping the stretch already
  /// driven. So this trims the polyline to the nearest remaining point and
  /// re-fetches only on a real deviation — turning a Directions request every
  /// 10 s (for the whole trip) into one per wrong turn.
  void _syncRouteToRider(LatLng rider) {
    if (!_hasDestination) return;
    if (_routeCoords.length < 2) {
      _getRoutePolyline();
      return;
    }

    var nearestIndex = 0;
    var nearestMetres = double.infinity;
    for (var i = 0; i < _routeCoords.length; i++) {
      final metres = Geolocator.distanceBetween(
        rider.latitude,
        rider.longitude,
        _routeCoords[i].latitude,
        _routeCoords[i].longitude,
      );
      if (metres < nearestMetres) {
        nearestMetres = metres;
        nearestIndex = i;
      }
    }

    // Off-route (wrong turn, diversion, or a GPS jump) → the drawn line no
    // longer describes the journey, so get a fresh one.
    if (nearestMetres > _routeDeviationMetres) {
      _getRoutePolyline();
      return;
    }

    // On route — drop what's already been driven so the line shortens ahead of
    // the rider instead of trailing behind them.
    if (nearestIndex > 0) {
      _setRoute(_routeCoords.sublist(nearestIndex));
    }
  }

  /// How far off the drawn route the rider may stray before it is re-fetched.
  /// Wide enough to absorb GPS scatter and dual-carriageway offsets, tight
  /// enough to catch an actual wrong turn.
  static const double _routeDeviationMetres = 80;




  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getRoutePolyline(); // Call the road-fetching function here
    _loadRiderIcon();
    _addInitialMarkers();
  }

  /// Two-wheeler glyph for the rider marker — matches the customer's pre-pickup
  /// tracking screen, so the same vehicle doesn't change shape when the ride
  /// starts. Falls back to the default pin if the SVG can't be rendered.
  Future<void> _loadRiderIcon() async {
    try {
      final bytes = await getBytesFromSvgAsset('assets/svg/2_wheeler.svg', kVehicleMarkerSize);
      if (!mounted || bytes.isEmpty) return;
      setState(() {
        _riderIcon = BitmapDescriptor.bytes(bytes);
        startMarker = startMarker?.copyWith(iconParam: _riderIcon);
      });
    } catch (_) {
      // Keep the default marker.
    }
  }

  void _addInitialMarkers() {
    setState(() {
      startMarker = Marker(
        markerId: const MarkerId('rider_marker'),
        position: LatLng(widget.startLat, widget.startLng),
        icon: _riderIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        // Centred + flat: a vehicle sits ON the road, it doesn't hang above a
        // point like a pin.
        anchor: const Offset(0.5, 0.5),
        flat: true,
      );
      endMarker = _hasDestination
          ? Marker(
              markerId: const MarkerId('drop_marker'),
              position: LatLng(widget.endLat, widget.endLng),
            )
          : null;
    });
  }

  Future<void> _updateRiderOnMap() async {
    final newLat = riderController.liveLat.value;
    final newLng = riderController.liveLng.value;
    if (newLat == 0 || newLng == 0) return;

    final newPosition = LatLng(newLat, newLng);

    setState(() {
      startMarker = startMarker?.copyWith(positionParam: newPosition);
    });

    // Trim the drawn route to what's left; only re-fetches when the rider has
    // actually left it.
    _syncRouteToRider(newPosition);

    // Follow only while the user hasn't taken the map over.
    if (_followRider) _moveCamera(newPosition);
  }

  Future<void> _moveCamera(LatLng target) async {
    final controller = mapController;
    if (controller == null) return;
    _programmaticCamera = true;
    await controller.animateCamera(CameraUpdate.newLatLng(target));
  }

  /// Re-attaches the camera to the rider after the user has panned away.
  void _recenterOnRider() {
    final lat = riderController.liveLat.value;
    final lng = riderController.liveLng.value;
    setState(() => _followRider = true);
    if (lat == 0 || lng == 0) return;
    _moveCamera(LatLng(lat, lng));
  }



  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateLiveLocation(position);
    });
  }

  Future<void> _updateLiveLocation(Position position) async {
    if (mapController == null) return;

    currentPosition = LatLng(position.latitude, position.longitude);

    try {
    setState(() {
      liveLocationCircle = Circle(
        circleId: CircleId('live_location_circle'),
        center: currentPosition!,
        radius: 15.0,
        fillColor: Colors.blue.withValues(alpha: 0.5),
        strokeColor: Colors.white,
        strokeWidth: 3,
      );
    });
    } catch (e) {
      print('Error updating live location: $e');
    }
  }

  // Future<void> _addInitialMarkersAndPolyline() async {
  //   final start = LatLng(widget.startLat, widget.startLng);
  //   final end = LatLng(widget.endLat, widget.endLng);
  //
  //   setState(() {
  //     startMarker = Marker(
  //       markerId: MarkerId('start_marker'),
  //       position: start,
  //     );
  //     endMarker = Marker(
  //       markerId: MarkerId('end_marker'),
  //       position: end,
  //     );
  //     polyline = Polyline(
  //       polylineId: PolylineId('route_polyline'),
  //       points: [start, end],
  //       color: Colors.blue,
  //       width: 5,
  //     );
  //   });
  // }



  // Future<void> _fitBounds() async {
  //   if (mapController == null || startMarker == null || endMarker == null) return;
  //
  //   final LatLng southwest = LatLng(
  //     widget.startLat < widget.endLat ? widget.startLat : widget.endLat,
  //     widget.startLng < widget.endLng ? widget.startLng : widget.endLng,
  //   );
  //   final LatLng northeast = LatLng(
  //     widget.startLat > widget.endLat ? widget.startLat : widget.endLat,
  //     widget.startLng > widget.endLng ? widget.startLng : widget.endLng,
  //   );
  //
  //   final LatLngBounds bounds = LatLngBounds(southwest: southwest, northeast: northeast);
  //
  //   mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  // }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.startLat, widget.startLng),
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          // A user pan releases the camera from the rider; our own animations
          // are flagged so they don't count as one.
          onCameraMoveStarted: () {
            if (_programmaticCamera) return;
            if (_followRider) setState(() => _followRider = false);
          },
          onCameraIdle: () => _programmaticCamera = false,
          markers: {
            if (startMarker != null) startMarker!,
            if (endMarker != null) endMarker!,
          },
          polylines: _polylines, // 🔥 THIS WILL SHOW REAL ROAD ROUTE
          circles: {
            if (liveLocationCircle != null) liveLocationCircle!,
          },
        ),
        // Only offered once the camera has been released — while following, it
        // would do nothing.
        if (!_followRider)
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton.small(
              heroTag: 'recenter_rider',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              onPressed: _recenterOnRider,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    "Rider is ${(_calculateTotalDistance()).toStringAsFixed(1)} km away",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  double _calculateTotalDistance() {
    // Prefer the server's authoritative drop distance from the poll; fall back
    // to a local straight-line calc until it arrives (both are haversine).
    final serverKm = riderController.distanceToDropKm.value;
    if (serverKm != null) return serverKm;

    // No drop coordinates to measure against — 0 renders as "—" rather than a
    // multi-thousand-km distance to the null island.
    if (!_hasDestination) return 0;

    // Calculate distance from rider to end point using Geolocator math
    final total = Geolocator.distanceBetween(
      riderController.liveLat.value,
      riderController.liveLng.value,
      widget.endLat,
      widget.endLng,
    );
    return total / 1000; // Convert meters to KM
  }
}
