import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/ai_description_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AIExpertiseGeneratorButton extends StatelessWidget {
  final Function(String) onSelected;

  const AIExpertiseGeneratorButton({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_awesome, color: AppColors.primaryColor),
      onPressed: () => _showAiSuggestions(context),
    );
  }
  void _showAiSuggestions(BuildContext context) async {
    // 1. Show Loading

    final suggestions = await AIService().generateExpertiseDescriptionRepo();


    if (suggestions == null || suggestions.isEmpty) {
      commonSnackBar(message: "Error: Failed to generate suggestions");
      return;
    }

    // Local state to track selected items
    List<String> selectedItems = [];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setInternalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomText("Select Expertise", fontWeight: FontWeight.bold, fontSize: 18),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),

                // Use Wrap for the "Tag" cloud effect
                Wrap(
                  spacing: 8.0, // Horizontal space between chips
                  runSpacing: 4.0, // Vertical space between lines
                  children: suggestions.map((item) {
                    final isSelected = selectedItems.contains(item);
                    return FilterChip(
                      label: CustomText(
                        item,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setInternalState(() {
                          if (selected) {
                            selectedItems.add(item);
                          } else {
                            selectedItems.remove(item);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryColor : Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: selectedItems.isEmpty
                        ? null
                        : () {
                      // Return the result joined by commas
                      onSelected(selectedItems.join(", "));
                      Get.back();
                    },
                    child: CustomText(
                      "Add ${selectedItems.length} items",
                  color: Colors.white, fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Padding for SafeArea
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
