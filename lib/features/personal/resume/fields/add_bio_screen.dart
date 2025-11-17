import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/bio_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBioScreen extends StatefulWidget {
  final String? initialBio;
  const AddBioScreen({Key? key, this.initialBio}) : super(key: key);

  @override
  State<AddBioScreen> createState() => _AddBioScreenState();
}

class _AddBioScreenState extends State<AddBioScreen> {
  final BioController controller = Get.find<BioController>();

  @override
  void initState() {
    super.initState();
    if (widget.initialBio != null && controller.bioController.text.isEmpty) {
      controller.bioController.text = widget.initialBio!;
      controller.bio.value = widget.initialBio!;
    } else if (controller.bioController.text.isEmpty) {
      controller.bioController.text = '';
      controller.bio.value = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialBio != null;
    return Scaffold(
      appBar: CommonBackAppBar(title: isEdit ?AppStrings.editBio : AppStrings.addBio),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SizeConfig.size16),
                ),
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.bio,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.small,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      hintText: AppStrings.defaultBioDescription,
                      fontSize: SizeConfig.large,
                      textEditController: controller.bioController,
                      maxLine: 5,
                      maxLength: controller.maxLength,
                      isValidate: false,
                      onChange: (val) => controller.bio.value = val,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Obx(() => CustomText(
                            "${controller.bio.value.length}/${controller.maxLength}",
                            color: AppColors.grey9B,
                            fontSize: SizeConfig.small,
                          )),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size30),
              Obx(() => CustomBtn(
                    onTap: controller.bio.value.isNotEmpty &&
                            controller.bio.value.length <= controller.maxLength
                        ? () async {
                            Map<String, dynamic> params = {
                              ApiKeys.bio: controller.bio.value.trim(),
                            };
                            if (isEdit) {
                              await controller.updateBio(params);
                            } else {
                              await controller.addBio(params);
                            }
                          }
                        : null,
                    title: isEdit ? AppStrings.update : AppStrings.save,
                    isValidate: controller.bio.value.isNotEmpty &&
                        controller.bio.value.length <= controller.maxLength,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
