import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
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
      return Icons.call_missed;
    }
    if (_isVideoCall) {
      return Icons.videocam;
    }
    return Icons.call;
  }

  Color get _statusColor {
    if (_isMissedCall || _isDeclined) {
      return Colors.red;
    }
    return AppColors.primaryColor;
  }


  /// Open the active call screen. On Android the call runs inside a separate
  /// task (CallActivity, often in PiP) — bring that task back to front, or
  /// relaunch it using the current CallController state if the task was
  /// dismissed. On iOS / when there is no native task, fall back to the
  /// in-app CallRoomScreen.
  Future<void> _openCallScreen() async {
    if (Platform.isAndroid) {
      final brought = await CallActivityService.bringCallActivityToFront();
      if (brought) return;

      if (Get.isRegistered<CallController>()) {
        final cc = Get.find<CallController>();
        final ctStr =
            cc.callType.value == CallType.video ? 'video' : 'audio';
        final relaunched = await CallActivityService.launchCallActivity(
          callId: cc.callId.value,
          roomId: cc.roomId.value,
          conversationId: cc.conversationId.value.isNotEmpty
              ? cc.conversationId.value
              : (conversationId ?? ''),
          callType: ctStr,
          callerName: cc.callerName.value,
          callerImage: cc.callerImage.value,
          remoteUserId: cc.remoteUserName.value.isNotEmpty
              ? (message.metadata?.otherUserId ?? otherUserId ?? '')
              : (message.metadata?.otherUserId ?? otherUserId ?? ''),
          remoteUserName:
              cc.remoteUserName.value.isNotEmpty
                  ? cc.remoteUserName.value
                  : (otherUserName ?? ''),
          remoteUserImage: cc.remoteUserImage.value.isNotEmpty
              ? cc.remoteUserImage.value
              : (otherUserImage ?? ''),
          isCaller: cc.isCaller.value,
          isGroupCall: cc.isGroupCall.value,
        );
        if (relaunched) {
          CallController.isCallActivityActive = true;
          return;
        }
      }
    }

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
    final textColor = chatThemeController.chatTextColor.value;
    final accent = _statusColor;
    final isNegative = _isMissedCall || _isDeclined;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = MediaQuery.of(context).size.width;
            final maxCardW = (screenW - 70).clamp(180.0, 320.0);
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardW),
              child: Container(
                margin: EdgeInsets.only(
                  left: isReceive ? 10 : 60,
                  right: isReceive ? 60 : 10,
                  top: 4,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.12),
                      accent.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: accent.withValues(alpha: 0.30), width: 1),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _isVideoCall
                                          ? 'Video Call'
                                          : 'Audio Call',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                  ),
                                  if (_isOngoingCall) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _callIcon,
                                    size: 14,
                                    color:
                                        isNegative ? Colors.red : accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _statusText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isNegative ? Colors.red : accent,
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textColor.withValues(alpha: 0.5),
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),
                        child: GestureDetector(
                          onTap:
                              _isOngoingCall ? _openCallScreen : _onCallBack,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isVideoCall ? Icons.videocam : Icons.call,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
