import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';

class EditGroupDetailsDialog extends StatefulWidget {
  const EditGroupDetailsDialog({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<EditGroupDetailsDialog> createState() => _EditGroupDetailsDialogState();
}

class _EditGroupDetailsDialogState extends State<EditGroupDetailsDialog> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(AppStrings.editGroupDetailsLabel.tr,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 10),
            Obx(() {
              return InkWell(
                onTap: (){
                  chatViewController.isPublicGroup.value =
                  !chatViewController.isPublicGroup.value;
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.whiteE5),
                    color: AppColors.white,
                    boxShadow: [
                      AppShadows.bottomShadow
                    ]
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14,vertical: 12),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                (!chatViewController.isPublicGroup.value) ? Icons
                                    .lock_outline : Icons.lock_open,
                                color: AppColors.black,
                                size: 22,
                              ),
                              SizedBox(width: 10,),
                              CustomText(
                                (!chatViewController.isPublicGroup.value)
                                    ? AppStrings.privateGroupLabel.tr
                                    : AppStrings.publicGroupLabel.tr,
                                color: AppColors.black,
                                fontSize: 16,
                              )
                            ],
                          ),
                          CustomText(
                            (!chatViewController.isPublicGroup.value) ? AppStrings.onLabel.tr : AppStrings.offLabel.tr,
                            color: AppColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),

            /// 🔹 GROUP NAME FIELD
            CommonTextField(
              title: AppStrings.groupName.tr,
              textEditController:
              chatViewController.groupNameController,
              hintText: AppStrings.groupName.tr,
            ),

            const SizedBox(height: 12),

            /// 🔹 GROUP DESCRIPTION FIELD
            CommonTextField(
              title: AppStrings.groupDescriptionLabel.tr,
              textEditController:
              chatViewController.groupDescriptionController,
              hintText: AppStrings.enterGroupDescription.tr,
              maxLine: 6,
            ),
            const SizedBox(height: 20),

            /// 🔹 SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: CustomBtn(
                isLoading: chatViewController.isEditGroupBtnLoading.value,
                  isValidate: true,
                  onTap: () async {
                    Map<String, dynamic> data  = {
                      ApiKeys.group_name: chatViewController
                          .groupNameController.text,
                      ApiKeys.description: chatViewController
                          .groupDescriptionController.text,
                      ApiKeys.public_group: chatViewController.isPublicGroup.value ,
                      ApiKeys.conversation_id:
                      widget.conversationId,
                    };
                    bool value = await chatViewController
                        .updateGroupInfo(data);
                    if (value == true) {
                      Navigator.pop(context);
                    }
                  },
                  title: AppStrings.editLabel.tr),
            ),
          ],
        ),
      ),
    );
  }
}
