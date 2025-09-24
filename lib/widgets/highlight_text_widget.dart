import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  const HighlightText({super.key, required this.text, this.style, this.maxLines, this.overflow});

  @override
  Widget build(BuildContext context) {
    final linkRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final mentionRegex = RegExp(r'(@\w+)');

    final spans = <TextSpan>[];
    int start = 0;

    // Combine regex for both links and mentions
    final combinedRegex =
        RegExp('${linkRegex.pattern}|${mentionRegex.pattern}');
    for (final match in combinedRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: style ?? const TextStyle(
            color: Colors.black,
            fontFamily: AppConstants.OpenSans,
          ),
        ));
      }

      final matchText = match.group(0)!;

      if (linkRegex.hasMatch(matchText)) {
        // It's a link
        spans.add(TextSpan(
          text: matchText,
          style: const TextStyle(
            color: AppColors.primaryColor,
            decoration: TextDecoration.underline,
            fontFamily: AppConstants.OpenSans,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri url = Uri.parse(matchText);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
        ));
      } else if (mentionRegex.hasMatch(matchText)) {
        // It's a mention (@Bava)
        spans.add(TextSpan(
          text: matchText,
          style: const TextStyle(
              color: AppColors.primaryColor,
              fontFamily: AppConstants.OpenSans,
              fontWeight: FontWeight.bold),
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style:  style ?? const TextStyle(
          color: Colors.black,
          fontFamily: AppConstants.OpenSans,
        ),
      ));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: spans),
    );
  }
}
