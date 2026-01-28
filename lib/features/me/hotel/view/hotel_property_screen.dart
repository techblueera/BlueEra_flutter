import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_policy_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HotelPoliciesScreen extends StatelessWidget {
  final controller = Get.put(HotelPolicyController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Hotel Policies",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Time Selection Row
              CommonCardWidget(
                cardMargin: 0,
                padding: 10,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText("Check In/Check Out", fontWeight: FontWeight.bold),
                        Row(
                          children: [
                            CustomText("24hrs", fontSize: 12),
                            Obx(() => Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: controller.is24Hours.value,
                                    activeColor: AppColors.primaryColor,
                                    onChanged: (v) => controller.is24Hours.value = v,
                                  ),
                                ))
                          ],
                        )
                      ],
                    ),
                    Row(
                      children: [
                        _timeDropdown("Check In"),
                        SizedBox(width: 10),
                        _timeDropdownCheckOut("Check Out"),
                      ],
                    ),
                  ],
                ),
              ),
           
              const SizedBox(height: 10),
        
              // Reusable Switches
              Obx(() => Column(
                    children: [
                      _buildSwitchTile("Early Check In Allowed ?",
                          controller.earlyCheckInAllowed),
                      _buildSwitchTile("Late Check Out Allowed ?",
                          controller.lateCheckOutAllowed),
                      _buildSwitchTile("Are You Allow Un-Married Couple",
                          controller.marriedCoupleAllowed),
                      _buildSwitchTile("Are You Allow Bachelor or Student",
                          controller.bachelorStudentAllowed),
                      _buildSwitchTile(
                          "Free Cancelation", controller.freeCancellation),
                      _buildSwitchTile(
                          "Local ID Allowed?", controller.localIdAllowed),
                      _buildSwitchTile(
                          "Aadhar Mandatory As ID?", controller.aadharMandatory),
                      _buildSwitchTile("Smoking & Drinking Allowed?",
                          controller.smokingDrinkingAllowed),
        
                      // Food Restriction Section
                      _buildFoodRestrictionSection(),
                    ],
                  )),
        
              const SizedBox(height: 20),
              PositiveCustomBtn(
                  onTap: controller.submitPolicies, title: AppStrings.submit),

               SizedBox(height: 20),


            ],
          ),
        ),
      ),
    );
  }

  Widget _timeDropdown(String label) {
    return Expanded(
      child: Obx(() {
        // Accessing .value here registers the dependency
        // final bool isEnabled = true;
        final bool isEnabled = !controller.is24Hours.value;
        final String currentSelection = controller.userCheckInSelections.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isEnabled ? Colors.white : Colors.grey.shade100),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // Use the locally stored value from the observer
              value: currentSelection.isEmpty ? null : currentSelection,
              isExpanded: true,
              // Only enable onChanged if isEnabled is true
              onChanged: isEnabled
                  ? (val) => controller.userCheckInSelections.value = val ?? ""
                  : null,
              items: controller.timeSlots.map((String t) {
                return DropdownMenuItem<String>(
                  value: t,
                  child: CustomText(
                    "$label - $t",
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }

  Widget _timeDropdownCheckOut(String label) {
    return Expanded(
      child: Obx(() {
        // Accessing .value here registers the dependency
        final bool isEnabled = !controller.is24Hours.value;
        final String currentSelection = controller.userCheckOutSelections.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isEnabled ? Colors.white : Colors.grey.shade100),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // Use the locally stored value from the observer
              value: currentSelection.isEmpty ? null : currentSelection,
              isExpanded: true,
              // Only enable onChanged if isEnabled is true
              onChanged: isEnabled
                  ? (val) => controller.userCheckOutSelections.value = val ?? ""
                  : null,
              items: controller.timeSlots.map((String t) {
                return DropdownMenuItem<String>(
                  value: t,
                  child: CustomText("$label - $t", fontSize: 13),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSwitchTile(String title, RxBool obsValue) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Obx(() => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
            // Adjust row spacing here
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Expanded(
                  child: CustomText(
                    title,
                  ),
                ),

                // Small Sized Switch
                SizedBox(
                  height: 30, // Tighten vertical space
                  width: 45, // Tighten horizontal space
                  child: Transform.scale(
                    scale: 0.75, // Adjust for small size
                    child: Switch(
                      value: obsValue.value,
                      onChanged: (val) => obsValue.value = val,
                      activeColor: AppColors.primaryColor,
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }

  Widget _buildFoodRestrictionSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText("Any Food Habit Restrictions"),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: controller.foodRestrictionsEnabled.value,
                  activeColor: AppColors.primaryColor,
                  onChanged: (val) =>
                      controller.foodRestrictionsEnabled.value = val,
                ),
              )
            ],
          ),
          if (controller.foodRestrictionsEnabled.value) ...[
            const Text("Kindly Indicate Which Food Habits You Allow.",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            _checkBoxTile("All"),
            _checkBoxTile("Vegetarian"),
            _checkBoxTile("Non-Vegetarian"),
          ]
        ],
      ),
    );
  }

  Widget _checkBoxTile(String label) {
    return Obx(() {
      // Accessing .value directly ensures Obx tracks changes
      List<String> currentList = List<String>.from(controller.userFoodTypeSelections);
      bool isSelected = currentList.contains(label);

      // Match these exactly with your UI labels and API expected values
      final foodOptions = ["Vegetarian", "Non-Vegetarian"];

      return CheckboxListTile(
        title: CustomText(label, fontSize: 12),
        value: isSelected,
        checkColor: AppColors.white,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (bool? v) {
          if (v == null) return;

          if (label == "All") {
            if (v) {
              // Select "All" and every individual option
              currentList = ["All", ...foodOptions];
            } else {
              // Clear everything
              currentList.clear();
            }
          } else {
            if (v) {
              currentList.add(label);
              // Check if all individual options are now selected to toggle "All"
              if (foodOptions.every((item) => currentList.contains(item))) {
                currentList.add("All");
              }
            } else {
              currentList.remove(label);
              // If any single item is unchecked, "All" must be removed
              currentList.remove("All");
            }
          }

          // Assign the new list to the observable to trigger UI update
          controller.userFoodTypeSelections.value = currentList;
        },
      );
    });




  }
}

