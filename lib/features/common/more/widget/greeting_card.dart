import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GreetingCard extends StatelessWidget {
  final String imagePath;

  const GreetingCard({
    super.key,
    required this.imagePath
  });

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imagePath,
            height: SizeConfig.size300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
            left: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SizeConfig.size30),
                boxShadow: [AppShadows.textFieldShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.size30),
                child: CachedNetworkImage(
                  imageUrl: userProfileGlobal,
                  width: SizeConfig.size45,
                  height: SizeConfig.size45,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: SizeConfig.size35,
                    height: SizeConfig.size30,
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.person, size:  SizeConfig.size45 / 2),
                ),
              ),
            ),
        ),
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.maxFinite,
              height: SizeConfig.size80,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)),
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.black.withValues(alpha: 0.7),
                        AppColors.black.withValues(alpha: 0.0)
                      ]
                  )
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CustomText(
                      isIndividual() ? userNameGlobal : businessOwnerNameGlobal,
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.large,
                      fontFamily: AppConstants.OpenSans,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CustomText(
                      isIndividual() ? userProfessionGlobal : businessNameGlobal,
                      fontWeight: FontWeight.w400,
                      fontSize: SizeConfig.small,
                      fontFamily: AppConstants.OpenSans,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
