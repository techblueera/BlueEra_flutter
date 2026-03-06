import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/snackbar_helper.dart';

class ChatShortcutService {
  static const _channel = MethodChannel('com.bluehr.shortcut/channel');

  static Future<void> createChatShortcut({
    required String conversationId,
    required String name,
    required String userId,
    String? profileImage,
    String chatType = 'personal',
  }) async {
    try {
      await _channel.invokeMethod('createShortcut', {
        'conversationId': conversationId,
        'name': name,
        'profileImage': profileImage ?? '',
        'userId': userId,
        'chatType': chatType,
      });
      commonSnackBar(message: "Shortcut added to home screen");
    } on PlatformException catch (e) {
      debugPrint("Shortcut error: ${e.message}");
      commonSnackBar(message: "Could not create shortcut");
    }
  }
}
