import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_product_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_dashboard_header.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_website_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EarnServiceDashboardView extends StatefulWidget {
  /// Which earn flavour's home page to render. When null, falls back to the
  /// first profile the user has created (`earnProfileType`).
  final String? earnType;

  const EarnServiceDashboardView({
    super.key,
    this.earnType,
  });

  @override
  State<EarnServiceDashboardView> createState() =>
      _EarnServiceDashboardViewState();
}

class _EarnServiceDashboardViewState extends State<EarnServiceDashboardView> {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();
  final _earnProfileCtrl = getOrPut(() => EarnProfileController());

  /// The flavour this dashboard renders: the explicitly-passed [earnType],
  /// else the first earn profile the user has created.
  String? get _activeEarnType {
    final types = _viewCtrl.earnProfileType;
    // Touch `length` so the surrounding Obx always registers a dependency,
    // even when an explicit earnType is supplied (avoids "improper use of GetX").
    final count = types.length;
    if (widget.earnType != null) return widget.earnType;
    return count == 0 ? null : types.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _earnProfileCtrl.fetchEarnProfile(activeType: widget.earnType);
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() ==
              AppConstants.OPEN.toUpperCase();
    });
  }

  // Tabs were removed — this dashboard now shows only the home content.
  // The per-type statistics live in the self-employee profile's Statics tab.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              _buildPatternBackground(),
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: kBottomNavigationBarHeight + 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildHomeContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BACKGROUND
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // Back button overlaid on the cover image, sitting in the status-bar
  // region — mirrors the consumer store-details hero.
  Widget _buildHeroBackOverlay() {
    final topInset = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topInset + 8, left: 12, right: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 0.6),
            ),
            child: LocalAssets(
              imagePath: AppIconAssets.back_arrow,
              width: 18,
              height: 18,
              imgColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Home content — dashboard header (cover/profile) + the matching earn-
  // profile page + website card when one is linked.
  List<Widget> _buildHomeContent() {
    return [
      Obx(() {
        final earnType = _activeEarnType;
        final website = _earnProfileCtrl.earnProfile.value?.website ?? '';
        final hasWebsite = website.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EarnServiceDashboardHeader(
              controller: _earnProfileCtrl,
              headerOverlay: _buildHeroBackOverlay(),
            ),
            _earnHomeBody(earnType),
            if (hasWebsite)
              EarnServiceWebsiteCard(
                controller: _earnProfileCtrl,
                webViewHeight: MediaQuery.of(context).size.height * 0.7,
              ),
          ],
        );
      }),
    ];
  }

  Widget _earnHomeBody(String? earnType) {
    switch (earnType) {
      case 'homeMadeFood':
        return const HomeMadeFoodHomePage();
      case 'homeMadeProduct':
        return const HomeMadeProductHomePage();
      case 'homeService':
        return const HomeServiceHomePage();
      default:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
          child: Center(
            child: CustomText(
              AppStrings.comingSoon,
              fontSize: SizeConfig.large,
              color: AppColors.secondaryTextColor,
            ),
          ),
        );
    }
  }
}
