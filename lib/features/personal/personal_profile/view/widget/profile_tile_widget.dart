
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

Widget profileListTile({required String? iconPath, required String? title}) {
  return ListTile(
    leading: CircleAvatar(
        backgroundColor: AppColors.blue3F,
        child: LocalAssets(imagePath:iconPath ?? "")),
    title: CustomText(title ?? "",),
    trailing: LocalAssets(imagePath:AppIconAssets.add),
  );
}
