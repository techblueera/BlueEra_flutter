import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateOverviewScreen extends StatefulWidget {
  CreateOverviewScreen({super.key, required this.isEdit, required this.data});

  final bool isEdit;
  final String data;

  @override
  State<CreateOverviewScreen> createState() => _CreateOverviewScreenState();
}

class _CreateOverviewScreenState extends State<CreateOverviewScreen> {
  final personalProfileController = Get.find<PersonalCreateProfileController>();

  @override
  void initState() {
    // TODO: implement initState
    if (widget.isEdit)
      personalProfileController.addOverview.value.text = widget.data;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit ? "Edit Overview" : "Write Overview"),
      body: Obx(() {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.paddingM),
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonTextField(
                    title: "Career Objective",
                    hintText: "Write about your self...",
                    textEditController:
                        personalProfileController.addOverview.value,
                    maxLine: 5,
                    maxLength: 200,
                    isValidate: false,
                    onChange: (text) => setState(() {}),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: CustomText(
                      "${personalProfileController.addOverview.value.text.length}/${200}",
                      color: AppColors.grey9B,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size30),
                  CustomBtn(
                    title: widget.isEdit ? "Update" : "Save",
                    isValidate: personalProfileController
                            .addOverview.value.text.isNotEmpty
                        ? true
                        : false,
                    onTap: personalProfileController
                            .addOverview.value.text.isNotEmpty
                        ? () async {
                            await personalProfileController
                                .updateUserProfileDetails(
                              params: {
                                ApiKeys.id: userId,
                                ApiKeys.objective: personalProfileController
                                    .addOverview.value.text
                              },
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
