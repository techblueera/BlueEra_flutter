
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../auth/controller/add_chat_symbol_controller.dart';

class CreateMessagePostScreen extends StatefulWidget {


  const CreateMessagePostScreen({super.key,});

  @override
  State<CreateMessagePostScreen> createState() =>
      _CreateMessagePostScreenState();
}

class _CreateMessagePostScreenState extends State<CreateMessagePostScreen> {
  final previewContainerKey = GlobalKey();

  final controller = Get.put(AddChatSymbolController());

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
    controller.selectedBgColor.value = colorOptions.first;


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

    return Container(
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
          //   textEditController: controller.postTitleController.value,
          //   hintText: "Title of your post",
          //   maxLine: 2,
          //   title: "Title",
          //   maxLength: 60,
          //   isValidate: false,
          //
          //   onChange: (val) {
          //     controller.messageTitle.value = val;
          //   },
          // ),

          // Card Preview Section
          Obx(() => RepaintBoundary(
            key: previewContainerKey,
            child: Container(
              padding: EdgeInsets.all(SizeConfig.paddingXL),
              decoration: BoxDecoration(
                color: controller.selectedBgColor.value,
                borderRadius: BorderRadius.circular(12),
              ),
              height: 200,
              width: 330,
              alignment: Alignment.center,
              child: TextField(
                controller:
                controller.linkTextSymbolController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(140),
                ],
                showCursor:true ,
                cursorColor: AppColors.white,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                maxLines: null,
                expands: true,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: controller.selectedFontSize.value,
                    fontWeight: controller.getFontWeight(controller.selectedFontWeight.value),
                    fontFamily:
                    controller.selectedFontFamily.value),
                onChanged: (val) {

                  setState(() {

                  });
                },
                decoration: InputDecoration(
                  filled: false,
                  isCollapsed: true,
                  // removes default internal padding
                  // contentPadding: EdgeInsets.zero, // removes additional padding

                  hintText: "Type your short message on card",
                  hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: controller.selectedFontSize.value,
                      fontWeight:  controller.getFontWeight(controller.selectedFontWeight.value),
                      fontFamily:
                      controller.selectedFontFamily.value ),
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
              ),
            ),
          )),
          SizedBox(height: SizeConfig.size20),
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
                controller.selectedBgColor.value = color,
                child: Obx(() => CircleAvatar(
                  backgroundColor: color,
                  radius: 13,
                  child: controller
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
          if(controller.selectedPostType.value!=PostType.link)
          Column(
            children: [
              SizedBox(height: SizeConfig.size10),
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
                  itemCount: controller.fontStyles.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final style = controller.fontStyles[index];

                    return Obx(() => GestureDetector(
                      onTap: () => controller
                          .changeFontFamily(style['family']!),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color:
                          controller.selectedFontFamily.value ==
                              style['family']
                              ? Colors.blue[100]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller
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
              SizedBox(height: SizeConfig.size12),
              Row(
                children: [
                  CustomText(
                    "Font Size",
                    fontSize: SizeConfig.small,
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.fontSizeList.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final num = controller.fontSizeList[index];

                    return Obx(() => GestureDetector(
                      onTap: () => controller
                          .changeFontSize(num),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color:
                          controller.selectedFontSize.value ==
                              num
                              ? Colors.blue[100]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller
                                .selectedFontSize.value ==
                                num
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          "${num.toInt()}",
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ));
                  },
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              Row(
                children: [
                  CustomText(
                    "Font Weight",
                    fontSize: SizeConfig.small,
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.fontWeightList.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final num = controller.fontWeightList[index];

                    return Obx(() => GestureDetector(
                      onTap: () => controller
                          .changeFontWeight(num),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color:
                          controller.selectedFontWeight.value ==
                              num
                              ? Colors.blue[100]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller
                                .selectedFontWeight.value ==
                                num
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          "${num}",
                          fontWeight: controller.getFontWeight(num),
                        ),
                      ),
                    ));
                  },
                ),
              ),
            ],
          ),


        ],
      ),
    );
  }
}