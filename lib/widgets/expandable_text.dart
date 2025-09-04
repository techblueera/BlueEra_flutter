
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

enum ExpandMode {
  expandable, // Expands inline
  dialog,     // Opens in dialog
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final ValueChanged<double>? onHeightChanged;
  final ExpandMode expandMode; // New parameter
  final String? dialogTitle; // Optional dialog title

  const ExpandableText({
    Key? key,
    required this.text,
    this.trimLines = 3,
    this.style,
    this.onHeightChanged,
    this.expandMode = ExpandMode.expandable, // Default to expandable
    this.dialogTitle,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const TextStyle(
        color: AppColors.black28
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: style);

        // Trimmed version
        final tpTrimmed = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: widget.trimLines,
          textAlign: TextAlign.start,
          textScaler: MediaQuery.of(context).textScaler,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflow = tpTrimmed.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _readMore ? widget.trimLines : null,
              overflow: _readMore ? TextOverflow.ellipsis : null,
              style: style,
            ),
            if (isOverflow)
              GestureDetector(
                onTap: () {
                  if (widget.expandMode == ExpandMode.dialog) {
                    _showFullTextDialog(context, style);
                  } else {
                    setState(() {
                      _readMore = !_readMore;
                      if (widget.onHeightChanged != null) {
                        // You can implement height change callback here if needed
                      }
                    });
                  }
                },
                child: CustomText(
                  widget.expandMode == ExpandMode.dialog
                      ? 'Read more'
                      : (_readMore ? 'Read more' : 'Show less'),
                  color: AppColors.primaryColor,
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFullTextDialog(BuildContext context, TextStyle style) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      widget.dialogTitle ?? 'Description',
                      fontSize: SizeConfig.large18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainTextColor,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.text,
                      style: style,
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: CustomText(
                      'Close',
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}