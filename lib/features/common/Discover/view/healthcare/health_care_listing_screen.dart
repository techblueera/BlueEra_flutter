import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/hospital_list_screen.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_profiles_list_screen.dart';
import 'package:BlueEra/features/me/medical/view/nearest_pharmacies_list_screen.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HealthCareListingScreen extends StatefulWidget {
  final OnboardingCategoryModel? selectedProfessionConsultantData;

  const HealthCareListingScreen(
      {super.key, this.selectedProfessionConsultantData});

  @override
  State<HealthCareListingScreen> createState() =>
      _HealthCareListingScreenState();
}

class _HealthCareListingScreenState extends State<HealthCareListingScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<OnboardingCategoryModel> _professionalConsultantCategories;
  ScrollController scrollController = ScrollController();
  int _locationVersion = 0;
  bool _isLocationLoading = false;

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = healthCareList;
    controller.selectedProfessionalConsultantData.value =
        widget.selectedProfessionConsultantData;

    // Listener for Pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {}
    });
  }

  int _bannerIndex = 0;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/doctor-with-his-patient_1098-603.jpg?w=1380",
    "https://img.freepik.com/free-photo/front-view-covid-recovery-center-young-patient-with-medical-mask_23-2148856202.jpg?w=1380",
    "https://img.freepik.com/free-photo/team-young-specialist-doctors-standing-corridor-hospital_1303-21202.jpg?w=1380",
  ];

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
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _headerBanner(statusBarHeight)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                child: _topCategorySlider(),
                onBack: () => Navigator.pop(context),
              ),
            ),
          ],
          body: rightContent(),
        ),
      ),
    );
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
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
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
                  placeholder: (_, __) =>
                      Container(color: AppColors.greyE5),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.greyE5),
                );
              },
            ),
          ),

          /// Gradient scrim for readability of top & bottom overlays.
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

          /// Top row: back + location selector
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

          /// Dot indicator
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
                    margin: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size3),
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

          /// Search bar overlapping bottom of banner
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
              _isLocationLoading
                  ? SizedBox(
                      width: SizeConfig.size14,
                      height: SizeConfig.size14,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Icon(Icons.keyboard_arrow_down,
                      color: AppColors.white, size: SizeConfig.size18),
            ],
          ),
        ),
      );
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
    if (changed) {
      // Bump version so inner list screens rebuild and refetch with new coords.
      setState(() => _locationVersion++);
    }
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      child: Obx(() {
        final selectedSlug =
            controller.selectedProfessionalConsultantData.value?.slugId;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_professionalConsultantCategories.length,
                (index) {
              final item = _professionalConsultantCategories[index];
              final isActive = selectedSlug == item.slugId;
              return Padding(
                padding: EdgeInsets.only(right: SizeConfig.size10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller.selectedTabIndex.value = index;
                    controller.selectedProfessionalConsultantData.value = item;
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

  Widget rightContent() {
    return Obx(() {
      final v = _locationVersion;
      final slug = controller.selectedProfessionalConsultantData.value?.slugId;
      if (slug == PHARMACY) {
        return NearestPharmaciesListScreen(
          key: ValueKey('pharmacy_$v'),
          category: INSTRUMENTS_PHARMACY,
        );
      } else if (slug == LABTEST) {
        return LabProfilesListScreen(key: ValueKey('lab_$v'));
      } else if (slug == HOSPITAL) {
        return HospitalListScreen(
          serviceType: 'hospital',
          key: ValueKey('hospital_$v'),
        );
      } else if (slug == CLINIC_DOCTORS) {
        return HospitalListScreen(
          serviceType: 'clinic',
          key: ValueKey('clinic_$v'),
        );
      } else if (slug == ALTERNATIVE_WELLNESS) {
        return HospitalListScreen(
          serviceType: 'wellness',
          key: ValueKey('wellness_$v'),
        );
      } else {
        return ComingSoon();
      }
    });
  }

  Widget selfProfessionCard(ProfessionalConsData service) {
    // Price
    final priceData = service.pricing?.amount;
    final isRange = service.pricing?.type == 'range';

    String priceDisplay;
    if (isRange) {
      final min = priceData ?? 0;
      final max = priceData ?? 0;
      priceDisplay = "₹${formatIndianNumber(min)}-${formatIndianNumber(max)}";
    } else {
      priceDisplay = "₹${formatIndianNumber(priceData ?? 0)}";
    }

    Color badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
    String badgeText = service.pricing?.type.toString().capitalizeFirst ?? '';

    return InkWell(
      // onTap: null,
      onTap: () => showFullProfessionDetails(
        service,
        // timingMap: timingMap,
        priceDisplay: priceDisplay,
        priceBadgeText: badgeText,
        priceBadgeColor: badgeColor,
      ),
      child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      // Navigate to details
                    },
                    child: CachedAvatarWidget(
                      imageUrl: service.basicDetails?.profilePhotoUrl ?? '',
                      size: SizeConfig.size40,
                      borderColor: Colors.white,
                      borderRadius: SizeConfig.size20,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.basicDetails?.fullName ?? 'User',
                          // fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      // SizedBox(height: SizeConfig.size6),
                      CustomText(
                        service.basicDetails?.shortTagline ?? 'User',
                        fontSize: SizeConfig.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.mainTextColor,
                      ),
                      // CommonRatingRow(
                      //   rating: double.tryParse(service.rating.toString()) ?? 0.0,
                      //   reviews: service.reviewCount ?? 0,
                      //   distance: '${service.distance ?? 0} KM',
                      // )
                    ],
                  )),
                  // Icon(Icons.more_vert, color: AppColors.black)
                ],
              ),
              SizedBox(height: SizeConfig.size6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    CustomText(
                      "${service.pricing?.consultationMode}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.green00,
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    priceDisplay,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: badgeColor,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size4,
                      vertical: SizeConfig.size2,
                    ),
                    child: CustomText(
                      badgeText,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  )
                ],
              ),
            ],
          )),
    );
  }

  void showFullProfessionDetails(
    ProfessionalConsData service, {
    // required Map<String, String> timingMap,
    required String priceDisplay,
    required String priceBadgeText,
    required Color priceBadgeColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: kToolbarHeight,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),

                _header(context),

                const SizedBox(height: 4),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigate to details
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10.0)),
                              child: CachedNetworkImage(
                                imageUrl:
                                    service.basicDetails?.profilePhotoUrl ?? '',
                                width: SizeConfig.screenWidth,
                                height: SizeConfig.size150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.size150,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: SizeConfig.size150 / 2),
                              ),
                            ),
                            Positioned(
                                left: 20,
                                bottom: -(SizeConfig.size34),
                                child: Container(
                                  padding: EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle),
                                  child: CachedAvatarWidget(
                                    imageUrl:
                                        service.basicDetails?.profilePhotoUrl ??
                                            '',
                                    size: SizeConfig.size65,
                                    borderColor: Colors.white,
                                    borderRadius: SizeConfig.size40,
                                  ),
                                ))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size60,
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomText(
                                  service.basicDetails?.fullName ?? ' User',
                                  fontSize: SizeConfig.large,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              width: SizeConfig.size8,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size3,
                                horizontal: SizeConfig.size10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                    color: AppColors.secondaryTextColor,
                                    width: 0.5),
                              ),
                              child: CustomText(
                                  service.basicDetails?.professionalTitle,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: ExpandableText(
                          text: "${service.basicDetails?.shortTagline ?? ''}",
                          trimLines: 3,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.mainTextColor,
                            fontFamily: AppConstants.OpenSans,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Price
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        '${AppStrings.price.tr}: ',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        priceDisplay,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: priceBadgeColor,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size4,
                          vertical: SizeConfig.size2,
                        ),
                        child: CustomText(
                          priceBadgeText,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      )
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Service Description
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Service Description',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.certificates != null &&
                              (service.certificates?.isNotEmpty ?? false))
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  SizedBox(height: SizeConfig.size6),
                                  ...List.generate(
                                    service.certificates?.take(2).length ?? 0,
                                    (index) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(
                                                top: 6.0, right: 8.0),
                                            width: 4.0,
                                            height: 4.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.secondaryTextColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomText(
                                              service
                                                  .certificates?[index].title,
                                              fontSize: SizeConfig.small,
                                              color:
                                                  AppColors.secondaryTextColor,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size6),
                                ])
                          : SizedBox(),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Work Experience
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Work Experience',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.about?.totalExperience?.years != null &&
                              service.about?.totalExperience?.years != 0)
                          ? CustomText(
                              "${service.about?.totalExperience?.years ?? 0} Yr",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            )
                          : CustomText(
                              'No Experience',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Expertise
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Portfolio',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.portfolio != null &&
                              service.portfolio!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                service.portfolio!.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(
                                                top: 6.0, right: 8.0),
                                            width: 4.0,
                                            height: 4.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.secondaryTextColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomText(
                                              service.portfolio?[index]
                                                  .projectTitle,
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mainTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      CustomText(
                                        service.portfolio?[index].description,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CustomText(
                              'No Data',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Gallery
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Gallery',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.gallery != null &&
                              service.gallery?.signedUrls != null &&
                              (service.gallery?.signedUrls?.isNotEmpty ??
                                  false))
                          ? Builder(builder: (context) {
                              // Split into rows of 4
                              final rows = <String>[];
                              rows.addAll(service.gallery?.signedUrls ?? []);
                              return Wrap(
                                children: List.generate(rows.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10.0)),
                                      child: CachedNetworkImage(
                                        imageUrl: rows[index],
                                        width: SizeConfig.size80,
                                        height: SizeConfig.size80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          width: SizeConfig.size80,
                                          height: SizeConfig.size80,
                                          color: Colors.grey[300],
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.person,
                                                size: SizeConfig.size80 / 2),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            })
                          : CustomText(
                              'No Photos Available',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingL),

                CustomBtn(
                  onTap: () {},
                  isValidate: true,
                  radius: SizeConfig.size10,
                  title: 'Request Booking',
                  // isLoading: authController.isAddBusinessUserLoading.value
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 50,
          height: 5,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          const Expanded(
            child: CustomText(
              "All Variants",
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      );
}

/// Keeps the category slider pinned at the top while scrolling.
/// When content starts overlapping (banner has scrolled away), the header
/// adds a back button so the user can still navigate back.
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final Widget child;
  final VoidCallback onBack;

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
