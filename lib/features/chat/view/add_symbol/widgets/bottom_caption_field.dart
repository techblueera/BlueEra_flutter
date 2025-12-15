import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/post_button.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/commom_textfield.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';
import '../../../contacts/view/be_available_contacts_list.dart';

class BottomCaptionField extends StatelessWidget {
  const BottomCaptionField({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddChatSymbolController>();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 35,
      child: Obx(() {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: SizeConfig.size230,
                margin: EdgeInsets.only(bottom: 8,),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding:  EdgeInsets.only(bottom: c.onTagSelectedList.isEmpty?0:8.0),
                      child: InkWell(
                        onTap: (){
                          Get.to(() =>
                              BeAvailableContactsList(preSelectedUsers:c.onTagSelectedList,
                                maxSelectionCount: 5,
                                tagPersonsSelection: true,
                                isFromAddMember: true,
                                onSelectedPersons: (selectedPersonsList) {

                                  c.onTagSelectedList.value=selectedPersonsList;
                                },
                              ));
                        },
                        child: Row(mainAxisAlignment: MainAxisAlignment
                            .spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_pin_rounded, size: 20,
                                  color: AppColors.white,),
                                SizedBox(width: SizeConfig.size6,),
                                CustomText("Tag Friends",
                                  fontSize: 16,
                                  color: AppColors.white,)
                              ],
                            ),
                            Icon(Icons.add, size: 24, color: AppColors.white,),
                          ],
                        ),
                      ),
                    ),
                    (c.onTagSelectedList.isEmpty)?SizedBox():Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      children: [
                        ...c.onTagSelectedList.map((user) {
                          return ConstrainedBox(
                            constraints:  BoxConstraints(
                              maxWidth:  SizeConfig.size230, // 👈 adjust as needed
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.white,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 6,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      "@${user.name}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 16,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      c.onTagSelectedList.remove(user);
                                    },
                                    child: const Icon(Icons.close, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    )

                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonTextField(validator: (val) {
                      return null;
                    },
                      textEditController: c.captionController,
                      title: "",
                      hintText: "Add a caption...",
                      inputLength: 300,
                      onChange: (v) {
                        if (v.contains("@")) {
                          // open user tag popup (you will handle)
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8,),
                  PostButton(),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
