import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void openBlockSelectionDialog(
    {
      required BuildContext context,
      required VoidCallback voidCallback
    }) {

  // showDialog(
  //   context: context,
  //   builder: (BuildContext context) {
  //     return Dialog(
  //       backgroundColor: AppColors.white,
  //       child: BlockModalSheet(
  //         userId: userId,
  //       ),
  //     );
  //   },
  // );

  commonConformationDialog(
      context: context,
      barrierDismissible: false,
      text: "Are you sure you want to block this user?",
      confirmCallback: () async {
        voidCallback();
      },
      cancelCallback: () {
        Get.back();
      });


}


