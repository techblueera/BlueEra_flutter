import 'dart:async';

import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  void _updateRiderMarker({required double heading}) {
    final pos = _currentRiderPosition;
    if (pos == null) return;
    _markers.removeWhere((m) => m.markerId.value == 'rider_live');
    _markers.add(
      Marker(
        markerId: const MarkerId('rider_live'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
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
            ..removeWhere((p) => p.polylineId.value == 'ride_route')
            ..add(
              Polyline(
                polylineId: const PolylineId('ride_route'),
                points: _routeCoords,
                width: 5,
                color: const Color(0xFF00C853),
                geodesic: true,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );
        });
        _fitBounds(origin, _dropLatLng);
      }
    } catch (_) {
      // Route drawing is best-effort — the ride still works without a polyline.
    }
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      if (!mounted || _rideCompleted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentRiderPosition = newPos;
        _updateRiderMarker(heading: position.heading);
        _recomputeRemaining();
      });
      // Push the position to the map-service so the customer's live-tracking
      // map follows the rider. Throttling/heartbeat/retry live in the publisher.
      RideLocationPublisher().updatePosition(newPos.latitude, newPos.longitude);
      // Keep the camera gently following the rider.
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
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
    });
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
      },
    );
    Navigator.of(context).pop();
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
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentRiderPosition ?? _dropLatLng,
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
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fitBounds(
                      _currentRiderPosition ?? _dropLatLng, _dropLatLng);
                });
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopStatusBar(),
            ),
            Positioned(
              right: 16,
              bottom: 300,
              child: _buildRecenterButton(),
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
                  child: Text(
                    _rideCompleted ? 'Ride Completed' : 'Heading to destination',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: () => _fitBounds(
          _currentRiderPosition ?? _dropLatLng, _dropLatLng),
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
          Text(
            'You earned ₹${widget.fareAmount.toStringAsFixed(0)} for this trip',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
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
