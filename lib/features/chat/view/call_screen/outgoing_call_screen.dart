import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';
import '../../auth/controller/call_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/service/call_pip_service.dart';

class CallRoomScreen extends StatefulWidget {
  const CallRoomScreen({super.key});

  @override
  State<CallRoomScreen> createState() => _CallRoomScreenState();
}

class _CallRoomScreenState extends State<CallRoomScreen>
    with TickerProviderStateMixin  {
  late Worker _callStatusWorker;
  late Worker _switchTypeWorker;
  final AudioPlayer _ringbackPlayer = AudioPlayer();

  // Ripple animation controllers (staggered)
  late AnimationController _ripple1Controller;
  late AnimationController _ripple2Controller;
  late AnimationController _ripple3Controller;

  late Animation<double> _ripple1Scale;
  late Animation<double> _ripple1Opacity;
  late Animation<double> _ripple2Scale;
  late Animation<double> _ripple2Opacity;
  late Animation<double> _ripple3Scale;
  late Animation<double> _ripple3Opacity;

  // Draggable local video position
  double _localVideoX = -1;
  double _localVideoY = -1;
  bool _positionInitialized = false;

  // PiP state
  bool _isInPipMode = false;

  // Controls visibility (tap to toggle in video call)
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    // --- Ripple animations (staggered by 600ms) ---
    _ripple1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _ripple2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ripple3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ripple2Controller.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _ripple3Controller.repeat();
    });

    _ripple1Scale = Tween<double>(begin: 0.9, end: 1.5).animate(
      CurvedAnimation(parent: _ripple1Controller, curve: Curves.easeOut),
    );
    _ripple1Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ripple1Controller, curve: Curves.easeOut),
    );
    _ripple2Scale = Tween<double>(begin: 0.9, end: 1.5).animate(
      CurvedAnimation(parent: _ripple2Controller, curve: Curves.easeOut),
    );
    _ripple2Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ripple2Controller, curve: Curves.easeOut),
    );
    _ripple3Scale = Tween<double>(begin: 0.9, end: 1.5).animate(
      CurvedAnimation(parent: _ripple3Controller, curve: Curves.easeOut),
    );
    _ripple3Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ripple3Controller, curve: Curves.easeOut),
    );

    final controller = Get.find<CallController>();

    // Play ringback for outgoing calls
    if (controller.callStatus.value == CallStatus.outgoing ||
        controller.callStatus.value == CallStatus.ringing) {
      _playRingback();
    }

    // Watch call status changes
    _callStatusWorker = ever(controller.callStatus, (status) {
      if (!mounted) return;
      if (status == CallStatus.idle ||
          status == CallStatus.connecting ||
          status == CallStatus.connected ||
          status == CallStatus.ended) {
        _ringbackPlayer.stop();
      }
      if (status == CallStatus.connected) {
        _ripple1Controller.stop();
        _ripple2Controller.stop();
        _ripple3Controller.stop();
      }
    });

    // Watch for incoming switch type requests
    _switchTypeWorker = ever(controller.switchTypeRequestedBy, (requestedBy) {
      if (requestedBy.isNotEmpty && mounted) {
        _showSwitchTypeDialog(context, controller, requestedBy);
      }
    });

    // Setup PiP listeners
    if (Platform.isAndroid) {
      CallPipService.init();
      CallPipService.onPipModeChanged = (isInPip) {
        if (mounted) setState(() => _isInPipMode = isInPip);
      };
      CallPipService.onPipAction = (action) {
        if (!mounted) return;
        switch (action) {
          case 'mute_toggle':
            controller.toggleMic();
            break;
          case 'hangup':
            controller.endCall();
            break;
        }
      };
    }
  }

  Future<void> _playRingback() async {
    try {
      await _ringbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringbackPlayer.play(AssetSource('sound/hangouts_call.mp3'));
      await _ringbackPlayer.setVolume(0.3);
    } catch (_) {}
  }

  @override
  void dispose() {
    _callStatusWorker.dispose();
    _switchTypeWorker.dispose();
    _ripple1Controller.dispose();
    _ripple2Controller.dispose();
    _ripple3Controller.dispose();
    _ringbackPlayer.stop();
    _ringbackPlayer.dispose();
    CallPipService.dispose();
    super.dispose();
  }

  Future<bool> _enterPipMode() async {
    if (!Platform.isAndroid) return false;
    return await CallPipService.enterPipMode();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (Platform.isAndroid) {
          final entered = await _enterPipMode();
          if (entered) return;
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111B21),
        body: Obx(() {
          final status = controller.callStatus.value;
          final isConnected = status == CallStatus.connected;
          final isVideo = controller.callType.value == CallType.video;
          final isGroup = controller.isGroupCall.value;

          // PiP mode
          if (_isInPipMode) {
            return _buildPipModeView(controller, isVideo);
          }

          // Ringing/Outgoing state
          if (!isConnected &&
              status != CallStatus.connecting &&
              status != CallStatus.accepting) {
            return _buildRingingView(controller);
          }

          // Active call — video mode
          if (isVideo && !isGroup) {
            return GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoCallBody(controller),
                  if (_showControls) _buildTopBar(controller),
                  if (_showControls) _buildActiveBottomControls(controller),
                ],
              ),
            );
          }

          // Active call — group
          if (isGroup) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildGroupCallBody(controller, isVideo),
                _buildTopBar(controller),
                _buildActiveBottomControls(controller),
              ],
            );
          }

          // Active call — audio
          return _buildAudioCallView(controller);
        }),
      ),
    );
  }

  // ==================== RINGING / OUTGOING VIEW ====================

  Widget _buildRingingView(CallController controller) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(painter: _BackgroundPatternPainter()),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.close_fullscreen_rounded,
                      onTap: () async {
                        if (Platform.isAndroid) {
                          final entered = await _enterPipMode();
                          if (entered) return;
                        }
                        Get.back();
                      },
                    ),
                    Column(
                      children: [
                        Obx(() => Text(
                              controller.remoteUserName.value.isNotEmpty
                                  ? controller.remoteUserName.value
                                  : 'Calling...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.2,
                              ),
                            )),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.55)),
                            const SizedBox(width: 4),
                            Text(
                              'End-to-end encrypted',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _CircleIconButton(
                      icon: Icons.person_add_alt_1_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Avatar + ripples
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple 1
                            AnimatedBuilder(
                              animation: _ripple1Controller,
                              builder: (context, _) => Transform.scale(
                                scale: _ripple1Scale.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF25D366)
                                          .withValues(
                                              alpha:
                                                  _ripple1Opacity.value * 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Ripple 2
                            AnimatedBuilder(
                              animation: _ripple2Controller,
                              builder: (context, _) => Transform.scale(
                                scale: _ripple2Scale.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF25D366)
                                          .withValues(
                                              alpha:
                                                  _ripple2Opacity.value * 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Ripple 3
                            AnimatedBuilder(
                              animation: _ripple3Controller,
                              builder: (context, _) => Transform.scale(
                                scale: _ripple3Scale.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF25D366)
                                          .withValues(
                                              alpha:
                                                  _ripple3Opacity.value * 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Avatar circle
                            Obx(() => _buildAvatarCircle(
                                  image: controller.remoteUserImage.value,
                                  size: 190,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Ringing status
                      Obx(() {
                        final status = controller.callStatus.value;
                        String text = 'Ringing...';
                        if (status == CallStatus.connecting) {
                          text = 'Connecting...';
                        } else if (status == CallStatus.accepting) {
                          text = 'Accepting...';
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Obx(() {
                    final isVideoCall =
                        controller.callType.value == CallType.video;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ControlButton(
                          icon: controller.isSpeakerOn.value
                              ? Icons.volume_up
                              : Icons.volume_down_outlined,
                          label: 'Speaker',
                          isActive: controller.isSpeakerOn.value,
                          onTap: () => controller.toggleSpeaker(),
                        ),
                        if (isVideoCall)
                          _ControlButton(
                            icon: controller.isCameraOn.value
                                ? Icons.videocam
                                : Icons.videocam_off_outlined,
                            label: 'Video',
                            isActive: !controller.isCameraOn.value,
                            onTap: () => controller.toggleCamera(),
                          ),
                        _ControlButton(
                          icon: controller.isMicOn.value
                              ? Icons.mic
                              : Icons.mic_off,
                          label: controller.isMicOn.value ? 'Mute' : 'Unmute',
                          isActive: !controller.isMicOn.value,
                          onTap: () => controller.toggleMic(),
                        ),
                        // End call button
                        GestureDetector(
                          onTap: () {
                            _ringbackPlayer.stop();
                            controller.cancelCall();
                          },
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0384A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF0384A)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ACTIVE AUDIO CALL VIEW ====================

  Widget _buildAudioCallView(CallController controller) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(painter: _BackgroundPatternPainter()),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.close_fullscreen_rounded,
                      onTap: () async {
                        if (Platform.isAndroid) {
                          final entered = await _enterPipMode();
                          if (entered) return;
                        }
                        Get.back();
                      },
                    ),
                    Column(
                      children: [
                        Obx(() => Text(
                              controller.remoteUserName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.2,
                              ),
                            )),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.55)),
                            const SizedBox(width: 4),
                            Text(
                              'End-to-end encrypted',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Obx(() {
                      if (controller.callStatus.value == CallStatus.connected) {
                        return _CircleIconButton(
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () =>
                              _showAddUserBottomSheet(context, controller),
                        );
                      }
                      return const SizedBox(width: 44);
                    }),
                  ],
                ),
              ),

              // Avatar + ripples (no ripple in connected state)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => _buildAvatarCircle(
                            image: controller.remoteUserImage.value,
                            size: 190,
                          )),
                      const SizedBox(height: 20),
                      // Call timer / status
                      Obx(() {
                        if (controller.callStatus.value ==
                            CallStatus.connected) {
                          return Text(
                            controller.formattedCallDuration,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              letterSpacing: 0.8,
                            ),
                          );
                        }
                        return Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        );
                      }),
                      // Remote mute indicator
                      Obx(() {
                        if (!controller.remoteAudioEnabled.value) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mic_off,
                                    color: Colors.redAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Muted',
                                  style: TextStyle(
                                    color: Colors.redAccent.withValues(alpha: 0.8),
                                    fontSize: 12,
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

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Obx(() {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Switch to video
                        if (controller.callStatus.value ==
                            CallStatus.connected)
                          _ControlButton(
                            icon: Icons.videocam_outlined,
                            label: 'Video',
                            isActive: controller.isSwitchTypePending.value,
                            onTap: controller.isSwitchTypePending.value
                                ? () {}
                                : () => controller.switchCallType(),
                          ),
                        _ControlButton(
                          icon: controller.isSpeakerOn.value
                              ? Icons.volume_up
                              : Icons.volume_down_outlined,
                          label: 'Speaker',
                          isActive: controller.isSpeakerOn.value,
                          onTap: () => controller.toggleSpeaker(),
                        ),
                        _ControlButton(
                          icon: controller.isMicOn.value
                              ? Icons.mic
                              : Icons.mic_off,
                          label: controller.isMicOn.value ? 'Mute' : 'Unmute',
                          isActive: !controller.isMicOn.value,
                          onTap: () => controller.toggleMic(),
                        ),
                        // End call
                        GestureDetector(
                          onTap: () {
                            _ringbackPlayer.stop();
                            controller.endCall();
                          },
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0384A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF0384A)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== AVATAR CIRCLE ====================

  Widget _buildAvatarCircle({required String image, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
                placeholder: (context, url) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  // ==================== PiP MODE VIEW ====================

  Widget _buildPipModeView(CallController controller, bool isVideo) {
    if (isVideo) {
      final remoteRenderer = controller.remoteRenderers.values.firstOrNull;
      if (remoteRenderer != null && controller.remoteVideoEnabled.value) {
        return RTCVideoView(
          remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      }
    }
    return Container(
      color: const Color(0xFF111B21),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallCircleAvatar(
              name: controller.remoteUserName.value,
              image: controller.remoteUserImage.value,
              radius: 30,
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.formattedCallDuration,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ==================== VIDEO CALL BODY ====================

  Widget _buildVideoCallBody(CallController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double videoW = 110;
        const double videoH = 150;
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
                showCameraOff: !controller.remoteVideoEnabled.value,
              );
            }),
            // Local video (draggable)
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

  // ==================== GROUP CALL BODY ====================

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
            final List<Widget> tiles = [];

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

            for (final entry in controller.remoteStreams.entries) {
              final peerId = entry.key;
              final info = controller.participantMediaState[peerId] ?? {};
              tiles.add(_buildParticipantTile(
                isLocal: false,
                isVideo: isVideo && (info['video'] ?? true),
                name: (info['name'] ?? '').toString().isNotEmpty
                    ? info['name']
                    : 'Participant',
                image: info['image'] ?? '',
                isMuted: !(info['audio'] ?? true),
                isCameraOff: !(info['video'] ?? true),
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
            .map((t) => Expanded(
                child: Padding(padding: const EdgeInsets.all(4), child: t)))
            .toList(),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: count <= 4 ? 0.75 : 0.85,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count,
      itemBuilder: (context, i) => tiles[i],
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
          if (isVideo && renderer != null && !isCameraOff)
            RTCVideoView(renderer,
                mirror: mirror,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
          else
            Center(
                child: _buildSmallCircleAvatar(
                    name: name, image: image, radius: 32)),
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
                    child: const Icon(Icons.mic_off,
                        color: Colors.white, size: 12),
                  ),
                if (isMuted) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isLocal ? 'You' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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

  // ==================== TOP BAR (video/group active call) ====================

  Widget _buildTopBar(CallController controller) {
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.close_fullscreen_rounded,
                  onTap: () async {
                    if (Platform.isAndroid) {
                      final entered = await _enterPipMode();
                      if (entered) return;
                    }
                    Get.back();
                  },
                ),
                Column(
                  children: [
                    Obx(() {
                      final isGroup = controller.isGroupCall.value;
                      return Text(
                        isGroup
                            ? 'Group Call'
                            : controller.remoteUserName.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: 0.2,
                        ),
                      );
                    }),
                    const SizedBox(height: 3),
                    Obx(() {
                      if (controller.callStatus.value ==
                          CallStatus.connected) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              controller.formattedCallDuration,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.callType.value == CallType.video
                                  ? 'Video'
                                  : 'Audio',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      );
                    }),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      if (controller.callStatus.value ==
                          CallStatus.connected) {
                        return _CircleIconButton(
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () =>
                              _showAddUserBottomSheet(context, controller),
                        );
                      }
                      return const SizedBox(width: 44);
                    }),
                    // Group participant count
                    Obx(() {
                      if (controller.isGroupCall.value) {
                        final count = controller.remoteStreams.length + 1;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
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
                                Text('$count',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ACTIVE BOTTOM CONTROLS (video/group) ====================

  Widget _buildActiveBottomControls(CallController controller) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Obx(() {
              final isVideo = controller.callType.value == CallType.video;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (isVideo)
                    _ControlButton(
                      icon: controller.isCameraOn.value
                          ? Icons.videocam
                          : Icons.videocam_off,
                      label: 'Camera',
                      isActive: !controller.isCameraOn.value,
                      onTap: () => controller.toggleCamera(),
                    ),
                  _ControlButton(
                    icon: controller.isSpeakerOn.value
                        ? Icons.volume_up
                        : Icons.volume_down_outlined,
                    label: 'Speaker',
                    isActive: controller.isSpeakerOn.value,
                    onTap: () => controller.toggleSpeaker(),
                  ),
                  _ControlButton(
                    icon: controller.isMicOn.value ? Icons.mic : Icons.mic_off,
                    label: controller.isMicOn.value ? 'Mute' : 'Unmute',
                    isActive: !controller.isMicOn.value,
                    onTap: () => controller.toggleMic(),
                  ),
                  if (isVideo)
                    _ControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Flip',
                      onTap: () => controller.switchCamera(),
                    ),
                  // End call
                  GestureDetector(
                    onTap: () {
                      _ringbackPlayer.stop();
                      controller.endCall();
                    },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0384A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF0384A)
                                .withValues(alpha: 0.45),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildAvatarPlaceholder({
    required String name,
    required String image,
    bool showCameraOff = false,
  }) {
    return Container(
      color: const Color(0xFF111B21),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatarCircle(image: image, size: 150),
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
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCircleAvatar({
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
            Icon(Icons.videocam, color: Color(0xFF25D366), size: 24),
            SizedBox(width: 10),
            Text('Switch to Video',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '${controller.remoteUserName.value.isNotEmpty ? controller.remoteUserName.value : 'Participant'} wants to switch to a video call',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.respondToSwitchType(false);
            },
            child: const Text('Decline',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.respondToSwitchType(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Accept',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ==================== ADD USER TO CALL ====================

  void _showAddUserBottomSheet(
      BuildContext context, CallController controller) {
    final chatViewController = Get.find<ChatViewController>();
    final List<_ContactItem> contacts = [];
    final currentUserId = userId;

    final personalChatList =
        chatViewController.getPersonalChatListModel?.value.chatList;
    if (personalChatList != null) {
      for (final chat in personalChatList) {
        if (chat == null) continue;
        final sender = chat.sender;
        if (sender == null || sender.id == currentUserId) continue;
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Add participants',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ),
                  Obx(() {
                    if (selectedIds.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () async {
                        Get.back();
                        await controller.addUsersToCall(selectedIds.toList());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Add (${selectedIds.length})',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => searchQuery.value = v,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Selected chips
            Obx(() {
              if (selectedIds.isEmpty) return const SizedBox.shrink();
              final selected =
                  contacts.where((c) => selectedIds.contains(c.id)).toList();
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: selected.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = selected[i];
                    return GestureDetector(
                      onTap: () => selectedIds.remove(c.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF2A3942),
                                backgroundImage: c.image.isNotEmpty
                                    ? CachedNetworkImageProvider(c.image)
                                    : null,
                                child: c.image.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Color(0xFF8696A0), size: 24)
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
                            child: Text(c.name,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center),
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
                final q = searchQuery.value.toLowerCase();
                final filtered = contacts.where((c) {
                  if (q.isEmpty) return true;
                  return c.name.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No contacts found',
                        style: TextStyle(color: Colors.white38, fontSize: 14)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return Obx(() {
                      final sel = selectedIds.contains(c.id);
                      return ListTile(
                        onTap: () => sel
                            ? selectedIds.remove(c.id)
                            : selectedIds.add(c.id),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF2A3942),
                          backgroundImage: c.image.isNotEmpty
                              ? CachedNetworkImageProvider(c.image)
                              : null,
                          child: c.image.isEmpty
                              ? const Icon(Icons.person,
                                  color: Color(0xFF8696A0), size: 22)
                              : null,
                        ),
                        title: Text(c.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15)),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel
                                ? const Color(0xFF25D366)
                                : Colors.transparent,
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF25D366)
                                  : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: sel
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

// ── Reusable Widgets ──────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Background Pattern Painter ───────────────────────────────

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawRect(
          Rect.fromLTWH(x + 10, y + 10, 10, 10),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x + 30, y + 30, 6, 6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
