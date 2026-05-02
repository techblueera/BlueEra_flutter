import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Amenities + Policies tab — combines the two configuration-heavy
/// sections so they share a tab. Empty states route into the same
/// edit screens used by the legacy `HotelHomeDetailScreen`.
class HotelAmenitiesTabV2 extends StatelessWidget {
  final HotelDetailController controller;

  const HotelAmenitiesTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.hotelData.value?.profile;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),

          // ── Amenities ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(AppStrings.hotelAmenitiesTitle.tr,
                          fontWeight: FontWeight.w700),
                      _EditButton(
                        onTap: () => Get.to(HotelAmenitiesScreen())
                            ?.then((_) => controller.loadHotelData()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (profile?.hotelAmenities != null)
                    _AmenitiesGrid(amen: profile!.hotelAmenities!)
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.hotelNoAmenitiesAdded.tr,
                      ctaIcon: Icons.spa_outlined,
                      onTap: () => Get.to(HotelAmenitiesScreen())
                          ?.then((_) => controller.loadHotelData()),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          // ── Policies ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(AppStrings.hotelPoliciesTitle.tr,
                          fontWeight: FontWeight.w700),
                      _EditButton(
                        onTap: () => Get.to(HotelPoliciesScreen())
                            ?.then((_) => controller.loadHotelData()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (profile?.policy != null)
                    _PolicySummary(policy: profile!.policy!)
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.hotelNoPoliciesAdded.tr,
                      ctaIcon: Icons.policy_outlined,
                      onTap: () => Get.to(HotelPoliciesScreen())
                          ?.then((_) => controller.loadHotelData()),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

class _AmenitiesGrid extends StatelessWidget {
  final HotelAmenities amen;
  const _AmenitiesGrid({required this.amen});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      children: [
        if (amen.freeParking ?? false)
          _AmenityIcon(
              icon: Icons.local_parking, label: AppStrings.hotelFreeParking.tr),
        if (amen.restaurant ?? false)
          _AmenityIcon(
              icon: Icons.restaurant, label: AppStrings.hotelRestaurant.tr),
        if (amen.frontDesk24x7 ?? false)
          _AmenityIcon(
              icon: Icons.support_agent,
              label: AppStrings.hotelFrontDesk247.tr),
        if (amen.elevatorLift ?? false)
          _AmenityIcon(
              icon: Icons.elevator, label: AppStrings.hotelElevatorLift.tr),
        if (amen.cctvSurveillance ?? false)
          _AmenityIcon(
              icon: Icons.videocam,
              label: AppStrings.hotelCctvSurveillance.tr),
        if (amen.powerBackup ?? false)
          _AmenityIcon(
              icon: Icons.battery_charging_full_sharp,
              label: AppStrings.hotelPowerBackup.tr),
        if (amen.laundryService ?? false)
          _AmenityIcon(
              icon: Icons.local_laundry_service,
              label: AppStrings.hotelLaundryService.tr),
        if (amen.swimmingPool ?? false)
          _AmenityIcon(
              icon: Icons.pool, label: AppStrings.hotelSwimmingPool.tr),
        if (amen.airportTransportation ?? false)
          _AmenityIcon(
              icon: Icons.airport_shuttle,
              label: AppStrings.hotelAirportTransportation.tr),
        if (amen.bar ?? false)
          _AmenityIcon(icon: Icons.local_bar, label: AppStrings.hotelBar.tr),
        if (amen.gym ?? false)
          _AmenityIcon(
              icon: Icons.fitness_center, label: AppStrings.hotelGym.tr),
      ],
    );
  }
}

class _AmenityIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AmenityIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          CustomText(label, fontSize: 12),
        ],
      ),
    );
  }
}

class _PolicySummary extends StatelessWidget {
  final Policy policy;
  const _PolicySummary({required this.policy});

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    if (policy.checkInTime != null) {
      items.add('${AppStrings.hotelCheckInLabel.tr} ${policy.checkInTime}');
    }
    if (policy.checkOutTime != null) {
      items.add('${AppStrings.hotelCheckOutLabel.tr} ${policy.checkOutTime}');
    }
    if (policy.earlyCheckInAllowed == true) {
      items.add(AppStrings.hotelEarlyCheckInAllowed.tr);
    }
    if (policy.lateCheckOutAllowed == true) {
      items.add(AppStrings.hotelLateCheckOutAllowed.tr);
    }
    if (policy.freeCancellation == true) {
      items.add(AppStrings.hotelFreeCancellation.tr);
    }
    if (policy.localIdAllowed == true) {
      items.add(AppStrings.hotelLocalIdAccepted.tr);
    }
    if (policy.marriedCoupleAllowed == true) {
      items.add(AppStrings.hotelMarriedCouplesAllowed.tr);
    }
    if (policy.bachelorStudentAllowed == true) {
      items.add(AppStrings.hotelBachelorsStudentsAllowed.tr);
    }
    if (policy.aadharMandatory == true) {
      items.add(AppStrings.hotelAadharMandatoryChip.tr);
    }
    if (policy.smokingDrinkingAllowed == true) {
      items.add(AppStrings.hotelSmokingDrinkingAllowedChip.tr);
    }
    if (policy.foodRestrictions?.enabled == true &&
        (policy.foodRestrictions?.restrictions?.isNotEmpty ?? false)) {
      items.add(
          '${AppStrings.hotelFoodRestrictionsLabel.tr}: ${policy.foodRestrictions!.restrictions!.join(', ')}');
    }

    if (items.isEmpty) {
      return EmptySectionPlaceholder(
        imageAsset: 'assets/images/other_gallery.png',
        ctaLabel: AppStrings.hotelNoPoliciesAdded.tr,
        ctaIcon: Icons.policy_outlined,
        onTap: () => Get.to(HotelPoliciesScreen()),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          AppColors.primaryColor.withValues(alpha: 0.2)),
                ),
                child: CustomText(item,
                    fontSize: 12, color: AppColors.mainTextColor),
              ))
          .toList(),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
