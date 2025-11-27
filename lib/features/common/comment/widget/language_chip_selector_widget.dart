import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageChipSelector extends StatelessWidget {
  final List<String> languages;
  final RxString selectedLanguage;

  LanguageChipSelector({
    required this.languages,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: languages.map((language) {
          final bool isSelected = selectedLanguage.value == language;

          return GestureDetector(
            onTap: () => selectedLanguage.value = language,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: CustomText(
                language,
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
