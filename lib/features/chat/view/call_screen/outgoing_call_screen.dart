import 'dart:ui';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          _buildBackground(controller),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Caller info
                Obx(() => Text(
                      controller.remoteUserName.value,
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
                          ? 'Video Calling...'
                          : 'Audio Calling...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                      ),
                    )),
                const SizedBox(height: 40),
                // Avatar
                Obx(() => CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white24,
                      backgroundImage: controller
                              .remoteUserImage.value.isNotEmpty
                          ? CachedNetworkImageProvider(
                              controller.remoteUserImage.value)
                          : null,
                      child: controller.remoteUserImage.value.isEmpty
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    )),
                const Spacer(),
                // Hang up button
                GestureDetector(
                  onTap: () => controller.cancelCall(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
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

  Widget _buildBackground(CallController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Obx(() {
          if (controller.remoteUserImage.value.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: controller.remoteUserImage.value,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF1a1a2e),
              ),
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
