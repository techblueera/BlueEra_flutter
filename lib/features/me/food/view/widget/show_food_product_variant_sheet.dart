import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
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
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              const SizedBox(height: 8),
              // The dish's own price, at the head of the sheet.
              //
              // The per-variant rows below carry the authoritative numbers, but
              // reading them meant scanning every row to answer "what does this
              // dish cost, and is it discounted?" — the first question the owner
              // opens this sheet with. This answers it once, at the top.
              _PriceSummary(product: product),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selling price, MRP and discount for a whole dish, for the head of the
/// variant sheet.
///
/// A dish is priced per VARIANT, so there is rarely one number to show. This
/// leads with the cheapest sellable variant — the price a customer would see on
/// a listing — and says how far the range runs when there is more than one:
///
///   * one variant            `₹85   ₹100   15% OFF`
///   * several, same price    `₹85   ₹100   15% OFF`
///   * several, a range       `₹85 – ₹150` + `up to 15% OFF`
///
/// The MRP shown belongs to the SAME variant as the leading price, so the pair
/// and its percentage always describe one real row rather than a mix of two.
class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.product});

  final CategoryFoodProductData product;

  @override
  Widget build(BuildContext context) {
    final variants = (product.variants ?? const <FoodVariants>[])
        .where((v) => (v.baseSellingPrice ?? 0) > 0)
        .toList();
    if (variants.isEmpty) return const SizedBox.shrink();

    // Cheapest first — the "from" price.
    variants.sort(
      (a, b) => (a.baseSellingPrice ?? 0).compareTo(b.baseSellingPrice ?? 0),
    );
    final lead = variants.first;
    final leadSelling = lead.baseSellingPrice ?? 0;
    final leadMrp = lead.mrp ?? 0;
    final highest = variants.last.baseSellingPrice ?? 0;
    final isRange = highest > leadSelling;

    // The BEST discount any variant carries, so "up to" is true of the set.
    var bestPercent = 0;
    for (final v in variants) {
      final mrp = v.mrp ?? 0;
      final selling = v.baseSellingPrice ?? 0;
      if (mrp > selling && mrp > 0) {
        final percent = (((mrp - selling) / mrp) * 100).round();
        if (percent > bestPercent) bestPercent = percent;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CustomText(
          isRange
              ? '${AppConstants.rupeeSymbol}$leadSelling – '
                  '${AppConstants.rupeeSymbol}$highest'
              : '${AppConstants.rupeeSymbol}$leadSelling',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        // Struck-through MRP only when there is a single price to strike
        // through. Against a range it would be ambiguous which end it belongs
        // to, and the "up to" badge already carries the saving.
        if (!isRange && leadMrp > leadSelling)
          CustomText(
            '${AppConstants.rupeeSymbol}$leadMrp',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor.withValues(alpha: 0.7),
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.secondaryTextColor,
          ),
        if (bestPercent > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: CustomText(
              isRange ? 'up to $bestPercent% OFF' : '$bestPercent% OFF',
              fontSize: SizeConfig.extraSmall,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
              letterSpacing: 0.3,
            ),
          ),
        if (variants.length > 1)
          CustomText(
            '${variants.length} variants',
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
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

  /// Inventory id of the variant whose price is being saved, so only that row's
  /// pill shows a spinner.
  String? _savingPriceId;

  /// The owner's price editor for ONE published variant — a bottom sheet, so
  /// it lifts for the keyboard the autofocused field brings up.
  ///
  /// This is the only place a dish's price can be changed after publishing. The
  /// cart's editor (`FoodCartScreen`) works on a variant that has not been sent
  /// to the server yet — it edits a local list and the publish call carries the
  /// numbers. Once published, the variant is a kitchen-inventory record and the
  /// price only moves through `PATCH kitchen-inventory/{inventoryId}`.
  ///
  /// The sheet is its own [StatefulWidget] rather than a builder closure here,
  /// so it OWNS its `TextEditingController`s and disposes them in its own
  /// `dispose()`. Disposing them at this call site — right after the `await`
  /// returned — threw "A TextEditingController was used after being disposed":
  /// `Get.bottomSheet`'s future completes the moment `Get.back()` runs, while
  /// the route is still playing its exit animation and rebuilding the fields.
  Future<void> _openPriceEditor(FoodVariants item) async {
    final inventoryId = item.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant's price can't be changed.");
      return;
    }

    final result = await Get.bottomSheet<_VariantPrice>(
      _VariantPriceEditorSheet(
        title: _variantTitle(item),
        sellingPrice: item.baseSellingPrice ?? 0,
        mrp: item.mrp ?? 0,
      ),
      // Required for the sheet's keyboard padding to have room to expand into —
      // without it the sheet caps at half the screen and the inset squeezes the
      // content instead of moving it.
      isScrollControlled: true,
    );
    if (!mounted || result == null) return;
    await _savePrice(item, sellingPrice: result.sellingPrice, mrp: result.mrp);
  }

  /// Writes the new pair, then mirrors it exactly where [_toggleStock] mirrors
  /// its flag — the local working copy AND the shared product — so the sheet and
  /// the screen behind it both show the new price without a refetch.
  ///
  /// READ, merge, then write. `PUT kitchen-inventory/{id}` replaces the whole
  /// `price` subdocument, so sending only `{mrp, sellingPrice}` silently reset
  /// `packingCharges` to 0 (verified against the live service — 20 became 0).
  /// The variant models parsed from the listing endpoints carry neither
  /// `currency` nor `packingCharges`, so the only way to send them back
  /// unchanged is to fetch the record first.
  ///
  /// A failed pre-read ABORTS rather than writing what it has: a price edit
  /// must not be able to zero a charge the merchant never touched.
  Future<void> _savePrice(
    FoodVariants item, {
    required int sellingPrice,
    required int mrp,
  }) async {
    final inventoryId = item.inventoryId ?? '';
    setState(() => _savingPriceId = inventoryId);

    final current = await FoodRepo().getKitchenInventoryByIdRepo(
      inventoryId: inventoryId,
    );
    if (!mounted) return;
    final existingPrice = current.isSuccess
        ? (current.response?.data?['data']?['price'] as Map?)
        : null;
    if (existingPrice == null) {
      setState(() => _savingPriceId = null);
      commonSnackBar(
          message: "Couldn't read the current price. Please try again.");
      return;
    }

    final res = await FoodRepo().updateKitchenInventoryVariantRepo(
      inventoryId: inventoryId,
      params: {
        'price': {
          // Everything the record already had, with only the two edited
          // numbers replaced.
          ...Map<String, dynamic>.from(existingPrice),
          'mrp': mrp,
          'sellingPrice': sellingPrice,
        },
      },
    );
    if (!mounted) return;

    if (!res.isSuccess) {
      setState(() => _savingPriceId = null);
      commonSnackBar(message: res.message ?? "Couldn't update the price.");
      return;
    }

    item.baseSellingPrice = sellingPrice;
    item.mrp = mrp;
    for (final v in widget.product.variants ?? const <FoodVariants>[]) {
      if (v.inventoryId == inventoryId) {
        v.baseSellingPrice = sellingPrice;
        v.mrp = mrp;
      }
    }
    // Repairs what this in-place patch cannot reach: the freshness guard, the
    // sibling rails still holding the old row, and the saved snapshot on disk —
    // a stale snapshot would put the old price straight back on the next open.
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().markMenuChanged();
    }
    setState(() => _savingPriceId = null);
    commonSnackBar(message: 'Price updated.');
  }

  /// "Half Plate - 250 g" — the variant as the merchant named it.
  String _variantTitle(FoodVariants item) {
    final label = item.quantityLabel ?? '';
    return '${item.variantName ?? 'Variant'}'
        '${label.isNotEmpty ? ' - $label' : ''}';
  }

  /// "15% OFF" for one variant.
  ///
  /// Rounded the same way the cart's review screen and the dish cards round it,
  /// so the merchant sees one number for a dish wherever they look at it.
  /// Callers only build this when MRP is above the selling price, so it never
  /// renders "0% OFF".
  Widget _discountBadge(FoodVariants item) {
    final mrp = item.mrp ?? 0;
    final selling = item.baseSellingPrice ?? 0;
    final percent = (((mrp - selling) / mrp) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: CustomText(
        '$percent% OFF',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.green.shade700,
        letterSpacing: 0.3,
      ),
    );
  }

  /// "Edit" beside a variant's price. Same pill the cart's review screen uses,
  /// so the control that sets a price before publishing and the one that
  /// changes it after look like the same thing.
  ///
  /// Swaps to a spinner while THAT row is saving — keyed on the inventory id
  /// rather than a single bool, so editing one variant does not blank the
  /// others' controls.
  Widget _editPricePill(FoodVariants item) {
    final saving = _savingPriceId == (item.inventoryId ?? '');
    return InkWell(
      onTap: saving ? null : () => _openPriceEditor(item),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving)
              SizedBox(
                height: SizeConfig.size14,
                width: SizeConfig.size14,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              )
            else
              LocalAssets(
                imagePath: AppIconAssets.pen_line,
                imgColor: AppColors.primaryColor,
                height: SizeConfig.size14,
                width: SizeConfig.size14,
              ),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  /// Flips one variant's manual out-of-stock flag via
  /// `PATCH kitchen-inventory/stock/flip-out-of-stock`. Goes straight to the
  /// repo, same as delete above — the food sheet has no controller of its own.
  Future<void> _toggleStock(FoodVariants item, bool markOutOfStock) async {
    final inventoryId = item.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant's stock can't be changed.");
      return;
    }

    setState(() => _togglingStockId = inventoryId);
    // A FLIP, not a set — no value goes up. That is safe here because
    // [StockStatusPill] only ever calls back with `!currentFlag`, so
    // `markOutOfStock` IS the inverse of what the server holds, and applying it
    // below matches what the flip just did.
    final res = await FoodRepo().flipOutOfStockRepo(
      inventoryIds: [inventoryId],
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
    // Repairs everything this sheet's in-place patch cannot reach: the
    // freshness guard, the sibling rails that still hold the old row, and the
    // saved snapshot on disk. See [RestaurantController.markMenuChanged].
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().markMenuChanged();
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
    // Ask the food screens to refetch on return so counts stay in sync, and
    // drop the saved snapshot — a deleted variant must not survive on disk.
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().markMenuChanged();
    }
    // A deleted variant is stockable again, so the add screens must start
    // offering it once more — the mirror of the refresh a publish triggers.
    if (Get.isRegistered<FoodServiceController>()) {
      Get.find<FoodServiceController>().markStockedVariantsChanged();
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
                          // MRP struck through, then what the pair actually
                          // saves the customer. A selling price and an MRP are
                          // two numbers to compare; the percentage is the thing
                          // the merchant set them FOR, and the same badge the
                          // cart and the dish cards already show.
                          if ((item.mrp ?? 0) > (item.baseSellingPrice ?? 0)) ...[
                            CustomText(
                              '₹${item.mrp ?? 0}',
                              fontSize: 12,
                              color: AppColors.secondaryTextColor
                                  .withValues(alpha: 0.7),
                              decoration: TextDecoration.lineThrough,
                            ),
                            const SizedBox(width: 8),
                            _discountBadge(item),
                          ],
                          const Spacer(),
                          // The owner's way in to the price. On the SAME row
                          // as the numbers it edits, and right-aligned so it
                          // stays clear of the swipe-to-delete gesture.
                          _editPricePill(item),
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


/// What the price editor hands back — both numbers, or nothing if cancelled.
typedef _VariantPrice = ({int sellingPrice, int mrp});

/// The owner's selling-price / MRP editor for one published variant.
///
/// A real widget rather than a builder closure so it OWNS its controllers: the
/// bottom-sheet future completes on `Get.back()` while the route is still
/// animating out and rebuilding these fields, so disposing them at the call
/// site threw "used after being disposed". Here `dispose()` runs when the
/// element actually leaves the tree.
class _VariantPriceEditorSheet extends StatefulWidget {
  const _VariantPriceEditorSheet({
    required this.title,
    required this.sellingPrice,
    required this.mrp,
  });

  final String title;
  final int sellingPrice;
  final int mrp;

  @override
  State<_VariantPriceEditorSheet> createState() =>
      _VariantPriceEditorSheetState();
}

class _VariantPriceEditorSheetState extends State<_VariantPriceEditorSheet> {
  late final TextEditingController _priceCtrl =
      TextEditingController(text: '${widget.sellingPrice}');
  late final TextEditingController _mrpCtrl =
      TextEditingController(text: '${widget.mrp}');

  String? _error;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    super.dispose();
  }

  int? get _selling => int.tryParse(_priceCtrl.text.trim());
  int? get _mrp => int.tryParse(_mrpCtrl.text.trim());

  /// Validates the PAIR rather than each field: a selling price above MRP is
  /// only wrong in relation to the other box, and the merchant may be fixing
  /// either one of them.
  String? _validate() {
    final selling = _selling;
    final mrp = _mrp;
    if (selling == null || selling <= 0) return 'Enter a valid selling price';
    if (mrp == null || mrp <= 0) return 'Enter a valid MRP';
    if (selling > mrp) {
      return 'Selling price cannot exceed MRP '
          '(${AppConstants.rupeeSymbol}$mrp)';
    }
    return null;
  }

  void _submit() {
    // Re-validated on submit, not only on change: the sheet opens with whatever
    // is already stored, so a variant saved wrong earlier would otherwise pass
    // through untouched.
    final message = _validate();
    setState(() => _error = message);
    if (message != null) return;
    Get.back(result: (sellingPrice: _selling!, mrp: _mrp!));
  }

  @override
  Widget build(BuildContext context) {
    // NO manual `viewInsets.bottom` padding here.
    //
    // The modal-bottom-sheet route ALREADY insets its child for the keyboard
    // when `isScrollControlled` is on. Adding the same inset again lifted the
    // sheet by two keyboard heights: it ran out of room, filled to the top of
    // the screen, and left a gap the exact height of the keyboard between the
    // Save button and the keys.
    //
    // The height cap is what keeps a tall sheet off the status bar; without it
    // `isScrollControlled` lets the sheet grow the full screen.
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
        child: SafeArea(
          top: false,
          // So Save stays reachable on a short screen with the keyboard up.
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size20,
                SizeConfig.size12,
                SizeConfig.size20,
                SizeConfig.size20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: EdgeInsets.only(bottom: SizeConfig.size16),
                      decoration: BoxDecoration(
                        color: AppColors.greyE5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  CustomText(
                    widget.title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  _priceField(
                    label: 'Selling price',
                    controller: _priceCtrl,
                    autofocus: true,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _priceField(label: 'MRP', controller: _mrpCtrl),
                  SizedBox(height: SizeConfig.size10),
                  // The discount the pair currently makes, live as either box is
                  // typed in — the number the merchant is actually deciding, and
                  // the one they would otherwise be computing in their head
                  // before deciding whether the selling price is right.
                  _discountPreview(),
                  if (_error != null) ...[
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: AppColors.red),
                        SizedBox(width: SizeConfig.size4),
                        Expanded(
                          child: CustomText(
                            _error!,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: SizeConfig.size20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: CustomText(
                          AppStrings.cancel.tr,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size20,
                            vertical: SizeConfig.size10,
                          ),
                        ),
                        onPressed: _submit,
                        child: CustomText(
                          AppStrings.save.tr,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  /// "₹85 · 15% OFF · saves ₹15", or a flat note when the two prices match.
  ///
  /// Silent while the pair is unusable — an in-progress edit ("8" on the way to
  /// "85") is not an error worth shouting about, and [_error] already covers a
  /// pair that is genuinely wrong.
  Widget _discountPreview() {
    final selling = _selling;
    final mrp = _mrp;
    if (selling == null || mrp == null || selling <= 0 || mrp <= 0) {
      return const SizedBox.shrink();
    }
    if (selling > mrp) return const SizedBox.shrink();

    final saved = mrp - selling;
    final percent = saved == 0 ? 0 : ((saved / mrp) * 100).round();
    final noDiscount = saved == 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: noDiscount
            ? AppColors.fillColor
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: noDiscount ? AppColors.greyE5 : Colors.green.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            noDiscount ? Icons.sell_outlined : Icons.local_offer,
            size: 14,
            color: noDiscount
                ? AppColors.secondaryTextColor
                : Colors.green.shade700,
          ),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: CustomText(
              noDiscount
                  ? 'Sold at MRP — no discount'
                  : '$percent% OFF · customer saves '
                      '${AppConstants.rupeeSymbol}$saved',
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w600,
              color: noDiscount
                  ? AppColors.secondaryTextColor
                  : Colors.green.shade700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// One labelled money input.
  ///
  /// ONE box. It used to be three nested ones — an outer bordered container, a
  /// tinted 45px plate for the ₹ with its own corner radii, and the field's own
  /// surface inside that — which drew two visible seams down a single input and
  /// read as a segmented control rather than something to type in.
  ///
  /// The rupee sign is a glyph on the same surface as the number now, in the
  /// same size and muted, so it reads as the unit of the value beside it.
  Widget _priceField({
    required String label,
    required TextEditingController controller,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        SizedBox(height: SizeConfig.size6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyE5),
          ),
          child: Row(
            children: [
              CustomText(
                AppConstants.rupeeSymbol,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: AppColors.primaryColor,
                  // Repaints the discount line and clears a stale error as
                  // either number is typed.
                  onChanged: (_) => setState(() {
                    if (_error != null) _error = _validate();
                  }),
                  style: TextStyle(
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  decoration: InputDecoration(
                    // Every border state off, not just the idle one: leaving
                    // `focusedBorder` to the theme is what put a second outline
                    // inside the box the moment the field took focus.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    filled: false,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor
                          .withValues(alpha: 0.45),
                    ),
                    // Vertical only — the row already owns the horizontal
                    // inset, and adding it here again offset the number from
                    // the ₹ by a stray gap.
                    contentPadding:
                        EdgeInsets.symmetric(vertical: SizeConfig.size14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
