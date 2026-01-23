import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/features/me/hospital/model/get_beds_details_model.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_ward_model.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/docters_details_model.dart';

class HospitalStaffDialog {
  static void showAddDoctor({
    required BuildContext context,
    required String departmentId,
    DoctorsDetailsModel? preDoctorDetails,
  }) {
    final controller = getOrPut(() => HospitalModelController());

    if(preDoctorDetails!=null){
      controller.prePhotoImage=preDoctorDetails.photo??'';
      controller.nameController.text=preDoctorDetails.name??'';
      controller.specializationController.text=preDoctorDetails.specialization??'';
      controller.qualificationController.text=preDoctorDetails.qualification??'';
      controller.availabilityController.text=preDoctorDetails.availability??'';
      controller.feesController.text=preDoctorDetails.fees.toString()??'';
    }else{
      controller.clearStaffForm();
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
          'Add Doctor',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: ()async{
                          final String? image =
                         await  SelectProfilePictureDialog.showLogoDialog(context, "Doctor Image");
                          if(image!=null){
                            controller.pickDoctorImage(File(image??''));
                          }
                        },
                        child: Container(
                          height: SizeConfig.size100,
                          width: SizeConfig.size100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: ClipOval(
                            child: (controller.prePhotoImage!=null)?
                            Image.network(controller.prePhotoImage??'')
                                :controller.pickedDoctorImage.value != null
                                ? Image.file(
                              controller.pickedDoctorImage.value!,
                              fit: BoxFit.cover,
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt, size: 24),
                                SizedBox(height: 4),
                                Text(
                                  "Photo of Doctor",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                /// Name
                CommonTextField(
                  title: "Doctor Name",
                  hintText: "E.g. Dr. Kumar",
                  textEditController: controller.nameController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Specialization
                CommonTextField(
                  title: "Specialization",
                  hintText: "E.g. Cardiologist",
                  textEditController:
                  controller.specializationController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Qualification
                CommonTextField(
                  title: "Qualification",
                  hintText: "E.g. MBBS, MD",
                  textEditController:
                  controller.qualificationController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Availability
                CommonTextField(
                  title: "Availability",
                  hintText: "E.g. Mon - Fri (10AM - 4PM)",
                  textEditController:
                  controller.availabilityController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Fees
                CommonTextField(
                  title: "Consultation Fees",
                  hintText: "E.g. 500",
                  keyBoardType: TextInputType.number,
                  textEditController: controller.feesController,
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
                          // controller.clearStaffForm();
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: CustomBtn(
                        title: (preDoctorDetails!=null)?"Edit Doctor":"Add Doctor",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          if(preDoctorDetails!=null){
                            controller.editDoctorDetails(preDoctorDetails.id??'');
                          }else{
                            controller.addDoctors(departmentId: departmentId);
                          }
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
  static void showAddIPDWardDialog({
    required BuildContext context,
    required String departmentId,
    WardModel? preDoctorDetails,
  }) {
    final controller = getOrPut(() => HospitalModelController());

    if(preDoctorDetails!=null){
      controller.nameController.text=preDoctorDetails.name??'';
      controller.totalBedsController.text=preDoctorDetails.totalBeds.toString()??'';
      controller.availableBedsController.text=preDoctorDetails.availableBeds.toString()??'';
      controller.feesController.text=preDoctorDetails.fees.toString()??'';
    }else{
      controller.clearStaffForm();
    }
    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title:  CustomText(
          preDoctorDetails!=null?"Edit Ward":'Add Ward',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Specialization
                CommonTextField(
                  title: "Name",
                  hintText: "E.g. General Bed Male",
                  textEditController:
                  controller.nameController,
                ),
                SizedBox(height: SizeConfig.size12),
                CommonTextField(
                  title: "Total Beds",
                  hintText: "E.g. 50",
                  textEditController:
                  controller.totalBedsController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Qualification
                CommonTextField(
                  title: "Available Beds",
                  hintText: "E.g. We have best and clean beds",
                  textEditController:
                  controller.availableBedsController,
                ),
                SizedBox(height: SizeConfig.size12),


                /// Fees
                CommonTextField(
                  title: "Fees",
                  hintText: "E.g. 500",
                  keyBoardType: TextInputType.number,
                  textEditController: controller.feesController,
                ),
                SizedBox(height: SizeConfig.size20),
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
                          // controller.clearStaffForm();
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: CustomBtn(
                        title: (preDoctorDetails!=null)?"Edit Ward":"Add Ward",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          if(preDoctorDetails!=null){
                            controller.editWardsDetails(departmentId: departmentId, wardId: preDoctorDetails.id??'');
                          }else{
                            controller.addNewWardsDetails(departmentId: departmentId);
                          }

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
  static void showAddBedsDialog({
    required BuildContext context,
    required String departmentId,
    BedDetailsModel? preDoctorDetails,
  }) {
    final controller = getOrPut(() => HospitalModelController());

    if(preDoctorDetails!=null){
      controller.prePhotoImage=preDoctorDetails.image??'';
      controller.nameController.text=preDoctorDetails.name??'';
      controller.totalBedsController.text=preDoctorDetails.bedNumber??'';
      controller.bedsDescriptionController.text=preDoctorDetails.description??'';
      controller.feesController.text=preDoctorDetails.fees.toString()??'';
    }else{
      controller.clearStaffForm();
    }
    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title:  CustomText(
          preDoctorDetails!=null?"Edit Beds":'Add Beds',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: ()async{
                          final String? image =
                         await  SelectProfilePictureDialog.showLogoDialog(context, "Doctor Image");
                          if(image!=null){
                            controller.pickDoctorImage(File(image??''));
                          }
                        },
                        child: Container(
                          height: SizeConfig.size100,
                          width: SizeConfig.size100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: ClipOval(
                            child: (controller.prePhotoImage!=null)?
                            Image.network(controller.prePhotoImage??'')
                                :controller.pickedDoctorImage.value != null
                                ? Image.file(
                              controller.pickedDoctorImage.value!,
                              fit: BoxFit.cover,
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt, size: 24),
                                SizedBox(height: 4),
                                Text(
                                  "Photo of Ward",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                /// Name
                /// //{


                /// Specialization
                CommonTextField(
                  title: "Name",
                  hintText: "E.g. General Bed Male",
                  textEditController:
                  controller.nameController,
                ),
                SizedBox(height: SizeConfig.size12),
                CommonTextField(
                  title: "Total Number",
                  hintText: "E.g. 50",
                  textEditController:
                  controller.totalBedsController,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Qualification
                CommonTextField(maxLine: 4,
                  title: "Discretion",
                  hintText: "E.g. We have best and clean beds",
                  textEditController:
                  controller.bedsDescriptionController,
                ),
                SizedBox(height: SizeConfig.size12),


                /// Fees
                CommonTextField(
                  title: "Fees (Per Day)",
                  hintText: "E.g. 500",
                  keyBoardType: TextInputType.number,
                  textEditController: controller.feesController,
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
                          // controller.clearStaffForm();
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: CustomBtn(
                        title: (preDoctorDetails!=null)?"Edit Bed":"Add Bed",
                        isValidate: true,
                        isLoading:
                        controller.addDoctorLoading.value,
                        onTap: () {
                          if(preDoctorDetails!=null){
                            controller.editBedsDetails(departmentId:preDoctorDetails.wardId ,bedId: preDoctorDetails.id??'');
                          }else{
                            controller.addNewBedsDetails(departmentId: departmentId);
                          }
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
