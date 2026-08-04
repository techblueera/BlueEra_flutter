import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:BlueEra/core/services/route_polyline_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';


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

  /// Measure the pickup→drop leg for the journey line ("12.4 km · 28 min").
  ///
  /// Kept after the preview map was removed because the DURATION lives nowhere
  /// else — the push payload carries a distance but never an ETA, and how long
  /// a job takes is half of whether it's worth taking. The polyline the reply
  /// also returns is now discarded.
  ///
  /// Best-effort and non-blocking: the Accept button must be usable the instant
  /// the screen opens — this offer expires in [_totalSeconds], so nothing here
  /// may gate the decision on a network call.
  Future<void> _loadRoute() async {
    if (!_hasRouteCoordinates) return;
    try {
      final result = await RoutePolylineService.fetch(
        origin: PointLatLng(_pickupLat, _pickupLng),
        destination: PointLatLng(_dropLat, _dropLng),
      );
      if (!mounted || result == null) return;
      // Metres / seconds → the units the journey line displays.
      final metres = result.totalDistanceValue;
      final seconds = result.totalDurationValue;
      if ((metres == null || metres <= 0) && (seconds == null || seconds <= 0)) {
        return;
      }
      setState(() {
        if (metres != null && metres > 0) _routeDistanceKm = metres / 1000;
        if (seconds != null && seconds > 0) _routeDurationMin = seconds / 60;
      });
    } catch (_) {
      // The journey line simply omits what it doesn't know — a failed
      // measurement must never block accepting.
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
      // The two phases are different surfaces: the ringing phase is a light
      // job-offer sheet, the call room stays the dark call UI it shares with
      // the customer's screen.
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
              // Transparent: the backdrop is painted inside _buildRingingUI,
              // which picks a scrim or the app's dark surface depending on
              // whether there is a page underneath to dim.
              backgroundColor: Colors.transparent,
              body: _buildRingingUI(),
            ),
    );
  }

  // ─────────────────────────────────────────────
  // RINGING UI (Phase 1 — before accept)
  //
  // Countdown pinned at the top, the offer's details in the middle, accept /
  // decline pinned at the bottom.
  //
  // This used to be a full-bleed route map with the details in a sheet over its
  // lower half. The map is gone: the rider is deciding in a handful of seconds
  // from the fare, the distance and the two addresses — all of which are text —
  // and the map pushed exactly those into a cramped sheet while costing a
  // Directions draw per offer. The addresses now get the whole screen.
  // ─────────────────────────────────────────────

  Widget _buildRingingUI() {
    final maxSheet = MediaQuery.of(context).size.height * 0.82;
    // The route fades the scrim in; the sheet rises on the same animation, so
    // the offer arrives the way a sheet does instead of cutting in. Falls back
    // to "already shown" when there's no route animation to ride (an offer
    // rebuilt outside a transition).
    final routeAnimation =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;

    return Stack(
      children: [
        Positioned.fill(child: _buildRingingBackdrop()),
        Column(
          children: [
            // Backdrop is deliberately inert: an offer is answered, not
            // dismissed by tapping away from it — and it expires on its own if
            // the rider does nothing. A tap-to-close here would read as
            // "declined" without ever saying so.
            const Expanded(child: SizedBox.shrink()),
            _buildSlidingSheet(routeAnimation, maxSheet),
          ],
        ),
      ],
    );
  }

  /// What sits behind the sheet.
  ///
  /// Normally: a scrim over the screen the rider was already on, which is what
  /// makes this read as a sheet rather than a page.
  ///
  /// But an offer can arrive from a notification with the app cold — then this
  /// route is the ONLY one on the stack and there is nothing to dim. Rather
  /// than a black void, that case gets the app's own dark surface (the same
  /// gradient the call room uses, so the app has one dark surface and not two)
  /// with a quiet mark. It stays quiet on purpose: the sheet is the thing to
  /// read, and this is on screen for twenty seconds.
  Widget _buildRingingBackdrop() {
    final hasPageBehind = Navigator.of(context).canPop();
    if (hasPageBehind) {
      return const ColoredBox(color: Color(0x8C000000));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A2E35), Color(0xFF0F1F27), Color(0xFF0B141A)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00A65A).withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                ),
                child: Icon(_jobIcon,
                    size: 24, color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 14),
              Text(
                'New ride request',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingSheet(Animation<double> routeAnimation, double maxSheet) {
    return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: routeAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          )),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheet),
        child: _buildOfferSheet(),
      ),
    );
  }

  /// The offer, as a sheet: the countdown rail welded to its top edge, the fare
  /// as the headline, the two stops on a rail, and the decision pinned to the
  /// bottom where a thumb already is.
  Widget _buildOfferSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x2E000000), blurRadius: 28, offset: Offset(0, -8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDrainRail(),
              _buildOfferHeader(),
              // Scrolls so a long address pair can't push the decision off a
              // short screen; the actions below stay pinned either way.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFareRow(),
                      const SizedBox(height: 18),
                      _buildRouteRows(),
                      const SizedBox(height: 16),
                      _buildCustomerRow(),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- countdown

  /// Fraction of the offer window still left, 1 → 0.
  double get _offerProgress {
    final total = _totalSeconds <= 0 ? 1 : _totalSeconds;
    return (_remainingSeconds / total).clamp(0.0, 1.0);
  }

  /// Green while there's time, amber past the halfway point, red in the last
  /// five seconds. Always paired with the literal seconds beside it — the
  /// colour is emphasis, never the message.
  Color get _urgencyColor {
    if (_remainingSeconds <= 5) return const Color(0xFFEA4335);
    if (_offerProgress <= 0.5) return const Color(0xFFF59E0B);
    return const Color(0xFF00A65A);
  }

  /// The countdown, drawn as the sheet's own top edge rather than as a widget
  /// inside it: a full-bleed hairline that drains left → right, so the sheet
  /// visibly runs out of time. A rider glancing down reads the remaining width
  /// without focusing on anything.
  Widget _buildDrainRail() {
    return SizedBox(
      height: 5,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFEEF2F6))),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _offerProgress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                color: _urgencyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// What the job is, and how long is left to take it.
  Widget _buildOfferHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Icon(_jobIcon, size: 18, color: const Color(0xFF0F172A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _offerTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF64748B),
                fontFamily: 'OpenSans',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          // The number the rail is drawing. Kept literal so the countdown is
          // legible to a rider who can't distinguish the rail's colours.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _urgencyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_remainingSeconds}s left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _urgencyColor,
                fontFamily: 'OpenSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ sheet

  // NOTE: `_buildDetailsSheet` lived here — the rounded, shadowed sheet that
  // held these rows over the lower half of the map. With the map gone the sheet
  // has nothing to sit on, so its contents are laid out directly by
  // [_buildRingingUI].

  /// Fare, the per-km rate behind it, and the trip's shape (type + payment).
  ///
  /// Per-km is what tells a rider whether a job is worth taking, and it is the
  /// one number the payload does NOT send — it is derived here from fare and
  /// distance, and hidden when distance is unknown rather than shown as ₹0/km.
  Widget _buildFareRow() {
    final prepaid = _paymentMethod.toLowerCase() == 'prepaid';
    // One line instead of three pills. A row of tags reads as a row of tags;
    // this reads as a sentence about the job, which is faster at a glance.
    // Trip distance is deliberately absent — it lives on the route connector,
    // where it means "the leg between these two points".
    final meta = <String>[
      if (_orderTypeLabel.isNotEmpty) _orderTypeLabel,
      prepaid ? 'Paid online' : 'Collect cash',
    ].join('  ·  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOU EARN',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Color(0xFF94A3B8),
            fontFamily: 'OpenSans',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${_fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Color(0xFF0F172A),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
            if (_farePerKm != null) ...[
              const SizedBox(width: 10),
              Text(
                '₹${_farePerKm!.toStringAsFixed(0)}/km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: prepaid ? const Color(0xFF0284C7) : const Color(0xFF00A65A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                meta,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  fontFamily: 'OpenSans',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _onRejectRide,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // "Decline", not "Cancel" — nothing of the rider's is being
                // cancelled; they are turning down an offer, and it goes to
                // someone else.
                child: const Text(
                  'Decline',
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
              height: 54,
              child: ElevatedButton(
                onPressed: _onAcceptRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A65A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // The action names the money it commits to. On the call flow the
                // fare is still to be agreed, so that button stays about the
                // conversation instead of quoting a number.
                child: Text(
                  _isBroadcast
                      ? 'Accept  ·  ₹${_fare.toStringAsFixed(0)}'
                      : 'Accept & talk',
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
