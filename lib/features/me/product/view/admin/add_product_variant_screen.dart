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
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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

  int _discountPercent(double mrp, double selling) {
    if (mrp <= 0 || selling >= mrp) return 0;
    return (((mrp - selling) / mrp) * 100).round();
  }

  void _removeVariant(SelectedVariant row) {
    final id = row.id;
    inventoryController.variantSelection.remove(id);
    inventoryController.variantSellingPrice.remove(id);
    inventoryController.selectedVariantsList.removeWhere((v) => v.id == id);
    productController.toggleProductSelection(row);
    setState(() => _priceErrors.remove(id));
  }

  /// Copied validation from [ProductCartScreen._onSellingPriceChanged]
  /// — red border + inline error when selling price exceeds MRP, and
  /// the bad value is NOT written into the controller.
  void _onSellingPriceChanged(String variantId, String value, double mrp) {
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed != null && parsed > mrp) {
      setState(() {
        _priceErrors[variantId] =
            'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)})';
      });
      return;
    }
    if (_priceErrors[variantId] != null) {
      setState(() => _priceErrors[variantId] = null);
    }
    inventoryController.updateSellingPrice(variantId, trimmed);
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

      return Scaffold(
        appBar: CommonBackAppBar(),
        bottomNavigationBar: _bottomBar(
          selectedCount: selected.length,
          isLoading: isLoading,
          totalSelling: totalSelling,
        ),
        body: AbsorbPointer(
          absorbing: isLoading,
          child: selected.isEmpty
              ? _emptyState()
              : ListView.builder(
                  itemCount: productIds.length,
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size12,
                    SizeConfig.size12,
                    SizeConfig.size12,
                    SizeConfig.size16,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final pid = productIds[index];
                    final variants =
                        grouped[pid] ?? const <SelectedVariant>[];
                    if (variants.isEmpty) return const SizedBox.shrink();
                    return _selectedProductCard(variants);
                  },
                ),
        ),
      );
    });
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
  }) {
    final hasItems = selectedCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size12,
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
                    'Total',
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    '${AppConstants.rupeeSymbol}${totalSelling.toStringAsFixed(0)}',
                    fontSize: SizeConfig.large18,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              SizedBox(width: SizeConfig.size16),
            ],
            Expanded(
              child: CustomBtn(
                onTap: hasItems && !isLoading
                    ? () => _handlePublish(context)
                    : null,
                isValidate: hasItems,
                radius: SizeConfig.size10,
                bgColor: hasItems ? AppColors.primaryColor : Colors.grey,
                title: hasItems
                    ? 'Publish $selectedCount ${selectedCount == 1 ? "variant" : "variants"}'
                    : 'Publish',
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedProductCard(List<SelectedVariant> variants) {
    final product = variants.first.product;
    final imageUrl = variants.first.primaryImageUrl;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header strip
          Container(
            padding: EdgeInsets.all(SizeConfig.size12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildProductImage(imageUrl),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        product.name,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        height: 1.25,
                      ),
                      SizedBox(height: SizeConfig.size6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size8,
                          vertical: SizeConfig.size3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText(
                          '${variants.length} ${variants.length == 1 ? "variant" : "variants"} selected',
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Variant rows
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size4,
            ),
            child: Column(
              children: [
                for (int i = 0; i < variants.length; i++) ...[
                  _variantRow(product.id, variants[i]),
                  if (i < variants.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.greyE5.withValues(alpha: 0.6),
                    ),
                ],
              ],
            ),
          ),
          // Add-more-variant CTA. Mirrors grocery's
          // `GroceryController.openAddVariantDialog` →
          // `createNewGroceryProductNewVariant` flow, but hits the
          // product-service `/products/<id>/variants` endpoint instead.
          InkWell(
            onTap: () {
              inventoryController.openAddVariantDialog(
                context: context,
                productId: product.id,
              );
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size12,
                horizontal: SizeConfig.size12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.greyE5.withValues(alpha: 0.7),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.add_circled,
                    color: AppColors.primaryColor,
                    size: 18,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.productViewAddMoreVariant.tr,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small,
                  ),
                ],
              ),
            ),
          ),
        ],
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

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CustomText(
                  variantLabel.isNotEmpty ? variantLabel : 'Default variant',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  letterSpacing: 0.2,
                ),
              ),
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
          SizedBox(height: SizeConfig.size8),
          Obx(() {
            final overridden =
                inventoryController.variantSellingPrice[variant.id];
            final displaySelling =
                (overridden != null && overridden.trim().isNotEmpty)
                    ? overridden
                    : variant.sellingPrice.toStringAsFixed(0);
            final sellingNum =
                double.tryParse(displaySelling) ?? variant.sellingPrice;
            final mrpNum = variant.mrp;
            final discount = _discountPercent(mrpNum, sellingNum);
            final showStrike = mrpNum > sellingNum;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  '${AppConstants.rupeeSymbol}$displaySelling',
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w700,
                  color:
                      hasError ? AppColors.red : AppColors.mainTextColor,
                ),
                if (showStrike) ...[
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    '${AppConstants.rupeeSymbol}${mrpNum.toStringAsFixed(0)}',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.secondaryTextColor,
                  ),
                ],
                if (discount > 0) ...[
                  SizedBox(width: SizeConfig.size8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size6,
                      vertical: SizeConfig.size2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.green.shade100,
                        width: 1,
                      ),
                    ),
                    child: CustomText(
                      '$discount% OFF',
                      fontSize: SizeConfig.extraSmall,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  onTap: () => _openEditSellingPriceDialog(variantData),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
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
                          fontWeight: FontWeight.w600,
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
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Small dialog to update the selling price for a single variant —
  /// mirrors grocery's edit-variant dialog flow. Validates against
  /// MRP using the same rule as [ProductCartScreen].
  void _openEditSellingPriceDialog(SelectedVariant variantData) {
    final variant = variantData.variant;
    final initial = inventoryController.variantSellingPrice[variant.id] ??
        variant.sellingPrice.toStringAsFixed(0);
    final textController = TextEditingController(text: initial);
    final localError = Rxn<String>();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size24,
            vertical: SizeConfig.size24,
          ),
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  variantData.product.name.isNotEmpty
                      ? variantData.product.name
                      : 'Edit selling price',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size4),
                Row(
                  children: [
                    CustomText(
                      'MRP',
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      '${AppConstants.rupeeSymbol}${variant.mrp.toStringAsFixed(0)}',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size16),
                Obx(() {
                  final err = localError.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.fillColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            err != null ? AppColors.red : AppColors.greyE5,
                        width: 1,
                      ),
                    ),
                    // IntrinsicHeight + stretch lets the rupee prefix
                    // match the TextField's natural height instead of
                    // being pinned to a fixed `size45`, which previously
                    // left the input visibly shorter than the prefix.
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: SizeConfig.size45,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(9),
                                bottomLeft: Radius.circular(9),
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
                              controller: textController,
                              autofocus: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                              onChanged: (value) {
                                final parsed =
                                    double.tryParse(value.trim());
                                if (parsed != null &&
                                    parsed > variant.mrp) {
                                  localError.value =
                                      'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}${variant.mrp.toStringAsFixed(0)})';
                                } else {
                                  localError.value = null;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Obx(() {
                  final err = localError.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: AppColors.red,
                        ),
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
                  );
                }),
                SizedBox(height: SizeConfig.size20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size10,
                        ),
                      ),
                      child: CustomText(
                        AppStrings.cancel,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size20,
                          vertical: SizeConfig.size10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final value = textController.text.trim();
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed > variant.mrp) {
                          localError.value =
                              'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}${variant.mrp.toStringAsFixed(0)})';
                          return;
                        }
                        // Persist + clear any prior row-level error.
                        _onSellingPriceChanged(
                            variant.id, value, variant.mrp);
                        Navigator.of(dialogCtx).pop();
                      },
                      child: const CustomText(
                        AppStrings.save,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Copied verbatim from [ProductCartScreen._handlePublish] — same
  /// MRP validation, same "use listed prices" confirmation dialog
  /// for variants missing a manual selling price, same ownerID /
  /// providerType resolution from [ProductController].
  Future<void> _handlePublish(BuildContext context) async {
    final variants = _allSelectedVariants;
    if (variants.isEmpty) return;

    final hasInvalidPrice =
        _priceErrors.values.any((err) => err != null && err.isNotEmpty);
    if (hasInvalidPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            'Fix selling prices that exceed MRP before publishing.',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final missingPriceIds =
        inventoryController.validateSelectedVariants(variants);

    if (missingPriceIds.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const CustomText(
              AppStrings.useListedPrices,
              fontWeight: FontWeight.bold,
            ),
            content: const CustomText(AppStrings.useListedPricesMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const CustomText(AppStrings.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const CustomText(
                  AppStrings.continueText,
                  color: AppColors.white,
                ),
              ),
            ],
          );
        },
      );

      if (proceed != true) return;

      inventoryController.fillMissingSellingPricesWithDefaults(
        variants,
        missingPriceIds,
      );
    }

    final providerType =
        productController.ownerProviderType ?? ProviderType.business;

    inventoryController.cloneProductVariantApi(
      providerType: providerType,
      variants: variants,
    );
  }
}
