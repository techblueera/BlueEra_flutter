import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class BusinessHoursWidget extends StatelessWidget {
  final String days;
  final String openTime;
  final String closeTime;

  const BusinessHoursWidget({
    super.key,
    required this.days,
    required this.openTime,
    required this.closeTime,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$days: ',
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
          TextSpan(
            text: openTime,
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: Colors.green,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
          TextSpan(
            text: ' – ',
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.mainTextColor,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
          TextSpan(
            text: closeTime,
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: Colors.red,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
        ],
      ),
    );
  }
}
