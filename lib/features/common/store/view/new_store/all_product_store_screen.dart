import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllProductScreen extends StatefulWidget {
  final bool isShowInGrid;
  final ProviderType providerType;
  final String? productCategory;

  const AllProductScreen({
    super.key,
    required this.isShowInGrid,
    required this.providerType,
    this.productCategory,
  });

  @override
  State<AllProductScreen> createState() => _AllProductScreenState();
}

class _AllProductScreenState extends State<AllProductScreen> {
  final controller = Get.isRegistered<NewStoreController>()
      ? Get.find<NewStoreController>()
      : Get.put(NewStoreController());
  final ScrollController storesScrollController = ScrollController();
  late ProviderType _providerType;
  String? _productCategory;

  @override
  void initState() {
    _providerType = widget.providerType;
    _productCategory = widget.productCategory;
    controller.getAllProductNearBy(
        providerType: _providerType,
        productCategory: _productCategory
    );
    super.initState();

    storesScrollController.addListener(() {
      if (storesScrollController.position.pixels >=
          storesScrollController.position.maxScrollExtent - 200) {
        controller.getAllProductNearBy(
            providerType: _providerType,
            productCategory: _productCategory,
            isLoadMore: true
        );
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
        title: AppStrings.tab_product
      ),

      body: SafeArea(
        child: Obx(() {
          // First time loading
          if (controller.isProductDataFirstLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final productList = List<GetProductData>.from(controller.productDataList);

          // Empty state
          if (productList.isEmpty) {
            return Center(
              child: CustomText(
                  AppStrings.notFoundAnyProduct,
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700
              ),
            );
          }

          return widget.isShowInGrid
              ? LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = 2;
              final crossSpacing = 10.0;
              final mainSpacing = 10.0;

              final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
              final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

              final approximateItemHeight = SizeConfig.size265;

              final childAspectRatio = itemWidth / approximateItemHeight;

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
                (controller.isProductDataLoadingMore.value ? 1 : 0),
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
