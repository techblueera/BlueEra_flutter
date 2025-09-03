import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CustomVerificationCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> bulletPoints;

  const CustomVerificationCard(
      {required this.title,
      required this.description,
      required this.bulletPoints,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.only(bottom:SizeConfig.paddingS ),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingXL, vertical: SizeConfig.paddingS),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color:AppColors.borderGray)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              title,
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
            SizedBox(
              height: SizeConfig.size2,
            ),
            CustomText(
              description,
              fontSize: SizeConfig.extraSmall,
              color: Colors.black,
            ),
            SizedBox(
              height: SizeConfig.size6,
            ),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bulletPoints
                    .map((point) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• ",
                                style: TextStyle(color: Colors.black,fontWeight: FontWeight.w700)),
                            Expanded(
                                child: CustomText(point,fontSize: SizeConfig.small,fontWeight: FontWeight.w700,color: Colors.black,)
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
