import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';

class ServiceHomeHeaderTitleWidget extends StatelessWidget {
  final String title, description;

  const ServiceHomeHeaderTitleWidget(
      {super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          CustomText(title,
              fontSize: 18,
              maxLines: 2,
              color: AppColors.mainTextColor,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.bold),
          if(description.isNotEmpty)...[
            const SizedBox(height: 10),
            ExpandableText(
              text: description,
              trimLines: 2,
              isReadMoreNewLine: false,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                fontFamily: AppConstants.OpenSans,
              ),
            ),
            const SizedBox(height: 10),
          ],

        ],
      ),
    );
  }
}

