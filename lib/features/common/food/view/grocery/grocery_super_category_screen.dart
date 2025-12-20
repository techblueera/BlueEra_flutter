import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_category_item.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_data.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GrocerySuperCategoryScreen extends StatelessWidget {
  final bool isOwnGrocery;
  GrocerySuperCategoryScreen({super.key, required this.isOwnGrocery});

  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    final List<CollapsibleGridModel> superCategories = GroceryData.grocerySuperCategories;
    return Scaffold(
      backgroundColor: AppColors.whiteFE,
      appBar: CommonBackAppBar(
          title: 'Add Products',
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
          return GroceryCategoryItem(
            url: superCategories[index].icon,
            label: superCategories[index].label,
            onTap: () {
              final categoryMap
                  = getCategoriesByTag(superCategories[index].tagId);

              Get.toNamed(
                RouteHelper.getGroceryCategoryScreenRoute(),
                arguments: {
                  ApiKeys.argOwnGrocery: false,
                  ApiKeys.argPageHeading: superCategories[index].label,
                  ApiKeys.argArrGroceryCat: categoryMap,
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
          'Rice and Rice Products': GroceryData.riceProducts,
          'Wheat Atta and Flours': GroceryData.wheatAndFlours,
          'Dals Pulses and Beans': GroceryData.dalNdBeans,
          'Millets and Traditional Grains': GroceryData.milletsNdTraditionalGrains,
          'Breakfast and Light Staples': GroceryData.breakfastStaples,
          'Spices and Masala': GroceryData.spicesAndMasala,
          'Salt Sugar and Sweeteners': GroceryData.saltNdSweeteners,
          'Oils Ghee and Fats': GroceryData.oilsAndFats,
          'Tea Coffee and Beverages': GroceryData.teaCoffeeBeverages,
          'Dry Fruits Seeds Baby and Ready Food': GroceryData.dryFruitsAndReadyFood,
        };

      case GroceryConstant.VEGETABLE:
        return {
          'Leafy Vegetables': GroceryData.leafyVegetables,
          'Root Vegetables': GroceryData.rootVegetables,
          'Bulb and Stem Vegetables': GroceryData.bulbNdStemVegetables,
          'Fruit Vegetables': GroceryData.fruitVegetables,
          'Pods and Beans': GroceryData.podNdBeansVegetables,
          'Flower Vegetables': GroceryData.flowerVegetables,
          'Fungi and Special Indian Items': GroceryData.fungiNdSpecialIndianItems,
          'Exotic but India-Available Vegetables': GroceryData.exoticAndSpecialty,
        };

      case GroceryConstant.FRUIT:
        return {
          'Daily Fruits': GroceryData.dailyFruits,
          'Desi Fruits': GroceryData.desiFruits,
          'Sour & Stone Fruits': GroceryData.sourAndStoneFruits,
          'Small & Seasonal Fruits': GroceryData.smallNdSeasonalFruits,
          'Forest & Coastal Fruits': GroceryData.forestNdCoastalFruits,
          'Special Exotic Fruits': GroceryData.specialNdExoticFruits,
        };

      case GroceryConstant.BAKERY_BREAD_ITEMS:
        return {
          'Bakery': controller.bakery,
          'Bread': controller.bread,
          'Cakes & Muffins': controller.cakesNdMuffins,
          'Cookies & Biscuits': controller.cookiesNdBiscuit,
          'Dessert / Bakery Sweets': controller.desertSweets,
        };

      case GroceryConstant.DAIRY_PRODUCTS:
        return {
          'Milk & Milk Products': controller.milkProduct,
          'Curd & Yogurt': controller.curdNdYogurt,
          'Cheese & Paneer': controller.cheeseNdPaneer,
          'Butter & Ghee': controller.butterNdGhee,
          'Ice Cream & Frozen Dairy': controller.iceCreamNdFrozen,
        };

      case GroceryConstant.HOME_ESSENTIALS:
        return {
          'Mom & Baby Care': controller.momBabyCare,
          'Kitchenware': controller.kitchenware,
          'Tableware': controller.tableware,
          'Home': controller.homeCare,
        };

      case GroceryConstant.PACKED_SWEETS_NAMKEENS:
        return {
          'Indian Sweets': controller.indianSweets,
          'Milk-Based Sweets': controller.milkBasedSweets,
          'Dry Fruit & Premium Sweets': controller.DryNdPremiumSweets,
          'Namkeens': controller.namkeens,
        };

      case GroceryConstant.CROCKERY:
        return {
          'Plates & Dinnerware': controller.platesNdDinnerWare,
          'Bowls & Serving Ware': controller.bowsNdServiceWare,
          'Cups, Mugs & Glassware': controller.cupsNdGlassWare,
          'Serving & Table Accessories': controller.servingNdTableAccessories,
        };

      case GroceryConstant.MEDICAL_ITEMS:
        return {
          'First Aid & Basic Care': controller.firstAidCare,
          'Common Medicines': controller.commonMedicines,
          'Health & Hygiene Essentials': controller.healthNdHygieneEsse,
          'Digestive & Wellness Products': controller.digestiveNdWellnessProducts,
        };

      case GroceryConstant.BEAUTY_BODY_CARE:
        return {
          'Bath & Body Care': controller.bathNdBodyCare,
          'Hair Care': controller.hairCare,
          'Oral & Personal Hygiene': controller.oralNdPersonalHygiene,
          'Skin Care & Daily Beauty': controller.skinCareNdDailyBeauty,
        };

      case GroceryConstant.STATIONARY:
        return {
          'Writing Essentials': controller.writingEsse,
          'Paper Products': controller.paperProduct,
          'School & Study Essentials': controller.schoolNdStudyEsse,
          'Office & Desk Essentials': controller.officeNdDeskEsse,
          'Art & Craft': controller.artNdCraft,
        };

      default:
        return {};
    }
  }
}
