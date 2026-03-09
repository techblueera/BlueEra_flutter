import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

class OutgoingCallScreen extends StatelessWidget {
  const OutgoingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Scaffold(
      backgroundColor: const Color(0xFF121B22),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F2C34), Color(0xFF0B141A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top encryption label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      color: Colors.white.withValues(alpha: 0.4), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'End-to-end encrypted',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Avatar with pulse ring
              Obx(() => _buildPulsingAvatar(controller)),
              const SizedBox(height: 24),
              // Name
              Obx(() => Text(
                    controller.remoteUserName.value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  )),
              const SizedBox(height: 8),
              // Call type
              Obx(() => Text(
                    controller.callType.value == CallType.video
                        ? 'Ringing...'
                        : 'Ringing...',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                      color: Color(0xFF8696A0),
                    ),
                  )),
              const SizedBox(height: 4),
              Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.callType.value == CallType.video
                            ? Icons.videocam
                            : Icons.call,
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
                          fontFamily: 'Poppins',
                          color: Color(0xFF8696A0),
                        ),
                      ),
                    ],
                  )),
              const Spacer(),
              // Hang up button
              GestureDetector(
                onTap: () => controller.cancelCall(),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA4335),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingAvatar(CallController controller) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          padding: EdgeInsets.all(8 + (value * 6)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00A884).withValues(alpha: 0.3 - (value * 0.3)),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF2A3942),
        backgroundImage: controller.remoteUserImage.value.isNotEmpty
            ? CachedNetworkImageProvider(controller.remoteUserImage.value)
            : null,
        child: controller.remoteUserImage.value.isEmpty
            ? const Icon(Icons.person, size: 60, color: Color(0xFF8696A0))
            : null,
      ),
    );
  }
}
