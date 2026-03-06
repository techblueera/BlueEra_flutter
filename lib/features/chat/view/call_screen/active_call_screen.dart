import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Obx(() {
        final isVideo = controller.callType.value == CallType.video;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Main content area
            if (isVideo) _buildVideoCallBody(controller) else _buildAudioCallBody(controller),
            // Top bar
            _buildTopBar(controller),
            // Bottom controls
            _buildBottomControls(controller, isVideo),
          ],
        );
      }),
    );
  }

  // ==================== VIDEO CALL ====================

  Widget _buildVideoCallBody(CallController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Remote video (full screen)
        Obx(() {
          if (controller.remoteStreams.isNotEmpty &&
              controller.remoteVideoEnabled.value) {
            final remoteRenderer =
                controller.remoteRenderers.values.firstOrNull;
            if (remoteRenderer != null) {
              return RTCVideoView(
                remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              );
            }
          }
          // Show avatar when no remote video
          return _buildRemoteAvatarView(controller);
        }),
        // Local video PiP (top right)
        if (controller.localRenderer != null)
          Positioned(
            top: 100,
            right: 16,
            child: Obx(() {
              if (!controller.isCameraOn.value) {
                return const SizedBox.shrink();
              }
              return Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: RTCVideoView(
                  controller.localRenderer!,
                  mirror: true,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildRemoteAvatarView(CallController controller) {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      controller.remoteUserImage.value.isNotEmpty
                          ? CachedNetworkImageProvider(
                              controller.remoteUserImage.value)
                          : null,
                  child: controller.remoteUserImage.value.isEmpty
                      ? const Icon(Icons.person,
                          size: 50, color: Colors.white)
                      : null,
                )),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.remoteUserName.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                )),
            const SizedBox(height: 4),
            Obx(() {
              if (!controller.remoteVideoEnabled.value) {
                return const Text(
                  'Camera off',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  // ==================== AUDIO CALL ====================

  Widget _buildAudioCallBody(CallController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        Obx(() {
          if (controller.remoteUserImage.value.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: controller.remoteUserImage.value,
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
        // Avatar + info
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        controller.remoteUserImage.value.isNotEmpty
                            ? CachedNetworkImageProvider(
                                controller.remoteUserImage.value)
                            : null,
                    child: controller.remoteUserImage.value.isEmpty
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.white)
                        : null,
                  )),
              const SizedBox(height: 16),
              Obx(() => Text(
                    controller.remoteUserName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  )),
              const SizedBox(height: 8),
              // Duration or connecting
              Obx(() {
                if (controller.callStatus.value == CallStatus.connected) {
                  return Text(
                    controller.formattedCallDuration,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  );
                }
                return const Text(
                  'Connecting...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                );
              }),
              // Mute indicator
              Obx(() {
                if (!controller.remoteAudioEnabled.value) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_off, color: Colors.redAccent, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Muted',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TOP BAR ====================

  Widget _buildTopBar(CallController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.lock_outline,
                  color: Colors.white54, size: 18),
              const Text(
                'End-to-end encrypted',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              // Duration for video calls
              Obx(() {
                if (controller.callType.value == CallType.video &&
                    controller.callStatus.value == CallStatus.connected) {
                  return Text(
                    controller.formattedCallDuration,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BOTTOM CONTROLS ====================

  Widget _buildBottomControls(CallController controller, bool isVideo) {
    return Positioned(
      bottom: 20,
      left: 32,
      right: 32,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic toggle
                  Obx(() => _buildControlButton(
                        icon: controller.isMicOn.value
                            ? Icons.mic
                            : Icons.mic_off,
                        isActive: !controller.isMicOn.value,
                        onTap: () => controller.toggleMic(),
                      )),
                  // Speaker toggle
                  Obx(() => _buildControlButton(
                        icon: controller.isSpeakerOn.value
                            ? Icons.volume_up
                            : Icons.volume_down,
                        isActive: controller.isSpeakerOn.value,
                        onTap: () => controller.toggleSpeaker(),
                      )),
                  // Camera toggle (video only)
                  if (isVideo)
                    Obx(() => _buildControlButton(
                          icon: controller.isCameraOn.value
                              ? Icons.videocam
                              : Icons.videocam_off,
                          isActive: !controller.isCameraOn.value,
                          onTap: () => controller.toggleCamera(),
                        )),
                  // Switch camera (video only)
                  if (isVideo)
                    _buildControlButton(
                      icon: Icons.cameraswitch,
                      onTap: () => controller.switchCamera(),
                    ),
                  // End call
                  GestureDetector(
                    onTap: () => controller.endCall(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
