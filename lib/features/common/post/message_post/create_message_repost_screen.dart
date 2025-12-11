import 'dart:io';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateMessagePostScreenRepost extends StatefulWidget {
  final Post? post;
  final bool isEdit;
  final bool isRepost = false;
  final PostVia? postVia;

  const CreateMessagePostScreenRepost(
      {super.key, this.post, required this.isEdit, this.postVia});

  @override
  State<CreateMessagePostScreenRepost> createState() =>
      _CreateMessagePostScreenNewState();
}

class _CreateMessagePostScreenNewState
    extends State<CreateMessagePostScreenRepost> {
  final msgController = Get.put(MessagePostController());

  @override
  void dispose() {
    Get.delete<MessagePostController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (msgController.isLoading.value) {
          commonSnackBar(message: "Please wait Request is still processing...");
          return false;
        }
        msgController.clearRepostData();
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            return CommonBackAppBar(
              title: AppStrings.messageRepost,
              isLeading: msgController.isLoading.value ? false : true,
              onBackTap: () {
                msgController.clearRepostData();
                Get.back();
              },
            );
          }),
        ),
        bottomNavigationBar: Obx(() {
          if (msgController.isLoading.value) {
            return SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size15,
                  right: SizeConfig.size15,
                  bottom: SizeConfig.size15,
                  top: SizeConfig.size5),
              child: CustomBtn(
                  isValidate: (msgController.postText.value.isNotEmpty),
                  onTap: (msgController.postText.value.isNotEmpty)
                      ? () async {
                          try {
                            msgController.isLoading.value = true;

                            final position = await getCurrentLocation();
                            dio.FormData formData = dio.FormData();

                            // Add media files
                            for (int i = 0;
                                i < (msgController.imagesList.length);
                                i++) {
                              final data = msgController.imagesList[i];

                              File processed = File(data.path);

                              String fileName = processed.path.split('/').last;
                              formData.files.add(
                                MapEntry(
                                  ApiKeys.media,
                                  await dio.MultipartFile.fromFile(
                                    processed.path,
                                    filename: fileName,
                                  ),
                                ),
                              );
                            }
                            formData.fields.add(MapEntry(
                                ApiKeys.type, AppConstants.MESSAGE_POST));
                            formData.fields.add(MapEntry(
                                ApiKeys.repostId, widget.post?.id ?? ""));

                            formData.fields.add(MapEntry(ApiKeys.postVia,
                                widget.postVia?.name ?? "profile"));

                            if (msgController
                                .descriptionMessage.value.text.isNotEmpty)
                              formData.fields.add(MapEntry(ApiKeys.sub_title,
                                  msgController.descriptionMessage.value.text));

                            // Add location if available
                            if (position?.latitude != null &&
                                position?.longitude != null) {
                              formData.fields.add(MapEntry(ApiKeys.latitude,
                                  position?.latitude.toString() ?? ""));
                              formData.fields.add(MapEntry(ApiKeys.longitude,
                                  position?.longitude.toString() ?? ""));
                            }
                            await msgController.rePostMsgPostControllerNew(
                              bodyReq: formData,
                            );

                            msgController.isLoading.value = false;
                          } on Exception catch (e) {
                            logs("ERROR ${e}");
                            msgController.isLoading.value = false;

                            // TODO
                          }
                        }
                      : null,
                  title: AppStrings.submit),
            ),
          );
        }),
        body: SafeArea(
          child: Obx(() {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.paddingM),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Message description input
                        CommonTextField(
                          textEditController:
                              msgController.descriptionMessage.value,
                          hintText:
                          AppStrings.defaultRepostMessage,
                          title: AppStrings.yourMessage,
                          maxLine: 5,
                          maxLength: 1000,
                          isValidate: false,
                          keyBoardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onChange: (val) {
                            // Replace multiple consecutive newlines with a single newline
                            String newVal =
                                val.replaceAll(RegExp(r'\n{3,}'), '\n');

                            // Block http/https
                            newVal = newVal.replaceAll(
                                RegExp(r'https?:\/\/\S+'), '');

                            if (newVal != val) {
                              msgController.descriptionMessage.value.text =
                                  newVal;
                              msgController.descriptionMessage.value.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: newVal.length),
                              );
                            }

                            msgController.postText.value = newVal;
                          },

                          validator: (val) {
                            if (val == null || val.trim().length < 10) {
                              return AppStrings.messageMinLengthError.tr;
                            }
                            if (RegExp(r'https?').hasMatch(val)) {
                              return  AppStrings.messageLinkNotAllowed.tr;
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Obx(() => CustomText(
                                "${msgController.postText.value.length}/1000",
                                color: Colors.grey,
                                fontSize: 12,
                              )),
                        ),
                        SizedBox(height: SizeConfig.size15),

                        PhotoUploadWidget(
                          isFromRepost: true,
                        ),
                        SizedBox(height: SizeConfig.size15),

                        ((msgController.imagesList.isNotEmpty))
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size15,
                                  vertical: SizeConfig.size8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.secondaryTextColor
                                            .withValues(alpha: 0.2)),
                                    color: AppColors.white, // light background
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(
                                            top: SizeConfig.size10,
                                            left: SizeConfig.size10),
                                        child: Row(
                                          children: [
                                            CachedAvatarWidget(
                                                imageUrl: widget
                                                    .post?.user?.profileImage,
                                                size: 30.0,
                                                borderRadius: 25),
                                            SizedBox(
                                              width: SizeConfig.size10,
                                            ),
                                            Expanded(
                                              child: SizedBox(
                                                width: Get.width,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Flexible(
                                                      child: CustomText(
                                                        widget.post?.user?.name,
                                                        fontSize:
                                                            SizeConfig.large,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        color: AppColors
                                                            .secondaryTextColor,
                                                      ),
                                                    ),
                                                    if (widget.post?.user
                                                                ?.username !=
                                                            null &&
                                                        (widget
                                                                .post
                                                                ?.user
                                                                ?.username
                                                                ?.isNotEmpty ??
                                                            false))
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: 0),
                                                          child: CustomText(
                                                            " @${widget.post?.user?.username}",
                                                            fontSize: SizeConfig
                                                                .medium,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: AppColors
                                                                .shadowColor,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: SizeConfig.size10,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 90,
                                            height: 90,
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.only(left: 8.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  color: Colors.black,
                                                  child: CachedNetworkImage(
                                                    imageUrl: widget.post?.media
                                                            ?.first ??
                                                        "",
                                                    width: 90,
                                                    height: 90,
                                                    fit: BoxFit.fill,
                                                    placeholder:
                                                        (context, url) =>
                                                            Container(
                                                      width: 90,
                                                      height: 90,
                                                      color: Colors.grey[300],
                                                      // child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(Icons.person,
                                                                size: 42 / 2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // RIGHT: Text Section
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                  SizeConfig.size10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if ((widget.post?.title
                                                          ?.isNotEmpty ??
                                                      false))
                                                    CustomText(
                                                      widget.post?.title ?? "",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .mainTextColor,
                                                    ),
                                                  SizedBox(height: 4),
                                                  CustomText(
                                                    widget.post?.subTitle ?? "",
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    color: AppColors
                                                        .secondaryTextColor,
                                                    fontSize: SizeConfig.size13,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: SizeConfig.size10,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.only(
                                  left: SizeConfig.size15,
                                ),
                                child: FeedCard(
                                    post: widget.post,
                                    index: 0,
                                    postFilteredType: PostType.otherPosts,
                                    horizontalPadding: 0,
                                    isRepost: true),
                              ),
                      ],
                    ),
                  ),
                ),
                if (msgController.isLoading.value) CircularIndicator(),
              ],
            );
          }),
        ),
      ),
    );
  }
}
