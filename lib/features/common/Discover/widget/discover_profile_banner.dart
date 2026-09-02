import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/referral/service/referral_share.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/franchise/request_to_franchise.dart';
import 'package:BlueEra/widgets/go_live_product_gate.dart';
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
///   1. **"You are not live"** — the go-live card, in the account's own flavour
///      ([AppImageAssets.goLiveBusinessAccount] /
///      [AppImageAssets.goLiveIndividualAccount]). It appears ONLY while the
///      account is offline and disappears the moment it goes live, so the slot
///      is a status light rather than a permanent promo. A guest has no account
///      to take live and gets the complete-profile artwork in that slot
///      instead: same box, so the header measures the same before and after
///      sign-up and nothing shifts under the user as they create a profile.
///
///      This replaced the account's backend marketing card (`marketing_card
///      .ready_url`). The card was the profile the user could already see;
///      being offline is something they usually cannot, and it is the one thing
///      that stops customers finding them.
///   2. **The grocery promo** — always present, in every condition.
///   3. **The franchise promo** — gated on [canSeeFranchiseBanner], and the one
///      bundled slide that goes somewhere: it opens the enquiry form.
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
      final guest = isGuestUser();
      // Null once the account is live — the slot then simply isn't there.
      final goLive = _goLiveSlide();

      // Built as a list rather than inline so the tap handler can key off WHICH
      // slide was tapped instead of a position: the leading slide is present
      // for a guest and for an offline account but absent for a live one, so
      // every index below it shifts.
      final slides = <String>[
        if (guest)
          AppImageAssets.completeProfileBanner
        else if (goLive != null)
          goLive,
        AppImageAssets.groceryBanner,
        if (canSeeFranchiseBanner) AppImageAssets.franchiseBanner,
      ];

      // Guests have no referral code and no poster, so there is nothing for
      // them to share yet — the share button and the hook are both withheld
      // until they have a profile. (A guest reaching the FOOTER banner is sent
      // to sign-up instead; here the button simply isn't drawn.)
      final VoidCallback? onShare = guest ? null : shareDiscoverReferral;

      final index = _current.clamp(0, slides.length - 1);

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
              // The "Share It, Get 100 Rupees" hook used to sit here, on the
              // marketing-card slide. It went with that slide: every remaining
              // slide is a promo for something OTHER than this user's profile,
              // and the offer is already stated in full on the Refer & Earn
              // banner further down the page.
              //
              // Share — the referral itself still travels from here (the code
              // and the deep link ride in the message text), so the button
              // stays. Top-right, clear of the page dots.
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

  /// The go-live artwork for this account, or null when there is nothing to
  /// say — the account is already live, or it is a guest / logged out.
  ///
  /// Reads the SAME observable each account type's own Go Live pill reads, so
  /// the card and the pill can never disagree:
  ///   * business → [ViewBusinessDetailsController.isLive] (computed from the
  ///     weekly schedule plus any same-day override);
  ///   * individual → [ViewPersonalDetailsController.shopStatusOpenClose].
  ///
  /// A business whose controller isn't registered yet returns null rather than
  /// guessing: "not live" is the state we advertise, and advertising it off a
  /// profile that simply has not loaded would show the card to accounts that
  /// are live.
  String? _goLiveSlide() {
    if (!isLoggedIn() || isGuestUser()) return null;

    if (isBusinessUser()) {
      if (!Get.isRegistered<ViewBusinessDetailsController>()) return null;
      final live = Get.find<ViewBusinessDetailsController>().isLive.value;
      return live ? null : AppImageAssets.goLiveBusinessAccount;
    }

    final personal = getOrPut(() => ViewPersonalDetailsController());
    return personal.shopStatusOpenClose.value
        ? null
        : AppImageAssets.goLiveIndividualAccount;
  }

  /// Takes the account live from here where that is the WHOLE tap, and hands
  /// off to the "Me" screen where it is not.
  ///
  /// Going live is gated differently per account, and the gates live on the
  /// screens that own the data behind them:
  ///
  ///  * **Un-gated business** (hospital, lab, hotel, school, doctor,
  ///    automotive-service, other) — its pill IS
  ///    `ViewBusinessDetailsController.toggleLiveNow()`, nothing else. That
  ///    call carries its own hours prompt and the plan / security-deposit gate
  ///    with it, so running it from here is the same tap, not a shortcut past
  ///    anything.
  ///  * **Catalogue business** (grocery, food, product, manufacturer, auto
  ///    parts, pharmacy, vehicle sales) — its pill runs
  ///    `ensureCatalogueBeforeGoLive` FIRST, off a catalogue controller that
  ///    only that screen owns. A shop taken live from here with empty shelves
  ///    would occupy every near-by list and hand each customer an empty store.
  ///  * **Individual** — deposit, background-location / battery / overlay
  ///    permissions, rider document checks.
  ///
  /// So the first case toggles, and the rest land on the Me tab with the pill
  /// in the top bar and every gate intact.
  Future<void> _onGoLiveTap() async {
    final canToggleHere = isBusinessUser() &&
        !businessGoLiveNeedsCatalogue() &&
        Get.isRegistered<ViewBusinessDetailsController>();

    if (canToggleHere) {
      await Get.find<ViewBusinessDetailsController>().toggleLiveNow();
      return;
    }
    _openMeTab();
  }

  /// The Me tab, where the account's own Go Live pill lives.
  void _openMeTab() {
    if (!Get.isRegistered<BottomBarController>()) return;
    Get.find<BottomBarController>()
        .onChangeIndex(BottomBarController.meTabIndex);
  }

  /// Wraps a slide in a tap target only where the slide actually goes
  /// somewhere, so the inert promos keep plain artwork and no invisible hit
  /// area under the share button's neighbourhood.
  Widget _tappable(String slide, bool guest, Widget child) {
    VoidCallback? onTap;
    if (slide == AppImageAssets.franchiseBanner) {
      onTap = () => Get.to(() => const FranchiseInquiryScreen());
    } else if (slide == AppImageAssets.goLiveBusinessAccount ||
        slide == AppImageAssets.goLiveIndividualAccount) {
      onTap = _onGoLiveTap;
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
