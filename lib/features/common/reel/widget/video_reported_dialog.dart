import 'package:BlueEra/widgets/custom_success_sheet.dart';
import 'package:flutter/material.dart';

/// Confirms a reported post (after [VideoActions.reportPost] succeeds).
void showVideoReportedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Material(
        color: Colors.transparent,
        child: CustomSuccessSheet(
          buttonText: 'Got it',
          title: 'You have reported this post',
          subTitle:
              'Thank you for your feedback. We will review and take necessary actions.',
          onPress: () => Navigator.pop(context),
        ),
      ),
    ),
  );
}
