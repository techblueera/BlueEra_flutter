
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

Future<void> postVia(
    BuildContext context, PostCreationMenu postCreationMenu) async {
  // Show the chooser only for individual users who have already created a channel.
  // Everyone else (business users, or individuals without a channel) posts via profile.
  if (isIndividual() && channelId.isNotEmpty) {
    showPostViaDialog(context, postCreationMenu);
  } else {
    postNavigations(context, postCreationMenu, PostVia.profile);
  }
}

void postNavigations(
    BuildContext context, PostCreationMenu postCreationMenu, PostVia postVia) {
  switch (postCreationMenu) {
    case PostCreationMenu.message:
      Get.toNamed(RouteHelper.getCreateMessagePostScreenRoute(), arguments: {
        ApiKeys.post: null,
        ApiKeys.isEdit: false,
        ApiKeys.argPostVia: postVia
      });
      break;
    case PostCreationMenu.poll:
      Get.toNamed(RouteHelper.getPollInputScreenRoute(),
          arguments: {ApiKeys.argPostVia: postVia});
      break;
    default:
      break;
  }
}

Future<void> showVideosPickerDialog(BuildContext context,
    {PostVia? type}) async {
  await SelectProfilePictureDialog.showVideoDialog(
    context,
    "Upload Video",
    onPickFromCamera: () async {
      Navigator.pop(Get.context!);
      Navigator.pushNamed(
        Get.context!,
        RouteHelper.getVideoReelRecorderScreenRoute(),
        arguments: {ApiKeys.argPostVia: type},
      );
    },
    onPickFromGallery: () async {
      Navigator.pop(Get.context!);
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      Navigator.pushNamed(
        Get.context!,
        RouteHelper.getFullVideoPreviewRoute(),
        arguments: {ApiKeys.videoPath: picked?.path, ApiKeys.argPostVia: type},
      );
    },
  );
}

Future<void> showPostViaDialog(
  BuildContext context,
  PostCreationMenu postCreationMenu,
) async {
  PostVia selected = PostVia.channel;

  await showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size20,
                SizeConfig.size20,
                SizeConfig.size20,
                SizeConfig.size16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.postVia,
                    color: AppColors.mainTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  CustomText(
                    AppStrings.chooseWhereToPost,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size20),
                  _PostViaOptionTile(
                    icon: Icons.campaign_rounded,
                    title: AppStrings.channel,
                    subtitle: 'Share with your channel followers',
                    isSelected: selected == PostVia.channel,
                    onTap: () => setState(() => selected = PostVia.channel),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _PostViaOptionTile(
                    icon: Icons.person_rounded,
                    title: AppStrings.profile,
                    subtitle: 'Post from your personal profile',
                    isSelected: selected == PostVia.profile,
                    onTap: () => setState(() => selected = PostVia.profile),
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          onTap: () => Navigator.pop(context),
                          title: AppStrings.cancel,
                          bgColor: Colors.transparent,
                          borderColor: AppColors.greyE5,
                          textColor: AppColors.secondaryTextColor,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: CustomBtn(
                          onTap: () {
                            Navigator.of(context).pop();
                            postNavigations(
                                context, postCreationMenu, selected);
                          },
                          bgColor: AppColors.primaryColor,
                          borderColor: Colors.transparent,
                          title: AppStrings.post,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _PostViaOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PostViaOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        isSelected ? AppColors.primaryColor : AppColors.greyE5;
    final Color bgColor =
        isSelected ? AppColors.primaryColor.withValues(alpha: 0.06) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: SizeConfig.size40,
              height: SizeConfig.size40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.12)
                    : AppColors.greyE5,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
                size: SizeConfig.size22,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    color: AppColors.mainTextColor,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    subtitle,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Container(
              width: SizeConfig.size20,
              height: SizeConfig.size20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.greyE5,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
