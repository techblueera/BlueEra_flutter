import 'dart:developer';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/common/store/view/business_store_card.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AllProductStoreScreen extends StatefulWidget {
  final bool isShowInGrid;
  const AllProductStoreScreen({
    super.key,
    required this.isShowInGrid
  });

  @override
  State<AllProductStoreScreen> createState() => _AllProductStoreScreenState();
}

class _AllProductStoreScreenState extends State<AllProductStoreScreen> {
  final controller = Get.isRegistered<NewStoreController>()
      ? Get.find<NewStoreController>()
      : Get.put(NewStoreController());
  final ScrollController storesScrollController = ScrollController();


  @override
  void initState() {

    controller.getAllStoreProductNearBy();
    super.initState();

    storesScrollController.addListener(() {
      if (storesScrollController.position.pixels >=
          storesScrollController.position.maxScrollExtent - 200) {
        controller.getAllStoreProductNearBy(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    storesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.screenWidth;

    double dynamicSize(double base) =>
        base * (width / 390);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Product'
      ),

      body: SafeArea(
        child: Obx(() {
          // First time loading
          if (controller.isStoreProductDataFirstLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final productList = List<GetProductData>.from(controller.storeProductDataList);

          // Empty state
          if (productList.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CustomText(AppStrings.notFoundAnyProduct),
              ),
            );
          }

          return widget.isShowInGrid
              ? LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = 2;
              final crossSpacing = 10.0;
              final mainSpacing = 15.0;

              final childAspectRatio = 0.8; // Adjust this value as needed

              return GridView.builder(
                controller: storesScrollController,
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: SizeConfig.size15
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossSpacing,
                  mainAxisSpacing: mainSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: productList.length +
                    (controller.isFoodDataLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= productList.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final productData = productList[index];

                  return StoreProductCard(
                    productStore: productData.product,
                    isShowInGrid: widget.isShowInGrid,
                  );
                },
              );
            },
          ) : ListView.builder(
            controller: storesScrollController,
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size15
            ),
            itemCount: productList.length +
                (controller.isStoreProductDataLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              // Pagination Loader
              if (index >= productList.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final productData = productList[index];

              return Padding(
                padding: EdgeInsets.only(bottom: dynamicSize(10)),
                child: StoreProductCard(
                    productStore: productData.product,
                    isShowInGrid: widget.isShowInGrid,
                ),
              );
            },
          );
        }),
      ),
    );
  }

}
