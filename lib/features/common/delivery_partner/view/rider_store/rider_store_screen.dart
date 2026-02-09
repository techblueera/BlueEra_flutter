import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
        name: AppStrings.labelGroceryItems,
        slugId: GroceryConstant.GROCERY_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.vegetablesColorful,
        name: AppStrings.labelVegetable,
        slugId: GroceryConstant.VEGETABLES),
    CollapsibleGridModel(
        icon: AppIconAssets.fruitsColorful,
        name: AppStrings.labelFruit,
        slugId: GroceryConstant.FRUITS),
    CollapsibleGridModel(
        icon: AppIconAssets.bakeryNamkeenItemsColorful,
        name: AppStrings.labelBakeryBreadItems,
        slugId: GroceryConstant.BAKERY_NAMKEEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.dairyFrozenItemsColorful,
        name: AppStrings.labelDairyProducts,
        slugId: GroceryConstant.DAIRY_FROZEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.crockeryColorful,
        name: AppStrings.labelCrockery,
        slugId: GroceryConstant.CROCKERY),
    CollapsibleGridModel(
        icon: AppIconAssets.homeEssentialsColorful,
        name: AppStrings.labelHomeEssentials,
        slugId: GroceryConstant.HOME_ESSENTIALS),
    CollapsibleGridModel(
        icon: AppIconAssets.cleaningMaintenanceColorful,
        name: AppStrings.labelCleaningMaintenance,
        slugId: GroceryConstant.CLEANING_MAINTENANCE),
    CollapsibleGridModel(
        icon: AppIconAssets.beautyHealthCareColorful,
        name: AppStrings.labelBeautyHealthCare,
        slugId: GroceryConstant.BEAUTY_HEALTH_CARE),
    CollapsibleGridModel(
        icon: AppIconAssets.stationaryColorful,
        name: AppStrings.labelStationary,
        slugId: GroceryConstant.STATIONARY),
  ];


  static const List<CollapsibleGridModel> foodCategories = [
    CollapsibleGridModel(
        icon: AppIconAssets.tiffinColorful,
        name: 'Tiffin',
        slugId: 'TIFFIN'),
    CollapsibleGridModel(
        icon: AppIconAssets.breakfastColorful,
        name: 'Breakfast',
        slugId: 'BREAKFAST'),
    CollapsibleGridModel(
        icon: AppIconAssets.lunchDinnerColorful,
        name: 'Lunch, Dinner',
        slugId: 'LUNCH_DINNER'),
    CollapsibleGridModel(
        icon: AppIconAssets.fastFoodColorful,
        name: 'Fast-Food',
        slugId: 'FAST_FOOD'),
    CollapsibleGridModel(
        icon: AppIconAssets.sweetsColorful,
        name: 'Sweets',
        slugId: 'SWEETS'),
    CollapsibleGridModel(
        icon: AppIconAssets.restaurantColorful,
        name: 'Restaurant',
        slugId: 'RESTAURANT'),
  ];

  static const List<CollapsibleGridModel> restaurantNearMe = [
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        name: 'Restaurant',
        slugId: 'NEAR_RESTAURANT'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        name: 'Breakfast',
        slugId: 'NEAR_BREAKFAST'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        name: 'Lunch, Dinner',
        slugId: 'NEAR_LUNCH_DINNER'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        name: 'Fast-Food',
        slugId: 'NEAR_FAST_FOOD'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        name: 'Sweets',
        slugId: 'NEAR_SWEETS'),
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey, // Use a variation if available
        name: 'Restaurant',
        slugId: 'NEAR_RESTAURANT_ALT'),
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

              _buildGap(gap: SizeConfig.paddingM),

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

                      _buildCategoryGrid(
                        items: grocerySuperCategories,
                        onTap: (item) {
                          final categoryMap = getCategoriesByTag(item.slugId);
                          Get.toNamed(
                            RouteHelper.getGroceryCategoryScreenRoute(),
                            arguments: {
                              ApiKeys.argMyGrocery: false,
                              ApiKeys.argArrGrocerySuperCategory: grocerySuperCategories,
                              ApiKeys.argArrGroceryCatKey: item.slugId,
                              ApiKeys.argArrGroceryCatName: item.name,
                            },
                          );
                        },
                      ),

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

                      _buildCategoryGrid(
                        items: foodCategories,
                        onTap: (item) {

                        },
                      ),

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

                      CustomText(
                          AppStrings.restaurantNearMe,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400),

                      SizedBox(height: SizeConfig.paddingXSL),

                      _buildCategoryGrid(
                        items: restaurantNearMe,
                        onTap: (item) {

                        },
                      ),

                    ],
                  ),
                ),
              ),

              _buildGap(gap: SizeConfig.paddingM)
            ],
          ),
        ),
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
        return _buildCategoryItem(
          label: item.name,
          iconPath: item.icon,
          onTap: () => onTap(item),
        );
      },
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
              height: SizeConfig.size60,
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
