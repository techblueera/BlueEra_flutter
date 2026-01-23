import 'dart:developer';

import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/common_drop_down_icon_dialoge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';

import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../hospital/controller/hospital_model_controller.dart';
import '../../../hospital/view/category/contact_us_details_page.dart';
import '../../../hospital/view/category/emergency_cricalcare.dart';
import '../../../hospital/view/category/hospital_about_us.dart';
import '../../../hospital/view/category/ipd_wards_list_page.dart';
import '../../../hospital/view/category/other_facility.dart';
import '../../../hospital/view/widget/add_department_dialog.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../../widget/no_product_profile.dart';
import '../../model/medical_lab_details.dart';

class CategoryListView extends StatefulWidget {
  CategoryListView({super.key});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  // final Map<String, Widget Function()> servicePages = {
  bool isToggleAvailable(String title) {
    return title == "OPT (Out-Patient Department)" ||
        title == "IPD (In-Patient Department)" ||
        title == "Emergency And Critical Care" ||
        title == "Diagnostic Departments" ||
        title == "Medical Store"
    ;
  }

  final controller = getOrPut(() => HospitalModelController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.getHospitalMainResponse.value.status == Status.COMPLETE) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              if(controller.hospitalMainPageData.value.data?.isEmpty ?? false)
                NoProfileDetailsFound(
                    content: "Hospital Details not Available Yet")
              else
                ...controller.hospitalMainPageData.value.data
                    ?.map((department) {
                  return InkWell(
                    onTap: () async {
                      if(department.name?.toLowerCase().contains("contact us")??false){
                        Get.to(()=>ContactUsDetailsPage());
                      }else if(department.name?.toLowerCase().contains("about us")??false){
                        Get.to(()=>HospitalAboutUs(
                          categoryId:  department.id??'',
                          title: department.name??"",
                          type: department.type??"",
                        ));
                      }else if(department.name?.toLowerCase().contains("ipd")??false){
                        Get.to(()=>IpdWardsListPage(
                          categoryId:  department.id??'',
                          title: department.name??"",
                          type: department.type??"",
                        ));
                      }else if(department.name?.toLowerCase().contains("emergency")??false){
                        Get.to(()=>EmergencyCriticalCare(
                          categoryId:  department.id??'',
                          title: department.name??"",
                          type: department.type??"",
                        ));
                      }else if(department.name?.toLowerCase().contains("other")??false){
                        Get.to(()=>OtherFacility(
                          categoryId:  department.id??'',
                          title: department.name??"",
                          type: department.type??"",
                        ));
                      }else{
                        Get.toNamed(
                          RouteHelper.getHospitalOptCategory(),
                          arguments: {
                            ApiKeys.title: department.name,
                            ApiKeys.categoryId: department.id,
                            ApiKeys.type: department.type,
                          },
                        );
                      }

                    },
                    child: MeMenuCardDesign(
                      onToggleChanged: (value){

                    },
                      title: department.name ?? '', // ✅ department name
                      isToggleOn: department.isActive,
                      showToggleButton: true,
                      icon: '',
                    ),
                  );
                }).toList() ?? [],
              SizedBox(height: SizeConfig.size10,),
              InkWell(
                onTap: () {
                  controller.nameController.clear();
                  controller.addDepartmentTypeValue.value='${DepartmentType.OPD.name}';
                  controller.addDepartmentLoading.value=false;
                  HospitalDepartmentDialog.show(
                    context: context,
                  );

                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryColor),
                    color: AppColors.primaryColor.withOpacity(0.1),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                        color: AppColors.primaryColor,),
                      SizedBox(width: SizeConfig.size6,),
                      CustomText(
                        "Add New Department",
                        fontSize: 14,
                        textAlign: TextAlign.center,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),


              SizedBox(height: SizeConfig.size100),
            ],
          ),
        );
      } else {
        return SizedBox();
      }
    })
    ;
  }

}