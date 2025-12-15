import 'package:BlueEra/features/chat/view/add_symbol/widgets/bottom_caption_field.dart';

import 'package:BlueEra/features/chat/view/add_symbol/widgets/symbol_upload_widget.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/top_left_options.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/common_box_shadow.dart';
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
                    (controller.itTextOrLinkPost() ? controller
                        .linkTextSymbolController.text.isNotEmpty : controller
                        .imagesList.length >= 1)),
                onTap: (controller.itTextOrLinkPost() ? controller
                    .linkTextSymbolController.text.isNotEmpty : controller
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Obx(
                                  () =>
                                  GestureDetector(
                                    onTap: () {
                                      controller.changeBgColorRandom();
                                    },
                                    child: Container(
                                      height: 500,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: controller.selectedBgColor.value,
                                        borderRadius: BorderRadius.circular(
                                            10.0),
                                        border: Border.all(
                                            width: 1, color: AppColors.greyE5),
                                        boxShadow: [AppShadows.textFieldShadow],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              CustomText(
                                                controller.selectedPostType
                                                    .value == PostType.text
                                                    ?
                                                "Enter What You Think"
                                                    : "Enter Link",
                                                fontSize: 17,
                                                color: AppColors.white,),
                                              Row(
                                                children: [
                                                  Icon(Icons.color_lens_rounded,
                                                    color: AppColors.white,
                                                    size: 26,),
                                                  SizedBox(
                                                    width: SizeConfig.size12,
                                                  ),
                                                  InkWell(
                                                      onTap: () {
                                                        controller
                                                            .choosePostType(
                                                            null);
                                                      },
                                                      child: Icon(
                                                        Icons.cancel_outlined,
                                                        color: AppColors.white,
                                                        size: 26,)),
                                                ],
                                              )
                                            ],
                                          ),
                                          SizedBox(
                                            height: SizeConfig.size18,
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: controller
                                                  .linkTextSymbolController,
                                              maxLines: null,
                                              // allow multiline
                                              textAlign: TextAlign.center,
                                              // center text horizontally
                                              textAlignVertical: TextAlignVertical
                                                  .center,
                                              // center vertically
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textInputAction: TextInputAction
                                                  .done,
                                              decoration: InputDecoration(


                                                hintText: controller
                                                    .selectedPostType.value ==
                                                    PostType.text
                                                    ? "Enter Here"
                                                    : "Enter Link Here",
                                                hintStyle: TextStyle(
                                                    color: Colors.white70),
                                                border: InputBorder.none,
                                                // ❌ no border
                                                filled: false, // ❌ no background
                                              ),
                                              cursorColor: Colors.white,
                                              onChanged: (v) {},
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            )
                            ,
                          ),
                        if (controller.selectedPostType.value != null)
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
