import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart'
    show kFloatingBottomNavExtent;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/discovery_video_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_video_slide.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GuestDashBoardScreen extends StatefulWidget {
  const GuestDashBoardScreen({super.key});

  @override
  State<GuestDashBoardScreen> createState() => _GuestDashBoardScreenState();
}

class _GuestDashBoardScreenState extends State<GuestDashBoardScreen>
    with WidgetsBindingObserver, RouteAware {
  // Soft pastel page background like the reference mock.
  static const Color _earnCardBg = Color(0xFFE8F0FF);
  static const Color _businessCardBg = Color(0xFFFEF9EF);
  static const Color _professionCardBg = Color(0xFFFBF4FF);

  // Per-card borders (0.5 px) and a shared subtle drop shadow.
  static const Color _earnCardBorder = Color(0xFFCFDDFF);
  static const Color _businessCardBorder = Color(0xFFFFF0D3);
  static const Color _professionCardBorder = Color(0xFFF2DCFF);
  // Shadow #00122314 -> ARGB (alpha 0x14 = 8%, RGB 0x001223).
  static const Color _featureCardShadow = Color(0x14001223);

  /// The hero's shape - the ratio the intro clip and
  /// [AppImageAssets.completeProfileBanner] are both authored for, so the
  /// artwork is never letterboxed and the clip crops exactly the way it does
  /// in the Discover header.
  static const double _heroAspect = 1.91;

  // -- Is the clip actually in front of the user? --------------------------
  //
  // Neither of these unmounts this screen, so without them the player keeps
  // decoding - and keeps talking once it has been unmuted - behind whatever
  // the user moved on to.

  /// Another route is covering this screen (the sign-up flow, a sheet).
  bool _routeCovered = false;

  /// The app is backgrounded.
  bool _appForeground = true;

  bool get _videoAlive => !_routeCovered && _appForeground;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // This screen is guests only, which is exactly who the clip is for. The
    // controller no-ops on every call after the first, so sharing it with the
    // Discover banner costs at most one request per app run.
    getOrPut(() => DiscoveryVideoController()).ensureLoaded();
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

  /// A route was pushed ON TOP of this screen.
  @override
  void didPushNext() => _setRouteCovered(true);

  /// That route popped and this screen is frontmost again.
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
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: false,
        appBarColor: AppColors.white,
        isShadowShow: false,
        isGuestLogout: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => createProfileScreen(),
          // Fits when it can, scrolls when it can't — decided by the layout
          // itself, not by a screen-size threshold that would need revisiting
          // every time a translation runs long or the system text scale moves.
          //
          // `minHeight` is the viewport minus this padding, so on a normal
          // phone the column is TALLER than its content: the slack is real,
          // `center` splits it above and below the block, and the scroll view
          // has nothing to scroll. On a short screen (or with large text) the
          // content outgrows that floor, the column takes its natural height,
          // and the same scroll view starts scrolling. Nothing is crushed
          // either way.
          //
          // `center`, not `spaceBetween`: any error in the height arithmetic is
          // then split evenly top and bottom instead of landing entirely on the
          // LAST child — which is how the Create Account button kept ending up
          // behind the nav bar, laid out past the viewport's bottom where a
          // scroll view will happily put it without complaining.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size12,
                SizeConfig.size16,
                // The bottom nav is a Stack sibling painted OVER this screen
                // (`bottom_navigation_bar_screen` puts the tab content in a
                // `Positioned.fill` and the bar on top), so the foot of the
                // screen is behind it. [kFloatingBottomNavExtent] is the bar's
                // own published extent — its height plus its bottom inset —
                // rather than a number of mine that can drift from it.
                kFloatingBottomNavExtent + SizeConfig.size12,
              );
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - padding.vertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Natural height, always. It used to be `Flexible` so it
                      // could shrink on a short screen; scrolling is the
                      // answer there instead, and a clip squeezed to a strip
                      // was never much of one.
                      _hero(),
                      SizedBox(height: SizeConfig.size12),
                      _title(),
                      SizedBox(height: SizeConfig.size8),
                      Center(child: _statusPill()),
                      SizedBox(height: SizeConfig.size16),
                      _featureCard(
                        bgColor: _earnCardBg,
                        borderColor: _earnCardBorder,
                        iconBg: AppColors.white,
                        iconAsset: AppImageAssets.loanSector,
                        title: AppStrings.earnWithBlueEra.tr,
                        subtitle: AppStrings.earnWithBlueEraDesc.tr,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _featureCard(
                        bgColor: _businessCardBg,
                        borderColor: _businessCardBorder,
                        iconBg: AppColors.white,
                        iconAsset: AppImageAssets.listCardBoard,
                        title: AppStrings.listYourBusiness.tr,
                        subtitle: AppStrings.listYourBusinessDesc.tr,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _featureCard(
                        bgColor: _professionCardBg,
                        borderColor: _professionCardBorder,
                        iconBg: AppColors.white,
                        iconAsset: AppImageAssets.professionalDiscover,
                        title: AppStrings.listYourProfession.tr,
                        subtitle: AppStrings.listYourProfessionDesc.tr,
                      ),
                      SizedBox(height: SizeConfig.size16),
                      _ctaBar(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The intro clip, and nothing else.
  ///
  /// The static scratch-card hero and the "Scratch & Earn Bonus" heading that
  /// belonged to it are gone: the clip makes that pitch itself, and the page
  /// has to fit on one screen.
  ///
  /// Until the URL arrives - and if it never does, or the clip fails to load -
  /// the slot holds [AppImageAssets.completeProfileBanner], so it is never
  /// blank, black, or a hole the layout has to reserve.
  Widget _hero() {
    final videoUrl = getOrPut(() => DiscoveryVideoController()).videoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(SizeConfig.size12),
      child: AspectRatio(
        aspectRatio: _heroAspect,
        child: Obx(() {
          final url = videoUrl.value;
          if (url == null) return _heroFallback();
          return DiscoverVideoSlide(
            key: ValueKey(url),
            url: url,
            fallback: _heroFallback(),
            // Torn down whenever this screen is not in front of the user, and
            // rebuilt when it is again - see [_videoAlive].
            alive: _videoAlive,
            // Nothing else on this screen competes for sound, so the clip
            // always owns it. A tap is still what unmutes it.
            hasFocus: true,
          );
        }),
      ),
    );
  }

  /// What fills the hero whenever the clip itself cannot: while it buffers,
  /// after it fails, and while it is torn down off-screen.
  ///
  /// Two layers, in the order they can actually appear. The clip's own first
  /// frame when the backend sends one — it beats the player to the screen, so
  /// the slot shows THIS clip rather than generic artwork, and there is no jump
  /// when playback starts. Then the bundled banner, which needs no network and
  /// is therefore the only thing that can be trusted to render when the reason
  /// the clip failed was the network.
  Widget _heroFallback() {
    final thumb = getOrPut(() => DiscoveryVideoController()).thumbnailUrl.value;
    if (thumb == null) return _bundledHero();
    return CachedNetworkImage(
      imageUrl: thumb,
      fit: BoxFit.cover,
      placeholder: (_, __) => _bundledHero(),
      errorWidget: (_, __, ___) => _bundledHero(),
    );
  }

  Widget _bundledHero() => LocalAssets(
        imagePath: AppImageAssets.completeProfileBanner,
        boxFix: BoxFit.cover,
      );

  Widget _title() {
    return CustomText(
      AppStrings.completeProfile.tr,
      fontSize: SizeConfig.size22,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w600,
      textAlign: TextAlign.center,
    );
  }

  Widget _statusPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 16,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            AppStrings.browsingAsGuest.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _ctaBar() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => createProfileScreen(),
        child: Container(
          height: SizeConfig.size50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                AppStrings.createAccount.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              SizedBox(width: SizeConfig.size10),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required String iconAsset,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: _featureCardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: SizeConfig.size40,
            height: SizeConfig.size40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            padding: EdgeInsets.all(SizeConfig.size8),
            child: LocalAssets(
              imagePath: iconAsset,
              boxFix: BoxFit.contain,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: 4),
                CustomText(
                  subtitle,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                  // Bounded so a long translation cannot push the page past
                  // the single screen it is built to fit in.
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
