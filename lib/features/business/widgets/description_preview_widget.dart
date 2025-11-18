
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DescriptionPreview extends StatefulWidget {
  final String text;
  final String? dialogTitle;

  const DescriptionPreview({
    Key? key,
    required this.text,
    this.dialogTitle,
  }) : super(key: key);

  @override
  State<DescriptionPreview> createState() => _DescriptionPreviewState();
}

class _DescriptionPreviewState extends State<DescriptionPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final maxChars = 120; // ~4 lines

    final showMore = widget.text.length > maxChars;

    final displayText = showMore && !_expanded
        ? "${widget.text.substring(0, maxChars)}..."
        : widget.text;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: SizeConfig.medium,
          color: Colors.black,
          fontFamily: AppConstants.OpenSans,
        ),
        children: [
          TextSpan(text: displayText),
          if (showMore && !_expanded)
            TextSpan(
              text: " ${AppStrings.read_more.tr}",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _showFullTextDialog(context, TextStyle());
                },
            ),
        ],
      ),
    );
  }

  void _showFullTextDialog(BuildContext context, TextStyle style) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.92,
            // ⬇️ height expands naturally but limits only when too tall
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            // 🔹 dynamic height based on content
            children: [
              CustomText(
                widget.dialogTitle ?? AppStrings.businessDescription,
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),

              SizedBox(height: SizeConfig.size10),

              Flexible(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: HighlightText(
                    text: widget.text,
                    style: TextStyle(
                      color: AppColors.mainTextColor,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppConstants.OpenSans,
                      height: 1.30,
                    ),
                  ),
                ),
              ),

              // ⬇️ Reduced gap to minimize bottom space
              SizedBox(height: SizeConfig.size4),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  // 🔹 small bottom padding
                  child: TextButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: CustomText(
                      AppStrings.close,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium15,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
