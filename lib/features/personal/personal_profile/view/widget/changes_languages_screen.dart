import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/language_localization_service/language_model_new.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/getx_utils.dart';

class ChangeLanguageScreen extends StatelessWidget {
  final controller = getOrPut(() => LanguageControllerNew());

  ChangeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.changeLanguage),
      body: Obx(() {
        final langs = controller.languages;
        if (langs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: langs.length,
          itemBuilder: (context, index) {
            final lang = langs[index];
            final bool isSelected = controller.selectedLang.value == lang.code;

            return GestureDetector(
              onTap: () async {
                if (!lang.isDownloaded) {
                  // show download confirmation popup
                  _showDownloadDialog(context, lang);
                } else {
                  // switch immediately
                  await controller.changeLanguage(lang);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.primaryColor, width: 2)
                      : Border.all(color: Colors.transparent, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        lang.name,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.black87,
                      ),
                    ),
                    if (lang.isDownloaded)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else
                      const Icon(Icons.file_download_outlined),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // 🔹 Confirmation dialog
  void _showDownloadDialog(BuildContext context, LanguageModelNew lang) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomText(
                AppStrings.downloadLanguagePack,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const CustomText(
                  AppStrings.downloadLanguageDescription,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: BorderSide(
                              color: AppColors.primaryColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: CustomText(
                          AppStrings.cancel,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();

                          // download + switch language
                          await controller.downloadLanguage(lang);
                          await controller.changeLanguage(lang);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          elevation: 0,
                        ),
                        child: const CustomText(
                          AppStrings.download,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

