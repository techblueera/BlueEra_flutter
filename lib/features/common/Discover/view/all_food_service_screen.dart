import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:get/get.dart';
import '../../../../core/api/model/new_food_home_res_model.dart';

class AllFoodServiceScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> professionalConsultantCategories;
  final OnboardingCategoryModel? selectedProfessionConsultantData;

  const AllFoodServiceScreen(
      {super.key,
      required this.professionalConsultantCategories,
      this.selectedProfessionConsultantData});

  @override
  State<AllFoodServiceScreen> createState() =>
      _AllFoodServiceScreenState();
}

class _AllFoodServiceScreenState extends State<AllFoodServiceScreen> {
  final controller_ = getOrPut(() => DiscoverController());
  late List<OnboardingCategoryModel> _professionalConsultantCategories;
  ScrollController scrollController = ScrollController();

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    controller_.selectedFoodServiceData.value =
        widget.selectedProfessionConsultantData;
    controller_.fetchFoodRestaurantService();

    // Listener for Pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller_.fetchFoodRestaurantService(isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(buildCustomActionWidget: () => const DiscoverCartIcon()),
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

    final fullList = [..._professionalConsultantCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        if (item.slugId == 'ALL_OPTION') {
          return controller_.selectedFoodServiceData.value == null;
        }
        return controller_.selectedFoodServiceData.value?.slugId ==
            item.slugId;
      },
      onTap: (item, index) {
        controller_.selectedTabIndex.value = index;

        if (item.slugId == 'ALL_OPTION') {
          controller_.selectedFoodServiceData.value = null;
        } else {
          controller_.selectedFoodServiceData.value = item;
        }
        // Single API Call (Clean & Shared)
        controller_.fetchFoodRestaurantService();
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
              if (controller_.isFoodRestaurantLoading.value &&
                  controller_.foodRestaurantDataList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller_.foodRestaurantDataList.isEmpty) {
                return Center(
                    child: EmptyStateWidget(message: "No services found"));
              }

              final rows = buildNativeAdRows(
                  controller_.foodRestaurantDataList.length);
              final showMoreLoader =
                  controller_.isEducationServiceLoadingMore.value;

              return ListView.builder(
                  controller: scrollController,
                  itemCount: rows.length + (showMoreLoader ? 1 : 0),
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final row = rows[index];
                    if (row.isAd) {
                      return NativeAdSlot(
                        adOrdinal: row.adOrdinal,
                        keyPrefix: 'food_service_native_ad',
                      );
                    }

                    var service = controller_
                        .foodRestaurantDataList[row.contentIndex];

                    return selfProfessionCard(service);
                  });
            }),
          )
        ],
      ),
    );
  }

  Widget selfProfessionCard(FoodData service) {
    return InkWell(
      onTap: () {
        if (service.businessProfile?.id == null) return;
        Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: service.businessProfile!.id!));
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
                    imageUrl: service.businessProfile?.logo ?? '',
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
                      CustomText( service.businessProfile?.businessName ?? 'N/A',
                          // fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      // SizedBox(height: SizeConfig.size6),
                      CustomText(
                        service.businessProfile?.typeOfBusiness ?? 'N/A',
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
                      (service.businessProfile?.address?.isNotEmpty??false)?(service.businessProfile?.address??"N/A"):"N/A",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

            ],
          )),
    );
  }


}
