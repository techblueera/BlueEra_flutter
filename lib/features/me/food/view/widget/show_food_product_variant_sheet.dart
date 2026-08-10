import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:BlueEra/widgets/swipe_to_delete_row.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Whether a whole dish reads as out of stock — true only when EVERY variant
/// is flagged. One sellable size still means a customer can order it, so a
/// partially-flagged dish is not marked.
///
/// Lives here beside the sheet that owns the in/out switch, so the card badge
/// and the sheet can never disagree on what "out of stock" means.
bool isFoodProductOutOfStock(CategoryFoodProductData product) {
  final variants = product.variants ?? const <FoodVariants>[];
  return variants.isNotEmpty && variants.every((v) => v.isOutOfStock == true);
}

Future<void> showFoodProductVariantSheet(
  BuildContext context, {
  required CategoryFoodProductData product,
}) {
  return Get.bottomSheet(
    FoodProductVariantSheet(product: product),
    isScrollControlled: true,
  );
}

class FoodProductVariantSheet extends StatelessWidget {
  final CategoryFoodProductData product;

  const FoodProductVariantSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            _ProductInfo(product: product),
            const Divider(),
            _VariantList(product: product),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'All Variant',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final CategoryFoodProductData product;

  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductImageWidget(
          imageUrl: product.images?.firstOrNull,
          width: 60,
          height: 60,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                product.name,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ProductDescriptionWidget(description: product.description),
              const SizedBox(height: 8),
              FoodDietaryAndTagRow(
                dietaryType: product.dietaryType,
                cookingMethods: product.cookingMethod,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VariantList extends StatefulWidget {
  final CategoryFoodProductData product;

  const _VariantList({required this.product});

  @override
  State<_VariantList> createState() => _VariantListState();
}

class _VariantListState extends State<_VariantList> {
  // Local working copy so a deleted variant disappears from the open sheet
  // immediately; we also mutate the shared product list so the screen behind
  // reflects the new count on return.
  late final List<FoodVariants> _variants =
      List<FoodVariants>.from(widget.product.variants ?? const []);

  /// Inventory id of the variant whose stock toggle is mid-flight, so only
  /// that row's pill spins.
  String? _togglingStockId;

  /// Flips one variant's manual out-of-stock flag via
  /// `PATCH kitchen-inventory/stock/toggle-out-of-stock`. Goes straight to the
  /// repo, same as delete above — the food sheet has no controller of its own.
  Future<void> _toggleStock(FoodVariants item, bool markOutOfStock) async {
    final inventoryId = item.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant's stock can't be changed.");
      return;
    }

    setState(() => _togglingStockId = inventoryId);
    final res = await FoodRepo().toggleOutOfStockRepo(
      inventoryIds: [inventoryId],
      isOutOfStock: markOutOfStock,
    );
    if (!mounted) return;

    if (!res.isSuccess) {
      setState(() => _togglingStockId = null);
      commonSnackBar(message: res.message ?? "Couldn't update stock.");
      return;
    }

    // Mutate the shared product's variant too, so the screen behind the sheet
    // shows the new state on return — mirrors [_onDeleted].
    item.isOutOfStock = markOutOfStock;
    for (final v in widget.product.variants ?? const <FoodVariants>[]) {
      if (v.inventoryId == inventoryId) v.isOutOfStock = markOutOfStock;
    }
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().foodDataNeedsRefresh = true;
    }
    setState(() => _togglingStockId = null);
    commonSnackBar(
      message: markOutOfStock ? 'Marked out of stock.' : 'Marked in stock.',
    );
  }

  /// Confirms, then calls `DELETE kitchen-inventory/{inventoryId}`. Returns
  /// `true` only when the variant was actually deleted (so the row dismisses).
  Future<bool> _confirmAndDelete(FoodVariants item) async {
    final inventoryId = item.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant can't be deleted.");
      return false;
    }

    final confirmed = await _showDeleteConfirm(item);
    if (confirmed != true) return false;

    AppLoader.show();
    final res =
        await FoodRepo().deleteKitchenInventoryRepo(inventoryId: inventoryId);
    AppLoader.hide();

    if (!res.isSuccess) {
      commonSnackBar(
          message: res.message ?? 'Could not delete the variant.');
      return false;
    }
    return true;
  }

  void _onDeleted(FoodVariants item) {
    _variants.removeWhere((v) => v.inventoryId == item.inventoryId);
    widget.product.variants
        ?.removeWhere((v) => v.inventoryId == item.inventoryId);
    // Ask the food screens to refetch on return so counts stay in sync.
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().foodDataNeedsRefresh = true;
    }
    if (mounted) setState(() {});
    commonSnackBar(message: 'Variant deleted.');
  }

  Future<bool?> _showDeleteConfirm(FoodVariants item) {
    final name = '${item.variantName ?? 'Variant'}'
        '${(item.quantityLabel ?? '').isNotEmpty ? ' - ${item.quantityLabel}' : ''}';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText('Delete variant?',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        content: CustomText(
          '"$name" and its inventory will be permanently removed. '
          "This can't be undone.",
          fontSize: 13,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText('Cancel',
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w700),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText('Delete',
                color: AppColors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_variants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CustomText(
          'No variants available',
          color: AppColors.secondaryTextColor,
        ),
      );
    }

    return Column(
      children: [
        // Affordance hint — the delete button only appears on swipe.
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 2),
          child: Row(
            children: [
              Icon(Icons.swipe_left_rounded,
                  size: 14, color: AppColors.secondaryTextColor),
              const SizedBox(width: 6),
              CustomText(
                'Swipe a variant left, then tap Delete',
                fontSize: 11,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
        ..._variants.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SwipeToDeleteRow(
              key: ValueKey(item.inventoryId ?? item.id ?? '${item.hashCode}'),
              onDelete: () async {
                if (await _confirmAndDelete(item)) _onDeleted(item);
              },
              child: _variantCard(item),
            ),
          );
        }),
      ],
    );
  }

  Widget _variantCard(FoodVariants item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.greyE5.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Blue vertical accent line
              Container(
                width: 4,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 12),
              // Variant content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        '${item.variantName ?? ''}'
                        '${(item.quantityLabel ?? '').isNotEmpty ? ' - ${item.quantityLabel}' : ''}',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Selling price chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CustomText(
                              '₹${item.baseSellingPrice ?? 0}',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // MRP strikethrough
                          if ((item.mrp ?? 0) > (item.baseSellingPrice ?? 0))
                            CustomText(
                              '₹${item.mrp ?? 0}',
                              fontSize: 12,
                              color: AppColors.secondaryTextColor
                                  .withValues(alpha: 0.7),
                              decoration: TextDecoration.lineThrough,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // The pill doubles as the in-stock / out-of-stock switch.
                      // Sits under the price so the swipe-to-delete gesture on
                      // the row still has the full width to work with.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StockStatusPill(
                          inStock: item.isOutOfStock != true,
                          busy: _togglingStockId == (item.inventoryId ?? ''),
                          onToggle: (markOutOfStock) =>
                              _toggleStock(item, markOutOfStock),
                        ),
                      ),
                    ],
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

