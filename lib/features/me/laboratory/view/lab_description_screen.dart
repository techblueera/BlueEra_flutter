import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profile_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabDescriptionScreen extends StatefulWidget {
  const LabDescriptionScreen({super.key});

  @override
  State<LabDescriptionScreen> createState() => _LabDescriptionScreenState();
}

class _LabDescriptionScreenState extends State<LabDescriptionScreen> {
  late final LabProfileController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabProfileController>()) {
      controller = Get.put(LabProfileController(), permanent: true);
    } else {
      controller = Get.find<LabProfileController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.description.tr,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                title: AppStrings.description,
                hintText: "Enter description (max 500 characters)",
                textEditController: controller.descController,
                maxLine: 6,
                maxLength: 500,
                isCounterVisible: true,
                onChange: (_) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size20),
              CustomBtn(
                title: AppStrings.save,
                isValidate: controller.isValid.value,
                isLoading: controller.isLoading.value,
                onTap: controller.isValid.value
                    ? () async {
                        final ok = await controller.save();
                        if (ok) Get.back();
                      }
                    : null,
              ),
            ],
          ),
        );
      }),
    );
  }
}
