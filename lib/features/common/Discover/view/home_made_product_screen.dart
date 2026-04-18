import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
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
  final List<OnboardingCategoryModel> _homeMadeProductCategories =
      homeMadeProductCategories;
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
                          _homeMadeProductCategories
                              .firstWhere((c) => c.slugId == item.id);
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
              HorizontalTabSelector<CategoryFilter>(
                tabs: controller.filters,
                selectedIndex:
                    controller.filters.indexOf(controller.selectedFilter.value),
                horizontalMargin: 0.0,
                verticalMargin: 5.0,
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

                  final productList =
                      List<GetProductData>.from(controller.productDataList);

                  if (productList.isEmpty) {
                    return EmptyStateWidget(
                        message: AppStrings.notFoundAnyProduct);
                  }

                  return widget.isShowInGrid
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = 2;
                            final crossSpacing = 10.0;
                            final mainSpacing = 10.0;

                            final totalHorizontalSpacing =
                                (crossAxisCount - 1) * crossSpacing;
                            final itemWidth = (constraints.maxWidth -
                                    totalHorizontalSpacing) /
                                crossAxisCount;

                            final approximateItemHeight = SizeConfig.size265;

                            final childAspectRatio =
                                itemWidth / approximateItemHeight;

                            return GridView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size8,
                                  vertical: SizeConfig.size15),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: crossSpacing,
                                mainAxisSpacing: mainSpacing,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: productList.length +
                                  (controller.isProductDataLoadingMore.value
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index >= productList.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                        child: CircularProgressIndicator()),
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
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: productList.length +
                              (controller.isProductDataLoadingMore.value
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= productList.length) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child:
                                    Center(child: CircularProgressIndicator()),
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
