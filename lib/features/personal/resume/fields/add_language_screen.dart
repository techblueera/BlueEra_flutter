import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/languages_controller.dart';

class AddLanguageScreen extends StatefulWidget {
  const AddLanguageScreen({super.key});

  @override
  State<AddLanguageScreen> createState() => _AddLanguageScreenState();
}

class _AddLanguageScreenState extends State<AddLanguageScreen> {
  final controller = Get.put(LanguagesController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title:AppStrings.addLanguage,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: SingleChildScrollView(
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Speak & Understand
                  CustomText(
                    AppStrings.langSpeakUnderstand,
                    fontSize: SizeConfig.small,
                  ),
                  SizedBox(height: SizeConfig.size8),

                  // Dropdown for speak languages
                  Obx(() => CommonDropdown<LanguageType>(
                        items: LanguageType.values
                            .where(
                                (l) => !controller.speakLanguages.contains(l))
                            .toList(),
                        selectedValue: controller.selectedSpeakLanguage.value,
                        hintText: AppStrings.langExample,
                        displayValue: (item) => item.label,
                        onChanged: (val) {
                          if (val != null) {
                            controller.addSpeakLanguage(val);
                          }
                        },
                      )),

                  SizedBox(height: SizeConfig.size10),

                  // Chips for selected speak languages
                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.speakLanguages.map((language) {
                          return CommonChip(
                            label: language.label,
                            onDeleted: () {
                              controller.removeSpeakLanguage(language);
                            },
                          );
                        }).toList(),
                      )),

                  SizedBox(height: SizeConfig.size24),

                  // Can Write
                  CustomText(
                    AppStrings.langWrite,
                    fontSize: SizeConfig.small,
                  ),
                  SizedBox(height: SizeConfig.size8),

                  // Dropdown for write languages
                  Obx(() => CommonDropdown<LanguageType>(
                        items: LanguageType.values
                            .where(
                                (l) => !controller.writeLanguages.contains(l))
                            .toList(),
                        selectedValue: controller.selectedWriteLanguage.value,
                        hintText:AppStrings.langExample,
                        displayValue: (item) => item.label,
                        onChanged: (val) {
                          if (val != null) {
                            controller.addWriteLanguage(val);
                          }
                        },
                      )),

                  SizedBox(height: SizeConfig.size10),

                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.writeLanguages.map((language) {
                          return CommonChip(
                            label: language.label,
                            onDeleted: () {
                              controller.removeWriteLanguage(language);
                            },
                          );
                        }).toList(),
                      )),

                  SizedBox(height: SizeConfig.size24),

                  // Save button
                  Obx(() => CustomBtn(
                        onTap: controller.isFormValid &&
                                !controller.isLoading.value
                            ? () {
                                controller.saveLanguages();
                              }
                            : null,
                        title:
                            controller.isLoading.value ? AppStrings.saving : AppStrings.save,
                        isValidate: controller.isFormValid &&
                            !controller.isLoading.value,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
