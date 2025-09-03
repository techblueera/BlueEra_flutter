import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CachedAvatarWidget(
                imageUrl: "https://dummyimage.com/120x100/000/fff.png&text=MC's+Burger",
                size: SizeConfig.size100,
                borderRadius: SizeConfig.size50,
                borderColor: AppColors.primaryColor
              ),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle
                    ),
                    child: Icon(Icons.edit, color: AppColors.white, size: SizeConfig.size15),
                  )
              )
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText("Profile Picture", fontSize: SizeConfig.medium, fontWeight: FontWeight.w700, color: AppColors.black28),
          SizedBox(height: SizeConfig.size4),
          CustomText("Upload your image for resume", color: AppColors.grey9A),
        ],
      ),
    );
  }
}

