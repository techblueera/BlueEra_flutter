import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/view/admin/edit_grocery_varient_dialog.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_qty_stepper.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_product_card.dart'
    show GroceryFallbackImage;
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet that lists **all variants** of one grocery product. Dual-mode:
///
/// * **Admin** (default — no [cartController]): each variant has edit (MRP /
///   selling price → `PUT grocery-service/api/inventory/{inventoryId}`) and
///   swipe-to-delete (`DELETE grocery-service/api/inventory/{inventoryId}`).
/// * **Customer** (pass [cartController] + [onAddToCart]): each variant has an
///   add/remove quantity stepper bound to the self-pickup cart, so the user
///   picks the exact variant to add. [onAddToCart] owns the business context
///   (businessId/name/logo) and is invoked on increment; decrement removes via
///   the controller.
///
/// Takes just the product name + fallback image + variants, so it works with
/// any product model (used by the admin top-selling rail/grid, the "My products"
/// listing, and the customer top-selling section).
Future<void> showGroceryVariantsSheet({
  required BuildContext context,
  required String productName,
  String? productImageUrl,
  required List<ProductVariants> variants,
  GrocerySelfPickupConsumerController? cartController,
  void Function(ProductVariants variant)? onAddToCart,
  VariantInventoryService? inventoryService,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GroceryVariantsSheet(
      productName: productName,
      productImageUrl: productImageUrl,
      variants: variants,
      cartController: cartController,
      onAddToCart: onAddToCart,
      inventoryService: inventoryService,
    ),
  );
}

/// Which service the sheet's edit / delete actions write to.
///
/// The sheet is shared by more than one me-section module because the
/// business-products response shape is identical across them — but the
/// **endpoints are not**. Without this, a pharmacy editing a variant from the
/// medical Top Selling rail posted a medical inventory id to
/// `grocery-service`, which is simply the wrong service.
///
/// [refreshOwner] nudges whichever controller owns the list behind the sheet,
/// since mutating an element in place doesn't notify an RxList.
class VariantInventoryService {
  final Future<ResponseModel> Function({
    required String inventoryId,
    required Map<String, dynamic> params,
  }) update;

  final Future<ResponseModel> Function({required String inventoryId}) delete;

  /// Marks inventory records in / out of stock. **Optional** — a service that
  /// leaves it null simply doesn't get the stock toggle, which is how the
  /// medical binding opts out until its own endpoint is confirmed.
  final Future<ResponseModel> Function({
    required List<String> inventoryIds,
    required bool isOutOfStock,
  })? toggleOutOfStock;

  final VoidCallback refreshOwner;

  const VariantInventoryService({
    required this.update,
    required this.delete,
    required this.refreshOwner,
    this.toggleOutOfStock,
  });

  /// `grocery-service/api/inventory/{id}` — the default, so every existing
  /// grocery call site keeps working untouched.
  factory VariantInventoryService.grocery() {
    return VariantInventoryService(
      update: ({required inventoryId, required params}) =>
          GroceryRepo().updateInventoryVariantRepo(
        inventoryId: inventoryId,
        params: params,
      ),
      delete: ({required inventoryId}) =>
          GroceryRepo().deleteInventoryVariantRepo(inventoryId: inventoryId),
      toggleOutOfStock: ({required inventoryIds, required isOutOfStock}) =>
          GroceryRepo().toggleOutOfStockRepo(
        inventoryIds: inventoryIds,
        isOutOfStock: isOutOfStock,
      ),
      refreshOwner: () {
        if (Get.isRegistered<GroceryController>()) {
          Get.find<GroceryController>().groceryBusinessProductsList.refresh();
        }
      },
    );
  }
}

class GroceryVariantsSheet extends StatefulWidget {
  final String productName;
  final String? productImageUrl;
  final List<ProductVariants> variants;

  /// When non-null, the sheet runs in customer add-to-cart mode.
  final GrocerySelfPickupConsumerController? cartController;
  final void Function(ProductVariants variant)? onAddToCart;

  /// Defaults to grocery — see [VariantInventoryService].
  final VariantInventoryService? inventoryService;

  const GroceryVariantsSheet({
    super.key,
    required this.productName,
    this.productImageUrl,
    required this.variants,
    this.cartController,
    this.onAddToCart,
    this.inventoryService,
  });

  @override
  State<GroceryVariantsSheet> createState() => _GroceryVariantsSheetState();
}

class _GroceryVariantsSheetState extends State<GroceryVariantsSheet> {
  late final List<ProductVariants> _variants =
      List<ProductVariants>.from(widget.variants);

  /// The service the edit / delete actions write to. Grocery unless the
  /// caller injected its own.
  late final VariantInventoryService _service =
      widget.inventoryService ?? VariantInventoryService.grocery();

  bool get _isCustomer => widget.cartController != null;

  String get _productName => widget.productName;

  /// First variant that carries a real image — last-resort fallback so a
  /// variant with no image (and a broken product image) still shows a sibling
  /// variant's photo instead of a placeholder.
  String? get _anyVariantImageUrl {
    for (final v in _variants) {
      if (v.images?.isNotEmpty ?? false) {
        final url = v.images!.first.url;
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  void _editVariant(int index) {
    final variant = _variants[index];
    // Seed the form from the INVENTORY price (what the endpoint writes and
    // what every surface displays), not the catalog `pricing`. Opening the
    // form on the catalog price meant the prefilled value could differ from
    // the price shown on the card the user just tapped.
    final price = _displayPriceOf(variant);
    // Bottom sheet, not showDialog: EditGroceryVarientDialog is built as a
    // sheet (top-only corners, drag handle, viewInsets keyboard padding), and
    // showDialog supplies no Material ancestor for its TextFields.
    showModalBottomSheet(
      context: context,
      // Both fields are numeric, so the keyboard is up the whole time — the
      // sheet pads itself and must be free to grow past the half-screen cap.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGroceryVarientDialog(
        title: AppStrings.groceryViewEditVariant.tr,
        mrp: price?.mrp?.toString() ?? '',
        selling: price?.sellingPrice?.toString() ?? '',
        // Persist FIRST, close only once the server has accepted it. Closing
        // up-front dismissed the form before the call resolved, so a failure
        // surfaced as a snackbar over a sheet the user had already left — with
        // their typed values gone.
        onSubmit: (mrp, selling) =>
            _saveVariantPricing(variant, mrp: mrp, selling: selling),
      ),
    );
  }

  /// The price every grocery surface displays for a variant: the merchant's
  /// inventory batch price, falling back to the catalog `pricing` only when
  /// the variant has no batches yet.
  ///
  /// Mirrors the resolution in [GroceryTopSellingProductCard] — both must read
  /// the same source or the card and this sheet disagree after an edit.
  Pricing? _displayPriceOf(ProductVariants variant) {
    final batches = variant.inventory?.batches;
    if (batches != null && batches.isNotEmpty) {
      return Pricing(
        mrp: batches.first.mrp,
        sellingPrice: batches.first.sellingPrice,
      );
    }
    return (variant.pricing?.isNotEmpty ?? false) ? variant.pricing![0] : null;
  }

  /// `PUT grocery-service/api/inventory/{inventoryId}` with the new pricing,
  /// then update the local model and close the edit sheet on success.
  Future<void> _saveVariantPricing(ProductVariants variant,
      {required String mrp, required String selling}) async {
    final inventoryId = variant.inventory?.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant can't be updated.");
      return;
    }
    final newMrp = num.tryParse(mrp);
    final newSelling = num.tryParse(selling);
    // Batch quantity ("2 kg") is carried through unchanged — this form edits
    // price only. Prefer the existing batch's own value; fall back to the
    // variant's quantity + unit when there's no batch row yet.
    final existingBatch = (variant.inventory?.batches?.isNotEmpty ?? false)
        ? variant.inventory!.batches!.first
        : null;
    final batchQuantity = existingBatch?.quantity ??
        '${variant.quantity ?? ''} ${variant.unit ?? ''}'.trim();

    AppLoader.show();
    final res = await _service.update(
      inventoryId: inventoryId,
      // The endpoint takes the batch list, not flat price fields — a bare
      // {mrp, sellingPrice} body doesn't identify which batch to write.
      params: {
        'batches': [
          {
            'quantity': batchQuantity,
            'mrp': newMrp,
            'sellingPrice': newSelling,
          },
        ],
      },
    );
    AppLoader.hide();
    if (!res.isSuccess) {
      // Leave the edit sheet open so the user can correct and retry without
      // retyping.
      commonSnackBar(message: res.message ?? 'Could not update the variant.');
      return;
    }

    // Mirror ONLY what the endpoint actually wrote: the merchant's inventory
    // batch price.
    //
    // `variant.pricing` is deliberately left alone — that's the shared master
    // catalog price, which this endpoint does not touch. Writing the
    // merchant's price into it would make the client disagree with the server
    // and the edit would appear to revert on the next fetch.
    final inventory = variant.inventory;
    final batches = inventory?.batches;
    if (batches != null && batches.isNotEmpty) {
      batches.first.mrp = newMrp;
      batches.first.sellingPrice = newSelling;
    } else if (inventory != null) {
      // No batch row yet — the server just created one from the body above, so
      // echo it locally instead of falling back to the catalog price. A later
      // refetch fills in the batchNumber/id this local stub can't know.
      inventory.batches = [
        ...?batches,
        Batches(
          quantity: batchQuantity,
          mrp: newMrp,
          sellingPrice: newSelling,
        ),
      ];
    }

    // `variant` is the same object the controller's list holds (the sheet
    // shallow-copies the list, not its elements), so the model is already
    // current — but mutating an element doesn't notify an RxList. Nudge it so
    // the top-selling rail behind this sheet rebuilds.
    _service.refreshOwner();

    if (mounted) setState(() {});
    Get.back(); // close the edit sheet — the variants list stays open
    commonSnackBar(message: 'Variant updated');
  }

  /// Inventory id of the variant whose stock toggle is mid-flight, so only
  /// that row's pill spins.
  String? _togglingStockId;

  /// Whether a variant reads as in stock — read off `variants[].inventory
  /// .isOutOfStock`, the only place the flag lives (the row's own top level
  /// carries no such field, and its representative `productVariant` has no
  /// `inventory` object at all).
  ///
  /// `totalStock` is deliberately NOT part of this. Quantity isn't maintained
  /// in this catalogue — rows come back with `totalStock: 0` while
  /// `isOutOfStock` is false — so folding it in marked every product sold out.
  bool _isInStock(ProductVariants variant) =>
      variant.inventory?.isOutOfStock != true;

  /// Flips the manual out-of-stock flag on one variant. Only the flag moves —
  /// quantity is untouched.
  Future<void> _toggleStock(
      ProductVariants variant, bool markOutOfStock) async {
    final inventoryId = variant.inventory?.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant's stock can't be changed.");
      return;
    }

    setState(() => _togglingStockId = inventoryId);
    final res = await _service.toggleOutOfStock!(
      inventoryIds: [inventoryId],
      isOutOfStock: markOutOfStock,
    );
    if (!mounted) return;

    if (!res.isSuccess) {
      setState(() => _togglingStockId = null);
      commonSnackBar(message: res.message ?? "Couldn't update stock.");
      return;
    }

    variant.inventory?.isOutOfStock = markOutOfStock;
    setState(() => _togglingStockId = null);
    // Same object the controller's list holds, but mutating an element doesn't
    // notify an RxList — nudge the rail behind the sheet.
    _service.refreshOwner();

    commonSnackBar(
      message: markOutOfStock ? 'Marked out of stock.' : 'Marked in stock.',
    );
  }

  /// Food-style: confirm, then `DELETE grocery-service/api/inventory/{inventoryId}`
  /// and remove the row on success.
  Future<void> _confirmAndDelete(ProductVariants variant) async {
    final confirmed = await _showDeleteConfirm(variant);
    if (confirmed != true) return;
    final inventoryId = variant.inventory?.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant can't be deleted.");
      return;
    }
    AppLoader.show();
    final res = await _service.delete(inventoryId: inventoryId);
    AppLoader.hide();
    if (!res.isSuccess) {
      commonSnackBar(message: res.message ?? 'Could not delete the variant.');
      return;
    }
    if (mounted) {
      setState(() => _variants.removeWhere((v) => identical(v, variant)));
    }
    // The row is gone from the server too, so the rail behind the sheet must
    // drop it as well — the old code only mutated this sheet's local copy.
    _service.refreshOwner();
    commonSnackBar(message: 'Variant deleted');
  }

  Future<bool?> _showDeleteConfirm(ProductVariants variant) {
    final name = variant.variantName ??
        '${variant.quantity ?? ''} ${variant.unit ?? ''}'.trim();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText('Delete variant?',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        content: CustomText(
          '"$name" will be removed.',
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText(AppStrings.cancel.tr,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w700),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText(AppStrings.delete.tr,
                color: AppColors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const Divider(height: 1),
          if (!_isCustomer && _variants.isNotEmpty) _swipeHint(),
          Flexible(
            child: _variants.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(SizeConfig.size24),
                    child: CustomText(
                      AppStrings.noProductYetCreateOne.tr,
                      color: AppColors.secondaryTextColor,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    // Bottom padding clears the gesture bar so the last row
                    // isn't flush against the sheet edge / under the home
                    // indicator when the list scrolls to the end.
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size12,
                      SizeConfig.size8,
                      SizeConfig.size12,
                      SizeConfig.size24 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: _variants.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: SizeConfig.size10),
                    itemBuilder: (_, i) {
                      // Customer rows aren't swipeable (they carry the cart
                      // stepper). Admin rows reveal a red Delete on swipe-left.
                      if (_isCustomer) return _variantRow(i);
                      final variant = _variants[i];
                      return _SwipeToDeleteRow(
                        key: ValueKey(variant.sId ?? '$i'),
                        onDelete: () => _confirmAndDelete(variant),
                        child: _variantRow(i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size14,
        SizeConfig.size8,
        SizeConfig.size12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  _productName,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  AppStrings.groceryViewAllVariants.tr,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.close,
                size: SizeConfig.size20, color: AppColors.black),
          ),
        ],
      ),
    );
  }

  Widget _variantRow(int index) {
    final variant = _variants[index];
    // Inventory batch price, same source the top-selling card reads — the two
    // must not diverge.
    final price = _displayPriceOf(variant);
    // Variant image first, product image as fallback (missing OR broken).
    final variantImageUrl = (variant.images?.isNotEmpty ?? false)
        ? variant.images!.first.url
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0.5, color: AppColors.greyE5),
      ),
      padding: EdgeInsets.all(SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: SizeConfig.size60,
              width: SizeConfig.size60,
              child: GroceryFallbackImage(
                // variant image → product image → any sibling variant image.
                urls: [
                  variantImageUrl,
                  widget.productImageUrl,
                  _anyVariantImageUrl,
                ],
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (variant.isVegetarian != null) ...[
                      FoodTypeIndicator(
                          isVegetarian: variant.isVegetarian ?? false),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Expanded(
                      child: CustomText(
                        variant.variantName ??
                            '${variant.quantity ?? ''} ${variant.unit ?? ''}'
                                .trim(),
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice:
                      '${AppConstants.rupeeSymbol}${price?.sellingPrice ?? ''}',
                  mrp: '${AppConstants.rupeeSymbol}${price?.mrp ?? ''}',
                  discount: '',
                ),
                // Admin: the pill doubles as the in-stock / out-of-stock
                // switch. It sits under the price rather than in the trailing
                // slot so it can share the row with the edit button.
                if (!_isCustomer && _service.toggleOutOfStock != null) ...[
                  SizedBox(height: SizeConfig.size6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StockStatusPill(
                      inStock: _isInStock(variant),
                      busy: _togglingStockId ==
                          (variant.inventory?.inventoryId ?? ''),
                      onToggle: (markOutOfStock) =>
                          _toggleStock(variant, markOutOfStock),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Customer: add/remove stepper. Admin: edit (delete is swipe-to-reveal).
          if (_isCustomer)
            Obx(() {
              final qty = widget.cartController!.getQuantity(variant.sId);
              return GroceryQtyStepper(
                quantity: qty,
                onIncrement: () => widget.onAddToCart?.call(variant),
                onDecrement: () =>
                    widget.cartController!.removeFromCart(variant),
              );
            })
          else
            _iconButton(
              icon: Icons.edit_outlined,
              color: AppColors.primaryColor,
              onTap: () => _editVariant(index),
            ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: SizeConfig.size18, color: color),
      ),
    );
  }

  Widget _swipeHint() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size8, SizeConfig.size16, 0),
      child: Row(
        children: [
          Icon(Icons.swipe_left_rounded,
              size: 14, color: AppColors.secondaryTextColor),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            'Swipe a variant left, then tap Delete',
            fontSize: 11,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

/// Zomato-style swipe-to-reveal (mirrors the food variant sheet): the [child]
/// slides left up to a fixed delete panel — it never fully dismisses; the user
/// taps the revealed red Delete button to act. Snaps open/closed on release.
class _SwipeToDeleteRow extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onDelete;

  const _SwipeToDeleteRow({
    super.key,
    required this.child,
    required this.onDelete,
  });

  @override
  State<_SwipeToDeleteRow> createState() => _SwipeToDeleteRowState();
}

class _SwipeToDeleteRowState extends State<_SwipeToDeleteRow>
    with SingleTickerProviderStateMixin {
  static const double _revealW = 96;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _c.value = (_c.value - (d.primaryDelta ?? 0) / _revealW).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final open = v < -300 ? true : (v > 300 ? false : _c.value > 0.5);
    _c.animateTo(open ? 1 : 0, curve: Curves.easeOut);
  }

  void _close() => _c.animateTo(0, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  await widget.onDelete();
                  _close();
                },
                child: Container(
                  width: _revealW,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(height: 2),
                      Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Transform.translate(
              offset: Offset(-_revealW * _c.value, 0),
              child: child,
            ),
            child: GestureDetector(
              onTap: () {
                if (_c.value > 0) _close();
              },
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
