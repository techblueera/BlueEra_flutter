import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/show_food_product_variant_sheet.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/card_name_slack.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One dish, as the MERCHANT sees it — the food twin of `AdminProductCard`,
/// and the single card every admin food surface renders.
///
/// Same two-shape contract as the product card, chosen with [isGridShow]:
///
/// * **`true` — the vertical dish card.** Photo with the discount ribbon, the
///   veg/non-veg mark and the stock pill on it, then name, rating, price and
///   the variant chip. Used by the Products tab's "Popular Dishes" rail and by
///   the Offer Dish grid.
/// * **`false` — the horizontal row.** Thumbnail, name, description and the
///   dietary/cooking row, with the stock pill under them. Used by the
///   category-drilldown list, where a dish is being read rather than shopped
///   and the price already lives one tap away in the variant sheet.
///
/// Tapping either opens [showFoodProductVariantSheet] — the one place per-
/// variant price, stock and delete live — unless [onTap] overrides it.
///
/// ## Why this exists
///
/// The three screens each carried their own copy of one of these two layouts,
/// and the copies had drifted: the Offer Dish grid was missing the stock pill
/// the rail shows, wrapped its discount ribbon in a `BackdropFilter` that
/// cannot be seen behind an opaque gradient, printed a "0 variant" chip for a
/// dish with none, and used a second set of translation keys
/// (`food_reviews_sample` / `food_more_variant` / `food_variant_singular`) that
/// say exactly what `reviewsKMock` / `variantsMoreFmt` / `variantSingularFmt`
/// say. All three now render from here, so a change lands everywhere at once.
class AdminFoodCard extends StatelessWidget {
  const AdminFoodCard({
    super.key,
    required this.product,
    this.isGridShow = true,
    this.width,
    this.equaliseHeight = false,
    this.onTap,
  });

  final CategoryFoodProductData product;

  /// Vertical dish card when true, horizontal row when false. See the class
  /// doc for which surface uses which.
  final bool isGridShow;

  /// Fixed width, for a rail whose cards must all measure the same. Null lets
  /// the card fill whatever cell it is given — and also switches the photo from
  /// a fixed height to [_imageAspect], because a grid cell's width is not known
  /// here and a fixed height would letterbox at some of them.
  final double? width;

  /// Pad a short name so neighbouring cards END at the same height (see
  /// [CardNameSlack]).
  ///
  /// ON for a rail, which sizes to its tallest card and would otherwise look
  /// ragged. OFF for a masonry grid, which sizes every tile to its own content
  /// on purpose — equalising there just adds dead space to short cards.
  final bool equaliseHeight;

  /// Overrides the default tap, which opens the variant sheet.
  final VoidCallback? onTap;

  /// The dish name's type, in one place: the card renders with these and
  /// [CardNameSlack] measures with them. They must not drift apart.
  static const double _nameFontSize = 13;
  static const double _nameLineHeight = 1.3;
  static const int _nameMaxLines = 2;

  /// Padding inside the vertical card's text block — also what the name
  /// measurement subtracts to size the text at the width it is laid out in.
  static const double _cardPadding = 6;

  /// Photo height when the card has a fixed [width], and its aspect when it
  /// does not.
  static const double _imageHeight = 130;
  static const double _imageAspect = 1.1;

  int get _variantCount => product.variants?.length ?? 0;

  /// Price comes off the FIRST variant — the card shows a "from" price and the
  /// sheet shows the rest.
  FoodVariants? get _leadVariant => product.variants?.firstOrNull;

  int get _discountPercent {
    final mrp = _leadVariant?.mrp;
    final selling = _leadVariant?.baseSellingPrice;
    if (mrp == null || selling == null || mrp <= selling) return 0;
    return (((mrp - selling) / mrp) * 100).round();
  }

  void _open(BuildContext context) {
    if (onTap != null) return onTap!();
    showFoodProductVariantSheet(context, product: product);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(context),
      child: isGridShow ? _verticalCard(context) : _horizontalCard(),
    );
  }

  // ---------------------------------------------------------------------------
  // Vertical — the dish card
  // ---------------------------------------------------------------------------

  Widget _verticalCard(BuildContext context) {
    if (!equaliseHeight) return _verticalBody(nameSlack: 0);
    return SizedBox(
      width: width,
      child: CardNameSlack(
        text: product.name ?? '',
        fontSize: _nameFontSize,
        lines: _nameMaxLines,
        lineHeight: _nameLineHeight,
        horizontalPadding: _cardPadding * 2,
        builder: (context, nameSlack) => _verticalBody(nameSlack: nameSlack),
      ),
    );
  }

  Widget _verticalBody({required double nameSlack}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photo(),
          Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Natural height: one line for a short name, two for a long
                // one. When [equaliseHeight] is on, the line a short name did
                // not use is added at the BOTTOM of the card instead of sitting
                // as a hole under the title.
                CustomText(
                  product.name ?? '',
                  fontWeight: FontWeight.w600,
                  maxLines: _nameMaxLines,
                  height: _nameLineHeight,
                  fontSize: _nameFontSize,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _ratingRow(),
                const SizedBox(height: 6),
                _priceRow(),
                if (_variantCount > 0) ...[
                  const SizedBox(height: 6),
                  _variantChip(),
                ],
                if (nameSlack > 0) SizedBox(height: nameSlack),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo() {
    final image = CachedNetworkImage(
      imageUrl: product.images?.firstOrNull ?? '',
      height: width == null ? null : _imageHeight,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.fastfood, color: Colors.grey),
      ),
    );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: width == null
              ? AspectRatio(aspectRatio: _imageAspect, child: image)
              : image,
        ),
        if (_discountPercent > 0)
          Positioned(top: 0, left: 0, child: _discountRibbon()),
        Positioned(
          top: 8,
          right: 8,
          child: FoodTypeIndicator(
            isVegetarian:
                product.dietaryType?.toLowerCase() == AppConstants.veg,
            size: 8,
          ),
        ),
        // Stock state on the photo, where the eye lands first when scanning a
        // rail or a grid. Bottom-LEFT: the top corners already carry the
        // discount ribbon and the veg/non-veg mark.
        Positioned(
          left: 8,
          bottom: 8,
          child: StockStatusPill(
            inStock: !isFoodProductOutOfStock(product),
            onImage: true,
          ),
        ),
      ],
    );
  }

  Widget _discountRibbon() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFD7845), Color(0xFFFA5568)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: CustomText(
          AppStrings.discountOffFmt.trParams({'percent': '$_discountPercent'}),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _ratingRow() {
    return Row(
      children: [
        RatingBadge(rating: '4.5'),
        const SizedBox(width: 4),
        Flexible(
          child: CustomText(
            AppStrings.reviewsKMock.tr,
            fontWeight: FontWeight.w600,
            maxLines: 1,
            color: AppColors.secondaryTextColor,
            fontSize: 11,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _priceRow() {
    final selling = _leadVariant?.baseSellingPrice;
    final mrp = _leadVariant?.mrp;
    return Row(
      children: [
        CustomText(
          '${AppConstants.rupeeSymbol}${selling ?? 0}',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        if (mrp != null && selling != null && mrp >= selling) ...[
          const SizedBox(width: 6),
          CustomText(
            '${AppConstants.rupeeSymbol}$mrp',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.secondaryTextColor,
          ),
        ],
      ],
    );
  }

  Widget _variantChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        _variantCount > 1
            ? AppStrings.variantsMoreFmt
                .trParams({'count': '${_variantCount - 1}'})
            : AppStrings.variantSingularFmt.trParams({'count': '$_variantCount'}),
        fontSize: 10,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Horizontal — the list row
  // ---------------------------------------------------------------------------

  Widget _horizontalCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImageWidget(imageUrl: product.images?.firstOrNull),
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
                  // Stock state at a glance, without opening the variant sheet
                  // where the switch lives. Both states, so the absence of a
                  // badge never has to be interpreted.
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StockStatusPill(
                      inStock: !isFoodProductOutOfStock(product),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
