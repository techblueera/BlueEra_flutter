import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/referral/service/referral_share.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/franchise/request_to_franchise.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The promo card at the top of Discover, and again above the QR row.
///
/// A CAROUSEL of up to three slides, restored from the header the current
/// Discover replaced (it had briefly collapsed to a single image):
///
///   1. **The account's marketing card** — the poster the backend composes for
///      sharing a profile, off `marketing_card.ready_url`. A guest has no
///      profile and so no card, and gets the bundled complete-profile artwork
///      in that slot instead: same box, so the header measures the same before
///      and after sign-up and nothing shifts under the user at the moment they
///      create a profile.
///   2. **The grocery promo** — always present, in every condition.
///   3. **The franchise promo** — gated on [canSeeFranchiseBanner], and the one
///      bundled slide that goes somewhere: it opens the enquiry form.
///
/// The share button and the "Share It, Get 100 Rupees" hook ride on the POSTER
/// slide only — the hook is about sharing this user's referral card, and
/// sitting it on the grocery or franchise promo read as a reward for those,
/// neither of which is shareable.
///
/// Lives in its own file rather than at the bottom of `discover_screen.dart`:
/// the page is long, and this is a self-contained component with its own state,
/// its own artwork rules and two mount points on that page.
class DiscoverProfileBanner extends StatefulWidget {
  const DiscoverProfileBanner({super.key});

  /// The box every slide is drawn into. Sized by ratio rather than a fixed
  /// height so the card is full-bleed on every screen width instead of being
  /// cropped to a strip on wide ones.
  ///
  /// **1.91, the artwork's own ratio** (all three bundled slides are 764x400),
  /// not the 2.05 measured off `assets/Discover.png`. At 2.05 the box is wider
  /// than the art relative to its height, so `cover` filled the width by
  /// slicing ~7% off the top and bottom of every promo. Matching the art means
  /// each slide covers the box edge to edge AND arrives complete; the card
  /// gains a few px of height over the design mock, which is the cheaper of the
  /// two compromises. The backend marketing card is composed at whatever ratio
  /// it likes and still gets `cover`, as it always did.
  static const double _aspect = 1.91;

  @override
  State<DiscoverProfileBanner> createState() => _DiscoverProfileBannerState();
}

/// Which marketing card and referral code belong to the signed-in account.
///
/// A business account falls back to the PERSONAL poster: it still has a
/// personal profile behind it, and for some accounts that is where the card was
/// generated. The code travels with the poster so the share message always
/// quotes the code belonging to the profile the card was made for.
///
/// Reads observables, so calling it inside an `Obx` registers a dependency and
/// the caller repaints when the profile lands.
({String? posterUrl, String? referralCode}) resolveReferralCard() {
  // getOrPut, not find: this is the same instance the share sheet composes its
  // card from.
  final personal = getOrPut(() => ViewPersonalDetailsController());
  String? poster =
      personal.personalProfileDetails.value.user?.marketingCard?.readyUrl;
  String? referralCode =
      personal.personalProfileDetails.value.user?.referral_code;

  if (isBusinessUser() && Get.isRegistered<ViewBusinessDetailsController>()) {
    final business =
        Get.find<ViewBusinessDetailsController>().businessProfileDetails;
    poster = business.value?.data?.marketingCard?.readyUrl ?? poster;
    referralCode = business.value?.data?.referral_code ?? referralCode;
  }

  final trimmed = poster?.trim();
  return (
    posterUrl: (trimmed?.isNotEmpty ?? false) ? trimmed : null,
    referralCode: referralCode,
  );
}

/// Opens the OS share sheet for a referral started from Discover.
///
/// **Every share sends the image the user was actually looking at.** The header
/// banner's share button sits ON the account's marketing card, so it sends that
/// card. The footer's Refer & Earn banner passes its own artwork as
/// [posterAsset], because sending someone's profile card from a banner that
/// reads "Invite Friends, Get Rewarded — Earn up to ₹1000" attaches a picture
/// they never saw and never mentions the offer they just tapped.
///
/// The referral CODE, the profile deep link and the store links all travel in
/// the message text either way, so the picture is free to be whichever one
/// makes the better invitation.
///
/// A guest has neither a poster nor a code, so they are sent to create a
/// profile rather than handed an empty share sheet: the invite is worth nothing
/// until there is an account for the reward to land in.
Future<void> shareDiscoverReferral({String? posterAsset}) async {
  if (isGuestUser()) {
    await createProfileScreen();
    return;
  }
  final card = resolveReferralCard();
  await shareReferralPoster(
    // A caller that supplied its own artwork means it; don't let the account's
    // marketing card take precedence over the thing on screen.
    posterUrl: posterAsset == null ? card.posterUrl : null,
    posterAsset: posterAsset,
    referralCode: card.referralCode,
  );
}

class _DiscoverProfileBannerState extends State<DiscoverProfileBanner> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    // Resolved outside the Obx so the builder below always has at least one
    // observable to read — a business account whose own controller isn't
    // registered on this entry path would otherwise touch no Rx at all and trip
    // GetX's "improper Obx use" check.
    getOrPut(() => ViewPersonalDetailsController());

    return Obx(() {
      // Only the poster is needed here — the share path resolves the code for
      // itself inside [shareDiscoverReferral].
      final poster = resolveReferralCard().posterUrl;

      final guest = isGuestUser();
      final hasPoster = poster != null;

      // Built as a list rather than inline so the tap handler can key off WHICH
      // slide was tapped instead of a position: the leading slide is present
      // for a guest and for a poster-holder but absent for a signed-in account
      // with no card yet, so every index below it shifts.
      final slides = <String>[
        if (guest)
          AppImageAssets.completeProfileBanner
        else if (hasPoster)
          poster,
        AppImageAssets.groceryBanner,
        if (canSeeFranchiseBanner) AppImageAssets.franchiseBanner,
      ];

      // Guests have no referral code and no poster, so there is nothing for
      // them to share yet — the share button and the hook are both withheld
      // until they have a profile. (A guest reaching the FOOTER banner is sent
      // to sign-up instead; here the button simply isn't drawn.)
      final VoidCallback? onShare = guest ? null : shareDiscoverReferral;

      final index = _current.clamp(0, slides.length - 1);
      // The poster is the only slide that comes from the profile API — the
      // bundled promos are assets — so "is this the shareable card" survives
      // slides being added or reordered, which an index would not.
      final onPosterSlide = isNetworkImage(slides[index]);

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: DiscoverProfileBanner._aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (slides.length == 1)
                // One slide has nothing to slide to: draw it flat and skip the
                // carousel (and its auto-play timer) altogether.
                _tappable(slides.first, guest, _slide(slides.first))
              else
                CarouselSlider.builder(
                  itemCount: slides.length,
                  options: CarouselOptions(
                    viewportFraction: 1.0,
                    aspectRatio: DiscoverProfileBanner._aspect,
                    // The carousel wraps every item in a `Center` unless this
                    // is set, and a Center hands its child LOOSE constraints —
                    // so each slide sized itself to the artwork's own ratio
                    // inside the box and sat there with a gutter down either
                    // side, reading as a floating card rather than the
                    // full-bleed banner it is. Off, the page's tight
                    // constraints reach the image and it fills the box.
                    disableCenter: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOutCubic,
                    enableInfiniteScroll: true,
                    scrollPhysics: const BouncingScrollPhysics(),
                    onPageChanged: (i, _) {
                      if (mounted) setState(() => _current = i);
                    },
                  ),
                  itemBuilder: (_, i, __) =>
                      _tappable(slides[i], guest, _slide(slides[i])),
                ),
              // The referral hook, ON the artwork: this banner IS the card the
              // user shares, so the reward for sharing it is stated on the card
              // rather than captioned above it. Top-LEFT, so it can never
              // collide with the share button opposite. Yellow can't carry
              // itself over a poster of unknown brightness, so it takes a dark
              // shadow.
              if (onShare != null && onPosterSlide)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 52,
                  // Broken over three lines with explicit newlines rather than
                  // left to soft-wrap: the breaks belong after the comma and
                  // before the amount, and the natural wrap points would
                  // otherwise move with the font scale.
                  child: CustomText(
                    'Share It,\nGet 100\nRupees',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow00,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    shadows: const [
                      Shadow(
                        color: Color(0xB3000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              // Share — sits on the artwork itself so the poster and the action
              // on it are one thing. Top-right, clear of the page dots.
              if (onShare != null)
                Positioned(top: 8, right: 8, child: _shareButton(onShare)),
              if (slides.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: _dots(slides.length, index),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// Wraps a slide in a tap target only where the slide actually goes
  /// somewhere, so the inert promos keep plain artwork and no invisible hit
  /// area under the share button's neighbourhood.
  Widget _tappable(String slide, bool guest, Widget child) {
    VoidCallback? onTap;
    if (slide == AppImageAssets.franchiseBanner) {
      onTap = () => Get.to(() => const FranchiseInquiryScreen());
    } else if (guest && slide == AppImageAssets.completeProfileBanner) {
      // The guest slide IS the call to action, so the whole artwork opens
      // sign-up.
      onTap = createProfileScreen;
    }
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  /// One slide, filling the card edge to edge.
  ///
  /// The marketing card is a backend URL while the promos are bundled assets,
  /// so the source is resolved per slide; a card that fails to load falls back
  /// to the bundled artwork rather than to a hole in the header.
  ///
  /// [SizedBox.expand] is not decoration. `Image` and `CachedNetworkImage` with
  /// no explicit width/height only fill their box when the box hands them TIGHT
  /// constraints — given a loose box they shrink to their own aspect ratio and
  /// leave a gap, `BoxFit.cover` or not. Making the slide expand itself means
  /// it stays full-bleed wherever it is mounted, rather than depending on every
  /// ancestor between here and the page to keep passing tight constraints down.
  Widget _slide(String path) {
    return SizedBox.expand(
      child: !isNetworkImage(path)
          ? LocalAssets(imagePath: path, boxFix: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: path,
              fit: BoxFit.cover,
              // Sized like the artwork it replaces, so a slow or failed load
              // never collapses the card's height mid-carousel.
              placeholder: (_, __) => const ColoredBox(color: Color(0x14000000)),
              errorWidget: (_, __, ___) => const LocalAssets(
                imagePath: AppImageAssets.completeProfileBanner,
                boxFix: BoxFit.cover,
              ),
            ),
    );
  }

  /// Dark glass pill over the artwork. Deliberately NOT the light glass the
  /// header's other chips use: those sit on the frosted header, this sits on a
  /// full-bleed image of unknown brightness, and a white-on-white chip would
  /// disappear on a light poster.
  Widget _shareButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.42),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: const Icon(Icons.share_rounded, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  /// Page dots — with three slides of similar artwork they're the only cue that
  /// the strip is moving at all.
  Widget _dots(int count, int active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.55),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
