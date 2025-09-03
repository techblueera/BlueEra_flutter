import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CommonDocumentPicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onClear;
  final Function(BuildContext context) onSelect;

  const CommonDocumentPicker({
    Key? key,
    required this.imagePath,
    required this.onClear,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.0),
      child: imagePath != null && imagePath!.isNotEmpty
          ? Container(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color:AppColors.fillColor,
        ),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.folderSkyIcon),
            SizedBox(width: SizeConfig.size4),
            Expanded(
              child: CustomText(
                maxLines: 2,
                imagePath!.split('/').last,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.grey9B,
              ),
            ),
            InkWell(
              onTap: onClear,
              child: Icon(Icons.close, color: AppColors.black),
            ),
          ],
        ),
      )
          : InkWell(
        onTap: () => onSelect(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size15),
          margin: EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color:AppColors.fillColor,
          ),
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalAssets(imagePath: AppIconAssets.uploadIcon, imgColor:  theme.colorScheme.onTertiary),
              SizedBox(width: SizeConfig.size10),
              CustomText(
                "Upload Document",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color:Color.fromRGBO(122, 139, 154, 1,),
              ),
              CustomText(
                " /",
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w400,
                color:Color.fromRGBO(122, 139, 154, 1,),
              ),
              SizedBox(width: SizeConfig.size2),
              LocalAssets(imagePath: AppIconAssets.cameraWhiteIcon, imgColor: Color.fromRGBO(122, 139, 154, 1,)),
              SizedBox(width: SizeConfig.size7),
              CustomText(
                "Take Photo",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: Color.fromRGBO(122, 139, 154, 1,),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
