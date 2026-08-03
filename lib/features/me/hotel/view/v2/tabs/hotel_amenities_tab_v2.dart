import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_screen.dart';
import 'package:BlueEra/features/me/hotel/widget/hotel_amenities_card.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';

/// Amenities + Policies tab — shared [HotelAmenitiesCard] on top followed
/// by the Policies card, which mirrors the amenities behaviour: standalone
/// [_SplitEmptyCard] when nothing is set, full [CommonCardWidget] with the
/// chip wrap when there is data.
class HotelAmenitiesTabV2 extends StatelessWidget {
  final HotelDetailController controller;

  const HotelAmenitiesTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: HotelAmenitiesCard(controller: controller),
        ),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: Obx(() {
            final profile = controller.hotelData.value?.profile;
            final items = profile?.policy == null
                ? const <String>[]
                : _policyItems(profile!.policy!);
            final onEdit = () => Get.to(HotelPoliciesScreen())
                ?.then((_) => controller.loadHotelData());

            if (items.isEmpty) {
              return _SplitEmptyCard(
                message: 'You Have Not Update Your \n Hotel Policy',
                onTap: onEdit,
              );
            }

            return CommonCardWidget(
              padding: 12,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    title: AppStrings.hotelPoliciesTitle.tr,
                    onEdit: onEdit,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  Wrap(
                    spacing: SizeConfig.size8,
                    runSpacing: SizeConfig.size8,
                    children: items
                        .map((item) => Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size12,
                                  vertical: SizeConfig.size6),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Color(0xffDDE2EE), width: 0.5),
                              ),
                              child: CustomText(item,
                                  fontSize: 12, color: AppColors.grey7E),
                            ))
                        .toList(),
                  ),
                ],
              ),
            );
          }),
        ),
        SizedBox(height: kBottomNavigationBarHeight + 10),
      ],
    );
  }
}

/// Flattens the [Policy] object into localized chip labels. Empty result
/// means the hotel hasn't set anything meaningful yet — the caller renders
/// the empty state.
List<String> _policyItems(Policy policy) {
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
  return items;
}

/// Card title + minimalist pencil-outline edit affordance (matches mockup).
class _CardHeader extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;

  const _CardHeader({required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CustomText(
            title,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black22,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size4),
            child: LocalAssets(
              imagePath: AppIconAssets.editIcon,
              imgColor: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// Standalone Policies empty state: self-contained card with its own
/// "Hotel Policy" title + illustration + "Update Now" CTA. Replaces the
/// full [CommonCardWidget] rather than being nested inside it, so the
/// empty layout doesn't render two headers stacked on top of each other.
class _SplitEmptyCard extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _SplitEmptyCard({
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.hotelPoliciesTitle.tr,
            fontSize: 20,
            color: AppColors.black,
            fontWeight: FontWeight.w600,
            maxLines: 1,
          ),
          SizedBox(height: SizeConfig.size4),
          Divider(
            color: Color(0xffDDE2EE),
            height: 0.5,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size16,
            ),
            child: Center(
              child: Column(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.emptyIcon,
                    height: 50,
                    width: 50,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CustomText(
                    message,
                    fontSize: 13,
                    color: AppColors.secondaryTextColor,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size14,
                        vertical: SizeConfig.size8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          CustomText(
                            'Update Now',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
