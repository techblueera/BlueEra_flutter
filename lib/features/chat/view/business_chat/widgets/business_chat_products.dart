import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_top_selling_tile.dart';
import 'package:BlueEra/features/me/product/view/customer/customer_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_products_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Products tab inside a business conversation. Mirrors the Top Selling +
/// Categories UI of `VisitProductStoreDetailsScreen`, but view-only — the cart
/// system (add-to-cart overlay + cart bar) is intentionally left out here; it
/// lives only on the dedicated store/visit screens.
class BusinessChatProducts extends StatefulWidget {
  final String businessId;
  final String conversationId;

  const BusinessChatProducts(
      {super.key, required this.businessId, required this.conversationId});

  @override
  State<BusinessChatProducts> createState() => _BusinessChatProductsState();
}

class _BusinessChatProductsState extends State<BusinessChatProducts> {
  final InventoryController controller =
      getOrPut<InventoryController>(() => InventoryController());

  @override
  void initState() {
    super.initState();
    // Load the visited business's products + categories (same call the visit
    // store screen makes).
    controller.fetchAllProductData(visitUserId: widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: SizeConfig.size20),
      child: Column(
        children: [
          // ─── Top Selling Products (preview of 20) ───
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

          // ─── Categories ───
          Obx(() {
            if (controller.fetchProductCategoryResponse.value.status ==
                Status.INITIAL) {
              return buildCategoryGridSkeleton();
            }
            return _categoryWithInventoryWidget();
          }),
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
                    visitUserId: widget.businessId,
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
                        // View-only: no cart overlay (cart stays on the store
                        // screens).
                        Expanded(
                          child: ProductTopSellingImage(product: product),
                        ),
                        ProductTopSellingInfoSection(product: product),
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
  //  CATEGORY GRID (view-only)
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
                            visitBusinessId: widget.businessId,
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
