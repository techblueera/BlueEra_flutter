import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  String _selectedAspect = 'Portrait';

  @override
  void initState() {
    // TODO: implement initState
    // Default to first background color option, we no longer use images
    msgController.isMsgPostEdit = widget.isEdit;

    if (widget.isEdit) {
      msgController.uploadMsgPostUrl.value = widget.post?.media?.first ?? "";
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

// keep track of aspect selection per image
  Map<int, String> _selectedAspects = {};

  @override
  Widget build(BuildContext context) {
    double fixedHeight = MediaQuery.of(context).size.width; // Instagram style

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

                        ///FOR ADD POST...
                        if (!msgController.isMsgPostEdit) {
                          Get.to(() => MessagePostPreviewScreenNew(
                                postVia: widget.postVia,
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
                          if (isOnlyHttpsLink(msgController.postText.value)) {
                            Get.to(() => MessagePostPreviewScreenNew(
                                ));
                            return;
                          } else {
                            commonSnackBar(
                                message: "Only https links are allowed");
                            return;
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
                  textInputAction: TextInputAction.none,
                  onChange: (val) {
                    msgController.postText.value = val;
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
                    // The result will be handled by the TagUserController
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
                InkWell(
                  onTap: msgController.pickImage,
                  child: Container(
                    width: SizeConfig.screenWidth,
                    height: SizeConfig.size50 + 2,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      // White background
                      borderRadius: BorderRadius.circular(10.0),
                      // Rounded corners
                      border: Border.all(width: 1, color: AppColors.greyE5),
                      boxShadow: [AppShadows.textFieldShadow],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LocalAssets(imagePath: AppIconAssets.black_gallery),
                          SizedBox(width: SizeConfig.size8),
                          CustomText(
                            'Upload Photos',
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.large,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size15),

                _buildPhotoUploadSection(),

                SizedBox(height: SizeConfig.size15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Obx(() {
      return ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.all(SizeConfig.size1),
        physics: NeverScrollableScrollPhysics(),
        itemCount: msgController.images.length,
        itemBuilder: (context, index) {
          if (msgController.isPhotoPostEdit) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                msgController.selectedPhotos[index],
                width: double.infinity,
                height: 200, // fixed height for list item
                fit: BoxFit.cover,
              ),
            );
          }
          // check aspect ratio for this image
          final aspect = _selectedAspects[index] ?? 'Square';

          if (aspect == 'Square') {
            msgController.aspectRatio.value = 1 / 1; // 0.8
          } else if (aspect == 'Portrait') {
            msgController.aspectRatio.value = 4 / 5; // 0.8
          }

          double previewWidth = Get.width * msgController.aspectRatio.value;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: Get.width * 0.9,
                    width: previewWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image:
                            FileImage(File(msgController.images[index].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => msgController.removePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // --- Crop button ---------------------------
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: _photoPhotoPopUpMenu(index),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  PopupMenuButton<String> _photoPhotoPopUpMenu(int index) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        setState(() {
          _selectedAspects[index] = value; // update aspect ratio per image
        });
      },
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.mainTextColor.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.crop,
          color: Colors.white,
          size: 18,
        ),
      ),
      itemBuilder: (context) => photoPostMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> photoPostMenuItems() {
    final items = <Map<String, dynamic>>[
      {'title': 'Square', 'icon': Icons.square_outlined},
      {'title': 'Portrait', 'icon': Icons.crop_portrait_outlined},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      final menu = items[i];
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['title'],
          child: Row(
            children: [
              Icon(menu['icon'], color: AppColors.grey5B),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                menu['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  bool isOnlyHttpsLink(String message) {
    final regex = RegExp(r'^(https:\/\/[^\s]+)$');
    return regex.hasMatch(message.trim());
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
