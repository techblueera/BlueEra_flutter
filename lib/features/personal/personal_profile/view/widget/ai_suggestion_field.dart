import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiSuggestionField extends StatefulWidget {
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
  State<AiSuggestionField> createState() => _AiSuggestionFieldState();
}

class _AiSuggestionFieldState extends State<AiSuggestionField> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChange);
  }

  void _onTextChange() => setState(() {});

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChange);
    widget.textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiController = Get.put(AiSuggestionController());
    final bool isEmpty = widget.textController.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              widget.title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
          ],
        ),
        // const SizedBox(height: 10),

        // --- 🔴 Show AI suggestion only when empty ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isEmpty
              ? InkWell(
            onTap: () async {
              await aiController.fetchSuggestions(
                bodyRequest: widget.bodyRequest,
                apiType: widget.apiType,
                targetController: widget.textController,
                onSaved: widget.onSaved,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 CustomText(
                   AppStrings.createViaBlueeraAI,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                LocalAssets(
                  height: 25,
                  width: 25,
                  imagePath: AppIconAssets.ai_generative,
                  imgColor: AppColors.primaryColor,
                ),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        CommonTextField(
          maxLength: 900,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.pleaseEnterBio.tr;
            } else if (value.trim().length < 50) {
              return AppStrings.bioMinLength.tr;
            } else if (value.trim().length > 900) {
              return AppStrings.bioMaxLength.tr;
            }
            return null;
          },
          hintText: "${AppStrings.writeYour.tr} ...",
          textEditController: widget.textController,
          maxLine: 3,
          onChange: (val) => widget.onChange?.call(),
        ),
      ],
    );
  }
}
