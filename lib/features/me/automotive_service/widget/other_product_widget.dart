import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/own_product_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherProductWidget extends StatefulWidget {
  const OtherProductWidget({super.key});

  @override
  State<OtherProductWidget> createState() => _OtherProductWidgetState();
}

class _OtherProductWidgetState extends State<OtherProductWidget> {
  late final InventoryController inventoryController;

  @override
  void initState() {
    super.initState();

    // 1. Get or Create the controller
    if (Get.isRegistered<InventoryController>()) {
      inventoryController = Get.find<InventoryController>();
    } else {
      inventoryController = Get.put(InventoryController());
    }

    // 2. Always call the API after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apiCalling();
    });
  }

  apiCalling() async {
    inventoryController.isProductLoading.value = true;
    // Pass 'false' to ensure data goes into liveProducts
    await inventoryController.fetchProducts(isDraftProduct: false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return (inventoryController.isProductLoading.value)
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : inventoryController.ownDraftAndPublicProductResponse.value.status ==
                  Status.COMPLETE
              ? inventoryController.liveProducts.isNotEmpty
                  ? LayoutBuilder(
                    builder: (context, constraints) {
                      // Two columns
                      final crossAxisCount = 2;
                      final crossSpacing = 10.0;
                      final mainSpacing = 10.0;

                      final totalHorizontalSpacing =
                          (crossAxisCount - 1) * crossSpacing;
                      final itemWidth =
                          (constraints.maxWidth - totalHorizontalSpacing) /
                              crossAxisCount;

                      final approximateItemHeight = SizeConfig.size240;

                      final childAspectRatio =
                          itemWidth / approximateItemHeight;

                      return Container(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: inventoryController.liveProducts.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: crossSpacing,
                            mainAxisSpacing: mainSpacing,
                            childAspectRatio: childAspectRatio,
                          ),
                          padding: EdgeInsets.only(

                            top: SizeConfig.size8,
                          ),
                          itemBuilder: (context, index) {
                            final product =
                                inventoryController.liveProducts[index];
                            return OwnProductCard(
                                deleteProductApi: () {
                                  inventoryController.deleteProduct();
                                },
                                product: product,
                                width: itemWidth,
                                isGridShow: true);
                          },
                        ),
                      );
                    },
                  )
                  : Center(
                      child: EmptyStateWidget(
                          message: 'Product is empty\nCreate your own product'))
              : SizedBox();
    });
  }
}
