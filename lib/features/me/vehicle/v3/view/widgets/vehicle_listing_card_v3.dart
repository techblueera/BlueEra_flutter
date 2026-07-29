import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// One vehicle listing, as a card.
///
/// Used by the owner rail, the owner's full list and the buyer's listing
/// list — one card so a seller sees exactly what a buyer sees. [showStatus]
/// is the only owner-side affordance: buyers only ever see live listings, so
/// an "inactive" chip would be meaningless there.
class VehicleListingCardV3 extends StatelessWidget {
  final VehicleListingV3 listing;
  final VoidCallback? onTap;

  /// Renders the active/inactive + verified chips. Owner surfaces only.
  final bool showStatus;

  /// Compact layout for the horizontal rail; the full-width list uses false.
  final bool compact;

  const VehicleListingCardV3({
    super.key,
    required this.listing,
    this.onTap,
    this.showStatus = false,
    this.compact = false,
  });

  /// Rail geometry — the tab sizes its ListView from these.
  static const double railHeight = 244;
  static const double cardWidth = 168;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5),
        ),
        clipBehavior: Clip.antiAlias,
        child: compact ? _compactBody() : _wideBody(),
      ),
    );
  }

  // ───── Layouts ────────────────────────────────────────────────────

  Widget _compactBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(aspectRatio: 4 / 3, child: _image()),
        Padding(
          padding: EdgeInsets.all(SizeConfig.size8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _conditionChip(),
              SizedBox(height: SizeConfig.size6),
              CustomText(
                listing.title,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                _subtitle(),
                fontSize: SizeConfig.small11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size6),
              CustomText(
                formatVehiclePriceV3(_price()),
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wideBody() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 104, height: 84, child: _image()),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _conditionChip(),
                    if (showStatus) ...[
                      SizedBox(width: SizeConfig.size6),
                      _statusChip(),
                    ],
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  listing.title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  _subtitle(),
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  formatVehiclePriceV3(_price()),
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───── Pieces ─────────────────────────────────────────────────────

  Widget _image() {
    final url = listing.thumbnail;
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.whiteF3,
        alignment: Alignment.center,
        child: Icon(
          Icons.directions_car_filled_outlined,
          color: AppColors.secondaryTextColor,
          size: 28,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.whiteF3),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.whiteF3,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined,
            color: AppColors.secondaryTextColor, size: 22),
      ),
    );
  }

  /// The NEW/USED badge — the single most load-bearing fact on the card, and
  /// the thing that decides which of the two field sets the subtitle reads.
  Widget _conditionChip() {
    final isNew = listing.isNew;
    final color = isNew ? const Color(0xFF1F9254) : const Color(0xFFB25E00);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        isNew ? 'NEW' : 'USED',
        fontSize: SizeConfig.small11,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  Widget _statusChip() {
    final active = listing.isActive;
    final color =
        active ? const Color(0xFF1F9254) : AppColors.secondaryTextColor;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        active ? 'Live' : 'Paused',
        fontSize: SizeConfig.small11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  /// Colour, then whichever condition-specific detail actually says something
  /// about the vehicle: kilometres and year for a used one, availability and
  /// delivery for a new one.
  String _subtitle() {
    final parts = <String>[];
    if (listing.colourLabel.isNotEmpty) parts.add(listing.colourLabel);
    if (listing.isNew) {
      if (listing.availability.isNotEmpty) parts.add(listing.availability);
      if (listing.deliveryTime.isNotEmpty) parts.add(listing.deliveryTime);
    } else {
      if (listing.registrationYear != null) {
        parts.add('${listing.registrationYear}');
      }
      if (listing.kmDriven != null) {
        parts.add(formatKilometresV3(listing.kmDriven));
      }
    }
    if (parts.isEmpty && listing.city.isNotEmpty) parts.add(listing.city);
    return parts.join(' · ');
  }

  /// `display_price` is the server's resolved price and the guide asks
  /// clients to prefer it so every surface shows the same number; the
  /// condition-specific fields are only a fallback for payloads without it.
  num? _price() =>
      listing.displayPrice ??
      (listing.isNew ? listing.onRoadPrice : listing.expectedPrice);
}
