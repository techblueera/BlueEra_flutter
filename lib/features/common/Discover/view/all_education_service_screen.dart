import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';

class AllEducationServiceScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> professionalConsultantCategories;
  final OnboardingCategoryModel? selectedProfessionConsultantData;

  const AllEducationServiceScreen(
      {super.key,
      required this.professionalConsultantCategories,
      this.selectedProfessionConsultantData});

  @override
  State<AllEducationServiceScreen> createState() =>
      _AllEducationServiceScreenState();
}

class _AllEducationServiceScreenState extends State<AllEducationServiceScreen> {
  final controller_ = getOrPut(() => DiscoverController());
  late List<OnboardingCategoryModel> _professionalConsultantCategories;
  ScrollController scrollController = ScrollController();
  bool _isLocationLoading = false;

  int _bannerIndex = 0;
  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/happy-students-classroom_23-2149207191.jpg?w=1380",
    "https://img.freepik.com/free-photo/group-college-students-studying-library_329181-15025.jpg?w=1380",
    "https://img.freepik.com/free-photo/group-young-students-with-books-chalkboard_1303-20932.jpg?w=1380",
  ];

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    controller_.selectedEducationServiceData.value =
        widget.selectedProfessionConsultantData;
    controller_.fetchEducationServiceServices();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller_.fetchEducationServiceServices(isLoadMore: true);
      }
    });
  }

  Future<void> _changeLocation() async {
    setState(() => _isLocationLoading = true);
    final prevLat = LocationService.lat;
    final prevLng = LocationService.lng;

    final result =
        await LocationService.fetchLocation(openSettingsOnDeny: true);

    if (!mounted) return;
    setState(() => _isLocationLoading = false);

    if (result == null) return;

    final changed =
        prevLat != LocationService.lat || prevLng != LocationService.lng;
    if (changed) controller_.fetchEducationServiceServices();
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
        body: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _headerBanner(statusBarHeight)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                child: _topCategorySlider(),
                onBack: () => Navigator.pop(context),
              ),
            ),
            _buildListSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver() {
    return Obx(() {
      if (controller_.isEducationServiceLoading.value &&
          controller_.schoolDetailsDataDataList.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller_.schoolDetailsDataDataList.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _NoSchoolsFound(
            title: 'No schools found',
            subtitle:
                'We couldn\'t find any schools or education services in this area. Try another category or change your location.',
            onRetry: () => controller_.fetchEducationServiceServices(),
          ),
        );
      }

      final list = controller_.schoolDetailsDataDataList;
      final showMoreLoader = controller_.isEducationServiceLoadingMore.value;

      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size10,
        ),
        sliver: SliverList.builder(
          itemCount: list.length + (showMoreLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return selfProfessionCard(list[index]);
          },
        ),
      );
    });
  }

  Widget _headerBanner(double statusBarHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth * 9 / 16) + statusBarHeight;

    return SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: CarouselSlider.builder(
              itemCount: _bannerImages.length,
              options: CarouselOptions(
                height: bannerHeight,
                viewportFraction: 1.0,
                autoPlay: _bannerImages.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.easeInOutCubic,
                enableInfiniteScroll: _bannerImages.length > 1,
                onPageChanged: (index, _) =>
                    setState(() => _bannerIndex = index),
              ),
              itemBuilder: (context, index, _) {
                return CachedNetworkImage(
                  imageUrl: _bannerImages[index],
                  width: double.infinity,
                  height: bannerHeight,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.greyE5),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.greyE5),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.35),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                _circleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: _locationPill()),
              ],
            ),
          ),
          if (_bannerImages.length > 1)
            Positioned(
              bottom: SizeConfig.size40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_bannerImages.length, (i) {
                  final active = i == _bannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size3),
                    width: active ? SizeConfig.size16 : SizeConfig.size6,
                    height: SizeConfig.size6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
          Positioned(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            bottom: SizeConfig.size8,
            child: _searchBar(),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white, size: SizeConfig.size20),
        ),
      ),
    );
  }

  Widget _locationPill() {
    return Obx(() {
      final loc = LocationService.userCurrentAddress.value;
      final title =
          [loc.subLocality, loc.city].where((e) => e.isNotEmpty).join(', ');
      return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _isLocationLoading ? null : _changeLocation,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined,
                  color: AppColors.white, size: SizeConfig.size20),
              SizedBox(width: SizeConfig.size6),
              Flexible(
                child: CustomText(
                  title.isEmpty ? 'Select location' : title,
                  fontSize: SizeConfig.medium,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.size4),
              // _isLocationLoading
              //     ? SizedBox(
              //         width: SizeConfig.size14,
              //         height: SizeConfig.size14,
              //         child: const CircularProgressIndicator(
              //           strokeWidth: 2,
              //           valueColor:
              //               AlwaysStoppedAnimation<Color>(AppColors.white),
              //         ),
              //       )
              //     : Icon(Icons.keyboard_arrow_down,
              //         color: AppColors.white, size: SizeConfig.size18),
            ],
          ),
        ),
      );
    });
  }

  Widget _searchBar() {
    return Container(
      height: SizeConfig.size48,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search,
              color: AppColors.secondaryTextColor, size: SizeConfig.size22),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              AppStrings.searchAnything,
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          LocalAssets(
            imagePath: AppIconAssets.mic,
            width: SizeConfig.size20,
            height: SizeConfig.size20,
            imgColor: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size10),
          LocalAssets(imagePath: AppIconAssets.camera_black),
        ],
      ),
    );
  }

  Widget _topCategorySlider() {
    final allItem = OnboardingCategoryModel(
      name: 'All',
      slugId: 'ALL_OPTION',
      icon: AppImageAssets.all,
      individualType: IndividualProfileType.PROFESSIONAL,
      accountType: AppConstants.individual,
    );
    final fullList = [allItem, ..._professionalConsultantCategories];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      child: Obx(() {
        final selected = controller_.selectedEducationServiceData.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(fullList.length, (index) {
              final item = fullList[index];
              final isActive = item.slugId == 'ALL_OPTION'
                  ? selected == null
                  : selected?.slugId == item.slugId;
              return Padding(
                padding: EdgeInsets.only(right: SizeConfig.size10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller_.selectedTabIndex.value = index;
                    controller_.selectedEducationServiceData.value =
                        item.slugId == 'ALL_OPTION' ? null : item;
                    controller_.fetchEducationServiceServices();
                  },
                  child: SizedBox(
                    width: SizeConfig.size70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(SizeConfig.size8),
                          decoration: BoxDecoration(
                            color: isActive ? null : AppColors.white,
                            gradient: isActive
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.white,
                                      Color(0xFFA4D4FF),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primaryColor
                                  : AppColors.greyE5,
                            ),
                          ),
                          child: LocalAssets(
                            imagePath: item.icon ?? '',
                            width: SizeConfig.size30,
                            height: SizeConfig.size30,
                            boxFix: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          item.name,
                          fontSize: SizeConfig.small,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget selfProfessionCard(SchoolDetailsData service) {
    return InkWell(
      onTap: () {
        final schoolAboutUsController =
            getOrPut(() => SchoolAboutUsController());
        schoolAboutUsController.schoolDetailsData?.value = service;
        Get.to(DiscoverSchoolHomeScreen());
      },
      child: CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _schoolLogo(service.logo ?? ''),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        service.name ?? AppStrings.unknownUser.tr,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((service.type ?? '').isNotEmpty)
                        CustomText(
                          service.type!,
                          fontSize: SizeConfig.small,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.secondaryTextColor,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            if ((service.location?.name ?? '').isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalAssets(imagePath: AppIconAssets.location_new),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomText(
                      service.location?.name,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            if (service.establishmentYear != null) ...[
              SizedBox(height: SizeConfig.size6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: CustomText(
                  "${AppStrings.sincePrefix.tr} ${service.establishmentYear ?? ""}",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.green00,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _schoolLogo(String url) {
    if (url.isEmpty) return _brokenSchoolLogo();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: SizeConfig.size40,
          height: SizeConfig.size40,
          color: AppColors.greyE5,
        ),
        errorWidget: (_, __, ___) => _brokenSchoolLogo(),
      ),
    );
  }

  Widget _brokenSchoolLogo() => Container(
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.school_outlined,
          size: SizeConfig.size22,
          color: AppColors.secondaryTextColor,
        ),
      );
}

class _NoSchoolsFound extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _NoSchoolsFound({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 380;
        final illustrationSize = isCompact
            ? SizeConfig.size80
            : (constraints.maxWidth * 0.35)
                .clamp(SizeConfig.size80, SizeConfig.size150);

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size24,
              vertical: SizeConfig.size16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: illustrationSize,
                  height: illustrationSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.12),
                        AppColors.primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.school_outlined,
                    size: illustrationSize * 0.5,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                CustomText(
                  title,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  subtitle,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (onRetry != null) ...[
                  SizedBox(height: SizeConfig.size16),
                  InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              color: AppColors.white,
                              size: SizeConfig.size18),
                          SizedBox(width: SizeConfig.size6),
                          CustomText(
                            'Retry',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Keeps the category slider pinned at the top while scrolling.
/// When content starts overlapping (i.e. the banner has scrolled away),
/// the header adds status-bar padding + a back button so the user can
/// still navigate back without the banner visible.
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final Widget child;
  final VoidCallback onBack;

  // Measured intrinsic height of the category slider content.
  // 2-line label + icon tile + padding ≈ this range; kept consistent
  // across stick/unstuck states so the pin doesn't jump.
  static const double _baseHeight = 110;

  _StickyCategoryHeaderDelegate({
    required this.topPadding,
    required this.child,
    required this.onBack,
  });

  @override
  double get maxExtent => _baseHeight + topPadding;

  @override
  double get minExtent => _baseHeight + topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // The header always reserves full extent (base + statusBar). While the
    // banner is still on-screen, the status-bar strip sits flush below the
    // banner's rounded bottom and reads as a thin gap. Once sticky, the
    // strip accommodates the system status bar and the back button appears.
    final isSticky = overlapsContent;
    final totalHeight = _baseHeight + topPadding;

    return Material(
      color: AppColors.white,
      elevation: isSticky ? 2 : 0,
      child: Container(
        height: totalHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.greyE5, width: 0.5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSticky)
                Padding(
                  padding: EdgeInsets.only(left: SizeConfig.size8),
                  child: IconButton(
                    onPressed: onBack,
                    splashRadius: SizeConfig.size22,
                    icon: Icon(Icons.arrow_back,
                        color: AppColors.mainTextColor,
                        size: SizeConfig.size22),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding ||
      child != oldDelegate.child ||
      onBack != oldDelegate.onBack;
}
