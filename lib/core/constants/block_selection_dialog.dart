import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/block_model_sheet.dart';
import 'package:flutter/material.dart';

void openBlockSelectionDialog(
    {
      required BuildContext context,
      required String userId,
      required String contentId,
      required String reportType,
      required VoidCallback userBlockVoidCallback,
      required Function(Map<String, dynamic>) reportCallback
    }){
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColors.white,
        child: BlockPostModalSheet(
          reportType: reportType,
          contentId: contentId,
          otherUserId: userId,
          userBlockVoidCallback: ()=> userBlockVoidCallback(),
          reportCallback: (params)=> reportCallback(params)
        ),
      );
    },
  );
}



