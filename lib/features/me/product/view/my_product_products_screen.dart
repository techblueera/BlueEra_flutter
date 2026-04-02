import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/widget/own_product_card.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_text_cm.dart';

class MyProductProductsScreen extends StatefulWidget {
  final String userId;
  final List<ProductNestedCategoryResponse> arrCategories;

  const MyProductProductsScreen({
    super.key,
    required this.userId,
    required this.arrCategories,
  });

  @override
  State<MyProductProductsScreen> createState() =>
      _MyProductProductsScreenState();
}

class _MyProductProductsScreenState extends State<MyProductProductsScreen> {
  final controller = getOrPut(() => InventoryController());
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedProductCategoryData.value =
          widget.arrCategories.first;
      getProducts();
    });
    super.initState();
  }

  void _onScrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !controller.isProductByCategoryLoadingMore.value &&
        controller.productByCategoryHasMore) {
      getProducts(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  void getProducts({bool isLoadMore = false}) {
    final String categoryId =
        controller.selectedProductCategoryData.value?.sId ?? '';

    controller.fetchProductsByCategory(
      categoryId: categoryId,
      isLoadMore: isLoadMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        isCustomTitleWidget: () => Obx(() {
          final bool isOpen = controller.isProductSearchOpen.value;

          return Expanded(
            child: isOpen
                ? CommonSearchBar(
                    controller: searchController,
                    isShowCursor: true,
                    onClearCallback: () {
                      searchController.clear();
                    },
                    hintText: "Search products...",
                  )
                : CustomText(
                    controller.selectedProductCategoryData.value?.name ??
                        "Products",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
          );
        }),
        buildCustomActionWidget: () =>
            (widget.userId == userId)
                ? Obx(() {
                    final bool isOpen = controller.isProductSearchOpen.value;

                    return InkWell(
                      onTap: () {
                        controller.isProductSearchOpen.value = !isOpen;
                        if (!controller.isProductSearchOpen.value) {
                          searchController.clear();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Icon(
                          isOpen
                              ? Icons.search_off_outlined
                              : Icons.search_outlined,
                          color: AppColors.black,
                          size: 24,
                        ),
                      ),
                    );
                  })
                : const SizedBox.shrink(),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftCategoryList(),
          Expanded(child: rightContent()),
        ],
      ),
    );
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<ProductNestedCategoryResponse>(
      items: widget.arrCategories,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
          controller.selectedProductCategoryData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrCategories[index];
        if (controller.selectedProductCategoryData.value?.sId ==
            selected.sId) {
          return;
        }
        controller.selectedProductCategoryData.value = selected;
        getProducts();
      },
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(4),
          child: controller.isProductByCategoryFirstLoading.value
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : controller.productsByCategoryList.isNotEmpty
                  ? MasonryGridView.count(
                      itemCount: controller.productsByCategoryList.length +
                          (controller.isProductByCategoryLoadingMore.value
                              ? 1
                              : 0),
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom:
                            SizeConfig.size15 + kBottomNavigationBarHeight,
                      ),
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      itemBuilder: (BuildContext context, int index) {
                        if (index >=
                            controller.productsByCategoryList.length) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }

                        final product =
                            controller.productsByCategoryList[index];

                        return OwnProductCard(
                          product: product,
                          deleteProductApi: () {
                            controller.deleteProduct();
                          },
                          isGridShow: true,
                        );
                      },
                    )
                  : Padding(
                      padding: EdgeInsets.all(SizeConfig.size20),
                      child: EmptyStateWidget(
                        message: 'No products found.',
                      ),
                    ),
        ));
  }
}
