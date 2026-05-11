import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  bool _isSharing = false;
  Future<void> shareCard(
    GlobalKey cardKey, {
    bool shareProfile = true,
    String? productId,
    String? serviceId,
    String? foodServiceId,
  }) async {
    if (_isSharing) return;
    _isSharing = true;
    try {
      // 1. Snapshot the keyed widget. cardKey must point at a
      // RepaintBoundary; the higher pixelRatio (3.0) keeps the
      // exported PNG sharp on high-DPI receiving devices.
      final boundary = cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Drop the PNG into the OS temp dir so SharePlus can hand
      // it off as a file attachment. The temp file is deleted in the
      // finally-style cleanup at the bottom — keeps the cache lean.
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/visiting_card.png').create();
      await file.writeAsBytes(pngBytes);

      // 3. Build the message body. Single helper so this dispatch is
      // testable + reused for any future "preview the share text
      // before actually sharing" surface.
      final message = _buildMessage(
        shareProfile: shareProfile,
        productId: productId,
        serviceId: serviceId,
        foodServiceId: foodServiceId,
      );

      // Route through `openShareSheet` so every share surface —
      // card, text-only profile share, etc. — funnels through the
      // same wrapper. Future tweaks (analytics, fallback copy,
      // error handling) only need to land in one place.
      await openShareSheet(
        text: message,
        subject: message,
        files: [XFile(file.path)],
      );

      // Tidy up the temp file. Best-effort — if the share sheet
      // kept a handle on the file it'll already be gone.
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Visiting card image deleted from cache.');
      }
    } catch (e) {
      debugPrint('❌ Error sharing card: $e');
    } finally {
      _isSharing = false;
    }
  }

  /// Resolves which message body to attach to the share. Pure
  /// function (no I/O, no state) so it's safe to unit-test and
  /// re-use for any "what would this share look like?" preview UI.
  String _buildMessage({
    required bool shareProfile,
    String? productId,
    String? serviceId,
    String? foodServiceId,
  }) {
    if (productId != null) {
      return 'Link to visit my store at BlueEra app:\n'
          '${productDeepLink(productId: productId)}\n';
    }
    if (serviceId != null) {
      return 'Link to visit my store at BlueEra app:\n'
          '${serviceDeepLink(serviceId: serviceId)}\n';
    }
    if (foodServiceId != null) {
      return 'Link to visit my store at BlueEra app:\n'
          '${foodServiceDeepLink(foodServiceId: foodServiceId)}\n';
    }
    if (shareProfile) {
      String link = profileDeepLink(
        userId: userId,
      );
      return _profileShareMessage(
          link
      );
    }
    return _appDownloadMessage();
  }


  Future<void> shareProfile({
    required String userId,
    String? subject,
  }) {
    final link = profileDeepLink(userId: userId);
    return openShareSheet(
      text: _profileShareMessage(link),
      subject: subject,
    );
  }

  /// Share the "download BlueEra" message with the signed-in user's
  /// BDM referral code embedded (when eligible). Caller can pass an
  /// [overrideReferralCode] to force a specific code — useful on
  /// surfaces that already have the code in hand (e.g. the BDM
  /// dashboard reads it from the wallet-stats API) and shouldn't
  /// race the profile-controller load.
  Future<void> shareAppDownload({
    String? overrideReferralCode,
    String? subject,
  }) {
    return openShareSheet(
      text: _appDownloadMessage(overrideReferralCode: overrideReferralCode),
      subject: subject ?? 'Join BlueEra',
    );
  }

  /// Builds the "download BlueEra" share body. When the signed-in
  /// user is a verified BDM (or [overrideReferralCode] is supplied)
  /// the referral code is encoded into the Play Store `referrer`
  /// param (captured by Android's Install Referrer API at first
  /// launch) and spelled out at the bottom for iOS users who need
  /// to enter it by hand at sign-up.
  String _appDownloadMessage({String? overrideReferralCode}) {
    final code = (overrideReferralCode != null &&
            overrideReferralCode.isNotEmpty)
        ? overrideReferralCode
        : currentBdmReferralCode();

    final playUrl = (code != null && code.isNotEmpty)
        ? '${AppConstants.androidPlayStoreUrl}'
            '&referrer=${Uri.encodeQueryComponent("referralCode=$code")}'
        : AppConstants.androidPlayStoreUrl;

    final buffer = StringBuffer()
      ..writeln('Download BlueEra:')
      ..writeln('👉 Play Store: $playUrl')
      ..writeln('👉 App Store: ${AppConstants.iosAppStoreUrl}');
    if (code != null && code.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Use my referral code at sign-up: $code');
    }
    return buffer.toString();
  }

  /// Single wrapper around `SharePlus.instance.share` — opens the
  /// OS share sheet with [text] (required), an optional [subject]
  /// (falls back to [text] when omitted, since most share sheets
  /// echo the body into the subject anyway), and optional [files]
  /// for image / attachment shares.
  Future<void> openShareSheet({
    required String text,
    String? subject,
    List<XFile>? files,
  }) async {
    await SharePlus.instance.share(ShareParams(
      text: text,
      subject: subject ?? text,
      files: files,
    ));
  }

  /// Standard "See my profile on BlueEra" share-body template.
  String _profileShareMessage(String link) =>
      'See my profile on BlueEra:\n$link\n';
}
