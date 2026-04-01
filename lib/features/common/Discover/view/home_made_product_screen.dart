import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:get/get.dart';

class HomeMadeProductScreen extends StatefulWidget {
  final bool isShowInGrid;
  const HomeMadeProductScreen({super.key, this.isShowInGrid = false});

  @override
  State<HomeMadeProductScreen> createState() => _HomeMadeProductScreenState();
}

class _HomeMadeProductScreenState extends State<HomeMadeProductScreen> {
  final controller = getOrPut(() => DiscoverController());
  final List<OnboardingCategoryModel> _homeMadeProductCategories = homeMadeProductCategories;
  ScrollController _scrollController = ScrollController();
  ProviderType _providerType =  ProviderType.user;

  @override
  initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      clearSelectedCategory();
      controller.getAllProductNearBy(
          providerType: _providerType,
      );

      // Listener for Pagination
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          controller.getAllProductNearBy(
              providerType: _providerType,
              isLoadMore: true);
        }
      });
    });
  }

  void clearSelectedCategory(){
    controller.selectedEarnServiceData.value = null;
    controller.selectedTabIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(buildCustomActionWidget: () => const DiscoverCartIcon()),
      body: SafeArea(
        child: Column(
          children: [

            BookViaBlueEraPartnerBanner(
              onTap: () {
                // your navigation here
              },
            ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftCategoryList(),
                  SizedBox(
                    width: SizeConfig.size6,
                  ),
                  Expanded(
                      child: rightContent()
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: _homeMadeProductCategories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item)=> controller.selectedEarnServiceData.value?.slugId == item.slugId,
      onTap: (item, index) {
        controller.selectedTabIndex.value = index;
        controller.selectedEarnServiceData.value = item;
        controller.getAllProductNearBy(
          providerType: _providerType,
        );
      },
    );
  }


  Widget rightContent() {
    return Obx(()=> Padding(
      padding: EdgeInsets.only(right: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HorizontalTabSelector<CategoryFilter>(
            tabs: controller.filters,
            selectedIndex: controller.filters.indexOf(controller.selectedFilter.value),
            horizontalMargin: 0.0,
            onTabSelected: (index, _) {
              final selectedEnum = controller.filters[index];

              if (controller.filters == selectedEnum) return;

              controller.selectedFilter.value = selectedEnum;
              // controller.callApi();
            },
            labelBuilder: (r) => r.label,
            unSelectedBackgroundColor: AppColors.white,
          ),

          SizedBox(
            height: SizeConfig.size5,
          ),

          Expanded(
            child: Obx(() {
              if (controller.isProductDataFirstLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final productList = List<GetProductData>.from(controller.productDataList);

              if (productList.isEmpty) {
                return EmptyStateWidget(
                  message: AppStrings.notFoundAnyProduct
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
                    controller: _scrollController,
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
                controller: _scrollController,
                padding: EdgeInsets.zero,
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
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: StoreProductCard(
                      productStore: productData.product,
                      isShowInGrid: widget.isShowInGrid,
                    ),
                  );
                },
              );
            }),
          )

        ],
      ),
    ));
  }

}
