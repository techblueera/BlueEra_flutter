import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AllProductStoreScreen extends StatefulWidget {
  final bool isShowInGrid;
  final ProviderType? providerType;
  final String? productCategoryName;
  final String? productCategory;

  const AllProductStoreScreen({
    super.key,
    required this.isShowInGrid,
    this.providerType,
    this.productCategoryName,
    this.productCategory,
  });

  @override
  State<AllProductStoreScreen> createState() => _AllProductStoreScreenState();
}

class _AllProductStoreScreenState extends State<AllProductStoreScreen> {
  final controller = getOrPut(() => DiscoverController());
  final ScrollController storesScrollController = ScrollController();
  ProviderType? _providerType;
  String? _productCategory;
  String? _productCategoryName;

  @override
  void initState() {
    super.initState();
    _providerType = widget.providerType;
    _productCategory = widget.productCategory;
    _productCategoryName = widget.productCategoryName;
    controller.getAllProductNearBy(
        providerType: _providerType,
        productCategory: _productCategory
    );

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
            return EmptyStateWidget(
              message: _productCategoryName==null
                      ? AppStrings.notFoundAnyProduct
                      : 'Not found ${_productCategoryName} related product',
            );
          }

          return widget.isShowInGrid
              ? LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = 2;
              final crossSpacing = 10.0;
              final mainSpacing = 10.0;

              // final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
              // final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;
              //
              // final approximateItemHeight = SizeConfig.size265;
              //
              // final childAspectRatio = itemWidth / approximateItemHeight;

              return MasonryGridView.count(
                controller: storesScrollController,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: SizeConfig.size15
                ),
                // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //   crossAxisCount: crossAxisCount,
                //   crossAxisSpacing: crossSpacing,
                //   mainAxisSpacing: mainSpacing,
                //   mainAxisExtent: SizeConfig.size265,
                //   // childAspectRatio: childAspectRatio,
                // ),
                itemCount: productList.length +
                    (controller.isProductDataLoadingMore.value ? 1 : 0),
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
