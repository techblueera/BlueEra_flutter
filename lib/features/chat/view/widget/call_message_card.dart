
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/chat_theme_controller.dart';

class CallMessageCard extends StatelessWidget {
  final Messages message;
  final bool isReceive;
  final String time;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserImage;

  const CallMessageCard({
    super.key,
    required this.message,
    required this.isReceive,
    required this.time,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserImage,
  });

  bool get _isVideoCall => message.messageType == 'video_call';
  bool get _isMissedCall => message.metadata?.missedCall == true;
  bool get _isCompleted => message.metadata?.callStatus == 'completed';
  bool get _isDeclined => message.metadata?.callDecline == true;
  String get _callTime => message.metadata?.callTime ?? '';

  /// True when this message's call is the currently active call.
  bool get _isOngoingCall {
    if (!Get.isRegistered<CallController>()) return false;
    final cc = Get.find<CallController>();
    final status = cc.callStatus.value;
    if (status == CallStatus.idle || status == CallStatus.ended) return false;

    final msgRoomId = message.metadata?.roomId ?? '';
    final msgCallId = message.metadata?.callId ?? '';
    if (msgRoomId.isNotEmpty && msgRoomId == cc.roomId.value) return true;
    if (msgCallId.isNotEmpty && msgCallId == cc.callId.value) return true;

    // Fallback: ringing status + same conversation
    if (_isRinging && cc.conversationId.value == (conversationId ?? '')) {
      return true;
    }
    return false;
  }

  bool get _isRinging => message.metadata?.callStatus == 'ringing';

  String get _statusText {
    if (_isOngoingCall) {
      return 'Ongoing call';
    }
    if (_isRinging) {
      return 'Calling...';
    }
    if (_isMissedCall) {
      return 'Missed call';
    }
    if (_isDeclined) {
      return 'Call declined';
    }
    if (_isCompleted && _callTime.isNotEmpty) {
      return 'Call ended • $_callTime';
    }
    if (_isCompleted) {
      return 'Call ended';
    }
    return message.message ?? 'Call';
  }

  IconData get _callIcon {
    if (_isMissedCall || _isDeclined) {
      return isReceive ? Icons.call_missed : Icons.call_missed_outgoing;
    }
    if (isReceive) {
      return Icons.call_received;
    }
    return Icons.call_made;
  }

  Color get _arrowColor {
    if (_isMissedCall || _isDeclined) return const Color(0xFFFF3B30);
    return const Color(0xFF34C759);
  }



  /// Open the active call screen. The call runs in-app in the same activity,
  /// so just navigate to the in-app CallRoomScreen (no separate CallActivity).
  Future<void> _openCallScreen() async {
    if (Get.currentRoute != '/CallRoomScreen') {
      Get.toNamed('/CallRoomScreen');
    }
  }

  void _onCallBack() {
    // Always call the conversation partner (widget.otherUserId), not
    // metadata.otherUserId — the latter is stored from the sender's
    // perspective and would point back at the current user when tapping
    // an outgoing call message.
    final targetUserId =
        (otherUserId?.isNotEmpty ?? false) ? otherUserId! : (message.metadata?.otherUserId ?? '');
    final targetConversationId = conversationId ?? '';
    final targetUserName = otherUserName ?? '';
    final targetUserImage = otherUserImage ?? '';

    if (targetUserId.isEmpty && targetConversationId.isEmpty) return;

    final callType = _isVideoCall ? CallType.video : CallType.audio;

    // Always place the call in-app (same activity) — no separate CallActivity.
    _initiateCallInApp(callType, targetUserId, targetConversationId,
        targetUserName, targetUserImage);
  }

  void _initiateCallInApp(CallType callType, String otherUserId,
      String conversationId, String userName, String userImage) async {
    if (!Get.isRegistered<CallController>()) {
      Get.put(CallController());
    }
    final callController = Get.find<CallController>();
    final success = await callController.initiateCall(
      type: callType,
      otherUserId: otherUserId,
      existingConversationId: conversationId,
      userName: userName,
      userImage: userImage,
    );
    if (success) {
      Get.toNamed('/CallRoomScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatThemeController = Get.find<ChatThemeController>();
    final isDark = chatThemeController.isDarkMode.value;
    final isNegative = _isMissedCall || _isDeclined;

    final bubbleColor = isReceive
        ? (isDark ? const Color(0xFF1F2C34) : Colors.white)
        : chatThemeController.myMessageBgColor.value;
    final primaryText = isReceive
        ? (isDark ? Colors.white : const Color(0xFF111B21))
        : Colors.white;
    final secondaryText = isReceive
        ? (isDark ? const Color(0xFF8696A0) : const Color(0xFF667781))
        : Colors.white.withValues(alpha: 0.75);
    final callBackIconColor = isReceive
        ? const Color(0xFF00A884)
        : Colors.white;

    return GestureDetector(
      onTap: () {
        if (_isOngoingCall) {
          _openCallScreen();
        } else if (_isMissedCall || _isCompleted || _isDeclined) {
          _onCallBack();
        }
      },
      child: Align(
        alignment: isReceive ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(
            left: isReceive ? 8 : 80,
            right: isReceive ? 80 : 8,
            top: 1,
            bottom: 1,
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isReceive ? 0 : 12),
              bottomRight: Radius.circular(isReceive ? 12 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Direction arrow icon
              Icon(
                _callIcon,
                size: 16,
                color: isNegative ? const Color(0xFFFF3B30) : _arrowColor,
              ),
              const SizedBox(width: 8),
              // Call info column
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Call type + ongoing indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                          size: 14,
                          color: primaryText,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _isVideoCall ? 'Video call' : 'Voice call',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: primaryText,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (_isOngoingCall) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Status + time row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: isNegative
                                ? const Color(0xFFFF3B30)
                                : secondaryText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Call-back button
              GestureDetector(
                onTap: _isOngoingCall ? _openCallScreen : _onCallBack,
                child: Icon(
                  _isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                  size: 22,
                  color: callBackIconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
