import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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
    ),
  );
}

class GroceryVariantsSheet extends StatefulWidget {
  final String productName;
  final String? productImageUrl;
  final List<ProductVariants> variants;

  /// When non-null, the sheet runs in customer add-to-cart mode.
  final GrocerySelfPickupConsumerController? cartController;
  final void Function(ProductVariants variant)? onAddToCart;

  const GroceryVariantsSheet({
    super.key,
    required this.productName,
    this.productImageUrl,
    required this.variants,
    this.cartController,
    this.onAddToCart,
  });

  @override
  State<GroceryVariantsSheet> createState() =>
      _GroceryVariantsSheetState();
}

class _GroceryVariantsSheetState
    extends State<GroceryVariantsSheet> {
  late final List<ProductVariants> _variants =
      List<ProductVariants>.from(widget.variants);

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
    final price = (variant.pricing?.isNotEmpty ?? false) ? variant.pricing![0] : null;
    showDialog(
      context: context,
      builder: (_) => EditGroceryVarientDialog(
        title: AppStrings.groceryViewEditVariant.tr,
        mrp: price?.mrp?.toString() ?? '',
        selling: price?.sellingPrice?.toString() ?? '',
        onSubmit: (mrp, selling) {
          Get.back(); // close the edit dialog, then persist
          _saveVariantPricing(variant, mrp: mrp, selling: selling);
        },
      ),
    );
  }

  /// `PUT grocery-service/api/inventory/{inventoryId}` with the new pricing,
  /// then update the local row on success.
  Future<void> _saveVariantPricing(ProductVariants variant,
      {required String mrp, required String selling}) async {
    final inventoryId = variant.inventory?.inventoryId ?? '';
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This variant can't be updated.");
      return;
    }
    AppLoader.show();
    final res = await GroceryRepo().updateInventoryVariantRepo(
      inventoryId: inventoryId,
      params: {
        'sellingPrice': num.tryParse(selling),
        'mrp': num.tryParse(mrp),
      },
    );
    AppLoader.hide();
    if (!res.isSuccess) {
      commonSnackBar(message: res.message ?? 'Could not update the variant.');
      return;
    }
    if (variant.pricing != null && variant.pricing!.isNotEmpty) {
      variant.pricing![0] = variant.pricing![0].copyWith(
        mrp: num.tryParse(mrp),
        sellingPrice: num.tryParse(selling),
      );
    }
    if (mounted) setState(() {});
    commonSnackBar(message: 'Variant updated');
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
    final res =
        await GroceryRepo().deleteInventoryVariantRepo(inventoryId: inventoryId);
    AppLoader.hide();
    if (!res.isSuccess) {
      commonSnackBar(message: res.message ?? 'Could not delete the variant.');
      return;
    }
    if (mounted) {
      setState(() => _variants.removeWhere((v) => identical(v, variant)));
    }
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
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size12,
                      SizeConfig.size8,
                      SizeConfig.size12,
                      SizeConfig.size12,
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
    final price =
        (variant.pricing?.isNotEmpty ?? false) ? variant.pricing![0] : null;
    // Variant image first, product image as fallback (missing OR broken).
    final variantImageUrl =
        (variant.images?.isNotEmpty ?? false) ? variant.images!.first.url : null;

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
                            '${variant.quantity ?? ''} ${variant.unit ?? ''}'.trim(),
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
