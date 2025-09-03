import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class CreateMessagePostScreen extends StatefulWidget {
  final Post? post;
  final bool isEdit;
  final PostVia? postVia;

  const CreateMessagePostScreen({super.key, this.post, required this.isEdit, this.postVia});

  @override
  State<CreateMessagePostScreen> createState() =>
      _CreateMessagePostScreenState();
}

class _CreateMessagePostScreenState extends State<CreateMessagePostScreen> {
  final previewContainerKey = GlobalKey();

  final msgController = Get.put(MessagePostController());
  final tagUserController = Get.put(TagUserController());

  final List<Color> colorOptions = [
    Color(0xFF26C2DC),
    AppColors.primaryColor,
    Color(0xFF7ACAA5),
    Color(0xFF55C265),
    Color(0xFF8FA842),
    Color(0xFFB6B326),
    Color(0xFFF1B32D),
    Color(0xFFC1A03F),
    Color(0xFFFE8A8B),
  ];

  @override
  void initState() {
    // TODO: implement initState
    // Default to first background color option, we no longer use images
    msgController.selectedBgColor.value = colorOptions.first;
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
                CustomText(
                  'Choose Your Card',
                  fontSize: SizeConfig.small,
                  color: Colors.black,
                ),
                SizedBox(height: SizeConfig.size12),
                // CommonTextField(
                //   textEditController: msgController.postTitleController.value,
                //   hintText: "Title of your post",
                //   maxLine: 2,
                //   title: "Title",
                //   maxLength: 60,
                //   isValidate: false,
                //
                //   onChange: (val) {
                //     msgController.messageTitle.value = val;
                //   },
                // ),

                // Card Preview Section
                msgController.isMsgPostEdit
                    ? NetWorkOcToAssets(
                        imgUrl: msgController.uploadMsgPostUrl.value)
                    : Obx(() => RepaintBoundary(
                          key: previewContainerKey,
                          child: Container(
                            padding: EdgeInsets.all(SizeConfig.paddingXL),
                            decoration: BoxDecoration(
                              color: msgController.selectedBgColor.value,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            height: 200,
                            width: 330,
                            alignment: Alignment.center,
                            child: IgnorePointer(
                              ignoring: msgController.isMsgPostEdit,
                              child: TextField(
                                controller:
                                    msgController.postTextDataController.value,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(140),
                                ],
                                showCursor:msgController.isCursorHide.value ,
                                cursorColor: AppColors.white,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                maxLines: null,
                                expands: true,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: SizeConfig.medium15,
                                    fontFamily:
                                        msgController.selectedFontFamily.value),
                                onChanged: (val) {
                                  msgController.postText.value = val;
                                },
                                decoration: InputDecoration(
                                  filled: false,
                                  isCollapsed: true,
                                  // removes default internal padding
                                  // contentPadding: EdgeInsets.zero, // removes additional padding

                                  hintText: "Type your short message on card",
                                  hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: SizeConfig.extraLarge,
                                      fontWeight: FontWeight.bold),
                                  disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: AppColors.transparent)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: AppColors.transparent)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: AppColors.transparent)),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: AppColors.transparent)),
                                ),
                              )

                            ),
                          ),
                        )),
                if (!msgController.isMsgPostEdit) ...[
                  SizedBox(height: SizeConfig.size24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        "Background Color",
                        fontSize: SizeConfig.small,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size12),
                  Wrap(
                    spacing: 10,
                    children: colorOptions
                        .map((color) => Padding(
                              padding:
                                  EdgeInsets.only(bottom: SizeConfig.size10),
                              child: GestureDetector(
                                onTap: () =>
                                    msgController.selectedBgColor.value = color,
                                child: Obx(() => CircleAvatar(
                                      backgroundColor: color,
                                      radius: 13,
                                      child: msgController
                                                  .selectedBgColor.value ==
                                              color
                                          ? Icon(Icons.check,
                                              color: Colors.white, size: 18)
                                          : SizedBox.shrink(),
                                    )),
                              ),
                            ))
                        .toList(),
                  ),

                  SizedBox(height: SizeConfig.size24),
                  Row(
                    children: [
                      CustomText(
                        "Font Style",
                        fontSize: SizeConfig.small,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: msgController.fontStyles.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final style = msgController.fontStyles[index];
                        return Obx(() => GestureDetector(
                              onTap: () => msgController
                                  .changeFontFamily(style['family']!),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color:
                                      msgController.selectedFontFamily.value ==
                                              style['family']
                                          ? Colors.blue[100]
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: msgController
                                                .selectedFontFamily.value ==
                                            style['family']
                                        ? Colors.blue
                                        : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: CustomText(
                                  style['name']!,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: style['family'],
                                ),
                              ),
                            ));
                      },
                    ),
                  ),
                  SizedBox(height: SizeConfig.size24),
                ],
                SizedBox(height: SizeConfig.size24),

                // Message description input

                CommonTextField(
                  textEditController: msgController.descriptionMessage.value,
                  hintText: "Briefly describe your message...",
                  title:                   "Description of Message",
                  maxLine: 5,
                  maxLength: 150,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.none,
                  onChange: (val) {
                    msgController.messageText.value = val;
                  },
                ),
                SizedBox(
                  height: SizeConfig.size5,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => CustomText(
                        "${msgController.messageText.value.length}/150",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.size15),

                Obx(() {
                  if (!msgController.isAddLink.value) {
                    return InkWell(
                      onTap: () {
                        msgController.isAddLink.value = true;
                      },
                      child: Row(
                        children: [
                          LocalAssets(imagePath: AppIconAssets.addBlueIcon,imgColor: AppColors.primaryColor,),
                          SizedBox(width: SizeConfig.size10),
                          CustomText(
                            'Add Link (Reference / Website)',
                            fontSize: SizeConfig.large,
                            color: AppColors.primaryColor,
                          )
                        ],
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
                // Continue button
                Obx(() {
                  return CustomBtn(
                      isValidate: msgController.postText.value.isNotEmpty,
                      onTap: msgController.postText.value.isNotEmpty
                          ? () async {
                        msgController.isCursorHide.value=false;
                        // FocusManager.instance.primaryFocus?.unfocus();
await Future.delayed(Duration(milliseconds: 200));
                        ///FOR ADD POST...
                              if (!msgController.isMsgPostEdit) {
                                File? file;
                                RenderRepaintBoundary boundary =
                                    previewContainerKey
                                            .currentContext!
                                            .findRenderObject()
                                        as RenderRepaintBoundary;
                                ui.Image image =
                                    await boundary.toImage(pixelRatio: 3.0);
                                ByteData? byteData = await image.toByteData(
                                    format: ui.ImageByteFormat.png);
                                Uint8List pngBytes =
                                    byteData!.buffer.asUint8List();

                                // 2. Save to file
                                final directory = await getTemporaryDirectory();
                                file = File(
                                    '${directory.path}/screenshot_${DateTime.now().microsecondsSinceEpoch}.png');
                                await file.writeAsBytes(pngBytes);
                                Get.to(()=> MessagePostPreviewScreen(
                                  imagePath: file?.path,
                                  postVia: widget.postVia,
                                ));
                                return;
                              }

                              ///FOR EDIT....
                              if (msgController.isMsgPostEdit) {
                                if (widget.post?.taggedUsers?.isNotEmpty ??
                                    false) {
                                  final taggedIds =
                                      widget.post?.taggedUsers ?? [];

                                  tagUserController.selectedUsers.value =
                                      tagUserController.allUsers.where((user) {
                                    final isTagged =
                                        taggedIds.contains(user.id);
                                    user.isSelected.value =
                                        isTagged; // set isSelected based on tagged
                                    return isTagged;
                                  }).toList();
                                }

                                Get.to(()=> MessagePostPreviewScreen(
                                  imagePath: "",
                                ));
                                return;
                              }
                            }
                          : null,
                      title: "Continue");
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
