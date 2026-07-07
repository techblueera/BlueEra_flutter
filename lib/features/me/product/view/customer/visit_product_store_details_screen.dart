import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/view/customer/customer_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_products_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_customer_card.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';

// import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/common_methods.dart';

class VisitProductStoreDetailsScreen extends StatefulWidget {
  final String visitUserId;

  const VisitProductStoreDetailsScreen({
    super.key,
    required this.visitUserId,
  });

  @override
  State<VisitProductStoreDetailsScreen> createState() =>
      _VisitProductStoreDetailsScreenState();
}

class _VisitProductStoreDetailsScreenState
    extends State<VisitProductStoreDetailsScreen> {
  final InventoryController controller =
      getOrPut<InventoryController>(() => InventoryController());
  final ViewBusinessDetailsController viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final StoreController storeController =
      getOrPut<StoreController>(() => StoreController());

  // Session cart — registered by the products entry point. `getOrPut`
  // here returns the same instance the cart bar on the entry point is
  // watching, so add/remove on this screen flows through.
  final ProductSelfPickupController cartController =
      getOrPut<ProductSelfPickupController>(
          () => ProductSelfPickupController());

  @override
  void initState() {
    super.initState();
    // Load the visiting business profile + inventory in parallel, and
    // track the store-detail view (same pattern as the grocery visit
    // screen).
    viewBusinessDetailsController
        .viewBusinessProfileByIdIfNeeded(widget.visitUserId);
    controller.fetchAllProductDataIfNeeded(visitUserId: widget.visitUserId);
    ProfileClickTracker.track(
      userId: widget.visitUserId,
      source: ChatClickSource.storeDetail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              viewBusinessDetailsController
                  .viewBusinessProfileById(widget.visitUserId);
              await controller.fetchAllProductData(
                  visitUserId: widget.visitUserId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size15,
              ),
              child: Column(
                children: [
                  // ─── 1. Header + Business Stats ───
                  Obx(() {
                    // Subscribe to silent profile refreshes — bumps on every
                    // successful fetch so this Obx rebuilds even when the
                    // loader is skipped.
                    viewBusinessDetailsController.profileVersion.value;
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return buildBusinessHeaderSkeleton();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    return Column(
                      children: [
                        VisitBusinessCommonHeader(
                          details: details,
                          onRated: () => viewBusinessDetailsController
                              .viewBusinessProfileById(
                            widget.visitUserId,
                            silent: true,
                          ),
                          onFollowChanged: () => viewBusinessDetailsController
                              .viewBusinessProfileById(
                            widget.visitUserId,
                            silent: true,
                          ),
                          // Encode the owner userId (what this screen expects
                          // as `visitUserId` and what the deep-link handler in
                          // splash_screen.dart passes through) — not the
                          // businessProfile _id.
                          shareLink: shopDeepLink(id: details?.userId),
                        ),
                        const SizedBox(height: 10),
                        VisitBusinessStatsCard(details: details),
                      ],
                    );
                  }),

                  // ─── 2. Top Selling Products (preview of 20) ───
                  Obx(() {
                    if (controller
                            .ownDraftAndPublicProductResponse.value.status ==
                        Status.INITIAL) {
                      return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                        child: buildHorizontalListSkeleton(),
                      );
                    }
                    return controller.allProducts.isNotEmpty
                        ? _topSellingProduct()
                        : const SizedBox.shrink();
                  }),

                  // ─── 3. Categories ───
                  Obx(() {
                    if (controller.fetchProductCategoryResponse.value.status ==
                        Status.INITIAL) {
                      return buildCategoryGridSkeleton();
                    }
                    return _categoryWithInventoryWidget();
                  }),

                  // ─── 4. Live Photos ───
                  Obx(() {
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return const SizedBox.shrink();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    if (details?.livePhotos != null &&
                        details!.livePhotos!.any((p) => p.trim().isNotEmpty)) {
                      return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.paddingM),
                        child: CustomFormCard(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CustomText(
                                'Live Photos',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 10),
                              StoreLivePhotoWidget(
                                livePhotos: details.livePhotos!
                                    .where((p) => p.trim().isNotEmpty)
                                    .toList(),
                                natureOfBusiness:
                                    details.subCategoryDetails?.name ??
                                        details.natureOfBusiness ??
                                        'OTHER',
                                onViewFullScreen: ({
                                  required int index,
                                  required List<String> storeImage,
                                  required String natureOfBusiness,
                                }) {
                                  navigatePushTo(
                                    context,
                                    ImageViewScreen(
                                      appBarTitle: details.businessName ?? '',
                                      subTitle: natureOfBusiness,
                                      imageUrls: storeImage,
                                      initialIndex: index,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // ─── 5. Contact & Map ───
                  Obx(() {
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return const SizedBox.shrink();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    return BusinessContactMapCard(
                      businessProfileDetails: details,
                      showEditButton: false,
                    );
                  }),

                  // ─── 6. QR Code ───
                  // Obx(() {
                  //   if (viewBusinessDetailsController.isProfileLoading.value) {
                  //     return const SizedBox.shrink();
                  //   }
                  //   final details = viewBusinessDetailsController
                  //       .visitedBusinessProfileDetails?.data;
                  //   return BusinessQrCodeWidget(data: details);
                  // }),

                  SizedBox(height: SizeConfig.size100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: ProductSelfPickupCart(controller: cartController),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  TOP SELLING PRODUCTS — horizontal preview (first 20 items)
  // ─────────────────────────────────────────────────────────────────
  Widget _topSellingProduct() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(top: SizeConfig.paddingXSL),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'Top Selling Product',
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              InkWell(
                onTap: () => Get.to(
                  () => CustomerAllTopSellingProductsScreen(
                    visitUserId: widget.visitUserId,
                  ),
                ),
                child: CustomText(
                  'View All',
                  fontSize: SizeConfig.medium,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          SizedBox(
            height: ProductCustomerCard.railCardHeight,
            child: Builder(builder: (context) {
              // Preview only — cap to first 20 items; "View All" opens
              // the paginated grid.
              final previewCount = controller.allProducts.length >
                      InventoryController.ownProductsPreviewLimit
                  ? InventoryController.ownProductsPreviewLimit
                  : controller.allProducts.length;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: previewCount,
                itemBuilder: (context, index) {
                  final product = controller.allProducts[index];
                  // Same card + variants-sheet flow as the products screen,
                  // so the entry point and the category grid present products
                  // identically (mirrors grocery's top-selling rail).
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: SizeConfig.size150,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.greyE5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProductCustomerCard(
                            product: product,
                            cartController: cartController,
                            visitBusinessId: widget.visitUserId,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  CATEGORY GRID (view-only in the visit flow)
  // ─────────────────────────────────────────────────────────────────
  Widget _categoryWithInventoryWidget() {
    final categoryList = controller.productNestedCategoryList;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(top: SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Category',
            fontSize: SizeConfig.large,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          categoryList.isNotEmpty
              ? MasonryGridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  itemCount: categoryList.length,
                  itemBuilder: (context, index) {
                    var categoryItem = categoryList[index];
                    return CommonServiceCard(
                      service: categoryItem,
                      getName: (c) => c.name ?? '',
                      getIcon: (c) => c.image ?? '',
                      iconHeight: SizeConfig.size60,
                      boxShadow: const [],
                      onTap: (c) {
                        Get.to(
                          () => VisitProductProductsScreen(
                            parentCategory: c,
                            visitBusinessId: widget.visitUserId,
                          ),
                        );
                      },
                    );
                  },
                )
              : EmptyStateWidget(
                  message: 'This store has no products yet.',
                ),
          SizedBox(height: SizeConfig.paddingXSL),
        ],
      ),
    );
  }
}
