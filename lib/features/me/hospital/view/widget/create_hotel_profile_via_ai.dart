import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../controller/hospital_model_controller.dart';
import 'add_hospital_prev_widget.dart';

class CreateHotelProfileViaAi extends StatefulWidget {
  const CreateHotelProfileViaAi({super.key});

  @override
  State<CreateHotelProfileViaAi> createState() =>
      _CreateHotelProfileViaAiState();
}

class _CreateHotelProfileViaAiState
    extends State<CreateHotelProfileViaAi> {

  final _formKey = GlobalKey<FormState>();
  late final HospitalModelController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalModelController());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "Create Your profile Via AI",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: SizeConfig.size20),

            CommonTextField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please Enter Hospital Name";
                }
                return null;
              },
              textEditController:
              controller.hospitalNameTextController,
              title: "Search Your Profile On Google",
              hintText: "E.g. The Mission Hospital...",
            ),

            SizedBox(height: SizeConfig.size12),

            CommonTextField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please Enter Hospital Address";
                }
                return null;
              },
              textEditController:
              controller.hospitalAddressTextController,
              title: "Hospital Address",
              hintText: "E.g. RM St, Mumbai",
            ),

            SizedBox(height: SizeConfig.size12),

            CommonTextField(
              isValidate: false,
              textEditController:
              controller.hospitalLinkTextController,
              title: "Hospital Website",
              hintText: "https://themissionhospital.com",
            ),

            SizedBox(height: SizeConfig.size20),

            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    return CustomBtn(
                      isLoading:
                      controller.isAiBtnLoading.value,
                      isValidate: true,
                      title: "Generate",
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          await controller.fetchHospitalViaAi();
                          Get.to(()=>HospitalPreviewScreen());
                        }
                      },
                    );
                  }),
                ),
                SizedBox(width: SizeConfig.size10),
                SizedBox(
                  width: 60,
                  child: CustomBtn(
                    title: "Skip",
                    onTap: () => Get.back(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
