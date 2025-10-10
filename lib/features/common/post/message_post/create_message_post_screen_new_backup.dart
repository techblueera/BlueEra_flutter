import 'dart:io';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart' as dio;

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
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
  void initState() {
    // TODO: implement initState
    // Default to first background color option, we no longer use images

    super.initState();
  }

  @override
  void dispose() {
    Get.delete<MessagePostController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Message Repost",
        isLeading: true,
        onBackTap: () {
          msgController.clearRepostData();
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
                isValidate: (msgController.postText.value.isNotEmpty ),
                onTap: (msgController.postText.value.isNotEmpty )
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

                            File processed = File(data.imageFile?.path ?? "");

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
                          await msgController.addMsgPostControllerNew(
                            bodyReq: formData,
                          );

                          msgController.isLoading.value = false;
                        } on Exception catch (e) {
                          logs("ERRO ${e}");
                          msgController.isLoading.value = false;

                          // TODO
                        }
                      }
                    : null,
                title: "Submit"),
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
                      "Hello Everyone @India User Now I am Using It’s Amazing, I suggest to Join Me.",
                  title: "Your Message",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (val) {
                    // Replace multiple consecutive newlines with a single newline
                    String newVal = val.replaceAll(RegExp(r'\n{2,}'), '\n');

                    // Block http/https
                    newVal = newVal.replaceAll(RegExp(r'https?:\/\/\S+'), '');

                    if (newVal != val) {
                      msgController.descriptionMessage.value.text = newVal;
                      msgController.descriptionMessage.value.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: newVal.length),
                      );
                    }

                    msgController.postText.value = newVal;
                  },
                  validator: (val) {
                    if (val == null || val.trim().length < 50) {
                      return "Message must be at least 50 characters long";
                    }
                    if (RegExp(r'https?').hasMatch(val)) {
                      return "Links are not allowed in the message";
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

                PhotoUploadWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
