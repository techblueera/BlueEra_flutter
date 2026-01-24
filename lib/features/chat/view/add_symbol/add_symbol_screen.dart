import 'package:BlueEra/features/chat/view/add_symbol/widgets/add_message_symbol.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/bottom_caption_field.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/symbol_upload_widget.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/top_left_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/size_config.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_btn.dart';
import '../../auth/controller/add_chat_symbol_controller.dart';


class AddChatSymbolScreen extends StatefulWidget {
  AddChatSymbolScreen({super.key});

  @override
  State<AddChatSymbolScreen> createState() => _AddChatSymbolScreenState();
}

class _AddChatSymbolScreenState extends State<AddChatSymbolScreen> {
  final controller = Get.put(AddChatSymbolController());

  @override
  void initState() {
    // TODO: implement initState
    controller.clearData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Add Symbol",
        isLeading: true,
        onBackTap: () {
          // controller.clearData();
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
