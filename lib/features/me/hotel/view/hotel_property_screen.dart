import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_policy_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hotel policy editor: check-in / check-out window (or 24-hour mode),
/// a stack of allow/disallow switches, and an optional food-restrictions
/// section.
class HotelPoliciesScreen extends StatelessWidget {
  HotelPoliciesScreen({super.key});

  final controller = Get.put(HotelPolicyController());

  // Food-restriction payload values (also stored on the controller's
  // `userFoodTypeSelections`). Must match the backend's expected literals.
  static const String _foodAll = 'All';
  static const String _foodVeg = 'Vegetarian';
  static const String _foodNonVeg = 'Non-Vegetarian';
  static const List<String> _individualFoodOptions = [_foodVeg, _foodNonVeg];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.hotelPoliciesTitle.tr),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCheckInOutCard(),
              const SizedBox(height: 10),
              _buildSwitchesAndFoodSection(),
              const SizedBox(height: 20),
              PositiveCustomBtn(
                onTap: controller.submitPolicies,
                title: AppStrings.submit.tr,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Check-in / check-out card --------------------------------------------

  Widget _buildCheckInOutCard() {
    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.hotelCheckInCheckOut.tr,
                  fontWeight: FontWeight.bold),
              Row(
                children: [
                  CustomText(AppStrings.hotelHours24.tr, fontSize: 12),
                  Obx(() => Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: controller.is24Hours.value,
                          activeThumbColor: AppColors.primaryColor,
                          onChanged: (v) => controller.is24Hours.value = v,
                        ),
                      )),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildTimeDropdown(
                label: AppStrings.hotelCheckIn.tr,
                selection: controller.userCheckInSelections,
              ),
              const SizedBox(width: 10),
              _buildTimeDropdown(
                label: AppStrings.hotelCheckOut.tr,
                selection: controller.userCheckOutSelections,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Renders a single time-of-day dropdown bound to [selection]. Disabled
  /// when 24-hour mode is on.
  Widget _buildTimeDropdown({
    required String label,
    required RxString selection,
  }) {
    return Expanded(
      child: Obx(() {
        final isEnabled = !controller.is24Hours.value;
        final current = selection.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: isEnabled ? Colors.white : Colors.grey.shade100,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current.isEmpty ? null : current,
              isExpanded: true,
              onChanged:
                  isEnabled ? (val) => selection.value = val ?? '' : null,
              items: controller.timeSlots
                  .map((t) => DropdownMenuItem<String>(
                        value: t,
                        child: CustomText('$label - $t'),
                      ))
                  .toList(),
            ),
          ),
        );
      }),
    );
  }

  // ---- Switches + food-restriction section ---------------------------------

  Widget _buildSwitchesAndFoodSection() {
    return Obx(() => Column(
          children: [
            _buildSwitchTile(AppStrings.hotelEarlyCheckInAllowedQ.tr,
                controller.earlyCheckInAllowed),
            _buildSwitchTile(AppStrings.hotelLateCheckOutAllowedQ.tr,
                controller.lateCheckOutAllowed),
            _buildSwitchTile(AppStrings.hotelAllowUnmarriedCouple.tr,
                controller.marriedCoupleAllowed),
            _buildSwitchTile(AppStrings.areYouAllowBachelorOrStudent.tr,
                controller.bachelorStudentAllowed),
            _buildSwitchTile(AppStrings.hotelFreeCancelation.tr,
                controller.freeCancellation),
            _buildSwitchTile(AppStrings.hotelLocalIdAllowed.tr,
                controller.localIdAllowed),
            _buildSwitchTile(AppStrings.hotelAadharMandatory.tr,
                controller.aadharMandatory),
            _buildSwitchTile(AppStrings.hotelSmokingDrinkingAllowed.tr,
                controller.smokingDrinkingAllowed),
            _buildFoodRestrictionSection(),
          ],
        ));
  }

  Widget _buildSwitchTile(String title, RxBool obsValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(() => Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: CustomText(title)),
                SizedBox(
                  height: 30,
                  width: 45,
                  child: Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: obsValue.value,
                      onChanged: (v) => obsValue.value = v,
                      activeThumbColor: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _buildFoodRestrictionSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.anyFoodHabitRestrictions.tr),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: controller.foodRestrictionsEnabled.value,
                  activeThumbColor: AppColors.primaryColor,
                  onChanged: (v) =>
                      controller.foodRestrictionsEnabled.value = v,
                ),
              ),
            ],
          ),
          if (controller.foodRestrictionsEnabled.value) ...[
            CustomText(
              AppStrings.kindlyIndicateWhichFoodHabits.tr,
              fontSize: 12,
              color: Colors.grey,
            ),
            _buildFoodCheckbox(_foodAll, AppStrings.all.tr),
            _buildFoodCheckbox(_foodVeg, AppStrings.vegetarian.tr),
            _buildFoodCheckbox(_foodNonVeg, AppStrings.nonVegetarian.tr),
          ],
        ],
      ),
    );
  }

  /// A single food-type checkbox. The selection list keeps `_foodAll` as a
  /// virtual entry that is added/removed in lockstep with the individual
  /// options being fully selected/cleared.
  Widget _buildFoodCheckbox(String payloadValue, String label) {
    return Obx(() {
      final currentList =
          List<String>.from(controller.userFoodTypeSelections);
      final isSelected = currentList.contains(payloadValue);

      return CheckboxListTile(
        title: CustomText(label, fontSize: 12),
        value: isSelected,
        checkColor: AppColors.white,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (checked) {
          if (checked == null) return;
          _applyFoodToggle(currentList, payloadValue, checked);
          controller.userFoodTypeSelections.value = currentList;
        },
      );
    });
  }

  void _applyFoodToggle(List<String> list, String payloadValue, bool checked) {
    if (payloadValue == _foodAll) {
      if (checked) {
        list
          ..clear()
          ..addAll([_foodAll, ..._individualFoodOptions]);
      } else {
        list.clear();
      }
      return;
    }

    if (checked) {
      list.add(payloadValue);
      // Promote to "All" once every individual option is selected.
      if (_individualFoodOptions.every(list.contains)) list.add(_foodAll);
    } else {
      list.remove(payloadValue);
      // "All" can no longer hold once any individual option is unchecked.
      list.remove(_foodAll);
    }
  }
}
