import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_business_all_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart' show CommonBackAppBar;
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AutomotiveInventoryBusinessCardsScreen extends StatefulWidget {
  final bool showBackAppBar;
  const AutomotiveInventoryBusinessCardsScreen({super.key, this.showBackAppBar = true});

  @override
  State<AutomotiveInventoryBusinessCardsScreen> createState() =>
      _AutomotiveInventoryBusinessCardsScreenState();
}

class _AutomotiveInventoryBusinessCardsScreenState
    extends State<AutomotiveInventoryBusinessCardsScreen> {
  final inventoryController = getOrPut(() => AutomotiveInventoryController());

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
        return AutomotiveBusinessAllProductCard(
          allProducts: inventoryController.allProducts,
        );
      }),
    );
  }
}
