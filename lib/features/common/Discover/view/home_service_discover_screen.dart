import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/home_service_discover_details_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/earn_profile_store_list.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Home service providers near me — a flat list of nearby earn-profiles from
/// `earn-service/earn-profiles?profileType=homeService`. Mirrors the home made
/// food store screen.
class HomeServiceDiscoverScreen extends StatefulWidget {
  const HomeServiceDiscoverScreen({super.key});

  @override
  State<HomeServiceDiscoverScreen> createState() => _HomeServiceDiscoverScreenState();
}

class _HomeServiceDiscoverScreenState extends State<HomeServiceDiscoverScreen> {
  static const String _profileType = 'homeService';
  static const Color _primary = AppColors.primaryColor;

  final controller = getOrPut(
    () => EarnProfilesDiscoverController(profileType: _profileType),
    tag: _profileType,
  );

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/young-handyman-installing-kitchen-cabinet_155003-37938.jpg?w=1380",
    "https://img.freepik.com/free-photo/medium-shot-woman-cleaning-home_23-2150454566.jpg?w=1380",
    "https://img.freepik.com/free-photo/plumber-man-fixing-kitchen-sink_53876-27.jpg?w=1380",
  ];

  @override
  void dispose() {
    deleteIfRegistered<EarnProfilesDiscoverController>(tag: _profileType);
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.onScrollEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        body: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.blue5CAF.withValues(alpha: 0.1),
                      AppColors.blue5CAF.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    BannerCarousel(
                      images: _bannerImages,
                      onBack: () => Navigator.of(context).pop(),
                      statusBarHeight: statusBarHeight,
                      backgroundColor: Colors.transparent,
                      bottomBorderSide: const BorderSide(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                    if (isIndividualUser()) _buildPostCta(),
                    SizedBox(height: SizeConfig.size12),
                  ],
                ),
              ),
            ),
          ],
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(),
        Expanded(
          child: EarnProfileStoreList(
            controller: controller,
            footerLabel: 'View Services',
            emptyMessage: 'No home service providers found nearby.',
            onStoreTap: (store) =>
                Get.to(() => HomeServiceDiscoverDetailsScreen(store: store)),
          ),
        ),
      ],
    );
  }

  // ── Post CTA (individual users only) ──────────────────────────────────────
  Widget _buildPostCta() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size14,
        SizeConfig.size12,
        SizeConfig.size4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onPostTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greyE5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_repair_service_rounded,
                        color: _primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'Add Your Own Home Service',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          'Offer your services & reach nearby customers',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary.withValues(alpha: 0.10),
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppColors.secondaryTextColor, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPostTap() {
    if (isGuestUser() || isBusinessUser()) return;
    final viewProfileController =
        Get.isRegistered<ViewPersonalDetailsController>()
            ? Get.find<ViewPersonalDetailsController>()
            : getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    if (viewProfileController.earnProfileType.contains('homeService')) {
      Get.to(() => const EarnServiceDashboardView(earnType: 'homeService'));
    } else {
      Get.to(() => const HomeServiceProfileScreen());
    }
  }

  // ── List header ──────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size16,
        SizeConfig.size14,
        SizeConfig.size8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomText(
            'Home Service Providers Near You',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: 0.2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
