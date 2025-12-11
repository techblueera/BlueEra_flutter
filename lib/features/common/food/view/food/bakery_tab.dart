import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class BakeryCategoryPage extends StatelessWidget {
  const BakeryCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          // --------------------- Bakery ---------------------
          _sectionWidget(
            "Bakery",
            [
              _iconItem(AppIconCategoryAssets.puffs, "Puffs"),
              _iconItem(AppIconCategoryAssets.bakeryPatties, "Patties"),
              _iconItem(AppIconCategoryAssets.sandwiches, "Sandwiches"),
              _iconItem(AppIconCategoryAssets.croissants, "Croissants"),
              _iconItem(AppIconCategoryAssets.bakeryGarlicBread, "Garlic Bread"),
              _iconItem(AppIconCategoryAssets.rollsWraps, "Rolls / Wraps"),
              _iconItem(AppIconCategoryAssets.miniPizzas, "Mini Pizzas"),
              _iconItem(AppIconCategoryAssets.cheeseSticks, "Cheese Sticks"),
            ],
          ),

          // --------------------- Bread ---------------------
          _sectionWidget(
            "Bread",
            [
              _iconItem(AppIconCategoryAssets.whiteBread, "White Bread"),
              _iconItem(AppIconCategoryAssets.brownBread, "Brown Bread"),
              _iconItem(AppIconCategoryAssets.multigrainBread, "Multigrain Bread"),
              _iconItem(AppIconCategoryAssets.milkBread, "Milk Bread"),
              _iconItem(AppIconCategoryAssets.sandwichBread, "Sandwich Bread"),
              _iconItem(AppIconCategoryAssets.garlicBreadLoaf, "Garlic Bread Loaf"),
              _iconItem(AppIconCategoryAssets.bunsPav, "Buns & Pav"),
              _iconItem(AppIconCategoryAssets.artisanBread, "Artisan Bread"),
            ],
          ),

          // --------------------- Cakes & Muffins ---------------------
          _sectionWidget(
            "Cakes & Muffins",
            [
              _iconItem(AppIconCategoryAssets.cupcakes, "Cupcakes"),
              _iconItem(AppIconCategoryAssets.muffins, "Muffins"),
              _iconItem(AppIconCategoryAssets.sliceCakes, "Slice Cakes"),
              _iconItem(AppIconCategoryAssets.pastries, "Pastries"),
              _iconItem(AppIconCategoryAssets.teaCakes, "Tea Cakes"),
              _iconItem(AppIconCategoryAssets.plumCake, "Plum Cake"),
              _iconItem(AppIconCategoryAssets.miniCakes, "Mini Cakes"),
              _iconItem(AppIconCategoryAssets.celebrationCake, "Celebration Cake"),
            ],
          ),

          // --------------------- Cookies & Biscuits ---------------------
          _sectionWidget(
            "Cookies & Biscuits",
            [
              _iconItem(AppIconCategoryAssets.butterCookies, "Butter Cookies"),
              _iconItem(AppIconCategoryAssets.chocoChipCookies, "Choco Chip Cookies"),
              _iconItem(AppIconCategoryAssets.oatsCookies, "Oats Cookies"),
              _iconItem(AppIconCategoryAssets.shortbread, "Shortbread"),
              _iconItem(AppIconCategoryAssets.jeeraBiscuits, "Jeera Biscuits"),
              _iconItem(AppIconCategoryAssets.digestiveCookies, "Digestive Cookies"),
              _iconItem(AppIconCategoryAssets.dryCakeRusks, "Dry Cake Rusks"),
              _iconItem(AppIconCategoryAssets.assortedCookies, "Assorted Cookies"),
            ],
          ),

          // --------------------- Dessert / Bakery Sweets ---------------------
          _sectionWidget(
            "Dessert / Bakery Sweets",
            [
              _iconItem(AppIconCategoryAssets.bakeryDonuts, "Donuts"),
              _iconItem(AppIconCategoryAssets.bakeryBrownies, "Brownies"),
              _iconItem(AppIconCategoryAssets.cheesecakeSlices, "Cheesecake Slices"),
              _iconItem(AppIconCategoryAssets.bakeryTarts, "Tarts"),
              _iconItem(AppIconCategoryAssets.eclairs, "Eclairs"),
              _iconItem(AppIconCategoryAssets.bakeryWaffles, "Waffles"),
              _iconItem(AppIconCategoryAssets.puddings, "Puddings"),
              _iconItem(AppIconCategoryAssets.bakeryDessertJars, "Dessert Jars"),
            ],
          ),

          // --------------------- Namkeens ---------------------
          _sectionWidget(
            "Namkeens",
            [
              _iconItem(AppIconCategoryAssets.alooBhujia, "Aloo Bhujia"),
              _iconItem(AppIconCategoryAssets.bikaneriBhujia, "Bikaneri Bhujia"),
              _iconItem(AppIconCategoryAssets.moongDalNamkeen, "Moong Dal"),
              _iconItem(AppIconCategoryAssets.navratanMix, "Navratan Mix"),
              _iconItem(AppIconCategoryAssets.chanaJorGaram, "Chana Jor Garam"),
              _iconItem(AppIconCategoryAssets.masalaSev, "Masala Sev"),
              _iconItem(AppIconCategoryAssets.saltedPeanuts, "Salted Peanuts"),
              _iconItem(AppIconCategoryAssets.khakhraSnacks, "Khakhra Snacks"),
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
