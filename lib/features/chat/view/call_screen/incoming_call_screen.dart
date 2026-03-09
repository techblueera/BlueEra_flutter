import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

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
              // Caller avatar
              Obx(() => CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF2A3942),
                    backgroundImage:
                        controller.callerImage.value.isNotEmpty
                            ? CachedNetworkImageProvider(
                                controller.callerImage.value)
                            : null,
                    child: controller.callerImage.value.isEmpty
                        ? const Icon(Icons.person,
                            size: 60, color: Color(0xFF8696A0))
                        : null,
                  )),
              const SizedBox(height: 24),
              // Caller name
              Obx(() => Text(
                    controller.callerName.value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  )),
              const SizedBox(height: 8),
              // Call type
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
                      const SizedBox(width: 6),
                      Text(
                        controller.callType.value == CallType.video
                            ? 'Incoming Video Call'
                            : 'Incoming Voice Call',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Poppins',
                          color: Color(0xFF8696A0),
                        ),
                      ),
                    ],
                  )),
              const Spacer(),
              // Accept / Decline buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline
                    _buildCallActionButton(
                      icon: Icons.call_end,
                      color: const Color(0xFFEA4335),
                      label: 'Decline',
                      onTap: () => controller.declineCall(),
                    ),
                    // Accept
                    Obx(() {
                      final isAccepting =
                          controller.callStatus.value == CallStatus.accepting;
                      return _buildCallActionButton(
                        icon: controller.callType.value == CallType.video
                            ? Icons.videocam
                            : Icons.call,
                        color: isAccepting
                            ? const Color(0xFF4B7A5B)
                            : const Color(0xFF00A884),
                        label: isAccepting ? 'Accepting...' : 'Accept',
                        onTap: isAccepting
                            ? () {}
                            : () async {
                                final accepted =
                                    await controller.acceptCall();
                                if (accepted) {
                                  Get.offNamed('/ActiveCallScreen');
                                }
                              },
                      );
                    }),
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

  Widget _buildCallActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
