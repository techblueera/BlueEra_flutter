import 'dart:io';
// ignore: unused_import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel service to launch CallActivity in a separate Android task.
/// Creates a WhatsApp-style separate Recent Apps entry for calls.
class CallActivityService {

  /// Channel used to launch the Android CallActivity
  static const MethodChannel _launcherChannel =
  MethodChannel('com.bluehr.call/launcher');

  /// Bridge channel used by CallActivity to communicate with Dart
  static const MethodChannel _bridgeChannel =
  MethodChannel('com.bluehr.call/bridge');

  /// Launch CallActivity on Android
  static Future<bool> launchCallActivity({
    required String callId,
    required String roomId,
    required String conversationId,
    required String callType,
    required String callerName,
    required String callerImage,
    required String remoteUserId,
    String remoteUserName = '',
    String remoteUserImage = '',
    required bool isCaller,
    bool isGroupCall = false,
    String iceServers = '{}',
  }) async {

    if (!Platform.isAndroid) {

      return false;
    }

    try {

      final params = {
        'callId': callId,
        'roomId': roomId,
        'conversationId': conversationId,
        'callType': callType,
        'callerName': callerName,
        'callerImage': callerImage,
        'remoteUserId': remoteUserId,
        'remoteUserName': remoteUserName,
        'remoteUserImage': remoteUserImage,
        'isCaller': isCaller,
        'isGroupCall': isGroupCall,
        'iceServers': iceServers,
      };



      final bool? launched =
      await _launcherChannel.invokeMethod('launchCallActivity', params);


      return launched??true;

    } catch (e) {


      return false;
    }
  }

  /// Get call parameters from Android Intent extras
  static Future<Map<String, dynamic>> getCallParams() async {
    try {

      final result = await _bridgeChannel.invokeMethod('getCallParams');

      if (result == null) {
        return {};
      }

      final params = Map<String, dynamic>.from(result as Map);



      return params;

    } catch (e) {



      return {};
    }
  }

  /// Bring existing CallActivity to front without creating a new instance
  static Future<bool> bringCallActivityToFront() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _launcherChannel.invokeMethod('bringCallActivityToFront');
      return result == true;
    } catch (e) {

      return false;
    }
  }

  /// Close CallActivity and remove from Recents
  static Future<void> closeCallActivity() async {
    if (!Platform.isAndroid) {

      return;
    }

    try {

      await _bridgeChannel.invokeMethod('closeCallActivity');
    } catch (e) {

    }
  }

  /// Close CallActivity when call ends
  static Future<void> finishCallActivity() async {
    try {

      await _bridgeChannel.invokeMethod('finishCallActivity');

    } catch (e) {


    }
  }
}