import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class NonVegCategoryPage extends StatelessWidget {
  const NonVegCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          // -------------------------------------
          // 1️⃣  Thali & Paratha
          // -------------------------------------
          _sectionWidget(
            "Thali & Paratha",
            [
              _iconItem(AppIconCategoryAssets.chickenThali, "Chicken Thali"),
              _iconItem(AppIconCategoryAssets.muttonThali, "Mutton Thali"),
              _iconItem(AppIconCategoryAssets.eggThali, "Egg Thali"),
              _iconItem(AppIconCategoryAssets.fishThali, "Fish Thali"),
              _iconItem(AppIconCategoryAssets.chickenParatha, "Chicken Paratha"),
              _iconItem(AppIconCategoryAssets.eggParatha, "Egg Paratha"),
              _iconItem(AppIconCategoryAssets.keemaParatha, "Keema Paratha"),
              _iconItem(AppIconCategoryAssets.fishCombo, "Fish Curry + Paratha"),
            ],
          ),

          // -------------------------------------
          // 2️⃣  Chicken
          // -------------------------------------
          _sectionWidget(
            "Chicken",
            [
              _iconItem(AppIconCategoryAssets.nuggets, "Chicken Nuggets"),
              _iconItem(AppIconCategoryAssets.popcorn, "Chicken Popcorn"),
              _iconItem(AppIconCategoryAssets.kebab, "Chicken Kebab"),
              _iconItem(AppIconCategoryAssets.tikka, "Chicken Tikka"),
              _iconItem(AppIconCategoryAssets.sausage, "Chicken Sausages"),
              _iconItem(AppIconCategoryAssets.momos, "Chicken Momos"),
              _iconItem(AppIconCategoryAssets.cutlets, "Chicken Cutlets"),
              _iconItem(AppIconCategoryAssets.wings, "Chicken Wings"),
            ],
          ),

          // -------------------------------------
          // 3️⃣ Fish & Seafood
          // -------------------------------------
          _sectionWidget(
            "Fish & Seafood",
            [
              _iconItem(AppIconCategoryAssets.fingers, "Fish Fingers"),
              _iconItem(AppIconCategoryAssets.cutlets, "Fish Cutlets"),
              _iconItem(AppIconCategoryAssets.popcornFish, "Fish Popcorn"),
              _iconItem(AppIconCategoryAssets.patties, "Fish Patties"),
              _iconItem(AppIconCategoryAssets.prawnFry, "Prawn Fry"),
              _iconItem(AppIconCategoryAssets.prawnPopcorn, "Prawn Popcorn"),
              _iconItem(AppIconCategoryAssets.crabSticks, "Crab Sticks"),
              _iconItem(AppIconCategoryAssets.seafoodMix, "Seafood Mix"),
            ],
          ),

          // -------------------------------------
          // 4️⃣ Mutton
          // -------------------------------------
          _sectionWidget(
            "Mutton",
            [
              _iconItem(AppIconCategoryAssets.seekhKebab, "Mutton Seekh Kebab"),
              _iconItem(AppIconCategoryAssets.shamiKebab, "Mutton Shami Kebab"),
              _iconItem(AppIconCategoryAssets.muttonCutlets, "Mutton Cutlets"),
              _iconItem(AppIconCategoryAssets.muttonMomos, "Mutton Momos"),
              _iconItem(AppIconCategoryAssets.muttonRoll, "Mutton Rolls"),
              _iconItem(AppIconCategoryAssets.muttonPatties, "Mutton Patties"),
              _iconItem(AppIconCategoryAssets.muttonMeatballs, "Mutton Meatballs"),
              _iconItem(AppIconCategoryAssets.muttonCurry, "Mutton Curry"),
            ],
          ),

          // -------------------------------------
          // 5️⃣ Egg
          // -------------------------------------
          _sectionWidget(
            "Eggs",
            [
              _iconItem(AppIconCategoryAssets.boiledEgg, "Boiled Eggs"),
              _iconItem(AppIconCategoryAssets.masalaEgg, "Masala Eggs"),
              _iconItem(AppIconCategoryAssets.eggPatties, "Egg Patties"),
              _iconItem(AppIconCategoryAssets.eggRolls, "Egg Rolls"),
              _iconItem(AppIconCategoryAssets.omelette, "Omelette Mix"),
              _iconItem(AppIconCategoryAssets.eggSandwich, "Egg Sandwich"),
              _iconItem(AppIconCategoryAssets.eggCutlet, "Egg Cutlet"),
              _iconItem(AppIconCategoryAssets.bhurji, "Egg Bhurji"),
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
