import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';
import '../../../contacts/view/be_available_contacts_list.dart';

class TopLeftOptions extends StatelessWidget {
  const TopLeftOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddChatSymbolController>();

    return Positioned(
      left: 10,
      top: 20,
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _postTypeSelector(c),
            const SizedBox(height: 12),
            _durationSelector(c),
            const SizedBox(height: 12),
            _visibilitySelector(c),
          ],
        );
      }),
    );
  }

  Widget _postTypeSelector(AddChatSymbolController c) {
    return _commonSelectorBox(
      title: "Change symbol type",
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PostType?>(
          value: c.selectedPostType.value,
          dropdownColor: Colors.black87,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isDense: true,
          hint: Row(
            children: const [
              Icon(Icons.image, size: 18, color: Colors.white),
              SizedBox(width: 8),
              CustomText('Select', color: Colors.white),
            ],
          ),
          items: [
            DropdownMenuItem(
              value: PostType.image,
              child: _dropItem(Icons.image, "Image"),
            ),
            DropdownMenuItem(
              value: PostType.video,
              child: _dropItem(Icons.videocam, "Video"),
            ),
            DropdownMenuItem(
              value: PostType.text,
              child: _dropItem(Icons.text_fields, "Text"),
            ),
          ],
          onChanged: (val) {
            if (val != null) c.choosePostType(val);
          },
        ),
      ),
    );
  }

  Widget _durationSelector(AddChatSymbolController c) {
    return _commonSelectorBox(
      title: "Set Duration in days",
      child: Row(
        children: [
          const Icon(Icons.timer, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          SizedBox(
            height: 30,
            width: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) {
                final day = index + 1;
                final selected = c.selectedDays.value == day;

                return GestureDetector(
                  onTap: () => c.selectedDays.value = day,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.white30,
                      ),
                    ),
                    child: Text(
                      "$day",
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilitySelector(AddChatSymbolController c) {
    return _commonSelectorBox(
      title: "Choose symbol privacy",
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<PostVisibility>(
              value: c.visibility.value,
              dropdownColor: Colors.black87,
              isDense: true,
              isExpanded: false,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: [
                DropdownMenuItem(
                  value: PostVisibility.public,
                  child: _dropItem(Icons.public, "Public"),
                ),
                DropdownMenuItem(
                  value: PostVisibility.private,
                  child: _dropItem(Icons.lock, "Private"),
                ),
                DropdownMenuItem(
                  value: PostVisibility.custom,
                  child: _dropItem(Icons.people, "Custom"),
                ),
              ],
              onChanged: (val) {
                if (val != null) c.visibility.value = val;
              },
            ),
          ),
          if( c.visibility.value == PostVisibility.custom)
            Obx(() {
              return Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: SizeConfig.size4,
                  ),
                  Container(
                    height: 1,
                    width: 120,
                    color: AppColors.greyA5,
                  ),
                  SizedBox(
                    height: SizeConfig.size4,
                  ),
                  CustomText(
                    "${c.onExceptContactSelectedList.length} Contact Excepted",
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                  SizedBox(
                    height: SizeConfig.size6,
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
                      width: 120,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.primaryColor
                      ),
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Center(
                        child: CustomText("Add Except", color: AppColors.white,
                          fontSize: 13,),
                      ),
                    ),
                  )
                ],
              );
            })
        ],
      ),
    );
  }

  // -----------------------
  // helper drop item
  // -----------------------
  static Widget _dropItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.white),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.white)),
      ],
    );
  }

  // common box decoration
  BoxDecoration get _box =>
      BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
      );

  Widget _commonSelectorBox({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 8),
      decoration: _box.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: SizeConfig.size4),
          child,
        ],
      ),
    );
  }

}
