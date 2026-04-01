import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/grocery_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/view_cart_footer.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class AllGroceryProductsScreen extends StatefulWidget {
  final List<GroceryNestedCategoryModel> argSubCategory;

  AllGroceryProductsScreen({
    super.key,
    required this.argSubCategory,
  });

  @override
  State<AllGroceryProductsScreen> createState() => _AllGroceryProductsScreenState();
}

class _AllGroceryProductsScreenState extends State<AllGroceryProductsScreen> {
  final consumerController = getOrPut(() => GroceryRiderConsumerController());
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  late List<GroceryNestedCategoryModel> subCategory;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
    subCategory= widget.argSubCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      consumerController.selectedGroceryData.value = subCategory.first;
      consumerController.fetchChildrenOfGroceryCategory();
      consumerController.fetchUserGroceries();
    });
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !consumerController.isUserGroceryLoadingMore.value &&
        consumerController.userGroceryHasMore) {
      consumerController.fetchUserGroceries(
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          isShadowShow: false,
          // isCustomTitleWidget: ()=> Obx(() {
          //   final bool isOpen = consumerController.isSearchOpen.value;
          //
          //   return Expanded(
          //     child: isOpen
          //         ? CommonSearchBar(
          //       controller: searchController,
          //       isShowCursor: true,
          //       // onSearchTap: () => controller.fetchGroceryProducts(),
          //       onClearCallback: () {
          //         searchController.clear();
          //         // controller.fetchGroceryProducts();
          //       },
          //       hintText: "Search products...",
          //     )
          //         : CustomText(
          //       consumerController.selectedGroceryData.value?.name ?? "Products",
          //       fontSize: 18,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   );
          // }),
          // buildCustomActionWidget: () =>  Obx(() {
          //   final bool isOpen = consumerController.isSearchOpen.value;
          //
          //   // The Toggle Button is now part of the Title Widget
          //   return InkWell(
          //     onTap: () {
          //       consumerController.isSearchOpen.value = !isOpen;
          //       if (!consumerController.isSearchOpen.value) {
          //         searchController.clear();
          //         // controller.fetchGroceryProducts();
          //       }
          //     },
          //     child: Padding(
          //       padding: const EdgeInsets.only(left: 10, right: 10),
          //       child: Icon(
          //         isOpen ? Icons.search_off_outlined : Icons.search_outlined,
          //         color: AppColors.black,
          //         size: 24,
          //       ),
          //     ),
          //   );
          // }),
        ),
        bottomNavigationBar: ViewCartFooter(),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftCategoryList(),
            Expanded(
                child: rightContent()
            ),
          ],
        ),
    );
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: subCategory,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
      consumerController.selectedGroceryData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = subCategory[index];
        if (consumerController.selectedGroceryData.value?.sId == selected.sId) {
          return;
        }
        consumerController.selectedGroceryData.value = selected;
        consumerController.fetchChildrenOfGroceryCategory();
        consumerController.fetchUserGroceries();
      },
    );
  }

  Widget rightContent() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sub-category tabs ────────────────────────────────────────
          Obx(() {
            // Children still loading
            if (consumerController.isGroceryCategoryOfChildrenLoading.value) {
              return const SizedBox(
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }


            if (consumerController.groceryChildrenWithInventoryCat.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                SizedBox(
                  height: 28,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: consumerController.groceryChildrenWithInventoryCat.length + 1,
                    itemBuilder: (_, i) {
                      final bool selected = consumerController.selectedTabIndex.value == i;
                      final item = i != 0
                          ? consumerController.groceryChildrenWithInventoryCat[i - 1]
                          : null;

                      return InkWell(
                        onTap: () {
                          consumerController.selectedTabIndex.value = i;
                          consumerController.fetchUserGroceries();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryColor : AppColors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: selected
                                ? null
                                : Border.all(color: AppColors.greyLite, width: 0.5),
                          ),
                          child: Center(
                            child: CustomText(
                              i != 0 ? item!.name : 'All',
                              color: selected
                                  ? AppColors.white
                                  : AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }),

          // ── Product grid ─────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              // Loading
              if (consumerController.isUserGroceryLoading.value) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: SizedBox(
                      height: SizeConfig.size30,
                      width: SizeConfig.size30,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              // Empty
              if (consumerController.arrUserGrocery.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(SizeConfig.size20),
                  child: EmptyStateWidget(
                    message: 'No ${consumerController.currentTabName.tr} found.',
                  ),
                );
              }

              return MasonryGridView.count(
                controller: scrollController,
                itemCount:
                consumerController.arrUserGrocery.length +
                    (consumerController.isUserGroceryLoadingMore
                        .value
                        ? 1
                        : 0),
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: EdgeInsets.only(
                    bottom: SizeConfig.size30),
                itemBuilder: (_, i) {
                  if (i == consumerController.arrUserGrocery.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return GroceryProductCard(
                    groceryProducts: consumerController.arrUserGrocery[i],
                    flowType: GroceryCardFlowType.rider,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

}



