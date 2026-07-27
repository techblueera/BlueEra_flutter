import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Renders one `type: "business"` entry from the mixed `/feed` response
/// (see docs/backend/FRONTEND_FEED_INTEGRATION.md §4.5) as a banner-style
/// business card: a large logo/banner image on top, with the name, category,
/// rating and address below.
///
/// The card carries no visible action buttons, but tapping it opens the
/// business's visiting profile ([VisitBusinessProfileNew]) — a `type:
/// "business"` feed item always represents a business. Business items only
/// arrive when the feed request carries `lat`/`long` (guide §6.1), and their
/// author often resolves to "Unknown User" (guide §4.1), so the card is built
/// entirely from the business payload for display.
class FeedBusinessCard extends StatelessWidget {
  final Post post;
  final double? horizontalPadding;
  final double? bottomPadding;

  const FeedBusinessCard({
    super.key,
    required this.post,
    this.horizontalPadding,
    this.bottomPadding,
  });

  FeedBusiness? get _business => post.business;

  /// The business feed item's own `_id` is the business id. We prefer the
  /// author's `business_id` when the user service resolved it, and fall back to
  /// the item id so the card stays tappable for the "Unknown User" case.
  String get _businessId {
    final fromAuthor = post.user?.business_id ?? '';
    return fromAuthor.isNotEmpty ? fromAuthor : post.id;
  }

  void _openBusiness() {
    if (_businessId.isEmpty) return;
    Get.to(() => VisitBusinessProfileNew(
          businessId: _businessId,
          screenName: AppConstants.feedScreen,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final business = _business;
    if (business == null) return const SizedBox.shrink();

    final name = business.name?.trim() ?? '';
    final category = business.category?.trim() ?? '';
    final address = business.location?.displayAddress ?? '';
    final rating = business.avgRating;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding ?? SizeConfig.size5,
        right: horizontalPadding ?? SizeConfig.size5,
        top: SizeConfig.size5,
        bottom: bottomPadding ?? SizeConfig.size5,
      ),
      child: GestureDetector(
        onTap: _openBusiness,
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
            _BusinessBanner(
              imageUrl: business.logo,
              fallbackLabel: name,
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomText(
                          name.isNotEmpty ? name : 'Business',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rating != null && rating > 0) ...[
                        SizedBox(width: SizeConfig.size8),
                        _RatingPill(
                          rating: rating,
                          totalRatings: business.totalRatings,
                        ),
                      ],
                    ],
                  ),
                  if (category.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      category,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (address.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: SizeConfig.size16,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        Expanded(
                          child: CustomText(
                            address,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}

/// The banner image at the top of the card. Uses the business logo as the
/// banner (the feed payload carries no dedicated banner), falling back to a
/// branded placeholder with the business initial when there is no image.
class _BusinessBanner extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLabel;

  const _BusinessBanner({required this.imageUrl, required this.fallbackLabel});

  @override
  Widget build(BuildContext context) {
    final initial =
        fallbackLabel.trim().isNotEmpty ? fallbackLabel.trim()[0].toUpperCase() : 'B';

    final placeholder = Container(
      color: AppColors.primaryColor.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: CustomText(
        initial,
        fontSize: SizeConfig.size40,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
      ),
    );

    return AspectRatio(
      aspectRatio: 16 / 9,
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
    );
  }
}

/// Rating chip: the score, plus the rating count when the backend sent one.
class _RatingPill extends StatelessWidget {
  final double rating;
  final int? totalRatings;

  const _RatingPill({required this.rating, this.totalRatings});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 13, color: AppColors.white),
              const SizedBox(width: 2),
              CustomText(
                rating.toStringAsFixed(1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ],
          ),
        ),
        if (totalRatings != null && totalRatings! > 0) ...[
          SizedBox(width: SizeConfig.size4),
          CustomText(
            '($totalRatings)',
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ],
    );
  }
}
