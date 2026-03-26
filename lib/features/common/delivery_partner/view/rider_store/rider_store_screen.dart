import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/food/model/food_category_res_model.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../../me/grocery/widget/grocery_data.dart';

class RiderStoreScreen extends StatefulWidget {
  const RiderStoreScreen({super.key});

  @override
  State<RiderStoreScreen> createState() => _RiderStoreScreenState();
}

class _RiderStoreScreenState extends State<RiderStoreScreen> {
  final groceryController = getOrPut(() => GroceryController());
  final foodServiceController = getOrPut(() => FoodServiceController());
  final foodCustomerController = getOrPut(() => FoodCustomerController());


  @override
  void initState() {
    foodCustomerController.clearControllerFields();
    foodServiceController.getFoodNestedCategoryApi();
    groceryController.fetchGroceryNestedCategory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
      ),
      child: CustomScrollView(

        slivers: [

          SliverToBoxAdapter(
            child: CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.paddingXSL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                          AppStrings.groceryNdStationary,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400),

                      SizedBox(width: SizeConfig.paddingXSL),

                      _buildPaymentMode(AppStrings.cashOnDelivery)
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  Obx(() {
                    if (groceryController.fetchNestedGroceryCategoryResponse.value.status ==
                        Status.COMPLETE) {
                      if (groceryController.grocerySuperCategoryList.isNotEmpty) {
                        return MasonryGridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: groceryController.grocerySuperCategoryList.length,
                          shrinkWrap: true,
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = groceryController.grocerySuperCategoryList[index];
                            return CommonServiceCard<GroceryNestedCategoryModel>(
                              service: item,
                              getName: (item) => item.name??'',
                              getIcon: (item) =>  item.image??'',
                              // getIcon: (item) =>  "${AppConstants.baseFoodAssetsPath}${item.key ?? " "}.svg",
                              iconHeight: SizeConfig.size60,
                              boxShadow: [],
                              onTap: (item) {
                                Get.toNamed(
                                  RouteHelper.getGroceryNestedCategoryScreenRoute(),
                                  arguments: {
                                    // ApiKeys.argMyGrocery: false,
                                    ApiKeys.argArrGrocerySuperCategory: groceryController.grocerySuperCategoryList,
                                    ApiKeys.argArrGroceryCatKey: item.key,
                                    ApiKeys.argArrGroceryCatName: item.name,
                                  },
                                );
                              },
                            );

                          },
                        );
                      }
                      else {
                        return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: CustomText(AppStrings.noDataFound),
                            ));
                      }
                    } else if (groceryController.fetchNestedGroceryCategoryResponse.value ==
                        Status.ERROR) {
                      return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: CustomText(AppStrings.somethingWentWrong),
                          ));
                    }
                    return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: CircularProgressIndicator(),
                        ));
                  }),

                  // _buildCategoryGrid(
                  //   items: GroceryData.grocerySuperCategories,
                  //   onTap: (item) {
                  //     // getCategoriesByTag(item.slugId);
                  //     Get.toNamed(
                  //       RouteHelper.getGroceryNestedCategoryScreenRoute(),
                  //       arguments: {
                  //         ApiKeys.argMyGrocery: false,
                  //         ApiKeys.argArrGrocerySuperCategory: GroceryData.grocerySuperCategories,
                  //         ApiKeys.argArrGroceryCatKey: item.slugId,
                  //         ApiKeys.argArrGroceryCatName: item.name,
                  //       },
                  //     );
                  //   },
                  // ),

                ],
              ),
            ),
          ),

          _buildGap(),

          SliverToBoxAdapter(
            child: CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.paddingXSL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                          AppStrings.foodNearMe,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400),

                      SizedBox(width: SizeConfig.paddingXSL),

                      _buildPaymentMode(AppStrings.prePaid)
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  Obx(() {
                    if (foodServiceController.getFoodCategoryResponse.value.status ==
                         Status.COMPLETE) {
                      if (foodServiceController.foodNestedCateList.isNotEmpty) {
                        return MasonryGridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: foodServiceController.foodNestedCateList.length,
                          shrinkWrap: true,
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = foodServiceController.foodNestedCateList[index];
                            return CommonServiceCard<GroceryNestedCategoryModel>(
                              service: item,
                              getName: (item) => item.name??'',
                              getIcon: (item) =>  item.image??'',
                              // getIcon: (item) =>  "${AppConstants.baseFoodAssetsPath}${item.key ?? " "}.svg",
                              iconHeight: SizeConfig.size60,
                              boxShadow: [],
                              onTap: (item) {
                                foodServiceController.selectedFoodTypeID.value =
                                    item.sId ?? "";

                                // Action for item tap
                                Get.toNamed(RouteHelper.getFoodCustomerListingScreenRoute(),
                                    arguments: {
                                      ApiKeys.argCategoryData: item,
                                    });
                              },
                            );

                          },
                        );
                      }
                      else {
                        return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: CustomText(AppStrings.noDataFound),
                            ));
                      }
                    } else if (foodServiceController.getFoodCategoryResponse.value ==
                        Status.ERROR) {
                      return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: CustomText(AppStrings.somethingWentWrong),
                          ));
                    }
                    return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: CircularProgressIndicator(),
                        ));
                  }),

                ],
              ),
            ),
          ),

          // _buildGap(),
          //
          // SliverToBoxAdapter(
          //   child: CustomFormCard(
          //     padding: EdgeInsets.all(SizeConfig.paddingXSL),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //
          //         CustomText(
          //             AppStrings.restaurantNearMe,
          //             fontSize: SizeConfig.medium,
          //             color: AppColors.mainTextColor,
          //             fontWeight: FontWeight.w400),
          //
          //         SizedBox(height: SizeConfig.paddingXSL),
          //
          //         _buildCategoryGrid(
          //           items: restaurantNearMe,
          //           onTap: (item) {
          //
          //           },
          //         ),
          //
          //       ],
          //     ),
          //   ),
          // ),

          _buildGap(gap: SizeConfig.paddingM)
        ],
      ),
    );
  }


  Widget _buildGap({double? gap}){
    return  SliverToBoxAdapter(
      child: SizedBox(height: gap ?? SizeConfig.paddingXSL),
    );
  }

  Widget _buildCategoryGrid({
    required List<CollapsibleGridModel> items,
    required Function(CollapsibleGridModel) onTap,
  }) {
    return MasonryGridView.count(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        var item = items[index];
        return CommonServiceCard<CollapsibleGridModel>(
            service: item,
            getName: (item) => item.name,
            getIcon: (item) => item.icon??'',
            iconHeight: SizeConfig.size60,
            boxShadow: [],
            onTap: (item) => onTap(item),
          );
      },
    );
  }

  Widget _buildPaymentMode(String text){
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6
      ),
      decoration: BoxDecoration(
        color: AppColors.yellowBC.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100.0)
      ),
      child: CustomText(
          text,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.yellowBC,
          fontWeight: FontWeight.w600
      ),
    );
  }

  // Map<String, List<CollapsibleGridModel>> getCategoriesByTag(String tagId) {
  //   switch (tagId) {
  //     case GroceryConstant.GROCERY_ITEMS:
  //       return {
  //         AppStrings.headerRiceRiceProducts: GroceryData.riceProducts,
  //         AppStrings.headerWheatAttaFlours: GroceryData.wheatAndFlours,
  //         AppStrings.headerDalsPulsesBeans: GroceryData.dalNdBeans,
  //         AppStrings.headerMilletsTraditionalGrains: GroceryData.milletsNdTraditionalGrains,
  //         AppStrings.headerBreakfastLightStaples: GroceryData.breakfastStaples,
  //         AppStrings.headerSpicesMasala: GroceryData.spicesAndMasala,
  //         AppStrings.headerSaltSugarSweeteners: GroceryData.saltNdSweeteners,
  //         AppStrings.headerOilsGheeFats: GroceryData.oilsAndFats,
  //         AppStrings.headerTeaCoffeeBeverages: GroceryData.teaCoffeeBeverages,
  //         AppStrings.headerDryFruitsReadyFood: GroceryData.dryFruitsAndReadyFood,
  //       };
  //
  //     case GroceryConstant.VEGETABLES:
  //       return {
  //         AppStrings.headerLeafyVegetables: GroceryData.leafyVegetables,
  //         AppStrings.headerRootVegetables: GroceryData.rootVegetables,
  //         AppStrings.headerBulbStemVegetables: GroceryData.bulbNdStemVegetables,
  //         AppStrings.headerFruitVegetables: GroceryData.fruitVegetables,
  //         AppStrings.headerPodsBeans: GroceryData.podNdBeansVegetables,
  //         AppStrings.headerFlowerVegetables: GroceryData.flowerVegetables,
  //         AppStrings.headerSpecialIndianItems: GroceryData.fungiNdSpecialIndianItems,
  //         AppStrings.headerExoticVegetables: GroceryData.exoticAndSpecialty,
  //       };
  //
  //     case GroceryConstant.FRUITS:
  //       return {
  //         AppStrings.headerDailyFruits: GroceryData.dailyFruits,
  //         AppStrings.headerDesiFruits: GroceryData.desiFruits,
  //         AppStrings.headerSourStoneFruits: GroceryData.sourAndStoneFruits,
  //         AppStrings.headerSmallSeasonalFruits: GroceryData.smallNdSeasonalFruits,
  //         AppStrings.headerForestCoastalFruits: GroceryData.forestNdCoastalFruits,
  //         AppStrings.headerSpecialExoticFruits: GroceryData.specialNdExoticFruits,
  //       };
  //
  //     case GroceryConstant.BAKERY_NAMKEEN_ITEMS:
  //       return {
  //         AppStrings.headerNamkeenMixture: GroceryData.namkeenAndMixture,
  //         AppStrings.headerChipsPapadFryums: GroceryData.chipsPapadFryums,
  //         AppStrings.headerBiscuitsCookies: GroceryData.biscuitsCookies,
  //         AppStrings.headerBakerySweetItems: GroceryData.bakeryItems,
  //         AppStrings.headerFriedHotSnacks: GroceryData.friedHotSnacks,
  //       };
  //
  //     case GroceryConstant.DAIRY_FROZEN_ITEMS:
  //       return {
  //         AppStrings.headerMilk: GroceryData.milkList,
  //         AppStrings.headerCurdCream: GroceryData.curdButtermilkCreamList,
  //         AppStrings.headerButterCheesePaneer: GroceryData.butterCheesePaneerList,
  //         AppStrings.headerGheeDairyFats: GroceryData.gheeAndDairyFatsList,
  //         AppStrings.headerIceCreamFrozen: GroceryData.iceCreamFrozenDessertsList,
  //         AppStrings.headerDairySweetNdChocolate: GroceryData.sweetsChocolatesList,
  //         AppStrings.headerFrozenVegetables: GroceryData.frozenVegetablesList,
  //         AppStrings.headerFrozenSnacks: GroceryData.frozenSnacksMealsList,
  //         AppStrings.headerMilkPowderAlts: GroceryData.milkPowdersAlternativesList,
  //       };
  //
  //     case GroceryConstant.CROCKERY:
  //       return {
  //         AppStrings.headerCookingUtensils: GroceryData.cookingUtensilsList,
  //         AppStrings.headerDiningUtensils: GroceryData.diningUtensilsList,
  //         AppStrings.headerServingUtensils: GroceryData.servingUtensilsList,
  //         AppStrings.headerKitchenHandTools: GroceryData.kitchenToolsList,
  //         AppStrings.headerKitchenAppliances: GroceryData.kitchenAppliancesList,
  //         AppStrings.headerStorageCarry: GroceryData.storageCarryList,
  //         AppStrings.headerGasWaterUtility: GroceryData.utilityItemsList,
  //         AppStrings.headerCleaningSetup: GroceryData.cleaningSetupList,
  //       };
  //
  //     case GroceryConstant.HOME_ESSENTIALS:
  //       return {
  //         AppStrings.headerElectricalSafety: GroceryData.electricalSafetyList,
  //         AppStrings.headerWaterStorage: GroceryData.waterStorageList,
  //         AppStrings.headerHomeUtility: GroceryData.homeUtilityList,
  //         AppStrings.headerPujaItems: GroceryData.pujaItemsList,
  //       };
  //
  //     case GroceryConstant.CLEANING_MAINTENANCE:
  //       return {
  //         AppStrings.headerLaundryCare: GroceryData.laundryCareList,
  //         AppStrings.headerBathroomCare: GroceryData.bathroomCareList,
  //         AppStrings.headerKitchenCare: GroceryData.kitchenCareList,
  //         AppStrings.headerFloorSurface: GroceryData.floorSurfaceList,
  //         AppStrings.headerCleaningTools: GroceryData.cleaningToolsList,
  //         AppStrings.headerPestAirCare: GroceryData.pestAirCareList,
  //         AppStrings.headerSafetyRepair: GroceryData.safetyRepairList,
  //       };
  //
  //     case GroceryConstant.BEAUTY_HEALTH_CARE:
  //       return {
  //         AppStrings.headerBathBodyCare: GroceryData.bathBodyCareList,
  //         AppStrings.headerSkinCare: GroceryData.skinCareList,
  //         AppStrings.headerHairCare: GroceryData.hairCareList,
  //         AppStrings.headerOralCare: GroceryData.oralCareList,
  //         AppStrings.headerMenGrooming: GroceryData.menGroomingList,
  //         AppStrings.headerWomenHygiene: GroceryData.womenHygieneList,
  //         AppStrings.headerBeautyCosmetics: GroceryData.beautyCosmeticsList,
  //         AppStrings.headerBathroomHygiene: GroceryData.bathroomHygieneList,
  //         AppStrings.headerBabyCare: GroceryData.babyCareList,
  //         AppStrings.headerMedicalEssentials: GroceryData.medicalEssentialsList,
  //       };
  //
  //     case GroceryConstant.STATIONARY:
  //       return {
  //         AppStrings.headerWritingNotebooks: GroceryData.writingPaperNotebooksList,
  //         AppStrings.headerSchoolEssentials: GroceryData.schoolEssentialsList,
  //         AppStrings.headerOfficeUtility: GroceryData.officeDeskUtilityList,
  //         AppStrings.headerArtCraftWork: GroceryData.artCraftProjectList,
  //         AppStrings.headerCuttingPacking: GroceryData.cuttingFixingPackingList,
  //         AppStrings.headerPrintingGifts: GroceryData.printingGiftsDecorList,
  //       };
  //
  //     default:
  //       return {};
  //   }
  // }



}
