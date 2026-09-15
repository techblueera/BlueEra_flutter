import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discovery_video_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_video_slide.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/referral/service/referral_share.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/franchise/request_to_franchise.dart';
import 'package:BlueEra/features/ride_booking/view/ride_home_screen.dart';
import 'package:BlueEra/widgets/go_live_product_gate.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:visibility_detector/visibility_detector.dart';
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
///      For a guest, the INTRO CLIP from `discovery/video` takes this slot once
///      its URL arrives, replacing the complete-profile artwork rather than
///      joining it — a guest has nothing of their own to show here, and the
///      clip is the one thing on the page that can explain what the app is
///      before they commit to signing up. It plays muted, holds the carousel
///      until it has been watched (see `_videoWatched`), is torn down whenever
///      the banner is not in front of the user (see `_videoAlive`), and falls
///      back to the artwork it replaced — so a guest with no clip sees exactly
///      the old carousel.
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

/// The artwork for the banner's LEADING slot, or null when nothing belongs
/// there.
///
/// Extracted as a pure function because the rule is easy to get wrong in the
/// collection-literal that consumes it. Written inline as
/// `if (guest) if (...) a else b`, Dart's dangling-else binds the `else` to the
/// INNER `if` — which silently drops [goLiveSlide] for every signed-in account
/// while looking correct. The tests pin all four combinations.
///
/// * **Guest with a clip** — null. The clip REPLACES the complete-profile
///   artwork rather than being added ahead of it, so the same slot is never
///   shown twice. The artwork is still what the clip falls back to, so a clip
///   that fails or is buffering leaves the slide exactly where it always was.
/// * **Guest without a clip** — the complete-profile artwork, as before.
/// * **Signed in** — [goLiveSlide], which is itself null once the account is
///   live.
String? discoverBannerLeadingSlide({
  required bool guest,
  required String? videoUrl,
  required String? goLiveSlide,
}) {
  if (!guest) return goLiveSlide;
  return videoUrl == null ? AppImageAssets.completeProfileBanner : null;
}

/// Whether the carousel's auto-advance should be HELD on the intro clip.
///
/// A 4-second rotation would slide the clip away before a guest saw any of it,
/// so the one slide with something to say would get the least time to say it.
///
/// Derived from the current index rather than latched when playback starts.
/// A "video is playing" flag set on play and cleared on finish never gets
/// cleared when the viewer swipes away mid-clip — the slide is deactivated and
/// the end is never reached — so auto-advance would stay switched off for the
/// rest of the session. Deriving it means leaving the slide releases the
/// carousel immediately, and returning re-holds it only while the clip is still
/// unwatched.
bool discoverBannerHoldsForVideo({
  required String? videoUrl,
  required bool watched,
  required int index,
}) {
  // The clip, when present, is always the first slide.
  return videoUrl != null && !watched && index == 0;
}

class _DiscoverProfileBannerState extends State<DiscoverProfileBanner>
    with WidgetsBindingObserver, RouteAware {
  int _current = 0;

  /// True once the guest intro clip has played through (or failed).
  ///
  /// Until then the carousel's auto-advance is HELD while the clip's slide is
  /// on screen: a 4-second rotation would slide the clip away before a guest
  /// saw any of it, so the one slide with something to say would get the least
  /// time to say it.
  ///
  /// The hold is derived from this flag plus the CURRENT INDEX rather than
  /// being a "video is playing" flag of its own. A flag set on play and cleared
  /// on finish never gets cleared when the viewer swipes away mid-clip — the
  /// slide is deactivated and the end is never reached — so auto-advance would
  /// stay switched off for the rest of the session. Deriving it means leaving
  /// the slide releases the carousel immediately, and coming back re-holds it
  /// only if the clip still has not been watched.
  bool _videoWatched = false;

  // ── Is the banner actually in front of the user? ───────────────────────
  //
  // Three independent ways it can stop being, none of which unmount this
  // widget — so without all three the clip keeps decoding, and keeps talking
  // once it has been unmuted, behind whatever the user is now looking at.
  //
  // Switching bottom-nav TABS is deliberately not among them: the nav swaps
  // `_getScreen()`'s child outright, so the banner is unmounted and `dispose`
  // already tears the player down.

  /// Scrolled out of the Discover page's own viewport. The banner sits in the
  /// header, so this goes false as soon as the user scrolls down the page.
  bool _pageVisible = true;

  /// Another route is covering Discover (a chip opened the ride screen, a
  /// folder opened a sheet). [RouteAware] rather than the visibility detector:
  /// an opaque route on top does not reliably change the covered route's
  /// reported visibility, so this is the signal that actually fires.
  bool _routeCovered = false;

  /// The app is backgrounded. Nothing else here catches it — a widget in a
  /// paused app stays mounted, visible and un-covered.
  bool _appForeground = true;

  /// Whether the clip's player should exist at all. False tears it down; true
  /// builds it again from scratch.
  bool get _videoAlive => _pageVisible && !_routeCovered && _appForeground;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Guests only — nobody else gets this slide, so nobody else pays for the
    // request. The controller no-ops on every call after the first.
    if (isGuestUser()) {
      getOrPut(() => DiscoveryVideoController()).ensureLoaded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A route was pushed ON TOP of the one holding this banner.
  @override
  void didPushNext() => _setRouteCovered(true);

  /// That route popped and Discover is frontmost again.
  @override
  void didPopNext() => _setRouteCovered(false);

  void _setRouteCovered(bool covered) {
    if (!mounted || _routeCovered == covered) return;
    setState(() => _routeCovered = covered);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (!mounted || _appForeground == foreground) return;
    setState(() => _appForeground = foreground);
  }

  @override
  Widget build(BuildContext context) {
    // Resolved outside the Obx so the builder below always has at least one
    // observable to read — a business account whose own controller isn't
    // registered on this entry path would otherwise touch no Rx at all and trip
    // GetX's "improper Obx use" check.
    final personalCtrl = getOrPut(() => ViewPersonalDetailsController());

    return Obx(() {
      final _ = personalCtrl.personalProfileDetails.value;

      final guest = isGuestUser();
      // Null once the account is live — the slot then simply isn't there.
      final goLive = _goLiveSlide();

      // The guest intro clip. Resolved BEFORE the slide list because it decides
      // what goes in the leading slot.
      //
      // Null for a signed-in account, and null for a guest until the URL
      // arrives — in both cases the card is exactly what it was before, so it
      // never holds an empty slot waiting on the network.
      final String? videoUrl = guest
          ? getOrPut(() => DiscoveryVideoController()).videoUrl.value
          : null;

      final leadingSlide = discoverBannerLeadingSlide(
        guest: guest,
        videoUrl: videoUrl,
        goLiveSlide: goLive,
      );

      // Built as a list rather than inline so the tap handler can key off WHICH
      // slide was tapped instead of a position: the leading slide is present
      // for a guest and for an offline account but absent for a live one, so
      // every index below it shifts.
      final slides = <String>[
        if (leadingSlide != null) leadingSlide,
        AppImageAssets.groceryBanner,
        // Book-a-ride promo. Always present, like the grocery slide — the ride
        // flow is open to any signed-in account, and a guest tapping it lands
        // on the same screen and is asked to sign in by the booking flow
        // itself rather than being refused a slide.
        AppImageAssets.rideBanner,
        if (canSeeFranchiseBanner) AppImageAssets.franchiseBanner,
      ];

      // Guests have no referral code and no poster, so there is nothing for
      // them to share yet — the share button and the hook are both withheld
      // until they have a profile. (A guest reaching the FOOTER banner is sent
      // to sign-up instead; here the button simply isn't drawn.)
      final VoidCallback? onShare = guest ? null : shareDiscoverReferral;

      // Widgets, not paths: every image slide resolves through `_slide` /
      // `_tappable` by path as it always did, but the clip is not a path and
      // cannot go through that lookup. Composing the final list here keeps the
      // string dispatch intact for the slides it was written for.
      final items = <Widget>[
        if (videoUrl != null)
          DiscoverVideoSlide(
            key: ValueKey(videoUrl),
            url: videoUrl,
            // The slide the clip replaced — shown while it buffers and kept if
            // it fails, so this slot is never blank or black and a guest who
            // never gets the clip still gets the sign-up call to action that
            // has always been here.
            fallback: _tappable(
              AppImageAssets.completeProfileBanner,
              guest,
              _slide(AppImageAssets.completeProfileBanner),
            ),
            // Torn down whenever the banner is not in front of the user, and
            // rebuilt when it is again — see [_videoAlive].
            alive: _videoAlive,
            // Sound follows the CURRENT slide. Scrolling the carousel to any
            // other slide silences the clip without disturbing playback, so a
            // viewer who unmuted never hears it narrating a different promo.
            hasFocus: _current == 0,
            onFinished: () {
              if (mounted) setState(() => _videoWatched = true);
            },
          ),
        for (final slide in slides) _tappable(slide, guest, _slide(slide)),
      ];

      final index = _current.clamp(0, items.length - 1);

      final holdForVideo = discoverBannerHoldsForVideo(
        videoUrl: videoUrl,
        watched: _videoWatched,
        index: index,
      );

      final card = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: DiscoverProfileBanner._aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (items.length == 1)
                // One slide has nothing to slide to: draw it flat and skip the
                // carousel (and its auto-play timer) altogether.
                items.first
              else
                CarouselSlider.builder(
                  itemCount: items.length,
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
                    autoPlay: !holdForVideo,
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
                  itemBuilder: (_, i, __) => items[i],
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
              if (items.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: _dots(items.length, index),
                ),
            ],
          ),
        ),
      );

      // Only the clip needs to know whether the banner is on screen, so the
      // detector is skipped entirely when there is no clip — every signed-in
      // account keeps exactly the widget tree it had.
      if (videoUrl == null) return card;

      return VisibilityDetector(
        // Unique per instance: the page mounts this banner in the header AND
        // again above the QR row, and VisibilityDetector keys a global
        // registry — two live detectors sharing a key report over each other.
        key: ValueKey('discover-banner-$hashCode'),
        onVisibilityChanged: (info) {
          final visible = info.visibleFraction > 0;
          if (!mounted || _pageVisible == visible) return;
          setState(() => _pageVisible = visible);
        },
        child: card,
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
    } else if (slide == AppImageAssets.rideBanner) {
      onTap = () => Get.to(() => const RideHomeScreen());
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
