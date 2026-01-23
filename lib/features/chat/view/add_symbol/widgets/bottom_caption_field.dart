
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';
import '../../contacts/be_available_contacts_list.dart';

class BottomCaptionField extends StatelessWidget {
  const BottomCaptionField({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddChatSymbolController>();

    return Obx(() {
      return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 20,),
            padding: EdgeInsets.symmetric(vertical: 12,horizontal: 8),

            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(width: 1, color: AppColors.greyE5),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: Column(
              children: [
                Padding(
                  padding:  EdgeInsets.only(bottom: c.onTagSelectedList.isEmpty?0:12.0),
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
                              color: AppColors.black,),
                            SizedBox(width: SizeConfig.size6,),
                            CustomText("Tag Friends",
                              fontSize: 16,
                              color: AppColors.black,)
                          ],
                        ),
                        Icon(Icons.add, size: 24, color: AppColors.black,),
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
                          // maxWidth:  SizeConfig.size230, // 👈 adjust as needed
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: AppColors.greyE5),
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
                                  color: AppColors.primaryColor,
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

        ],
      );
    });
  }
}
