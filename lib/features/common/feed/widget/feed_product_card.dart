import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/feed_profile_navigation.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders one `type: "product"` entry from the mixed `/feed` response
/// (see docs/backend/FRONTEND_FEED_INTEGRATION.md §4.6) as a banner-style
/// product / service card, styled to mirror the Discover store product card
/// (image on top, title, prominent price, store row).
///
/// The card carries no visible action buttons, but tapping it opens the
/// seller's profile through the same resolver every other feed profile tap
/// uses ([openFeedProfile]), so the seller's own store screen wins when its
/// type/sub-category has one.
class FeedProductCard extends StatelessWidget {
  final Post post;
  final double? horizontalPadding;
  final double? bottomPadding;

  const FeedProductCard({
    super.key,
    required this.post,
    this.horizontalPadding,
    this.bottomPadding,
  });

  FeedProduct? get _product => post.product;

  /// Opens the seller through the shared feed profile resolver
  /// ([openFeedProfile]), which routes on the seller's account type *and*
  /// sub-category — so a product listed by a grocery store opens that store,
  /// not the generic business profile.
  void _openSeller() => openFeedProfile(post.user);

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product == null) return const SizedBox.shrink();

    final name = product.name?.trim() ?? '';
    final brand = product.brand?.trim() ?? '';
    final price = product.displayPrice;
    final image = product.primaryImage;
    final storeName = product.store?.name?.trim() ?? '';
    final rating = product.rating;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding ?? SizeConfig.size5,
        right: horizontalPadding ?? SizeConfig.size5,
        top: SizeConfig.size5,
        bottom: bottomPadding ?? SizeConfig.size5,
      ),
      child: GestureDetector(
        onTap: _openSeller,
        child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(
              imageUrl: image,
              badge: product.isService ? 'Service' : 'Product',
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty) ...[
                    CustomText(
                      brand.toUpperCase(),
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                      letterSpacing: 0.5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size2),
                  ],
                  CustomText(
                    name.isNotEmpty ? name : 'Product',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    children: [
                      if (price != null)
                        CustomText(
                          price,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          // Discover prices read in the brand colour.
                          color: AppColors.primaryColor,
                        ),
                      if (rating != null && rating > 0) ...[
                        SizedBox(width: SizeConfig.size8),
                        Icon(
                          Icons.star_rounded,
                          size: SizeConfig.size16,
                          color: Colors.amber.shade700,
                        ),
                        SizedBox(width: SizeConfig.size2),
                        CustomText(
                          rating.toStringAsFixed(1),
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                  if (storeName.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: SizeConfig.size16,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        Expanded(
                          child: CustomText(
                            storeName,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Returns only make sense for physical products (guide §4.6).
                  if (!product.isService && product.isReturnable == true) ...[
                    SizedBox(height: SizeConfig.size8),
                    _ReturnChip(days: product.returnPeriodDays),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Product hero image with the Product/Service badge. Falls back to a neutral
/// placeholder — the guide allows `images` to be empty.
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String badge;

  const _ProductImage({required this.imageUrl, required this.badge});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.greyE5,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: SizeConfig.size40,
        color: AppColors.secondaryTextColor,
      ),
    );

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: SizedBox(
            width: double.infinity,
            child: (imageUrl?.isNotEmpty ?? false)
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => placeholder,
                    errorWidget: (_, __, ___) => placeholder,
                  )
                : placeholder,
          ),
        ),
        Positioned(
          top: SizeConfig.size8,
          left: SizeConfig.size8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomText(
              badge,
              fontSize: SizeConfig.extraSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Returnable" / "7-day returns" chip.
class _ReturnChip extends StatelessWidget {
  final int? days;

  const _ReturnChip({this.days});

  @override
  Widget build(BuildContext context) {
    final label = (days != null && days! > 0) ? '$days-day returns' : 'Returnable';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.greyE5,
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.extraSmall,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
}
