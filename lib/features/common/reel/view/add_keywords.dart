import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reelsModule/controller/reels_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class KeyWordInputWidget extends StatefulWidget {
  final List<String>? isSelectedSkills;

  const KeyWordInputWidget({super.key, required this.isSelectedSkills});

  @override
  _KeyWordInputWidgetState createState() => _KeyWordInputWidgetState();
}

class _KeyWordInputWidgetState extends State<KeyWordInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<String> allSkills = [];
  List<String> selectedSkills = [];
  bool isEdit = false;
  final reelsController = Get.find<ReelsController>();

  void addSkill(String skill) {
    skill = skill.trimRight();
    if (skill.isNotEmpty) {
      if (!selectedSkills.contains(skill)) {
        setState(() {
          isEdit = true;

          selectedSkills.add(skill);
          _controller.clear();
        });
      }
    }
  }

  void showMoreSkillsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black28,
      builder: (_) => ListView(
        padding: EdgeInsets.all(16),
        children: selectedSkills.map((skill) {
          return ListTile(
            title: Text(
              skill,
              style: TextStyle(color: AppColors.white),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.close,
                color: AppColors.white,
              ),
              onPressed: () {
                setState(() {
                  isEdit = true;

                  selectedSkills.remove(skill);
                });
                Navigator.pop(context);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  int skillTempCount = 0;

  @override
  void initState() {
    // TODO: implement initState
    selectedSkills.addAll(widget.isSelectedSkills ?? []);
    skillTempCount = selectedSkills.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final visibleSkills = selectedSkills.take(2).toList();
    final moreCount = selectedSkills.length - visibleSkills.length;

    return SafeArea(
      child: Scaffold(
          backgroundColor: AppColors.blue3F,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CustomText(
                        "Add your key",
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    CustomText(
                      "Add your key",
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    CustomText(
                      "Key",
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    TextField(
                      controller: _controller,
                      onChanged: (value) {
                        setState(() {});
                      },
                      style: TextStyle(color: Colors.white),
                      cursorColor: AppColors.white,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^ ')),
                        // FilteringTextInputFormatter.allow(RegExp(r'^ ')),
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^[^\s][a-zA-Z0-9+\.\#_\-]*$')),

                        // ⛔️ Block space at start
                      ],
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                        icon: _controller.text.isNotEmpty
                            ? Icon(
                                Icons.add,
                                color: AppColors.primaryColor,
                              )
                            : SizedBox(),
                        onPressed: () => addSkill(_controller.text),
                      )),
                    ),

                    Wrap(
                      spacing: 8,
                      children: [
                        ...visibleSkills.map((skill) => Chip(
                              color: WidgetStateProperty.all<Color>(
                                  AppColors.black28),
                              label: Text(
                                skill,
                                style: TextStyle(color: AppColors.white),
                              ),
                              deleteIconColor: AppColors.white,
                              onDeleted: () => setState(() {
                                isEdit = true;

                                selectedSkills.remove(skill);
                              }),
                            )),
                        if (moreCount > 0)
                          GestureDetector(
                            onTap: showMoreSkillsBottomSheet,
                            child: Chip(
                              label: CustomText(
                                '+ $moreCount more',
                                color: AppColors.white,
                              ),
                              color: WidgetStateProperty.all<Color>(
                                  AppColors.black28),
                            ),
                          )
                      ],
                    ),
                    SizedBox(height: 24),

                    ///SAVE CANCEL BUTTON....
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PositiveCustomBtn(
                            bgColor: Colors.transparent,
                            borderColor: AppColors.primaryColor,
                            title: AppLocalizations.of(context)!.cancel,
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                        Expanded(
                          child: PositiveCustomBtn(
                            title: /*selectedSkills.isNotEmpty
                                ? AppLocalizations.of(context)!.update
                                : */AppLocalizations.of(context)!.save,
                            onTap: selectedSkills.isNotEmpty
                                ? () {
                                    List<String> finalList = selectedSkills
                                        .where((item) =>
                                            selectedSkills.contains(item))
                                        .toList();
                                    reelsController.KeyWordList?.clear();
                                    reelsController.KeyWordList
                                        ?.addAll(finalList);

                                    Navigator.pop(context);
                                  }
                                : () {},
                          ),
                        )
                      ],
                    ),
                  ]),
            ),
          )),
    );
  }
}
