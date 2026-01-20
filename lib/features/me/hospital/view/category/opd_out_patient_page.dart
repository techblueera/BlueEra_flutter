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
import '../../../../../widgets/common_drop_down.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../../medical/model/medical_lab_details.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';
import '../widget/add_department_dialog.dart';
import '../widget/general_medicine.dart';
import 'contact_us_details_page.dart';


class OpdOutPatientPage extends StatefulWidget {
  const OpdOutPatientPage(
      {super.key, required this.categoryId, required this.title, required this.type});
  final String categoryId;
  final String title;
  final String type;

  @override
  State<OpdOutPatientPage> createState() => _OpdOutPatientPageState();
}

class _OpdOutPatientPageState extends State<OpdOutPatientPage> {
  final controller = getOrPut(() => HospitalModelController());

  // final Map<String, Widget Function()> opdPages = {
  //   "General Medicine": () => DoctorListView(),
  //   "General Surgery": () => DoctorListView(),
  //   "Orthopedics": () => DoctorListView(),
  //   "Obstetrics & Gynecology": () => DoctorListView(),
  //   "Pediatrics": () => DoctorListView(),
  //   "ENT (Ear, Nose, Throat)": () => DoctorListView(),
  //   "Ophthalmology (Eye)": () => DoctorListView(),
  //   "Dermatology (Skin)": () => DoctorListView(),
  //   "Psychiatry": () => DoctorListView(),
  //   "Dental OPD": () => DoctorListView(),
  // };

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
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: NoProfileDetailsFound(
                            content: "No Details Found Under ${widget.title}"),
                      )
                    else
                      ...controller.hospitalSubCate.map((department) {
                        return InkWell(
                          onTap: () async {
                            if(widget.type.toLowerCase().contains("opd")){
                              Get.toNamed(
                                RouteHelper.getHospitalDoctorViewCategory(),
                              arguments: {
                                  ApiKeys.categoryId:department.id,
                                  ApiKeys.title:department.name
                              }
                              );
                            }else if(widget.type.toLowerCase().contains('ipd')){
                              Get.toNamed(
                                  RouteHelper.getHospitalWardViewCategory(),
                                  arguments: {
                                    ApiKeys.categoryId:department.id,
                                    ApiKeys.title:department.name
                                  }
                              );
                            }
                          },
                          child: MeMenuCardDesign(
                            title: department.name ?? '', // ✅ department name
                            isToggleOn: department.isActive,
                            showToggleButton: true,
                            icon: 'assets/icons/service_icon.svg',
                          ),
                        );
                      }).toList(),
                    SizedBox(height: SizeConfig.size20,),
                    InkWell(
                      onTap: () {
                        controller.nameController.clear();
                        HospitalDepartmentDialog.show(
                          preDepartmentType: widget.type,
                          context: context,
                          categoryId: widget.categoryId,
                          type: widget.type,
                        );
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
}
