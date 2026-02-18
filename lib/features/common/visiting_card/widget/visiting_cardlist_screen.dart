import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/common/visiting_card/helper/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget_infoRow(
    {required String imagePath,
    required String? title,
    Color? textColor,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    Color? iconColor}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      LocalAssets(
        imagePath: imagePath,
        height: 18,
        width: 18,
      ),
      SizedBox(width: 4),
      Expanded(
        child: CustomText(
          title,
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          textAlign: textAlign,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}


