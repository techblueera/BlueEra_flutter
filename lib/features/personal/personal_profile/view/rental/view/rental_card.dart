import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card representation of a rental listing — used by
/// RentalServiceScreen and the self-employee dashboard's Rental tab.
///
/// Visual structure:
///   ┌─────────────────────┐
///   │  [hero slideshow]   │   1.15-aspect; gradient scrim at the top
///   │             [trash] │   so the delete affordance reads against
///   │                     │   any photo
///   ├─────────────────────┤
///   │ Name (2 lines)      │
///   │ Description (2 ln)  │
///   │ ₹2,500 /month       │   primary, hero typography
///   │ ─── hairline ───    │
///   │ 📞 9876543210       │
///   │ 📍 Address line     │
///   └─────────────────────┘
class RentalCard extends StatelessWidget {
  final RentalServiceData rentalServiceData;
  final VoidCallback? deleteServiceApi;
  final double width;

  const RentalCard({
    super.key,
    required this.rentalServiceData,
    this.deleteServiceApi,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          RouteHelper.getRentalServiceFullDetailsScreenRoute(),
          arguments: {ApiKeys.argRentalData: rentalServiceData},
        );
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.whiteFE,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipRRect so the slideshow's image edges follow the card's
        // 14-px radius without leaking sharp corners against the
        // rounded chrome.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      rentalServiceData.name,
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      rentalServiceData.description,
                      fontWeight: FontWeight.w400,
                      fontSize: SizeConfig.small11,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _buildPriceBlock(),
                    SizedBox(height: SizeConfig.size10),
                    // Hairline separates "what you're renting" from
                    // "how to reach the owner" — small visual reset
                    // before the contact rows.
                    Container(height: 0.6, color: AppColors.greyE5),
                    SizedBox(height: SizeConfig.size8),
                    _buildContactRow(),
                    SizedBox(height: SizeConfig.size4),
                    _buildAddressRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero slideshow with overlay actions ────────────────────────
  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomImageSlideshow(
              isLoading: false,
              width: double.infinity,
              height: double.infinity,
              imagePaths: rentalServiceData.images ?? [],
              borderRadius: BorderRadius.zero,
              onPhotoIndex: (_) {},
            ),
          ),
          // Top scrim — soft black-to-transparent gradient over the
          // top 56-px so the trash button stays legible against
          // bright photos. IgnorePointer because we don't want it
          // intercepting taps that should land on the slideshow.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Delete affordance — only when a callback is wired,
          // otherwise the card is read-only (e.g., consumer-side
          // viewing). delete_outline_rounded telegraphs the action
          // (was kebab/more_vert, which read as a menu but actually
          // deletes, and that mismatch was confusing).
          if (deleteServiceApi != null)
            Positioned(
              top: 8,
              right: 8,
              child: _buildDeleteIcon(),
            ),
        ],
      ),
    );
  }

  Widget _buildDeleteIcon() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: deleteServiceApi,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 30,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            // Faint white ring picks the chip out from the photo
            // even when the gradient scrim runs out of room.
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.6,
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  // ─── Price block ─────────────────────────────────────────────────
  // Splits "₹2500/month" into a w800 primary number and a w500
  // muted "/unit" tail so the rate scans as one big anchor with a
  // small qualifier — easier to compare across cards in the grid.
  Widget _buildPriceBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomText(
          '₹${rentalServiceData.price}',
          fontWeight: FontWeight.w800,
          fontSize: SizeConfig.large,
          color: AppColors.primaryColor,
        ),
        SizedBox(width: SizeConfig.size4),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: CustomText(
            '/${rentalServiceData.priceUnit}',
            fontWeight: FontWeight.w500,
            fontSize: SizeConfig.small11,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  // ─── Contact / Address rows ──────────────────────────────────────
  Widget _buildContactRow() {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.call,
          imgColor: AppColors.secondaryTextColor,
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            rentalServiceData.contactNumber,
            fontWeight: FontWeight.w500,
            fontSize: SizeConfig.small11,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Pin icon optically reads ~1 px below text baseline; nudge
          // it down so it aligns with the address's first cap-line.
          padding: const EdgeInsets.only(top: 1),
          child: LocalAssets(
            imagePath: AppIconAssets.location_outline,
            imgColor: AppColors.secondaryTextColor,
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            rentalServiceData.address,
            fontWeight: FontWeight.w400,
            fontSize: SizeConfig.small11,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
