import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/common_ai_genereted_button.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiDescriptionField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final RxString rxValue; // To track length reactively
  final String aiType;
  final Map<String, dynamic> aiData;
  final int maxChars;

  const AiDescriptionField({
    super.key,
    required this.label,
    required this.controller,
    required this.rxValue,
    required this.aiType,
    required this.aiData,
    this.hintText = "Enter description...",
    this.maxChars = 1000,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Label and AI Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(label, fontWeight: FontWeight.w500),
            AIGeneratorButton(
              type: aiType,
              data: aiData,
              onSelected: (generatedText) {
                controller.text = generatedText;
                rxValue.value = generatedText;
              },
            )
          ],
        ),

        // The TextField
        CommonTextField(
          textEditController: controller,
          title: "", // Title is handled by our Row above
          hintText: hintText,
          maxLine: 5,
          maxLength: maxChars,
          isValidate: false,
          keyBoardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChange: (value) {
            // Logic: Prevent more than 2 consecutive newlines
            String formatted = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
            if (formatted != value) {
              controller.text = formatted;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
            rxValue.value = formatted;
          },
        ),

        SizedBox(height: SizeConfig.size5),

        // Character Counter
        Align(
          alignment: Alignment.centerRight,
          child: Obx(() => CustomText(
            "${rxValue.value.length}/$maxChars",
            color: Colors.grey,
            fontSize: 12,
          )),
        ),
      ],
    );
  }
}