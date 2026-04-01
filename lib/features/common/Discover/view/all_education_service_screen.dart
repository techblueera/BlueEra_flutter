import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
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

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    controller_.selectedEducationServiceData.value =
        widget.selectedProfessionConsultantData;
    controller_.fetchEducationServiceServices();

    // Listener for Pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller_.fetchEducationServiceServices(isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.paddingM,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size10,
                  horizontal: SizeConfig.size10,
                ),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 1.2),
                    boxShadow: [AppShadows.textFieldShadow]),
                child: Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.franchiseIcon,
                      height: SizeConfig.size30,
                      width: SizeConfig.size30,
                    ),
                    SizedBox(width: SizeConfig.size10),
                    CustomText(AppStrings.bookViaBlueEraPartner,
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: SizeConfig.paddingXSL,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftCategoryList(),
                  SizedBox(
                    width: SizeConfig.size6,
                  ),
                  Expanded(child: rightContent()),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    final allItem = OnboardingCategoryModel(
      name: 'All',
      slugId: 'ALL_OPTION',
      icon: AppImageAssets.all,
      individualType: IndividualProfileType.PROFESSIONAL,
      accountType: AppConstants.individual,
    );

    final fullList = [allItem, ..._professionalConsultantCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        if (item.slugId == 'ALL_OPTION') {
          return controller_.selectedEducationServiceData.value == null;
        }
        return controller_.selectedEducationServiceData.value?.slugId ==
            item.slugId;
      },
      onTap: (item, index) {
        controller_.selectedTabIndex.value = index;

        if (item.slugId == 'ALL_OPTION') {
          controller_.selectedEducationServiceData.value = null;
        } else {
          controller_.selectedEducationServiceData.value = item;
        }
        // Single API Call (Clean & Shared)
        controller_.fetchEducationServiceServices();
      },
    );
  }

  Widget rightContent() {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Expanded(
            child: Obx(() {
              if (controller_.isEducationServiceLoading.value &&
                  controller_.schoolDetailsDataDataList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller_.schoolDetailsDataDataList.isEmpty) {
                return Center(
                    child: EmptyStateWidget(message: "No services found"));
              }

              return ListView.builder(
                  controller: scrollController,
                  itemCount: controller_.schoolDetailsDataDataList.length +
                      (controller_.isEducationServiceLoadingMore.value
                          ? 1
                          : 0),
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                  itemBuilder: (context, index) {
                    if (index ==
                        controller_.schoolDetailsDataDataList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    var service =
                    controller_.schoolDetailsDataDataList[index];

                    return selfProfessionCard(service);
                  });
            }),
          )
        ],
      ),
    );
  }

  Widget selfProfessionCard(SchoolDetailsData service) {
    return InkWell(
      onTap: () {
        final schoolAboutUsController = getOrPut(() => SchoolAboutUsController());

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
                  CachedAvatarWidget(
                    imageUrl: service.logo ?? '',
                    size: SizeConfig.size40,
                    borderColor: Colors.white,
                    borderRadius: SizeConfig.size20,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.name ?? 'User',
                          // fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      // SizedBox(height: SizeConfig.size6),
                      CustomText(
                        service.type ?? 'User',
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
              SizedBox(height: SizeConfig.size8),
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
                  child: Row(
                    children: [
                      CustomText(
                        "Since ${service.establishmentYear ?? ""}",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.green00,
                      ),
                    ],
                  ),
                ),
              ]
            ],
          )),
    );
  }


}
