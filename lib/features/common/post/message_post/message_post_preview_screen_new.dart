import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagePostPreviewScreenNew extends StatefulWidget {
  final PostVia? postVia;

  MessagePostPreviewScreenNew({Key? key, this.postVia}) : super(key: key);

  @override
  State<MessagePostPreviewScreenNew> createState() =>
      _MessagePostPreviewScreenNewState();
}

class _MessagePostPreviewScreenNewState
    extends State<MessagePostPreviewScreenNew> {
  final MessagePostController msgPostController =
      Get.find<MessagePostController>();

  final tagUserController = Get.find<TagUserController>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        msgPostController.isCursorHide.value = true;

        return true;
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: 'Post Preview',
          onBackTap: () {
            msgPostController.isCursorHide.value = true;
            Get.back();
          },
        ),
        body: Obx(() {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: Get.width,
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size15,
                          vertical: SizeConfig.size15),
                      margin: EdgeInsets.all(SizeConfig.size16),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChannelProfileHeader(
                            imageUrl: userProfileGlobal,
                            title: isIndividualUser()
                                ? userNameGlobal
                                : isBusinessUser()
                                    ? businessOwnerNameGlobal
                                    : "",
                            userName: isIndividualUser()
                                ? userNameAtGlobal
                                : businessOwnerNameGlobal,
                            subtitle: isIndividualUser()
                                ? userProfessionGlobal
                                : businessNameGlobal,
                          ),
                          /*   if (widget.imagePath?.isNotEmpty ?? false)
                            msgPostController.isMsgPostEdit
                                ? NetWorkOcToAssets(
                                    imgUrl: msgPostController
                                        .uploadMsgPostUrl.value)
                                : Image.file(File(widget.imagePath ?? "")),
*/
                          Padding(
                            padding: EdgeInsets.only(
                                left: SizeConfig.size50,
                                top: SizeConfig.size15,
                                bottom: SizeConfig.size15),
                            child: CustomText(msgPostController
                                .descriptionMessage.value.text),
                          ),
                          if (msgPostController
                              .referenceLinkController.value.text.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                  top: SizeConfig.size10,
                                  bottom: SizeConfig.size15),
                              child: CustomText(
                                msgPostController
                                    .referenceLinkController.value.text,
                                color: AppColors.primaryColor,
                              ),
                            ),

                          if (msgPostController.images.isNotEmpty)
                            InstaSlider(),

                          // Selected users chips
                          Obx(() => tagUserController.selectedUsers.isNotEmpty
                              ? Padding(
                                  padding:
                                      EdgeInsets.only(top: SizeConfig.size16),
                                  child: Wrap(
                                    children: tagUserController.selectedUsers
                                        .map((user) => UserChip(
                                              user: user,
                                              onRemove: () => tagUserController
                                                  .removeSelectedUser(user),
                                            ))
                                        .toList(),
                                  ),
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size15,
                          vertical: SizeConfig.size15),
                      margin:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonTextField(
                            title: "Nature of Post",
                            hintText: "Eg. Flower",
                            maxLength: 50,
                            isValidate: false,
                            textEditController:
                                msgPostController.natureOfPostController.value,
                          ),
                          SizedBox(height: SizeConfig.size30),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: PositiveCustomBtn(
                                  onTap: () {
                                    msgPostController.isCursorHide.value = true;
                                    Get.back();
                                  },
                                  title: "Back",
                                  textColor: AppColors.primaryColor,
                                  bgColor: AppColors.white,
                                ),
                              ),
                              SizedBox(width: SizeConfig.size16),
                              Expanded(
                                child: PositiveCustomBtn(
                                  onTap: () async {
                                    try {
                                      String? tagUserIds = tagUserController
                                          .selectedUsers
                                          .map((user) => user.id.toString())
                                          .join(',');
                                      msgPostController.isLoading.value = true;

                                      dynamic reqData;
                                      final position =
                                          await getCurrentLocation();

                                      if (msgPostController.isMsgPostEdit) {
                                        reqData = {
                                          ApiKeys.type:
                                              AppConstants.MESSAGE_POST,
                                          ApiKeys.sub_title: msgPostController
                                                  .descriptionMessage
                                                  .value
                                                  .text
                                                  .isNotEmpty
                                              ? msgPostController
                                                  .descriptionMessage.value.text
                                              : "",
                                          ApiKeys.nature_of_post:
                                              msgPostController
                                                      .natureOfPostController
                                                      .value
                                                      .text
                                                      .isNotEmpty
                                                  ? msgPostController
                                                      .natureOfPostController
                                                      .value
                                                      .text
                                                  : "",
                                          if (position?.longitude
                                                  .toString()
                                                  .isNotEmpty ??
                                              false)
                                            ApiKeys.longitude:
                                                position?.longitude,
                                          if (position?.latitude
                                                  .toString()
                                                  .isNotEmpty ??
                                              false)
                                            ApiKeys.latitude:
                                                position?.latitude,
                                          ApiKeys.reference_link:
                                              msgPostController
                                                      .referenceLinkController
                                                      .value
                                                      .text
                                                      .isNotEmpty
                                                  ? msgPostController
                                                      .referenceLinkController
                                                      .value
                                                      .text
                                                  : "",
                                          ApiKeys.tagged_users:
                                              tagUserIds.isNotEmpty
                                                  ? tagUserIds
                                                  : ""
                                        };
                                        await msgPostController
                                            .addMsgPostController(
                                          bodyReq: reqData,
                                        );
                                      } else {

                                        dio.FormData formData = dio.FormData();

                                        // Add media files
                                        for (int i = 0;
                                        i < (msgPostController.images.length);
                                        i++) {
                                          String fileName = msgPostController
                                              .images[i].path
                                              .split('/')
                                              .last ??
                                              "";
                                          formData.files.add(
                                            MapEntry(
                                              ApiKeys.media,
                                              await dio.MultipartFile.fromFile(
                                                msgPostController
                                                    .images[i].path ??
                                                    "",
                                                filename: fileName,
                                              ),
                                            ),
                                          );
                                        }
                                        formData.fields.add(MapEntry(ApiKeys.type,
                                            AppConstants.MESSAGE_POST));

                                        formData.fields.add(MapEntry(
                                            ApiKeys.postVia,
                                           "profile"));
                                        if (msgPostController.postTitleController
                                            .value.text.isNotEmpty)
                                          formData.fields.add(MapEntry(
                                              ApiKeys.title,
                                              msgPostController
                                                  .postTitleController
                                                  .value
                                                  .text));
                                        if (msgPostController.descriptionMessage
                                            .value.text.isNotEmpty)
                                          formData.fields.add(MapEntry(
                                              ApiKeys.sub_title,
                                              msgPostController.descriptionMessage
                                                  .value.text));
                                        if (tagUserIds.isNotEmpty)
                                          formData.fields.add(MapEntry(
                                              ApiKeys.tagged_users, tagUserIds));
                                        // Assuming 'photo' is the type for photo posts
                                        if (msgPostController
                                            .natureOfPostController
                                            .value
                                            .text
                                            .isNotEmpty)
                                          formData.fields.add(MapEntry(
                                              ApiKeys.nature_of_post,
                                              msgPostController
                                                  .natureOfPostController
                                                  .value
                                                  .text));

                                        if (msgPostController
                                            .referenceLinkController
                                            .value
                                            .text
                                            .isNotEmpty)
                                          formData.fields.add(MapEntry(
                                            ApiKeys.reference_link,
                                            msgPostController
                                                .referenceLinkController
                                                .value
                                                .text
                                                .isNotEmpty
                                                ? msgPostController
                                                .referenceLinkController
                                                .value
                                                .text
                                                : "",
                                          ));
                                        // final position = await getCurrentLocation();

                                        // Add location if available
                                        if (position?.latitude != null &&
                                            position?.longitude != null) {
                                          formData.fields.add(MapEntry(
                                              ApiKeys.latitude,
                                              position?.latitude.toString() ??
                                                  ""));
                                          formData.fields.add(MapEntry(
                                              ApiKeys.longitude,
                                              position?.longitude.toString() ??
                                                  ""));
                                        }
                                        await msgPostController
                                            .addMsgPostControllerNew(
                                          bodyReq: formData,
                                        );
                                      }


                                      msgPostController.isLoading.value = false;



                                    } on Exception catch (e) {
                                      logs("ERRO ${e}");
                                      msgPostController.isLoading.value = false;

                                      // TODO
                                    }
                                  },
                                  title: "Post Now",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              if (msgPostController.isLoading.value) CircularIndicator(),
            ],
          );
        }),
      ),
    );
  }
}

class InstaSlider extends StatefulWidget {
  const InstaSlider({
    super.key,
  });

  @override
  State<InstaSlider> createState() => _InstaSliderState();
}

class _InstaSliderState extends State<InstaSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.width * 0.5,
      margin: EdgeInsets.only(left: SizeConfig.size50),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // --- Image Slider ---
            PageView.builder(
              controller: _pageController,
              itemCount: msgPostController.images.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return Image.file(
                  File(msgPostController.images[index].path),
                  width: double.infinity,
                  height: 350, // adjustable
                  fit: BoxFit.cover,
                );
              },
            ),

            // --- Page Indicator ---
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentPage + 1}/${msgPostController.images.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),

            // --- Edit Button ---
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  // Handle edit action
                  debugPrint("Edit image ${_currentPage + 1}");
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
