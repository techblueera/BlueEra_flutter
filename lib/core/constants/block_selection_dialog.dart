import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/block_model_sheet.dart';
import 'package:flutter/material.dart';

void openBlockSelectionDialog(
    {
      required BuildContext context,
      required VoidCallback postBlockVoidCallback,
      required VoidCallback userBlockVoidCallback
    }){
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColors.white,
        child: BlockPostModalSheet(
             postBlockVoidCallback: ()=> postBlockVoidCallback(),
             userBlockVoidCallback: ()=> userBlockVoidCallback(),
        ),
      );
    },
  );
}



