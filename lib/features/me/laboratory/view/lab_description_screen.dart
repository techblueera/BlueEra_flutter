import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/info_banner.dart';
import 'package:BlueEra/widgets/section_icon_header.dart';
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
      appBar: CommonBackAppBar(title: AppStrings.description.tr),
      body: SafeArea(
        child: Obx(() {
          return SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBanner(
                  icon: Icons.info_outline,
                  message: AppStrings.labAddDescHelp.tr,
                ),
                SizedBox(height: SizeConfig.size14),

                CommonCardWidget(
                  padding: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionIconHeader(
                          icon: Icons.description_outlined,
                          title: AppStrings.description.tr,
                          subtitle: AppStrings.labTellAboutLab.tr,
                        ),
                        const SizedBox(height: 16),
                        CommonTextField(
                          title: "",
                          hintText: AppStrings.labHintEnterDescription.tr,
                          textEditController: controller.descController,
                          maxLine: 6,
                          maxLength: 500,
                          isCounterVisible: true,
                          onChange: (_) => controller.validateForm(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

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
                SizedBox(height: SizeConfig.size20),
              ],
            ),
          );
        }),
      ),
    );
  }
}
