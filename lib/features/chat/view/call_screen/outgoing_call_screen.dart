import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

class OutgoingCallScreen extends StatefulWidget {
  const OutgoingCallScreen({super.key});

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotController;
  late Worker _callStatusWorker;
  final AudioPlayer _ringbackPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _playRingback();

    // Watch call status — stop ringback when call is accepted/declined/ended
    final controller = Get.find<CallController>();
    _callStatusWorker = ever(controller.callStatus, (status) {
      if (!mounted) return;
      if (status == CallStatus.idle ||
          status == CallStatus.connecting ||
          status == CallStatus.connected) {
        _ringbackPlayer.stop();
      }
    });
  }

  Future<void> _playRingback() async {
    try {
      await _ringbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringbackPlayer.play(AssetSource('sound/iphone_tone.mp3'));
      await _ringbackPlayer.setVolume(0.3);
    } catch (_) {}
  }

  @override
  void dispose() {
    _callStatusWorker.dispose();
    _pulseController.dispose();
    _dotController.dispose();
    _ringbackPlayer.stop();
    _ringbackPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Scaffold(
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
              const SizedBox(height: 20),
              // Encryption label
              _buildEncryptionLabel(),
              const SizedBox(height: 16),
              // Remote user name
              Obx(() => Text(
                    controller.remoteUserName.value.isNotEmpty
                        ? controller.remoteUserName.value
                        : 'Calling...',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'OpenSans',
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  )),
              const SizedBox(height: 6),
              // Calling status with animated dots
              _buildCallingStatus(),
              const SizedBox(height: 4),
              // Call type
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
                      const SizedBox(width: 4),
                      Text(
                        controller.callType.value == CallType.video
                            ? 'Video Call'
                            : 'Voice Call',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'OpenSans',
                          color: Color(0xFF8696A0),
                        ),
                      ),
                    ],
                  )),

              // Avatar with pulse
              Expanded(
                child: Center(
                  child: Obx(() => _buildPulsingAvatar(controller)),
                ),
              ),

              // Bottom controls
              _buildBottomControls(controller),
              const SizedBox(height: 40),
            ],
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

  Widget _buildCallingStatus() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) {
        final dotCount = (_dotController.value * 4).floor().clamp(0, 3);
        final dots = '.' * dotCount;
        return Text(
          'Ringing$dots',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8696A0),
            fontFamily: 'OpenSans',
          ),
        );
      },
    );
  }

  Widget _buildPulsingAvatar(CallController controller) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple rings
              for (int i = 0; i < 3; i++) _buildRippleRing(i),
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
              color: const Color(0xFF00A884).withValues(alpha: 0.15),
              blurRadius: 25,
              spreadRadius: 3,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF2A3942),
          backgroundImage: controller.remoteUserImage.value.isNotEmpty
              ? CachedNetworkImageProvider(controller.remoteUserImage.value)
              : null,
          child: controller.remoteUserImage.value.isEmpty
              ? const Icon(Icons.person_rounded,
                  size: 60, color: Color(0xFF8696A0))
              : null,
        ),
      ),
    );
  }

  Widget _buildRippleRing(int index) {
    final delay = index * 0.33;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        double progress = (_pulseController.value + delay) % 1.0;
        double size = 120 + (progress * 100);
        double opacity = (1.0 - progress) * 0.3;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00A884).withValues(alpha: opacity),
              width: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(CallController controller) {
    return Column(
      children: [
        // Quick action buttons
        Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: controller.isSpeakerOn.value
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'Speaker',
                    isActive: controller.isSpeakerOn.value,
                    onTap: () => controller.toggleSpeaker(),
                  ),
                  if (controller.callType.value == CallType.video)
                    _buildControlButton(
                      icon: controller.isCameraOn.value
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: 'Camera',
                      isActive: !controller.isCameraOn.value,
                      onTap: () => controller.toggleCamera(),
                    ),
                  _buildControlButton(
                    icon: controller.isMicOn.value
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: 'Mute',
                    isActive: !controller.isMicOn.value,
                    onTap: () => controller.toggleMic(),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 36),
        // Cancel button
        GestureDetector(
          onTap: () {
            _ringbackPlayer.stop();
            controller.cancelCall();
          },
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
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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
}
