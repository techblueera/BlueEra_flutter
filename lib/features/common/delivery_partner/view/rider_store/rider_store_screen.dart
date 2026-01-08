import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_data.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderStoreScreen extends StatefulWidget {
  const RiderStoreScreen({super.key});

  @override
  State<RiderStoreScreen> createState() => _RiderStoreScreenState();
}

class _RiderStoreScreenState extends State<RiderStoreScreen> {

  /// Super Grocery Categories
  static const List<CollapsibleGridModel> grocerySuperCategories = [
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsColorful,
        label: AppStrings.labelGroceryItems,
        tagId: GroceryConstant.GROCERY_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.vegetablesColorful,
        label: AppStrings.labelVegetable,
        tagId: GroceryConstant.VEGETABLES),
    CollapsibleGridModel(
        icon: AppIconAssets.fruitsColorful,
        label: AppStrings.labelFruit,
        tagId: GroceryConstant.FRUITS),
    CollapsibleGridModel(
        icon: AppIconAssets.bakeryNamkeenItemsColorful,
        label: AppStrings.labelBakeryBreadItems,
        tagId: GroceryConstant.BAKERY_NAMKEEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.dairyFrozenItemsColorful,
        label: AppStrings.labelDairyProducts,
        tagId: GroceryConstant.DAIRY_FROZEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.crockeryColorful,
        label: AppStrings.labelCrockery,
        tagId: GroceryConstant.CROCKERY),
    CollapsibleGridModel(
        icon: AppIconAssets.homeEssentialsColorful,
        label: AppStrings.labelHomeEssentials,
        tagId: GroceryConstant.HOME_ESSENTIALS),
    CollapsibleGridModel(
        icon: AppIconAssets.cleaningMaintenanceColorful,
        label: AppStrings.labelCleaningMaintenance,
        tagId: GroceryConstant.CLEANING_MAINTENANCE),
    CollapsibleGridModel(
        icon: AppIconAssets.beautyHealthCareColorful,
        label: AppStrings.labelBeautyHealthCare,
        tagId: GroceryConstant.BEAUTY_HEALTH_CARE),
    CollapsibleGridModel(
        icon: AppIconAssets.stationaryColorful,
        label: AppStrings.labelStationary,
        tagId: GroceryConstant.STATIONARY),
  ];


  static const List<CollapsibleGridModel> foodCategories = [
    CollapsibleGridModel(
        icon: AppIconAssets.tiffinColorful,
        label: 'Tiffin',
        tagId: 'TIFFIN'),
    CollapsibleGridModel(
        icon: AppIconAssets.breakfastColorful,
        label: 'Breakfast',
        tagId: 'BREAKFAST'),
    CollapsibleGridModel(
        icon: AppIconAssets.lunchDinnerColorful,
        label: 'Lunch, Dinner',
        tagId: 'LUNCH_DINNER'),
    CollapsibleGridModel(
        icon: AppIconAssets.fastFoodColorful,
        label: 'Fast-Food',
        tagId: 'FAST_FOOD'),
    CollapsibleGridModel(
        icon: AppIconAssets.sweetsColorful,
        label: 'Sweets',
        tagId: 'SWEETS'),
    CollapsibleGridModel(
        icon: AppIconAssets.restaurantColorful,
        label: 'Restaurant',
        tagId: 'RESTAURANT'),
  ];

  static const List<CollapsibleGridModel> restaurantNearMe = [
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        label: 'Restaurant',
        tagId: 'NEAR_RESTAURANT'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        label: 'Breakfast',
        tagId: 'NEAR_BREAKFAST'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        label: 'Lunch, Dinner',
        tagId: 'NEAR_LUNCH_DINNER'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        label: 'Fast-Food',
        tagId: 'NEAR_FAST_FOOD'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        label: 'Sweets',
        tagId: 'NEAR_SWEETS'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey, // Use a variation if available
        label: 'Restaurant',
        tagId: 'NEAR_RESTAURANT_ALT'),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
          ),
          child: CustomScrollView(

            slivers: [

              SliverToBoxAdapter(
                child: SizedBox(height: SizeConfig.paddingM),
              ),

              SliverToBoxAdapter(
                child: InkWell(
                  onTap: () {
                    // Handle search tap
                  },
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    margin: EdgeInsets.only(bottom: SizeConfig.paddingXSL), // Add spacing below search
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5, width: 1.2),
                      boxShadow: [AppShadows.textFieldShadow],
                    ),
                    child: Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.riderIconColorful,
                          height: SizeConfig.size30,
                          width: SizeConfig.size30,
                        ),
                        SizedBox(width: SizeConfig.size10),
                        CustomText(
                          AppStrings.yourPreviousRider,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

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

                      
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: grocerySuperCategories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          var groceryData = grocerySuperCategories[index];
                          return _buildCategoryItem(
                            label: groceryData.label,
                            iconPath: groceryData.icon,
                            onTap: () {
                              final categoryMap = getCategoriesByTag(groceryData.tagId);
                              Get.toNamed(
                                RouteHelper.getGroceryCategoryScreenRoute(),
                                arguments: {
                                  ApiKeys.argMyGrocery: false,
                                  ApiKeys.argPageHeading: groceryData.label,
                                  ApiKeys.argArrGroceryCat: categoryMap,
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: SizeConfig.paddingXSL),
              ),

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


                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: foodCategories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          var foodCategoryData = foodCategories[index];
                          return _buildCategoryItem(
                            label: foodCategoryData.label,
                            iconPath: foodCategoryData.icon,
                            onTap: () {

                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: SizeConfig.paddingXSL),
              ),

              SliverToBoxAdapter(
                child: CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.paddingXSL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      CustomText(
                          AppStrings.restaurantNearMe,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400),

                      SizedBox(height: SizeConfig.paddingXSL),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: restaurantNearMe.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          var restaurantNearMeData = restaurantNearMe[index];
                          return _buildCategoryItem(
                            label: restaurantNearMeData.label,
                            iconPath: restaurantNearMeData.icon,
                            onTap: () {

                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: SizeConfig.paddingM),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String label,
    required String iconPath,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: AppColors.greyE5,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Section
            LocalAssets(
              imagePath: iconPath,
              height: SizeConfig.size30,
              width: SizeConfig.size30,
            ),

            SizedBox(height: SizeConfig.paddingXSL),

            // Label Section
            CustomText(
                label,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
            ),

          ],
        ),
      ),
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

  Map<String, List<CollapsibleGridModel>> getCategoriesByTag(String tagId) {
    switch (tagId) {
      case GroceryConstant.GROCERY_ITEMS:
        return {
          AppStrings.headerRiceRiceProducts: GroceryData.riceProducts,
          AppStrings.headerWheatAttaFlours: GroceryData.wheatAndFlours,
          AppStrings.headerDalsPulsesBeans: GroceryData.dalNdBeans,
          AppStrings.headerMilletsTraditionalGrains: GroceryData.milletsNdTraditionalGrains,
          AppStrings.headerBreakfastLightStaples: GroceryData.breakfastStaples,
          AppStrings.headerSpicesMasala: GroceryData.spicesAndMasala,
          AppStrings.headerSaltSugarSweeteners: GroceryData.saltNdSweeteners,
          AppStrings.headerOilsGheeFats: GroceryData.oilsAndFats,
          AppStrings.headerTeaCoffeeBeverages: GroceryData.teaCoffeeBeverages,
          AppStrings.headerDryFruitsReadyFood: GroceryData.dryFruitsAndReadyFood,
        };

      case GroceryConstant.VEGETABLES:
        return {
          AppStrings.headerLeafyVegetables: GroceryData.leafyVegetables,
          AppStrings.headerRootVegetables: GroceryData.rootVegetables,
          AppStrings.headerBulbStemVegetables: GroceryData.bulbNdStemVegetables,
          AppStrings.headerFruitVegetables: GroceryData.fruitVegetables,
          AppStrings.headerPodsBeans: GroceryData.podNdBeansVegetables,
          AppStrings.headerFlowerVegetables: GroceryData.flowerVegetables,
          AppStrings.headerSpecialIndianItems: GroceryData.fungiNdSpecialIndianItems,
          AppStrings.headerExoticVegetables: GroceryData.exoticAndSpecialty,
        };

      case GroceryConstant.FRUITS:
        return {
          AppStrings.headerDailyFruits: GroceryData.dailyFruits,
          AppStrings.headerDesiFruits: GroceryData.desiFruits,
          AppStrings.headerSourStoneFruits: GroceryData.sourAndStoneFruits,
          AppStrings.headerSmallSeasonalFruits: GroceryData.smallNdSeasonalFruits,
          AppStrings.headerForestCoastalFruits: GroceryData.forestNdCoastalFruits,
          AppStrings.headerSpecialExoticFruits: GroceryData.specialNdExoticFruits,
        };

      case GroceryConstant.BAKERY_NAMKEEN_ITEMS:
        return {
          AppStrings.headerNamkeenMixture: GroceryData.namkeenAndMixture,
          AppStrings.headerChipsPapadFryums: GroceryData.chipsPapadFryums,
          AppStrings.headerBiscuitsCookies: GroceryData.biscuitsCookies,
          AppStrings.headerBakerySweetItems: GroceryData.bakeryItems,
          AppStrings.headerFriedHotSnacks: GroceryData.friedHotSnacks,
        };

      case GroceryConstant.DAIRY_FROZEN_ITEMS:
        return {
          AppStrings.headerMilk: GroceryData.milkList,
          AppStrings.headerCurdCream: GroceryData.curdButtermilkCreamList,
          AppStrings.headerButterCheesePaneer: GroceryData.butterCheesePaneerList,
          AppStrings.headerGheeDairyFats: GroceryData.gheeAndDairyFatsList,
          AppStrings.headerIceCreamFrozen: GroceryData.iceCreamFrozenDessertsList,
          AppStrings.headerDairySweetNdChocolate: GroceryData.sweetsChocolatesList,
          AppStrings.headerFrozenVegetables: GroceryData.frozenVegetablesList,
          AppStrings.headerFrozenSnacks: GroceryData.frozenSnacksMealsList,
          AppStrings.headerMilkPowderAlts: GroceryData.milkPowdersAlternativesList,
        };

      case GroceryConstant.CROCKERY:
        return {
          AppStrings.headerCookingUtensils: GroceryData.cookingUtensilsList,
          AppStrings.headerDiningUtensils: GroceryData.diningUtensilsList,
          AppStrings.headerServingUtensils: GroceryData.servingUtensilsList,
          AppStrings.headerKitchenHandTools: GroceryData.kitchenToolsList,
          AppStrings.headerKitchenAppliances: GroceryData.kitchenAppliancesList,
          AppStrings.headerStorageCarry: GroceryData.storageCarryList,
          AppStrings.headerGasWaterUtility: GroceryData.utilityItemsList,
          AppStrings.headerCleaningSetup: GroceryData.cleaningSetupList,
        };

      case GroceryConstant.HOME_ESSENTIALS:
        return {
          AppStrings.headerElectricalSafety: GroceryData.electricalSafetyList,
          AppStrings.headerWaterStorage: GroceryData.waterStorageList,
          AppStrings.headerHomeUtility: GroceryData.homeUtilityList,
          AppStrings.headerPujaItems: GroceryData.pujaItemsList,
        };

      case GroceryConstant.CLEANING_MAINTENANCE:
        return {
          AppStrings.headerLaundryCare: GroceryData.laundryCareList,
          AppStrings.headerBathroomCare: GroceryData.bathroomCareList,
          AppStrings.headerKitchenCare: GroceryData.kitchenCareList,
          AppStrings.headerFloorSurface: GroceryData.floorSurfaceList,
          AppStrings.headerCleaningTools: GroceryData.cleaningToolsList,
          AppStrings.headerPestAirCare: GroceryData.pestAirCareList,
          AppStrings.headerSafetyRepair: GroceryData.safetyRepairList,
        };

      case GroceryConstant.BEAUTY_HEALTH_CARE:
        return {
          AppStrings.headerBathBodyCare: GroceryData.bathBodyCareList,
          AppStrings.headerSkinCare: GroceryData.skinCareList,
          AppStrings.headerHairCare: GroceryData.hairCareList,
          AppStrings.headerOralCare: GroceryData.oralCareList,
          AppStrings.headerMenGrooming: GroceryData.menGroomingList,
          AppStrings.headerWomenHygiene: GroceryData.womenHygieneList,
          AppStrings.headerBeautyCosmetics: GroceryData.beautyCosmeticsList,
          AppStrings.headerBathroomHygiene: GroceryData.bathroomHygieneList,
          AppStrings.headerBabyCare: GroceryData.babyCareList,
          AppStrings.headerMedicalEssentials: GroceryData.medicalEssentialsList,
        };

      case GroceryConstant.STATIONARY:
        return {
          AppStrings.headerWritingNotebooks: GroceryData.writingPaperNotebooksList,
          AppStrings.headerSchoolEssentials: GroceryData.schoolEssentialsList,
          AppStrings.headerOfficeUtility: GroceryData.officeDeskUtilityList,
          AppStrings.headerArtCraftWork: GroceryData.artCraftProjectList,
          AppStrings.headerCuttingPacking: GroceryData.cuttingFixingPackingList,
          AppStrings.headerPrintingGifts: GroceryData.printingGiftsDecorList,
        };

      default:
        return {};
    }
  }



}
