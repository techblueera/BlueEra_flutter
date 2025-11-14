import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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
      return RichText(
        text: TextSpan(

          children: [
            TextSpan(
             style: widget.style ?? const TextStyle(color: AppColors.black28),
              text: widget.text.length > 120
                  ? '${widget.text.substring(0, 120)}... '
                  : widget.text,
            ),
            TextSpan(
              text: (widget.isReadMoreNewLine ?? false) ? "Read more\n" : 'Read more',
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
            'Show less',
            color: AppColors.primaryColor,
            // fontSize: SizeConfig.medium15,
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
                widget.dialogTitle ?? 'Description',
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
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
                  child: const CustomText('Close', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
