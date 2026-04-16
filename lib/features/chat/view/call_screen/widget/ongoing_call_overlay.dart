import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../auth/controller/call_controller.dart';

/// WhatsApp-style in-app overlay shown at the top of the screen when a call is
/// active but the user is on a different screen. Shows caller name, duration,
/// mute toggle, and hang-up button. Tapping the bar returns to the call screen.
class OngoingCallOverlay extends StatelessWidget {
  const OngoingCallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => CallController());

    return Obx(() {
      final status = controller.callStatus.value;

      // Show for ANY non-idle call state
      final isActive = status == CallStatus.ringing ||
          status == CallStatus.outgoing ||
          status == CallStatus.accepting ||
          status == CallStatus.connecting ||
          status == CallStatus.connected ||
          controller.isIncomingCall.value == true;

      // Don't show overlay when user is already on a call screen
      final route = Get.currentRoute;
      final isOnCallScreen = route == '/ActiveCallScreen' ||
          route == '/OutgoingCallScreen' ||
          route == '/IncomingCallScreen' ||
          route == '/CallRoomScreen' ||
          route == '/IncomingRiderOrderScreen';

      if (!isActive || isOnCallScreen) {
        return const SizedBox.shrink();
      }

      final isConnected = status == CallStatus.connected;
      final isRinging = status == CallStatus.ringing ||
          controller.isIncomingCall.value == true;
      final name = controller.callerName.value.isNotEmpty
          ? controller.callerName.value
          : (controller.remoteUserName.value.isNotEmpty
              ? controller.remoteUserName.value
              : 'Call');

      final isVideo = controller.callType.value == CallType.video;

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () {
              if (controller.isIncomingCall.value == true) {
                Get.toNamed('/IncomingCallScreen');
              } else if (controller.isFareCall.value) {
                Get.toNamed('/IncomingRiderOrderScreen');
              } else {
                if (Get.currentRoute != '/CallRoomScreen') {
                  Get.toNamed('/CallRoomScreen');
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isRinging
                    ? const Color(0xFF1A2E35)
                    : const Color(0xFF00A884),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Call icon
                  Icon(
                    isVideo
                        ? Icons.videocam_rounded
                        : Icons.phone_in_talk_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),

                  // Name & duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        CustomText(
                          isConnected
                              ? controller.formattedCallDuration
                              : isRinging
                                  ? 'Incoming call...'
                                  : AppStrings.connectingLabel.tr,
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.normal,
                        ),
                      ],
                    ),
                  ),

                  // Mute button
                  _OverlayButton(
                    icon: controller.isMicOn.value
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    isActive: !controller.isMicOn.value,
                    onTap: () => controller.toggleMic(),
                  ),
                  const SizedBox(width: 12),

                  // Hang up button
                  _OverlayButton(
                    icon: Icons.call_end_rounded,
                    isActive: false,
                    isHangUp: true,
                    onTap: () {
                      if (isRinging) {
                        controller.declineCall();
                      } else {
                        controller.endCall();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isHangUp;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.icon,
    required this.isActive,
    this.isHangUp = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHangUp
              ? const Color(0xFFEA4335)
              : (isActive
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
