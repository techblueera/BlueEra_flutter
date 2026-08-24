import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

/// WhatsApp-style green call bar pinned to the top of every screen while a call
/// is live and the user has navigated away from the call UI.
///
/// Tapping the bar returns to the call room; the red button on the right ends
/// the call without going back to it first.
///
/// It is mounted once, in main.dart's `GetMaterialApp.builder`, via
/// [OngoingCallStrip.wrap] — so it survives route changes and shows on top of
/// whatever screen the user wandered off to.
class OngoingCallStrip extends StatelessWidget {
  const OngoingCallStrip({super.key});

  /// Height of the coloured bar itself, excluding the status-bar inset.
  static const double barHeight = 38;

  static const Color _green = Color(0xFF00A884);

  /// Wrap the app so the strip sits *above* the content and the app shrinks to
  /// fit, rather than floating over and covering everyone's app bar — which is
  /// what WhatsApp does and what makes the bar feel native instead of pasted on.
  ///
  /// The child's MediaQuery is shrunk to match, so screens that size themselves
  /// off `MediaQuery.size.height` stay correct instead of overflowing by the
  /// bar's height. Its top padding is zeroed because the bar has already
  /// consumed the status-bar area.
  static Widget wrap(Widget child) => _OngoingCallStripHost(child: child);

  /// A call is live but its screen is not on top — the one state this bar is for.
  static bool get shouldShow {
    // Read the static observables FIRST. They exist whether or not the
    // controller is registered, so the enclosing Obx always has something to
    // track — bail out before touching any observable and Obx throws
    // "improper use of Obx".
    final callScreensMounted = CallController.callScreensMounted.value;
    final everShown = CallController.callRoomEverShown.value;
    if (!Get.isRegistered<CallController>()) return false;
    // The call screen is on top — nothing to return to.
    if (callScreensMounted > 0) return false;
    // The call screen has not been shown yet for this call (still setting up,
    // or still booting into it from a killed state). Showing the strip here
    // would flash it over the screen we are about to replace.
    if (!everShown) return false;
    final controller = Get.find<CallController>();
    // Fare-calls and rider orders drive their own dedicated UI (the queue
    // screen / order card) and are deliberately left alone.
    if (controller.isFareCall.value) return false;
    switch (controller.callStatus.value) {
      case CallStatus.outgoing:
      case CallStatus.accepting:
      case CallStatus.connecting:
      case CallStatus.connected:
        return true;
      // `ringing` is an unanswered incoming call — it owns the full screen
      // until the user picks it up, so no bar for it.
      case CallStatus.ringing:
      case CallStatus.idle:
      case CallStatus.ended:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Material(
      color: _green,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: InkWell(
            onTap: () {
              if (Get.currentRoute != '/CallRoomScreen') {
                Get.toNamed('/CallRoomScreen');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Obx(() {
                    final isVideo =
                        controller.callType.value == CallType.video;
                    return Icon(
                      isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: Colors.white,
                      size: 16,
                    );
                  }),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Text(
                        _label(controller),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _EndCallButton(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _label(CallController controller) {
    switch (controller.callStatus.value) {
      case CallStatus.outgoing:
        return 'Calling…  Tap to return';
      case CallStatus.accepting:
      case CallStatus.connecting:
        return 'Connecting…  Tap to return';
      case CallStatus.connected:
        return '${controller.formattedCallDuration}  ·  Tap to return to call';
      default:
        return 'Tap to return to call';
    }
  }
}

/// Red hang-up affordance. Deliberately a small pill rather than a bare icon:
/// it sits inside a tappable bar, so it needs to read as its own target.
class _EndCallButton extends StatelessWidget {
  final CallController controller;

  const _EndCallButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'End call',
      button: true,
      child: InkWell(
        onTap: controller.endCall,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEA4335),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_end_rounded, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                'End',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OngoingCallStripHost extends StatelessWidget {
  final Widget child;

  const _OngoingCallStripHost({required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!OngoingCallStrip.shouldShow) return child;

      final media = MediaQuery.of(context);
      final consumed = media.padding.top + OngoingCallStrip.barHeight;

      return Column(
        children: [
          const OngoingCallStrip(),
          Expanded(
            child: MediaQuery(
              data: media.copyWith(
                size: Size(
                  media.size.width,
                  (media.size.height - consumed).clamp(0.0, media.size.height),
                ),
                padding: media.padding.copyWith(top: 0),
                viewPadding: media.viewPadding.copyWith(top: 0),
              ),
              child: child,
            ),
          ),
        ],
      );
    });
  }
}
