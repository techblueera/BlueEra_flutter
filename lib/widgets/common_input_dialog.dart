import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A reusable single-field input dialog following the app's standard dialog
/// chrome ([CustomFormCard] + [CommonTextField] + [CustomBtn]).
///
/// Use [showCommonInputDialog] to present it. Returns the trimmed text the
/// user entered, or `null` if they dismissed/cancelled the dialog.
class CommonInputDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final String confirmLabel;
  final String? Function(String?)? validator;
  final int? maxLength;
  final bool isCapitalize;
  final TextInputType? keyBoardType;

  const CommonInputDialog({
    super.key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.confirmLabel = '',
    this.validator,
    this.maxLength,
    this.isCapitalize = true,
    this.keyBoardType,
  });

  @override
  State<CommonInputDialog> createState() => _CommonInputDialogState();
}

class _CommonInputDialogState extends State<CommonInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue ?? '');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: CustomFormCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.mainTextColor),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size12),
                CommonTextField(
                  textEditController: _controller,
                  hintText: widget.hintText,
                  validator: widget.validator,
                  maxLength: widget.maxLength,
                  isCounterVisible: widget.maxLength != null,
                  isCapitalize: widget.isCapitalize,
                  keyBoardType: widget.keyBoardType,
                  autoFocus: true,
                  textInputAction: TextInputAction.done,
                  onDone: (_) => _onSubmit(),
                ),
                SizedBox(height: SizeConfig.size20),
                CustomBtn(
                  onTap: _onSubmit,
                  title: widget.confirmLabel.isNotEmpty
                      ? widget.confirmLabel
                      : AppStrings.add.tr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents a [CommonInputDialog] and resolves to the entered text (trimmed)
/// or `null` if cancelled/dismissed.
Future<String?> showCommonInputDialog(
  BuildContext context, {
  required String title,
  String? hintText,
  String? initialValue,
  String confirmLabel = '',
  String? Function(String?)? validator,
  int? maxLength,
  bool isCapitalize = true,
  TextInputType? keyBoardType,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => CommonInputDialog(
      title: title,
      hintText: hintText,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      validator: validator,
      maxLength: maxLength,
      isCapitalize: isCapitalize,
      keyBoardType: keyBoardType,
    ),
  );
}
