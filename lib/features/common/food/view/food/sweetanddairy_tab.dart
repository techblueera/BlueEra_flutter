import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class SweetAndBakeCategoryPage extends StatelessWidget {
  const SweetAndBakeCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          // -------------------- Dairy Drinks --------------------
          _sectionWidget(
            "Dairy Drinks",
            [
              _iconItem(AppIconCategoryAssets.milk, "Milk"),
              _iconItem(AppIconCategoryAssets.yogurtDrinks, "Yogurt Drinks"),
              _iconItem(AppIconCategoryAssets.lassi, "Lassi"),
              _iconItem(AppIconCategoryAssets.paneer, "Paneer"),
              _iconItem(AppIconCategoryAssets.ghee, "Ghee"),
              _iconItem(AppIconCategoryAssets.milkshakes, "Milkshakes"),
              _iconItem(AppIconCategoryAssets.teaCoffee, "Tea & Coffee"),
              _iconItem(AppIconCategoryAssets.dairyOthers, "Others"),
            ],
          ),

          // -------------------- Indian Sweets --------------------
          _sectionWidget(
            "Indian Sweets",
            [
              _iconItem(AppIconCategoryAssets.rasgulla, "Rasgulla"),
              _iconItem(AppIconCategoryAssets.gulabJamun, "Gulab Jamun"),
              _iconItem(AppIconCategoryAssets.rajbhog, "Rajbhog"),
              _iconItem(AppIconCategoryAssets.rasmalai, "Rasmalai"),
              _iconItem(AppIconCategoryAssets.kheerCups, "Kheer Cups"),
              _iconItem(AppIconCategoryAssets.sandesh, "Sandesh"),
              _iconItem(AppIconCategoryAssets.chamCham, "Cham Cham"),
              _iconItem(AppIconCategoryAssets.barfiAssort, "Barfi Assortment"),
            ],
          ),

          // -------------------- Western Desserts --------------------
          _sectionWidget(
            "Western Desserts",
            [
              _iconItem(AppIconCategoryAssets.cheesecake, "Cheesecake Cups"),
              _iconItem(AppIconCategoryAssets.mousse, "Mousse Cups"),
              _iconItem(AppIconCategoryAssets.pudding, "Pudding Cups"),
              _iconItem(AppIconCategoryAssets.brownies, "Brownies"),
              _iconItem(AppIconCategoryAssets.tarts, "Tarts"),
              _iconItem(AppIconCategoryAssets.donuts, "Donuts"),
              _iconItem(AppIconCategoryAssets.waffles, "Waffles"),
              _iconItem(AppIconCategoryAssets.dessertJars, "Dessert Jars"),
            ],
          ),

          // -------------------- Ice Creams --------------------
          _sectionWidget(
            "Ice Creams & Frozen Desserts",
            [
              _iconItem(AppIconCategoryAssets.iceCreamCups, "Ice Cream Cups"),
              _iconItem(AppIconCategoryAssets.sorbet, "Sorbet Cups"),
              _iconItem(AppIconCategoryAssets.kulfi, "Kulfi"),
              _iconItem(AppIconCategoryAssets.gelato, "Gelato"),
              _iconItem(AppIconCategoryAssets.frozenYogurt, "Frozen Yogurt"),
              _iconItem(AppIconCategoryAssets.sundae, "Sundae Cups"),
              _iconItem(AppIconCategoryAssets.familyPacks, "Family Packs"),
              _iconItem(AppIconCategoryAssets.iceCreamBars, "Bars / Sticks"),
            ],
          ),

          // -------------------- Juice Corner --------------------
          _sectionWidget(
            "Juice Corner",
            [
              _iconItem(AppIconCategoryAssets.orangeJuice, "Orange Juice"),
              _iconItem(AppIconCategoryAssets.mosambiJuice, "Mosambi Juice"),
              _iconItem(AppIconCategoryAssets.watermelonJuice, "Watermelon"),
              _iconItem(AppIconCategoryAssets.pomegranateJuice, "Pomegranate"),
              _iconItem(AppIconCategoryAssets.pineappleJuice, "Pineapple"),
              _iconItem(AppIconCategoryAssets.mangoJuice, "Mango Juice"),
              _iconItem(AppIconCategoryAssets.appleJuice, "Apple Juice"),
              _iconItem(AppIconCategoryAssets.mixedFruitJuice, "Mixed Fruit"),
            ],
          ),

          // -------------------- Oil Fried Snacks --------------------
          _sectionWidget(
            "Oil Fried Snacks",
            [
              _iconItem(AppIconCategoryAssets.samosa, "Samosa"),
              _iconItem(AppIconCategoryAssets.kachori, "Kachori"),
              _iconItem(AppIconCategoryAssets.pakoraBhaji, "Pakora / Bhaji"),
              _iconItem(AppIconCategoryAssets.frenchFries, "French Fries"),
              _iconItem(AppIconCategoryAssets.chickenFishFry, "Chicken/Fish Fry"),
              _iconItem(AppIconCategoryAssets.cutlet, "Cutlet / Patties"),
              _iconItem(AppIconCategoryAssets.vada, "Vada"),
              _iconItem(AppIconCategoryAssets.crispyRolls, "Crispy Rolls"),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================
  // SECTION WIDGET
  // ============================
  Widget _sectionWidget(String title, List<Widget> icons) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CustomText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: icons,
          ),
        ],
      ),
    );
  }

  // ============================
  // ICON ITEM
  // ============================
  Widget _iconItem(String img, String label) {
    return SizedBox(
      width: SizeConfig.size80,
      child: Column(
        children: [
          Container(
            height: SizeConfig.size50,
            width: SizeConfig.size50,
            padding: EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: LocalAssets(imagePath: img),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
