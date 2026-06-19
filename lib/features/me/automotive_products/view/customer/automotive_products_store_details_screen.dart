import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
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
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_product_top_selling_tile.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_customer_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_visit_product_products_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/widget/automotive_product_self_pickup_cart.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Automotive store-details page. Mirrors [VisitProductStoreDetailsScreen]:
/// business header + stats, top-selling preview, category grid, live photos,
/// contact/map, and a self-pickup cart bar (add-to-cart + place order). All
/// product/category/order calls go through the automotive-service endpoints.
///
/// Keeps the original constructor (`productStore` / `id`) so the existing
/// route builder is unchanged — the seller's user id is derived from the
/// passed product (or `id` as a fallback).
class AutomotiveProductsStoreDetailsScreen extends StatefulWidget {
  final ProductStore? productStore;
  final String? id;
  final ProviderType? providerType;

  const AutomotiveProductsStoreDetailsScreen({
    super.key,
    required this.productStore,
    this.id,
    this.providerType,
  });

  @override
  State<AutomotiveProductsStoreDetailsScreen> createState() =>
      _AutomotiveProductsStoreDetailsScreenState();
}

class _AutomotiveProductsStoreDetailsScreenState
    extends State<AutomotiveProductsStoreDetailsScreen> {
  final AutomotiveInventoryController controller =
      getOrPut<AutomotiveInventoryController>(
          () => AutomotiveInventoryController());
  final ViewBusinessDetailsController viewBusinessDetailsController =
      getOrPut<ViewBusinessDetailsController>(
          () => ViewBusinessDetailsController());
  final StoreController storeController =
      getOrPut<StoreController>(() => StoreController());
  // Session cart — same instance the discover/cart bar watches, so
  // add/remove on this screen flows through.
  final AutomotiveProductSelfPickupController cartController =
      getOrPut<AutomotiveProductSelfPickupController>(
          () => AutomotiveProductSelfPickupController());

  /// Seller's user id — drives the business-profile + inventory fetch.
  late final String _visitUserId =
      (widget.productStore?.user_id ?? '').isNotEmpty
          ? widget.productStore!.user_id!
          : (widget.id ?? '');

  @override
  void initState() {
    super.initState();
    // Load the visiting business profile + inventory in parallel, and
    // track the store-detail view (same pattern as the product visit screen).
    viewBusinessDetailsController.viewBusinessProfileByIdIfNeeded(_visitUserId);
    controller.fetchAllProductDataIfNeeded(visitUserId: _visitUserId);
    ProfileClickTracker.track(
      userId: _visitUserId,
      source: ChatClickSource.storeDetail,
    );
  }

  /// First variant id of a product — the key the cart uses.
  String? _firstVariantId(dynamic product) {
    final variants = product.product.sellerClassification?.variants;
    if (variants == null || variants.isEmpty) return null;
    final id = variants.first.id;
    return id is String && id.isNotEmpty ? id : null;
  }

  void _onToggleTopSellingCart(dynamic product) {
    final id = _firstVariantId(product);
    if (id == null) return;
    final bDetails =
        viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
    if (cartController.isVariantInCart(id)) {
      cartController.removeFromCart(product);
    } else {
      cartController.addToCart(
        product,
        userId: _visitUserId,
        businessName: bDetails?.businessName,
        businessLogo: bDetails?.logo,
        businessAddress: bDetails?.address,
      );
    }
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
                  .viewBusinessProfileById(_visitUserId);
              await controller.fetchAllProductData(visitUserId: _visitUserId);
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
                            .viewBusinessProfileById(_visitUserId, silent: true),
                        onFollowChanged: () => viewBusinessDetailsController
                            .viewBusinessProfileById(_visitUserId, silent: true),
                      ),
                      const SizedBox(height: 10),
                      VisitBusinessStatsCard(details: details),
                    ],
                  );
                }),

                // ─── 2. Top Selling Products (preview of 20) ───
                Obx(() {
                  if (controller.ownDraftAndPublicProductResponse.value.status ==
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

                SizedBox(height: SizeConfig.size100),
              ],
            ),
          ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AutomotiveProductSelfPickupCart(controller: cartController),
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
                  () => AutomotiveCustomerAllTopSellingProductsScreen(
                    visitUserId: _visitUserId,
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
            height: SizeConfig.size240,
            child: Builder(builder: (context) {
              final previewCount = controller.allProducts.length >
                      AutomotiveInventoryController.ownProductsPreviewLimit
                  ? AutomotiveInventoryController.ownProductsPreviewLimit
                  : controller.allProducts.length;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: previewCount,
                itemBuilder: (context, index) {
                  final product = controller.allProducts[index];
                  return Container(
                    width: SizeConfig.size160,
                    margin: const EdgeInsets.only(right: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SizeConfig.size4),
                        Expanded(
                          child: AutomotiveProductTopSellingImage(
                            product: product,
                            cartOverlay: Obx(() {
                              final cart =
                                  cartController.selectedProductVariants;
                              // ignore: unused_local_variable
                              final _ = cart.length;
                              final id = _firstVariantId(product);
                              final added =
                                  cartController.isVariantInCart(id);
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                onPressed: id == null
                                    ? null
                                    : () =>
                                        _onToggleTopSellingCart(product),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: added
                                        ? AppColors.greenShade
                                        : AppColors.blackMite,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    added ? Icons.check : Icons.add,
                                    size: SizeConfig.size16,
                                    color: AppColors.white,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        AutomotiveProductTopSellingInfoSection(product: product),
                      ],
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
                          () => AutomotiveVisitProductProductsScreen(
                            parentCategory: c,
                            visitBusinessId: _visitUserId,
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
