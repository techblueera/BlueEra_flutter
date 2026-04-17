import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
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
    if (data.values.any((element) => element.toString().isEmpty)) {
      commonSnackBar(message: AppStrings.pleaseFillDataFirst.tr);
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    final suggestions =
        await AIService().generateDescriptionRepo(type: type, data: data);

    if (suggestions == null || suggestions.isEmpty) {
      commonSnackBar(message: AppStrings.errorFailedSuggestions.tr);
      return;
    }

    Get.bottomSheet(
      _AiSuggestionsSheet(
        suggestions: suggestions,
        onSelected: (text) {
          onSelected(text);
          Get.back();
        },
        onRegenerate: () {
          Get.back();
          _showAiSuggestions(context);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _AiSuggestionsSheet extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onSelected;
  final VoidCallback onRegenerate;

  const _AiSuggestionsSheet({
    required this.suggestions,
    required this.onSelected,
    required this.onRegenerate,
  });

  @override
  State<_AiSuggestionsSheet> createState() => _AiSuggestionsSheetState();
}

class _AiSuggestionsSheetState extends State<_AiSuggestionsSheet> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.15),
                        AppColors.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.aiSuggestions,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.large18,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        "Tap to select a suggestion",
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(color: Colors.grey[200], height: 1),

          // Suggestions list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: widget.suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.06)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.grey[200]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isSelected
                                ? Icon(Icons.check_circle,
                                    key: const ValueKey('checked'),
                                    color: AppColors.primaryColor,
                                    size: 20)
                                : Icon(Icons.radio_button_unchecked,
                                    key: const ValueKey('unchecked'),
                                    color: Colors.grey[400],
                                    size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomText(
                            widget.suggestions[index],
                            fontSize: SizeConfig.medium,
                            color: isSelected
                                ? AppColors.mainTextColor
                                : AppColors.secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SafeArea(
              child: Row(
                children: [
                  // Regenerate
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onRegenerate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh,
                                size: 18, color: AppColors.primaryColor),
                            const SizedBox(width: 6),
                            CustomText(
                              "Regenerate",
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Use selected
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectedIndex != null
                          ? () => widget
                              .onSelected(widget.suggestions[_selectedIndex!])
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedIndex != null
                              ? AppColors.primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check,
                                size: 18,
                                color: _selectedIndex != null
                                    ? Colors.white
                                    : Colors.grey[500]),
                            const SizedBox(width: 6),
                            CustomText(
                              "Use This",
                              color: _selectedIndex != null
                                  ? Colors.white
                                  : Colors.grey[500]!,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium,
                            ),
                          ],
                        ),
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
