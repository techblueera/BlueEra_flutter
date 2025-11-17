import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/add_career_obj_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AddCareerObjectiveScreen extends StatefulWidget {
  final bool isEdit;
  const AddCareerObjectiveScreen({Key? key, this.isEdit = false}) : super(key: key);

  @override
  State<AddCareerObjectiveScreen> createState() => _AddCareerObjectiveScreenState();
}

class _AddCareerObjectiveScreenState extends State<AddCareerObjectiveScreen> {
  final CareerObjectiveController controller = Get.find<CareerObjectiveController>();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && controller.careerObjective.value.isNotEmpty) {
      controller.careerObjectiveController.text = controller.careerObjective.value;
    } else {
      controller.careerObjectiveController.clear();
    }
  }

 @override
Widget build(BuildContext context) {
  final obs = controller.careerObjectiveController;
  return Scaffold(
    appBar: CommonBackAppBar(
      title: widget.isEdit ? AppStrings.editCareerObjective :AppStrings.addCareerObjective),
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
                    AppStrings.careerObjective,
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  CommonTextField(
                    hintText: AppStrings.typeHere,
                    fontSize: SizeConfig.large,
                    textEditController: obs,
                    maxLine: 5,
                    maxLength: controller.maxLength,
                    isValidate: false,
                    onChange: (text) => setState(() {}),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: CustomText(
                      "${obs.text.length}/${controller.maxLength}",
                      color: AppColors.grey9B,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size30),
            CustomBtn(
              title: widget.isEdit ? AppStrings.update : AppStrings.save,
              isValidate: obs.text.trim().isNotEmpty &&
                  obs.text.length <= controller.maxLength,
              onTap: obs.text.trim().isNotEmpty &&
                      obs.text.length <= controller.maxLength
                  ? () async {
                      if (widget.isEdit) {
                        await controller.updateCareerObjectiveApi();
                      } else {
                        await controller.addCareerObjectiveApi();
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}
}