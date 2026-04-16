import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/getx_utils.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';

/// Global overlay bar shown at the top of every screen when the rider is live.
/// Similar to a WhatsApp call bar — dark background with a pulsing green dot,
/// "I'm Live" label, and elapsed time.
class RiderLiveOverlay extends StatelessWidget {
  const RiderLiveOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        getOrPut(() => ViewPersonalDetailsController());

    return Obx(() {
      if (!controller.shopStatusOpenClose.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () {
              // Navigate to rider service screen if not already there
              if (Get.currentRoute != '/RiderServiceScreen') {
                Get.toNamed('/RiderServiceScreen');
              }
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1A2E35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Pulsing green dot
                  const _PulsingDot(),
                  const SizedBox(width: 10),

                  // "I'm Live" label
                  const Expanded(
                    child: Text(
                      "I'm Live",
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'OpenSans',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  // Go Offline button
                  GestureDetector(
                    onTap: () => controller.toggleShopStatus(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Go Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
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

/// Animated pulsing green dot indicator
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final opacity = 0.4 + (_controller.value * 0.6);
        final scale = 0.8 + (_controller.value * 0.2);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C853).withValues(alpha: opacity),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF00C853).withValues(alpha: opacity * 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
