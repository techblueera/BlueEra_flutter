import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
class MeMenuCardDesign extends StatelessWidget {
  const MeMenuCardDesign({super.key, required this.title, required this.icon});
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:AppColors.greyE5
        ),
        color: AppColors.white
      ),
      padding: EdgeInsets.symmetric(horizontal: 14,vertical: 18),
      child: Row(
        children: [
          Icon(Icons.store, color: AppColors.secondaryTextColor,),
          SizedBox(
            width: SizeConfig.size12,
          ),
          CustomText(
              "${title}",
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: AppColors.secondaryTextColor,

          )
        ],
      ),
    );
  }
}
