import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../auth/controller/call_controller.dart';

/// Draggable floating call overlay shown when the user navigates back
/// from any call screen (incoming, outgoing, or connected).
/// Similar to the ride navigation floating overlay but for calls.
class CallFloatingOverlay extends StatelessWidget {
  const CallFloatingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => CallController());

    return Obx(() {
      final status = controller.callStatus.value;
      final isActive = status == CallStatus.ringing ||
          status == CallStatus.outgoing ||
          status == CallStatus.accepting ||
          status == CallStatus.connecting ||
          status == CallStatus.connected ||
          controller.isIncomingCall.value == true;

      // Don't show overlay when on call screens themselves
      final route = Get.currentRoute;
      final isOnCallScreen = route == '/ActiveCallScreen' ||
          route == '/OutgoingCallScreen' ||
          route == '/IncomingCallScreen' ||
          route == '/CallRoomScreen' ||
          route == '/IncomingRiderOrderScreen';

      // OngoingCallOverlay (top bar) now handles all states — hide the
      // draggable bubble so they don't overlap.
      if (!isActive || isOnCallScreen) {
        return const SizedBox.shrink();
      }

      return const SizedBox.shrink();
    });
  }
}

class _DraggableCallBubble extends StatefulWidget {
  final CallController controller;
  const _DraggableCallBubble({required this.controller});

  @override
  State<_DraggableCallBubble> createState() => _DraggableCallBubbleState();
}

class _DraggableCallBubbleState extends State<_DraggableCallBubble>
    with SingleTickerProviderStateMixin {
  double _xPos = 16;
  double _yPos = 120;

  static const double _width = 180;
  static const double _height = 80;

  late AnimationController _pulseController;

  CallController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _statusText {
    final status = ctrl.callStatus.value;
    if (status == CallStatus.connected) {
      return ctrl.formattedCallDuration;
    } else if (status == CallStatus.ringing ||
        ctrl.isIncomingCall.value == true) {
      return 'Incoming call...';
    } else if (status == CallStatus.outgoing) {
      return 'Ringing...';
    } else if (status == CallStatus.connecting ||
        status == CallStatus.accepting) {
      return 'Connecting...';
    }
    return '';
  }

  String get _callerName {
    if (ctrl.callerName.value.isNotEmpty) return ctrl.callerName.value;
    if (ctrl.remoteUserName.value.isNotEmpty) return ctrl.remoteUserName.value;
    return 'Call';
  }

  String get _callerImage {
    if (ctrl.callerImage.value.isNotEmpty) return ctrl.callerImage.value;
    return ctrl.remoteUserImage.value;
  }

  bool get _isVideo => ctrl.callType.value == CallType.video;

  void _onTap() {
    if (ctrl.isIncomingCall.value == true) {
      Get.toNamed('/IncomingCallScreen');
    } else {
      if (Get.currentRoute != '/CallRoomScreen') {
        Get.toNamed('/CallRoomScreen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos =
                (_xPos + details.delta.dx).clamp(0, screenWidth - _width);
            _yPos =
                (_yPos + details.delta.dy).clamp(0, screenHeight - _height);
          });
        },
        onTap: _onTap,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          shadowColor: Colors.black45,
          child: Obx(() {
            final isRinging = ctrl.callStatus.value == CallStatus.ringing ||
                ctrl.isIncomingCall.value == true ||
                ctrl.callStatus.value == CallStatus.outgoing;

            return Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRinging
                      ? const [Color(0xFF1A2E35), Color(0xFF0F1F27)]
                      : const [Color(0xFF00A884), Color(0xFF008F6F)],
                ),
                border: Border.all(
                  color: isRinging
                      ? const Color(0xFF00C853)
                      : const Color(0xFF00A884),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Pulse indicator for ringing
                    if (isRinging)
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF00C853).withValues(
                                    alpha:
                                        1.0 - _pulseController.value * 0.6,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Main content
                    Padding(
                      padding: EdgeInsets.only(
                        left: isRinging ? 30 : 10,
                        right: 40,
                        top: 10,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          _buildAvatar(),
                          const SizedBox(width: 8),
                          // Name + status
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  _callerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'OpenSans',
                                    decoration: TextDecoration.none,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      _isVideo
                                          ? Icons.videocam_rounded
                                          : Icons.phone_in_talk_rounded,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _statusText,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontFamily: 'OpenSans',
                                          fontWeight: FontWeight.normal,
                                          decoration:
                                              TextDecoration.none,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // End call button
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 8,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (ctrl.isIncomingCall.value == true) {
                              ctrl.declineCall();
                            } else {
                              ctrl.endCall();
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEA4335),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final image = _callerImage;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipOval(
        child: image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) => _defaultAvatar(),
                errorWidget: (_, __, ___) => _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF2A3942),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white54,
        size: 22,
      ),
    );
  }
}
