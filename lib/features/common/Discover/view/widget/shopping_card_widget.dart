import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/me/product/view/customer/products_store_discover_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShoppingCardWidget extends StatefulWidget {
  const ShoppingCardWidget({super.key});

  @override
  State<ShoppingCardWidget> createState() => _ShoppingCardWidgetState();
}

class _ShoppingCardWidgetState extends State<ShoppingCardWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final allCategories =
        Get.find<AuthController>().businessOnboardingProductsCategories;
    final showMoreButton = allCategories.length > 10;
    final displayCategories =
        _showAll ? allCategories.toList() : allCategories.take(10).toList();

    return DiscoverGridSection(
      title: AppStrings.shoppingSales.tr,
      items: displayCategories,
      getName: (item) => item.name ?? '',
      getIcon: (item) => getProductCategoryIcon(item.tagId),
      onViewAll: showMoreButton
          ? () => setState(() => _showAll = !_showAll)
          : null,
      viewAllLabel: _showAll ? AppStrings.showLess.tr : AppStrings.showMore.tr,
      // Folder tap → the store discover screen with NO category preselected.
      // Both of its category params are nullable and it only filters when one
      // is given, so this is the "all products" entry rather than an arbitrary
      // category picked for the user.
      onItemTap: (item) {
        Get.to(() => ProductsStoreDiscoverScreen(
              productCategoryName: item.name,
              productCategory: item.tagId,
            ));
      },
    );
  }
}
