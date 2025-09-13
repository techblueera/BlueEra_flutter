import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
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
    final style = widget.style ?? const TextStyle(color: AppColors.black28);

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

          // If text fits, no need for expand/collapse
          if (!isOverflow) {
            return SizedBox(
              width: double.infinity,
              child: HighlightText(
                text:widget.text,
                // style: style,
                // textAlign: TextAlign.start,
              ),
            );
            return SizedBox(
              width: double.infinity,
              child: Text(
                widget.text,
                style: style,
                textAlign: TextAlign.start,
              ),
            );

        }

        if (_readMore) {
          // Create "Read more" text painter to measure its width
          final readMoreStyle = style.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: SizeConfig.medium15,
          );
          final readMorePainter = TextPainter(
            text: TextSpan(text: '... Read more', style: readMoreStyle),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            textScaler: MediaQuery.of(context).textScaler,
          )..layout();

          // Calculate the cutoff position, accounting for "Read more" width
          final lastLineHeight = (widget.trimLines - 1) * tpTrimmed.preferredLineHeight;
          final availableWidthOnLastLine = constraints.maxWidth - readMorePainter.width;

          final cutoffOffset = tpTrimmed.getPositionForOffset(Offset(
            availableWidthOnLastLine,
            lastLineHeight + (tpTrimmed.preferredLineHeight * 0.5), // Middle of last line
          ));

          final cutoffIndex = cutoffOffset.offset;
          String visibleText = widget.text.substring(0, cutoffIndex);

          // Clean up the visible text
          if (visibleText.endsWith(' ')) {
            visibleText = visibleText.trimRight();
          }

          // Remove any partial word at the end to avoid awkward cuts
          final lastSpaceIndex = visibleText.lastIndexOf(' ');
          if (lastSpaceIndex > 0 && cutoffIndex < widget.text.length) {
            visibleText = visibleText.substring(0, lastSpaceIndex);
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              softWrap: true,
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(text: visibleText,),
                  const TextSpan(text: '... '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
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
                        fontSize: SizeConfig.medium15,                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Expanded view with "Show less" link below
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(widget.text, style: style),
              HighlightText(
                text:widget.text,
                // style: style,
                // textAlign: TextAlign.start,
              ),
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
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Flexible(
                  child: SingleChildScrollView(
                    child: HighlightText(text:widget.text, ),
                  ),
                ),
                SizedBox(height: SizeConfig.size8),
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