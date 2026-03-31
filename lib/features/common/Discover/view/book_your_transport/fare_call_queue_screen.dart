import 'dart:async';

import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../chat/auth/controller/call_controller.dart';
import '../../controller/discover_controller.dart';

/// Customer-side calling screen shown after placing a fare-call order.
/// Shows call controls (mute, speaker, end call), ringing animation,
/// call timer when connected, and queue progress (rider X of Y).
class FareCallQueueScreen extends StatefulWidget {
  final String orderId;

  const FareCallQueueScreen({super.key, required this.orderId});

  @override
  State<FareCallQueueScreen> createState() => _FareCallQueueScreenState();
}

class _FareCallQueueScreenState extends State<FareCallQueueScreen>
    with TickerProviderStateMixin {
  final discoverController = getOrPut(() => DiscoverController());
  late final CallController _callController;

  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Worker _queueAcceptedWorker;
  late Worker _queueExhaustedWorker;
  late Worker _callStatusWorker;

  // Local call timer (independent fallback)
  Timer? _localTimer;
  int _localSeconds = 0;

  @override
  void initState() {
    super.initState();

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
        _showRideAcceptedDialog(riderInfo);
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
    _pulseController.dispose();
    _ringController.dispose();
    _queueAcceptedWorker.dispose();
    _queueExhaustedWorker.dispose();
    _callStatusWorker.dispose();
    _localTimer?.cancel();
    super.dispose();
  }

  void _endCallAndGoBack() {
    _callController.endCall();
    discoverController.cancelFareCallQueue();
    discoverController.resetFareCallState();
    Get.back();
  }

  void _showRideAcceptedDialog(Map<String, dynamic> riderInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00C853), size: 56),
            const SizedBox(height: 16),
            const Text(
              'Rider Accepted!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'OpenSans'),
            ),
            const SizedBox(height: 8),
            Text(
              riderInfo['name'] ?? 'Rider',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'OpenSans'),
            ),
            if (riderInfo['contact'] != null) ...[
              const SizedBox(height: 4),
              Text(
                riderInfo['contact'],
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'OpenSans'),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Your ride is confirmed. You are on a call with the rider.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'OpenSans'),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK', style: TextStyle(fontFamily: 'OpenSans')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _endCallAndGoBack();
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
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Encryption label
                _buildEncryptionLabel(),
                const SizedBox(height: 12),
                // Queue status
                _buildQueueStatus(),
                const SizedBox(height: 8),
                // Call status / timer
                _buildCallStatus(),
                const SizedBox(height: 8),
                // Progress dots
                _buildProgressDots(),

                // Avatar with ripple
                Expanded(child: Center(child: _buildCallingAvatar())),

                // Ride summary card
                _buildRideSummary(),
                const SizedBox(height: 24),

                // Call action buttons
                _buildCallActions(),
                const SizedBox(height: 16),

                // End call button
                _buildEndCallButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
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
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF2A3942),
            child: const Icon(Icons.delivery_dining_rounded,
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
      final isMicOn = _callController.isMicOn.value;
      final isSpeakerOn = _callController.isSpeakerOn.value;
      final isConnected =
          _callController.callStatus.value == CallStatus.connected;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute
            _buildActionBtn(
              icon: isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: isMicOn ? 'Mute' : 'Unmute',
              isActive: !isMicOn,
              onTap: () => _callController.toggleMic(),
              enabled: isConnected,
            ),
            // Speaker
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
            child:
                const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
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
