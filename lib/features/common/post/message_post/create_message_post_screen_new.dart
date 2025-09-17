import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateMessagePostScreenNew extends StatefulWidget {
  final Post? post;
  final bool isEdit;
  final PostVia? postVia;

  const CreateMessagePostScreenNew(
      {super.key, this.post, required this.isEdit, this.postVia});

  @override
  State<CreateMessagePostScreenNew> createState() =>
      _CreateMessagePostScreenNewState();
}

class _CreateMessagePostScreenNewState
    extends State<CreateMessagePostScreenNew> {
  final msgController = Get.put(MessagePostController());
  final tagUserController = Get.put(TagUserController());

  @override
  void initState() {
    // TODO: implement initState
    // Default to first background color option, we no longer use images
    msgController.isMsgPostEdit = widget.isEdit;

    if (widget.isEdit) {
      msgController.postId = widget.post?.id ?? "";
      msgController.postText.value = widget.post?.message ?? "";
      msgController.postTextDataController.value.text =
          widget.post?.message ?? "";
      msgController.descriptionMessage.value.text = widget.post?.subTitle ?? "";

      msgController.natureOfPostController.value.text =
          widget.post?.natureOfPost ?? "";

      if (widget.post?.referenceLink?.isNotEmpty ?? false) {
        msgController.isAddLink.value = true;
        msgController.referenceLinkController.value.text =
            widget.post?.referenceLink ?? "";
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    Get.delete<MessagePostController>();
    Get.delete<TagUserController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Message Post',
        isLeading: true,
        onBackTap: () {
          msgController.clearData();
          Get.back();
        },
      ),
      bottomNavigationBar: // Continue button
          Obx(() {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                bottom: SizeConfig.size15,
                top: SizeConfig.size5),
            child: CustomBtn(
                isValidate: msgController.postText.value.isNotEmpty,
                onTap: msgController.postText.value.isNotEmpty
                    ? () async {
                        await Future.delayed(Duration(milliseconds: 200));
                        final input = msgController.postText.value.trim();
                        if (containsHttpButNotHttps(input)) {
                          commonSnackBar(
                              message: "Only HTTPS links are allowed");
                          return;
                        }

                        ///FOR ADD POST...
                        if (!msgController.isMsgPostEdit) {
                          Get.to(() => MessagePostPreviewScreenNew(
                                postVia: widget.postVia,
                                isEdit: msgController.isMsgPostEdit,
                              ));
                          return;
                        }

                        ///FOR EDIT....
                        if (msgController.isMsgPostEdit) {
                          if (widget.post?.taggedUsers?.isNotEmpty ?? false) {
                            final taggedIds = widget.post?.taggedUsers ?? [];

                            tagUserController.selectedUsers.value =
                                tagUserController.allUsers.where((user) {
                              final isTagged = taggedIds.contains(user.id);
                              user.isSelected.value =
                                  isTagged; // set isSelected based on tagged
                              return isTagged;
                            }).toList();
                          }
                        }
                      }
                    : null,
                title: "Continue"),
          ),
        );
      }),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  textEditController: msgController.descriptionMessage.value,
                  hintText:
                  "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  title: "Your Message",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (val) {
                    // Replace more than one consecutive newlines with a single newline
                    String newVal = val.replaceAll(RegExp(r'\n{2,}'), '\n');

                    if (newVal != val) {
                      msgController.descriptionMessage.value.text = newVal;
                      msgController.descriptionMessage.value.selection =
                          TextSelection.fromPosition(
                            TextPosition(offset: newVal.length),
                          );
                    }

                    msgController.postText.value = newVal;
                  },
                  // onChange: (val) {
                  //   // Prevent multiple empty newlines at the end
                  //   if (val.endsWith("\n\n")) {
                  //     msgController.descriptionMessage.value.text =
                  //         val.substring(0, val.length - 1); // remove extra newline
                  //     msgController.descriptionMessage.value.selection =
                  //         TextSelection.fromPosition(
                  //           TextPosition(offset: msgController.descriptionMessage.value.text.length),
                  //         );
                  //   }
                  //
                  //   msgController.postText.value = val;
                  // },
                  validator: (val) {
                    if (val == null || val.trim().length < 50) {
                      return "Message must be at least 50 characters long";
                    }
                    return null;
                  },
                )
,


                // CommonTextField(
                //   textEditController: msgController.descriptionMessage.value,
                //   hintText:
                //       "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                //   title: "Your Message",
                //   maxLine: 5,
                //
                //   maxLength: 1000,
                //   isValidate: false,
                //   keyBoardType: TextInputType.multiline,
                //   textInputAction: TextInputAction.none,
                //   onChange: (val) {
                //     msgController.postText.value = val;
                //   },
                // ),
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

                ///ADD TITLE....
                Obx(() {
                  if (!msgController.isAddTitle.value) {
                    return InkWell(
                      onTap: () {
                        msgController.isAddTitle.value = true;
                      },
                      child: AddLinkRow(
                        title: 'Add Your Message Title',
                      ),
                    );
                  }
                  if (msgController.isAddTitle.value) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: CustomText(
                              'Add Your Message Title (Optional)',
                            )),
                            InkWell(
                              onTap: () {
                                msgController.postTitleController.value.clear();
                                msgController.messageTitle.value = "";
                                msgController.isAddTitle.value = false;
                              },
                              child: CustomText(
                                "Remove",
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                        CommonTextField(
                          textEditController:
                              msgController.postTitleController.value,
                          hintText: "Title of your post",
                          title: "",
                          maxLength: 50,
                          isValidate: false,
                          keyBoardType: TextInputType.multiline,
                          maxLine: 1,
                          // expands automatically
                          onChange: (val) {
                            msgController.messageTitle.value = val;
                          },
                        ),
                      ],
                    );
                  }
                  return SizedBox();
                }),
                SizedBox(height: SizeConfig.size15),

                Obx(() {
                  if (!msgController.isAddLink.value) {
                    return InkWell(
                      onTap: () {
                        msgController.isAddLink.value = true;
                      },
                      child: AddLinkRow(
                        title: 'Add Link (Reference / Website)',
                      ),
                    );
                  }
                  if (msgController.isAddLink.value) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText("Reference link"),
                            InkWell(
                              onTap: () {
                                msgController.referenceLinkController.value
                                    .clear();
                                msgController.isAddLink.value = false;
                              },
                              child: CustomText(
                                "Remove",
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                        HttpsTextField(
                            controller:
                                msgController.referenceLinkController.value,
                            hintText: "Add website link"),
                      ],
                    );
                  }
                  return SizedBox();
                }),
                SizedBox(height: SizeConfig.size15),
                // Add Tag People / Organization button
                GestureDetector(
                  onTap: () async {
                    await Get.to(() => TagUserScreen());
                  },
                  child: AddLinkRow(
                    title: 'Add Tag People / Organization',
                  ),
                ),

                // Selected users chips
                Obx(() => tagUserController.selectedUsers.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(top: SizeConfig.size16),
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
                SizedBox(height: SizeConfig.size15),

                PhotoUploadWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddLinkRow extends StatelessWidget {
  const AddLinkRow({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blue + icon
        LocalAssets(
          imagePath: AppIconAssets.addBlueIcon,
          imgColor: AppColors.primaryColor,
        ),
        SizedBox(width: SizeConfig.size10),
        // Wrap long text automatically
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: SizeConfig.large, color: Colors.black),
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.large,

                    // fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: " (Optional)",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
