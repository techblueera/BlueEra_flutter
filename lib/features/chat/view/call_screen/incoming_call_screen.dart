import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Worker _callStatusWorker;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for ripple rings
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Ring shake animation for the phone icon
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Ringtone is played by CallController.startRingtone() in _handleIncomingCall
    // so it can be reliably stopped regardless of screen lifecycle.
    HapticFeedback.heavyImpact();

    // Watch call status to auto-close when call is cancelled/ended/answered elsewhere
    final controller = Get.find<CallController>();
    _callStatusWorker = ever(controller.callStatus, (status) {
      if (!mounted) return;
      if (status == CallStatus.idle ||
          status == CallStatus.connected ||
          status == CallStatus.ended) {
        controller.stopRingtone();
      }
    });
  }

  @override
  void dispose() {
    _callStatusWorker.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    // Stop controller ringtone on screen dispose as safety net
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().stopRingtone();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return WillPopScope(

      onWillPop: () async{
        controller.isIncomingCall.value= true;
        return true;
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
                const SizedBox(height: 20),
                // Encryption label
                _buildEncryptionLabel(),
                const SizedBox(height: 16),
                // Caller info
                Obx(() => Text(
                      controller.callerName.value.isNotEmpty
                          ? controller.callerName.value
                          : 'Unknown',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'OpenSans',
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    )),
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
                        CustomText(
                          controller.callType.value == CallType.video
                              ? AppStrings.blueEraVideoCall.tr
                              : AppStrings.blueEraVoiceCall.tr,
                          fontSize: 14,
                          color: const Color(0xFF8696A0),
                          fontFamily: 'OpenSans',
                        ),
                      ],
                    )),

                // Avatar with ripple rings
                Expanded(
                  child: Center(
                    child: Obx(() => _buildRippleAvatar(controller)),
                  ),
                ),

                // Bottom section: Decline + Accept buttons or Slide to answer
                _buildBottomActions(controller),
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
        CustomText(
          AppStrings.endToEndEncrypted.tr,
          fontSize: 11,
          fontFamily: 'OpenSans',
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ],
    );
  }

  Widget _buildRippleAvatar(CallController controller) {
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
              for (int i = 0; i < 3; i++)
                _buildRippleRing(i),
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

  Widget _buildBottomActions(CallController controller) {
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
            CustomText(
              AppStrings.connectingLabel.tr,
              color: const Color(0xFF8696A0),
              fontSize: 14,
              fontFamily: 'OpenSans',
            ),
          ],
        );
      }

      return Column(
        children: [
          // Quick action row (Message, Remind me)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallAction(
                  icon: Icons.message_rounded,
                  label: AppStrings.messageLabel.tr,
                  onTap: () {
                    controller.stopRingtone();
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
                _buildCallButton(
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFFEA4335),
                  label: AppStrings.declineLabel.tr,
                  onTap: () {
                    controller.stopRingtone();
                    controller.declineCall();
                  },
                ),
                // Accept
                _buildCallButton(
                  icon: controller.callType.value == CallType.video
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: const Color(0xFF00A884),
                  label: AppStrings.acceptLabel.tr,
                  onTap: () async {
                    controller.stopRingtone();
                    setState(() => _isAccepting = true);
                    // acceptCall() handles launching CallActivity on Android main engine,
                    // or does full WebRTC setup in CallActivity engine / iOS.
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

  Widget _buildCallButton({
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
}
