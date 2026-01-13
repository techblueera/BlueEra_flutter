import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_model.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_product_selection_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart'; // Ensure you add this to pubspec.yaml

class GroceryCategoryMenuScreen extends StatelessWidget {
  const GroceryCategoryMenuScreen({super.key});

  // List mapped to your specific local assets
  List<GroceryCategoryModel> get categories => [
        GroceryCategoryModel(
            title: 'Breakfast',
            iconPath: 'assets/category/grocery/menu/breakfast.svg'),
        GroceryCategoryModel(
            title: 'Veg Curry',
            iconPath: 'assets/category/grocery/menu/vegcurry.svg'),
        GroceryCategoryModel(
            title: 'Tiffin & Thali',
            iconPath: 'assets/category/grocery/menu/tiffinthali.svg'),
        GroceryCategoryModel(
            title: 'Rice Items',
            iconPath: 'assets/category/grocery/menu/riceItems.svg'),
        GroceryCategoryModel(
            title: 'Non-Veg Food',
            iconPath: 'assets/category/grocery/menu/nonvegfood.svg'),
        GroceryCategoryModel(
            title: 'Bread & Paratha Items',
            iconPath: 'assets/category/grocery/menu/breadparathaitems.svg'),
        GroceryCategoryModel(
            title: 'Sweets',
            iconPath: 'assets/category/grocery/menu/sweets.svg'),
        GroceryCategoryModel(
            title: 'Dairy & Ice Creams',
            iconPath: 'assets/category/grocery/menu/dairyicecreams.svg'),
        GroceryCategoryModel(
            title: 'Bakery & Namkeens',
            iconPath: 'assets/category/grocery/menu/bakerynamkeens.svg'),
        GroceryCategoryModel(
            title: 'Braverages, Salad & Fruit',
            iconPath: 'assets/category/grocery/menu/braverages.svg'),
        GroceryCategoryModel(
            title: 'Fast Food, Starter & Grill (Veg)',
            iconPath: 'assets/category/grocery/menu/fastfood.svg'),
        GroceryCategoryModel(
            title: 'Non-Veg Starter & Grill (Non-Veg)',
            iconPath: 'assets/category/grocery/menu/nonveg.svg'),
        GroceryCategoryModel(
            title: 'Restaurant Special',
            iconPath: 'assets/category/grocery/menu/restaurantspecial.svg'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Products',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 50.0),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: SvgPicture.asset(
                      item.iconPath,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      // If your SVGs are black and white, you can tint them here:
                      // colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    ),
                    title: CustomText(
                      item.title,
                      fontSize: 15,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    onTap: () {
                      // Action for item tap
                      Get.to(ProductSelectionScreen());
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
