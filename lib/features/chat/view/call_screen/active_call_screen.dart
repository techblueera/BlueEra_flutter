import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';
import '../../auth/controller/call_controller.dart';
import '../../auth/controller/chat_view_controller.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  late Worker _switchTypeWorker;

  // Draggable local video position
  double _localVideoX = -1;
  double _localVideoY = -1;
  bool _positionInitialized = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CallController>();
    // Watch for incoming switch type requests
    _switchTypeWorker = ever(controller.switchTypeRequestedBy, (requestedBy) {
      if (requestedBy.isNotEmpty && mounted) {
        _showSwitchTypeDialog(context, controller, requestedBy);
      }
    });
  }

  @override
  void dispose() {
    _switchTypeWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return PopScope(
      canPop: !controller.isInPipMode.value,
      child: Scaffold(
        backgroundColor: const Color(0xFF121B22),
        body: Obx(() {
          final isVideo = controller.callType.value == CallType.video;
          final isGroup = controller.isGroupCall.value;
          final isPip = controller.isInPipMode.value;

          // PiP mode: show minimal UI
          if (isPip) {
            return _buildPipModeUI(controller, isVideo);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Main content area
              if (isGroup)
                _buildGroupCallBody(controller, isVideo)
              else if (isVideo)
                _buildVideoCallBody(controller)
              else
                _buildAudioCallBody(controller),
              // Top bar
              _buildTopBar(context, controller),
              // Bottom controls
              _buildBottomControls(controller, isVideo),
            ],
          );
        }),
      ),
    );
  }

  // ==================== PiP MODE UI ====================

  Widget _buildPipModeUI(CallController controller, bool isVideo) {
    // Minimal UI shown in PiP window
    if (isVideo && controller.remoteStreams.isNotEmpty) {
      final remoteRenderer = controller.remoteRenderers.values.firstOrNull;
      if (remoteRenderer != null) {
        return RTCVideoView(
          remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      }
    }
    // Audio call or no remote video — show avatar + timer
    return Container(
      color: const Color(0xFF121B22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleAvatar(
              name: controller.remoteUserName.value,
              image: controller.remoteUserImage.value,
              radius: 30,
            ),
            const SizedBox(height: 8),
            Text(
              controller.formattedCallDuration,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 1-to-1 VIDEO CALL ====================

  Widget _buildVideoCallBody(CallController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double videoW = 110;
        const double videoH = 150;
        // Initialize position to bottom-right on first build
        if (!_positionInitialized) {
          _localVideoX = constraints.maxWidth - videoW - 16;
          _localVideoY = constraints.maxHeight - videoH - 140;
          _positionInitialized = true;
        }

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
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  );
                }
              }
              return _buildAvatarPlaceholder(
                name: controller.remoteUserName.value,
                image: controller.remoteUserImage.value,
                radius: 50,
                showCameraOff: !controller.remoteVideoEnabled.value,
              );
            }),
            // Local video PiP (draggable anywhere)
            if (controller.localRenderer != null)
              Obx(() {
                if (!controller.isCameraOn.value) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  left: _localVideoX,
                  top: _localVideoY,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _localVideoX = (_localVideoX + details.delta.dx)
                            .clamp(0.0, constraints.maxWidth - videoW);
                        _localVideoY = (_localVideoY + details.delta.dy)
                            .clamp(0.0, constraints.maxHeight - videoH);
                      });
                    },
                    child: Container(
                      width: videoW,
                      height: videoH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: RTCVideoView(
                        controller.localRenderer!,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // ==================== 1-to-1 AUDIO CALL ====================

  Widget _buildAudioCallBody(CallController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark gradient background (WhatsApp style)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F2C34), Color(0xFF0B141A)],
            ),
          ),
        ),
        // Avatar + info centered
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleAvatar(
                name: controller.remoteUserName.value,
                image: controller.remoteUserImage.value,
                radius: 55,
              ),
              const SizedBox(height: 20),
              Obx(() => Text(
                    controller.remoteUserName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  )),
              const SizedBox(height: 8),
              Obx(() => _buildCallStatusText(controller)),
              // Remote mute indicator
              Obx(() {
                if (!controller.remoteAudioEnabled.value) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_off,
                            color: Colors.redAccent, size: 16),
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

  // ==================== GROUP CALL (WhatsApp Style Grid) ====================

  Widget _buildGroupCallBody(CallController controller, bool isVideo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2C34), Color(0xFF0B141A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60, bottom: 100),
          child: Obx(() {
            // Build participant tiles: local user + all remote peers
            final List<Widget> tiles = [];

            // Local user tile
            tiles.add(_buildParticipantTile(
              isLocal: true,
              isVideo: isVideo,
              name: 'You',
              image: '',
              isMuted: !controller.isMicOn.value,
              isCameraOff: !controller.isCameraOn.value,
              renderer: controller.localRenderer,
              mirror: true,
            ));

            // Remote participant tiles
            for (final entry in controller.remoteStreams.entries) {
              final peerId = entry.key;
              final participantInfo =
                  controller.participantMediaState[peerId] ?? {};
              final isParticipantVideoEnabled =
                  participantInfo['video'] ?? true;
              final isParticipantAudioEnabled =
                  participantInfo['audio'] ?? true;
              final peerName = participantInfo['name'] ?? '';
              final peerImage = participantInfo['image'] ?? '';

              tiles.add(_buildParticipantTile(
                isLocal: false,
                isVideo: isVideo && isParticipantVideoEnabled,
                name: peerName.isNotEmpty ? peerName : 'Participant',
                image: peerImage,
                isMuted: !isParticipantAudioEnabled,
                isCameraOff: !isParticipantVideoEnabled,
                renderer: controller.remoteRenderers[peerId],
              ));
            }

            return _buildGroupGrid(tiles);
          }),
        ),
      ),
    );
  }

  Widget _buildGroupGrid(List<Widget> tiles) {
    final count = tiles.length;

    if (count <= 1) {
      return Center(child: tiles.isNotEmpty ? tiles[0] : const SizedBox());
    }

    if (count == 2) {
      return Column(
        children: tiles
            .map((tile) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: tile,
                  ),
                ))
            .toList(),
      );
    }

    // 3+ participants: grid layout (2 columns)
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: false,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: count <= 4 ? 0.75 : 0.85,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count,
      itemBuilder: (context, index) => tiles[index],
    );
  }

  Widget _buildParticipantTile({
    required bool isLocal,
    required bool isVideo,
    required String name,
    required String image,
    required bool isMuted,
    required bool isCameraOff,
    RTCVideoRenderer? renderer,
    bool mirror = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF233138),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or avatar
          if (isVideo && renderer != null && !isCameraOff)
            RTCVideoView(
              renderer,
              mirror: mirror,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: _buildCircleAvatar(
                name: name,
                image: image,
                radius: 32,
              ),
            ),
          // Name label (bottom)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                if (isMuted)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.mic_off, color: Colors.white, size: 12),
                  ),
                if (isMuted) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isLocal ? 'You' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Camera off indicator (top right)
          if (isCameraOff && isVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.videocam_off,
                    color: Colors.white70, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== TOP BAR ====================

  Widget _buildTopBar(BuildContext context, CallController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final isGroup = controller.isGroupCall.value;
                        return Text(
                          isGroup
                              ? 'Group Call'
                              : controller.remoteUserName.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      Obx(() => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCallStatusText(controller, fontSize: 12),
                              const SizedBox(width: 8),
                              Text(
                                controller.callType.value == CallType.video
                                    ? 'Video Call'
                                    : 'Audio Call',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
                // Minimize (PiP) button
                GestureDetector(
                  onTap: () => controller.enterPipMode(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_in_picture_alt,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Add user button (WhatsApp style)
                Obx(() {
                  if (controller.callStatus.value == CallStatus.connected) {
                    return GestureDetector(
                      onTap: () => _showAddUserBottomSheet(context, controller),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add,
                            color: Colors.white, size: 20),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(width: 8),
                // Participant count for group calls
                Obx(() {
                  if (controller.isGroupCall.value) {
                    final count =
                        controller.remoteStreams.length + 1; // +1 for self
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
        ),
      ),
    );
  }

  Widget _buildCallStatusText(CallController controller,
      {double fontSize = 14}) {
    final status = controller.callStatus.value;
    if (status == CallStatus.connected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00A884),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            controller.formattedCallDuration,
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
    }

    String text;
    switch (status) {
      case CallStatus.accepting:
        text = 'Accepting...';
        break;
      case CallStatus.outgoing:
        text = 'Ringing...';
        break;
      case CallStatus.connecting:
        text = 'Connecting...';
        break;
      default:
        text = 'Connecting...';
    }
    return Text(
      text,
      style: TextStyle(
        color: Colors.white70,
        fontSize: fontSize,
        fontFamily: 'Poppins',
      ),
    );
  }

  // ==================== BOTTOM CONTROLS (WhatsApp Style) ====================

  Widget _buildBottomControls(CallController controller, bool isVideo) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 20),
            child: Obx(() {
              final currentIsVideo = controller.callType.value == CallType.video;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Camera, Mic, Speaker, Flip (media controls)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (currentIsVideo)
                        Obx(() => _buildControlButton(
                              icon: controller.isCameraOn.value
                                  ? Icons.videocam
                                  : Icons.videocam_off,
                              label: 'Camera',
                              isActive: !controller.isCameraOn.value,
                              onTap: () => controller.toggleCamera(),
                            )),
                      Obx(() => _buildControlButton(
                            icon: controller.isMicOn.value
                                ? Icons.mic
                                : Icons.mic_off,
                            label: 'Mute',
                            isActive: !controller.isMicOn.value,
                            onTap: () => controller.toggleMic(),
                          )),
                      Obx(() => _buildControlButton(
                            icon: controller.isSpeakerOn.value
                                ? Icons.volume_up
                                : Icons.hearing,
                            label: 'Speaker',
                            isActive: controller.isSpeakerOn.value,
                            onTap: () => controller.toggleSpeaker(),
                          )),
                      if (currentIsVideo)
                        _buildControlButton(
                          icon: Icons.flip_camera_ios,
                          label: 'Flip',
                          onTap: () => controller.switchCamera(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 2: Switch type, End call
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (controller.callStatus.value == CallStatus.connected)
                        Obx(() => _buildControlButton(
                              icon: currentIsVideo ? Icons.call : Icons.videocam,
                              label: currentIsVideo ? 'Audio' : 'Video',
                              isActive: controller.isSwitchTypePending.value,
                              onTap: controller.isSwitchTypePending.value
                                  ? null
                                  : () => controller.switchCallType(),
                            )),
                      _buildEndCallButton(controller),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton(CallController controller) {
    return GestureDetector(
      onTap: () => controller.endCall(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFEA4335),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'End',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildAvatarPlaceholder({
    required String name,
    required String image,
    required double radius,
    bool showCameraOff = false,
  }) {
    return Container(
      color: const Color(0xFF121B22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleAvatar(name: name, image: image, radius: radius),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            if (showCameraOff) ...[
              const SizedBox(height: 4),
              const Text(
                'Camera off',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAvatar({
    required String name,
    required String image,
    required double radius,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2A3942),
      backgroundImage:
          image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
      child: image.isEmpty
          ? Icon(Icons.person, size: radius, color: const Color(0xFF8696A0))
          : null,
    );
  }

  // ==================== SWITCH CALL TYPE DIALOG ====================

  void _showSwitchTypeDialog(
      BuildContext context, CallController controller, String requestedBy) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Color(0xFF00A884), size: 24),
            SizedBox(width: 10),
            Text(
              'Switch to Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        content: Text(
          '${controller.remoteUserName.value.isNotEmpty ? controller.remoteUserName.value : 'Participant'} wants to switch to a video call',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.respondToSwitchType(false);
            },
            child: const Text(
              'Decline',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.respondToSwitchType(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ==================== ADD USER TO CALL (WhatsApp Style) ====================

  void _showAddUserBottomSheet(
      BuildContext context, CallController controller) {
    // Gather contacts from personal chat list
    final chatViewController = Get.find<ChatViewController>();
    final List<_ContactItem> contacts = [];
    final currentUserId = userId;

    // Get contacts from personal chat list
    final personalChatList =
        chatViewController.getPersonalChatListModel?.value.chatList;
    if (personalChatList != null) {
      for (final chat in personalChatList) {
        if (chat == null) continue;
        final sender = chat.sender;
        if (sender == null || sender.id == currentUserId) continue;
        // Skip users already in the call
        if (controller.peerConnections.containsKey(sender.id)) continue;
        contacts.add(_ContactItem(
          id: sender.id ?? '',
          name: sender.name ?? sender.contactNo ?? 'Unknown',
          image: sender.profileImage ?? '',
        ));
      }
    }

    final selectedIds = <String>{}.obs;
    final searchQuery = ''.obs;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add participants',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  // Done button
                  Obx(() {
                    if (selectedIds.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () async {
                        if (selectedIds.isNotEmpty) {
                          Get.back();
                          await controller
                              .addUsersToCall(selectedIds.toList());
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A884),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Add (${selectedIds.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF233138),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Poppins'),
                  decoration: const InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(
                        color: Colors.white38, fontFamily: 'Poppins'),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => searchQuery.value = value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Selected chips
            Obx(() {
              if (selectedIds.isEmpty) return const SizedBox.shrink();
              final selectedContacts = contacts
                  .where((c) => selectedIds.contains(c.id))
                  .toList();
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedContacts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final contact = selectedContacts[index];
                    return GestureDetector(
                      onTap: () => selectedIds.remove(contact.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF2A3942),
                                backgroundImage: contact.image.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        contact.image)
                                    : null,
                                child: contact.image.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Color(0xFF8696A0),
                                        size: 24)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8696A0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
            // Contact list
            Expanded(
              child: Obx(() {
                final query = searchQuery.value.toLowerCase();
                final filtered = contacts.where((c) {
                  if (query.isEmpty) return true;
                  return c.name.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return Obx(() {
                      final isSelected = selectedIds.contains(contact.id);
                      return ListTile(
                        onTap: () {
                          if (isSelected) {
                            selectedIds.remove(contact.id);
                          } else {
                            selectedIds.add(contact.id);
                          }
                        },
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF2A3942),
                          backgroundImage: contact.image.isNotEmpty
                              ? CachedNetworkImageProvider(contact.image)
                              : null,
                          child: contact.image.isEmpty
                              ? const Icon(Icons.person,
                                  color: Color(0xFF8696A0), size: 22)
                              : null,
                        ),
                        title: Text(
                          contact.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF00A884)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00A884)
                                  : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ContactItem {
  final String id;
  final String name;
  final String image;

  _ContactItem({
    required this.id,
    required this.name,
    required this.image,
  });
}
