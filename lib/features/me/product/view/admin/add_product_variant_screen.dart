import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_catalog_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AddProductVariantScreen extends StatefulWidget {
  const AddProductVariantScreen({super.key});

  @override
  State<AddProductVariantScreen> createState() =>
      _AddProductVariantScreenState();
}

class _AddProductVariantScreenState extends State<AddProductVariantScreen> {
  final productController = getOrPut(() => ProductController());
  late final InventoryController inventoryController;

  /// Per-variant inline error message keyed by variant id. Mirrors the
  /// validation pattern in [ProductCartScreen] — a selling price > MRP
  /// is held in the field but never written into
  /// [InventoryController.variantSellingPrice], and blocks publish.
  final Map<String, String?> _priceErrors = {};

  @override
  void initState() {
    super.initState();
    inventoryController = Get.put(InventoryController());

    // Make sure every visible variant is marked selected in the
    // inventory controller (publish reads from there).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in productController.selectedProducts) {
        inventoryController.variantSelection[row.id] = true;
      }
    });
  }

  /// Source of truth for "what's in the cart". Falls back to the
  /// inventory controller's [selectedVariantsList] when the product
  /// controller list is empty (snap-search flow assigns there first).
  List<SelectedVariant> get _allSelectedVariants {
    if (productController.selectedProducts.isNotEmpty) {
      return productController.selectedProducts.toList();
    }
    return inventoryController.selectedVariantsList.toList();
  }

  /// Group the flat variant list by product id so each product card
  /// renders once with its variants nested underneath (matches
  /// grocery's product → variants nesting).
  Map<String, List<SelectedVariant>> _groupedByProduct(
      List<SelectedVariant> list) {
    final grouped = <String, List<SelectedVariant>>{};
    for (final v in list) {
      grouped.putIfAbsent(v.product.id, () => []).add(v);
    }
    return grouped;
  }

  double _effectiveSellingPrice(SelectedVariant v) {
    final overridden = inventoryController.variantSellingPrice[v.id];
    if (overridden != null && overridden.trim().isNotEmpty) {
      return double.tryParse(overridden) ?? v.variant.sellingPrice;
    }
    return v.variant.sellingPrice;
  }

  double _effectiveMrp(SelectedVariant v) =>
      inventoryController.effectiveMrp(v);

  int _discountPercent(double mrp, double selling) {
    if (mrp <= 0 || selling >= mrp) return 0;
    return (((mrp - selling) / mrp) * 100).round();
  }

  void _removeVariant(SelectedVariant row) {
    final id = row.id;
    inventoryController.variantSelection.remove(id);
    inventoryController.variantSellingPrice.remove(id);
    inventoryController.variantMrp.remove(id);
    inventoryController.selectedVariantsList.removeWhere((v) => v.id == id);
    productController.toggleProductSelection(row);
    setState(() => _priceErrors.remove(id));
  }

  String _variantLabel(Variant variant) {
    final parts = variant.attributes.entries.map((entry) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (key == 'color' && value is Map<String, dynamic>) {
        return (value['color_name'] ?? '').toString();
      } else if (value != null) {
        return value.toString();
      }
      return '';
    }).where((s) => s.isNotEmpty);
    return parts.join(' • ');
  }

  // Accent gradient shared with the floating-cart language across the app
  // (primary → deep-blue), used on the publish bar, card edge stripes and
  // price chips to tie the screen together.
  static const LinearGradient _accent = LinearGradient(
    colors: [AppColors.primaryColor, AppColors.blue5CAF],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Tinted canvas behind the cards so the white surfaces read as raised
  /// rather than sitting flat on a white screen.
  static const Color _canvas = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = inventoryController.cloneProductVariantLoading.value;
      final selected = _allSelectedVariants;
      final grouped = _groupedByProduct(selected);
      final productIds = grouped.keys.toList();

      final totalSelling = selected.fold<double>(
        0,
        (sum, v) => sum + _effectiveSellingPrice(v),
      );
      final totalMrp = selected.fold<double>(
        0,
        (sum, v) => sum + _effectiveMrp(v),
      );
      final totalSavings = (totalMrp - totalSelling).clamp(0, double.infinity);

      return Scaffold(
        backgroundColor: _canvas,
        appBar: CommonBackAppBar(title: 'Review & Publish'),
        bottomNavigationBar: _bottomBar(
          selectedCount: selected.length,
          isLoading: isLoading,
          totalSelling: totalSelling,
          totalSavings: totalSavings.toDouble(),
        ),
        body: AbsorbPointer(
          absorbing: isLoading,
          child: selected.isEmpty
              ? _emptyState()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _summaryHeader(
                        productCount: productIds.length,
                        variantCount: selected.length,
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        SizeConfig.size12,
                        0,
                        SizeConfig.size12,
                        SizeConfig.size16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final pid = productIds[index];
                            final variants =
                                grouped[pid] ?? const <SelectedVariant>[];
                            if (variants.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _selectedProductCard(variants);
                          },
                          childCount: productIds.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  /// Editorial intro strip — frames the screen as a final review step and
  /// gives the otherwise list-only screen a confident opening.
  Widget _summaryHeader({
    required int productCount,
    required int variantCount,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
              gradient: _accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  'Confirm your prices',
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  letterSpacing: 0.1,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  '$productCount ${productCount == 1 ? 'product' : 'products'} • $variantCount ${variantCount == 1 ? 'variant' : 'variants'} ready to publish',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.size24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: SizeConfig.size40 + SizeConfig.size16,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'No variants in cart',
              fontSize: SizeConfig.large18,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              'Pick products and variants from your inventory to publish them to your store.',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.center,
              height: 1.4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar({
    required int selectedCount,
    required bool isLoading,
    required double totalSelling,
    required double totalSavings,
  }) {
    final hasItems = selectedCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size14,
        SizeConfig.size16,
        SizeConfig.size12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (hasItems) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    'Total payable',
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    '${AppConstants.rupeeSymbol}${totalSelling.toStringAsFixed(0)}',
                    fontSize: SizeConfig.large18 + 2,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                  if (totalSavings > 0) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      'Saves ${AppConstants.rupeeSymbol}${totalSavings.toStringAsFixed(0)}',
                      fontSize: SizeConfig.extraSmall,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ],
              ),
              SizedBox(width: SizeConfig.size16),
            ],
            Expanded(
              child: _publishButton(
                hasItems: hasItems,
                isLoading: isLoading,
                count: selectedCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gradient publish CTA with an inline loading state. Replaces the generic
  /// [CustomBtn] so the button carries the screen's accent gradient + a soft
  /// glow, and dims to a flat disabled fill when nothing is selected.
  Widget _publishButton({
    required bool hasItems,
    required bool isLoading,
    required int count,
  }) {
    final enabled = hasItems && !isLoading;
    return GestureDetector(
      onTap: enabled ? () => _handlePublish(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: SizeConfig.size45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled ? _accent : null,
          color: enabled ? null : AppColors.greyE5,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    hasItems
                        ? 'Publish $count ${count == 1 ? "variant" : "variants"}'
                        : 'Publish',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w800,
                    color: hasItems
                        ? AppColors.white
                        : AppColors.secondaryTextColor,
                    letterSpacing: 0.2,
                  ),
                  if (hasItems) ...[
                    SizedBox(width: SizeConfig.size6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _selectedProductCard(List<SelectedVariant> variants) {
    final product = variants.first.product;
    final imageUrl = variants.first.primaryImageUrl;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildProductImage(imageUrl),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CustomText(
                      product.name,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w800,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            // Variant tiles
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size4,
                SizeConfig.size12,
                SizeConfig.size12,
              ),
              child: Column(
                children: [
                  for (int i = 0; i < variants.length; i++) ...[
                    _variantRow(product.id, variants[i]),
                    if (i < variants.length - 1)
                      SizedBox(height: SizeConfig.size8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            height: SizeConfig.size80,
            width: SizeConfig.size80,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              height: SizeConfig.size80,
              width: SizeConfig.size80,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
              height: SizeConfig.size80,
              width: SizeConfig.size80,
            ),
          )
        : LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.fill,
            height: SizeConfig.size80,
            width: SizeConfig.size80,
          );
  }

  Widget _variantRow(String productId, SelectedVariant variantData) {
    final variant = variantData.variant;
    final variantLabel = _variantLabel(variant);
    final hasError = _priceErrors[variant.id] != null;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: hasError ? AppColors.red.withValues(alpha: 0.04) : _canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.red.withValues(alpha: 0.3)
              : AppColors.greyE5.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant identity chip + remove
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: SizeConfig.size4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.style_outlined,
                        size: SizeConfig.size14,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      Flexible(
                        child: CustomText(
                          variantLabel.isNotEmpty
                              ? variantLabel
                              : 'Default variant',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              InkWell(
                onTap: () => _removeVariant(variantData),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          // Price block — BOTH selling price and MRP, clearly labelled.
          Obx(() {
            final overridden =
                inventoryController.variantSellingPrice[variant.id];
            final displaySelling =
                (overridden != null && overridden.trim().isNotEmpty)
                    ? overridden
                    : variant.sellingPrice.toStringAsFixed(0);
            final sellingNum =
                double.tryParse(displaySelling) ?? variant.sellingPrice;
            // Read the overridden MRP map so an edit re-renders the card.
            final mrpOverride = inventoryController.variantMrp[variant.id];
            final mrpNum =
                (mrpOverride != null && mrpOverride.trim().isNotEmpty)
                    ? (double.tryParse(mrpOverride) ?? variant.mrp)
                    : variant.mrp;
            final discount = _discountPercent(mrpNum, sellingNum);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Selling price
                _priceCell(
                  label: 'Selling price',
                  value:
                      '${AppConstants.rupeeSymbol}${sellingNum.toStringAsFixed(0)}',
                  valueColor: hasError ? AppColors.red : AppColors.primaryColor,
                  valueSize: SizeConfig.large18 + 1,
                ),
                SizedBox(width: SizeConfig.size16),
                // MRP
                _priceCell(
                  label: 'MRP',
                  value:
                      '${AppConstants.rupeeSymbol}${mrpNum.toStringAsFixed(0)}',
                  valueColor: AppColors.secondaryTextColor,
                  valueSize: SizeConfig.medium,
                  strike: mrpNum > sellingNum,
                ),
                if (discount > 0) ...[
                  SizedBox(width: SizeConfig.size8),
                  Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size2),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size6,
                        vertical: SizeConfig.size2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: Colors.green.shade200, width: 1),
                      ),
                      child: CustomText(
                        '$discount% OFF',
                        fontSize: SizeConfig.extraSmall,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Edit selling price
                InkWell(
                  onTap: () => _openEditSellingPriceDialog(variantData),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.pen_line,
                          imgColor: AppColors.primaryColor,
                          height: SizeConfig.size14,
                          width: SizeConfig.size14,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          AppStrings.edit,
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          if (hasError)
            Padding(
              padding: EdgeInsets.only(top: SizeConfig.size8),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.red,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                    child: CustomText(
                      _priceErrors[variant.id]!,
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A small labelled price cell — used to render the selling price and MRP
  /// side by side so both are always visible on the card.
  Widget _priceCell({
    required String label,
    required String value,
    required Color valueColor,
    required double valueSize,
    bool strike = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          label.toUpperCase(),
          fontSize: SizeConfig.extraSmall - 1,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
          letterSpacing: 0.5,
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          value,
          fontSize: valueSize,
          fontWeight: FontWeight.w800,
          color: valueColor,
          decoration: strike ? TextDecoration.lineThrough : null,
          decorationColor: AppColors.secondaryTextColor,
        ),
      ],
    );
  }

  /// Edit BOTH the MRP and the selling price for a single variant.
  /// Validation rules (enforced live and on save):
  ///  • MRP must be greater than 0
  ///  • Selling price must be greater than 0
  ///  • Selling price must NOT exceed the MRP
  /// Invalid values are never written into the controller.
  void _openEditSellingPriceDialog(SelectedVariant variantData) {
    final variant = variantData.variant;
    final imageUrl = variantData.primaryImageUrl;
    final mrpController = TextEditingController(
      text: inventoryController.variantMrp[variant.id] ??
          variant.mrp.toStringAsFixed(0),
    );
    final sellingController = TextEditingController(
      text: inventoryController.variantSellingPrice[variant.id] ??
          variant.sellingPrice.toStringAsFixed(0),
    );
    final mrpError = Rxn<String>();
    final sellingError = Rxn<String>();
    // Live preview of the resulting discount, shown between the fields and
    // the actions so the merchant sees the effect of their numbers instantly.
    final discount = 0.obs;
    final savings = 0.0.obs;

    void recompute() {
      final mrp = double.tryParse(mrpController.text.trim());
      final sp = double.tryParse(sellingController.text.trim());
      mrpError.value = (mrp == null || mrp <= 0) ? 'Enter a valid MRP' : null;
      if (sp == null || sp <= 0) {
        sellingError.value = 'Enter a valid selling price';
      } else if (mrp != null && sp > mrp) {
        sellingError.value =
            'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)})';
      } else {
        sellingError.value = null;
      }
      if (mrp != null && sp != null && mrp > 0 && sp > 0 && sp <= mrp) {
        discount.value = (((mrp - sp) / mrp) * 100).round();
        savings.value = mrp - sp;
      } else {
        discount.value = 0;
        savings.value = 0;
      }
    }

    recompute();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size24,
            vertical: SizeConfig.size24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient header: thumbnail + name + close ──────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(SizeConfig.size14),
                decoration: const BoxDecoration(gradient: _accent),
                child: Row(
                  children: [
                    Container(
                      width: SizeConfig.size45,
                      height: SizeConfig.size45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => LocalAssets(
                                  imagePath: AppIconAssets.place_holder_image,
                                  boxFix: BoxFit.cover,
                                ),
                              )
                            : LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            'EDIT PRICE',
                            fontSize: SizeConfig.extraSmall - 1,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 1,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            variantData.product.name.isNotEmpty
                                ? variantData.product.name
                                : 'Variant price',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    InkWell(
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(SizeConfig.size4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _priceField(
                      label: 'MRP',
                      controller: mrpController,
                      error: mrpError,
                      onChanged: (_) => recompute(),
                    ),
                    SizedBox(height: SizeConfig.size14),
                    _priceField(
                      label: 'Selling price',
                      controller: sellingController,
                      error: sellingError,
                      autofocus: true,
                      onChanged: (_) => recompute(),
                    ),
                    // Live discount preview
                    Obx(() {
                      if (discount.value <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.size14),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sell_rounded,
                                  size: 16, color: Colors.green.shade700),
                              SizedBox(width: SizeConfig.size8),
                              CustomText(
                                '${discount.value}% OFF',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                              ),
                              const Spacer(),
                              CustomText(
                                'You save ${AppConstants.rupeeSymbol}${savings.value.toStringAsFixed(0)}',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: SizeConfig.size20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.of(dialogCtx).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: SizeConfig.size45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.fillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.greyE5),
                              ),
                              child: CustomText(
                                AppStrings.cancel,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              recompute();
                              if (mrpError.value != null ||
                                  sellingError.value != null) {
                                return;
                              }
                              // Persist both, clear any prior row-level error.
                              inventoryController.updateMrp(
                                  variant.id, mrpController.text.trim());
                              inventoryController.updateSellingPrice(
                                  variant.id, sellingController.text.trim());
                              setState(() => _priceErrors.remove(variant.id));
                              Navigator.of(dialogCtx).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: SizeConfig.size45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: _accent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CustomText(
                                AppStrings.save,
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Reusable rupee-prefixed price input with an inline error, used for both
  /// the MRP and selling-price fields in the edit dialog.
  Widget _priceField({
    required String label,
    required TextEditingController controller,
    required Rxn<String> error,
    required ValueChanged<String> onChanged,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          label.toUpperCase(),
          fontSize: SizeConfig.extraSmall,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
          letterSpacing: 0.4,
        ),
        SizedBox(height: SizeConfig.size6),
        Obx(() {
          final err = error.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: err != null ? AppColors.red : AppColors.greyE5,
                    width: 1.2,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: SizeConfig.size45,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          AppConstants.rupeeSymbol,
                          fontSize: SizeConfig.large,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: autofocus,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          textAlignVertical: TextAlignVertical.center,
                          cursorColor: AppColors.primaryColor,
                          style: TextStyle(
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                            letterSpacing: 0.3,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size12,
                              vertical: SizeConfig.size14,
                            ),
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          onChanged: onChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (err != null)
                Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size6),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: AppColors.red),
                      SizedBox(width: SizeConfig.size4),
                      Expanded(
                        child: CustomText(
                          err,
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  /// Validate every selected variant (valid MRP + selling price, MRP ≥
  /// selling) and publish. Un-edited variants publish their displayed default
  /// price — the payload falls back to `variant.sellingPrice` when there's no
  /// manual override — so there's no "use listed prices" confirmation step.
  Future<void> _handlePublish(BuildContext context) async {
    final variants = _allSelectedVariants;
    if (variants.isEmpty) return;

    // Every selected variant must carry BOTH a valid MRP and selling price,
    // with the MRP greater than or equal to the selling price. Offending
    // variants are flagged inline (red tile) and publish is blocked.
    _priceErrors.clear();
    String? firstError;
    for (final v in variants) {
      final mrp = _effectiveMrp(v);
      final selling = _effectiveSellingPrice(v);
      String? err;
      if (mrp <= 0) {
        err = 'Add a valid MRP';
      } else if (selling <= 0) {
        err = 'Add a valid selling price';
      } else if (selling > mrp) {
        err = 'Selling price can’t exceed MRP';
      }
      if (err != null) {
        _priceErrors[v.id] = err;
        firstError ??= err;
      }
    }
    if (firstError != null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            'Check MRP & selling price — $firstError.',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // No "use listed prices" confirmation here: the validation above already
    // guarantees every selected variant has a valid MRP + selling price, and
    // the publish payload sends exactly the price shown on the card
    // (`variantSellingPrice[id] ?? variant.sellingPrice`). A variant the user
    // didn't manually edit simply publishes its displayed default price — so
    // prompting "some variants use the default price" was redundant and read
    // as an error when nothing was wrong.
    final providerType =
        productController.ownerProviderType ?? ProviderType.business;

    inventoryController.cloneProductVariantApi(
      providerType: providerType,
      variants: variants,
    );
  }
}
