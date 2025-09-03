import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResumeProfileHeader extends StatefulWidget {
  const ResumeProfileHeader({super.key});

  @override
  State<ResumeProfileHeader> createState() => _ResumeProfileHeaderState();
}

class _ResumeProfileHeaderState extends State<ResumeProfileHeader> {
  final controller = Get.find<ProfilePicController>();
  @override
  void initState() {
    // apiCall();
    super.initState();
  }
  //
  // apiCall() async {
  //   await controller.getMyResume();
  // }

  @override
  Widget build(BuildContext context) {
    return Obx(() => CommonCardWidget(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CachedAvatarWidget(
                    imageUrl: controller.getResumeData.value.profilePicture ,
                    size: SizeConfig.size100,
                    borderRadius: SizeConfig.size50,

                    borderColor: AppColors.primaryColor,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () async {
                        final newPath =
                            await SelectProfilePictureDialog.showLogoDialog(
                          context,
                          "Edit Profile Picture",
                          isOnlyCamera: true,
                          isGallery: true,
                          isCircleCrop: true,
                        );
                        if (newPath != null &&
                            newPath is String &&
                            newPath.isNotEmpty) {
                          await controller.updateProfilePic(File(newPath));
                          controller.getMyResume();
                        }
                      },
                      child: Container(
                        width: SizeConfig.size34,
                        height: SizeConfig.size34,
                        padding: EdgeInsets.all(SizeConfig.size8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: LocalAssets(
                          imagePath: AppIconAssets.pen_line,
                          imgColor: AppColors.white,
                          height: SizeConfig.size20,
                          width: SizeConfig.size20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                "Profile Picture",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                "Upload your image for resume",
                color: AppColors.grey9A,
                fontWeight: FontWeight.w400,
                fontSize: SizeConfig.small,
              ),
            ],
          ),
        ));
  }
}
