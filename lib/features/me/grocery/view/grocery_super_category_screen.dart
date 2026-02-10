import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_category_item.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_constant.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_data.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GrocerySuperCategoryScreen extends StatelessWidget {
  GrocerySuperCategoryScreen({super.key});

  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    final List<CollapsibleGridModel> superCategories = GroceryData.grocerySuperCategories;
    return Scaffold(
      backgroundColor: AppColors.whiteFE,
      appBar: CommonBackAppBar(
          title: AppStrings.addProducts,
          buildCustomWidget:()=>
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(-6, 36),
                color: AppColors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onSelected: (value) {},
                icon: Icon(Icons.more_vert, color: AppColors.mainTextColor),
                itemBuilder: (context) => groceryPopUpMenuItems(),
              ),
      ),
      body: ListView.builder(
        itemCount: superCategories.length,
        padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            top: SizeConfig.size15,
            bottom: SizeConfig.size30,
        ),
        itemBuilder: (context, index) {
          var groceryData = superCategories[index];

          return GroceryCategoryItem(
            url: groceryData.icon,
            label: groceryData.name,
            onTap: () {
              final categoryMap
                  = getCategoriesByTag(groceryData.slugId);

              Get.toNamed(
                RouteHelper.getGroceryCategoryScreenRoute(),
                arguments: {
                  ApiKeys.argMyGrocery: true,
                  ApiKeys.argArrGrocerySuperCategory: superCategories,
                  ApiKeys.argArrGroceryCatKey: groceryData.slugId,
                  ApiKeys.argArrGroceryCatName: groceryData.name,
                },
              );
            },
          );
        },
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
