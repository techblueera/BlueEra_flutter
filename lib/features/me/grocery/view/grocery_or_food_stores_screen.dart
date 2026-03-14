import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_enum.dart';

class GroceryOrFoodStoresScreen extends StatefulWidget {
  final OnboardingCategoryModel selectedGroceryOrFoodCategory;
  final bool isGroceryStore;

  const GroceryOrFoodStoresScreen(
      { super.key,
        required this.selectedGroceryOrFoodCategory,
        required this.isGroceryStore,
        });

  @override
  State<GroceryOrFoodStoresScreen> createState() =>
      _GroceryOrFoodStoresScreenState();
}

class _GroceryOrFoodStoresScreenState extends State<GroceryOrFoodStoresScreen> {
  final controller = getOrPut(() => NewStoreController());
  final groceryController = getOrPut(() => GroceryController());
  final foodCustomerListingScreen = getOrPut(() => FoodCustomerController());
  final ScrollController storesScrollController = ScrollController();

  @override
  initState() {
    super.initState();

    if(widget.isGroceryStore){
      controller.typeOfBusiness = BusinessType.Grocery.name;
    }else{
      controller.typeOfBusiness = BusinessType.Food.name;
    }

    controller.selectedGroceryOrFoodCategoryData.value =
        widget.selectedGroceryOrFoodCategory;
    controller.businessCategoryId = controller.selectedGroceryOrFoodCategoryData.value?.slugId;

    controller.getAllStoreNearBy();

    // Listener for Pagination
    controller.addListener(_onLoadMore);
  }

  void _onLoadMore(){
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftCategoryList(),
            SizedBox(
              width: SizeConfig.size6,
            ),
            Expanded(
                child: rightContent()
            ),
          ],
        )
      ),
    );
  }

  Widget leftCategoryList() {
    final allItem = OnboardingCategoryModel(
      name: 'All',
      slugId: 'ALL',
      icon: AppImageAssets.all,
      individualType: IndividualProfileType.SELF_EMPLOYED,
      accountType: AppConstants.individual,
    );

    final fullList = [allItem, ...groceriesCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        if (item.slugId == 'ALL') {
          return controller.selectedGroceryOrFoodCategoryData.value == null;
        }
        return controller.selectedGroceryOrFoodCategoryData.value?.slugId == item.slugId;
      },
      onTap: (item, index) {
        if (item.slugId == 'ALL') {
          controller.selectedGroceryOrFoodCategoryData.value = null;
        } else {
          controller.selectedGroceryOrFoodCategoryData.value = item;
          controller.businessCategoryId = item.slugId;
        }

        // Single API Call (Clean & Shared)
        controller.getAllStoreNearBy();
      },
    );
  }
  
  Widget rightContent() {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
            child: EmptyStateWidget(message: "No store found"));
      }

      return ListView.builder(
          controller: storesScrollController,
          itemCount: controller.allStore.length +
              (controller.isAllStoreLoadingMore.value ? 1 : 0),
          shrinkWrap: true,
          padding: EdgeInsets.only(
              top: SizeConfig.paddingM,
              bottom: SizeConfig.paddingL,
            right: SizeConfig.paddingXS,
          ),
          itemBuilder: (context, index) {
            if (index == controller.allStore.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            var store = controller.allStore[index];

            return groceryStoreCard(store);
          });
    });
  }

  Widget groceryStoreCard(GetAllStoreResModel store) {
    return InkWell(
      onTap: (){
        if(widget.isGroceryStore){
          Get.toNamed(
              RouteHelper.getOtherGroceryStoreScreenRoute(),
              arguments: {
                ApiKeys.userId: store.userId,
                ApiKeys.businessId: store.id,
              }
          );
        } else{
          Get.toNamed(
              RouteHelper.getOtherFoodStoreDetailsScreenRoute(),
              arguments: {
                ApiKeys.businessId: store.id,
              }
          );
        }
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
                  InkWell(
                    onTap: () {
                      // Navigate to details
                    },
                    child: CachedAvatarWidget(
                      imageUrl: store.logo ?? '',
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
                          CustomText(
                              store.businessName ?? 'Unknown Business',
                              fontSize: SizeConfig.small,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w600),
                          SizedBox(height: SizeConfig.size6),
                          CustomText(
                              store.subCategoryOfBusiness?.name ?? AppStrings.na,
                              fontSize: SizeConfig.extraSmall,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          SizedBox(height: SizeConfig.size6),
                          CommonRatingRow(
                            rating: double.tryParse(store.avgRating.toString()) ?? 0.0,
                            reviews: int.tryParse(store.totalRatings.toString()) ?? 0,
                            distance: '${calculateDistanceKm(
                              LocationService.lat,
                              LocationService.lng,
                              store.businessLocation?.lat?.toDouble() ?? 0.0,
                              store.businessLocation?.lon?.toDouble() ?? 0.0,
                            ).toStringAsFixed(2)} Km Away',
                          )
                        ],
                      )),
                ],
              ),

              SizedBox(
                height: SizeConfig.paddingS
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   LocalAssets(
                       imagePath: AppIconAssets.location_outline,
                       imgColor: AppColors.secondaryTextColor,
                   ),
                   SizedBox(width: SizeConfig.size5),
                   Expanded(
                     child: CustomText(
                         store.address ?? AppStrings.na,
                         fontSize: SizeConfig.small,
                         color: AppColors.secondaryTextColor,
                         fontWeight: FontWeight.w400),
                   ),
                 ],
              ),

              SizedBox(
                  height: SizeConfig.paddingXSL
              ),

              FittedBox(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size10
                      ),
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: AppColors.greyE5
                        )
                      ),
                      child: CustomText(
                          '${store.totalCategoryCount} Category',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                        width: SizeConfig.paddingXS
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size20,
                          vertical: SizeConfig.size10
                      ),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: AppColors.greyE5
                          )
                      ),
                      child: CustomText(
                          '${store.totalProductCount} Product',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )


            ],
          )),
    );
  }



}

