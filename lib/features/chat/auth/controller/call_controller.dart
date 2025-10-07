import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../repo/call_repo.dart';
import '../socket/chat_socket.dart';
import 'chat_view_controller.dart';

enum CallType { audio, video }
enum CallStatus { idle, ringing, ongoing, ended, hold }

class CallController extends GetxController {
  late ChatSocketService callSocket;

  /// Observables
  var callType = CallType.audio.obs;
  var callStatus = CallStatus.idle.obs;
  var callerName = "".obs;
  var targetUserId = 0.obs;
  var isMicOn = true.obs;
  var isSpeakerOn = false.obs;


  Future<void> callToUser(Map<String, dynamic> params) async {
      ResponseModel responseModel =
      await CallRepo().callToUser(params);
      print(" lkdclskmclskdcmsdc ${responseModel.response?.data}");
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }

  }
  Future<void> initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");
    final chatViewController = Get.find<ChatViewController>();
    callSocket = chatViewController.chatSocket;
    callSocket.listenEvent("call_user", (data){

    });
    callSocket.listenEvent("call_decline", (data){

    });
    callSocket.listenEvent("call_decline", (data){

    });
  }
}

/// CallKit notification helper
void showFlutterCallNotification({
  required String callSessionId,
  required String userId,
  required String callerName,
  int callerId = 0,
  int receiverId = 0,
}) async {
  final params = CallKitParams(
    id: callSessionId,
    nameCaller: callerName,
    appName: 'Picturo',
    handle: "Call From $callerName",
    type: 0,
    duration: 30000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      subtitle: 'Missed call',
    ),
    extra: {
      'userId': userId,
      'callerId': callerId.toString(),
      'receiverId': receiverId.toString(),
    },
    android: const AndroidParams(
      isShowLogo: true,
      isShowFullLockedScreen: true,
      isImportant: true,
    ),
    ios: const IOSParams(
      supportsVideo: true,
      supportsDTMF: true,
      supportsHolding: true,
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}
