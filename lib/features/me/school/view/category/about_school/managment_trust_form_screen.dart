import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementTrustFormScreen extends StatefulWidget {
  ManagementTrustFormScreen({super.key});

  @override
  State<ManagementTrustFormScreen> createState() =>
      _ManagementTrustFormScreenState();
}

class _ManagementTrustFormScreenState extends State<ManagementTrustFormScreen> {
  final aboutUsController = Get.find<SchoolController>();

  final nameEditController = TextEditingController();

  final professionEditController = TextEditingController();

  final messageEditController = TextEditingController();

  @override
  void initState() {
    aboutUsController.isFormValid.value=false;
    // TODO: implement initState
    aboutUsController.addQualification();
    nameEditController.addListener(_runValidation);
    professionEditController.addListener(_runValidation);
    messageEditController.addListener(_runValidation);
    aboutUsController.qualifications.firstOrNull?.addListener(_runValidation);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Management / Trust",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonTextField(
                  textEditController: nameEditController,
                  hintText: "E.g. Ramesh Gupta",
                  title: "Name",
                  maxLength: 50,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  'Qualification',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                Obx(() => Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: aboutUsController.qualifications.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: aboutUsController
                                          .qualifications[index],
                                      decoration: InputDecoration(
                                        hintText: "E.g. PhD in Geography",
                                      ),
                                    ),
                                  ),
                                  if (aboutUsController.qualifications.length >
                                      1)
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () => aboutUsController
                                          .removeQualification(index),
                                    )
                                ],
                              ),
                            );
                          },
                        ),

                        /// Add More Button (hidden after 5)
                        if (aboutUsController.qualifications.length < 5)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(Icons.add),
                              label: CustomText(
                                "Add More",
                                color: AppColors.primaryColor,
                              ),
                              onPressed: aboutUsController.addQualification,
                            ),
                          ),
                      ],
                    )),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: professionEditController,
                  hintText: "E.g. Managing Director",
                  title: "Profession",
                  maxLength: 50,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),

                CommonTextField(
                  textEditController: messageEditController,
                  title: AppStrings.message,
                  hintText:
                      "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (value) {
                    String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    aboutUsController.managementDescriptionText.value = newVal;
                    _runValidation();
                  },
                ),
                SizedBox(height: SizeConfig.paddingXSL),

                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => CustomText(
                        "${aboutUsController.managementDescriptionText.value.length}/1000",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.paddingM),

                // THE BUTTON
                Obx(() => CustomBtn(
                      onTap: aboutUsController.isFormValid.value ? () {} : null,
                      title: AppStrings.add,
                      // Pass the validation state to change button color/opacity
                      isValidate: aboutUsController.isFormValid.value,
                    )),
                SizedBox(height: SizeConfig.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper to trigger validation
  void _runValidation() {
    aboutUsController.managementValidateForm(
        managementName: nameEditController.text,
        profession: professionEditController.text,
        message: messageEditController.text,
        qualification:
            aboutUsController.qualifications.firstOrNull?.text ?? "");
  }
}
