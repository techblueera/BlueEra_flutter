import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Review-and-publish screen for the food flow, modelled on
/// `ProductCartScreen`. Lists every variant the merchant has ticked in
/// the variant bottom sheet, lets them tweak the selling price inline
/// (capped at the variant's MRP), and publishes the batch via
/// [FoodServiceController.bulkPublishInventory].
class FoodCartScreen extends StatefulWidget {
  final bool isSnapSearch;
  const FoodCartScreen({super.key, this.isSnapSearch = false});

  @override
  State<FoodCartScreen> createState() => _FoodCartScreenState();
}

class _FoodCartScreenState extends State<FoodCartScreen> {
  final FoodServiceController controller =
      Get.find<FoodServiceController>();

  /// Per-variant inline error message keyed by variant id. Populated
  /// when the merchant types a selling price that exceeds MRP — blocks
  /// the publish CTA.
  final Map<String, String?> _priceErrors = {};

  /// Cached text-field controllers keyed by variant id so the field
  /// keeps its cursor / focus across rebuilds.
  final Map<String, TextEditingController> _priceCtrls = {};

  @override
  void dispose() {
    for (final c in _priceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(String variantId, int initial) {
    return _priceCtrls.putIfAbsent(
      variantId,
      () => TextEditingController(text: initial.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: 'Review & Publish'),
      bottomNavigationBar: _buildBottomBar(),
      body: Obx(() {
        final items = _flattenItems();
        if (items.isEmpty) return _emptyState();
        return Column(
          children: [
            _buildHeader(items.length),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12,
                  vertical: SizeConfig.size8,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _buildCartCard(items[i]),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Flattens `selectedVariantsMap` into one row per variant, looking
  /// up the matching live product so we can render image / name / tags.
  List<_FoodCartRow> _flattenItems() {
    final rows = <_FoodCartRow>[];
    controller.selectedVariantsMap.forEach((productId, variants) {
      final product = controller.categoryFoundProductDataList
          .firstWhereOrNull((p) => p.id == productId);
      for (final variant in variants) {
        rows.add(_FoodCartRow(
          productId: productId,
          product: product,
          variant: variant,
        ));
      }
    });
    return rows;
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.greyE5),
          SizedBox(height: SizeConfig.size15),
          CustomText(
            'No variants selected',
            fontSize: SizeConfig.large,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            'Pick variants from the product list to start.',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size15,
        vertical: SizeConfig.size12,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
              vertical: SizeConfig.size4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              '$count ${count == 1 ? 'Variant' : 'Variants'}',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const Spacer(),
          CustomText(
            'Set selling price for each variant',
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard(_FoodCartRow row) {
    final product = row.product;
    final variant = row.variant;
    final variantId = variant.id ?? '';
    final mrp = variant.mrp ?? 0;
    final sellingPrice = variant.baseSellingPrice ?? 0;
    final imageUrl = product?.images?.firstOrNull ?? '';
    final discount = mrp > 0
        ? ((mrp - sellingPrice) / mrp * 100).round()
        : 0;
    final variantLabel = [
      variant.variantName,
      variant.quantityLabel,
    ].where((s) => s != null && s.isNotEmpty).join(' • ');

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.fillColor,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.fillColor,
                              child: LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.fillColor,
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        product?.name ?? 'Product',
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variantLabel.isNotEmpty) ...[
                        SizedBox(height: SizeConfig.size4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.boxBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText(
                            variantLabel,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                      SizedBox(height: SizeConfig.size8),
                      PriceRow(
                        sellingPrice:
                            '${AppConstants.rupeeSymbol}$sellingPrice',
                        mrp: '${AppConstants.rupeeSymbol}$mrp',
                        discount: discount > 0 ? '$discount% off' : null,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeVariant(row.productId, variant),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppColors.whiteF3,
            margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.primaryColor),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      'Your Selling Price',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(child: _buildPriceField(row, mrp)),
                  ],
                ),
                if (_priceErrors[variantId] != null) ...[
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 14, color: AppColors.red),
                      SizedBox(width: SizeConfig.size4),
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(_FoodCartRow row, int mrp) {
    final variantId = row.variant.id ?? '';
    final initial = row.variant.baseSellingPrice ?? 0;
    final ctrl = _ctrlFor(variantId, initial);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.fillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _priceErrors[variantId] != null
                ? AppColors.red
                : AppColors.greyE5,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
              ),
              alignment: Alignment.center,
              child: CustomText(
                AppConstants.rupeeSymbol,
                fontSize: SizeConfig.medium,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (value) =>
                    _onSellingPriceChanged(row, value, mrp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSellingPriceChanged(_FoodCartRow row, String value, int mrp) {
    final variantId = row.variant.id ?? '';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      if (_priceErrors[variantId] != null) {
        setState(() => _priceErrors[variantId] = null);
      }
      return;
    }
    if (parsed > mrp) {
      setState(() {
        _priceErrors[variantId] =
            'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}$mrp)';
      });
      return;
    }
    if (_priceErrors[variantId] != null) {
      setState(() => _priceErrors[variantId] = null);
    }
    _persistSellingPrice(row, parsed);
  }

  /// Mirrors the new price into both the cart entry (so publish picks
  /// it up) and the live product list (so the bottom sheet shows the
  /// same number next time it opens).
  void _persistSellingPrice(_FoodCartRow row, int newPrice) {
    final pId = row.productId;
    final variantId = row.variant.id ?? '';
    final mrp = row.variant.mrp ?? 0;

    final list = List<FoodVariants>.from(
      controller.selectedVariantsMap[pId] ?? <FoodVariants>[],
    );
    final idx = list.indexWhere((v) => v.id == variantId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(baseSellingPrice: newPrice);
      controller.selectedVariantsMap[pId] = list;
      controller.selectedVariantsMap.refresh();
    }
    controller.updateLocalVariantPrice(pId, variantId, newPrice, mrp);
  }

  void _removeVariant(String productId, FoodVariants variant) {
    final list = List<FoodVariants>.from(
      controller.selectedVariantsMap[productId] ?? <FoodVariants>[],
    );
    list.removeWhere((v) => v.id == variant.id);
    if (list.isEmpty) {
      controller.selectedVariantsMap.remove(productId);
    } else {
      controller.selectedVariantsMap[productId] = list;
    }
    controller.selectedVariantsMap.refresh();
    // Drop the cached field controller so it re-initialises if the user
    // re-adds the same variant later.
    _priceCtrls.remove(variant.id);
    _priceErrors.remove(variant.id);
    setState(() {});
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final items = _flattenItems();
      if (items.isEmpty) return const SizedBox();
      final hasInvalid = _priceErrors.values
          .any((err) => err != null && err.isNotEmpty);
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15,
          vertical: SizeConfig.size12,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    '${items.length} ${items.length == 1 ? 'variant' : 'variants'} selected',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  Row(
                    children: [
                      Icon(
                        hasInvalid
                            ? Icons.error_outline
                            : Icons.check_circle,
                        size: 14,
                        color:
                            hasInvalid ? AppColors.red : AppColors.green00,
                      ),
                      SizedBox(width: 4),
                      CustomText(
                        hasInvalid ? 'Fix prices first' : 'Ready to publish',
                        fontSize: SizeConfig.small,
                        color:
                            hasInvalid ? AppColors.red : AppColors.green00,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size10),
              CustomBtn(
                onTap: hasInvalid ? null : _publish,
                isValidate: !hasInvalid,
                radius: SizeConfig.size8,
                title: 'Publish ${items.length} '
                    '${items.length == 1 ? 'Variant' : 'Variants'}',
              ),
            ],
          ),
        ),
      );
    });
  }

  void _publish() {
    controller.bulkPublishInventory(isSnapSearch: widget.isSnapSearch);
  }
}

class _FoodCartRow {
  final String productId;
  final CategoryFoodProductData? product;
  final FoodVariants variant;
  _FoodCartRow({
    required this.productId,
    required this.product,
    required this.variant,
  });
}
