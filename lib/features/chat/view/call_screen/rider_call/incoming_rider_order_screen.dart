import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      duration: const Duration(seconds: 45),
    )..forward();

    // Ringtone is played by CallController.startRingtone() in _handleIncomingCall
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

    // Capture orderMongoId and the customer user id before endCall() clears
    // them via _resetState() — the rider pickup screen needs the customer id
    // so the "call customer" button can initiate a fresh audio call.
    final orderMongoId = _callController.fareCallOrderMongoId.value;
    final customerUserId = _callController.remoteUserId ?? '';

    // End the WebRTC call only if it's actually active (connected/connecting).
    // Fire-and-forget so navigation isn't blocked by the API roundtrip.
    if (_callController.callStatus.value != CallStatus.idle) {
      _callController.endCall();
    }
    _callTimer?.cancel();
    if (!mounted) return;
    Get.off(() => RiderPickupNavigationScreen(
          pickupLocation: _pickupAddress,
          dropLocation: _dropAddress,
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropLat: _dropLat,
          dropLng: _dropLng,
          fareAmount: _fare,
          distanceKm: _distance,
          customerName: _customerName,
          customerImage: _customerImage,
          otp: '',
          paymentMethod: _paymentMethod,
          orderId: orderMongoId,
          customerUserId: customerUserId,
        ));
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
      child: Scaffold(
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
          child: SafeArea(
            child: _isCallConnected
                ? _buildCallRoomUI()
                : _buildRingingUI(),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RINGING UI (Phase 1 — before accept)
  // ─────────────────────────────────────────────

  Widget _buildRingingUI() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(child: _buildRideInfoCard()),
        _buildBottomActions(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Flexible(
            child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final opacity = 0.5 + (_pulseController.value * 0.5);
              return Opacity(opacity: opacity, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_jobIcon, color: const Color(0xFF00C853), size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _callTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00C853),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          const SizedBox(width: 12),
          _buildCountdownTimer(),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final color = _remainingSeconds <= 10
        ? const Color(0xFFFF5252)
        : const Color(0xFF00C853);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, _) {
                return CircularProgressIndicator(
                  value: 1.0 - _timerController.value,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                );
              },
            ),
          ),
          Text(
            '$_remainingSeconds',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCustomerRow(),
          if (_riderTask.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(_jobIcon,
                      color: const Color(0xFF42A5F5), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _riderTask,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildFareDistanceHeader(),
                Divider(
                    color: Colors.white.withValues(alpha: 0.08), height: 1),
                _buildRouteTimeline(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPaymentChip(),
              if (_jobLabel.isNotEmpty) _buildInfoChip(
                icon: _jobIcon,
                label: _jobLabel,
                color: const Color(0xFF42A5F5),
              ),
              if (_etaDurationMin > 0) _buildInfoChip(
                icon: Icons.access_time_rounded,
                label: '${_etaDurationMin.toStringAsFixed(0)} min${_etaDistanceKm > 0 ? ' (${_etaDistanceKm.toStringAsFixed(1)} km)' : ''}',
                color: const Color(0xFF66BB6A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow() {
    return Row(
      children: [
        _buildAvatar(50),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'OpenSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2A3942),
        border: Border.all(
          color: const Color(0xFF00C853).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: _customerImage.isNotEmpty
          ? ClipOval(
              child: Image.network(
                _customerImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.person_rounded,
                    color: const Color(0xFF8696A0),
                    size: size * 0.56),
              ),
            )
          : Icon(Icons.person_rounded,
              color: const Color(0xFF8696A0), size: size * 0.56),
    );
  }

  Widget _buildFareDistanceHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.currency_rupee_rounded,
                    color: const Color(0xFF00C853).withValues(alpha: 0.7),
                    size: 20),
                const SizedBox(height: 6),
                Text(
                  '₹${_fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853),
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estimated Fare',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.route_rounded,
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.7),
                    size: 20),
                const SizedBox(height: 6),
                Text(
                  '${_distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF42A5F5),
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total Distance',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
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

  Widget _buildRouteTimeline() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C853),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              ...List.generate(
                4,
                (_) => Container(
                  width: 2,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7043),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00C853).withValues(alpha: 0.8),
                    fontFamily: 'OpenSans',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _pickupAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  'DROP-OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF7043).withValues(alpha: 0.8),
                    fontFamily: 'OpenSans',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _dropAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip() {
    return _buildInfoChip(
      icon: _paymentMethod.toLowerCase() == 'prepaid'
          ? Icons.account_balance_wallet_rounded
          : Icons.money_rounded,
      label: _paymentMethod,
      color: const Color(0xFFFFC107),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_isAccepting) {
      return Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Color(0xFF00C853),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Accepting ride...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFEA4335),
            label: 'Reject',
            onTap: _onRejectRide,
          ),
          _buildActionButton(
            icon: Icons.check_rounded,
            color: const Color(0xFF00C853),
            label: 'Accept',
            isAccept: true,
            onTap: _onAcceptRide,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isAccept = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              if (!isAccept) return child!;
              final scale = 1.0 + (_slideController.value * 0.08);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
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
