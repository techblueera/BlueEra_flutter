import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Product quick-view sheet for the admin inventory list. Driven by the
/// `inventory/all-business-products` response shape (a product with its
/// variants, each carrying its own pricing + inventory/stock) — `GetProductData`
/// already parses that response, so this renders straight off it:
///
///  • a product header (image strip + name + brand + category),
///  • a price summary (starting price + best discount + overall stock),
///  • the description,
///  • and one row per variant with its price / MRP / discount / stock.
///
/// Intentionally its OWN layout — it does not reuse `ProductPreviewScreen`.
class ProductInventoryBottomSheet extends StatelessWidget {
  final GetProductData product;

  const ProductInventoryBottomSheet({super.key, required this.product});

  /// Opens the sheet as a draggable modal. Call from a card tap.
  static Future<void> show(
    BuildContext context, {
    required GetProductData product,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductInventoryBottomSheet(product: product),
    );
  }

  ProductDetails? get _details => product.product.details;

  List<Variant> get _variants =>
      product.product.sellerClassification?.variants ?? const [];

  List<String> get _productImages => _details?.media ?? const [];

  /// Whole-number discount % for a variant; 0 when there's no real markdown.
  int _discountPct(num selling, num mrp) {
    if (mrp <= 0 || selling <= 0 || selling >= mrp) return 0;
    return (((mrp - selling) / mrp) * 100).round();
  }

  /// Human-readable variant label from its attributes (e.g. "Black · M"),
  /// falling back to the product name when a variant has no attributes.
  String _variantTitle(Variant v) {
    final parts = <String>[];
    v.attributes.forEach((key, value) {
      if (value == null) return;
      if (key.toLowerCase() == 'color' && value is Map) {
        final name = (value['color_name'] ?? '').toString();
        if (name.isNotEmpty) parts.add(name);
      } else {
        final s = value.toString();
        if (s.isNotEmpty) parts.add(s);
      }
    });
    if (parts.isEmpty) return _details?.name ?? 'Variant';
    return parts.join(' · ');
  }

  String _firstVariantImage(Variant v) {
    if (v.mediaRelatedToVariant.isNotEmpty) return v.mediaRelatedToVariant.first;
    return _productImages.isNotEmpty ? _productImages.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final variants = _variants;
    final sellingPrices =
        variants.map((v) => v.sellingPrice).where((p) => p > 0).toList();
    final num? minSelling = sellingPrices.isEmpty
        ? null
        : sellingPrices.reduce((a, b) => a < b ? a : b);
    final int maxDiscount = variants.isEmpty
        ? 0
        : variants
            .map((v) => _discountPct(v.sellingPrice, v.mrp))
            .fold<int>(0, (a, b) => a > b ? a : b);
    final bool anyInStock = variants.any((v) => v.stock);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _grabHandle(context),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(SizeConfig.size16, 0,
                      SizeConfig.size16, SizeConfig.size20),
                  children: [
                    if (_productImages.isNotEmpty) _imageStrip(),
                    SizedBox(height: SizeConfig.size12),
                    _header(),
                    SizedBox(height: SizeConfig.size12),
                    _priceSummary(
                      single: variants.length == 1 ? variants.first : null,
                      minSelling: minSelling,
                      maxDiscount: maxDiscount,
                      anyInStock: anyInStock,
                    ),
                    if ((_details?.description ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size16),
                      _sectionTitle('Description'),
                      SizedBox(height: SizeConfig.size6),
                      ExpandableText(
                        text: _details!.description.trim(),
                        trimLines: 4,
                        expandMode: ExpandMode.dialog,
                        dialogTitle: 'Description',
                        style: TextStyle(
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                    // Only show the variants list for genuinely multi-variant
                    // products. A single-variant product is fully described by
                    // the price summary above, so a "Variants (1)" list would be
                    // redundant.
                    if (variants.length > 1) ...[
                      SizedBox(height: SizeConfig.size16),
                      Row(
                        children: [
                          _sectionTitle('Variants'),
                          SizedBox(width: SizeConfig.size6),
                          CustomText(
                            '(${variants.length})',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                      ...variants.map(_variantRow),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Pieces ──────────────────────────────────────────────────────────────

  Widget _grabHandle(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size8, SizeConfig.size10, SizeConfig.size8, SizeConfig.size4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered drag handle.
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyE5,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Close button to dismiss the sheet.
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.greyE5.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageStrip() {
    return SizedBox(
      height: SizeConfig.size150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _productImages.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: _productImages[i],
              width: SizeConfig.size150,
              height: SizeConfig.size150,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.greyE5),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.greyE5,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    final brand = (_details?.brand ?? '').trim();
    final categoryName = (_details?.category.name ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          _details?.name ?? '',
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          maxLines: 3,
        ),
        if (brand.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size4),
          CustomText(
            'by $brand',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
        if (categoryName.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size8),
          _chip(categoryName),
        ],
      ],
    );
  }

  Widget _priceSummary({
    required Variant? single,
    required num? minSelling,
    required int maxDiscount,
    required bool anyInStock,
  }) {
    // A single-variant product shows its exact price (selling + struck MRP +
    // discount). Multi-variant products show the aggregated "Starting from /
    // Up to X% OFF" range instead.
    final bool isSingle = single != null;
    final int singleDiscount =
        isSingle ? _discountPct(single.sellingPrice, single.mrp) : 0;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  isSingle ? 'Price' : 'Starting from',
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      isSingle
                          ? '₹${single.sellingPrice}'
                          : (minSelling == null ? '—' : '₹$minSelling'),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                    // Single variant → exact struck MRP + its discount.
                    if (isSingle && singleDiscount > 0) ...[
                      SizedBox(width: SizeConfig.size6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: CustomText(
                          '₹${single.mrp}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: CustomText(
                          '$singleDiscount% OFF',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green7F,
                        ),
                      ),
                    ],
                    // Multi variant → aggregated best discount.
                    if (!isSingle && maxDiscount > 0) ...[
                      SizedBox(width: SizeConfig.size8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: CustomText(
                          'Up to $maxDiscount% OFF',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green7F,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _stockPill(anyInStock),
        ],
      ),
    );
  }

  Widget _variantRow(Variant v) {
    final discount = _discountPct(v.sellingPrice, v.mrp);
    final showStrike = discount > 0;
    final image = _firstVariantImage(v);
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image.isEmpty
                ? Container(
                    width: SizeConfig.size50,
                    height: SizeConfig.size50,
                    color: AppColors.greyE5,
                    child: const Icon(Icons.image_outlined,
                        size: 20, color: Colors.grey),
                  )
                : CachedNetworkImage(
                    imageUrl: image,
                    width: SizeConfig.size50,
                    height: SizeConfig.size50,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.greyE5),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.greyE5,
                      child: const Icon(Icons.broken_image,
                          size: 20, color: Colors.grey),
                    ),
                  ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  _variantTitle(v),
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      '₹${v.sellingPrice}',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    if (showStrike) ...[
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        '₹${v.mrp}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        '$discount% OFF',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green7F,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          _stockPill(v.stock),
        ],
      ),
    );
  }

  Widget _stockPill(bool inStock) {
    final color = inStock ? AppColors.green7F : AppColors.redB4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          CustomText(
            inStock ? 'In stock' : 'Out of stock',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.large,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.20)),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.small11,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }
}
