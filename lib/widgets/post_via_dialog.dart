
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

Future<void> postVia(
    BuildContext context, PostCreationMenu postCreationMenu) async {
  if (isIndividual()) {
    showPostViaDialog(context, postCreationMenu);
  } else {
    /// business user don't need channel
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

    // case PostCreationMenu.photos:
    //   Get.toNamed(RouteHelper.getPhotoPostScreenRoute(),
    //       arguments: {ApiKeys.argPostVia: postVia});
    //   break;
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
  String selected = 'channel';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size30,
                vertical: SizeConfig.size20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  CustomText(
                    AppStrings.postVia,
                    color: AppColors.mainTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                  ),

                  SizedBox(height: SizeConfig.size7),

                  // Subtitle
                  CustomText(
                    AppStrings.chooseWhereToPost,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                  ),

                  SizedBox(height: SizeConfig.size15),

                  RadioTheme(
                    data: RadioThemeData(
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                            (states) => states.contains(WidgetState.selected)
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                      ),
                    ),
                    child: RadioGroup<String>(
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) setState(() => selected = value);
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'channel',
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: CustomText(
                              AppStrings.channel,
                              color: AppColors.mainTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          RadioListTile<String>(
                            value: 'profile',
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: CustomText(
                              AppStrings.profile,
                              color: AppColors.mainTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.size15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomBtn(
                          onTap: () => Navigator.pop(context),
                          title: AppStrings.cancel,
                          bgColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          textColor: AppColors.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          onTap: () async {
                            Navigator.of(context).pop();

                            if (selected == 'profile') {
                              postNavigations(
                                context,
                                postCreationMenu,
                                PostVia.profile,
                              );
                            } else {
                              if (channelId.isEmpty) {
                                await showCreateChannelDialog(context, () {
                                  postNavigations(
                                    context,
                                    postCreationMenu,
                                    PostVia.profile,
                                  );
                                });
                              } else {
                                postNavigations(
                                  context,
                                  postCreationMenu,
                                  PostVia.channel,
                                );
                              }
                            }
                          },
                          bgColor: AppColors.primaryColor,
                          borderColor: Colors.transparent,
                          title: AppStrings.post,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


Future<void> showCreateChannelDialog(
    BuildContext context, VoidCallback onSkip) async {
  await showCommonDialog(
    context: context,
    text:
        'You haven\'t created a channel yet. You can either create one now or skip this step.',
    confirmText: 'Create',
    cancelText: 'Skip',
    confirmCallback: () {
      Get.back();

      Get.toNamed(
        RouteHelper.getManageChannelScreenRoute(),
      );
    },
    cancelCallback: () {
      Get.back();
      onSkip();
    },
  );
}
