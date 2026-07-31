import 'dart:io';
import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/app_targeted_share.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/update_referral_page.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_strings.dart';

/// The referral share card: referral-code header, the promo clip, the
/// "Share One-Time, Earn Full Year" headline, the poster, and the share-via
/// row — one card, in that order.
///
/// The clip and the poster both come off the signed-in profile, so the whole
/// card composes itself from whatever the caller's account type resolves to;
/// each part self-hides when the profile carries no URL for it. The clip also
/// self-hides when the placement opts out via [showPromoVideo] — the Discover
/// bottom sheet does.
class ProfileShareBanner extends StatefulWidget {
  /// Marks this placement as an individual / professional one, so the card
  /// sources its poster, referral code and editability from the PERSONAL
  /// profile instead of the registered business profile (legacy behavior).
  ///
  /// The poster itself is generated server-side and rendered as-is, so these
  /// values are no longer drawn on the card — they only pick which profile the
  /// card reads from. Kept as separate fields because callers already pass
  /// whichever of them they happen to have.
  final String? overrideName;

  /// See [overrideName] — selects the personal-profile source.
  final String? overridePhoto;

  /// See [overrideName] — selects the personal-profile source.
  final String? overrideSubCategory;

  /// Account type used in the share-message deep link. Pass
  /// [AppConstants.individual] for personal/professional profiles;
  /// defaults to the global `accountTypeGlobal`.
  final String? accountType;

  /// Referral code shown in the header and embedded in the share
  /// message. Both the personal profile (`User.referral_code`) and the
  /// business profile (`BusinessProfileDetails.referral_code`) already
  /// carry this key — pass it from the personal dashboards; the legacy
  /// business path reads it off the registered profile automatically.
  final String? referralCode;

  /// Renders the close (✕) button in the header. Only the dialog
  /// presentation sets this — inline placements inside profile screens
  /// leave it `false` so no stray close control appears.
  final bool showCloseButton;

  /// Starts the promo clip immediately, **muted**, with a tap-to-unmute badge.
  ///
  /// Only the Discover promo sheet sets this: it opens on its own once a day,
  /// so the clip plays without being asked for — which is exactly why it must
  /// not make noise until the viewer opts in.
  ///
  /// Inline placements on the me-section profile screens leave it `false` and
  /// keep the plain tap-to-play behaviour: the user navigated there on purpose
  /// and the card is one section among many, so a clip that started itself
  /// mid-scroll would be an interruption.
  final bool autoPlayVideo;

  /// Renders the promo clip at all.
  ///
  /// The Discover bottom sheet passes `false`: that sheet opens on its own once
  /// a day, and a video playing inside it is more than the placement is asking
  /// for — the poster and the share row carry it. Inline placements on the
  /// me-section profile screens leave this `true`; the user navigated there
  /// deliberately, so the clip is content they can choose to play.
  final bool showPromoVideo;

  const ProfileShareBanner({
    super.key,
    this.overrideName,
    this.overridePhoto,
    this.overrideSubCategory,
    this.accountType,
    this.referralCode,
    this.showCloseButton = false,
    this.autoPlayVideo = false,
    this.showPromoVideo = true,
  });

  @override
  State<ProfileShareBanner> createState() => _ProfileShareBannerState();
}

class _ProfileShareBannerState extends State<ProfileShareBanner> {
  final GlobalKey _bannerKey = GlobalKey();
  bool _isExporting = false;

  /// The backend poster currently on screen, or null when the profile has
  /// none. Set from `build` and read by the share paths, which have nothing to
  /// capture without it.
  String? _posterUrl;

  @override
  Widget build(BuildContext context) {
    final hasOverride = (widget.overrideName?.trim().isNotEmpty ?? false) ||
        (widget.overridePhoto?.trim().isNotEmpty ?? false) ||
        (widget.overrideSubCategory?.trim().isNotEmpty ?? false) ||
        (widget.referralCode?.trim().isNotEmpty ?? false);

    // Override path — caller supplied the data, no observable to
    // listen to here, so render directly. Wrapping in Obx without
    // touching any .value would trip the "improper Obx use" check.
    if (hasOverride) {
      // Override path is the individual/professional profile — editability and
      // the ready-made poster come off the personal profile record. The referral
      // code falls back to the personal profile too, so callers that don't pass
      // one (e.g. the Discover share promo) still show it instead of '------'.
      final referral = (widget.referralCode?.trim().isNotEmpty ?? false)
          ? widget.referralCode
          : _safePersonalReferralCode();
      return _buildBannerCard(referral, _safePersonalReferralEditable(),
          marketingCardUrl: _safePersonalMarketingCardUrl());
    }

    // Legacy business path — observe the registered business profile
    // so the banner repaints when business details load / change.
    return Obx(() {
      final details = _safeBusinessDetails();
      if (details == null) return const SizedBox.shrink();
      return _buildBannerCard(
          details.referral_code, details.referralCodeEditable ?? false,
          marketingCardUrl: details.marketingCard?.readyUrl);
    });
  }

  /// Reads the ready-made poster URL off the signed-in personal profile. The
  /// backend nests it inside `user`. Guarded so it never throws when the
  /// controller isn't registered.
  String? _safePersonalMarketingCardUrl() {
    try {
      return Get.find<ViewPersonalDetailsController>()
          .personalProfileDetails
          .value
          .user
          ?.marketingCard
          ?.readyUrl;
    } catch (_) {
      return null;
    }
  }

  /// The promo clip for the signed-in account, or null when there isn't one.
  ///
  /// Sourced from `referal_video` on the profile response — a TOP-LEVEL key,
  /// not part of `marketing_card` (that object is poster-only). Business
  /// accounts read their business profile; everyone else reads the personal
  /// profile — the same split this widget uses to pick its poster, so the clip
  /// and the card always come from one profile.
  ///
  /// Falls back across the two profiles: a business user whose business
  /// response omits the key still gets the clip off their personal profile,
  /// which is where the sample payload carries it.
  String? _resolveVideoUrl() {
    final business = _safeBusinessVideo();
    final personal = _safePersonalVideo();
    return isBusinessUser() ? (business ?? personal) : (personal ?? business);
  }

  /// Guarded — the controller may not be registered on every entry path.
  String? _safeBusinessVideo() {
    try {
      return Get.find<ViewBusinessDetailsController>()
          .businessProfileDetails
          .value
          ?.referalVideoUrl;
    } catch (_) {
      return null;
    }
  }

  String? _safePersonalVideo() {
    try {
      return Get.find<ViewPersonalDetailsController>()
          .personalProfileDetails
          .value
          .referalVideoUrl;
    } catch (_) {
      return null;
    }
  }

  /// Reads the referral code off the signed-in personal profile (`user`).
  /// Guarded so it never throws when the controller isn't registered.
  String? _safePersonalReferralCode() {
    try {
      return Get.find<ViewPersonalDetailsController>()
          .personalProfileDetails
          .value
          .user
          ?.referral_code;
    } catch (_) {
      return null;
    }
  }

  /// Reads `referralCodeEditable` off the signed-in personal profile.
  /// Guarded so it never throws when the controller isn't registered.
  bool _safePersonalReferralEditable() {
    try {
      return Get.find<ViewPersonalDetailsController>()
              .personalProfileDetails
              .value
              .user
              ?.referralCodeEditable ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the update-referral screen, seeding the shared controller with
  /// the current code so the field is pre-filled.
  void _openUpdateReferral(String? referralCode) {
    final c = getOrPut(() => ReferralController());
    c.loadProfileReferralInfo();
    if ((referralCode ?? '').trim().isNotEmpty) {
      c.profileReferralCode.value = referralCode!.trim();
    }
    Get.to(() => UpdateReferralPage(controller: c));
  }

  Widget _buildBannerCard(String? referralCode, bool referralCodeEditable,
      {String? marketingCardUrl}) {
    // In dialog mode the card sits directly inside the dialog (itself a
    // white rounded surface), so keep a tight uniform 10px inset and no
    // top margin instead of stacking padding on the dialog's own inset.
    final bool dialogMode = widget.showCloseButton;
    // Null when the placement opts out of the clip (Discover sheet) — the
    // player below is skipped entirely rather than built and hidden, so no
    // VideoPlayerController is ever created for it.
    final videoUrl = widget.showPromoVideo ? _resolveVideoUrl() : null;
    final poster = (marketingCardUrl?.trim().isNotEmpty ?? false)
        ? marketingCardUrl!.trim()
        : null;
    // Remembered for the share paths: with no backend poster there is nothing
    // to capture, so they send the referral text on its own rather than an
    // empty PNG.
    _posterUrl = poster;
    return CustomFormCard(
      padding: EdgeInsets.all(dialogMode ? 10.0 : 14.0),
      margin: dialogMode ? EdgeInsets.zero : const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          SizedBox(height: SizeConfig.size10),
          const _DashedDivider(),
          SizedBox(height: SizeConfig.size12),
          // Clip sits between the header and the headline, and collapses away
          // entirely when the profile has none or the placement opted out —
          // kept OUT of the [RepaintBoundary] below so it never lands in the
          // shared PNG. Its trailing divider goes with it, otherwise the two
          // rules stack a few pixels apart with nothing between them.
          if (videoUrl != null) ...[
            _PromoVideoPlayer(
              key: ValueKey(videoUrl),
              url: videoUrl,
              autoPlay: widget.autoPlayVideo,
            ),
            SizedBox(height: SizeConfig.size12),
            const _DashedDivider(),
            SizedBox(height: SizeConfig.size12),
          ],
          _headline(referralCode, referralCodeEditable),
          // The poster is the backend-generated card and nothing else — no
          // client-composed artwork. A profile whose card isn't generated yet
          // simply shows the rest of the card without a poster.
          if (poster != null) ...[
            SizedBox(height: SizeConfig.size12),
            // The promo line is stacked OUTSIDE the [RepaintBoundary], over the
            // poster rather than inside it: everything within the boundary is
            // what gets captured and sent, and "Share It, Get 100 Rupees" is
            // addressed to the person holding the phone, not to whoever
            // receives the card. On screen it reads as part of the artwork; the
            // shared PNG stays exactly the poster the backend built.
            Stack(
              children: [
                RepaintBoundary(key: _bannerKey, child: _backendPoster(poster)),
                Positioned(top: 10, left: 14, right: 14, child: _promoLine()),
              ],
            ),
          ],
          SizedBox(height: SizeConfig.size14),
          _shareViaPanel(referralCode),
        ],
      ),
    );
  }

  /// The backend-generated poster, rendered directly and WHOLE, inside the
  /// [RepaintBoundary] so the existing "capture → share as PNG" flow still
  /// works unchanged.
  ///
  /// It used to be pinned into a 3:2 slot with `BoxFit.cover`. 3:2 is only what
  /// the bundled promo artwork is drawn at — the server composes these cards at
  /// whatever ratio it likes, so anything wider than 3:2 had its left and right
  /// edges cropped away, and the crop went into the shared PNG as well as onto
  /// the screen.
  ///
  /// So the poster now takes the card's full width and derives its own height
  /// from the image's real aspect ratio: nothing cropped, no letterbox bars,
  /// and the capture is the poster exactly as the backend built it. The 3:2 box
  /// survives only as the placeholder/error footprint, which keeps the card
  /// from jumping while the image loads.
  Widget _backendPoster(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        // fitWidth against an unbounded height: the render box takes the full
        // width and scales its height with the image's own ratio.
        fit: BoxFit.fitWidth,
        placeholder: (_, __) => _posterPlaceholder(),
        errorWidget: (_, __, ___) => _posterPlaceholder(),
      ),
    );
  }

  Widget _posterPlaceholder() => AspectRatio(
        aspectRatio: 3 / 2,
        child: Container(color: AppColors.greyE5),
      );

  /// The referral hook sitting on the poster's top-left corner — the same line
  /// the Discover header banner carries, so the card reads the same wherever it
  /// is placed. Broken over three lines with explicit newlines rather than left
  /// to soft-wrap, so the breaks don't move with the font scale.
  ///
  /// Yellow can't carry itself over a poster of unknown brightness, so it takes
  /// a dark shadow.
  Widget _promoLine() {
    return CustomText(
      'Share It,\nGet 100\nRupees',
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w700,
      color: AppColors.yellow00,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      shadows: const [
        Shadow(color: Color(0xB3000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
    );
  }

  BusinessProfileDetails? _safeBusinessDetails() {
    try {
      final ctrl = Get.find<ViewBusinessDetailsController>();
      return ctrl.businessProfileDetails.value?.data;
    } catch (_) {
      return null;
    }
  }

  // ───── Header (headline + optional close) ─────────────────────────

  /// Headline on the left, the dialog's ✕ trailing.
  ///
  /// Learn More used to sit up here beside the headline, competing with it for
  /// the row's width — it now lives under the share panel, next to the terms it
  /// opens (see [_learnMoreButton]).
  ///
  /// The headline is the only flexible child, so the close button always gets
  /// its intrinsic width and the row can't overflow on narrow screens.
  ///
  /// The two lines are authored with an explicit `\n` and then scaled down as a
  /// whole to whatever width is left over. At a hard 24px, "Share One-Time,"
  /// was wider than that leftover space on narrow phones and soft-wrapped, so
  /// the headline rendered as three ragged lines instead of the two it's
  /// written as. [BoxFit.scaleDown] shrinks the type instead of re-wrapping it,
  /// and never scales past the 24px design size on wider screens.
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                  color: AppColors.mainTextColor,
                ),
                children: [
                  const TextSpan(text: 'Share One-Time,\nEarn '),
                  TextSpan(
                    text: 'Full Year',
                    style: TextStyle(color: AppColors.blueAF),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showCloseButton) ...[
          SizedBox(width: SizeConfig.size4),
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded,
                  size: 22, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ],
    );
  }

  // ───── Headline + Learn More ──────────────────────────────────────

  Widget _headline(String? referralCode, bool referralCodeEditable) {
    final code = (referralCode?.trim().isNotEmpty ?? false)
        ? referralCode!.trim().toUpperCase()
        : '------';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Your Referral Code: ',
                  style: TextStyle(
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                TextSpan(
                  text: code,
                  style: TextStyle(
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Edit pen — only when the backend still allows changing the code.
        if (referralCodeEditable) ...[
          SizedBox(width: SizeConfig.size8),
          InkWell(
            onTap: () => _openUpdateReferral(referralCode),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: LocalAssets(
                imagePath: AppIconAssets.editIcon,
                imgColor: AppColors.primaryColor,
                height: 18,
                width: 18,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size4),
        ],
        SizedBox(width: SizeConfig.size8),
        _learnMoreLink(),
      ],
    );
  }

  /// Learn More as bare underlined text, trailing the referral-code line.
  ///
  /// It has moved twice and shrunk each time, for the same reason: it is a link
  /// to the terms, not an action. As a tinted pill beside the 24px headline it
  /// read as a second call to action and took width the headline needed; as
  /// plain text at the end of the code row it sits with the small print it
  /// belongs to and costs the card nothing.
  ///
  /// The underline is what carries the affordance now that there is no pill —
  /// blue text alone on this card would be indistinguishable from the code
  /// beside it. The padding is dead space around the glyphs purely to keep the
  /// tap target reachable.
  Widget _learnMoreLink() {
    return InkWell(
      onTap: _openTermsAndConditions,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: CustomText(
          AppStrings.learnMore.tr,
          fontSize: SizeConfig.small11,
          fontWeight: FontWeight.w600,
          color: AppColors.blueAF,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.blueAF,
        ),
      ),
    );
  }

  /// Learn More opens the referral terms & conditions in the in-app webview —
  /// the same `tncLink` + [CommonWebView] pairing every other T&C entry point
  /// in the app uses.
  void _openTermsAndConditions() {
    Get.to(
      () => CommonWebView(
        urlLink: tncLink,
        urlTitle: AppStrings.termsConditions.tr,
      ),
    );
  }

  // ───── Share-via panel ────────────────────────────────────────────

  Widget _shareViaPanel(String? referralCode) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.greyE5
          )
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
            'Share Your Referral Code Via',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _circleButton(
                color: const Color(0xFF22C55E),
                onTap: _isExporting
                    ? null
                    : () => _shareGeneric(referralCode),
                child: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 22),
              ),
              SizedBox(width: SizeConfig.size15),
              _circleButton(
                color: const Color(0xFF25D366),
                onTap: () => _shareToWhatsApp(referralCode),
                child: SvgPicture.string(_whatsappSvg, width: 22, height: 22),
              ),
              SizedBox(width: SizeConfig.size15),
              _circleButton(
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFFFEDA75),
                    Color(0xFFFA7E1E),
                    Color(0xFFD62976),
                    Color(0xFF962FBF),
                    Color(0xFF4F5BD5),
                  ],
                ),
                onTap: () => _shareToInstagram(referralCode),
                child: SvgPicture.string(_instagramSvg, width: 22, height: 22),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _circleButton({
    Color? color,
    Gradient? gradient,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? color : null,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.black).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ───── Share plumbing ─────────────────────────────────────────────

  /// Referral share body — profile deep link first, then headline +
  /// code + store links (the Play Store URL carries the code as a
  /// `referrer` param so Android's Install Referrer API can auto-apply
  /// it at first launch). The profile link itself already carries the
  /// referral code as a `?referralCode=` query param.
  String _referralMessage(String? referralCode) {
    final code = (referralCode ?? '').trim().toUpperCase();
    // Individual profiles deep-link to /app/profile; every other account
    // type is a business profile.
    final isIndividual =
        (widget.accountType ?? accountTypeGlobal).toUpperCase() ==
            AppConstants.individual;
    final profileLink = isIndividual
        ? profileDeepLink(userId: userId)
        : businessProfileDeepLink(userId: businessId);
    final playUrl = code.isNotEmpty
        ? '${AppConstants.androidPlayStoreUrl}'
            '&referrer=${Uri.encodeQueryComponent("referralCode=$code")}'
        : AppConstants.androidPlayStoreUrl;
    final buffer = StringBuffer()
      ..writeln(
          '🎁Share One-Time, Earn Full Year on BlueEra! Visit-$profileLink')
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

  Future<Uint8List?> _captureBannerPng({double pixelRatio = 3.0}) async {
    // No backend poster → no boundary in the tree to capture. Bail out here so
    // the share paths fall through to their text-only branch.
    if (_posterUrl == null) return null;
    try {
      final boundary = _bannerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Banner capture failed: $e');
      return null;
    }
  }

  /// Captures the poster and writes it to a temp PNG, or null if the capture
  /// failed. Shared by every share path so they all send the same image.
  ///
  /// The cache dir is deliberate — it's the only location exposed by the
  /// `beshare` FileProvider that the direct-to-app share hands URIs through.
  Future<File?> _writeBannerPng() async {
    final bytes = await _captureBannerPng();
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/referral_banner_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Opens the OS share sheet with the poster + referral message so the user
  /// can pick any target app. Also the fallback for the per-app buttons.
  Future<void> _shareGeneric(String? referralCode) async {
    setState(() => _isExporting = true);
    try {
      final caption = _referralMessage(referralCode);
      final file = await _writeBannerPng();
      if (file == null) {
        // Text-only share if the capture failed — better than nothing.
        await SharePlus.instance
            .share(ShareParams(text: caption, subject: caption));
        return;
      }
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile(file.path, mimeType: 'image/png', name: 'referral_banner.png')
        ],
        text: caption,
        subject: caption,
      ));
    } catch (e) {
      commonSnackBar(message: 'Share failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Share the poster straight into WhatsApp.
  ///
  /// This used to launch `whatsapp://send?text=…`, which is why it sent text
  /// with no image: a URL scheme can carry a message but has no way to attach
  /// a file. Pushing the image needs a native ACTION_SEND with setPackage
  /// (see [AppTargetedShare]).
  ///
  /// Falls back to the system sheet — still carrying the image — when the
  /// direct route isn't available (iOS, WhatsApp not installed, capture
  /// failed). The user then picks WhatsApp themselves and the poster still
  /// goes with it.
  Future<void> _shareToWhatsApp(String? referralCode) async {
    setState(() => _isExporting = true);
    try {
      final caption = _referralMessage(referralCode);
      final file = await _writeBannerPng();
      if (file != null) {
        final sent = await AppTargetedShare.shareFileToApp(
          filePath: file.path,
          packages: AppTargetedShare.whatsappPackages,
          text: caption,
        );
        if (sent) return;
      }
    } catch (_) {
      // Fall through to the sheet.
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
    await _shareGeneric(referralCode);
  }

  /// Share the poster into Instagram.
  ///
  /// Instagram accepts a shared image but ignores `EXTRA_TEXT` — it has no
  /// caption pre-fill — so the referral message is copied to the clipboard for
  /// the user to paste. Without that, a direct share would post the poster
  /// with no code attached.
  Future<void> _shareToInstagram(String? referralCode) async {
    final caption = _referralMessage(referralCode);
    await Clipboard.setData(ClipboardData(text: caption));

    setState(() => _isExporting = true);
    try {
      final file = await _writeBannerPng();
      if (file != null) {
        final sent = await AppTargetedShare.shareFileToApp(
          filePath: file.path,
          packages: AppTargetedShare.instagramPackages,
          text: caption,
        );
        if (sent) {
          commonSnackBar(
              message: 'Referral copied — paste it into your Instagram post');
          return;
        }
      }
    } catch (_) {
      // Fall through to the sheet.
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
    await _shareGeneric(referralCode);
  }

  // Brand glyphs kept inline so the buttons need no extra asset files.
  static const String _whatsappSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill="#FFFFFF" d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.149-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.885-9.885 9.885M20.52 3.449C18.24 1.245 15.24 0 12.045 0 5.463 0 .104 5.359.101 11.892c0 2.096.549 4.14 1.595 5.945L0 24l6.335-1.652a12.062 12.062 0 005.71 1.447h.006c6.585 0 11.946-5.359 11.949-11.893a11.821 11.821 0 00-3.481-8.413z"/>'
      '</svg>';

  static const String _instagramSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill="#FFFFFF" d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069M12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0m0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324M12 16a4 4 0 110-8 4 4 0 010 8m6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881"/>'
      '</svg>';
}

/// Short dashed horizontal rule under the header — mirrors the dashed
/// separator in the reference card.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(color: AppColors.greyE5),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashLength = 5;
  static const double _dashGap = 4;

  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final centerY = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final end = (x + _dashLength).clamp(0, size.width).toDouble();
      canvas.drawLine(Offset(x, centerY), Offset(end, centerY), paint);
      x += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  Promo clip — 16:9 tap-to-play referral video.
// ═══════════════════════════════════════════════════════════════════

/// Tap the body to play/pause; the badge replays once it ends.
///
/// With [autoPlay] false (the inline placements) it starts **paused** at full
/// volume — the viewer presses play, so they've asked for sound.
///
/// With [autoPlay] true (the Discover sheet) it starts playing **muted** and
/// shows a tap-to-unmute badge. The sheet opens on its own, so nobody asked for
/// audio; playing it anyway would blast a stranger's promo at whoever happens
/// to be in earshot. Sound stays one tap away.
///
/// Collapses to nothing if the video fails to load, so a bad URL costs an empty
/// box, not a broken one.
class _PromoVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const _PromoVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
  });

  @override
  State<_PromoVideoPlayer> createState() => _PromoVideoPlayerState();
}

class _PromoVideoPlayerState extends State<_PromoVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _ready = false;

  /// Clips start unmuted — both the inline placements and the autoplay Discover
  /// sheet play at full volume by default. The badge lets the viewer mute.
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted) return;
      controller.addListener(_onValueChanged);
      if (widget.autoPlay) {
        // Play at full volume by default — the viewer can mute via the badge.
        await controller.setVolume(1);
        await controller.play();
      }
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = !_muted;
    await c.setVolume(next ? 0 : 1);
    if (mounted) setState(() => _muted = next);
  }

  /// Repaints for play/pause and the end-of-video replay affordance.
  void _onValueChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onValueChanged);
    _controller?.dispose();
    super.dispose();
  }

  bool get _isEnded {
    final v = _controller?.value;
    if (v == null || !v.isInitialized) return false;
    return v.position >= v.duration && v.duration > Duration.zero;
  }

  Future<void> _toggle() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_isEnded) {
      await c.seekTo(Duration.zero);
      await c.play();
      return;
    }
    c.value.isPlaying ? await c.pause() : await c.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    final c = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        // Fixed 16:9 rather than the source ratio, so the card's height doesn't
        // jump once the video reports its real dimensions.
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_ready && c != null)
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  )
                else
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_ready && c != null && !c.value.isPlaying)
                  Center(child: _playBadge()),
                // Sound control only in autoplay mode — inline placements start
                // paused at full volume, so there's nothing to unmute and the
                // me-screens keep the plain play/pause they had.
                if (widget.autoPlay && _ready && c != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleMute,
                      child: _muteBadge(),
                    ),
                  ),
                if (_ready && c != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: AppColors.primaryColor,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playBadge() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
      child: Icon(
        _isEnded ? Icons.replay_rounded : Icons.play_arrow_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _muteBadge() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white70, width: 1.2),
      ),
      child: Icon(
        _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        color: Colors.white,
        size: 17,
      ),
    );
  }
}
