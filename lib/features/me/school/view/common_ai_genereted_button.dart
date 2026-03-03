import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/ai_description_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AIGeneratorButton extends StatelessWidget {
  final String type;
  final Map<String, dynamic> data;
  final Function(String) onSelected;

  const AIGeneratorButton({
    super.key,
    required this.type,
    required this.data,
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
    // 1. Basic Validation
    if (data.values.any((element) => element.toString().isEmpty)) {
      commonSnackBar(message:AppStrings.pleaseFillDataFirst.tr);
      // Get.snackbar(
      //     "Error", "Please fill in the names first to generate description");
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    final suggestions =
        await AIService().generateDescriptionRepo(type: type, data: data);

    // Get.back(); // Close loading

    if (suggestions == null || suggestions.isEmpty) {
      commonSnackBar(message:AppStrings.errorFailedSuggestions.tr);
      return;
    }

    // 2. Show suggestions in a BottomSheet or Dialog
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(AppStrings.aiSuggestions,
                      fontWeight: FontWeight.bold, fontSize: 18),
                  InkWell(onTap: () => Get.back(), child: Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 10),
              ...suggestions
                  .map((text) => ListTile(
                        title: CustomText(text),
                        onTap: () {
                          onSelected(text);
                          Get.back();
                        },
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
