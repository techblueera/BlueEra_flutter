import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? content;
  final String? icon;
  final Widget? child;
  final VoidCallback? onTap;

  const InfoCard(
      {required this.title, required this.icon, this.content, this.child,required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              (icon == '') ? SizedBox() : LocalAssets(imagePath: icon ?? ''),
              (icon == '') ? SizedBox() : SizedBox(width: SizeConfig.size18),
              Expanded(
                child: CustomText(
                  title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(onTap:onTap,child: LocalAssets(imagePath: AppIconAssets.pen,imgColor: Colors.black,))
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          if (content != null)
            CustomText(
              content!,
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
