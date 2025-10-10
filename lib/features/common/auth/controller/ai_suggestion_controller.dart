import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AiSuggestionController extends GetxController {
  var isLoading = false.obs;
  var suggestions = <String>[].obs;
  var selectedSuggestion = ''.obs;

  /// Fetch AI suggestions (like bio, description, etc.)
  Future<void> fetchSuggestions({
    required Map<String, dynamic> bodyRequest,
    required String apiType, // e.g. "bio" or "description"
    required TextEditingController targetController,
    VoidCallback? onSaved,
  }) async {
    try {
      isLoading.value = true;
      suggestions.clear();
      selectedSuggestion.value = '';

      // Call your API
      final ResponseModel response = await AuthRepo().aiGenerateBioRepo(
        bodyParam: bodyRequest,
      );

      if (response.isSuccess && response.response?.data != null) {
        final key =
           'bio_suggestions';
        final data = response.response?.data[key] ?? [];
        suggestions.value = List<String>.from(data);

        // Show dialog
        await showSuggestionDialog(
          targetController: targetController,
          onSaved: onSaved,
        );
      } else {
        commonSnackBar(message: response.message ?? "Something went wrong");
      }
    } catch (e) {
      commonSnackBar(message: "Error Failed to fetch suggestions");
    } finally {
      isLoading.value = false;
    }
  }

  /// Show dialog for suggestions
  Future<void> showSuggestionDialog({
    required TextEditingController targetController,
    VoidCallback? onSaved,
  }) async {
    final tempSelected = selectedSuggestion.value.obs;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: Obx(() {
          if (suggestions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: CustomText("No suggestions found."),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  "Select a Suggestion",
                fontSize: 18, fontWeight: FontWeight.w600),

                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: suggestions.map((sugg) {
                        final isSelected = tempSelected.value == sugg;
                        return GestureDetector(
                          onTap: () => tempSelected.value = sugg,
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
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomText(
                                      sugg,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const CustomText("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (tempSelected.value.isNotEmpty) {
                          selectedSuggestion.value = tempSelected.value;
                          targetController.text = tempSelected.value;
                          onSaved
                              ?.call(); // trigger callback (like form validation)
                        }
                        Get.back();
                      },
                      child: const CustomText("Save",color: AppColors.white,),
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
}
