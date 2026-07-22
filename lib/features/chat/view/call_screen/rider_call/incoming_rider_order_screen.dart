import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../environment_config.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../auth/controller/call_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/service/call_pip_service.dart';
import 'rider_pickup_navigation_screen.dart';

/// Incoming ride request screen for the rider.
/// Phase 1: Shows ride details with Accept/Reject buttons (ringing).
/// Phase 2: After accept — shows in-app call room with timer, speaker toggle,
///          then auto-navigates to RiderPickupNavigationScreen.
class IncomingRiderOrderScreen extends StatefulWidget {
  const IncomingRiderOrderScreen({super.key});

  @override
  State<IncomingRiderOrderScreen> createState() =>
      _IncomingRiderOrderScreenState();
}

class _IncomingRiderOrderScreenState extends State<IncomingRiderOrderScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _timerController;
  late Timer _countdownTimer;
  late Worker _callStatusWorker;
  int _remainingSeconds = 45;
  bool _isAccepting = false;

  // Call room state (after accepted)
  bool _isCallConnected = false;
  bool _isSpeakerOn = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;

  // Ride details extracted from CallController metadata
  late final CallController _callController;
  late final String _pickupAddress;
  late final String _dropAddress;
  late final double _pickupLat;
  late final double _pickupLng;
  late final double _dropLat;
  late final double _dropLng;
  late final double _fare;
  late final double _distance;
  late final String _customerName;
  late final String _customerImage;
  late final String _paymentMethod;
  // Job descriptor (ride | goods | parcel) — drives the call header/labels so
  // the rider immediately knows whether this is a passenger ride, a shop
  // goods pickup, or a parcel delivery. See the master integration guide §2.
  late final String _jobType;
  late final String _jobLabel;
  late final String _callTitle;
  late final String _riderTask;
  late final double _etaDistanceKm;
  late final double _etaDurationMin;
  /// True when this arrived via broadcast dispatch (`orderType: "broadcast"`).
  ///
  /// The difference is not cosmetic: a broadcast has **no VoIP call behind it**
  /// (guide §7.3 — no `call_id` is sent), so Accept must confirm the order
  /// directly instead of trying to answer a call that does not exist.
  late final bool _isBroadcast;

  /// `InCity | OutStation | HourlyRental | Parcel`.
  late final String _orderFor;

  /// Countdown length. The push carries `ttl_seconds` (20 for broadcast); the
  /// old hard-coded 45 outlived the offer and left the rider tapping Accept on
  /// a ride the server had already given away.
  late final int _totalSeconds;

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = const [];

  /// Road distance/duration of the pickup→drop leg, from the same Directions
  /// call that draws the polyline. The reply already carries both; they used to
  /// be discarded along with everything but `points`.
  double? _routeDistanceKm;
  double? _routeDurationMin;

  bool get _hasRouteCoordinates =>
      (_pickupLat != 0 || _pickupLng != 0) && (_dropLat != 0 || _dropLng != 0);

  /// Trip distance to show and to derive the per-km rate from.
  ///
  /// The payload's `distance` wins — that is what the fare was actually
  /// computed against. The measured route is a fallback for the payloads that
  /// omit it, which previously left the rider with no trip distance at all.
  double? get _effectiveDistanceKm {
    if (_distance > 0) return _distance;
    if ((_routeDistanceKm ?? 0) > 0) return _routeDistanceKm;
    return null;
  }

  /// The journey leg itself — "12.4 km · 28 min" — shown on the rail between
  /// PICKUP and DROP, which is where "how long is this trip" is actually asked.
  String? get _journeyLabel {
    final km = _effectiveDistanceKm;
    final minutes = _routeDurationMin;
    final parts = <String>[
      if (km != null) '${km.toStringAsFixed(1)} km',
      if (minutes != null && minutes > 0) '${minutes.round()} min',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Rate behind the fare — the number a rider actually judges a job by, and
  /// the one thing the payload never sends. Null when distance is unknown, so
  /// the row is hidden rather than showing a misleading ₹0/km.
  double? get _farePerKm {
    final km = _effectiveDistanceKm;
    return (km != null && km > 0 && _fare > 0) ? _fare / km : null;
  }

  String get _orderTypeLabel {
    switch (_orderFor.toLowerCase()) {
      case 'incity':
        return 'In city';
      case 'outstation':
        return 'Outstation';
      case 'hourlyrental':
        return 'Hourly rental';
      case 'parcel':
        return 'Parcel';
      default:
        return _orderFor;
    }
  }

  /// How far — and how long — the rider is from the pickup, when the push says.
  ///
  /// This is the deciding number for a rider weighing an offer: a ₹50 job is
  /// good at 1 km out and bad at 6, so it sits on the PICKUP row itself rather
  /// than in a chip further down.
  String? get _pickupDistanceLabel {
    final parts = <String>[
      if (_etaDistanceKm > 0) '${_etaDistanceKm.toStringAsFixed(1)} km away',
      if (_etaDurationMin > 0) '${_etaDurationMin.round()} min',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Heading for the offer. `jobLabel` ("Passenger ride") is the friendlier of
  /// the two; `callTitle` ("Incoming Ride Request") is the legacy fallback.
  String get _offerTitle {
    if (_jobLabel.isNotEmpty) return _jobLabel;
    if (_callTitle.isNotEmpty) return _callTitle;
    return 'New ride request';
  }

  @override
  void initState() {
    super.initState();

    _callController = Get.find<CallController>();
    final ride = _callController.fareCallRideDetails.value;
    _pickupAddress = ride?['pickup']?['address'] ?? 'Pickup location';
    _dropAddress = ride?['drop']?['address'] ?? 'Drop location';
    _pickupLat = _toDouble(ride?['pickup']?['lat']);
    _pickupLng = _toDouble(ride?['pickup']?['lng']);
    _dropLat = _toDouble(ride?['drop']?['lat']);
    _dropLng = _toDouble(ride?['drop']?['lng']);
    _fare = _toDouble(ride?['fare']);
    _distance = _toDouble(ride?['distance']);
    _customerName = _callController.callerName.value.isNotEmpty
        ? _callController.callerName.value
        : 'Customer';
    _customerImage = _callController.callerImage.value;
    _paymentMethod = ride?['modeOfPayment'] ?? 'postpaid';
    // Friendly job descriptor — fall back to raw orderFor / sensible defaults
    // for legacy payloads that don't carry the new fields.
    _jobType = ride?['jobType'] ?? 'ride'; // ride | goods | parcel
    _jobLabel = ride?['jobLabel'] ?? ride?['orderFor'] ?? 'Ride';
    _callTitle = ride?['callTitle'] ?? 'Incoming Ride Request';
    _riderTask = ride?['riderTask'] ?? '';
    _etaDistanceKm = _toDouble(ride?['eta']?['distanceKm']);
    _etaDurationMin = _toDouble(ride?['eta']?['durationMin']);
    _orderFor = (ride?['orderFor'] ?? '').toString();
    _isBroadcast =
        (ride?['orderType'] ?? '').toString().toLowerCase() == 'broadcast';
    final ttl = _toDouble(ride?['ttlSeconds']).round();
    _totalSeconds = ttl > 0 ? ttl : 45;
    _remainingSeconds = _totalSeconds;
    _loadRoute();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _timerController = AnimationController(
      vsync: this,
      // Matches the server's ttl_seconds, not a fixed 45.
      duration: Duration(seconds: _totalSeconds),
    )..forward();

    // Ring for as long as this screen is up.
    //
    // A fare-call reaches here with the ringtone already going (started by
    // `_handleIncomingCall` on the VoIP path), but a BROADCAST has no call
    // behind it — nothing ever called startRingtone, so the screen opened in
    // silence. The notification's own insistent ring stops the moment the
    // rider taps it, so the offer sat there mute. `startRingtone` is idempotent,
    // so this is a no-op on the fare-call path and the fix on the broadcast one.
    _callController.startRingtone();
    HapticFeedback.heavyImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _stopRingtone();
          _callController.declineCall();
        }
      });
    });

    // Watch call status
    _callStatusWorker = ever(_callController.callStatus, (status) {
      if (!mounted) return;
      if (_isCallConnected) {
        // In call room phase — track connected state for call timer.
        // Do NOT auto-navigate on call end; rider must tap "Accept Ride" to proceed.
        if (status == CallStatus.connected && _callTimer == null) {
          _startCallTimer();
        }
      } else {
        // In ringing phase — if call cancelled externally, close screen
        if (status == CallStatus.idle || status == CallStatus.ended) {
          _stopRingtone();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  /// Icon representing the job type on the call (passenger / shop goods /
  /// parcel).
  IconData get _jobIcon {
    switch (_jobType) {
      case 'goods':
        return Icons.shopping_bag_rounded;
      case 'parcel':
        return Icons.inventory_2_rounded;
      case 'ride':
      default:
        return Icons.person_rounded;
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Fetch the driving route for the preview map.
  ///
  /// Best-effort and non-blocking: the sheet and the Accept button must be
  /// usable the instant the screen opens — this offer expires in
  /// [_totalSeconds], so nothing here may gate the decision on a network call.
  /// Until it lands (or if it fails) the map shows a dashed straight hint.
  Future<void> _loadRoute() async {
    if (!_hasRouteCoordinates) return;
    try {
      final result =
          await PolylinePoints(apiKey: googleMapKey).getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_pickupLat, _pickupLng),
          destination: PointLatLng(_dropLat, _dropLng),
          mode: TravelMode.driving,
        ),
      );
      if (!mounted || result.points.length < 2) return;
      setState(() {
        _routePoints = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false);
        // Metres / seconds → the units the sheet displays.
        final metres = result.totalDistanceValue;
        final seconds = result.totalDurationValue;
        if (metres != null && metres > 0) _routeDistanceKm = metres / 1000;
        if (seconds != null && seconds > 0) _routeDurationMin = seconds / 60;
      });
      _fitRouteBounds();
    } catch (_) {
      // Keep the dashed hint — a missing preview must never block accepting.
    }
  }

  /// Frame pickup, drop and the route between them.
  Future<void> _fitRouteBounds() async {
    final map = _mapController;
    if (map == null || !_hasRouteCoordinates) return;

    final points = <LatLng>[
      LatLng(_pickupLat, _pickupLng),
      LatLng(_dropLat, _dropLng),
      ..._routePoints,
    ];
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    try {
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          60,
        ),
      );
    } catch (_) {
      // Map not laid out yet — the next call after the route lands retries.
    }
  }

  void _stopRingtone() {
    // Stop the controller's ringtone (centralized player)
    _callController.stopRingtone();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _callDurationSeconds++);
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _callStatusWorker.dispose();
    _countdownTimer.cancel();
    _callTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _timerController.dispose();
    // Stop controller ringtone on screen dispose as safety net
    _callController.stopRingtone();
    super.dispose();
  }

  /// Rider taps "Accept Ride"
  Future<void> _onAcceptRide() async {
    debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → START, callStatus=${_callController.callStatus.value}, callId=${_callController.callId.value}, roomId=${_callController.roomId.value}');
    debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → isFareCall=${_callController.isFareCall.value}, fareCallOrderId=${_callController.fareCallOrderId.value}');
    _countdownTimer.cancel();
    setState(() => _isAccepting = true);

    // Broadcast dispatch has NO call behind it — the server rings every nearby
    // rider with a data push and the first to accept wins (guide §7.3: no
    // `call_id` is sent). Routing it through acceptCall() would try to answer a
    // WebRTC session that was never created, fail, and drop the rider back to a
    // dead screen with the job lost. Claim the order directly instead.
    if (_isBroadcast) {
      _stopRingtone();
      final claimed = await _callController.acceptFareCallRide();
      if (!mounted) return;
      if (!claimed) {
        // 409 = another rider won the race. acceptFareCallRide already closes
        // the popup quietly in that case; anything else surfaced its own error.
        setState(() => _isAccepting = false);
        return;
      }
      await _proceedAfterRideAccepted();
      return;
    }

    // 1. Stop ringtone and release audio resources BEFORE WebRTC starts.
    //    On Android, the native AudioPlayer must fully release the audio
    //    session before WebRTC's getUserMedia can capture the microphone.
    _stopRingtone();
    debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → ringtone stopped, waiting 300ms for audio session release');
    // Small delay to let Android fully release the audio focus/session
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // 2. Accept the audio call (in-app WebRTC, no method channel)
    debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → calling acceptCall()...');
    try {
      final callAccepted = await _callController.acceptCall();
      debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → acceptCall returned: $callAccepted, callStatus=${_callController.callStatus.value}');
      if (!callAccepted) {
        debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → acceptCall FAILED, aborting');
        if (mounted) setState(() => _isAccepting = false);
        return;
      }
    } catch (e, stack) {
      debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → acceptCall CRASHED: $e');
      debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → crash stack: $stack');
      if (mounted) setState(() => _isAccepting = false);
      return;
    }

    if (!mounted) return;

    // 3. Transition to call room UI — rider speaks with customer first,
    //    then taps "Accept Ride" to confirm the order via _acceptRideFromCallRoom.
    debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → transitioning to call room UI, callStatus=${_callController.callStatus.value}');
    setState(() {
      _isAccepting = false;
      _isCallConnected = true;
    });

    // Start call timer if already connected
    if (_callController.callStatus.value == CallStatus.connected) {
      debugPrint('[FARE_CALL_DEBUG] _onAcceptRide → already connected, starting call timer');
      _startCallTimer();
    }
  }

  /// Rider taps "Reject Ride"
  Future<void> _onRejectRide() async {
    _stopRingtone();
    await _callController.rejectFareCallRide();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Rider taps "Accept Ride" in call room — accept the order, end call, navigate to pickup map.
  Future<void> _acceptRideFromCallRoom() async {
    // Accept the ride order via API (rider confirmed after speaking with customer)
    final rideAccepted = await _callController.acceptFareCallRide();
    if (!rideAccepted) return;
    await _proceedAfterRideAccepted();
  }

  /// Shared tail of both accept paths: tear down any call and route the rider
  /// to the job.
  ///
  /// Broadcast reaches here straight from the sheet with no call to end;
  /// fare-call reaches it after the conversation.
  ///
  /// EVERY order type lands on the orders dashboard — goods and passenger
  /// rides alike. The accepted job appears there as a card, and its "Navigate
  /// to Pickup" button opens [RiderPickupNavigationScreen]. Pushing that screen
  /// from here as well gave the same destination two entry points that had to
  /// be kept in step: this one built it from the CALL payload, the card builds
  /// it from the ORDER, so the two could disagree about ids and addresses for
  /// the same ride.
  Future<void> _proceedAfterRideAccepted() async {
    // End the WebRTC call only if it's actually active (connected/connecting).
    // Fire-and-forget so navigation isn't blocked by the API roundtrip.
    if (_callController.callStatus.value != CallStatus.idle) {
      _callController.endCall();
    }
    _callTimer?.cancel();
    if (!mounted) return;
    Get.offNamed(RouteHelper.getRiderServiceScreenRoute());
  }

  /// End call without navigating (rider hangs up during call room)
  void _endCallOnly() {
    _callController.endCall();
    _callTimer?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    _callController.toggleSpeaker();
  }

  /// Push the Connect screen on the Inquiry tab without ending the active
  /// call. The call screen stays in the navigation stack underneath, so the
  /// WebRTC call keeps running and Back from Connect returns to it.
  void _goToConnectInquiry() {
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.selectedChatTabIndex.value = 1;
    Get.toNamed(RouteHelper.getHomeScreenRoute());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Once the call is connected, Back takes the rider to Connect →
        // Inquiry while the call stays alive in the background (this screen
        // remains underneath in the stack).
        if (_isCallConnected) {
          _goToConnectInquiry();
          return;
        }
        // Before connect (ringing): minimise into Android PiP instead of
        // ending the call or rejecting the ride request.
        await CallPipService.enterPipMode();
      },
      // The two phases are different surfaces: the ringing phase is a map-led
      // job offer (light, edge-to-edge, its own SafeArea inside the sheet), the
      // call room stays the dark call UI it shares with the customer's screen.
      child: _isCallConnected
          ? Scaffold(
              backgroundColor: const Color(0xFF0B141A),
              body: Container(
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
                child: SafeArea(child: _buildCallRoomUI()),
              ),
            )
          : Scaffold(
              backgroundColor: Colors.white,
              // No SafeArea around the map — it should run under the status
              // bar; the countdown pill and the sheet inset themselves.
              body: _buildRingingUI(),
            ),
    );
  }

  // ─────────────────────────────────────────────
  // RINGING UI (Phase 1 — before accept)
  //
  // Map on top with the pickup→drop route, details sheet below. Replaces the
  // earlier dark "incoming call" card: a rider decides on a job from the
  // geometry (how far away is the pickup, where does it end up) far more than
  // from a list of fields, so the route is the primary content and everything
  // else reads against it.
  // ─────────────────────────────────────────────

  Widget _buildRingingUI() {
    return Stack(
      children: [
        Positioned.fill(child: _buildRouteMap()),
        // Countdown floats over the map so it never scrolls out of sight —
        // this offer expires whether or not the rider is looking at it.
        //
        // Offset by the status-bar inset: the map is deliberately edge-to-edge
        // (no SafeArea), so a bare `top: 12` puts the pill under the clock and
        // the notch.
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: _buildCountdownBar(),
        ),
        Align(alignment: Alignment.bottomCenter, child: _buildDetailsSheet()),
      ],
    );
  }

  // ------------------------------------------------------------------- map

  Widget _buildRouteMap() {
    if (!_hasRouteCoordinates) {
      // No coordinates in the push — show a neutral panel rather than a map
      // parked on the null island.
      return Container(
        color: const Color(0xFFEDF1F5),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 44, color: Color(0xFF9AA5B1)),
            const SizedBox(height: 8),
            Text(
              'Route preview unavailable',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: 13,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_pickupLat, _pickupLng),
        zoom: 13,
      ),
      onMapCreated: (c) {
        _mapController = c;
        _fitRouteBounds();
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      liteModeEnabled: false,
      // Keep the fitted route inside the band that is actually visible —
      // between the floating countdown pill (status bar + its own height) and
      // the details sheet covering the lower half.
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 76,
        bottom: 260,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_pickupLat, _pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(_dropLat, _dropLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop'),
        ),
      },
      polylines: {
        if (_routePoints.length >= 2)
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: const Color(0xFF0F172A),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          )
        else
          // Straight hint until the Directions call lands — dashed so it never
          // reads as the actual road route.
          Polyline(
            polylineId: const PolylineId('route_pending'),
            points: [
              LatLng(_pickupLat, _pickupLng),
              LatLng(_dropLat, _dropLng),
            ],
            color: const Color(0xFF94A3B8),
            width: 3,
            patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          ),
      },
    );
  }

  // -------------------------------------------------------------- countdown

  Widget _buildCountdownBar() {
    final total = _totalSeconds <= 0 ? 1 : _totalSeconds;
    final progress = (_remainingSeconds / total).clamp(0.0, 1.0);
    final urgent = _remainingSeconds <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(_jobIcon, size: 20, color: const Color(0xFF0F172A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _offerTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'OpenSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(
                      urgent ? const Color(0xFFEA4335) : const Color(0xFF00A65A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_remainingSeconds}s',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: urgent ? const Color(0xFFEA4335) : const Color(0xFF0F172A),
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ sheet

  Widget _buildDetailsSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Scrollable so a long address pair can't overflow on a short
            // screen — the action row below stays pinned either way.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFareRow(),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFEEF2F6)),
                    const SizedBox(height: 14),
                    _buildRouteRows(),
                    const SizedBox(height: 12),
                    _buildCustomerRow(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  /// Fare, the per-km rate behind it, and the trip's shape (type + payment).
  ///
  /// Per-km is what tells a rider whether a job is worth taking, and it is the
  /// one number the payload does NOT send — it is derived here from fare and
  /// distance, and hidden when distance is unknown rather than shown as ₹0/km.
  Widget _buildFareRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${_fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_farePerKm != null)
                    Text(
                      '₹${_farePerKm!.toStringAsFixed(0)}/km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_orderTypeLabel.isNotEmpty)
                    _buildTag(_orderTypeLabel, const Color(0xFF0F172A)),
                  _buildTag(
                    _paymentMethod.toLowerCase() == 'prepaid'
                        ? 'Paid online'
                        : 'Collect cash',
                    _paymentMethod.toLowerCase() == 'prepaid'
                        ? const Color(0xFF0284C7)
                        : const Color(0xFF00A65A),
                  ),
                  if (_effectiveDistanceKm != null)
                    _buildTag(
                      '${_effectiveDistanceKm!.toStringAsFixed(1)} km trip',
                      const Color(0xFF64748B),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'OpenSans',
        ),
      ),
    );
  }

  /// Pickup above drop, joined by a rail — the standard reading order, so the
  /// rider scans "where do I go first" without parsing labels.
  Widget _buildRouteRows() {
    return Column(
      children: [
        _buildStopRow(
          color: const Color(0xFF00A65A),
          label: 'PICKUP',
          address: _pickupAddress,
          trailing: _pickupDistanceLabel,
        ),
        // The leg between the two stops, labelled on the connector itself so
        // the trip length reads as "pickup → 12.4 km → drop" rather than as
        // another loose field somewhere else in the sheet.
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Container(width: 2, height: 22, color: const Color(0xFFE2E8F0)),
              if (_journeyLabel != null) ...[
                const SizedBox(width: 17),
                const Icon(Icons.straighten_rounded,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Text(
                  _journeyLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildStopRow(
          color: const Color(0xFFEA4335),
          label: 'DROP',
          address: _dropAddress,
        ),
      ],
    );
  }

  Widget _buildStopRow({
    required Color color,
    required String label,
    required String address,
    String? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: color,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      trailing,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: Color(0xFF0F172A),
                  fontFamily: 'OpenSans',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildAvatar(38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'OpenSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_riderTask.isNotEmpty)
                  Text(
                    _riderTask,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontFamily: 'OpenSans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Light-theme avatar. The call-room phase keeps its own dark
  /// [_buildCallRoomAvatar]; this one sits on the white details sheet.
  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE2E8F0),
        border: Border.all(color: const Color(0xFF00A65A), width: 1.6),
      ),
      child: _customerImage.isNotEmpty
          ? ClipOval(
              child: Image.network(
                _customerImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person_rounded,
                    color: const Color(0xFF94A3B8), size: size * 0.56),
              ),
            )
          : Icon(Icons.person_rounded,
              color: const Color(0xFF94A3B8), size: size * 0.56),
    );
  }

  // ---------------------------------------------------------------- actions

  Widget _buildBottomActions() {
    if (_isAccepting) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFF00A65A),
                strokeWidth: 2.4,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isBroadcast ? 'Claiming ride…' : 'Connecting…',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _onRejectRide,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA4335),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _onAcceptRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A65A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  // Broadcast is a race — "Accept" understates it; the rider is
                  // claiming a job several others are being offered right now.
                  _isBroadcast ? 'Accept ride' : 'Accept & talk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CALL ROOM UI (Phase 2 — after accept)
  // Identical layout to customer FareCallQueueScreen
  // ─────────────────────────────────────────────

  Widget _buildCallRoomUI() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Encryption label
        _buildEncryptionLabel(),
        const SizedBox(height: 12),
        // Connected status
        _buildCallRoomStatus(),
        const SizedBox(height: 8),
        // Call timer
        _buildCallRoomTimer(),
        // Avatar with ripple/glow
        Expanded(child: Center(child: _buildCallRoomAvatar())),
        // Ride summary card
        _buildCallRoomRideSummary(),
        const SizedBox(height: 24),
        // Speaker button
        _buildCallRoomActions(),
        const SizedBox(height: 20),
        // Accept Ride + End Call buttons
        _buildCallRoomBottomButtons(),
        const SizedBox(height: 40),
      ],
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
          'End-to-end encrypted 4',
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

  Widget _buildCallRoomStatus() {
    return Obx(() {
      final status = _callController.callStatus.value;
      final isConnected = status == CallStatus.connected;

      return Text(
        isConnected ? 'Connected with $_customerName' : 'Connecting...',
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

  Widget _buildCallRoomTimer() {
    return Obx(() {
      final status = _callController.callStatus.value;

      String text;
      Color color;

      if (status == CallStatus.connected) {
        text = _formatDuration(_callDurationSeconds);
        color = const Color(0xFF00C853);
      } else if (status == CallStatus.connecting ||
          status == CallStatus.accepting) {
        text = 'Connecting...';
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

  Widget _buildCallRoomAvatar() {
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
          child: _customerImage.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _customerImage,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CircleAvatar(
                      radius: 60,
                      backgroundColor: Color(0xFF2A3942),
                      child: Icon(Icons.person_rounded,
                          size: 50, color: Color(0xFF8696A0)),
                    ),
                  ),
                )
              : const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF2A3942),
                  child: Icon(Icons.person_rounded,
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

  Widget _buildCallRoomRideSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
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
            // Addresses
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickupAddress,
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
                    _dropAddress,
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
        ),
      ),
    );
  }

  Widget _buildCallRoomActions() {
    return Obx(() {
      final isSpeakerOn = _callController.isSpeakerOn.value;
      final isConnected =
          _callController.callStatus.value == CallStatus.connected;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCallRoomActionBtn(
              icon: isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              label: 'Speaker 7',
              isActive: isSpeakerOn,
              onTap: _toggleSpeaker,
              enabled: isConnected,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCallRoomActionBtn({
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

  Widget _buildCallRoomBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Accept Ride — green full-width button (enabled only after call connects)
          Obx(() {
            final isConnected = _callController.callStatus.value == CallStatus.connected;
            return SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isConnected ? _acceptRideFromCallRoom : null,
                icon: isConnected
                    ? const Icon(Icons.check_rounded, size: 22)
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                label: Text(
                  isConnected ? 'Accept Ride & Navigate' : 'Connecting...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'OpenSans',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? const Color(0xFF00C853)
                      : const Color(0xFF00C853).withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  elevation: isConnected ? 4 : 0,
                  shadowColor: const Color(0xFF00C853).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // End Call — red circle button
          GestureDetector(
            onTap: _endCallOnly,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA4335),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA4335).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  'End Call',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
