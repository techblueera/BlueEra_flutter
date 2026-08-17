import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The redesigned laboratory listing card from `docs/labnew.png`.
///
/// Built as a plain, data-in widget (no controller, no fetch) so the same
/// layout can back both the owner-side preview inside
/// [LabRequiredDetailsForm] and, later, the customer-facing listing.
///
/// Every value it renders is a field the dashboard collects up-front, so empty
/// values show a placeholder rather than dropping the row: in the preview the
/// point is to make what is still missing obvious.
class LabProfileCardPreview extends StatelessWidget {
  /// Locally picked cover, shown before it has been uploaded. Takes priority
  /// over [coverUrl] so the preview reacts the moment an image is chosen.
  final File? coverFile;

  final String? coverUrl;

  final String name;

  /// Hidden when null or 0 — a fresh listing has no ratings, and a "0.0"
  /// badge reads worse than no badge.
  final double? rating;

  /// The line under the name ("Pathology Lab", "Diagnostic Centre", …).
  final String labType;

  /// Preformatted, e.g. "10km away". Empty collapses that slice.
  final String distanceLabel;

  final String address;

  /// Rendered as the green "Open Now" pill over the cover.
  final bool isOpenNow;

  final int testCount;

  final int facilityCount;

  const LabProfileCardPreview({
    super.key,
    this.coverFile,
    this.coverUrl,
    required this.name,
    this.rating,
    required this.labType,
    this.distanceLabel = '',
    this.address = '',
    this.isOpenNow = false,
    required this.testCount,
    required this.facilityCount,
  });

  static const Color _border = Color(0xFFE6E8EE);
  static const Color _rowBg = Color(0xFFF5F7FB);
  static const Color _open = Color(0xFF13A452);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001120),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _cover(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size10,
              SizeConfig.size12,
              SizeConfig.size4,
            ),
            child: _identity(),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              children: [
                _countRow(
                  icon: AppIconAssets.laboratoryIcon,
                  count: testCount,
                  label: AppStrings.labTestsLabel.tr,
                ),
                SizedBox(height: SizeConfig.size6),
                _countRow(
                  icon: '${AppIconAssets.iconPath}hands_brain.svg',
                  count: facilityCount,
                  label: AppStrings.labFacilitiesLabel.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cover + Open Now pill ─────────────────────────────────────────────

  Widget _cover() {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _coverImage(),
          Positioned(
            top: SizeConfig.size10,
            right: SizeConfig.size10,
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_outlined,
                  size: SizeConfig.size14, color: AppColors.white),
            ),
          ),
          if (isOpenNow)
            Positioned(
              right: SizeConfig.size10,
              bottom: SizeConfig.size10,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10,
                  vertical: SizeConfig.size4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 13, color: _open),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      AppStrings.labCardOpenNow.tr,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: _open,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coverImage() {
    if (coverFile != null) {
      return Image.file(coverFile!, fit: BoxFit.cover);
    }
    final url = (coverUrl ?? '').trim();
    if (url.isEmpty) return _coverPlaceholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: _rowBg),
      errorWidget: (_, __, ___) => _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: _rowBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 28, color: AppColors.grey99),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            AppStrings.labCardCoverPlaceholder.tr,
            fontSize: SizeConfig.small,
            color: AppColors.grey99,
          ),
        ],
      ),
    );
  }

  // ── Name · rating | type · distance | address ─────────────────────────

  Widget _identity() {
    final hasType = labType.trim().isNotEmpty;
    final hasAddress = address.trim().isNotEmpty;
    final hasDistance = distanceLabel.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          name.trim().isEmpty ? AppStrings.labCardNamePlaceholder.tr : name,
          fontSize: SizeConfig.large18,
          fontWeight: FontWeight.w800,
          color: _valueColor(name.trim().isNotEmpty),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size6),
        Row(
          children: [
            if ((rating ?? 0) > 0) ...[
              const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5B301)),
              SizedBox(width: SizeConfig.size3),
              CustomText(
                rating!.toStringAsFixed(1),
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(width: SizeConfig.size6),
              CustomText(
                '|',
                fontSize: SizeConfig.small,
                color: AppColors.grey99,
              ),
              SizedBox(width: SizeConfig.size6),
            ],
            Expanded(
              child: CustomText(
                hasType ? labType : AppStrings.labCardTypePlaceholder.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: _valueColor(hasType),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size6),
        Row(
          children: [
            LocalAssets(
              imagePath: AppIconAssets.location_outline,
              imgColor: AppColors.primaryColor,
              height: SizeConfig.size12,
              width: SizeConfig.size12,
            ),
            SizedBox(width: SizeConfig.size4),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    if (hasDistance)
                      TextSpan(
                        text: '$distanceLabel  ',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    TextSpan(
                      text: hasAddress
                          ? address
                          : AppStrings.labCardAddressPlaceholder.tr,
                      style: TextStyle(
                        color: _valueColor(hasAddress),
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Tests / Facilities counters ───────────────────────────────────────

  Widget _countRow({
    required String icon,
    required int count,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: _rowBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: count > 0 ? AppColors.primaryColor : AppColors.grey99,
            height: SizeConfig.size18,
            width: SizeConfig.size18,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              '$count • $label',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: _valueColor(count > 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Filled values read as content; placeholders read as "still to do".
  Color _valueColor(bool filled) =>
      filled ? AppColors.mainTextColor : AppColors.grey99;
}
