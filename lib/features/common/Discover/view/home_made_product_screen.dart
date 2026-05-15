import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/me/product/view/customer/store_product_card.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeMadeProductScreen extends StatefulWidget {
  final bool isShowInGrid;

  const HomeMadeProductScreen({super.key, this.isShowInGrid = false});

  @override
  State<HomeMadeProductScreen> createState() => _HomeMadeProductScreenState();
}

class _HomeMadeProductScreenState extends State<HomeMadeProductScreen> {
  final controller = getOrPut(() => DiscoverController());
  final List<CollapsibleGridModel> _homeMadeProductCategories =
      homeMadeProductsCategories;
  ProviderType _providerType = ProviderType.user;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-table-full-delicious-food-composition_23-2149141353.jpg?w=1380",
    "https://img.freepik.com/free-photo/flat-lay-batch-cooking-composition_23-2148765597.jpg?w=1380",
    "https://img.freepik.com/free-photo/home-made-food-concept-with-salad_23-2148580246.jpg?w=1380",
  ];

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      clearSelectedCategory();
      controller.getAllProductNearBy(
        providerType: _providerType,
      );
    });
  }

  void clearSelectedCategory() {
    controller.selectedEarnServiceData.value = null;
    controller.selectedTabIndex.value = 0;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.getAllProductNearBy(
          providerType: _providerType, isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = _homeMadeProductCategories
        .map((c) => StickyCategory(
      id: c.slugId,
      name: c.name,
      imageUrl: c.icon,
    ))
        .toList();

    OnboardingCategoryModel _asOnboardingCategory(CollapsibleGridModel c) =>
        OnboardingCategoryModel(
          name: c.name,
          slugId: c.slugId,
          accountType: AppConstants.individual,
          icon: c.icon,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor:
                    AppColors.blue5CAF.withValues(alpha: 0.1),
                    bottomBorderSide: const BorderSide(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: stickyCategories,
                    selectedId:
                    controller.selectedEarnServiceData.value?.slugId ??
                        stickyCategories.first.id,
                    onCategoryTap: (item) {
                      final index = stickyCategories
                          .indexWhere((c) => c.id == item.id);
                      controller.selectedTabIndex.value = index;
                      controller.selectedEarnServiceData.value =
                          _asOnboardingCategory(
                        _homeMadeProductCategories
                            .firstWhere((c) => c.slugId == item.id),
                      );
                      controller.getAllProductNearBy(
                        providerType: _providerType,
                      );
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ],
              body: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: rightContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BookViaBlueEraPartnerBanner(onTap: () {}),
          SizedBox(height: SizeConfig.size8),
          HorizontalTabSelector<CategoryFilter>(
            tabs: controller.filters,
            selectedIndex:
            controller.filters.indexOf(controller.selectedFilter.value),
            horizontalMargin: 0.0,
            verticalMargin: 2.0,
            onTabSelected: (index, _) {
              final selectedEnum = controller.filters[index];
              if (controller.selectedFilter.value == selectedEnum) return;
              controller.selectedFilter.value = selectedEnum;
            },
            labelBuilder: (r) => r.localizedLabel,
            unSelectedBackgroundColor: AppColors.white,
          ),
          Expanded(
            child: Obx(() {
              if (controller.isProductDataFirstLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Drop entries that StoreProductCard would render as an
              // empty SizedBox (product.details == null). Otherwise those
              // slots appear as blank cards in the grid — the cause of
              // the "nothing showing at index 0 / some indices" issue.
              final productList = controller.productDataList
                  .where((d) => d.product.details != null)
                  .toList();

              if (productList.isEmpty) {
                return EmptyStateWidget(
                    message: AppStrings.notFoundAnyProduct);
              }

              return _buildTwoColumnGrid(productList);
            }),
          )
        ],
      ),
    ));
  }

  /// Two-column grid using the same pattern as all_business_products_screen:
  /// IntrinsicHeight + CrossAxisAlignment.stretch so both cards in a row
  /// share the taller card's height — one-line names render with
  /// whitespace below while the row gap stays constant.
  Widget _buildTwoColumnGrid(List<GetProductData> products) {
    final rowCount = (products.length / 2).ceil();
    final hasLoadMore = controller.isProductDataLoadingMore.value;
    final totalItems = rowCount + (hasLoadMore ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.only(
        top: SizeConfig.size8,
        bottom: SizeConfig.paddingL,
      ),
      itemCount: totalItems,
      itemBuilder: (context, rowIdx) {
        if (rowIdx >= rowCount) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final leftIdx = rowIdx * 2;
        final rightIdx = leftIdx + 1;
        final Widget leftCell = StoreProductCard(
          productStore: products[leftIdx].product,
          isShowInGrid: true,
        );
        final Widget rightCell = rightIdx < products.length
            ? StoreProductCard(
                productStore: products[rightIdx].product,
                isShowInGrid: true,
              )
            : const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: leftCell),
                const SizedBox(width: 8),
                Expanded(child: rightCell),
              ],
            ),
          ),
        );
      },
    );
  }
}
