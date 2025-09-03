import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CommonIconRow extends StatelessWidget {
  final Widget imageIcon;
  final VoidCallback? onTap;
  final String? image;
  final String? text;

  const CommonIconRow({
    Key? key,
    required this.imageIcon,
    this.onTap,
    this.image,
    this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap?.call();
      },
      child: Container(
        height: 25,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Padding(
                padding: EdgeInsets.only(right: SizeConfig.size5),
                child: LocalAssets(imagePath: image!),
              ),
            if (text != null) ...[
              Align(
                alignment: Alignment.bottomLeft,
                child: CustomText(
                  "$text",
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: SizeConfig.size3),
            ],
            Align(
              alignment: Alignment.bottomLeft,
              child: imageIcon,
            ),
          ],
        ),
      ),
    );
  }
}
