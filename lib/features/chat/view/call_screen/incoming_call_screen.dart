import 'dart:ui';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(controller),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Obx(() => Text(
                      controller.callerName.value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    )),
                const SizedBox(height: 8),
                Obx(() => Text(
                      controller.callType.value == CallType.video
                          ? 'Incoming Video Call'
                          : 'Incoming Audio Call',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                      ),
                    )),
                const SizedBox(height: 40),
                Obx(() => CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          controller.callerImage.value.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  controller.callerImage.value)
                              : null,
                      child: controller.callerImage.value.isEmpty
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    )),
                const Spacer(),
                // Accept / Decline buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline
                      _buildActionButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'Decline',
                        onTap: () => controller.declineCall(),
                      ),
                      // Accept
                      _buildActionButton(
                        icon: Icons.call,
                        color: Colors.green,
                        label: 'Accept',
                        onTap: () async {
                          final accepted = await controller.acceptCall();
                          if (accepted) {
                            Get.offNamed('/ActiveCallScreen');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(CallController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Obx(() {
          if (controller.callerImage.value.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: controller.callerImage.value,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF1a1a2e)),
            );
          }
          return Container(color: const Color(0xFF1a1a2e));
        }),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(color: Colors.black.withOpacity(0.4)),
        ),
      ],
    );
  }
}
