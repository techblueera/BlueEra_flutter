import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';

import '../../../hospital/controller/hospital_model_controller.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../model/medical_lab_details.dart';

class CategoryListView extends StatefulWidget {
  CategoryListView({super.key});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  // final Map<String, Widget Function()> servicePages = {
  bool isToggleAvailable(String title){
    return title == "OPT (Out-Patient Department)" ||
        title == "IPD (In-Patient Department)"||
        title == "Emergency And Critical Care"||
        title == "Diagnostic Departments"||
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
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ...controller.hospitalFacilitiesMap.keys.map((key) {
              return InkWell(
                onTap: (){
                  List<dynamic> modelList = controller.hospitalFacilitiesMap[key];
                  List<MedicalLabDataListModel> hospitalCategoryDataList =
                      modelList.map((e) => MedicalLabDataListModel.fromJson(e)).toList();

                  Get.toNamed(RouteHelper.getHospitalOptCategory(),
                      arguments: {
                        ApiKeys.medicalOtcChildren:hospitalCategoryDataList,
                        // ApiKeys.categoryId:title.id,
                        ApiKeys.title:key.toString(),
                      });
                },
                child: MeMenuCardDesign(
                  title: key,                 // 👈 KEY NAME
                  isToggleOn: false,
                  showToggleButton: false,
                  icon: 'assets/icons/service_icon.svg',
                ),
              );
            }).toList(),
            // ...List.generate(
            //   controller.hospitalFacilitiesMap.length,
            //       (index) {
            //     // final title = controller.hospitalCategoryDataList[index];
            //
            //     return InkWell(
            //       onTap: () {
            //         // if (title.children?.isNotEmpty ?? false) {
            //         //   Get.toNamed(
            //         //     RouteHelper.getHospitalOptCategory(),
            //         //     arguments: {
            //         //       ApiKeys.medicalOtcChildren: title.children,
            //         //       ApiKeys.categoryId: title.id,
            //         //       ApiKeys.title: title.name,
            //         //     },
            //         //   );
            //         // }
            //       },
            //       child: MeMenuCardDesign(
            //         onToggleChanged: (val) {
            //           // /// ✅ 1. UPDATE UI FIRST
            //           // controller.hospitalCategoryDataList[index] =
            //           //     title.copyWith(isActive: val);
            //           //
            //           // /// ✅ 2. CALL API
            //           // Map<String, dynamic> params = {
            //           //   ApiKeys.isActive: val,
            //           // };
            //           //
            //           // controller.updateEnableStatus(title.id ?? '', params);
            //         },
            //         isToggleOn: false,
            //         showToggleButton:false,
            //         title: 'Good',
            //         icon: 'assets/icons/service_icon.svg',
            //       ),
            //     );
            //   },
            // ),

            SizedBox(height: SizeConfig.size100),
          ],
        ),
      );
    })
    ;
  }
}