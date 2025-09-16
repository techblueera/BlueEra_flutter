import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
import 'package:flutter/material.dart';

enum ExpandMode { expandable, dialog }

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final ValueChanged<double>? onHeightChanged;
  final ExpandMode expandMode;
  final String? dialogTitle;

  const ExpandableText({
    Key? key,
    required this.text,
    this.trimLines = 3,
    this.style,
    this.onHeightChanged,
    this.expandMode = ExpandMode.expandable,
    this.dialogTitle,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;


  bool get _isLong {
    if (widget.text.isEmpty) return false;
    final newLines = '\n'.allMatches(widget.text).length + 1;
    final roughChars = widget.text.length;
    return newLines > widget.trimLines || roughChars > widget.trimLines * 60;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const TextStyle(color: AppColors.black28);

    if (!_isLong) {
      return SizedBox(
        width: double.infinity,
        child: HighlightText(text: widget.text, style: style),
      );
    }

    if (_readMore) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HighlightText(
            text: widget.text,
            style: style,
            maxLines: widget.trimLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (widget.expandMode == ExpandMode.dialog) {
                _showFullTextDialog(context, style);
              } else {
                setState(() => _readMore = false);
              }
            },
            child: CustomText(
              'Read more',
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.medium15,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HighlightText(text: widget.text, style: style),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _readMore = true),
          child: CustomText(
            'Show less',
            color: AppColors.primaryColor,
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showFullTextDialog(BuildContext context, TextStyle style) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dialogTitle ?? 'Description',
                style: TextStyle(
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Flexible(
                child: SingleChildScrollView(
                  child: HighlightText(
                      text: widget.text,
                    style: TextStyle(
                      color: AppColors.mainTextColor,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppConstants.OpenSans,
                    )
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}