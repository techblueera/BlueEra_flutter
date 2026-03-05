

import 'package:BlueEra/features/chat/view/add_symbol/widgets/add_message_symbol.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/bottom_caption_field.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/symbol_upload_widget.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/top_left_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';

import '../../../../core/constants/size_config.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_btn.dart';
import '../../auth/controller/add_chat_symbol_controller.dart';


class AddChatSymbolScreen extends StatefulWidget {
  AddChatSymbolScreen({super.key, this.message, this.sharedText, this.sharedFiles});
  final  message;
  final String? sharedText;
  final List<SharedAttachment?>? sharedFiles;

  @override
  State<AddChatSymbolScreen> createState() => _AddChatSymbolScreenState();
}

class _AddChatSymbolScreenState extends State<AddChatSymbolScreen> {
  final controller = Get.put(AddChatSymbolController());

  @override
  void initState() {
    controller.clearData();
    super.initState();
    _prefillSharedData();
  }

  void _prefillSharedData() {
    if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
      final text = widget.sharedText!;
      final isLink = Uri.tryParse(text)?.hasScheme ?? false;
      if (isLink) {
        controller.choosePostType(PostType.link);
      } else {
        controller.choosePostType(PostType.text);
      }
      controller.linkTextSymbolController.text = text;
    }
    // else if (widget.sharedFiles != null && widget.sharedFiles!.isNotEmpty) {
    //   final files = widget.sharedFiles!
    //       .where((e) => e?.path != null && e!.path.isNotEmpty)
    //       .map((e) => File(e!.path))
    //       .toList();
    //   if (files.isNotEmpty) {
    //     final ext = files.first.path.split('.').last.toLowerCase();
    //     final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
    //     controller.choosePostType(isVideo ? PostType.video : PostType.image);
    //     controller.imagesList.addAll(files);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Add Symbol",
        isLeading: true,
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
                isLoading: controller.isPosting.value,
                isValidate: (
                    (controller.itTextOrLinkPost() ? true : controller
                        .imagesList.length >= 1)),
                onTap: (controller.itTextOrLinkPost() ? true : controller
                    .imagesList.length >= 1)
                    ? () async {
                  controller.createSymbol();
                }
                    : null,
                title: "Post Symbol"),
          ),
        );
      }),
      body: Obx(() {
        return SafeArea(
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
                      children: [
                        SymbolUploadWidget(),
                        if (controller.selectedPostType.value != null &&
                            (controller.itTextOrLinkPost()))
                          CreateMessagePostScreen(),
                        if (controller.selectedPostType.value != null)
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(!controller.itTextOrLinkPost())
                              CommonTextField(
                                validator: (val) {
                                  return null;
                                },
                                textEditController: controller
                                    .captionController,
                                title: "",
                                hintText: "Add a caption...",
                                inputLength: 300,
                                maxLine: 4,
                                onChange: (v) {

                                },
                              ),
                              TopLeftOptions(),
                              BottomCaptionField()
                            ],
                          )
                      ],
                    ))));
      }),
    );
  }
}
