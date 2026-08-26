import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Review-and-publish screen for the food flow. Mirrors the visual
/// structure of `AddProductVariantScreen`: product-grouped cards with a
/// header strip, variant rows showing price + edit-pill, modal dialog
/// for editing selling price, and an "Add more variant" CTA per card.
class FoodCartScreen extends StatefulWidget {
  final bool isSnapSearch;
  const FoodCartScreen({super.key, this.isSnapSearch = false});

  @override
  State<FoodCartScreen> createState() => _FoodCartScreenState();
}

class _FoodCartScreenState extends State<FoodCartScreen> {
  final FoodServiceController controller =
      Get.find<FoodServiceController>();

  /// Per-variant inline error keyed by variant id. Populated when a
  /// persisted selling price exceeds MRP — blocks the publish CTA.
  final Map<String, String?> _priceErrors = {};

  final RxBool _isPublishing = false.obs;

  int _discountPercent(int mrp, int selling) {
    if (mrp <= 0 || selling >= mrp) return 0;
    return (((mrp - selling) / mrp) * 100).round();
  }

  /// The product a cart entry belongs to — its name and its PHOTO. Resolved
  /// through the controller, which checks the snapshot taken when the variant
  /// was ticked before falling back to searching the loaded lists: a dish
  /// picked off a Quick Upload rail is not in `categoryFoundProductDataList`,
  /// which is all this used to look at, so those cards rendered as "Product"
  /// over a placeholder.
  CategoryFoodProductData? _productFor(String productId) =>
      controller.productById(productId);

  String _variantLabel(FoodVariants v) {
    return [v.variantName, v.quantityLabel]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • ');
  }

  void _removeVariant(String productId, FoodVariants variant) {
    final list = List<FoodVariants>.from(
      controller.selectedVariantsMap[productId] ?? <FoodVariants>[],
    );
    list.removeWhere((v) => v.id == variant.id);
    if (list.isEmpty) {
      controller.selectedVariantsMap.remove(productId);
      controller.forgetSelectedProduct(productId);
    } else {
      controller.selectedVariantsMap[productId] = list;
    }
    controller.selectedVariantsMap.refresh();
    setState(() => _priceErrors.remove(variant.id));
  }

  /// Mirrors the new price into both the cart entry and the live
  /// product list so the variant sheet shows the same number next time.
  void _persistSellingPrice(
      String productId, FoodVariants variant, int newPrice) {
    final list = List<FoodVariants>.from(
      controller.selectedVariantsMap[productId] ?? <FoodVariants>[],
    );
    final idx = list.indexWhere((v) => v.id == variant.id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(baseSellingPrice: newPrice);
      controller.selectedVariantsMap[productId] = list;
      controller.selectedVariantsMap.refresh();
    }
    final variantId = variant.id ?? '';
    controller.updateLocalVariantPrice(
      productId,
      variantId,
      newPrice,
      variant.mrp ?? 0,
    );
    if (_priceErrors[variantId] != null) {
      setState(() => _priceErrors[variantId] = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedMap = controller.selectedVariantsMap;
      final productIds = selectedMap.keys.toList();
      final allVariants = selectedMap.values.expand((e) => e).toList();
      final isLoading = _isPublishing.value;

      final totalSelling = allVariants.fold<int>(
        0,
        (sum, v) => sum + (v.baseSellingPrice ?? 0),
      );

      return Scaffold(
        appBar: CommonBackAppBar(title: 'Review & Publish'),
        bottomNavigationBar: _bottomBar(
          selectedCount: allVariants.length,
          isLoading: isLoading,
          totalSelling: totalSelling,
        ),
        body: AbsorbPointer(
          absorbing: isLoading,
          child: allVariants.isEmpty
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
                        selectedMap[pid] ?? const <FoodVariants>[];
                    if (variants.isEmpty) return const SizedBox.shrink();
                    return _selectedProductCard(pid, variants);
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
    required int totalSelling,
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
                    '${AppConstants.rupeeSymbol}$totalSelling',
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
                    ? 'Add $selectedCount ${selectedCount == 1 ? "item" : "items"} to my inventory'
                    : 'Add to my inventory',
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedProductCard(
      String productId, List<FoodVariants> variants) {
    final product = _productFor(productId);
    final imageUrl = product?.images?.firstOrNull ?? '';

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
                        product?.name ?? 'Product',
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size4,
              SizeConfig.size12,
              SizeConfig.size8,
            ),
            child: Column(
              children: [
                for (int i = 0; i < variants.length; i++) ...[
                  _variantRow(productId, variants[i]),
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

  Widget _variantRow(String productId, FoodVariants variant) {
    final variantId = variant.id ?? '';
    final variantLabel = _variantLabel(variant);
    final hasError = _priceErrors[variantId] != null;
    final mrp = variant.mrp ?? 0;
    final selling = variant.baseSellingPrice ?? 0;
    final discount = _discountPercent(mrp, selling);
    final showStrike = mrp > selling;

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
                onTap: () => _removeVariant(productId, variant),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomText(
                '${AppConstants.rupeeSymbol}$selling',
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w700,
                color: hasError ? AppColors.red : AppColors.mainTextColor,
              ),
              if (showStrike) ...[
                SizedBox(width: SizeConfig.size8),
                CustomText(
                  '${AppConstants.rupeeSymbol}$mrp',
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
                onTap: () => _openEditSellingPriceDialog(productId, variant),
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
          ),
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
                        _priceErrors[variantId]!,
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

  /// Modal dialog for updating a variant's selling price — mirrors the
  /// product cart's edit dialog. Validates against MRP locally before
  /// persisting via [_persistSellingPrice].
  void _openEditSellingPriceDialog(String productId, FoodVariants variant) {
    final mrp = variant.mrp ?? 0;
    final initial = (variant.baseSellingPrice ?? 0).toString();
    final textController = TextEditingController(text: initial);
    final localError = Rxn<String>();
    final product = _productFor(productId);

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
                  (product?.name ?? '').isNotEmpty
                      ? product!.name ?? 'Edit selling price'
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
                      '${AppConstants.rupeeSymbol}$mrp',
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
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
                                final parsed = int.tryParse(value.trim());
                                if (parsed != null && parsed > mrp) {
                                  localError.value =
                                      'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}$mrp)';
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
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          localError.value =
                              'Enter a valid selling price';
                          return;
                        }
                        if (parsed > mrp) {
                          localError.value =
                              'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}$mrp)';
                          return;
                        }
                        _persistSellingPrice(productId, variant, parsed);
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

  Future<void> _handlePublish(BuildContext context) async {
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

    _isPublishing.value = true;
    try {
      controller.bulkPublishInventory(isSnapSearch: widget.isSnapSearch);
    } finally {
      _isPublishing.value = false;
    }
  }
}
