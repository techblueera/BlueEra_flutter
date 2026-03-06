import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_category_item.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_data.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class GrocerySuperCategoryScreen extends StatelessWidget {
  GrocerySuperCategoryScreen({super.key});

  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    final List<CollapsibleGridModel> superCategories = GroceryData.grocerySuperCategories;


    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
          title: AppStrings.addProducts,
          buildCustomActionWidget:()=>
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15,
        ),
        child: SafeArea(
          child: Column(
            children: [

              CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        CustomText(
                            'Bulk Upload Shop Product Photos',
                            fontSize: SizeConfig.large,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w600
                        ),
                      SizedBox(height: SizeConfig.paddingXSL),
                      MasonryGridView.count(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.grocerySnapSearchPhotos.length,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          var item = controller.grocerySnapSearchPhotos[index];
                          return InkWell(
                            onTap:()=> Get.toNamed(RouteHelper.getAddGrocerySnapSearchScreenRoute()),
                            child: ClipRRect(
                             borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.greyE5
                                  ),
                                ),
                                child: LocalAssets(
                                    imagePath: item,
                                    height: SizeConfig.size120,
                                    width: double.infinity,
                                    boxFix: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  )
              ),

              SizedBox(
                height: SizeConfig.paddingXSL
              ),

              CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                        'Category',
                        fontSize: SizeConfig.large,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),

                    MasonryGridView.count(
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: superCategories.length,
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        var superCategory = superCategories[index];
                        return CommonServiceCard<CollapsibleGridModel>(
                          service: superCategory,
                          getName: (item) => item.name,
                          getIcon: (item) => item.icon??'',
                          iconHeight: SizeConfig.size60,
                          boxShadow: [],
                          onTap: (item) {
                            // getCategoriesByTag(item.slugId);

                            Get.toNamed(
                              RouteHelper.getGroceryCategoryScreenRoute(),
                              arguments: {
                                ApiKeys.argMyGrocery: true,
                                ApiKeys.argArrGrocerySuperCategory: superCategories,
                                ApiKeys.argArrGroceryCatKey: item.slugId,
                                ApiKeys.argArrGroceryCatName: item.name,
                              },
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
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
