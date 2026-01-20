import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_drop_down.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../controller/hospital_model_controller.dart';

class HospitalDepartmentDialog {
  static void show({
    required BuildContext context,
    String? preDepartmentType,
     String? categoryId,
    String? type,
  }) {
    final controller = getOrPut(() => HospitalModelController());

    // if (preDepartmentType != null) {
    //   controller.addDepartmentTypeValue.value = preDepartmentType;
    // }

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title:  CustomText(
          'Add ${preDepartmentType == null?'':"Sub"}Department',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Name
                CommonTextField(
                  title: "Name of the ${preDepartmentType == null?'':"Sub"}Department",
                  textEditController: controller.nameController,
                  hintText: 'E.g. Diagnostic Department',
                ),
                SizedBox(height: SizeConfig.size16),

                /// Department Type
                if(preDepartmentType == null)
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText("Choose Department Type"),
                      SizedBox(height: SizeConfig.size10),
                      CommonDropdown(
                        items:
                        DepartmentType.values.map((e) => e.name).toList(),
                        selectedValue:
                        controller.addDepartmentTypeValue.value,
                        hintText: "Choose Department Type",
                        onChanged: (value) {
                          controller.addDepartmentTypeValue.value = value ?? '';
                        },
                        displayValue: (value) => "$value",
                      ),
                      SizedBox(height: SizeConfig.size16),
                    ],
                  ),
                /// Active Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomText('Active Status'),
                    CustomToggleSwitch(
                      isOn: controller.isActive.value,
                      onChanged: (val) {
                        controller.isActive.value = val;
                      },
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size28),

                /// Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        title: "Cancel",
                        isValidate: false,
                        onTap: () {
                          Get.back();
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: CustomBtn(
                        title: "Add",
                        isValidate: true,
                        isLoading:
                        controller.addDepartmentLoading.value,
                        onTap: () {
                          controller.addHospitalDepartmentApi(
                            preType: type,
                            categoryId: categoryId,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
