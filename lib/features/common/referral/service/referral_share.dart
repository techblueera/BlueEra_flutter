import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Sharing a referral, without a screen in front of it.
///
/// The share card ([ProfileShareBanner]) composes the same thing out of widgets
/// so it can be looked at; this is the path for placements that already show
/// the poster and just need the OS sheet — the Discover header's share button.
/// Both build their message here, so the two can never drift into sending
/// different links or a differently-formatted code.

/// Whether the franchise promo may be shown to the signed-in account.
///
/// Gig workers and the self-employed are withheld: a franchise enquiry is an
/// invitation to run a BlueEra outlet, which is not what either account is on
/// the platform for — they are here to take work, not to buy a territory.
///
/// Reads `userProfileTypeGlobal`, NOT `userProfessionGlobal`. The two are easy
/// to confuse: the profile TYPE holds the bucket (`GIG_WORKER`,
/// `SELF_EMPLOYED`, …) while the profession holds the specific tag inside it
/// (`BIKE_RIDER`, `MECHANIC`, …). Testing the profession against these two
/// values would never match, so the banner would show to everyone and the gate
/// would look like it worked.
bool get canSeeFranchiseBanner =>
    userProfileTypeGlobal != GIG_WORKER &&
    userProfileTypeGlobal != SELF_EMPLOYED;

/// The referral share body: profile deep link, then the headline, code and
/// store links.
///
/// The Play Store URL carries the code as a `referrer` param so Android's
/// Install Referrer API can auto-apply it at first launch, and the profile link
/// already carries it as `?referralCode=`.
///
/// [accountType] picks which deep link the message points at; it defaults to
/// the signed-in account's. Individual profiles link to `/app/profile`,
/// everything else to the business profile.
String buildReferralShareMessage({String? referralCode, String? accountType}) {
  final code = (referralCode ?? '').trim().toUpperCase();
  final isIndividual = (accountType ?? accountTypeGlobal).toUpperCase() ==
      AppConstants.individual;
  final profileLink = isIndividual
      ? profileDeepLink(userId: userId)
      : businessProfileDeepLink(userId: businessId);
  final playUrl = code.isNotEmpty
      ? '${AppConstants.androidPlayStoreUrl}'
          '&referrer=${Uri.encodeQueryComponent("referralCode=$code")}'
      : AppConstants.androidPlayStoreUrl;
  final buffer = StringBuffer()
    ..writeln('🎁Share One-Time, Earn Full Year on BlueEra! Visit-$profileLink')
    ..writeln();
  if (code.isNotEmpty) {
    buffer
      ..writeln('🎁 My Referral Code: $code')
      ..writeln();
  }
  buffer
    ..writeln('Download BlueEra:')
    ..writeln('👉 Play Store: $playUrl')
    ..writeln('👉 App Store: ${AppConstants.iosAppStoreUrl}');
  return buffer.toString();
}

/// Opens the OS share sheet with the backend poster and the referral message.
///
/// The poster comes from its URL rather than a screen capture: the placements
/// that call this show it as one slide of a carousel, so capturing what is on
/// screen would send the grocery promo whenever that slide happened to be up.
/// Fetching by URL sends the card the backend built, whatever the carousel is
/// doing.
///
/// Degrades to a text-only share when there is no poster or it can't be
/// fetched — a referral message with no image is still a working referral.
Future<void> shareReferralPoster({
  String? posterUrl,
  String? referralCode,
  String? accountType,
}) async {
  final caption = buildReferralShareMessage(
    referralCode: referralCode,
    accountType: accountType,
  );
  try {
    final file = await _posterFile(posterUrl);
    if (file == null) {
      await SharePlus.instance
          .share(ShareParams(text: caption, subject: caption));
      return;
    }
    await SharePlus.instance.share(ShareParams(
      files: [
        XFile(file.path, mimeType: _mimeFor(file.path), name: 'referral_card'
            '${_extensionFor(file.path)}')
      ],
      text: caption,
      subject: caption,
    ));
  } catch (e) {
    commonSnackBar(message: 'Share failed: $e');
  }
}

/// The poster as a file the share sheet can attach, or null.
///
/// Goes through the image cache the banner already painted from, so an on-screen
/// poster is shared without a second download. The copy into the temp directory
/// is deliberate: that is the location this app's share paths are wired to hand
/// URIs out of, and the cache manager's own directory is not.
Future<File?> _posterFile(String? url) async {
  final source = url?.trim() ?? '';
  if (source.isEmpty || !source.startsWith('http')) return null;
  try {
    final cached = await DefaultCacheManager().getSingleFile(source);
    if (!await cached.exists()) return null;
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/referral_card_'
        '${DateTime.now().millisecondsSinceEpoch}${_extensionFor(source)}');
    await out.writeAsBytes(await cached.readAsBytes());
    return out;
  } catch (_) {
    // Offline, 404, or an unwritable temp dir — the caller falls back to text.
    return null;
  }
}

/// File extension off a URL or path, ignoring any query string. Defaults to
/// `.jpg`: these posters are photographic, and an extension that disagrees with
/// the bytes is what makes a receiving app refuse the attachment.
String _extensionFor(String source) {
  final path = source.split('?').first;
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot < path.lastIndexOf('/')) return '.jpg';
  final ext = path.substring(dot).toLowerCase();
  return ext.length <= 5 ? ext : '.jpg';
}

String _mimeFor(String path) =>
    _extensionFor(path) == '.png' ? 'image/png' : 'image/jpeg';
