import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_business_all_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerInventoryBusinessCardsScreen extends StatefulWidget {
  final bool showBackAppBar;
  const ManufacturerInventoryBusinessCardsScreen(
      {super.key, this.showBackAppBar = true});

  @override
  State<ManufacturerInventoryBusinessCardsScreen> createState() =>
      _InventoryBusinessCardsScreenState();
}

class _InventoryBusinessCardsScreenState
    extends State<ManufacturerInventoryBusinessCardsScreen> {
  final inventoryController = getOrPut(() => ManufacturerInventoryController());

  @override
  void initState() {
    super.initState();
    if (inventoryController.allProducts.isEmpty) {
      inventoryController.fetchBusinessProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showBackAppBar
          ? CommonBackAppBar(
              isLeading: true,
              title: AppStrings.myBusinessCards,
            )
          : null,
      body: Obx(() {
        if (inventoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (inventoryController.allProducts.isEmpty) {
          return const Center(child: CustomText(AppStrings.noProductsFound));
        }
        return ManufacturerBusinessAllProductCard(
          allProducts: inventoryController.allProducts,
        );
      }),
    );
  }
}
