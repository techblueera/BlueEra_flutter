
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

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
            CustomText("Edit Group Details",
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
                                    ? "Private group"
                                    : "Public group",
                                color: AppColors.black,
                                fontSize: 16,
                              )
                            ],
                          ),
                          CustomText(
                            (!chatViewController.isPublicGroup.value) ? "On" : "Off",
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
              title: "Group Name",
              textEditController:
              chatViewController.groupNameController,
              hintText: "Group Name",
            ),

            const SizedBox(height: 12),

            /// 🔹 GROUP DESCRIPTION FIELD
            CommonTextField(
              title: "Group Description",
              textEditController:
              chatViewController.groupDescriptionController,
              hintText: "Enter Group Description",
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
                  title: "Edit"),
            ),
          ],
        ),
      ),
    );
  }
}
