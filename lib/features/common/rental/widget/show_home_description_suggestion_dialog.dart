import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/business_description/business_description_controller.dart';
import 'package:BlueEra/features/common/rental/controller/home_stay_rental_service_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

showHomeDescriptionSuggestionsDialog() {
  final controller = Get.find<HomeStayRentalServiceController>();

  final tempSelected =
      controller.selectedDescription.value.obs;

  Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Obx(() {
        final suggestions =
            controller.descriptionSuggestions;

        if (suggestions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: CustomText(
              "No descriptions yet. Generate to see suggestions.",
              textAlign: TextAlign.center,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText("Select a Description",
                  fontSize: 18, fontWeight: FontWeight.w600),
              const SizedBox(height: 12),

              // 🔹 Scrollable list of suggestions
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: suggestions.map((desc) {
                      final isSelected = tempSelected.value == desc;

                      return GestureDetector(
                        onTap: () {
                          tempSelected.value = desc; // only temp select
                        },
                        child: Card(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.white,
                          elevation: isSelected ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color:
                                  isSelected ? Colors.white : Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomText(
                                    desc,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const CustomText("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Save selected description only when user presses Save
                      if ((tempSelected.value.isNotEmpty)) {
                        controller
                            .selectedDescription.value = tempSelected.value;
                        // controller.listingDescriptionController.value.text
                        controller.descriptionCtrl.text = tempSelected.value;

                      }
                      Get.back(); // close dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const CustomText(
                      "Submit",
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    ),
  );
}
