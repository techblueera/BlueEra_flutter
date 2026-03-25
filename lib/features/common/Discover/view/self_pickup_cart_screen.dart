import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfPickUpCartScreen extends StatefulWidget {
  final String deliveryType;
  const SelfPickUpCartScreen({super.key, this.deliveryType = 'SELF'});

  @override
  State<SelfPickUpCartScreen> createState() => _SelfPickUpCartScreenState();
}

class _SelfPickUpCartScreenState extends State<SelfPickUpCartScreen> {
  static const List<Color> _cardColors = [
    Color(0xFFFFFEF7),
    Color(0xFFFFF9F3),
    Color(0xFFFFF5F5),
  ];

  /// Selected (checked) business IDs - all checked by default
  final RxSet<String> selectedBusinessIds = <String>{}.obs;
  bool _initialized = false;

  /// Group variants by businessId, filtered by delivery type
  Map<String, List<ProductVariants>> _groupByBusiness(
      GroceryCustomerController controller) {
    final grouped = controller.groupByBusinessForDeliveryType(widget.deliveryType);
    // Initialize all as checked on first build
    if (!_initialized && grouped.isNotEmpty) {
      selectedBusinessIds.addAll(grouped.keys);
      _initialized = true;
    }
    return grouped;
  }

  /// Calculate total selling price for a list of variants
  double _calcTotal(
      List<ProductVariants> items, GroceryCustomerController controller) {
    double total = 0;
    for (var v in items) {
      int qty = controller.getQuantity(v.sId);
      double sp = double.tryParse(
              v.pricing?.first.sellingPrice.toString() ?? '0') ??
          0;
      total += sp * qty;
    }
    return total;
  }

  /// Calculate total item count for a list of variants
  int _calcItemCount(
      List<ProductVariants> items, GroceryCustomerController controller) {
    int count = 0;
    for (var v in items) {
      count += controller.getQuantity(v.sId);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroceryCustomerController>();

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.mainTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          widget.deliveryType == 'SELF'
              ? 'Self Pick-Up'
              : widget.deliveryType == 'RIDER'
                  ? 'Book Rider'
                  : 'Order Via Partner',
          fontSize: SizeConfig.extraLarge,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.appBackgroundColor, height: 1),
        ),
      ),
      body: Obx(() {
        final variants = controller.variantsByDeliveryType(widget.deliveryType);
        if (variants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppColors.greyCA),
                const SizedBox(height: 16),
                CustomText(
                  widget.deliveryType == 'SELF'
                      ? 'No items in self pick-up'
                      : widget.deliveryType == 'RIDER'
                          ? 'No items in book rider'
                          : 'No items in order via partner',
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          );
        }

        final grouped = _groupByBusiness(controller);
        final businessIds = grouped.keys.toList();

        // For RIDER: show products directly with +/- buttons
        if (widget.deliveryType == 'RIDER') {
          return _buildRiderProductsView(variants, controller, grouped);
        }

        return Column(
          children: [
            // --- Store Cards List ---
            Expanded(
              child: ListView.builder(
                itemCount: businessIds.length,
                padding: EdgeInsets.all(SizeConfig.paddingM),
                itemBuilder: (context, index) {
                  final businessId = businessIds[index];
                  final items = grouped[businessId]!;
                  final businessInfo =
                      controller.cartBusinessInfo[items.first.sId] ?? {};
                  final Color bgColor =
                      _cardColors[index % _cardColors.length];
                  final int productCount =
                      _calcItemCount(items, controller);
                  final double storeTotal =
                      _calcTotal(items, controller);

                  return _StoreCard(
                    businessName:
                        businessInfo['businessName'] ?? 'Unknown Store',
                    businessLogo: businessInfo['logo'] ?? '',
                    businessAddress: businessInfo['address'] ?? '',
                    productCount: productCount,
                    storeTotal: storeTotal,
                    bgColor: bgColor,
                    onManageProducts: () {
                      _showProductsBottomSheet(
                        context,
                        businessName:
                            businessInfo['businessName'] ?? 'Unknown Store',
                        items: items,
                        controller: controller,
                      );
                    },
                  );
                },
              ),
            ),

            // --- Bottom Bar: Grand Total + Per-shop totals + Submit ---
            _BottomSummaryBar(
              grouped: grouped,
              controller: controller,
              calcTotal: _calcTotal,
              calcItemCount: _calcItemCount,
              selectedBusinessIds: selectedBusinessIds,
              deliveryType: widget.deliveryType,
            ),
          ],
        );
      }),
    );
  }

  void _showProductsBottomSheet(
    BuildContext context, {
    required String businessName,
    required List<ProductVariants> items,
    required GroceryCustomerController controller,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductsBottomSheet(
        businessName: businessName,
        items: items,
        controller: controller,
      ),
    );
  }

  /// Rider view: show all products directly with +/- buttons and summary footer
  Widget _buildRiderProductsView(
    List<ProductVariants> allVariants,
    GroceryCustomerController controller,
    Map<String, List<ProductVariants>> grouped,
  ) {
    // Calculate totals
    int totalProducts = 0;
    double totalAmount = 0;
    for (var v in allVariants) {
      int qty = controller.getQuantity(v.sId);
      totalProducts += qty;
      double sp = double.tryParse(
              v.pricing?.first.sellingPrice.toString() ?? '0') ??
          0;
      totalAmount += sp * qty;
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15,
              vertical: SizeConfig.size8,
            ),
            itemCount: allVariants.length + 1, // +1 for summary footer
            itemBuilder: (context, index) {
              if (index == allVariants.length) {
                // --- Summary Footer ---
                return Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 18, color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          CustomText(
                            '$totalProducts ${totalProducts == 1 ? 'Product' : 'Products'}',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                      CustomText(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                );
              }

              final variant = allVariants[index];
              return _RiderVariantItem(
                variant: variant,
                controller: controller,
              );
            },
          ),
        ),

        // --- Bottom Bar ---
        _RiderBottomBar(
          totalProducts: totalProducts,
          totalAmount: totalAmount,
          controller: controller,
          deliveryType: widget.deliveryType,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RIDER VARIANT ITEM - Product card with +/- buttons
// ═══════════════════════════════════════════════════════════════════

class _RiderVariantItem extends StatelessWidget {
  final ProductVariants variant;
  final GroceryCustomerController controller;

  const _RiderVariantItem({
    required this.variant,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final sellingPrice = variant.pricing?.first.sellingPrice ?? 0;
    final mrp = variant.pricing?.first.mrp ?? 0;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        children: [
          /// Variant Image
          (variant.images != null && variant.images!.isNotEmpty)
              ? CustomImageSlideshow(
                  isLoading: false,
                  width: SizeConfig.size50,
                  height: SizeConfig.size50,
                  imagePaths:
                      variant.images!.map((i) => i.url ?? '').toList(),
                  borderRadius: BorderRadius.circular(6),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.fill,
                    width: SizeConfig.size50,
                    height: SizeConfig.size50,
                  ),
                ),

          SizedBox(width: SizeConfig.paddingXSL),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText('${variant.quantity}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 0.5,
                      height: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText('₹$sellingPrice',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(width: SizeConfig.size6),
                    CustomText('₹$mrp',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: SizeConfig.paddingXSL),

          /// Dashed Border
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(
              height: SizeConfig.size50,
              width: 1,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Actions: price + qty buttons
          Obx(() {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText('₹$sellingPrice',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(width: SizeConfig.size4),
                    CustomText('₹$mrp',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                  ],
                ),
                SizedBox(height: SizeConfig.size4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: AppColors.white,
                    border: Border.all(color: AppColors.greyE5),
                    boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                controller.removeFromCart(variant),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primaryColor
                                .withValues(alpha: 0.2),
                            highlightColor: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Icon(Icons.remove,
                                    color: AppColors.secondaryTextColor,
                                    size: SizeConfig.size12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      CustomText(
                        '${controller.getQuantity(variant.sId)}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.addToCart(variant),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primaryColor
                                .withValues(alpha: 0.2),
                            highlightColor: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Icon(Icons.add,
                                    size: SizeConfig.size12,
                                    color: AppColors.secondaryTextColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RIDER BOTTOM BAR - Total + Submit
// ═══════════════════════════════════════════════════════════════════

class _RiderBottomBar extends StatelessWidget {
  final int totalProducts;
  final double totalAmount;
  final String deliveryType;
  final GroceryCustomerController controller;

  const _RiderBottomBar({
    required this.totalProducts,
    required this.totalAmount,
    required this.controller, required this.deliveryType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      '$totalProducts ${totalProducts == 1 ? 'Product' : 'Products'}',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      fontSize: SizeConfig.extraLarge,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: totalProducts > 0
                      ? () => controller.addGroceryOrderApi()
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: totalProducts > 0
                          ? AppColors.primaryColor
                          : AppColors.greyCA,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: totalProducts > 0
                          ? [
                              BoxShadow(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: CustomText(
                      deliveryType == 'RIDER'?"Search Riders": 'Submit Order',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM SUMMARY BAR - Grand total, per-shop totals, submit
// ═══════════════════════════════════════════════════════════════════

class _BottomSummaryBar extends StatelessWidget {
  final Map<String, List<ProductVariants>> grouped;
  final GroceryCustomerController controller;
  final double Function(List<ProductVariants>, GroceryCustomerController)
      calcTotal;
  final int Function(List<ProductVariants>, GroceryCustomerController)
      calcItemCount;
  final RxSet<String> selectedBusinessIds;
  final String deliveryType;

  const _BottomSummaryBar({
    required this.grouped,
    required this.controller,
    required this.calcTotal,
    required this.calcItemCount,
    required this.selectedBusinessIds,
    this.deliveryType = 'SELF',
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Calculate grand totals only for checked shops
      double grandTotal = 0;
      int grandItemCount = 0;
      int selectedShopCount = 0;
      for (var entry in grouped.entries) {
        if (selectedBusinessIds.contains(entry.key)) {
          grandTotal += calcTotal(entry.value, controller);
          grandItemCount += calcItemCount(entry.value, controller);
          selectedShopCount++;
        }
      }

      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Per-shop breakdown with checkboxes ---
                ...grouped.entries.map((entry) {
                  final businessId = entry.key;
                  final items = entry.value;
                  final businessInfo =
                      controller.cartBusinessInfo[items.first.sId] ?? {};
                  final shopName =
                      businessInfo['businessName'] ?? 'Unknown Store';
                  final shopTotal = calcTotal(items, controller);
                  final shopItems = calcItemCount(items, controller);
                  final isChecked =
                      selectedBusinessIds.contains(businessId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {
                        if (isChecked) {
                          selectedBusinessIds.remove(businessId);
                        } else {
                          selectedBusinessIds.add(businessId);
                        }
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (val) {
                                if (val == true) {
                                  selectedBusinessIds.add(businessId);
                                } else {
                                  selectedBusinessIds.remove(businessId);
                                }
                              },
                              activeColor: AppColors.primaryColor,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              '$shopName ($shopItems ${shopItems == 1 ? 'item' : 'items'})',
                              fontSize: SizeConfig.small,
                              color: isChecked
                                  ? AppColors.secondaryTextColor
                                  : AppColors.greyCA,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CustomText(
                            '₹${shopTotal.toStringAsFixed(2)}',
                            fontSize: SizeConfig.small,
                            color: isChecked
                                ? AppColors.mainTextColor
                                : AppColors.greyCA,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const Divider(height: 16, color: AppColors.greyE5),

                // --- Grand total row (only checked shops) ---
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            '$selectedShopCount ${selectedShopCount == 1 ? 'Shop' : 'Shops'} | $grandItemCount ${grandItemCount == 1 ? 'Product' : 'Products'}',
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            fontSize: SizeConfig.extraLarge,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: selectedShopCount > 0
                            ? () {
                                if (deliveryType == 'RIDER') {
                                  controller.addGroceryOrderApi();
                                } else {
                                  controller.placeBulkGroceryOrderApi();
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedShopCount > 0
                                ? AppColors.primaryColor
                                : AppColors.greyCA,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: selectedShopCount > 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: CustomText(
                            'Submit Order',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STORE CARD - Business details with product count + Manage btn
// ═══════════════════════════════════════════════════════════════════

class _StoreCard extends StatelessWidget {
  final String businessName;
  final String businessLogo;
  final String businessAddress;
  final int productCount;
  final double storeTotal;
  final Color bgColor;
  final VoidCallback onManageProducts;

  const _StoreCard({
    required this.businessName,
    required this.businessLogo,
    required this.businessAddress,
    required this.productCount,
    required this.storeTotal,
    required this.bgColor,
    required this.onManageProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: bgColor,
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Logo & Name ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedAvatarWidget(
                  imageUrl: businessLogo,
                  size: SizeConfig.size40,
                  borderColor: Colors.white,
                  borderRadius: SizeConfig.size20,
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        businessName,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: SizeConfig.size6),
                      Row(
                        children: [
                          _buildBadge(
                            '$productCount ${productCount == 1 ? 'Product' : 'Products'}',
                            AppColors.lightYellowShade,
                            AppColors.blue2D,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            '₹${storeTotal.toStringAsFixed(2)}',
                            const Color(0xFFE8F5E9),
                            AppColors.green1A,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Address ---
            if (businessAddress.isNotEmpty) ...[
              SizedBox(height: SizeConfig.paddingXSL),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5, width: 0.5),
                  color: AppColors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 1),
                            blurRadius: 2.0,
                          )
                        ],
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.location_outline,
                        imgColor: AppColors.secondaryTextColor,
                        height: 24,
                        width: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        businessAddress,
                        fontSize: 11.0,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: SizeConfig.paddingXSL),

            // --- Manage Products Button ---
            SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: onManageProducts,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border:
                        Border.all(color: AppColors.green1A, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.green1A),
                      const SizedBox(width: 8),
                      CustomText(
                        'Manage Products',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green1A,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: bgColor,
        border: Border.all(color: bgColor, width: 0.5),
      ),
      child: CustomText(text,
          fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PRODUCTS BOTTOM SHEET - 70% height, Save btn, summary footer
// ═══════════════════════════════════════════════════════════════════

class _ProductsBottomSheet extends StatelessWidget {
  final String businessName;
  final List<ProductVariants> items;
  final GroceryCustomerController controller;

  const _ProductsBottomSheet({
    required this.businessName,
    required this.items,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Handle ---
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyCA,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // --- Title + Save Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    businessName,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      'Save',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.appBackgroundColor),

          // --- Product List ---
          Expanded(
            child: Obx(() {
              final activeItems = items
                  .where((v) => controller.selectedGroceriesVariants
                      .any((sv) => sv.sId == v.sId))
                  .toList();

              if (activeItems.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                });
                return const SizedBox.shrink();
              }

              // Calculate totals for footer
              int totalProducts = 0;
              double totalAmount = 0;
              for (var v in activeItems) {
                int qty = controller.getQuantity(v.sId);
                totalProducts += qty;
                double sp = double.tryParse(
                        v.pricing?.first.sellingPrice.toString() ?? '0') ??
                    0;
                totalAmount += sp * qty;
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15,
                  vertical: SizeConfig.size8,
                ),
                itemCount: activeItems.length + 1, // +1 for summary footer
                itemBuilder: (context, index) {
                  if (index == activeItems.length) {
                    // --- Summary Footer after last product ---
                    return Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 18, color: AppColors.primaryColor),
                              const SizedBox(width: 8),
                              CustomText(
                                '$totalProducts ${totalProducts == 1 ? 'Product' : 'Products'}',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                          CustomText(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    );
                  }

                  final variant = activeItems[index];
                  return _variantItem(variant: variant);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _variantItem({required ProductVariants variant}) {
    final sellingPrice = variant.pricing?.first.sellingPrice ?? 0;
    final mrp = variant.pricing?.first.mrp ?? 0;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        children: [
          /// Variant Image
          (variant.images != null && variant.images!.isNotEmpty)
              ? CustomImageSlideshow(
                  isLoading: false,
                  width: SizeConfig.size50,
                  height: SizeConfig.size50,
                  imagePaths:
                      variant.images!.map((i) => i.url ?? '').toList(),
                  borderRadius: BorderRadius.circular(6),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.fill,
                    width: SizeConfig.size50,
                    height: SizeConfig.size50,
                  ),
                ),

          SizedBox(width: SizeConfig.paddingXSL),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText('${variant.quantity}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 0.5,
                      height: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText('₹$sellingPrice',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(width: SizeConfig.size6),
                    CustomText('₹$mrp',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: SizeConfig.paddingXSL),

          /// Dashed Border
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(
              height: SizeConfig.size50,
              width: 1,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Actions
          Obx(() {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText('₹$sellingPrice',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(width: SizeConfig.size4),
                    CustomText('₹$mrp',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                  ],
                ),
                SizedBox(height: SizeConfig.size4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: AppColors.white,
                    border: Border.all(color: AppColors.greyE5),
                    boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                controller.removeFromCart(variant),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primaryColor
                                .withValues(alpha: 0.2),
                            highlightColor: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Icon(Icons.remove,
                                    color: AppColors.secondaryTextColor,
                                    size: SizeConfig.size12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      CustomText(
                        '${controller.getQuantity(variant.sId)}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.addToCart(variant),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primaryColor
                                .withValues(alpha: 0.2),
                            highlightColor: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Icon(Icons.add,
                                    size: SizeConfig.size12,
                                    color: AppColors.secondaryTextColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
