import 'dart:io';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    final isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
      return await FlutterOverlayWindow.isPermissionGranted();
    }
    return true;
  }

  static Future<void> showCallOverlay({
    required String callerName,
    required bool isVideo,
    String callTime = '00:00',
  }) async {
    if (!Platform.isAndroid) return;
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'Ongoing Call',
      overlayContent: callerName,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: isVideo ? 250 : 80,
      width: isVideo ? 180 : 280,
      startPosition: const OverlayPosition(0, -200),
    );

    await FlutterOverlayWindow.shareData({
      'callerName': callerName,
      'isVideo': isVideo,
      'callTime': callTime,
      'action': 'start',
    });
  }

  static Future<void> updateTimer(String timeString) async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.shareData({
          'action': 'updateTimer',
          'time': timeString,
        });
      }
    } catch (_) {}
  }

  static Future<void> closeOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }

  static Future<bool> isActive() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (_) {
      return false;
    }
  }
}
