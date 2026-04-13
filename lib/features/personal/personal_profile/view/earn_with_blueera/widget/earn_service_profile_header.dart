import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class EarnServiceProfileHeader extends StatelessWidget {
  final String? coverImageUrl;
  final String? profileImageUrl;
  final String? serviceName;
  final String? serviceCategory;
  final double rating;
  final int totalRatings;
  final String? address;
  final String? foodType;
  final bool isFoodProfile;
  final VoidCallback? onCoverEdit;
  final VoidCallback? onProfileEdit;

  const EarnServiceProfileHeader({
    super.key,
    this.coverImageUrl,
    this.profileImageUrl,
    this.serviceName,
    this.serviceCategory,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.address,
    this.foodType,
    this.isFoodProfile = false,
    this.onCoverEdit,
    this.onProfileEdit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBannerSection(),
          _buildDetailsSection(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    final coverUrl = coverImageUrl ?? profileImageUrl ?? '';

    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey[200]),
                    )
                  : Container(color: Colors.grey[200]),
            ),
          ),
          Positioned(
            left: 16,
            top: 180,
            child: GestureDetector(
              onTap: onProfileEdit,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CachedAvatarWidget(
                  imageUrl: profileImageUrl,
                  size: 70,
                  borderRadius: 35,
                  showProfileOnFullScreen: false,
                ),
              ),
            ),
          ),
          if (onCoverEdit != null)
            Positioned(
              right: 10,
              top: 8,
              child: GestureDetector(
                onTap: onCoverEdit,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          CustomText(
            serviceName,
            fontSize: 20,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isFoodProfile && foodType != null) ...[
                FoodTypeIndicator(
                  isVegetarian: foodType?.toLowerCase() == 'veg',
                ),
                const SizedBox(width: 6),
              ],
              if (serviceCategory != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomText(
                    serviceCategory!,
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              CommonRatingRow(
                rating: rating,
                reviews: totalRatings,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (address != null && address!.isNotEmpty) _buildLocationBlock(),
        ],
      ),
    );
  }

  Widget _buildLocationBlock() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 5),
          Expanded(
            child: CustomText(
              address,
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
