import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
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
import 'package:path_provider/path_provider.dart';

Future<void> postVia(
    BuildContext context, PostCreationMenu postCreationMenu) async {
  log("account type--> $accountTypeGlobal");

  if (isIndividual()) {
    showPostViaDialog(context, postCreationMenu);

    /*  if (postCreationMenu == PostCreationMenu.videos) {
      postNavigations(context, postCreationMenu, PostVia.channel);
    } else {
      showPostViaDialog(context, postCreationMenu);
    }*/

    // if(postCreationMenu == PostCreationMenu.videos){
    //   if (channelId.isEmpty) {
    //     await showCreateChannelDialog(context, () {
    //       postNavigations(
    //           context,
    //           postCreationMenu,
    //           PostVia.profile
    //       );
    //     });
    //   } else {
    //     postNavigations(
    //         context,
    //         postCreationMenu,
    //         PostVia.channel
    //     );
    //   }
    // }else{
    //   showPostViaDialog(context, postCreationMenu);
    // }
  } else {
    /// business user don't need channel
    postNavigations(context, postCreationMenu, PostVia.profile);
  }
}

void postNavigations(
    BuildContext context, PostCreationMenu postCreationMenu, PostVia postVia) {
  log('post via--> $postVia');
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

    case PostCreationMenu.photos:
      Get.toNamed(RouteHelper.getPhotoPostScreenRoute(),
          arguments: {ApiKeys.argPostVia: postVia});
      break;

    // case PostCreationMenu.videos:
    //   showVideosPickerDialog(context, type: postVia);
    //   break;

    default:
      break;
  }
}

Future<String> getOutputPath() async {
  Directory? directory;
  if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else if (Platform.isAndroid) {
    directory = Directory(
        '/storage/emulated/0/Download/${DateTime.now().millisecondsSinceEpoch}.mp4');
  }
  return directory?.path ??
      '${directory?.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
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
    BuildContext context, PostCreationMenu postCreationMenu) async {
  String selected = 'profile'; // or 'channel'

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size30, vertical: SizeConfig.size20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Post Via",
                    color: AppColors.mainTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: SizeConfig.size7),
                  CustomText(
                    "Choose where you want to post this content",
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size15),

                  // Wrap with Theme to apply inactive color
                  RadioTheme(
                    data: RadioThemeData(
                      fillColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primaryColor; // Selected
                        }
                        return AppColors.secondaryTextColor; // Inactive
                      }),
                    ),
                    child: Column(
                      children: [
                        // Profile Option
                        RadioListTile(
                          value: 'profile',
                          groupValue: selected,
                          visualDensity: VisualDensity.compact,
                          // Reduces vertical & horizontal spacing
                          onChanged: (value) =>
                              setState(() => selected = value!),
                          contentPadding: EdgeInsets.zero,
                          title: CustomText(
                            "Profile",
                            color: AppColors.mainTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        // Channel Option
                        RadioListTile(
                          value: 'channel',
                          groupValue: selected,
                          visualDensity: VisualDensity.compact,
                          // Reduces vertical & horizontal spacing
                          onChanged: (value) =>
                              setState(() => selected = value!),
                          contentPadding: EdgeInsets.zero,
                          title: CustomText(
                            "Channel",
                            color: AppColors.mainTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomBtn(
                          onTap: () => Navigator.pop(context),
                          title: 'Cancel',
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
                                  context, postCreationMenu, PostVia.profile);
                              // showVideosPickerDialog(context, type: PostVia.profile);
                            } else {
                              log('channel is--> $channelId');
                              if (channelId.isEmpty) {
                                await showCreateChannelDialog(context, () {
                                  postNavigations(context, postCreationMenu,
                                      PostVia.profile);
                                  // showVideosPickerDialog(context, type: PostVia.profile);
                                });
                              } else {
                                postNavigations(
                                    context, postCreationMenu, PostVia.channel);
                                // showVideosPickerDialog(context, type: PostVia.channel);
                              }
                            }
                          },
                          bgColor: AppColors.primaryColor,
                          borderColor: Colors.transparent,
                          title: "Post",
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
