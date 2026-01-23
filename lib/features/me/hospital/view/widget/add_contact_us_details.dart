import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../controller/hospital_model_controller.dart';

class AddContactUsDetailsDialog {
  static void showAddContactUs({
    required BuildContext context,
  }) {
    final controller = getOrPut(() => HospitalModelController());

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Add Hospital Details',
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
                  title: "Hospital Name",
                  hintText: "E.g. Dr. The Mission Hospital",
                  textEditController: controller.nameController,
                ),
                SizedBox(height: SizeConfig.size12),
                /// Specialization
                CommonTextField(
                  title: "Website",
                  hintText: "E.g. http//:themissionhospital.in",
                  textEditController:
                  controller.websiteController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Qualification
                CommonTextField(
                  title: "Address",
                  hintText: "E.g. Mg st,second cross,UP",
                  textEditController:
                  controller.addressController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Availability
                CommonTextField(
                  title: "Admission Phone",
                  hintText: "Admission Phone Number",
                  keyBoardType: TextInputType.number,
                  validationType: ValidationTypeEnum.pNumber,
                  textEditController:
                  controller.admissionNoController,
                  maxLength: 10,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Fees
                CommonTextField(
                  maxLength: 10,
                  title: "Principal Phone",
                  hintText: "Principal Phone Number",
                  keyBoardType: TextInputType.number,
                  validationType: ValidationTypeEnum.pNumber,
                  textEditController:
                  controller.principalNoController,
                ),
                SizedBox(height: SizeConfig.size12),
                CommonTextField(
                  title: "Email",
                  hintText: "E.g. themissionhospital@gmail.com",
                  textEditController:
                  controller.emailController,
                ),
                SizedBox(height: SizeConfig.size24),

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
                        title: "Add Details",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          controller.addContactUsDetails();
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
  static void showHospitalNameEdit({
    required BuildContext context,
    required String preName
  }) {
    final controller = getOrPut(() => HospitalModelController());
    controller.nameController.text=preName;
    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Edit Hospital Details',
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
                  title: "Hospital Name",
                  hintText: "E.g. Dr. The Mission Hospital",
                  textEditController: controller.nameController,
                ),

                SizedBox(height: SizeConfig.size24),

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
                        title: "Add Details",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          controller.editHospitalNameDetails();
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
  static void showHospitalAdmissionEdit({
    required BuildContext context,
    required String preName
  }) {
    final controller = getOrPut(() => HospitalModelController());
    controller.admissionNoController.text=preName;
    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Edit Hospital Details',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                CommonTextField(
                  title: "Admission Phone",
                  hintText: "Admission Phone Number",
                  keyBoardType: TextInputType.number,
                  validationType: ValidationTypeEnum.pNumber,
                  textEditController:
                  controller.admissionNoController,
                  maxLength: 10,
                ),
                SizedBox(height: SizeConfig.size24),

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
                        title: "Add Details",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          controller.editHospitalAdmissionCellDetails();
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
  static void showHospitalPrincipalEdit({
    required BuildContext context,
    required String preName
  }) {
    final controller = getOrPut(() => HospitalModelController());
    controller.principalNoController.text=preName;
    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Edit Hospital Details',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                CommonTextField(
                  maxLength: 10,
                  title: "Principal Phone",
                  hintText: "Principal Phone Number",
                  keyBoardType: TextInputType.number,
                  validationType: ValidationTypeEnum.pNumber,
                  textEditController:
                  controller.principalNoController,
                ),
                SizedBox(height: SizeConfig.size24),

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
                        title: "Add Details",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          controller.editHospitalPrincipalCellDetails();
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
  static void showHospitalEmailEdit({
    required BuildContext context,
    required String preName
  }) {
    final controller = getOrPut(() => HospitalModelController());
    controller.emailController.text=preName;
    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Edit Hospital Details',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                CommonTextField(
                  title: "Email",
                  hintText: "E.g. themissionhospital@gmail.com",
                  textEditController:
                  controller.emailController,
                ),
                SizedBox(height: SizeConfig.size24),

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
                        title: "Add Details",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          controller.editHospitalEmailDetails();
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
  static void addAboutUsDetailsPage({
    required BuildContext context,
     String? preVision,
     String? preHistory
  }) {
    final controller = getOrPut(() => HospitalModelController());
    if(preVision!=null&&preHistory!=null){
      controller.vissionAndMission.text=preVision;
      controller.hospitalHistory.text=preHistory;
    }

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Add About Us',
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
                  title: "Vision And Mission",
                  hintText: "E.g. Enter Future Vision And Mission",
                  textEditController: controller.vissionAndMission,
                  maxLine: 4,
                ),
                SizedBox(height: 10,),
                CommonTextField(
                  title: "History",
                  hintText: "E.g. Since 1999 we successfully run our hospital",
                  textEditController: controller.hospitalHistory,
                  maxLine: 4,
                ),

                SizedBox(height: SizeConfig.size24),

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
                        title: preVision!=null&&preHistory!=null?"Edit Details":"Add Details",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          controller.addAboutUs();
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
