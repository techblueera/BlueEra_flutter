import 'dart:io';

import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/service/call_activity_service.dart';
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
      return 'Call ended - $_callTime';
    }
    return message.message ?? 'Call';
  }

  IconData get _callIcon {
    if (_isMissedCall || _isDeclined) {
      return Icons.call_missed;
    }
    if (_isVideoCall) {
      return Icons.videocam;
    }
    return Icons.call;
  }

  Color _iconColor(BuildContext context) {
    if (_isMissedCall || _isDeclined) {
      return Colors.red;
    }
    return Colors.green;
  }

  /// Open the active call screen (Android CallActivity or in-app CallRoomScreen)
  void _openCallScreen() {
    if (Platform.isAndroid && CallController.isCallActivityActive) {
      CallActivityService.bringCallActivityToFront();
      return;
    }
    if (Get.currentRoute != '/CallRoomScreen') {
      Get.toNamed('/CallRoomScreen');
    }
  }

  void _onCallBack() {
    final targetUserId = message.metadata?.otherUserId ?? otherUserId ?? '';
    final targetConversationId = conversationId ?? '';
    final targetUserName = otherUserName ?? '';
    final targetUserImage = otherUserImage ?? '';

    if (targetUserId.isEmpty && targetConversationId.isEmpty) return;

    final callType = _isVideoCall ? CallType.video : CallType.audio;

    if (Platform.isAndroid) {
      CallController.isCallActivityActive = true;
      CallActivityService.launchCallActivity(
        callId: '',
        roomId: '',
        conversationId: targetConversationId,
        callType: _isVideoCall ? 'video' : 'audio',
        callerName: targetUserName,
        callerImage: targetUserImage,
        remoteUserId: targetUserId,
        remoteUserName: targetUserName,
        remoteUserImage: targetUserImage,
        isCaller: true,
      ).then((launched) {
        if (!launched) {
          CallController.isCallActivityActive = false;
          _initiateCallInApp(callType, targetUserId, targetConversationId,
              targetUserName, targetUserImage);
        }
      });
      return;
    }

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
    final isMyMessage = !isReceive;

    final bgColor = isMyMessage
        ? chatThemeController.myMessageBgColor.value
        : chatThemeController.receiveMessageBgColor.value;

    final textColor = chatThemeController.chatTextColor.value;

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
          left: isReceive ? 10 : 60,
          right: isReceive ? 60 : 10,
          top: 2,
          bottom: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isReceive ? 0 : 12),
            bottomRight: Radius.circular(isReceive ? 12 : 0),
          ),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _iconColor(context).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _callIcon,
                      size: 18,
                      color: _iconColor(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isVideoCall ? 'Video Call' : 'Audio Call',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontFamily: "Poppins",
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _isMissedCall || _isDeclined
                                ? Colors.red
                                : textColor.withOpacity(0.7),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isMissedCall || _isCompleted || _isDeclined) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _onCallBack,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVideoCall ? Icons.videocam : Icons.call,
                          size: 18,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withOpacity(0.5),
                    fontFamily: "Poppins",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
