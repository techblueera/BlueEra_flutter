import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiSuggestionField extends StatelessWidget {
  final String title;
  final String apiType; // "bio" or "description"
  final TextEditingController textController;
  final Map<String, dynamic> bodyRequest;
  final VoidCallback? onSaved;
  final VoidCallback? onChange;

  const AiSuggestionField({
    super.key,
    required this.title,
    required this.apiType,
    required this.textController,
    required this.bodyRequest,
    this.onSaved,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final aiController = Get.put(AiSuggestionController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
            InkWell(
                onTap: () async {
                  await aiController.fetchSuggestions(
                    bodyRequest: bodyRequest,
                    apiType: apiType,
                    targetController: textController,
                    onSaved: onSaved,
                  );
                },
                child: LocalAssets(
                  height: 25,
                  width: 25,
                  imagePath: AppIconAssets.ai_generative,
                  imgColor: AppColors.primaryColor,
                )),
          ],
        ),
        const SizedBox(height: 10),
        CommonTextField(
          maxLength: 900,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Bio';
            } else if (value.trim().length < 50) {
              return 'Bio must be at least 50 characters';
            } else if (value.trim().length > 900) {
              return 'Bio must not exceed 900 characters';
            }
            return null;
          },
          hintText: "Write your $title...",
          textEditController: textController,
          maxLine: 3,

          onChange: (val) => onChange?.call(),

        ),
      ],
    );
  }
}
