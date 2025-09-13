import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/auth/views/screens/visiting_card_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VisitingCardHelper {

  /// Builds the card off-screen, captures it, then shares the PNG.
  static Future<void> buildAndShareVisitingCard(BuildContext context) async {
    GlobalKey cardKey = GlobalKey();

    // 1. Create an overlay that is **not** visible
    final overlay = OverlayEntry(
      builder: (_) => Transform.translate(
        offset: const Offset(0, -9999), // move completely off-screen
        child: VisitingCard(cardKey: cardKey),
      ),
    );

    Overlay.of(context).insert(overlay);

    // Wait until the frame is actually painted
    await WidgetsBinding.instance.endOfFrame;

    // One extra pump to be safe on slow devices
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await VisitingCardHelper().shareVisitingCard(cardKey, shareProfile: false);
    } finally {
      overlay.remove();
    }
  }

  bool _isSharing = false;

  Future<void> shareVisitingCard(GlobalKey cardKey, {bool shareProfile = true}) async {
    // Prevent multiple calls
   log('callll');
    if (_isSharing) return;

    try {
      _isSharing = true; // Set flag to prevent multiple calls

      // Capture with RepaintBoundary (keeps your background image)
      RenderRepaintBoundary boundary =
      cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save captured image
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/visiting_card.png').create();
      await file.writeAsBytes(pngBytes);

      final String message;
      if (shareProfile) {
        final link = profileDeepLink(userId: userId);
        message = "See my profile on BlueEra:\n$link\n";
      } else {
        message = """
Download our app now:
👉 Play Store: ${AppConstants.androidPlayStoreUrl}
👉 App Store: ${AppConstants.iosAppStoreUrl}
""";
      }

      // ✅ Share with image + text
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: message,
        subject: message,
      ));

      // Clean up the temporary file
      if (await file.exists()) {
        await file.delete();
        debugPrint("🗑️ Visiting card image deleted from cache.");
      }

    } catch (e) {
      debugPrint("❌ Error sharing card: $e");
    } finally {
      _isSharing = false;
    }
  }
}