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

  /// Snapshots the widget behind [cardKey] (must point at a
  /// [RepaintBoundary]) to a PNG and shares it with a body chosen by
  /// [_messageForCard]. [isProfileCard] true → attach the profile
  /// link; otherwise the most-specific of the id params wins, falling
  /// back to the app-download message.
  Future<void> captureAndShareCard(
    GlobalKey cardKey, {
    bool isProfileCard = true,
    String? productId,
    String? serviceId,
    String? foodServiceId,
  }) {
    return _captureAndShare(
      cardKey: cardKey,
      message: _messageForCard(
        isProfileCard: isProfileCard,
        productId: productId,
        serviceId: serviceId,
        foodServiceId: foodServiceId,
      ),
    );
  }

  /// Snapshots the widget behind [cardKey] and shares it as the
  /// referral invite *image*, paired with the full "download BlueEra"
  /// text body (both store links + the eye-catching referral block).
  /// Pass [overrideReferralCode] on surfaces that already hold the
  /// code — e.g. the referral dashboard reads it from wallet stats —
  /// so the body's code matches the one printed on the poster.
  Future<void> shareReferralImageCard({
    required GlobalKey cardKey,
    String? overrideReferralCode,
  }) {
    return _captureAndShare(
      cardKey: cardKey,
      message: _appDownloadMessage(overrideReferralCode: overrideReferralCode),
    );
  }

  /// Single capture path behind every image share: snapshots a keyed
  /// [RepaintBoundary] to a temp PNG, opens the OS share sheet with the
  /// image + [message], then deletes the temp file. Re-entrancy guarded
  /// (`_isSharing`) so a rapid double-tap can't fire two sheets at once.
  Future<void> _captureAndShare({
    required GlobalKey cardKey,
    required String message,
  }) async {
    if (_isSharing) return;
    _isSharing = true;
    try {
      // Snapshot the keyed widget — pixelRatio 3.0 keeps the exported
      // PNG sharp on high-DPI receiving devices.
      final boundary = cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Drop the PNG into the OS temp dir so SharePlus can attach it,
      // then delete it once the sheet has taken it — keeps cache lean.
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/blueera_share_card.png').create();
      await file.writeAsBytes(pngBytes);

      await openShareSheet(
        text: message,
        subject: message,
        files: [XFile(file.path)],
      );

      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Share card image deleted from cache.');
      }
    } catch (e) {
      debugPrint('❌ Error sharing card: $e');
    } finally {
      _isSharing = false;
    }
  }

  /// Resolves which message body to attach to a card share. Pure
  /// function (no I/O, no state) so it's safe to unit-test and
  /// re-use for any "what would this share look like?" preview UI.
  String _messageForCard({
    required bool isProfileCard,
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
    if (isProfileCard) {
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

  Future<void> shareProfConsProfile({
    required String userId,
    String? subject,
  }) {
    final link = professionalsConsultantDeepLink(id: userId);
    return openShareSheet(
      text: _profileShareMessage(link),
      subject: subject,
    );
  }

  /// Share a single product via its deep link. Mirrors [shareProfile] —
  /// opens the OS share sheet with a short body + the product deeplink
  /// (which auto-carries the signed-in BDM's referral code as a query
  /// param when eligible). [productName], when supplied, is woven into
  /// the body and used as the default subject so the share preview reads
  /// naturally on apps that surface it.
  Future<void> shareProduct({
    required String productId,
    String? productName,
    String? subject,
  }) {
    return openShareSheet(
      text: _productShareMessage(productId: productId, productName: productName),
      subject: subject ??
          ((productName != null && productName.isNotEmpty)
              ? productName
              : 'Check out this product on BlueEra'),
    );
  }

  /// Builds the product share body. Mirrors [_profileShareMessage]: the
  /// deeplink already encodes the BDM referral code as a query param, but
  /// the human-readable referral block is also appended (when eligible)
  /// so recipients on iOS can enter the code by hand at sign-up.
  String _productShareMessage({
    required String productId,
    String? productName,
  }) {
    final buffer = StringBuffer();
    if (productName != null && productName.isNotEmpty) {
      buffer.writeln('Check out "$productName" on BlueEra:');
    } else {
      buffer.writeln('Check out this product on BlueEra:');
    }
    buffer.writeln(productDeepLink(productId: productId));
    final code = currentBdmReferralCode();
    if (code != null && code.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(_referralCodeBlock(code));
    }
    return buffer.toString();
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
        ..writeln(_referralCodeBlock(code));
    }
    return buffer.toString();
  }

  /// Eye-catching referral block appended to the bottom of both the
  /// app-download and profile share bodies. OS share sheets are plain
  /// text — no font or colour control — so "attractive" here means
  /// emoji plus a separator rule that makes the code jump out from
  /// the surrounding lines. Returns the block with no leading/trailing
  /// blank line; callers add their own spacing.
  String _referralCodeBlock(String code) =>
      '━━━━━━━━━━━━━━\n'
      '🎁  My Referral Code\n'
      '🔑  $code\n'
      '✨  Apply it at sign-up & get rewarded!\n'
      '━━━━━━━━━━━━━━';

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

  /// Standard "See my profile on BlueEra" share-body template. When
  /// the signed-in user is a verified BDM, the referral code is also
  /// spelled out at the bottom (mirroring [_appDownloadMessage]) so
  /// the recipient can enter it by hand at sign-up — the [link]
  /// already carries it as a `referralCode` query param. Non-BDM
  /// users share just the profile link, no referral line.
  String _profileShareMessage(String link) {
    final buffer = StringBuffer()
      ..writeln('See my profile on BlueEra:')
      ..writeln(link);
    final code = currentBdmReferralCode();
    if (code != null && code.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(_referralCodeBlock(code));
    }
    return buffer.toString();
  }
}
