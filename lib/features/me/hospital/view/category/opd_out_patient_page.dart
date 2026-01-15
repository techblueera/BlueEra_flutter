import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../../medical/model/medical_lab_details.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';
import '../widget/general_medicine.dart';
import 'contact_us_details_page.dart';
enum DepartmentType {
  opd,
  ipd,
  emergency,
  diagnostic,
  medicalStore,
  other,
}

class OpdOutPatientPage extends StatefulWidget {
  const OpdOutPatientPage(
      {super.key, required this.categoryId, required this.title});

  final String categoryId;
  final String title;

  @override
  State<OpdOutPatientPage> createState() => _OpdOutPatientPageState();
}

class _OpdOutPatientPageState extends State<OpdOutPatientPage> {
  final controller = getOrPut(() => HospitalModelController());

  final Map<String, Widget Function()> opdPages = {
    "General Medicine": () => DoctorListView(),
    "General Surgery": () => DoctorListView(),
    "Orthopedics": () => DoctorListView(),
    "Obstetrics & Gynecology": () => DoctorListView(),
    "Pediatrics": () => DoctorListView(),
    "ENT (Ear, Nose, Throat)": () => DoctorListView(),
    "Ophthalmology (Eye)": () => DoctorListView(),
    "Dermatology (Skin)": () => DoctorListView(),
    "Psychiatry": () => DoctorListView(),
    "Dental OPD": () => DoctorListView(),
  };

  @override
  void initState() {
    // TODO: implement initState
    controller.fetchHospitalSubCategoryData(widget.categoryId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: widget.title,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Obx(() {
            if (controller.getHospitalSubResponse.value.status ==
                Status.COMPLETE) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    if(controller.hospitalSubCate.isEmpty)
                      NoProfileDetailsFound(
                          content: "${widget.title} not Available Yet")
                    else
                      ...controller.hospitalSubCate.map((department) {
                        return InkWell(
                          onTap: () async {
                            Get.toNamed(
                              RouteHelper.getHospitalDoctorViewCategory(),);
                          },
                          child: MeMenuCardDesign(
                            title: department.name ?? '', // ✅ department name
                            isToggleOn: false,
                            showToggleButton: false,
                            icon: 'assets/icons/service_icon.svg',
                          ),
                        );
                      }).toList(),
                    SizedBox(height: SizeConfig.size10,),
                    InkWell(
                      onTap: () {
                        showAddDepartmentDialog(context);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryColor),
                          color: AppColors.primaryColor.withOpacity(0.1),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                              color: AppColors.primaryColor,),
                            SizedBox(width: SizeConfig.size6,),
                            CustomText(
                              "Add More ${widget.title}",
                              fontSize: 14,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size50,),
                  ],
                ),
              );
            } else if (controller.getHospitalSubResponse.value.status ==
                Status.INITIAL) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(
                child: CustomText("Please try sometime"),
              );
            }
          }),
        ),
      ),
    );
  }
 // String findDepartmentName(String department) {
 // return (widget.title.toLowerCase().contains('opd'))?DepartmentType.:'';
 //  }
  void showAddDepartmentDialog(BuildContext context) {
    final controller = getOrPut(() => HospitalModelController());
    Get.dialog(
      AlertDialog(
        title: const CustomText('Add Department'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Name
                  CommonTextField(
                    title: "Name of the Department",
                    textEditController: controller.nameController,
                    hintText: 'E.g.General Surgery',
                  ),
                  SizedBox(height: SizeConfig.size12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText('Active Status'),
                      Obx(() {
                        return CustomToggleSwitch(
                          isOn: controller.isActive.value,
                          onChanged: (val) {
                            controller.isActive.value = val;
                          },
                        );
                      })
                    ],
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                            isValidate: false,
                            onTap: () {
                              Get.back();
                            }, title: "Cancel"),
                      ),
                      SizedBox(width: SizeConfig.size12,),
                      Expanded(
                        child: CustomBtn(
                            isValidate: true,
                            onTap: () {
                              Map<String,dynamic> params={
                                "name": "string",
                                "type": "OPD",
                                "icon": "string",
                                "isActive": true
                              };
                              controller.addHospitalDepartmentApi(params);
                            }, title: "Add"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}
