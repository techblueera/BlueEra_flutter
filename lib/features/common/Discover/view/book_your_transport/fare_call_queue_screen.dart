import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/pip_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../chat/auth/controller/call_controller.dart';
import '../../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../../../chat/auth/controller/chat_view_controller.dart';
import '../../../../chat/auth/controller/live_trach_rider_controller.dart';
import '../../../../chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import '../../../bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../controller/discover_controller.dart';

/// Customer-side fare-call screen.
/// Phase 1: Calling UI with queue progress, call controls, ringing animation.
/// Phase 2: After rider accepts — map showing rider's live location heading to pickup.
class FareCallQueueScreen extends StatefulWidget {
  final String orderId;

  const FareCallQueueScreen({super.key, required this.orderId});

  @override
  State<FareCallQueueScreen> createState() => _FareCallQueueScreenState();
}

class _FareCallQueueScreenState extends State<FareCallQueueScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final discoverController = getOrPut(() => DiscoverController());
  late final CallController _callController;

  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Worker _queueAcceptedWorker;
  late Worker _queueExhaustedWorker;
  late Worker _callStatusWorker;
  Worker? _rideCompletedWorker;

  // Call timer
  Timer? _localTimer;
  int _localSeconds = 0;

  // Rider accepted state
  bool _riderAccepted = false;
  bool _rideCompleted = false;
  Map<String, dynamic>? _acceptedRiderInfo;

  // Map state (after rider accepted)
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _routeCoords = [];
  LiveTrachRiderController? _liveTrackController;
  Worker? _riderLatWorker;
  Worker? _riderLngWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Hide floating overlay after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<RideNavigationOverlayController>()) {
        Get.find<RideNavigationOverlayController>().hideOverlay();
      }
    });

    if (!Get.isRegistered<CallController>()) {
      Get.put(CallController(), permanent: true);
    }
    _callController = Get.find<CallController>();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Watch for ride accepted
    _queueAcceptedWorker =
        ever(discoverController.fareCallAcceptedRiderInfo, (riderInfo) {
      if (!mounted) return;
      if (riderInfo != null) {
        _onRiderAccepted(riderInfo);
      }
    });

    // Watch for queue exhausted (no riders)
    _queueExhaustedWorker =
        ever(discoverController.isFareCallInProgress, (inProgress) {
      if (!mounted) return;
      if (!inProgress &&
          discoverController.fareCallAcceptedRiderInfo.value == null) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Get.back();
        });
      }
    });

    // Watch call status for timer
    _callStatusWorker = ever(_callController.callStatus, (status) {
      if (!mounted) return;
      if (status == CallStatus.connected) {
        _startLocalTimer();
      }
      if (status == CallStatus.idle || status == CallStatus.ended) {
        _localTimer?.cancel();
      }
    });

    // Watch for ride completed
    _rideCompletedWorker =
        ever(discoverController.isFareCallRideCompleted, (completed) {
      if (!mounted || !completed) return;
      _liveTrackController?.dispose();
      _riderLatWorker?.dispose();
      _riderLngWorker?.dispose();
      setState(() => _rideCompleted = true);
    });

    // If rider was already accepted (e.g. returning from floating overlay),
    // restore map state directly.
    final existingRiderInfo = discoverController.fareCallAcceptedRiderInfo.value;
    if (existingRiderInfo != null && !_riderAccepted) {
      _riderAccepted = true;
      _acceptedRiderInfo = existingRiderInfo;

      if (Platform.isAndroid) {
        PipService.updatePipStatus(true);
      }

      final riderId = discoverController.fareCallAcceptedRiderId.value;
      if (riderId.isNotEmpty) {
        _liveTrackController = Get.put(LiveTrachRiderController());
        _liveTrackController!.fetchStream(riderId);
        _riderLatWorker = ever(_liveTrackController!.liveLat, (_) => _updateRiderOnMap());
        _riderLngWorker = ever(_liveTrackController!.liveLng, (_) => _updateRiderOnMap());
      }

      _setupPickupMarker();
    }
  }

  void _onRiderAccepted(Map<String, dynamic> riderInfo) {
    // Rider accepted the ride order (after speaking on call).
    // End the call first, then switch to map view.
    _callController.endCall();
    _localTimer?.cancel();

    setState(() {
      _riderAccepted = true;
      _acceptedRiderInfo = riderInfo;
    });

    // Enable PiP for map phase
    if (Platform.isAndroid) {
      PipService.updatePipStatus(true);
    }

    // Start tracking rider's live location
    final riderId = discoverController.fareCallAcceptedRiderId.value;
    if (riderId.isNotEmpty) {
      _liveTrackController = Get.put(LiveTrachRiderController());
      _liveTrackController!.fetchStream(riderId);

      _riderLatWorker = ever(_liveTrackController!.liveLat, (_) => _updateRiderOnMap());
      _riderLngWorker = ever(_liveTrackController!.liveLng, (_) => _updateRiderOnMap());
    }

    // Setup initial markers for customer pickup location
    _setupPickupMarker();
  }

  void _setupPickupMarker() {
    final pickupLat = discoverController.selectedFromLat?.value ?? 0.0;
    final pickupLng = discoverController.selectedFromLong?.value ?? 0.0;
    if (pickupLat == 0.0 && pickupLng == 0.0) return;

    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Your Pickup',
          snippet: discoverController.selectedFromAddress?.value ?? '',
        ),
      ),
    );
  }

  void _updateRiderOnMap() {
    if (_liveTrackController == null) return;
    final riderLat = _liveTrackController!.liveLat.value;
    final riderLng = _liveTrackController!.liveLng.value;
    if (riderLat == 0.0 || riderLng == 0.0) return;

    final riderPos = LatLng(riderLat, riderLng);
    final pickupLat = discoverController.selectedFromLat?.value ?? 0.0;
    final pickupLng = discoverController.selectedFromLong?.value ?? 0.0;
    final pickupPos = LatLng(pickupLat, pickupLng);

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'rider');
      _markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: riderPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: _acceptedRiderInfo?['name'] ?? 'Rider',
          ),
        ),
      );
    });

    _fetchRoute(riderPos, pickupPos);
    _fitBounds(riderPos, pickupPos);
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final polylinePoints = PolylinePoints(apiKey: googleMapKey);
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(from.latitude, from.longitude),
          destination: PointLatLng(to.latitude, to.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        final routeCoords = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        _routeCoords = routeCoords;

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('rider_to_pickup'),
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

  double _calculateRiderDistance() {
    if (_liveTrackController == null) return 0.0;
    final riderLat = _liveTrackController!.liveLat.value;
    final riderLng = _liveTrackController!.liveLng.value;
    final pickupLat = discoverController.selectedFromLat?.value ?? 0.0;
    final pickupLng = discoverController.selectedFromLong?.value ?? 0.0;
    if (riderLat == 0.0 || riderLng == 0.0) return 0.0;

    final meters = geo.Geolocator.distanceBetween(
      riderLat, riderLng, pickupLat, pickupLng,
    );
    return meters / 1000;
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localSeconds = 0;
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _localSeconds++);
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid) {
      PipService.updatePipStatus(false);
    }
    _pulseController.dispose();
    _ringController.dispose();
    _queueAcceptedWorker.dispose();
    _queueExhaustedWorker.dispose();
    _callStatusWorker.dispose();
    _rideCompletedWorker?.dispose();
    _riderLatWorker?.dispose();
    _riderLngWorker?.dispose();
    _localTimer?.cancel();
    _mapController?.dispose();
    if (_liveTrackController != null && Get.isRegistered<LiveTrachRiderController>()) {
      Get.delete<LiveTrachRiderController>();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid || !_riderAccepted) return;
    if (state == AppLifecycleState.inactive) {
      PipService.enterPip();
    }
  }

  void _endCallAndGoBack() {
    _callController.endCall();
    discoverController.cancelFareCallQueue();
    discoverController.resetFareCallState();
    Get.back();
  }

  void _minimiseToOverlay() {
    final pickupLat = discoverController.selectedFromLat?.value ?? 0.0;
    final pickupLng = discoverController.selectedFromLong?.value ?? 0.0;
    final riderLat = _liveTrackController?.liveLat.value ?? 0.0;
    final riderLng = _liveTrackController?.liveLng.value ?? 0.0;

    final overlayCtrl = Get.put(RideNavigationOverlayController());
    overlayCtrl.showOverlay(
      riderLatVal: riderLat,
      riderLngVal: riderLng,
      destLatVal: pickupLat,
      destLngVal: pickupLng,
      destLabelVal: discoverController.selectedFromAddress?.value ?? 'Pickup',
      customerNameVal: _acceptedRiderInfo?['name'] ?? 'Rider',
      fareAmountVal: 0,
      routePoints: _routeCoords,
      type: 'customer_tracking',
      params: {
        'orderId': widget.orderId,
      },
    );
    // Pop all screens until the bottom navigation bar
    final bottomBarController = Get.put(BottomBarController());
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.selectedChatTabIndex.value=3;
    bottomBarController.onChangeIndex(3);
    Get.until((route) =>
        route.settings.name == '/BottomNavigationBarScreen' ||
        route.isFirst);

  }

  void _callRider() {
    final contact = _acceptedRiderInfo?['contact'] ?? '';
    if (contact.isNotEmpty) {
      launchUrl(Uri.parse('tel:$contact'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_riderAccepted) {
          _minimiseToOverlay();
        } else {
          _endCallAndGoBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B141A),
        body: _riderAccepted ? _buildMapScreen() : _buildCallingScreen(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP SCREEN (Phase 2 — rider accepted, show live tracking)
  // ─────────────────────────────────────────────

  Widget _buildMapScreen() {
    final pickupLat = discoverController.selectedFromLat?.value ?? 0.0;
    final pickupLng = discoverController.selectedFromLong?.value ?? 0.0;

    return Stack(
      children: [
        // Full-screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(pickupLat, pickupLng),
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
          },
        ),

        // Top bar — rider info + distance
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildMapTopBar(),
        ),

        // Recenter button
        Positioned(
          right: 16,
          bottom: 200,
          child: GestureDetector(
            onTap: () {
              if (_liveTrackController != null) {
                final riderLat = _liveTrackController!.liveLat.value;
                final riderLng = _liveTrackController!.liveLng.value;
                if (riderLat != 0.0 && riderLng != 0.0) {
                  _fitBounds(
                    LatLng(riderLat, riderLng),
                    LatLng(pickupLat, pickupLng),
                  );
                }
              }
            },
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
          ),
        ),

        // Bottom panel — call controls + ride info OR completed panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _rideCompleted
              ? _buildRideCompletedPanel()
              : _buildMapBottomPanel(),
        ),
      ],
    );
  }

  Widget _buildMapTopBar() {
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
              // Rider info card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rider on the way',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OpenSans',
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _acceptedRiderInfo?['name'] ?? 'Rider',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Distance badge
                      if (_liveTrackController != null)
                        Obx(() {
                          final dist = _calculateRiderDistance();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${dist.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          );
                        }),
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

  Widget _buildMapBottomPanel() {
    return Obx(() {
    final otp = discoverController.fareCallPickupOtp.value;
    final rideStarted = discoverController.isFareCallRideStarted.value;

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
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Rider info + call button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Rider avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF0F0F0),
                    border: Border.all(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: _acceptedRiderInfo?['profileImage'] != null &&
                          (_acceptedRiderInfo!['profileImage'] as String).isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _acceptedRiderInfo!['profileImage'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.delivery_dining_rounded,
                                color: Color(0xFF9E9E9E),
                                size: 26),
                          ),
                        )
                      : const Icon(Icons.delivery_dining_rounded,
                          color: Color(0xFF9E9E9E), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _acceptedRiderInfo?['name'] ?? 'Rider',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (_acceptedRiderInfo?['contact'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            _acceptedRiderInfo!['contact'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Call rider button
                GestureDetector(
                  onTap: _callRider,
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
          ),

          const SizedBox(height: 16),

          // Show OTP or Share Live Location based on ride started
          if (rideStarted)
            _buildShareRiderDetailsButton()
          else if (otp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_rounded,
                        color: Color(0xFF4285F4), size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Pickup OTP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'OpenSans',
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    // OTP digits
                    Row(
                      children: otp.split('').map((digit) {
                        return Container(
                          width: 32,
                          height: 38,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'OpenSans',
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Ride summary (pickup → drop)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Timeline dots
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7043),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discoverController.selectedFromAddress?.value ?? 'Pickup',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'OpenSans',
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        discoverController.selectedToAddress?.value ?? 'Drop',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'OpenSans',
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
    });
  }

  Widget _buildRideCompletedPanel() {
    final completedData = discoverController.fareCallRideCompletedData.value;
    final rideDetails = completedData?['rideDetails'] as Map<String, dynamic>? ?? {};
    final riderInfo = completedData?['riderInfo'] as Map<String, dynamic>? ?? {};

    final fare = rideDetails['fare'] ?? 0;
    final modeOfPayment = rideDetails['modeOfPayment'] ?? '';
    final orderFor = rideDetails['orderFor'] ?? '';
    final pickupAddress = rideDetails['pickup']?['address'] ?? '';
    final dropAddress = rideDetails['drop']?['address'] ?? '';
    final riderName = riderInfo['name'] ?? '';
    final riderContact = riderInfo['contact'] ?? '';
    final riderImage = riderInfo['profileImage'] ?? '';

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

          // Checkmark
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
            'You have arrived at your destination',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 20),

          // Rider info row
          if (riderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0F0F0),
                      border: Border.all(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: riderImage.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              riderImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF9E9E9E),
                                  size: 24),
                            ),
                          )
                        : const Icon(Icons.person_rounded,
                            color: Color(0xFF9E9E9E), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riderName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        if (riderContact.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              riderContact,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (riderName.isNotEmpty) const SizedBox(height: 16),

          // Fare & Payment summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '₹${(fare is num) ? fare.toStringAsFixed(0) : fare}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C853),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fare',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    children: [
                      Text(
                        modeOfPayment.toString().capitalizeFirst ?? modeOfPayment,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ),
                  if (orderFor.isNotEmpty) ...[
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Column(
                      children: [
                        Text(
                          orderFor,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA000),
                            fontFamily: 'OpenSans',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ride Type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pickup → Drop addresses
          if (pickupAddress.isNotEmpty || dropAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7043),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'OpenSans',
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          dropAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'OpenSans',
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Done button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  discoverController.resetFareCallState();
                  Get.until((route) =>
                      route.settings.name == '/BottomNavigationBarScreen' ||
                      route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
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

  Widget _buildShareRiderDetailsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00C853).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00C853), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ride Started — OTP Verified',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _shareRiderDetails,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text(
                  'Share Rider Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildRiderShareText() {
    final data = discoverController.fareCallRideStartedData.value;
    final riderInfo = data?['riderInfo'];
    final rideDetails = data?['rideDetails'];

    final riderName = riderInfo?['name'] ?? _acceptedRiderInfo?['name'] ?? 'Unknown';
    final riderContact = riderInfo?['contact'] ?? _acceptedRiderInfo?['contact'] ?? '';
    final dropAddress = rideDetails?['drop']?['address'] ??
        discoverController.selectedToAddress?.value ?? '';
    final pickupAddress = rideDetails?['pickup']?['address'] ??
        discoverController.selectedFromAddress?.value ?? '';

    return '🚗 Ride Safety Details\n\n'
        '👤 Rider: $riderName\n'
        '📞 Contact: $riderContact\n'
        '📍 Pickup: $pickupAddress\n'
        '📍 Drop: $dropAddress\n\n'
        'Shared via BlueEra for safety purposes.';
  }

  void _shareRiderDetails() {
    final shareText = _buildRiderShareText();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded,
                  color: Color(0xFF4285F4), size: 24),
              title: const Text(
                'Share within BlueEra',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'OpenSans',
                ),
              ),
              onTap: () {
                Get.back();
                Get.to(() => ChatForwardScreen(
                      sharedText: shareText,
                      stopChatNav: true,
                    ));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: Color(0xFF4285F4), size: 24),
              title: const Text(
                'Share externally',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'OpenSans',
                ),
              ),
              onTap: () async {
                Get.back();
                try {
                  await SharePlus.instance.share(
                    ShareParams(text: shareText),
                  );
                } catch (e) {
                  debugPrint('Share failed: $e');
                }
              },
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CALLING SCREEN (Phase 1 — before rider accepts)
  // ─────────────────────────────────────────────

  Widget _buildCallingScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A2E35),
            Color(0xFF0F1F27),
            Color(0xFF0B141A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildEncryptionLabel(),
            const SizedBox(height: 12),
            _buildQueueStatus(),
            const SizedBox(height: 8),
            _buildCallStatus(),
            const SizedBox(height: 8),
            _buildProgressDots(),
            Expanded(child: Center(child: _buildCallingAvatar())),
            _buildRideSummary(),
            const SizedBox(height: 24),
            _buildCallActions(),
            const SizedBox(height: 16),
            _buildEndCallButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded,
            color: Colors.white.withValues(alpha: 0.35), size: 13),
        const SizedBox(width: 4),
        Text(
          'End-to-end encrypted',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'OpenSans',
            color: Colors.white.withValues(alpha: 0.35),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueStatus() {
    return Obx(() {
      final index = discoverController.fareCallCurrentRiderIndex.value;
      final total = discoverController.fareCallTotalRiders.value;

      return Text(
        total > 0 ? 'Calling rider $index of $total' : 'Finding you a rider',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: 'OpenSans',
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      );
    });
  }

  Widget _buildCallStatus() {
    return Obx(() {
      final status = _callController.callStatus.value;
      final duration = _callController.callDurationSeconds.value;

      String text;
      Color color;

      if (status == CallStatus.connected) {
        final t = duration > 0 ? duration : _localSeconds;
        text = _formatTime(t);
        color = const Color(0xFF00C853);
      } else if (status == CallStatus.connecting ||
          status == CallStatus.accepting) {
        text = 'Connecting...';
        color = const Color(0xFF8696A0);
      } else if (status == CallStatus.outgoing ||
          status == CallStatus.ringing) {
        text = 'Ringing...';
        color = const Color(0xFF8696A0);
      } else {
        text = 'Calling...';
        color = const Color(0xFF8696A0);
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == CallStatus.connected)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF00C853),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProgressDots() {
    return Obx(() {
      final total = discoverController.fareCallTotalRiders.value;
      final current = discoverController.fareCallCurrentRiderIndex.value;
      if (total == 0) return const SizedBox(height: 8);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final isActive = i < current;
            final isCurrent = i == current - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCurrent
                    ? const Color(0xFF00C853)
                    : isActive
                        ? const Color(0xFFFF5252).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.15),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildCallingAvatar() {
    return Obx(() {
      final status = _callController.callStatus.value;
      final isConnected = status == CallStatus.connected;

      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isConnected)
                  for (int i = 0; i < 3; i++) _buildRippleRing(i),
                child!,
              ],
            ),
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A884).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFF2A3942),
            child: Icon(Icons.delivery_dining_rounded,
                size: 50, color: Color(0xFF8696A0)),
          ),
        ),
      );
    });
  }

  Widget _buildRippleRing(int index) {
    final delay = index * 0.33;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        double progress = (_pulseController.value + delay) % 1.0;
        double size = 120 + (progress * 100);
        double opacity = (1.0 - progress) * 0.4;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00A884).withValues(alpha: opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Obx(() {
          final from = discoverController.selectedFromAddress?.value ?? '';
          final to = discoverController.selectedToAddress?.value ?? '';

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C853),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7043),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from.isNotEmpty ? from : 'Pickup location',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      to.isNotEmpty ? to : 'Drop location',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCallActions() {
    return Obx(() {
      final isSpeakerOn = _callController.isSpeakerOn.value;
      final isConnected =
          _callController.callStatus.value == CallStatus.connected;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionBtn(
              icon: isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              label: 'Speaker',
              isActive: isSpeakerOn,
              onTap: () => _callController.toggleSpeaker(),
              enabled: isConnected,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF0B141A) : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCallAndGoBack,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFEA4335),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA4335).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.call_end_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            'End Call',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }
}
