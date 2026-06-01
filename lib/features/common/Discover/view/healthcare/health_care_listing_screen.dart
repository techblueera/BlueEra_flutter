import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/hospital_list_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
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
  int _locationVersion = 0;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/doctor-with-his-patient_1098-603.jpg?w=1380",
    "https://img.freepik.com/free-photo/front-view-covid-recovery-center-young-patient-with-medical-mask_23-2148856202.jpg?w=1380",
    "https://img.freepik.com/free-photo/team-young-specialist-doctors-standing-corridor-hospital_1303-21202.jpg?w=1380",
  ];

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = healthCareList;
    controller.selectedProfessionalConsultantData.value =
        widget.selectedProfessionConsultantData;
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
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor:
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                    bottomBorderSide: const BorderSide(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    singleLineLabel: true,
                    categories: _professionalConsultantCategories.map((c) => StickyCategory(
                      id: c.slugId,
                      name: c.name,
                      imageUrl: c.icon,
                    )).toList(),
                    selectedId: controller.selectedProfessionalConsultantData.value?.slugId,
                    onCategoryTap: (item) {
                      final cat = _professionalConsultantCategories.firstWhere((c) => c.slugId == item.id);
                      controller.selectedTabIndex.value = _professionalConsultantCategories.indexOf(cat);
                      controller.selectedProfessionalConsultantData.value = cat;
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ],
              body: rightContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget rightContent() {
    return Obx(() {
      final v = _locationVersion;
      final slug = controller.selectedProfessionalConsultantData.value?.slugId;
      if (slug == PHARMACY) {
        return NearestPharmaciesListScreen(
          key: ValueKey('pharmacy_$v'),
          category: "PHARMACY",
          // category: "INSTRUMENTS_PHARMACY",
        );
      } else if (slug == LABTEST) {
        return LabProfilesListScreen(
          key: ValueKey('lab_$v'),
          category: "LABTEST",
        );
      } else if (slug == HOSPITAL) {
        return HospitalListScreen(
          serviceType: 'HOSPITAL',
          // serviceType: 'HOSPITAL_SECTOR',
          // serviceType: 'hospital',
          key: ValueKey('hospital_$v'),
        );
      } else if (slug == CLINIC_DOCTORS) {
        return HospitalListScreen(
          serviceType: 'CLINIC_DOCTORS',
          // serviceType: 'clinic',
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
                        AppStrings.serviceDescription.tr,
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
                        AppStrings.workExperience.tr,
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
                              "${service.about?.totalExperience?.years ?? 0} ${AppStrings.yearShort.tr}",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            )
                          : CustomText(
                              AppStrings.noExperienceLabel.tr,
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
                        AppStrings.portfolioLabel.tr,
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
                              AppStrings.noDataLabel.tr,
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
                        AppStrings.gallery.tr,
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
                              AppStrings.noPhotosAvailableMsg.tr,
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
                  title: AppStrings.requestBooking.tr,
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
          Expanded(
            child: CustomText(
              AppStrings.allVariants.tr,
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
