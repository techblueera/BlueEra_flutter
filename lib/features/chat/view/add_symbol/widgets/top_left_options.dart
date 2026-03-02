import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/common_box_shadow.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';
import '../../contacts/view/be_available_contacts_list.dart';

class TopLeftOptions extends StatefulWidget {
  const TopLeftOptions({super.key});

  @override
  State<TopLeftOptions> createState() => _TopLeftOptionsState();


}

class _TopLeftOptionsState extends State<TopLeftOptions> {
  final c = Get.find<AddChatSymbolController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size20),
          _durationSelector(c),
          SizedBox(height: SizeConfig.size20),
          _visibilitySelector(c),
        ],
      );
    });
  }

  Widget _durationSelector(AddChatSymbolController c) {
    return _commonSelectorBox(
      title: "Set Symbol Duration in Days",
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            return Obx(() {
              final day = index + 1;
              final selected = c.selectedDays.value == day;
              return GestureDetector(
                onTap: () => c.selectedDays.value = day,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin:
                  const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Colors.blue : AppColors.greyE5,
                    ),
                  ),
                  child: Center(
                    child: CustomText(
                      "$day",
                      color: selected ? AppColors.white : AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget dropItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.black),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.black)),
      ],
    );
  }

  Widget _visibilitySelector(AddChatSymbolController c) {
    return _commonSelectorBox(
      title: "Choose Symbol Privacy",
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(width: 1, color: AppColors.greyE5),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            margin: EdgeInsets.symmetric(vertical: 6),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PostVisibility>(
                value: c.visibility.value,
                dropdownColor: Colors.white,
                isDense: true,
                isExpanded: false,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.grayText),
                items: [
                  DropdownMenuItem(
                    value: PostVisibility.public,
                    child: dropItem(Icons.public, "Public"),
                  ),
                  DropdownMenuItem(
                    value: PostVisibility.private,
                    child: dropItem(Icons.lock, "Private"),
                  ),
                  DropdownMenuItem(
                    value: PostVisibility.custom,
                    child: dropItem(Icons.people, "Custom"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) c.visibility.value = val;
                },
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size4,),
          if( c.visibility.value == PostVisibility.custom)
            Obx(() {
              return Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(
                    height: SizeConfig.size8,
                  ),
                  CustomText(
                    "${c.onExceptContactSelectedList.length} Contact Excepted",
                    color: AppColors.black,
                    fontSize: 14,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  InkWell(
                    onTap: () {
                      Get.to(() =>
                          BeAvailableContactsList(preSelectedUsers: c
                              .onExceptContactSelectedList,
                            maxSelectionCount: 5,
                            tagPersonsSelection: true,
                            isFromAddMember: true,
                            onSelectedPersons: (selectedPersonsList) {
                              c.onExceptContactSelectedList.value =
                                  selectedPersonsList;
                            },
                          ));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.primaryColor
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CustomText(
                          "Choose Except Contacts", color: AppColors.white,
                          fontWeight: FontWeight.w600,),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size4,
                  ),
                ],
              );
            })
        ],
      ),
    );
  }

  // common box decoration
  BoxDecoration get _box =>
      BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(width: 1, color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      );

  Widget _commonSelectorBox({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      decoration: _box.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
          ),
          SizedBox(height: SizeConfig.size8),
          child,
        ],
      ),
    );
  }
}
