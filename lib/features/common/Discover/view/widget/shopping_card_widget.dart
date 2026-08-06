import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
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
    // The opened folder is a PICKER and shows every category. The 10-item cap
    // and its Show more/less toggle exist so the landing card doesn't run down
    // the page — inside the sheet the toggle isn't rendered at all, so keeping
    // the cap there would strand the categories past the tenth with no way to
    // reach them. Each tile routes to its OWN category here, so that is a real
    // loss rather than a cosmetic one.
    final inSheet = DiscoverSheetScope.isActive(context);
    final displayCategories = (_showAll || inSheet)
        ? allCategories.toList()
        : allCategories.take(10).toList();

    return DiscoverGridSection(
      title: AppStrings.shoppingSales.tr,
      items: displayCategories,
      getName: (item) => item.name ?? '',
      // Category artwork comes from the API (`image_url`), not a bundled map
      // keyed by tagId — a category added or renamed server-side then arrives
      // with its icon instead of rendering blank until the app ships a new
      // asset. `getProductCategoryIcon` still exists for the store screens,
      // which are not part of the Discover grid.
      getIcon: (item) => item.imageUrl ?? '',
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
