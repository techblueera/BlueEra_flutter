import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyProductCardDetails extends StatelessWidget {
  const MyProductCardDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryController = Get.put(InventoryController());

    final productList = inventoryController.allProducts;
    return Obx(() {
      return Column(
        children: [
          (productList.isEmpty)
              ? Center(
                  child: EmptyStateWidget(
                    message: AppStrings.noProductsAvailable,
                  ),
                )
              : SafeArea(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: productList.length,
                    padding: EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final productData = productList[index];

                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: SizeConfig.size8,
                            left: SizeConfig.size8,
                            right: SizeConfig.size8),
                        child: OwnProductCard(
                          product: productData,
                          isGridShow: false,
                          deleteProductApi: () {
                            // earnWithBlueEraController.deleteProduct();
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      );
    });
  }
}
