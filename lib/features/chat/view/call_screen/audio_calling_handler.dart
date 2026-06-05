import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';
import '../../auth/service/call_pip_service.dart';
import 'rider_call/rider_pickup_navigation_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CallActivityRoomScreen — Unified call screen for both incoming and outgoing calls.
// Handles: ringing (outgoing/incoming), connecting, active audio, active video,
// group call, and PiP mode.
// ══════════════════════════════════════════════════════════════════════════════

class CallActivityRoomScreen extends StatefulWidget {
  const CallActivityRoomScreen({super.key});

  @override
  State<CallActivityRoomScreen> createState() => _CallActivityRoomScreenState();
}

class _CallActivityRoomScreenState extends State<CallActivityRoomScreen>
    with TickerProviderStateMixin {
  late Worker _callStatusWorker;
  late Worker _switchTypeWorker;
  late Worker _ringingStateWorker;
  Timer? _terminalDismissTimer;
  final AudioPlayer _ringbackPlayer = AudioPlayer();

  // Ripple animation controllers (staggered — used for outgoing ringing view)
  late AnimationController _ripple1Controller;
  late AnimationController _ripple2Controller;
  late AnimationController _ripple3Controller;

  late Animation<double> _ripple1Scale;
  late Animation<double> _ripple1Opacity;
  late Animation<double> _ripple2Scale;
  late Animation<double> _ripple2Opacity;
  late Animation<double> _ripple3Scale;
  late Animation<double> _ripple3Opacity;

  // Incoming-call specific animations
  late AnimationController _pulseController;
  late AnimationController _ringController;

  // Draggable local video position
  double _localVideoX = -1;
  double _localVideoY = -1;
  bool _positionInitialized = false;

  // PiP state
  bool _isInPipMode = false;

  // Controls visibility (tap to toggle in video call)
  bool _showControls = true;

  // Incoming call accepting state
  bool _isAccepting = false;

  // Rider fare-call: snapshot of ride details captured while connected so we
  // can navigate to the pickup/OTP screen after the call ends. CallController
  // resets isFareCall/fareCallOrderId/fareCallRideDetails during cleanup, so
  // reading them in the call:ended path is too late.
  bool _riderFareCallSnapshotTaken = false;
  bool _riderAcceptedRide = false; // set only when rider taps "Accept Ride"
  bool _riderAcceptingRide = false; // in-flight guard for the API call
  Map<String, dynamic>? _riderFareCallRideDetails;
  String _riderFareCallOrderId = '';
  String _riderFareCallOrderMongoId = '';
  String _riderFareCallCustomerUserId = '';
  String _riderFareCallCustomerName = '';
  String _riderFareCallCustomerImage = '';

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    // --- Outgoing ripple animations (staggered by 600ms) ---
    _ripple1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _ripple2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ripple3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ripple2Controller.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _ripple3Controller.repeat();
    });

    _ripple1Scale = Tween<double>(begin: 0.9, end: 1.5).animate(
      CurvedAnimation(parent: _ripple1Controller, curve: Curves.easeOut),
    );
    _ripple1Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ripple1Controller, curve: Curves.easeOut),
    );
    _ripple2Scale = Tween<double>(begin: 0.9, end: 1.5).animate(
      CurvedAnimation(parent: _ripple2Controller, curve: Curves.easeOut),
    );
    _ripple2Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ripple2Controller, curve: Curves.easeOut),
    );
    _ripple3Scale = Tween<double>(begin: 0.9, end: 1.5).animate(
      CurvedAnimation(parent: _ripple3Controller, curve: Curves.easeOut),
    );
    _ripple3Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ripple3Controller, curve: Curves.easeOut),
    );

    // --- Incoming pulse/ring animations ---
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    final controller = Get.find<CallController>();

    // Caller stays silent — only the receiver plays the ringtone (via
    // CallController.startRingtone() in _handleIncomingCall). Previously the
    // caller played `hangouts_call.mp3` as a ringback, which is the same
    // asset as the incoming ringtone and sounded like their own phone was
    // ringing.
    if (!controller.isCaller.value) {
      HapticFeedback.heavyImpact();
    }

    // Watch call status changes
    _callStatusWorker = ever(controller.callStatus, (status) {
      if (!mounted) return;
      if (status == CallStatus.idle ||
          status == CallStatus.connecting ||
          status == CallStatus.connected ||
          status == CallStatus.ended) {
        _ringbackPlayer.stop();
      }
      if (status == CallStatus.connected) {
        _ripple1Controller.stop();
        _ripple2Controller.stop();
        _ripple3Controller.stop();
        _captureRiderFareCallSnapshot(controller);
      }
      // Stop ringtone on decline, cancel, accept, end, or any non-ringing state
      if (status == CallStatus.idle ||
          status == CallStatus.accepting ||
          status == CallStatus.connecting ||
          status == CallStatus.connected ||
          status == CallStatus.ended) {
        _stopRingtone();
      }
      // Rider fare-call: after the call ends, either redirect to pickup/OTP
      // (rider accepted the ride) or pop the call screen (rider just hung up).
      // CallController._handleCallEnded skips _navigateBackFromCallScreen for
      // fare-calls, so without this hop the rider lands on a black screen.
      if ((status == CallStatus.idle || status == CallStatus.ended) &&
          _riderFareCallSnapshotTaken) {
        if (_riderAcceptedRide) {
          _navigateRiderToPickup();
        } else {
          _popRiderCallScreen();
        }
      }
    });

    // Watch ringing-state terminal transitions (Dialing/Ringing/Connecting/
    // Connected → no_answer/declined/busy/cancelled/failed). Show the label
    // for ~2s, then dismiss the outgoing-call screen if no other handler
    // (call:declined/cancelled/ended) already popped it. Caller-side only.
    _ringingStateWorker = ever(controller.ringingState, (state) {
      if (!mounted) return;
      if (!controller.isCaller.value) return;
      if (state.isTerminal) {
        _terminalDismissTimer?.cancel();
        _terminalDismissTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    });

    // Watch for incoming switch type requests
    _switchTypeWorker = ever(controller.switchTypeRequestedBy, (requestedBy) {
      if (requestedBy.isNotEmpty && mounted) {
        _showSwitchTypeDialog(context, controller, requestedBy);
      }
    });

    // Setup PiP listeners
    if (Platform.isAndroid) {
      CallPipService.init();
      CallPipService.onPipModeChanged = (isInPip) {
        if (mounted) setState(() => _isInPipMode = isInPip);
      };
      CallPipService.onPipAction = (action) {
        if (!mounted) return;
        switch (action) {
          case 'mute_toggle':
            controller.toggleMic();
            break;
          case 'hangup':
            controller.endCall();
            break;
        }
      };
    }
  }

  void _stopRingtone() {
    _ringbackPlayer.stop();
    // Also stop controller's ringtone as a safety measure
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().stopRingtone();
    }
  }

  void _captureRiderFareCallSnapshot(CallController controller) {
    if (_riderFareCallSnapshotTaken) return;
    if (!controller.isFareCall.value) return;
    if (controller.isCaller.value) return;
    final orderId = controller.fareCallOrderId.value;
    if (orderId.isEmpty) return;
    final ride = controller.fareCallRideDetails.value;
    _riderFareCallRideDetails = ride != null
        ? Map<String, dynamic>.from(ride)
        : null;
    _riderFareCallOrderId = orderId;
    _riderFareCallOrderMongoId = controller.fareCallOrderMongoId.value;
    _riderFareCallCustomerUserId = controller.remoteUserId ?? '';
    _riderFareCallCustomerName = controller.callerName.value.isNotEmpty
        ? controller.callerName.value
        : controller.remoteUserName.value;
    _riderFareCallCustomerImage = controller.callerImage.value.isNotEmpty
        ? controller.callerImage.value
        : controller.remoteUserImage.value;
    _riderFareCallSnapshotTaken = true;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  void _popRiderCallScreen() {
    _riderFareCallSnapshotTaken = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _onRiderAcceptRide(CallController controller) async {
    if (_riderAcceptingRide || _riderAcceptedRide) return;
    setState(() => _riderAcceptingRide = true);
    try {
      // Make sure we have a snapshot — captureRiderFareCallSnapshot was
      // already called when status became connected, but acceptFareCallRide
      // and the subsequent endCall both clear the controller state, so we
      // re-capture here as a safety net.
      _captureRiderFareCallSnapshot(controller);
      final accepted = await controller.acceptFareCallRide();
      if (!accepted) {
        if (mounted) setState(() => _riderAcceptingRide = false);
        return;
      }
      _riderAcceptedRide = true;
      // Ending the call triggers _handleCallEnded → resetState → status=idle,
      // which the call-status worker observes and calls _navigateRiderToPickup.
      if (controller.callStatus.value != CallStatus.idle) {
        // Fire-and-forget so the navigation isn't blocked by the API roundtrip.
        controller.endCall();
      } else {
        // Call already ended — navigate immediately.
        _navigateRiderToPickup();
      }
    } catch (_) {
      if (mounted) setState(() => _riderAcceptingRide = false);
    }
  }

  Future<void> _onRiderRejectRide(CallController controller) async {
    if (_riderAcceptingRide || _riderAcceptedRide) return;
    // rejectFareCallRide → declineCall → call ends; the worker sees idle with
    // _riderAcceptedRide=false and pops the screen.
    await controller.rejectFareCallRide();
  }

  Widget _buildRiderFareCallActions(CallController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _RiderActionButton(
              label: 'Reject Ride',
              icon: Icons.close_rounded,
              backgroundColor: const Color(0xFF3A2A2A),
              foregroundColor: const Color(0xFFEA4335),
              onTap: _riderAcceptingRide
                  ? null
                  : () => _onRiderRejectRide(controller),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RiderActionButton(
              label: _riderAcceptingRide ? 'Accepting...' : 'Accept Ride',
              icon: Icons.check_rounded,
              backgroundColor: const Color(0xFF1F4A2C),
              foregroundColor: const Color(0xFF25D366),
              isLoading: _riderAcceptingRide,
              onTap: _riderAcceptingRide
                  ? null
                  : () => _onRiderAcceptRide(controller),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateRiderToPickup() {
    if (!_riderFareCallSnapshotTaken) return;
    _riderFareCallSnapshotTaken = false; // one-shot

    final ride = _riderFareCallRideDetails;
    final pickup = ride?['pickup'] is Map ? ride!['pickup'] as Map : const {};
    final drop = ride?['drop'] is Map ? ride!['drop'] as Map : const {};
    final orderId = _riderFareCallOrderMongoId.isNotEmpty
        ? _riderFareCallOrderMongoId
        : _riderFareCallOrderId;

    final target = RiderPickupNavigationScreen(
      pickupLocation: (pickup['address'] ?? '').toString(),
      dropLocation: (drop['address'] ?? '').toString(),
      pickupLat: _toDouble(pickup['lat']),
      pickupLng: _toDouble(pickup['lng']),
      dropLat: _toDouble(drop['lat']),
      dropLng: _toDouble(drop['lng']),
      fareAmount: _toDouble(ride?['fare']),
      distanceKm: _toDouble(ride?['distance']),
      customerName: _riderFareCallCustomerName.isNotEmpty
          ? _riderFareCallCustomerName
          : 'Customer',
      customerImage: _riderFareCallCustomerImage,
      otp: '',
      paymentMethod: (ride?['modeOfPayment'] ?? 'Cash').toString(),
      orderId: orderId,
      customerUserId: _riderFareCallCustomerUserId,
    );

    // Use offAll-style replace so the empty call screen doesn't linger in the
    // back stack. Defer to next frame so we don't mutate the navigator while
    // the Obx is rebuilding.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.off(() => target);
    });
  }

  @override
  void dispose() {
    _callStatusWorker.dispose();
    _switchTypeWorker.dispose();
    _ringingStateWorker.dispose();
    _terminalDismissTimer?.cancel();
    _ripple1Controller.dispose();
    _ripple2Controller.dispose();
    _ripple3Controller.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _ringbackPlayer.stop();
    _ringbackPlayer.dispose();
    // Stop controller ringtone on screen dispose as safety net
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().stopRingtone();
    }
    CallPipService.dispose();
    super.dispose();
  }

  Future<bool> _enterPipMode() async {
    if (!Platform.isAndroid) return false;
    return await CallPipService.enterPipMode();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (Platform.isAndroid) {
          final entered = await _enterPipMode();
          if (entered) return;
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B141A),
        body: Obx(() {
          final status = controller.callStatus.value;
          final isConnected = status == CallStatus.connected;
          final isVideo = controller.callType.value == CallType.video;
          final isGroup = controller.isGroupCall.value;
          final isCaller = controller.isCaller.value;

          // PiP mode
          if (_isInPipMode) {
            return _buildPipModeView(controller, isVideo);
          }

          // Call has ended/reset — show empty body while navigation pops the screen.
          // Prevents the ringing/active view from re-rendering during the gap
          // between _resetState() (sets idle) and _navigateBackFromCallScreen().
          if (status == CallStatus.idle || status == CallStatus.ended) {
            return const SizedBox.shrink();
          }

          // Incoming call ringing state — show incoming UI with accept/decline
          if (!isCaller &&
              !isConnected &&
              status != CallStatus.connecting &&
              status != CallStatus.accepting &&
              status != CallStatus.ended &&
              status != CallStatus.idle) {
            return _buildIncomingCallView(controller);
          }

          // Outgoing ringing state
          if (!isConnected &&
              status != CallStatus.connecting &&
              status != CallStatus.accepting &&
              status != CallStatus.ended &&
              status != CallStatus.idle) {
            return _buildRingingView(controller);
          }

          // Active call — video mode
          if (isVideo && !isGroup) {
            return GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoCallBody(controller),
                  if (_showControls) _buildTopBar(controller),
                  if (_showControls) _buildActiveBottomControls(controller),
                ],
              ),
            );
          }

          // Active call — group
          if (isGroup) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildGroupCallBody(controller, isVideo),
                _buildTopBar(controller),
                _buildActiveBottomControls(controller),
              ],
            );
          }

          // Active call — audio
          return _buildAudioCallView(controller);
        }),
      ),
    );
  }

  // ==================== INCOMING CALL VIEW ====================

  Widget _buildIncomingCallView(CallController controller) {
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
            const SizedBox(height: 20),
            // Encryption label
            _buildIncomingEncryptionLabel(),
            const SizedBox(height: 16),
            // Caller info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Obx(() => Text(
                    controller.callerName.value.isNotEmpty
                        ? controller.callerName.value
                        : 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'OpenSans',
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  )),
            ),
            const SizedBox(height: 6),
            Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.callType.value == CallType.video
                          ? Icons.videocam_rounded
                          : Icons.phone_rounded,
                      color: const Color(0xFF8696A0),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.callType.value == CallType.video
                          ? 'BlueEra Video Call'
                          : 'BlueEra Voice Call',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8696A0),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                )),

            // Avatar with ripple rings
            Expanded(
              child: Center(
                child: Obx(() => _buildIncomingRippleAvatar(controller)),
              ),
            ),

            // Bottom section: Decline + Accept buttons or Connecting...
            _buildIncomingBottomActions(controller),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingEncryptionLabel() {
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

  Widget _buildIncomingRippleAvatar(CallController controller) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple rings
              for (int i = 0; i < 3; i++) _buildIncomingRippleRing(i),
              // Avatar
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
        child: CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF2A3942),
          backgroundImage: controller.callerImage.value.isNotEmpty
              ? CachedNetworkImageProvider(controller.callerImage.value)
              : null,
          child: controller.callerImage.value.isEmpty
              ? const Icon(Icons.person_rounded,
                  size: 60, color: Color(0xFF8696A0))
              : null,
        ),
      ),
    );
  }

  Widget _buildIncomingRippleRing(int index) {
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

  Widget _buildIncomingBottomActions(CallController controller) {
    return Obx(() {
      final isAccepting = controller.callStatus.value == CallStatus.accepting;

      if (isAccepting || _isAccepting) {
        return Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF00A884),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Connecting...',
              style: TextStyle(
                color: Color(0xFF8696A0),
                fontSize: 14,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          // Quick action row (Message)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallAction(
                  icon: Icons.message_rounded,
                  label: 'Message',
                  onTap: () {
                    _stopRingtone();
                    controller.declineCall();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // Accept / Decline buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Decline
                _buildIncomingCallButton(
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFFEA4335),
                  label: 'Decline',
                  onTap: () {
                    _stopRingtone();
                    controller.declineCall();
                  },
                ),
                // Accept
                _buildIncomingCallButton(
                  icon: controller.callType.value == CallType.video
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: const Color(0xFF00A884),
                  label: 'Accept',
                  onTap: () async {
                    _stopRingtone();
                    setState(() => _isAccepting = true);
                    final accepted = await controller.acceptCall();
                    if (!accepted) {
                      setState(() => _isAccepting = false);
                    }
                  },
                  isAccept: true,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSmallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
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
    );
  }

  Widget _buildIncomingCallButton({
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
            animation: _ringController,
            builder: (context, child) {
              // Only animate the accept button with a gentle bounce
              if (!isAccept) return child!;
              final scale = 1.0 + (_ringController.value * 0.08);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
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

  // ==================== RINGING / OUTGOING VIEW ====================

  Widget _buildRingingView(CallController controller) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(painter: _BackgroundPatternPainter()),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.close_fullscreen_rounded,
                      onTap: () async {
                        if (Platform.isAndroid) {
                          final entered = await _enterPipMode();
                          if (entered) return;
                        }
                        Get.back();
                      },
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Column(
                          children: [
                            Obx(() => CustomText(
                                  controller.remoteUserName.value.isNotEmpty
                                      ? controller.remoteUserName.value
                                      : 'Calling...',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 0.2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.55)),
                                const SizedBox(width: 4),
                                Text(
                                  'End-to-end encrypted',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _CircleIconButton(
                      icon: Icons.person_add_alt_1_rounded,
                      onTap: () {
                        commonSnackBar(message: "Coming soon...");
                      },
                    ),
                  ],
                ),
              ),

              // Avatar + ripples
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple 1
                            AnimatedBuilder(
                              animation: _ripple1Controller,
                              builder: (context, _) => Transform.scale(
                                scale: _ripple1Scale.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF25D366).withValues(
                                          alpha: _ripple1Opacity.value * 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Ripple 2
                            AnimatedBuilder(
                              animation: _ripple2Controller,
                              builder: (context, _) => Transform.scale(
                                scale: _ripple2Scale.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF25D366).withValues(
                                          alpha: _ripple2Opacity.value * 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Ripple 3
                            AnimatedBuilder(
                              animation: _ripple3Controller,
                              builder: (context, _) => Transform.scale(
                                scale: _ripple3Scale.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF25D366).withValues(
                                          alpha: _ripple3Opacity.value * 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Avatar circle
                            Obx(() => _buildAvatarCircle(
                                  image: controller.remoteUserImage.value,
                                  size: 190,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Outgoing-call status label.
                      // For the caller, this is driven by the server's
                      // `call:ringing` event (Dialing…/Ringing…/Connecting…/
                      // Connected/terminal). For the callee's accepting flow
                      // we keep the local CallStatus.accepting label since
                      // `call:ringing` is caller-only.
                      Obx(() {
                        String text;
                        if (controller.callStatus.value ==
                                CallStatus.accepting &&
                            !controller.isCaller.value) {
                          text = 'Accepting...';
                        } else {
                          text = controller.ringingState.value.label;
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom controls (WhatsApp pill)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2733),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Obx(() {
                    final isVideoCall =
                        controller.callType.value == CallType.video;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (isVideoCall)
                          _ControlButton(
                            icon: controller.isCameraOn.value
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            label: 'Camera',
                            isActive: !controller.isCameraOn.value,
                            onTap: () => controller.toggleCamera(),
                          ),
                        _buildAudioOutputButton(controller),
                        _ControlButton(
                          icon: controller.isMicOn.value
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          label: controller.isMicOn.value ? 'Mute' : 'Unmute',
                          isActive: !controller.isMicOn.value,
                          activeColor: Colors.red,
                          bold: !controller.isMicOn.value,
                          onTap: () => controller.toggleMic(),
                        ),
                        _ControlButton(
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          backgroundColor: const Color(0xFFEA4335),
                          onTap: () {
                            _ringbackPlayer.stop();
                            controller.cancelCall();
                          },
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ACTIVE AUDIO CALL VIEW ====================

  Widget _buildAudioCallView(CallController controller) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(painter: _BackgroundPatternPainter()),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.close_fullscreen_rounded,
                      onTap: () async {
                        if (Platform.isAndroid) {
                          final entered = await _enterPipMode();
                          if (entered) return;
                        }
                        Get.back();
                      },
                    ),
                    Flexible(
                      child: Column(
                        children: [
                          Obx(() => Text(
                                controller.remoteUserName.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 0.2,
                                ),
                              )),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.55)),
                              const SizedBox(width: 4),
                              Text(
                                'End-to-end encrypted',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(),
                    /*    Obx(() {
                      if (controller.callStatus.value == CallStatus.connected) {
                        return _CircleIconButton(
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () =>
                              _showAddUserBottomSheet(context, controller),
                        );
                      }
                      return const SizedBox(width: 44);
                    }),*/
                  ],
                ),
              ),

              // Avatar + ripples (no ripple in connected state)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => _buildAvatarCircle(
                            image: controller.remoteUserImage.value,
                            size: 190,
                          )),
                      const SizedBox(height: 20),
                      // Call timer / status
                      Obx(() {
                        if (controller.callStatus.value ==
                            CallStatus.connected) {
                          return Text(
                            controller.formattedCallDuration,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              letterSpacing: 0.8,
                            ),
                          );
                        }
                        return Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        );
                      }),
                      // Remote mute indicator
                      Obx(() {
                        if (!controller.remoteAudioEnabled.value) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mic_off,
                                    color: Colors.redAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Muted',
                                  style: TextStyle(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ),

              // Rider fare-call: Accept Ride / Reject Ride row (shown above
              // the regular call controls when the rider is on a fare-call).
              Obx(() {
                if (!controller.isFareCall.value) return const SizedBox.shrink();
                if (controller.isCaller.value) return const SizedBox.shrink();
                if (_riderAcceptedRide) return const SizedBox.shrink();
                return _buildRiderFareCallActions(controller);
              }),

              // Bottom controls (WhatsApp pill — 5 buttons)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2733),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Obx(() {
                    final isConnected =
                        controller.callStatus.value == CallStatus.connected;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlButton(
                          icon: Icons.more_horiz_rounded,
                          label: 'More',
                          onTap: () => _showMoreOptions(context, controller),
                        ),
                        _ControlButton(
                          icon: Icons.videocam_off_rounded,
                          label: 'Switch to video',
                          isActive: controller.isSwitchTypePending.value,
                          onTap: (!isConnected ||
                                  controller.isSwitchTypePending.value)
                              ? () {}
                              : () => controller.switchCallType(),
                        ),
                        _buildAudioOutputButton(controller),
                        _ControlButton(
                          icon: controller.isMicOn.value
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          label: controller.isMicOn.value ? 'Mute' : 'Unmute',
                          isActive: !controller.isMicOn.value,
                          activeColor: Colors.red,
                          bold: !controller.isMicOn.value,
                          onTap: () => controller.toggleMic(),
                        ),
                        _ControlButton(
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          backgroundColor: const Color(0xFFEA4335),
                          onTap: () {
                            _ringbackPlayer.stop();
                            controller.endCall();
                          },
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== AVATAR CIRCLE ====================

  Widget _buildAvatarCircle({required String image, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
                placeholder: (context, url) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  // ==================== PiP MODE VIEW ====================

  Widget _buildPipModeView(CallController controller, bool isVideo) {
    if (isVideo) {
      final remoteRenderer = controller.remoteRenderers.values.firstOrNull;
      if (remoteRenderer != null && controller.remoteVideoEnabled.value) {
        return RTCVideoView(
          remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      }
    }
    return Container(
      color: const Color(0xFF111B21),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallCircleAvatar(
              name: controller.remoteUserName.value,
              image: controller.remoteUserImage.value,
              radius: 30,
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.formattedCallDuration,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ==================== VIDEO CALL BODY ====================

  Widget _buildVideoCallBody(CallController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double videoW = 110;
        const double videoH = 150;
        if (!_positionInitialized) {
          _localVideoX = constraints.maxWidth - videoW - 16;
          _localVideoY = constraints.maxHeight - videoH - 140;
          _positionInitialized = true;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Remote video (full screen)
            Obx(() {
              if (controller.remoteStreams.isNotEmpty &&
                  controller.remoteVideoEnabled.value) {
                final remoteRenderer =
                    controller.remoteRenderers.values.firstOrNull;
                if (remoteRenderer != null) {
                  return RTCVideoView(
                    remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  );
                }
              }
              return _buildAvatarPlaceholder(
                name: controller.remoteUserName.value,
                image: controller.remoteUserImage.value,
                showCameraOff: !controller.remoteVideoEnabled.value,
              );
            }),
            // Local video (draggable)
            if (controller.localRenderer != null)
              Obx(() {
                if (!controller.isCameraOn.value) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  left: _localVideoX,
                  top: _localVideoY,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _localVideoX = (_localVideoX + details.delta.dx)
                            .clamp(0.0, constraints.maxWidth - videoW);
                        _localVideoY = (_localVideoY + details.delta.dy)
                            .clamp(0.0, constraints.maxHeight - videoH);
                      });
                    },
                    child: Container(
                      width: videoW,
                      height: videoH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: RTCVideoView(
                        controller.localRenderer!,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // ==================== GROUP CALL BODY ====================

  Widget _buildGroupCallBody(CallController controller, bool isVideo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2C34), Color(0xFF0B141A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60, bottom: 100),
          child: Obx(() {
            final List<Widget> tiles = [];

            tiles.add(_buildParticipantTile(
              isLocal: true,
              isVideo: isVideo,
              name: 'You',
              image: '',
              isMuted: !controller.isMicOn.value,
              isCameraOff: !controller.isCameraOn.value,
              renderer: controller.localRenderer,
              mirror: true,
            ));

            for (final entry in controller.remoteStreams.entries) {
              final peerId = entry.key;
              final info = controller.participantMediaState[peerId] ?? {};
              tiles.add(_buildParticipantTile(
                isLocal: false,
                isVideo: isVideo && (info['video'] ?? true),
                name: (info['name'] ?? '').toString().isNotEmpty
                    ? info['name']
                    : 'Participant',
                image: info['image'] ?? '',
                isMuted: !(info['audio'] ?? true),
                isCameraOff: !(info['video'] ?? true),
                renderer: controller.remoteRenderers[peerId],
              ));
            }

            return _buildGroupGrid(tiles);
          }),
        ),
      ),
    );
  }

  Widget _buildGroupGrid(List<Widget> tiles) {
    final count = tiles.length;
    if (count <= 1) {
      return Center(child: tiles.isNotEmpty ? tiles[0] : const SizedBox());
    }
    if (count == 2) {
      return Column(
        children: tiles
            .map((t) => Expanded(
                child: Padding(padding: const EdgeInsets.all(4), child: t)))
            .toList(),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: count <= 4 ? 0.75 : 0.85,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count,
      itemBuilder: (context, i) => tiles[i],
    );
  }

  Widget _buildParticipantTile({
    required bool isLocal,
    required bool isVideo,
    required String name,
    required String image,
    required bool isMuted,
    required bool isCameraOff,
    RTCVideoRenderer? renderer,
    bool mirror = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF233138),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo && renderer != null && !isCameraOff)
            RTCVideoView(renderer,
                mirror: mirror,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
          else
            Center(
                child: _buildSmallCircleAvatar(
                    name: name, image: image, radius: 32)),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                if (isMuted)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_off,
                        color: Colors.white, size: 12),
                  ),
                if (isMuted) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isLocal ? 'You' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isCameraOff && isVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.videocam_off,
                    color: Colors.white70, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== TOP BAR (video/group active call) ====================

  Widget _buildTopBar(CallController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.close_fullscreen_rounded,
                  onTap: () async {
                    if (Platform.isAndroid) {
                      final entered = await _enterPipMode();
                      if (entered) return;
                    }
                    Get.back();
                  },
                ),
                Flexible(
                  child: Column(
                    children: [
                      Obx(() {
                        final isGroup = controller.isGroupCall.value;
                        return Text(
                          isGroup
                              ? 'Group Call'
                              : controller.remoteUserName.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                        );
                      }),
                      const SizedBox(height: 3),
                      Obx(() {
                        if (controller.callStatus.value ==
                            CallStatus.connected) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                controller.formattedCallDuration,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                controller.callType.value == CallType.video
                                    ? 'Video'
                                    : 'Audio',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Obx(() {
                    //   if (controller.callStatus.value ==
                    //       CallStatus.connected) {
                    //     return _CircleIconButton(
                    //       icon: Icons.person_add_alt_1_rounded,
                    //       onTap: () =>
                    //           _showAddUserBottomSheet(context, controller),
                    //     );
                    //   }
                    //   return const SizedBox(width: 44);
                    // }),
                    // Group participant count
                    Obx(() {
                      if (controller.isGroupCall.value) {
                        final count = controller.remoteStreams.length + 1;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people,
                                    color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text('$count',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ACTIVE BOTTOM CONTROLS (video/group) ====================

  Widget _buildActiveBottomControls(CallController controller) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2733),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Obx(() {
              final isVideo = controller.callType.value == CallType.video;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    onTap: () => _showMoreOptions(context, controller),
                  ),
                  _ControlButton(
                    icon: isVideo && controller.isCameraOn.value
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: 'Camera',
                    isActive: isVideo && !controller.isCameraOn.value,
                    onTap: () {
                      if (isVideo) {
                        controller.toggleCamera();
                      } else if (!controller.isSwitchTypePending.value) {
                        controller.switchCallType();
                      }
                    },
                  ),
                  _buildAudioOutputButton(controller),
                  _ControlButton(
                    icon: controller.isMicOn.value
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: controller.isMicOn.value ? 'Mute' : 'Unmute',
                    isActive: !controller.isMicOn.value,
                    activeColor: Colors.red,
                    bold: !controller.isMicOn.value,
                    onTap: () => controller.toggleMic(),
                  ),
                  _ControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    backgroundColor: const Color(0xFFEA4335),
                    onTap: () {
                      _ringbackPlayer.stop();
                      controller.endCall();
                    },
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ==================== AUDIO OUTPUT ROUTING ====================

  IconData _audioRouteIcon(AudioRoute route) {
    switch (route) {
      case AudioRoute.speaker:
        return Icons.volume_up_rounded;
      case AudioRoute.earpiece:
        return Icons.phone_in_talk_rounded;
      case AudioRoute.bluetooth:
        return Icons.bluetooth_audio_rounded;
      case AudioRoute.wiredHeadset:
        return Icons.headset_rounded;
    }
  }

  /// Speaker / audio-output button for the call pill. When a Bluetooth (or
  /// wired) headset is connected it opens the WhatsApp-style route picker;
  /// otherwise it behaves as a plain speaker toggle. The icon and highlight
  /// reflect the currently active route in real time.
  Widget _buildAudioOutputButton(CallController controller) {
    return Obx(() {
      final route = controller.currentAudioRoute.value;
      final hasPicker = controller.isBluetoothAvailable ||
          controller.isWiredHeadsetAvailable;
      // Highlight (white fill) whenever audio is off the earpiece.
      final active = route != AudioRoute.earpiece;
      return _ControlButton(
        icon: _audioRouteIcon(route),
        label: hasPicker ? 'Audio output' : 'Speaker',
        isActive: active,
        backgroundColor: active ? Colors.white : null,
        iconColor: active ? const Color(0xFF1F2C34) : Colors.white,
        onTap: () {
          if (hasPicker) {
            _showAudioOutputPicker(context, controller);
          } else {
            controller.toggleSpeaker();
          }
        },
      );
    });
  }

  /// WhatsApp-style bottom sheet listing the available audio outputs. Bluetooth
  /// / wired rows only appear while such a device is connected, and the list
  /// updates live (Obx) if a device connects or disconnects while it is open.
  void _showAudioOutputPicker(BuildContext context, CallController controller) {
    // Display order matches native WhatsApp: Speaker, Earpiece, then accessories.
    const order = [
      AudioRoute.speaker,
      AudioRoute.earpiece,
      AudioRoute.bluetooth,
      AudioRoute.wiredHeadset,
    ];
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Audio output',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Obx(() {
                final available = controller.availableAudioRoutes;
                final current = controller.currentAudioRoute.value;
                final rows = order
                    .where((r) => available.contains(r))
                    .map((route) {
                  final selected = route == current;
                  return ListTile(
                    leading: Icon(
                      _audioRouteIcon(route),
                      color: selected
                          ? const Color(0xFF25D366)
                          : Colors.white,
                    ),
                    title: Text(
                      route.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF25D366)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFF25D366))
                        : null,
                    onTap: () {
                      Get.back();
                      controller.selectAudioRoute(route);
                    },
                  );
                }).toList();
                return Column(mainAxisSize: MainAxisSize.min, children: rows);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MORE OPTIONS (Flip camera / Switch type) ====================

  void _showMoreOptions(BuildContext context, CallController controller) {
    final currentIsVideo = controller.callType.value == CallType.video;
    final isConnected = controller.callStatus.value == CallStatus.connected;
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              if (isConnected)
                ListTile(
                  leading: Icon(
                    currentIsVideo
                        ? Icons.call_rounded
                        : Icons.videocam_rounded,
                    color: Colors.white,
                  ),
                  title: Text(
                    currentIsVideo
                        ? 'Switch to audio call'
                        : 'Switch to video call',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  enabled: !controller.isSwitchTypePending.value,
                  onTap: () {
                    Get.back();
                    controller.switchCallType();
                  },
                ),
              if (currentIsVideo)
                ListTile(
                  leading: const Icon(Icons.flip_camera_ios_rounded,
                      color: Colors.white),
                  title: const Text(
                    'Flip camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    controller.switchCamera();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildAvatarPlaceholder({
    required String name,
    required String image,
    bool showCameraOff = false,
  }) {
    return Container(
      color: const Color(0xFF111B21),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatarCircle(image: image, size: 150),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            if (showCameraOff) ...[
              const SizedBox(height: 4),
              const Text(
                'Camera off',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCircleAvatar({
    required String name,
    required String image,
    required double radius,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2A3942),
      backgroundImage:
          image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
      child: image.isEmpty
          ? Icon(Icons.person, size: radius, color: const Color(0xFF8696A0))
          : null,
    );
  }

  // ==================== SWITCH CALL TYPE DIALOG ====================

  void _showSwitchTypeDialog(
      BuildContext context, CallController controller, String requestedBy) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Color(0xFF25D366), size: 24),
            SizedBox(width: 10),
            Text('Switch to Video',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '${controller.remoteUserName.value.isNotEmpty ? controller.remoteUserName.value : 'Participant'} wants to switch to a video call',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.respondToSwitchType(false);
            },
            child: const Text('Decline',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.respondToSwitchType(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Accept',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ==================== ADD USER TO CALL ====================

}

// ── Reusable Widgets ──────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2A3942),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// WhatsApp-style circle button used inside the bottom pill.
// `label` is kept only for accessibility (Semantics) — not rendered visually.
class _ControlButton extends StatelessWidget {
  static const double _size = 52;

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;
  final bool bold;
  final Color? backgroundColor;
  final Color? iconColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
    this.bold = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final useTintedActive = isActive && activeColor != null;
    final bg = backgroundColor ??
        (useTintedActive
            ? activeColor!.withValues(alpha: 0.22)
            : isActive
                ? const Color(0xFF3B4A54)
                : const Color(0xFF2A3942));
    final resolvedIconColor =
        iconColor ?? (useTintedActive ? activeColor! : Colors.white);
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: resolvedIconColor,
            size: _size * (bold ? 0.5 : 0.44),
            weight: bold ? 900 : 400,
          ),
        ),
      ),
    );
  }
}

// Pill button used by the rider's fare-call Accept/Reject row.
class _RiderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _RiderActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled && !isLoading ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: foregroundColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else
                Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background Pattern Painter ───────────────────────────────

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawRect(
          Rect.fromLTWH(x + 10, y + 10, 10, 10),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x + 30, y + 30, 6, 6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ── Legacy aliases for backward compatibility ────────────────
// IncomingCallScreen is now handled within CallActivityRoomScreen.
// This typedef ensures existing route references continue to work.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CallActivityRoomScreen();
  }
}
