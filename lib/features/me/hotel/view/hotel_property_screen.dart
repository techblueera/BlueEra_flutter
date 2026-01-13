import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_property_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelPropertySettingsScreen extends StatelessWidget {
  final controller = Get.put(HotelPropertyController());
  final HotelServiceCategoriesData hotelCategoryData;

  HotelPropertySettingsScreen({super.key, required this.hotelCategoryData});

  HotelServiceCategoriesData? getNodeByKey(String key) {
    // Use firstWhereOrNull to safely return null if not found
    return hotelCategoryData.children?.firstWhereOrNull(
      (element) => element.key == key,
    );
  }

  // Get ID safely
  String getIdFromKey(String key) {
    return getNodeByKey(key)?.id ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Hotel Policies",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTimeCard(),
              _buildDynamicSwitches(),
              _buildFoodCard(),
              SizedBox(height: 20),
              PositiveCustomBtn(
                  onTap: () {
                    controller.submitData();
                  },
                  title: "Submit"),
              SizedBox(height: 70),

            ],
          ),
        ),
      ),
    );
  }

  // logic for Check-in/Check-out row
  Widget _buildTimeCard() {
    // Dynamically fetch IDs using the Keys from your JSON response
    final String checkInId = getIdFromKey("CHECKIN_TIME");
    final String checkOutId = getIdFromKey("CHECKOUT_TIME");
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
              _timeDropdown(checkInId, "Check In"),
              SizedBox(width: 10),
              _timeDropdown(checkOutId, "Check Out"),
            ],
          )
        ],
      ),
    );
  }

  Widget _timeDropdown(String id, String label) {
    return Expanded(
      child: Obx(() {
        bool enabled = !controller.is24Hours.value;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: enabled ? Colors.white : Colors.grey.shade100),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.userSelections[id],
              isExpanded: true,
              onChanged:
                  enabled ? (val) => controller.userSelections[id] = val : null,
              items: controller.timeSlots
                  .map((t) => DropdownMenuItem(
                      value: t, child: CustomText("$label - $t", fontSize: 13)))
                  .toList(),
            ),
          ),
        );
      }),
    );
  }

  // Generates switches for keys like EARLY_CHECKIN_ALLOWED, SMOKING_ALLOWED, etc.
  Widget _buildDynamicSwitches() {
    // List of IDs that should be simple switches
    final switchIds = [
      {
        "id": getIdFromKey("EARLY_CHECKIN_ALLOWED"),
        "name": "Early Check-in Allowed"
      },
      {
        "id": getIdFromKey("LATE_CHECKOUT_ALLOWED"),
        "name": "Late Check-out Allowed"
      },
      {
        "id": getIdFromKey("UNMARRIED_COUPLES_ALLOWED"),
        "name": "Unmarried Couples Allowed"
      },
      {
        "id": getIdFromKey("BACHELOR_STUDENTS_ALLOWED"),
        "name": "Bachelor/Students Allowed"
      },
      {"id": getIdFromKey("FREE_CANCELLATION"), "name": "Free Cancellation"},
      {"id": getIdFromKey("LOCAL_ID_ALLOWED"), "name": "Local ID Allowed"},
      {"id": getIdFromKey("AADHAR_MANDATORY"), "name": "Aadhar Mandatory"},
      {"id": getIdFromKey("SMOKING_ALLOWED"), "name": "Smoking Allowed"},
    ];

    return Column(
      children: switchIds
          .map((item) => Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Obx(() => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0), // Adjust row spacing here
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Expanded(
                        child: CustomText(
                          item['name']!,
                          fontSize: 14,
                        ),
                      ),

                      // Small Sized Switch
                      Obx(() => SizedBox(
                        height: 30, // Tighten vertical space
                        width: 45,  // Tighten horizontal space
                        child: Transform.scale(
                          scale: 0.75, // Adjust for small size
                          child: Switch(
                            value: controller.activeStates[item['id']] ?? false,
                            activeColor: AppColors.primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => controller.activeStates[item['id'] ?? ""] = v,
                          ),
                        ),
                      )),
                    ],
                  ),
                )/*SwitchListTile(
                      title: CustomText(item['name']!, fontSize: 14),
                      value: controller.activeStates[item['id']] ?? false,
                      onChanged: (v) =>
                          controller.activeStates[item['id'] ?? ""] = v,
                      activeColor: AppColors.primaryColor,
                    )*/),
              ))
          .toList(),
    );
  }

  Widget _buildFoodCard() {
    String foodId = getIdFromKey("FOOD_RESTRICTIONS");
    return Obx(() => Container(
          padding: EdgeInsets.all(0),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0), // Consistent spacing
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Title Section
                    Expanded(
                      child: CustomText(
                        "Food Habit Restrictions",
                        fontSize: 14,
                      ),
                    ),

                    // 2. Small Toggle Section
                    Obx(() => SizedBox(
                      height: 30, // Reduces vertical footprint
                      width: 45,  // Reduces horizontal footprint
                      child: Transform.scale(
                        scale: 0.75, // Makes the switch smaller
                        child: Switch(
                          value: controller.activeStates[foodId] ?? false,
                          activeColor: AppColors.primaryColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes invisible padding
                          onChanged: (v) => controller.activeStates[foodId] = v,
                        ),
                      ),
                    )),
                  ],
                ),
              )/*SwitchListTile(
                title: CustomText("Food Habit Restrictions", fontSize: 14),
                value:controller.activeStates[foodId] ?? false,
                  onChanged: (v) => controller.activeStates[foodId] = v,

                activeColor: AppColors.primaryColor,
              )*/),
              if (controller.activeStates[foodId] == true) ...[
                _foodCheck("ALL", foodId),
                _foodCheck("VEGETARIAN", foodId),
                _foodCheck("NON-VEGETARIAN", foodId),
              ]
            ],
          ),
        ));
  }

  Widget _foodCheck(String label, String nodeId) {
    return Obx(() {
      // Ensure we are working with a fresh list to trigger reactivity
      List<String> currentList = List<String>.from(controller.userSelections[nodeId] ?? []);
      bool isSelected = currentList.contains(label);

      // Define your options (excluding 'ALL')
      final foodOptions = ["VEGETARIAN", "NON-VEGETARIAN"];

      return CheckboxListTile(
        title: CustomText(label, fontSize: 12),
        value: isSelected,
        controlAffinity: ListTileControlAffinity.leading,
        checkColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 7),
        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
        onChanged: (bool? v) {
          if (v == null) return;

          if (label == "ALL") {
            if (v) {
              // Select everything
              currentList = ["ALL", ...foodOptions];
            } else {
              // Deselect everything
              currentList.clear();
            }
          } else {
            if (v) {
              currentList.add(label);
              // If all individual items are now selected, also check "ALL"
              if (foodOptions.every((item) => currentList.contains(item))) {
                currentList.add("ALL");
              }
            } else {
              currentList.remove(label);
              // If any item is unchecked, "ALL" must be unchecked too
              currentList.remove("ALL");
            }
          }

          // Update the controller map to trigger Obx
          controller.userSelections[nodeId] = currentList;
        },
      );
    });
  }

}
