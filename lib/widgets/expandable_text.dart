import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

enum ExpandMode { expandable, dialog }

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final ValueChanged<double>? onHeightChanged;
  final ExpandMode expandMode;
  final String? dialogTitle;
  final bool? isReadMoreNewLine;

  const ExpandableText({
    Key? key,
    required this.text,
    this.trimLines = 3,
    this.style,
    this.onHeightChanged,
    this.expandMode = ExpandMode.expandable,
    this.dialogTitle,
    this.isReadMoreNewLine = false,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;


  bool get _isLong {
    if (widget.text.isEmpty) return false;

    final textSpan = TextSpan(
      text: widget.text,
      style: widget.style ?? const TextStyle(color: AppColors.black28),
    );

    final tp = TextPainter(
      text: textSpan,
      maxLines: widget.trimLines,
      textDirection: TextDirection.ltr,
    );

    // subtract your padding (15 left & right)
    tp.layout(maxWidth: MediaQuery.of(context).size.width - (SizeConfig.size15 * 2));

    return tp.didExceedMaxLines;
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final textSpan = TextSpan(
            text: widget.text,
            style: style,
          );
          final tp = TextPainter(
            text: textSpan,
            maxLines: widget.trimLines,
            textDirection: TextDirection.ltr,
          );
          tp.layout(maxWidth: constraints.maxWidth);

          // Find the end position for trimLines
          final endPos = tp.getPositionForOffset(
            Offset(tp.size.width, tp.size.height),
          );
          // Leave room for "... Read more"
          final truncateIndex = endPos.offset > 10
              ? endPos.offset - 10
              : endPos.offset;
          final truncatedText = widget.text.substring(
            0,
            truncateIndex.clamp(0, widget.text.length),
          );

          return RichText(
            maxLines: widget.trimLines,
            overflow: TextOverflow.clip,
            text: TextSpan(
              children: [
                TextSpan(
                  style: style,
                  text: '$truncatedText... ',
                ),
                TextSpan(
                  text: (widget.isReadMoreNewLine ?? false)
                      ? "${AppStrings.read_more.tr}\n"
                      : AppStrings.read_more.tr,
                  style: style.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      if (widget.expandMode == ExpandMode.dialog) {
                        _showFullTextDialog(context, style);
                      } else {
                        setState(() => _readMore = false);
                      }
                    },
                ),
              ],
            ),
          );
        },
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
            AppStrings.show_less,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: SizeConfig.size13,

          ),
        ),
      ],
    );
  }

  void _showFullTextDialog(BuildContext context, TextStyle style) {
    showDialog(
      context: context,

      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
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
              CustomText(
                widget.dialogTitle ?? AppStrings.description,
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              Flexible(
                child: Scrollbar(
                  radius: const Radius.circular(10),
                  trackVisibility: false,
                  thumbVisibility: false,
                  thickness: 3,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
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
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const CustomText(AppStrings.close, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class ExpandableTextVideo extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final ValueChanged<double>? onHeightChanged;
  final ExpandMode expandMode;
  final String? dialogTitle;
  final bool? isReadMoreNewLine;

  const ExpandableTextVideo({
    Key? key,
    required this.text,
    this.trimLines = 3,
    this.style,
    this.onHeightChanged,
    this.expandMode = ExpandMode.expandable,
    this.dialogTitle,
    this.isReadMoreNewLine = false,
  }) : super(key: key);

  @override
  State<ExpandableTextVideo> createState() => _ExpandableTextVideoState();
}

class _ExpandableTextVideoState extends State<ExpandableTextVideo> {
  bool _readMore = true;


  bool get _isLong {
    if (widget.text.isEmpty) return false;

    final textSpan = TextSpan(
      text: widget.text,
      style: widget.style ?? const TextStyle(color: AppColors.black28),
    );

    final tp = TextPainter(
      text: textSpan,
      maxLines: widget.trimLines,
      textDirection: TextDirection.ltr,
    );

    // subtract your padding (15 left & right)
    tp.layout(maxWidth: MediaQuery.of(context).size.width - (SizeConfig.size15 * 2));

    return tp.didExceedMaxLines;
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
      return RichText(
        text: TextSpan(

          children: [
            TextSpan(
             style: widget.style ?? const TextStyle(color: AppColors.black28),
              text: widget.text.length > 50
                  ? '${widget.text.substring(0, 50)}... '
                  : widget.text,
            ),
            TextSpan(
              text: (widget.isReadMoreNewLine ?? false) ? "${AppStrings.read_more.tr}\n" : '${AppStrings.read_more.tr}',
              style: style.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (widget.expandMode == ExpandMode.dialog) {
                    _showFullTextDialog(context, style);
                  } else {
                    setState(() => _readMore = false);
                  }
                },
            ),
          ],
        ),
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
            AppStrings.show_less,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: SizeConfig.size13,

          ),
        ),
      ],
    );
  }

  void _showFullTextDialog(BuildContext context, TextStyle style) {
    showDialog(
      context: context,

      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
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
              CustomText(
                widget.dialogTitle ?? AppStrings.description,
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              Flexible(
                child: Scrollbar(
                  radius: const Radius.circular(10),
                  trackVisibility: false,
                  thumbVisibility: false,
                  thickness: 3,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
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
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const CustomText(AppStrings.close, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
