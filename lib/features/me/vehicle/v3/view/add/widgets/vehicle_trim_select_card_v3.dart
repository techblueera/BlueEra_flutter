import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A trim on the add screen's "Quick Upload" rails, with the "+" that puts it
/// in the basket — the vehicle counterpart of `GroceryProductSelectCard`.
///
/// The "+" doesn't add directly: it hands off to the colour + condition sheet,
/// because a listing needs a `productVariant` (colour) and a `condition`
/// before it can exist. Once anything for this trim is in the basket the
/// control flips to a tick.
class VehicleTrimSelectCardV3 extends StatelessWidget {
  final VehicleTrimV3 trim;
  final VehicleV3Controller controller;
  final double width;

  /// Opens the colour + condition sheet for this trim.
  final VoidCallback onAdd;

  const VehicleTrimSelectCardV3({
    super.key,
    required this.trim,
    required this.controller,
    required this.onAdd,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final image = trim.firstImage;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: image == null
                  ? Container(
                      color: AppColors.whiteF3,
                      alignment: Alignment.center,
                      child: Icon(Icons.directions_car_filled_outlined,
                          color: AppColors.secondaryTextColor, size: 28),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.whiteF3),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.whiteF3),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    trim.name,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_specLine.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      _specLine,
                      fontSize: SizeConfig.small11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          trim.exShowroomPrice == null
                              ? ''
                              : formatVehiclePriceV3(trim.exShowroomPrice),
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _addButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return Obx(() {
      // Any colour of this trim already in the basket counts as "added" — the
      // basket is keyed by colour, so a merchant can add two colours of the
      // same trim and the card still reads as selected.
      final added = controller.basket.any((e) => e.trim.id == trim.id);
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: added ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Icon(
            added ? Icons.check : Icons.add,
            size: 16,
            color: added ? AppColors.white : AppColors.primaryColor,
          ),
        ),
      );
    });
  }

  String get _specLine {
    final parts = <String>[
      if (trim.fuelType.isNotEmpty) trim.fuelType,
      if (trim.transmission.isNotEmpty) trim.transmission,
    ];
    return parts.join(' · ');
  }
}
