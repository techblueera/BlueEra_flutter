import 'dart:ui';

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
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  primary: false,
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: topBarHeight,
                  flexibleSpace: _buildTopBar(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: SizeConfig.size10,
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

  // TOP BAR — glassmorphic strip: [back arrow] [earn-type title]. The title
  // mirrors the active home body so users always know which earn flavour
  // (Food / Product / Service) they're on. Reactive on [earnProfileType].
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              topInset + SizeConfig.size8,
              SizeConfig.size12,
              SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: Row(
              children: [
                _circleIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Obx(() {
                    final title = _earnTypeTitle(_activeEarnType);
                    return CustomText(
                      title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Maps the controller's [earnProfileType] code to the title shown in the
  /// top bar. Kept here so the same mapping can be reused if other surfaces
  /// need the human label.
  String _earnTypeTitle(String? earnType) {
    switch (earnType) {
      case 'homeMadeFood':
        return 'Home Made Food';
      case 'homeMadeProduct':
        return 'Home Made Product';
      case 'homeService':
        return 'Home Service';
      default:
        return '';
    }
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
                height: SizeConfig.size36,
                width: SizeConfig.size36,
                padding: EdgeInsets.all(SizeConfig.size10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFC9CDD5),
                    width: 1,
                  ),
                ),
                child: LocalAssets(
                  imagePath: AppIconAssets.back_arrow,
                  height: SizeConfig.size26,
                  width: SizeConfig.size26,
                  imgColor: AppColors.mainTextColor,
                )),
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
              headerOverlay: const SizedBox.shrink(),
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
