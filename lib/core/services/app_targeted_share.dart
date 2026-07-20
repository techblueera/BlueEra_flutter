import 'dart:io';

import 'package:flutter/services.dart';

/// Share a file straight to a named app, skipping the system chooser.
///
/// ## Why this exists
/// Neither of the obvious routes can do it:
/// * `share_plus` opens the system chooser — `ShareParams` has no field for
///   targeting a package.
/// * `whatsapp://send?text=` (and the equivalent schemes) carry **text only**;
///   a URL scheme has no way to attach a file.
///
/// Sending an image directly therefore needs a native `ACTION_SEND` with
/// `setPackage()`, which is what the `ai.bluecs.app/app_share` channel does.
///
/// **Android only.** iOS has no supported way for one app to push a file into
/// another specific app — WhatsApp's iOS URL scheme is text-only and Apple
/// routes everything else through the share sheet. [shareFileToApp] returns
/// false on iOS so callers fall back to the normal sheet, which is the correct
/// behaviour there rather than a missing feature.
class AppTargetedShare {
  const AppTargetedShare._();

  static const MethodChannel _channel =
      MethodChannel('ai.bluecs.app/app_share');

  /// WhatsApp consumer app, then WhatsApp Business — tried in order, so a user
  /// with only the Business app still gets a direct share.
  static const List<String> whatsappPackages = [
    'com.whatsapp',
    'com.whatsapp.w4b',
  ];

  static const List<String> instagramPackages = ['com.instagram.android'];

  /// Push [filePath] into the first installed app in [packages].
  ///
  /// Returns true only when an app actually opened. False means "not
  /// possible" — wrong platform, app not installed, file gone — and the caller
  /// should fall back to the system share sheet.
  ///
  /// [text] rides along as `EXTRA_TEXT`. WhatsApp honours it as the message
  /// caption alongside the image; some other apps drop it and take the file
  /// only, which is why the caption is also worth keeping in the fallback.
  static Future<bool> shareFileToApp({
    required String filePath,
    required List<String> packages,
    String? text,
    String mimeType = 'image/png',
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('shareFileToApp', {
        'path': filePath,
        'packages': packages,
        'text': text,
        'mimeType': mimeType,
      });
      return result == true;
    } catch (_) {
      // Channel missing (older build) or the platform threw — treat as "can't
      // do it" so the caller degrades to the share sheet.
      return false;
    }
  }
}
