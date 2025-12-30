import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/features/common/post/message_post/social_post_description_screen.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/features/common/reel/controller/reel_upload_details_controller.dart';
import 'package:BlueEra/features/common/reel/models/video_category_response.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateMessagePostScreenNew extends StatefulWidget {
  final Post? post;
  final bool isEdit;
  final bool isRepost = false;
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
  final reelUploadDetailsController = Get.put(ReelUploadDetailsController());
  VideoCategoryData? _commonCategory;

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
    } else {
      reelUploadDetailsController.getVideoCategories();
    }

    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<MessagePostController>();
    deleteIfRegistered<TagUserController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.lekhaPost,
        isLeading: true,
        onBackTap: () {
          msgController.clearData();
          Get.back();
        },
      ),
      bottomNavigationBar: Obx(() {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                bottom: SizeConfig.size15,
                top: SizeConfig.size5),
            child: CustomBtn(
                isValidate: (msgController.postText.value.isNotEmpty &&
                    (msgController.imagesList.length >= 1)),
                onTap: (msgController.postText.value.isNotEmpty &&

                    (msgController.imagesList.length >= 1))
                    ? () async {
                  await Future.delayed(Duration(milliseconds: 200));
                  final input = msgController.postText.value.trim();
                  if (containsHttpButNotHttps(input)) {
                    commonSnackBar(
                        message: AppStrings.onlyHttpsAllowed);
                    return;
                  }
                  if (msgController.postText.value.isEmpty ||
                      msgController.postText.value.trim().length < 30) {
                    return commonSnackBar(
                        message: AppStrings.lekhaMin30);
                  }

                  if (msgController.imagesList.length < 1) {
                    commonSnackBar(
                        message: AppStrings.atleastOnePhoto);
                    return;
                  }

                  if (!msgController.isMsgPostEdit) {
                    Get.to(() => MessagePostPreviewScreenNew(
                      postVia: widget.postVia,
                      isEdit: msgController.isMsgPostEdit,
                    ));
                    return;
                  }

                  if (msgController.isMsgPostEdit) {
                    if (widget.post?.taggedUsers?.isNotEmpty ?? false) {
                      final taggedIds = widget.post?.taggedUsers ?? [];

                      tagUserController.selectedUsers.value =
                          tagUserController.allUsers.where((user) {
                            final isTagged = taggedIds.contains(user.id);
                            user.isSelected.value = isTagged;
                            return isTagged;
                          }).toList();
                    }
                  }
                }
                    : null,
                title: AppStrings.continueText),
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
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhotoUploadWidget(),
                  if (msgController.selectedType.value != null) ...[
                    SizedBox(height: SizeConfig.size10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(AppStrings.yourLekha),
                        InkWell(
                          onTap: () {
                            Get.to(SocialPostDescriptionScreen());
                          },
                          child: LocalAssets(
                            height: 25,
                            width: 25,
                            imagePath: AppIconAssets.ai_generative,
                            imgColor: AppColors.primaryColor,
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: SizeConfig.size10),

                    CommonTextField(
                      textEditController:
                      msgController.descriptionMessage.value,
                      hintText: AppStrings.lekhaHint,
                      title: "",
                      maxLine: 5,
                      maxLength: 1800,
                      isValidate: false,
                      keyBoardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChange: (val) {
                        String newVal =
                        val.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                        newVal =
                            newVal.replaceAll(RegExp(r'https?:\/\/\S+'), '');

                        if (msgController.descriptionMessage.value.text !=
                            newVal) {
                          msgController.descriptionMessage.value.text = newVal;
                          msgController.descriptionMessage.value.selection =
                              TextSelection.fromPosition(
                                TextPosition(offset: newVal.length),
                              );
                        }

                        msgController.postText.value = newVal;
                      },
                      validator: (val) {
                        if (val == null || val.trim().length < 30) {
                          return AppStrings.lekha30Validator.tr;
                        }
                        if (RegExp(r'https?').hasMatch(val)) {
                          return AppStrings.linkNotAllowed;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: SizeConfig.size5),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(() => CustomText(
                        "${msgController.postText.value.length}/1800",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                    ),

                    SizedBox(height: SizeConfig.size15),

                    Obx(() {
                      if (!msgController.isAddTitle.value) {
                        return InkWell(
                          onTap: () {
                            msgController.isAddTitle.value = true;
                          },
                          child: AddLinkRow(
                            title: AppStrings.addLekhaTitle,
                          ),
                        );
                      }
                      if (msgController.isAddTitle.value) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child:
                                    CustomText(AppStrings.addLekhaTitle)),
                              ],
                            ),
                            SizedBox(height: SizeConfig.size10),
                            CommonTextField(
                              textEditController:
                              msgController.postTitleController.value,
                              hintText: AppStrings.titleOfPost,
                              title: "",
                              maxLength: 50,
                              isValidate: false,
                              keyBoardType: TextInputType.multiline,
                              maxLine: 1,
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(AppStrings.natureOfPost),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    CommonDropdownDialog<VideoCategoryData>(
                      items: reelUploadDetailsController.videoCategory,
                      selectedValue: _commonCategory,
                      title: AppStrings.selectNatureOfPost,
                      hintText: AppStrings.exampleNature,
                      displayValue: (value) => value.name ?? '',
                      onChanged: (value) {
                        setState(() {
                          _commonCategory = value;
                        });
                        msgController.natureOfPostController.value.text =
                            value?.name ?? "";
                      },
                    ),

                    SizedBox(height: SizeConfig.size15),

                    Obx(() {
                      if (!msgController.isAddLink.value) {
                        return InkWell(
                          onTap: () {
                            msgController.isAddLink.value = true;
                          },
                          child: AddLinkRow(
                            title: AppStrings.addLinkTitle,
                          ),
                        );
                      }
                      if (msgController.isAddLink.value) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(AppStrings.referenceLink),
                                InkWell(
                                  onTap: () {
                                    msgController.referenceLinkController
                                        .value
                                        .clear();
                                    msgController.isAddLink.value = false;
                                  },
                                  child: CustomText(
                                    AppStrings.remove,
                                    color: AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: SizeConfig.size10),
                            HttpsTextField(
                              controller:
                              msgController.referenceLinkController.value,
                              hintText: AppStrings.addWebsiteLink,
                            ),
                          ],
                        );
                      }
                      return SizedBox();
                    }),

                    SizedBox(height: SizeConfig.size15),

                    GestureDetector(
                      onTap: () async {
                        await Get.to(() => TagUserScreen());
                      },
                      child: AddLinkRow(
                        title: AppStrings.addTagPeople,
                      ),
                    ),

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
                        : SizedBox.shrink()),
                    SizedBox(height: SizeConfig.size15),
                  ]
                ],
              );
            }),
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
                  text: title.tr,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.large,

                    // fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: " (${AppStrings.optional.tr})",
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
