import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Entity types that are catalogue rows rather than places. They carry a price
/// but never an address, which changes what the listing card renders.
const Set<String> kSearchProductTypes = {
  'product',
  'variant',
  'grocery_product',
};

bool isSearchProductType(String entityType) =>
    kSearchProductTypes.contains(entityType);

/// Human label for an entity type. New types ship server-side without a client
/// release, so an unknown one falls back to its own (untranslated) name rather
/// than rendering blank.
String searchEntityLabel(String type) {
  switch (type) {
    case 'product':
    case 'variant':
      return AppStrings.searchEntityProduct.tr;
    case 'grocery_product':
      return AppStrings.searchEntityGrocery.tr;
    case 'grocery_shop':
      return AppStrings.searchEntityGroceryShop.tr;
    case 'user':
      return AppStrings.searchEntityPeople.tr;
    case 'business':
      return AppStrings.searchEntityBusiness.tr;
    case 'service':
      return AppStrings.searchEntityService.tr;
    default:
      return type.isEmpty
          ? AppStrings.searchEntityResult.tr
          : '${type[0].toUpperCase()}${type.substring(1)}';
  }
}

IconData searchEntityIcon(String type) {
  switch (type) {
    case 'product':
    case 'variant':
      return Icons.shopping_bag_outlined;
    case 'grocery_product':
    case 'grocery_shop':
      return Icons.local_grocery_store_outlined;
    case 'user':
      return Icons.person_outline;
    case 'business':
      return Icons.storefront_outlined;
    case 'service':
      return Icons.handyman_outlined;
    default:
      return Icons.search;
  }
}

/// One search result as the wide listing card from `docs/saerch_cat_view.png`:
/// circular photo · name · rating | category · distance | address, with a
/// product-count (or price) badge on the right.
///
/// Every slot is conditional. One result list mixes shops — name, rating,
/// address, product count — with catalogue rows (a packet of atta has none of
/// those), so a missing value collapses its row instead of leaving a hole, and
/// a missing image falls back to an entity-typed placeholder.
///
/// The card is width-agnostic: the text column is the only flexible child, so
/// long names and addresses ellipsize instead of overflowing on narrow phones.
class SearchResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback? onTap;

  const SearchResultCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final trailing = _trailing(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeConfig.size16),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(),
            SizedBox(width: SizeConfig.size12),
            // Expanded — never a fixed width — is what keeps long shop names
            // and addresses inside the card on narrow screens.
            Expanded(child: _body()),
            if (trailing != null) ...[
              SizedBox(width: SizeConfig.size8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final title = item.title.trim();
    final meta = _metaRow();
    final location = _locationRow();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                title.isNotEmpty ? title : AppStrings.globalSearchUntitled.tr,
                fontSize: SizeConfig.medium15,
                fontWeight: FontWeight.w700,
                color: title.isNotEmpty
                    ? AppColors.mainTextColor
                    : AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.sponsored) ...[
              SizedBox(width: SizeConfig.size4),
              _sponsoredTag(),
            ],
          ],
        ),
        if (meta != null) ...[
          SizedBox(height: SizeConfig.size4),
          meta,
        ],
        if (location != null) ...[
          SizedBox(height: SizeConfig.size4),
          location,
        ],
      ],
    );
  }

  /// Circular thumbnail. Falls back to an entity-typed icon on a tinted disc
  /// whenever the row carries no image or the image fails to load.
  Widget _avatar() {
    final size = SizeConfig.size54;
    final url = item.imageUrl?.trim() ?? '';
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blue5CAF.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Icon(
        searchEntityIcon(item.entityType),
        size: size * 0.44,
        color: AppColors.blue5CAF,
      ),
    );
    if (url.isEmpty) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }

  /// "★ 4.8 | General Store". An unrated row shows "New" in place of the star
  /// so the line never renders as a bare separator.
  Widget? _metaRow() {
    final rating = item.rating;
    final category = _categoryLabel();
    if (rating == null && category.isEmpty) return null;
    return Row(
      children: [
        if (rating != null) ...[
          Icon(Icons.star_rounded,
              size: SizeConfig.size16, color: AppColors.yellow00),
          SizedBox(width: SizeConfig.size2),
          CustomText(
            rating.toStringAsFixed(1),
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ] else
          // Flexible, because the label is translated — a long word in one
          // locale must shorten rather than push the category off the card.
          Flexible(
            child: CustomText(
              AppStrings.globalSearchNoRating.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (item.assured) ...[
          SizedBox(width: SizeConfig.size4),
          Icon(Icons.verified,
              size: SizeConfig.size15, color: AppColors.blue5CAF),
        ],
        if (category.isNotEmpty) ...[
          _metaDivider(),
          Expanded(
            child: CustomText(
              category,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// The category shown next to the rating: the row's own subtitle, else its
  /// category, else the entity's label — so the slot is never blank.
  String _categoryLabel() {
    final subtitle = item.subtitle?.trim() ?? '';
    if (subtitle.isNotEmpty) return subtitle;
    final category = item.category?.trim() ?? '';
    if (category.isNotEmpty) return category;
    return searchEntityLabel(item.entityType);
  }

  /// The row's distance, server-formatted (e.g. `4.5 km`), or empty when it
  /// has none.
  String get _distanceText =>
      item.hasDistance ? (item.distanceText?.trim() ?? '') : '';

  /// True when the trailing badge is carrying the distance, so [_locationRow]
  /// leaves the number out instead of printing it twice.
  ///
  /// Only place-like rows hand it over: a priced product keeps its price in the
  /// badge, so its distance stays on the address line where it has always been.
  bool get _distanceInBadge => _distanceText.isNotEmpty && item.price == null;

  /// "◉ 4.5 Km | Sastri Nagar, Lucknow…". Distance and address arrive
  /// independently, so each half is optional. A place-like row keeps the line
  /// with a "not available" hint — an address is expected there — while a
  /// catalogue row drops it, since a product legitimately has no address.
  Widget? _locationRow() {
    final distance = _distanceInBadge ? '' : _distanceText;
    final address = item.address?.trim() ?? '';

    if (distance.isEmpty && address.isEmpty) {
      if (isSearchProductType(item.entityType)) return null;
      return Row(
        children: [
          _locationPin(),
          SizedBox(width: SizeConfig.size4),
          Expanded(
            child: CustomText(
              AppStrings.globalSearchLocationUnavailable.tr,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _locationPin(),
        SizedBox(width: SizeConfig.size4),
        if (distance.isNotEmpty)
          Flexible(
            child: CustomText(
              distance,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.blue5CAF,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (distance.isNotEmpty && address.isNotEmpty) _metaDivider(),
        if (address.isNotEmpty)
          Expanded(
            child: CustomText(
              address,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _locationPin() => Icon(Icons.location_on,
      size: SizeConfig.size15, color: AppColors.blue5CAF);

  /// Thin "|" between two inline meta values.
  Widget _metaDivider() => Container(
        width: 1,
        height: SizeConfig.size12,
        margin: EdgeInsets.symmetric(horizontal: SizeConfig.size6),
        color: AppColors.greyE5,
      );

  /// Capped width: the label is translated, and an unbounded tag would eat the
  /// title's row on a narrow screen instead of ellipsizing itself.
  Widget _sponsoredTag() => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: SizeConfig.size80),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size6, vertical: SizeConfig.size2),
          decoration: BoxDecoration(
            color: AppColors.whiteF4,
            borderRadius: BorderRadius.circular(SizeConfig.size4),
          ),
          child: CustomText(
            AppStrings.globalSearchSponsored.tr,
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  /// Right-hand badge: how far away a place is, else a product's price. Null
  /// when the row carries neither — the card then gives that width back to the
  /// title and address instead of drawing an empty box.
  ///
  /// The badge used to hold the shop's product count. Distance is the fact a
  /// search result is picked on, so it takes the slot and the address line goes
  /// back to being only the address (see [_distanceInBadge]). The old badge:
  ///
  /// ```dart
  /// final count = item.productCountLabel;
  /// if (count != null) {
  ///   return _badge(
  ///     context,
  ///     icon: Icons.shopping_bag_outlined,
  ///     value: count,
  ///     label: AppStrings.globalSearchProducts.tr,
  ///   );
  /// }
  /// ```
  Widget? _trailing(BuildContext context) {
    if (_distanceInBadge) {
      return _badge(
        context,
        icon: Icons.near_me_outlined,
        value: _distanceText,
      );
    }
    if (item.price != null) {
      return _badge(
        context,
        value: '₹${SearchResponse.formatPrice(item.price)}',
        label: item.hasDiscount
            ? AppStrings.globalSearchDiscountFmt
                .trParams({'percent': '${item.discountPercent}'})
            : null,
        labelColor: item.hasDiscount ? Colors.green.shade700 : null,
      );
    }
    return null;
  }

  Widget _badge(
    BuildContext context, {
    required String value,
    IconData? icon,
    String? label,
    Color? labelColor,
  }) {
    // Capped at a share of the *live* width (MediaQuery, so it survives
    // rotation and split-screen) — a long value then ellipsizes inside the
    // badge instead of squeezing the title. The badge never gets to dictate
    // the card's layout.
    final maxWidth =
        (MediaQuery.sizeOf(context).width * 0.28).clamp(72.0, 130.0).toDouble();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size6),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.greyE5),
          borderRadius: BorderRadius.circular(SizeConfig.size8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: SizeConfig.size12, color: AppColors.blue5CAF),
                  SizedBox(width: SizeConfig.size3),
                ],
                Flexible(
                  child: CustomText(
                    value,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (label != null)
              CustomText(
                label,
                fontSize: SizeConfig.extraSmall,
                color: labelColor ?? AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
