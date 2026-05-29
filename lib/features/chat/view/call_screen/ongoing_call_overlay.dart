import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

/// WhatsApp-style ongoing-call chip that sits above the active route while a
/// call is alive and the user has navigated away from the call screen.
///
/// Layout (matches reference image):
///   ┌──────────────────────────────────────────────────┐
///   │  [🎤]   📞 Roshni - 0:04                  [📞❌] │
///   └──────────────────────────────────────────────────┘
///
/// - Left: mute toggle (tinted red when muted).
/// - Center: tap area — returns the user to the call screen. Shows a green
///   phone icon, the caller's name, and the live call duration / state.
/// - Right: hangup button.
///
/// Hidden automatically when:
///   - no call is active,
///   - a CallActivityRoomScreen is currently mounted (counter > 0),
///   - the app is in killed-state cold-start call mode (the home itself is
///     the call screen).
class OngoingCallOverlay extends StatelessWidget {
  const OngoingCallOverlay({super.key});

  static const _bgColor = Color(0xFF0B141A);
  static const _accentGreen = Color(0xFF25D366);
  static const _hangupRed = Color(0xFFEA4335);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CallController>()) {
      return const SizedBox.shrink();
    }

    final controller = Get.find<CallController>();

    return Obx(() {
      if (CallController.launchedForCall.value) {
        return const SizedBox.shrink();
      }

      final status = controller.callStatus.value;
      final isActive = status == CallStatus.connected ||
          status == CallStatus.connecting ||
          status == CallStatus.outgoing ||
          status == CallStatus.ringing ||
          status == CallStatus.accepting;
      if (!isActive) return const SizedBox.shrink();

      if (controller.callScreenInstanceCount.value > 0) {
        return const SizedBox.shrink();
      }

      final name = controller.remoteUserName.value.isNotEmpty
          ? controller.remoteUserName.value
          : (controller.callerName.value.isNotEmpty
              ? controller.callerName.value
              : 'Ongoing call');
      final subtitle = status == CallStatus.connected
          ? controller.formattedCallDuration
          : (status == CallStatus.connecting
              ? 'Connecting…'
              : (status == CallStatus.outgoing
                  ? 'Ringing…'
                  : 'Incoming call'));

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: _bgColor,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: controller.isMicOn.value
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                      onTap: controller.toggleMic,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _returnToCall,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              color: _accentGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                '$name - $subtitle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _accentGreen,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'OpenSans',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _CircleButton(
                      icon: Icons.call_end_rounded,
                      iconColor: _hangupRed,
                      onTap: () => _endCall(controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Push CallRoomScreen back on top. `preventDuplicates: true` blocks a
  /// re-push if the chip is tapped while a route transition is already
  /// running.
  static void _returnToCall() {
    const callRoute = '/CallRoomScreen';
    final route = Get.currentRoute;
    if (route == callRoute ||
        route == '/IncomingCallScreen' ||
        route == '/OutgoingCallScreen' ||
        route == '/ActiveCallScreen') {
      return;
    }
    Get.toNamed(callRoute, preventDuplicates: true);
  }

  /// End the call from the chip's hangup button. Outgoing/ringing states
  /// use the matching cancel path so the server gets the correct event;
  /// active/connecting states use endCall.
  static void _endCall(CallController controller) {
    final status = controller.callStatus.value;
    if (status == CallStatus.outgoing || status == CallStatus.ringing) {
      controller.cancelCall();
    } else {
      controller.endCall();
    }
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF2A3942),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
