import 'dart:developer';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_floating_cart.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_product_select_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class GroceryProductsSelectionScreen extends StatefulWidget {
  final List<GroceryNestedCategoryModel> arrGroceries;

   GroceryProductsSelectionScreen({
     super.key,
     required this.arrGroceries,
   });

  @override
  State<GroceryProductsSelectionScreen> createState() => _GroceryProductsSelectionScreenState();
}

class _GroceryProductsSelectionScreenState extends State<GroceryProductsSelectionScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedGroceryData.value = widget.arrGroceries.first;
      controller.fetchBoth();
      // Same set the rails use — this grid shows the same cards, so it needs
      // the same "already added" answer.
      controller.fetchStockedVariantIdsIfNeeded();
    });
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
          !controller.isGroceryCategoryProductsLoadingMore.value &&
             controller.groceryCategoryProductsHasMore) {
      controller.fetchGroceryCategoryProducts(
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
        isCustomTitleWidget: () => Obx(() {
          final name = controller.selectedGroceryData.value?.name ?? '';
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        isShadowShow: false,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Icon(Icons.search),
        ),
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftCategoryList(),
              Expanded(child: rightContent()),
            ],
          ),
          // Floating cart
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GroceryFloatingCart(controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: widget.arrGroceries,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
      controller.selectedGroceryData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrGroceries[index];
        log('new selection ${controller.selectedGroceryData.value}');

        if (controller.selectedGroceryData.value?.sId == selected.sId) {
          return;
        }

        controller.selectedGroceryData.value = selected;
        controller.selectedHorizontalTabIndex.value = 0;

        /// api call
        controller.fetchBoth();
      },
    );
  }

  Widget rightContent() {
    return Obx(()=> Padding(
      padding: const EdgeInsets.all(8),
      child: controller.isInitialLoading.value
          ? Center(
                child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Max Limit Error
          if (controller.isMaxLimitHit)
            Container(
              width: SizeConfig.screenWidth,
              decoration: BoxDecoration(
                color: AppColors.redBE,
                borderRadius: BorderRadius.circular(10.0)
              ),
              margin: EdgeInsets.only(bottom: SizeConfig.size10),
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size4,
                horizontal: SizeConfig.size10
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.warningOutlineIcon,
                      width: SizeConfig.size20,
                      height: SizeConfig.size20
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.groceryViewMaxLimitWarning.trParams({'count': '${controller.maxLimit}'}),
                      color: AppColors.redLite,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ),

          // TABS
          Obx(() {
            final List<dynamic> tabData = [AppStrings.groceryViewAll.tr, ...controller.selectedGroceryData.value?.children??[]];

            return HorizontalTabSelector<dynamic>(
              tabs: tabData,
              selectedIndex: controller.selectedHorizontalTabIndex.value,
              labelBuilder: (item) => (item is String) ? item : (item.name ?? ""),
              horizontalPadding: 8,
              verticalPadding: 6,
              verticalMargin: 0,
              horizontalMargin: 0,
              unSelectedBackgroundColor: AppColors.white,
              unSelectedBorderColor: AppColors.greyE5,
              onTabSelected: (index, label) {
                controller.selectedHorizontalTabIndex.value = index;
                controller.fetchGroceryCategoryProducts();
              },
            );
          }),

          SizedBox(height: 8),

          // GRID
          Expanded(
            child: controller.isGroceryCategoryProductsLoading.value
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: SizedBox(
                    height: 20.0,
                    width: 20.0,
                    child: CircularProgressIndicator()
                ),
              ),
            )
                : controller.arrGroceryCategoryProducts.isNotEmpty
                ? MasonryGridView.count(
              controller: scrollController,
              itemCount: controller.arrGroceryCategoryProducts.length +
                  (controller.isGroceryCategoryProductsLoadingMore.value ? 1 : 0),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: EdgeInsets.only(
                bottom: controller.selectedGroceries.isNotEmpty
                    ? SizeConfig.size80
                    : SizeConfig.size30,
              ),
              itemBuilder: (_, i) {
                if (i == controller.arrGroceryCategoryProducts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                return GroceryProductSelectCard(
                  product: controller.arrGroceryCategoryProducts[i],
                  controller: controller,
                );
              },
            )
                : Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: EmptyStateWidget(
                    message: AppStrings.groceryViewNoXFound.trParams({'name': controller.currentTabName.tr}))
            ),
          )

        ],
      ),
    ));
  }

}
